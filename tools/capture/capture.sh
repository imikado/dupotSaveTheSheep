#!/bin/bash
# Enregistre une partie pilotée automatiquement (capture.gd, Movie Maker de
# Godot) puis en extrait :
#   - les screenshots     export/Linux/screenshots/*.png (1440x810)
#   - le GIF de promotion export/promo/save_the_sheep.gif (720x405)
#
# La partie est reproductible (temps fixe à 30 images/s) : les numéros
# d'images ci-dessous désignent toujours le même moment. Après un changement
# de gameplay, vérifier les images et ajuster ces numéros si besoin.
#
# Usage : ./tools/capture/capture.sh [dossier_images]
#   dossier_images : réutilise un enregistrement existant (f*.png) au lieu de
#                    relancer la partie, ou y garde le nouvel enregistrement
#                    s'il n'existe pas encore
set -e

cd "$(dirname "$0")/../.."

GODOT="${GODOT:-$(command -v godot || echo "$HOME/apps/Godot_v4.7.2-stable_linux.x86_64")}"
FPS=30
SIZE="1440x810"
SCREENSHOTS_DIR="export/Linux/screenshots"
GIF="export/promo/save_the_sheep.gif"

command -v ffmpeg >/dev/null || { echo "ffmpeg est requis" >&2; exit 1; }

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
FRAMES_DIR="${1:-$WORK_DIR}"

if [ ! -e "$FRAMES_DIR/f00000000.png" ]; then
	if [ ! -x "$GODOT" ]; then
		echo "Godot introuvable ($GODOT) : définir la variable GODOT" >&2
		exit 1
	fi
	mkdir -p "$FRAMES_DIR"
	# Enregistrement (fenêtre visible : le Movie Maker a besoin du rendu)
	"$GODOT" --path . --resolution "$SIZE" --fixed-fps "$FPS" \
		--write-movie "$FRAMES_DIR/f.png" -s "$PWD/tools/capture/capture.gd"
fi

frame() { printf "%s/f%08d.png" "$FRAMES_DIR" "$1"; }

# Screenshots : nom -> numéro d'image
declare -A SHOTS=(
	[menu]=60
	[level_01_start]=204
	[level_01_gate]=300
	[level_01_trex]=498
	[bonus_level]=1218
	[menu_two_players]=1680
	[level_01_two_players]=2040
	[bonus_level_two_players]=2420
)
mkdir -p "$SCREENSHOTS_DIR"
for name in "${!SHOTS[@]}"; do
	cp "$(frame "${SHOTS[$name]}")" "$SCREENSHOTS_DIR/$name.png"
done

# GIF : extraits communs avec la vidéo YouTube (demo_segments.sh)
source tools/capture/demo_segments.sh
LIST="$WORK_DIR/gif.txt"
: > "$LIST"
for segment in $DEMO_SEGMENTS; do
	first=$(awk "BEGIN { print int(${segment%:*} * $FPS + 0.5) }")
	last=$(awk "BEGIN { print int(${segment#*:} * $FPS + 0.5) }")
	for ((i = first; i < last; i += 2)); do
		echo "file '$(frame "$i")'" >> "$LIST"
	done
done
mkdir -p "$(dirname "$GIF")"
ffmpeg -v error -y -f concat -safe 0 -r 15 -i "$LIST" \
	-vf "scale=720:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=none" \
	"$GIF"

echo "Screenshots : $SCREENSHOTS_DIR"
echo "GIF         : $GIF ($(du -h "$GIF" | cut -f1))"
