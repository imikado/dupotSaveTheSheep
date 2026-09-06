#!/usr/bin/env bash
# Syncs the `version:` field in snapcraft.yaml from the game's own version
# source of truth: src/Common/Autoload/GlobalVersion.gd (`var version = "X.Y"`).
#
# Usage: ./update-version.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DIR/../../.." && pwd)"
GLOBAL_VERSION_GD="$PROJECT_ROOT/src/Common/Autoload/GlobalVersion.gd"
SNAPCRAFT_YAML="$DIR/snapcraft.yaml"

NEW_VERSION="$(grep -m1 -E '^\s*var version\s*=' "$GLOBAL_VERSION_GD" | sed -E 's/.*=\s*"([^"]+)".*/\1/')"
if [ -z "$NEW_VERSION" ]; then
  echo "ERROR: could not read 'var version = \"...\"' from $GLOBAL_VERSION_GD" >&2
  exit 1
fi

CURRENT_VERSION="$(grep -m1 '^version:' "$SNAPCRAFT_YAML" | sed -E 's/^version:\s*"?([^"#[:space:]]*)"?.*/\1/')"

if [ "$NEW_VERSION" = "$CURRENT_VERSION" ]; then
  echo "snapcraft.yaml already at version ${NEW_VERSION}, nothing to do."
  exit 0
fi

sed -i -E "s/^version:\s*\"[^\"]*\"/version: \"${NEW_VERSION}\"/" "$SNAPCRAFT_YAML"
echo "Updated snapcraft.yaml version: ${CURRENT_VERSION} -> ${NEW_VERSION}"
