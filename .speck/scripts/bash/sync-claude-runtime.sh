#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

sync_dir() {
  local name="$1"
  local src="$ROOT/.cursor/$name"
  local dest="$ROOT/.claude/$name"

  if [ ! -d "$src" ]; then
    echo "❌ Missing source directory: $src" >&2
    exit 1
  fi

  mkdir -p "$ROOT/.claude"
  rm -rf "$dest"
  mkdir -p "$dest"
  rsync -a --delete "$src/" "$dest/"
  echo "✅ Synced .claude/$name from .cursor/$name"
}

sync_dir commands
sync_dir agents

echo "✅ Claude runtime mirrors are up to date"
