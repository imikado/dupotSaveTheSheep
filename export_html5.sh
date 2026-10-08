#!/bin/bash
# Exporte Save the Sheep en HTML5 (preset « Web ») puis crée le zip à publier
# sur itch.io (index.html à la racine du zip).
set -e

cd "$(dirname "$0")"

GODOT="${GODOT:-$(command -v godot || echo "$HOME/apps/Godot_v4.7.2-stable_linux.x86_64")}"
PRESET="Web"
EXPORT_DIR="export/HTML5"
ZIP_NAME="dupotSaveTheSheep-html5.zip"

if [ ! -x "$GODOT" ]; then
	echo "Godot introuvable ($GODOT) : définir la variable GODOT" >&2
	exit 1
fi

# Les modèles d'export Web doivent correspondre à la version de Godot
GODOT_VERSION="$("$GODOT" --version | sed "s/\.official.*//")"
TEMPLATES="$HOME/.local/share/godot/export_templates/$GODOT_VERSION"
if [ ! -f "$TEMPLATES/web_nothreads_release.zip" ]; then
	echo "Modèles d'export Web absents pour Godot $GODOT_VERSION ($TEMPLATES)" >&2
	exit 1
fi

# Godot ne doit pas importer (ni embarquer dans le .pck) les fichiers exportés :
# screenshots, cover itch.io, gif promo, builds Linux/Android...
mkdir -p export
touch export/.gdignore

rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

# Import des ressources puis export avec la version de Godot du projet
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --export-release "$PRESET" "$EXPORT_DIR/index.html"

# le zip est rangé avec l'export, sans s'inclure lui-même
(cd "$EXPORT_DIR" && rm -f "$ZIP_NAME" && zip -r -q "$ZIP_NAME" . -x "*.import" "$ZIP_NAME")

echo "Export : $EXPORT_DIR"
echo "Zip    : $EXPORT_DIR/$ZIP_NAME ($(du -h "$EXPORT_DIR/$ZIP_NAME" | cut -f1))"
