#!/usr/bin/env bash
# Builds the snap.
#
# Guards against a permission bug seen on this machine: if snapcraft is
# invoked with a restrictive umask (e.g. 077), the package's internal
# "snap/" metadata directory (which holds the gnome extension's
# command-chain/desktop-launch launcher and gui/) comes out mode 700
# (root-only) instead of 755, which makes the app fail with:
#   cannot snap-exec: cannot exec ".../snap/command-chain/desktop-launch": permission denied
#
# The fix is to force a sane umask *before* calling snapcraft, so the
# output of `snapcraft pack` is already correct. Do NOT post-process/repack
# the resulting .snap (e.g. unsquashfs + mksquashfs) even to fix permissions
# — the Snap Store rejects re-packed snaps on `snapcraft upload` with
# "checksums do not match. Please ensure the snap is created with
# 'snapcraft pack <DIR>'", so the file must come straight out of snapcraft.
#
# Usage:
#   ./build-snap.sh            # pack
#   ./build-snap.sh --install  # pack + (re)install locally with --dangerous
set -euo pipefail
umask 022

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

yaml_field() {
  # Extract a top-level "key: value" from snapcraft.yaml, stripping inline
  # comments and surrounding quotes/whitespace.
  grep -m1 "^$1:" snapcraft.yaml | sed "s/^$1:\s*//" | sed 's/#.*//' | tr -d '"'\''' | xargs
}
SNAP_NAME="$(yaml_field name)"
VERSION="$(yaml_field version)"
SNAP_FILE="${SNAP_NAME}_${VERSION}_amd64.snap"

echo "==> Packing ${SNAP_FILE} with snapcraft (umask $(umask))..."
snapcraft pack --output "${SNAP_FILE}"

echo "==> Verifying permissions..."
# Flag anything others can't read, and dirs/executables others can't traverse/exec.
BAD_PERMS="$(unsquashfs -ll "${SNAP_FILE}" 2>/dev/null | awk '
  { perm=$1 }
  perm ~ /^d/ && substr(perm,10,1) != "x" { print; next }
  perm ~ /^-/ {
    other_r = substr(perm,8,1)
    owner_x = substr(perm,4,1)
    other_x = substr(perm,10,1)
    if (other_r != "r") { print; next }
    if (owner_x == "x" && other_x != "x") { print; next }
  }
')"
if [ -n "${BAD_PERMS}" ]; then
  echo "WARNING: unexpected permissions found (do NOT repack manually, re-run with a sane umask instead):"
  echo "${BAD_PERMS}"
  exit 1
else
  echo "OK: all entries are world-readable/executable as expected."
fi

echo "==> Done: ${DIR}/${SNAP_FILE}"

if [ "${1:-}" = "--install" ]; then
  echo "==> Installing (you may be prompted for your password)..."
  sudo snap remove "${SNAP_NAME}" 2>/dev/null || true
  sudo snap install --dangerous "${SNAP_FILE}"
else
  echo "Install with: sudo snap install --dangerous \"${DIR}/${SNAP_FILE}\""
  echo "Upload with:  snapcraft upload \"${DIR}/${SNAP_FILE}\" --release=stable"
fi
