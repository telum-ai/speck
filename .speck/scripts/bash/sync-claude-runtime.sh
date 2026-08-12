#!/usr/bin/env bash
# Sync skill trees only. Do NOT symlink agents — those are generated per-harness
# by `npm run gen-agents` (see packages/cli/lib/generate-agents.js).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SRC="$ROOT/.cursor/skills"

if [ ! -d "$SRC" ]; then
  echo "Missing source directory: $SRC" >&2
  exit 1
fi

symlink_skills() {
  local dest="$1"
  local link_target="$2"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  ln -s "$link_target" "$dest"
  echo "Symlinked $dest → $link_target"
}

symlink_skills "$ROOT/.claude/skills" "../.cursor/skills"
symlink_skills "$ROOT/.codex/skills" "../.cursor/skills"
symlink_skills "$ROOT/.agents/skills" "../.cursor/skills"

if [ -L "$ROOT/.claude/agents" ] || [ -L "$ROOT/.codex/agents" ]; then
  echo "WARN: .claude/agents or .codex/agents is a symlink — run npm run gen-agents to restore generated agent defs" >&2
fi

echo "Skill symlinks up to date (agents left untouched)"
