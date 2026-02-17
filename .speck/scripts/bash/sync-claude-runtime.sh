#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

symlink_dir() {
  local name="$1"
  local src="$ROOT/.cursor/$name"

  if [ ! -d "$src" ]; then
    echo "❌ Missing source directory: $src" >&2
    exit 1
  fi

  for runtime in .claude .codex; do
    local dest="$ROOT/$runtime/$name"
    mkdir -p "$ROOT/$runtime"
    rm -rf "$dest"
    ln -s "../.cursor/$name" "$dest"
    echo "✅ Symlinked $runtime/$name → .cursor/$name"
  done
}

symlink_dir skills
symlink_dir agents

echo "✅ Claude Code and Codex runtime symlinks are up to date"
