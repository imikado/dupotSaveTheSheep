#!/bin/bash
# Exporte Save the Sheep pour Flathub : génère le .pck (preset « Linux ») puis
# crée export/Linux/bundle.tar.gz (pck + icônes + appdata + desktop) référencé
# par le manifeste Flathub, et affiche son sha256.
set -e

cd "$(dirname "$0")"

GODOT="${GODOT:-$(command -v godot || echo "$HOME/apps/Godot_v4.7.2-stable_linux.x86_64")}"
PRESET="Linux"
APP_ID="org.dupot.savethesheep"
LINUX_DIR="export/Linux"
FLATPAK_DIR="$LINUX_DIR/flatpak"
BUNDLE_DIR="$LINUX_DIR/bundle"
BUNDLE_TGZ="$LINUX_DIR/bundle.tar.gz"
PCK="$LINUX_DIR/dupotSaveTheSheep.pck"

if [ ! -x "$GODOT" ]; then
	echo "Godot introuvable ($GODOT) : définir la variable GODOT" >&2
	exit 1
fi

for f in "$FLATPAK_DIR/$APP_ID.appdata.xml" "$FLATPAK_DIR/$APP_ID.desktop" "$FLATPAK_DIR/icons"; do
	if [ ! -e "$f" ]; then
		echo "Fichier manquant : $f" >&2
		exit 1
	fi
done

# Screenshots de l'appdata : Flathub refuse les URL sur une branche (main), qui
# casseraient les liens si les fichiers changent. On les fait pointer sur le
# dernier commit (déjà poussé) qui a modifié les screenshots.
APPDATA="$FLATPAK_DIR/$APP_ID.appdata.xml"
SCREENSHOTS_DIR="$LINUX_DIR/screenshots"
if [ -n "$(git status --porcelain -- "$SCREENSHOTS_DIR")" ]; then
	echo "Screenshots modifiés non commités ($SCREENSHOTS_DIR) : commiter et pousser d'abord" >&2
	exit 1
fi
SCREENSHOTS_COMMIT="$(git log -1 --format=%H -- "$SCREENSHOTS_DIR")"
if [ -z "$(git branch -r --contains "$SCREENSHOTS_COMMIT")" ]; then
	echo "Le commit $SCREENSHOTS_COMMIT des screenshots n'est pas poussé : git push d'abord" >&2
	exit 1
fi
sed -i -E "s|(https://raw\.githubusercontent\.com/[^/]+/[^/]+/)[^/]+(/$SCREENSHOTS_DIR/)|\1$SCREENSHOTS_COMMIT\2|g" "$APPDATA"
for image in $(grep -oP "raw\.githubusercontent\.com/[^/]+/[^/]+/$SCREENSHOTS_COMMIT/\K[^<]+" "$APPDATA"); do
	if ! git cat-file -e "$SCREENSHOTS_COMMIT:$image" 2>/dev/null; then
		echo "Screenshot absent du commit $SCREENSHOTS_COMMIT : $image" >&2
		exit 1
	fi
done
echo "Screenshots : commit $SCREENSHOTS_COMMIT"

# Godot ne doit pas importer (ni embarquer dans le .pck) les fichiers exportés
mkdir -p export
touch export/.gdignore

# Import des ressources puis export du .pck seul (le runtime Godot est fourni
# par le manifeste Flathub)
rm -f "$PCK"
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --export-pack "$PRESET" "$PCK"

if [ ! -f "$PCK" ]; then
	echo "Échec de l'export du pck ($PCK)" >&2
	exit 1
fi

# Vérification des métadonnées (facultative, si les outils sont installés)
if command -v appstreamcli >/dev/null; then
	appstreamcli validate --no-net "$FLATPAK_DIR/$APP_ID.appdata.xml" || true
fi
if command -v desktop-file-validate >/dev/null; then
	desktop-file-validate "$FLATPAK_DIR/$APP_ID.desktop" || true
fi

# Bundle
rm -rf "$BUNDLE_DIR" "$BUNDLE_TGZ"
mkdir -p "$BUNDLE_DIR/icons"
cp "$PCK" "$BUNDLE_DIR/"
cp "$FLATPAK_DIR"/icons/*.png "$BUNDLE_DIR/icons/"
cp "$FLATPAK_DIR/$APP_ID.appdata.xml" "$BUNDLE_DIR/"
cp "$FLATPAK_DIR/$APP_ID.desktop" "$BUNDLE_DIR/"
tar -czf "$BUNDLE_TGZ" -C "$BUNDLE_DIR" .

echo "Pck    : $PCK ($(du -h "$PCK" | cut -f1))"
echo "Bundle : $BUNDLE_TGZ ($(du -h "$BUNDLE_TGZ" | cut -f1))"
echo "sha256 : $(sha256sum "$BUNDLE_TGZ" | cut -d' ' -f1)"
