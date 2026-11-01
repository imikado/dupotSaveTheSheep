#!/usr/bin/env bash
# Syncs the `version:` field in snapcraft.yaml from the game's own version
# source of truth: project.godot (`config/version="X.Y.Z"`).
#
# Usage: ./update-version.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DIR/../../.." && pwd)"
PROJECT_GODOT="$PROJECT_ROOT/project.godot"
SNAPCRAFT_YAML="$DIR/snapcraft.yaml"

NEW_VERSION="$(grep -m1 -E '^config/version=' "$PROJECT_GODOT" | sed -E 's/.*=\s*"([^"]+)".*/\1/')"
if [ -z "$NEW_VERSION" ]; then
  echo "ERROR: could not read 'config/version=\"...\"' from $PROJECT_GODOT" >&2
  exit 1
fi

CURRENT_VERSION="$(grep -m1 '^version:' "$SNAPCRAFT_YAML" | sed -E 's/^version:\s*"?([^"#[:space:]]*)"?.*/\1/')"

if [ "$NEW_VERSION" = "$CURRENT_VERSION" ]; then
  echo "snapcraft.yaml already at version ${NEW_VERSION}, nothing to do."
  exit 0
fi

sed -i -E "s/^version:\s*\"[^\"]*\"/version: \"${NEW_VERSION}\"/" "$SNAPCRAFT_YAML"
echo "Updated snapcraft.yaml version: ${CURRENT_VERSION} -> ${NEW_VERSION}"
