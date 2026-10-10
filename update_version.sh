#!/bin/bash
# Reporte le numéro de version de la dernière release déclarée dans l'appdata
# Flathub (première balise <release>) dans le reste du projet :
#   - project.godot                       application/config/version
#   - src/Autoload/GlobalVersion.gd       var version = "X.Y.Z"
#   - export/Linux/snap/snapcraft.yaml    version: "X.Y.Z"
#
# Usage : ajouter une <release version="X.Y.Z"> en tête de <releases> dans
# l'appdata, puis lancer ./update_version.sh
set -e

cd "$(dirname "$0")"

APPDATA="export/Linux/flatpak/org.dupot.savethesheep.appdata.xml"
PROJECT="project.godot"
GLOBAL_VERSION="src/Autoload/GlobalVersion.gd"
SNAPCRAFT="export/Linux/snap/snapcraft.yaml"

VERSION="$(grep -m1 -oP '<release\b[^>]*\bversion="\K[^"]+' "$APPDATA" || true)"
if [ -z "$VERSION" ]; then
	echo "Aucune <release version=\"...\"> trouvée dans $APPDATA" >&2
	exit 1
fi
echo "Version de l'appdata : $VERSION"

# project.godot : remplace config/version, ou l'ajoute après config/name
if grep -q '^config/version=' "$PROJECT"; then
	sed -i -E "s|^config/version=.*|config/version=\"$VERSION\"|" "$PROJECT"
else
	sed -i -E "/^config\/name=/a config/version=\"$VERSION\"" "$PROJECT"
fi
echo "  $PROJECT"

sed -i -E "s|^(var version = )\"[^\"]*\"|\1\"$VERSION\"|" "$GLOBAL_VERSION"
echo "  $GLOBAL_VERSION"

sed -i -E "s|^version:.*|version: \"$VERSION\"|" "$SNAPCRAFT"
echo "  $SNAPCRAFT"

# Contrôle : chaque fichier doit maintenant contenir la version
for f in "$PROJECT" "$GLOBAL_VERSION" "$SNAPCRAFT"; do
	if ! grep -q "\"$VERSION\"" "$f"; then
		echo "Version non mise à jour dans $f" >&2
		exit 1
	fi
done
echo "OK"
