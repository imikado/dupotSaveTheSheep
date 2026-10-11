#!/bin/bash
# Enregistre la partie pilotée automatiquement (capture.gd, Movie Maker de
# Godot) en 1920x1080 avec le son du jeu, puis monte la vidéo de promotion
# YouTube export/promo/save_the_sheep.mp4 :
#   - extraits de la partie : menu, niveau 1 (grille, T-Rex), niveau bonus
#   - écran de fin (titre, liens Flathub / Snap Store / itch.io) sur la
#     musique du menu
#
# La partie est reproductible (temps fixe) : les extraits ci-dessous
# désignent toujours le même moment. Après un changement de gameplay,
# vérifier la vidéo et ajuster SEGMENTS si besoin.
#
# Usage : ./tools/capture/promo_video.sh [dossier_images]
#   dossier_images : réutilise un enregistrement existant (f*.png + f.wav)
#                    au lieu de relancer la partie (~5 min)
set -e

cd "$(dirname "$0")/../.."

GODOT="${GODOT:-$(command -v godot || echo "$HOME/apps/Godot_v4.7.2-stable_linux.x86_64")}"
FPS=60
# Extraits (secondes) : menu + début du niveau 1 + grille, combat contre le
# T-Rex (début, puis fin), niveau bonus
SEGMENTS="0:13 14:19 24.5:28.5 34:49"
END_CARD=7
FONT="src/UI/Controls/Shared/Pixeled.ttf"
END_MUSIC="assets/audio/music/menu.ogg"
VIDEO="export/promo/save_the_sheep.mp4"

command -v ffmpeg >/dev/null || { echo "ffmpeg est requis" >&2; exit 1; }

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

if [ -n "$1" ]; then
	FRAMES_DIR="$1"
else
	if [ ! -x "$GODOT" ]; then
		echo "Godot introuvable ($GODOT) : définir la variable GODOT" >&2
		exit 1
	fi
	if [ -e override.cfg ]; then
		echo "override.cfg existe déjà : le supprimer d'abord" >&2
		exit 1
	fi
	# La taille de fenêtre du projet (1440x810) l'emporte sur --resolution :
	# override.cfg temporaire pour enregistrer en 1920x1080 (viewport x4)
	trap 'rm -rf "$WORK_DIR" override.cfg' EXIT
	cat > override.cfg <<-EOF
		[display]

		window/size/window_width_override=1920
		window/size/window_height_override=1080
		window/size/borderless=true
	EOF
	FRAMES_DIR="$WORK_DIR"
	# Enregistrement (fenêtre visible : le Movie Maker a besoin du rendu).
	# Avec une sortie .png, Godot écrit aussi le son dans f.wav.
	"$GODOT" --path . --fixed-fps "$FPS" \
		--write-movie "$FRAMES_DIR/f.png" -s "$PWD/tools/capture/capture.gd"
	rm -f override.cfg
fi

calc() { awk "BEGIN { print $1 }"; }

# Montage des extraits (coupes franches, micro-fondus sonores anti-clic)
COUNT=$(echo $SEGMENTS | wc -w)
GRAPH="[0:v]split=$COUNT$(for i in $(seq $COUNT); do printf "[sv%s]" "$i"; done);"
GRAPH+="[1:a]aformat=sample_rates=48000:channel_layouts=stereo,asplit=$COUNT$(for i in $(seq $COUNT); do printf "[sa%s]" "$i"; done);"
CONCAT=""
GAME_LENGTH=0
i=0
for segment in $SEGMENTS; do
	i=$((i + 1))
	start=${segment%:*}
	end=${segment#*:}
	length=$(calc "$end - $start")
	GRAPH+="[sv$i]trim=start=$start:end=$end,setpts=PTS-STARTPTS[v$i];"
	GRAPH+="[sa$i]atrim=start=$start:end=$end,asetpts=PTS-STARTPTS,afade=in:d=0.05,afade=out:st=$(calc "$length - 0.05"):d=0.05[a$i];"
	CONCAT+="[v$i][a$i]"
	GAME_LENGTH=$(calc "$GAME_LENGTH + $length")
	LAST_END=$end
done
TOTAL=$(calc "$GAME_LENGTH + $END_CARD - 1")
CARD_FRAME="$(printf "%s/f%08d.png" "$FRAMES_DIR" "$(calc "int($LAST_END * $FPS) - 1")")"

# Textes de l'écran de fin (fichiers : pas d'échappement des « : »)
echo "SAVE THE SHEEP" > "$WORK_DIR/title.txt"
echo "FREE AND OPEN SOURCE" > "$WORK_DIR/free.txt"
echo "LINUX : FLATHUB - SNAP STORE" > "$WORK_DIR/linux.txt"
echo "PLAY IN YOUR BROWSER ON ITCH.IO" > "$WORK_DIR/web.txt"
echo "dupot-org.itch.io/save-the-sheep" > "$WORK_DIR/url.txt"

# Tailles relatives à la hauteur de l'image (1080 en temps normal)
HEIGHT=$(ffprobe -v error -select_streams v -show_entries stream=height -of csv=p=0 "$CARD_FRAME")
text() { # fichier taille couleur y (taille et y en fraction de la hauteur)
	echo "drawtext=fontfile=$FONT:textfile=$WORK_DIR/$1:fontsize=$(calc "int($HEIGHT * $2)"):fontcolor=$3:x=(w-text_w)/2:y=$(calc "int($HEIGHT * $4)"):borderw=$(calc "int($HEIGHT / 180)"):bordercolor=black"
}

# Partie en fondu depuis le noir, fondu enchaîné vers l'écran de fin (image
# floutée et assombrie), fondu vers le noir à la fin
GRAPH+="${CONCAT}concat=n=$COUNT:v=1:a=1[gamev][gamea];
	[gamev]fps=$FPS,settb=1/$FPS,format=yuv420p,fade=in:d=0.5[game];
	[2:v]gblur=sigma=14,eq=brightness=-0.3,
		$(text title.txt 0.09 white 0.16),
		$(text free.txt 0.042 0xFFC83C 0.40),
		$(text linux.txt 0.037 white 0.55),
		$(text web.txt 0.037 white 0.66),
		$(text url.txt 0.033 0xFFC83C 0.76),
		fps=$FPS,settb=1/$FPS,format=yuv420p[card];
	[game][card]xfade=transition=fade:duration=1:offset=$(calc "$GAME_LENGTH - 1"),
		fade=out:st=$(calc "$TOTAL - 1"):d=1[v];
	[3:a]atrim=duration=$END_CARD,aformat=sample_rates=48000:channel_layouts=stereo[music];
	[gamea][music]acrossfade=d=1,afade=out:st=$(calc "$TOTAL - 1.5"):d=1.5[a]"

mkdir -p "$(dirname "$VIDEO")"
ffmpeg -v error -stats -y \
	-framerate "$FPS" -i "$FRAMES_DIR/f%08d.png" \
	-i "$FRAMES_DIR/f.wav" \
	-loop 1 -framerate "$FPS" -t "$END_CARD" -i "$CARD_FRAME" \
	-i "$END_MUSIC" \
	-filter_complex "$GRAPH" \
	-map "[v]" -map "[a]" -r "$FPS" \
	-c:v libx264 -preset slow -crf 18 -profile:v high -pix_fmt yuv420p \
	-c:a aac -b:a 192k -movflags +faststart \
	"$VIDEO" || {
	# L'enregistrement est long : on le garde pour relancer seulement le montage
	trap - EXIT
	rm -f override.cfg
	echo "Échec du montage : enregistrement conservé, relancer avec $0 $FRAMES_DIR" >&2
	exit 1
}

echo "Vidéo : $VIDEO (${TOTAL} s, $(du -h "$VIDEO" | cut -f1))"
