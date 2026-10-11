#!/bin/bash
# Exporte Save the Sheep pour le Snap Store : génère l'exécutable et le .pck
# (preset « Linux ») dans export/Linux/snap/, puis construit le .snap avec
# export/Linux/snap/build-snap.sh.
#
# Usage :
#   ./export_snap.sh            # export + pack
#   ./export_snap.sh --install  # export + pack + installation locale
set -e

cd "$(dirname "$0")"

GODOT="${GODOT:-$(command -v godot || echo "$HOME/apps/Godot_v4.7.2-stable_linux.x86_64")}"
PRESET="Linux"
SNAP_DIR="export/Linux/snap"
BINARY="$SNAP_DIR/dupotSaveTheSheep.x86_64"
PCK="$SNAP_DIR/dupotSaveTheSheep.pck"

if [ ! -x "$GODOT" ]; then
	echo "Godot introuvable ($GODOT) : définir la variable GODOT" >&2
	exit 1
fi

if ! command -v snapcraft >/dev/null; then
	echo "snapcraft introuvable : sudo snap install snapcraft --classic" >&2
	exit 1
fi

# Les modèles d'export Linux doivent correspondre à la version de Godot
GODOT_VERSION="$("$GODOT" --version | sed "s/\.official.*//")"
TEMPLATES="$HOME/.local/share/godot/export_templates/$GODOT_VERSION"
if [ ! -f "$TEMPLATES/linux_release.x86_64" ]; then
	echo "Modèles d'export Linux absents pour Godot $GODOT_VERSION ($TEMPLATES)" >&2
	exit 1
fi

# Godot ne doit pas importer (ni embarquer dans le .pck) les fichiers exportés
mkdir -p export
touch export/.gdignore

# Import des ressources puis export release (le preset n'embarque pas le pck :
# l'exécutable et le .pck sont générés côte à côte, comme l'attend snapcraft.yaml)
rm -f "$BINARY" "$PCK"
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --export-release "$PRESET" "$BINARY"

for f in "$BINARY" "$PCK"; do
	if [ ! -f "$f" ]; then
		echo "Échec de l'export ($f)" >&2
		exit 1
	fi
done
chmod 755 "$BINARY"

echo "Binaire : $BINARY ($(du -h "$BINARY" | cut -f1))"
echo "Pck     : $PCK ($(du -h "$PCK" | cut -f1))"

"$SNAP_DIR/build-snap.sh" "$@"
