#!/bin/bash
# Enregistre une partie pilotée automatiquement (capture.gd, Movie Maker de
# Godot) puis en extrait :
#   - les screenshots     export/Linux/screenshots/*.png (1440x810)
#   - le GIF de promotion export/promo/save_the_sheep.gif (720x405)
#
# La partie est reproductible (temps fixe à 30 images/s) : les numéros
# d'images ci-dessous désignent toujours le même moment. Après un changement
# de gameplay, vérifier les images et ajuster ces numéros si besoin.
set -e

cd "$(dirname "$0")/../.."

GODOT="${GODOT:-$(command -v godot || echo "$HOME/apps/Godot_v4.7.2-stable_linux.x86_64")}"
FPS=30
SIZE="1440x810"
SCREENSHOTS_DIR="export/Linux/screenshots"
GIF="export/promo/save_the_sheep.gif"

if [ ! -x "$GODOT" ]; then
	echo "Godot introuvable ($GODOT) : définir la variable GODOT" >&2
	exit 1
fi
command -v ffmpeg >/dev/null || { echo "ffmpeg est requis" >&2; exit 1; }

FRAMES_DIR="$(mktemp -d)"
trap 'rm -rf "$FRAMES_DIR"' EXIT

# Enregistrement (fenêtre visible : le Movie Maker a besoin du rendu)
"$GODOT" --path . --resolution "$SIZE" --fixed-fps "$FPS" \
	--write-movie "$FRAMES_DIR/f.png" -s "$PWD/tools/capture/capture.gd"

frame() { printf "%s/f%08d.png" "$FRAMES_DIR" "$1"; }

# Screenshots : nom -> numéro d'image
declare -A SHOTS=(
	[menu]=60
	[level_01_start]=204
	[level_01_gate]=300
	[level_01_trex]=498
	[bonus_level]=1218
)
mkdir -p "$SCREENSHOTS_DIR"
for name in "${!SHOTS[@]}"; do
	cp "$(frame "${SHOTS[$name]}")" "$SCREENSHOTS_DIR/$name.png"
done

# GIF : menu, niveau 1 (grille, T-Rex), niveau bonus (premier saut)
SEGMENTS="15:75 260:600 1150:1260"
LIST="$FRAMES_DIR/gif.txt"
: > "$LIST"
for segment in $SEGMENTS; do
	for ((i = ${segment%:*}; i < ${segment#*:}; i += 2)); do
		echo "file '$(frame "$i")'" >> "$LIST"
	done
done
mkdir -p "$(dirname "$GIF")"
ffmpeg -v error -y -f concat -safe 0 -r 15 -i "$LIST" \
	-vf "scale=720:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=none" \
	"$GIF"

echo "Screenshots : $SCREENSHOTS_DIR"
echo "GIF         : $GIF ($(du -h "$GIF" | cut -f1))"
