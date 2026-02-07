#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SRC="$ROOT/.cursor/commands"
DEST="$ROOT/.claude/commands"

if [ ! -d "$SRC" ]; then
  echo "❌ Missing source directory: $SRC" >&2
  exit 1
fi

mkdir -p "$ROOT/.claude"
rm -rf "$DEST"
mkdir -p "$DEST"

# Portable copy preserving structure
rsync -a --delete "$SRC/" "$DEST/"

echo "✅ Synced .claude/commands from .cursor/commands"
