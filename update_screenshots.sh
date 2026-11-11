#!/bin/bash
# Met à jour les captures d'écran de Save the Sheep
# (export/Linux/screenshots/*.png) et leurs URLs dans l'appdata Flathub.
#
# Usage :
#   ./update_screenshots.sh capture   # partie pilotée automatiquement (tools/capture/capture.sh) :
#                                     # régénère les captures et le GIF promo (ffmpeg requis)
#   ./update_screenshots.sh appdata   # après commit + push des captures : pointe les URLs de
#                                     # l'appdata vers le dernier commit qui les a modifiées
#                                     # (ordre et légendes de l'appdata conservés)
set -e

cd "$(dirname "$0")"

SCREENSHOT_DIR="export/Linux/screenshots"
APPDATA="export/Linux/flatpak/org.dupot.savethesheep.appdata.xml"
REPO_RAW_URL="https://raw.githubusercontent.com/imikado/dupotSaveTheSheep"

capture() {
	./tools/capture/capture.sh

	echo
	echo "Ensuite : commit + push, puis ./update_screenshots.sh appdata"
}

appdata() {
	local commit
	commit="$(git log -1 --format=%H -- "$SCREENSHOT_DIR")"
	if [ -z "$commit" ]; then
		echo "Aucun commit ne contient $SCREENSHOT_DIR" >&2
		exit 1
	fi
	if [ -n "$(git status --porcelain -- "$SCREENSHOT_DIR")" ]; then
		echo "Captures modifiées non commitées dans $SCREENSHOT_DIR : les commiter d'abord" >&2
		exit 1
	fi

	# Les URLs raw.githubusercontent.com doivent exister côté GitHub
	git fetch --quiet origin
	if [ -z "$(git branch -r --contains "$commit")" ]; then
		echo "Le commit $commit n'est pas encore poussé sur origin" >&2
		exit 1
	fi

	# Remplace <ref> (hash ou branche) dans .../dupotSaveTheSheep/<ref>/export/Linux/screenshots/
	REPO_RAW_URL="$REPO_RAW_URL" DIR="$SCREENSHOT_DIR" COMMIT="$commit" perl -pi -e \
		's{\Q$ENV{REPO_RAW_URL}\E/[^/]+/\Q$ENV{DIR}\E/}{$ENV{REPO_RAW_URL}/$ENV{COMMIT}/$ENV{DIR}/}g' \
		"$APPDATA"

	# Contrôle : chaque capture référencée doit exister dans le commit
	local file missing=0
	while read -r file; do
		if ! git cat-file -e "$commit:$file" 2>/dev/null; then
			echo "Capture absente du commit $commit : $file" >&2
			missing=1
		fi
	done < <(grep -oP "\Q$REPO_RAW_URL/$commit/\E\K$SCREENSHOT_DIR/[^<]+" "$APPDATA")
	if [ "$missing" -ne 0 ]; then
		exit 1
	fi

	if command -v appstreamcli >/dev/null; then
		appstreamcli validate --no-net "$APPDATA" || true
	fi

	echo "URLs des captures de $APPDATA pointées sur le commit $commit"
}

case "$1" in
	capture) capture ;;
	appdata) appdata ;;
	*)
		sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
		exit 1
		;;
esac
