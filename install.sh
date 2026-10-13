#!/bin/bash
# Installs the reverse-engineering-shield skill into an agent skills directory.
# Usage: install.sh [--dir <skills-dir>] [--ref <git-ref>] [--dry-run]
set -eu
DIR="$HOME/.claude/skills"
REF="main"
DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR=$2; shift 2 ;;
    --ref) REF=$2; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

NAME=reverse-engineering-shield
URL="https://codeload.github.com/ChosingDept/$NAME/tar.gz/$REF"
DEST="$DIR/$NAME"
echo "skill:       $NAME ($REF)"
echo "destination: $DEST"
[ "$DRY" = 1 ] && { echo "dry run: nothing written"; exit 0; }

TMP=$(mktemp -d "${TMPDIR:-/tmp}/res-install.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$URL" | tar -xz -C "$TMP"
SRC=$(find "$TMP" -type d -path "*/.agents/skills/$NAME" | head -1)
[ -n "$SRC" ] || { echo "skill folder not found in the archive" >&2; exit 1; }

mkdir -p "$DIR"
if [ -d "$DEST" ]; then
  mv "$DEST" "$DEST.bak.$(date +%Y%m%d%H%M%S)"
  echo "previous version kept as $DEST.bak.*"
fi
cp -R "$SRC" "$DEST"
chmod +x "$DEST/scripts/audit.sh"
echo "installed. Restart your agent so it loads the skill."
