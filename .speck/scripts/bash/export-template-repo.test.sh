#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'find "$TMP" -depth -mindepth 1 -delete; rmdir "$TMP"' EXIT
OUT="$TMP/export"

bash "$ROOT/.speck/scripts/bash/export-template-repo.sh" --out "$OUT" --json >/dev/null

for required in \
  AGENTS.md \
  CLAUDE.md \
  .speck/reference/canonical-routing.md \
  .speck/scripts/graph/speck_graph.py \
  .speck/templates/project/project-template.md \
  .cursor/skills/speck/SKILL.md \
  .claude/agents/speck-auditor.md \
  .codex/agents/speck-auditor.toml; do
  [[ -e "$OUT/$required" ]] || { echo "missing export path: $required" >&2; exit 1; }
done

for excluded in tests/eval docs/history .speck/eval .speck/feedback .speck/patterns; do
  [[ ! -e "$OUT/$excluded" ]] || { echo "meta path leaked into export: $excluded" >&2; exit 1; }
done

[[ -L "$OUT/.claude/skills" ]] || { echo ".claude/skills must be a symlink" >&2; exit 1; }
[[ -L "$OUT/.codex/skills" ]] || { echo ".codex/skills must be a symlink" >&2; exit 1; }
[[ -L "$OUT/.agents/skills" ]] || { echo ".agents/skills must be a symlink" >&2; exit 1; }
[[ ! -L "$OUT/.claude/agents" ]] || { echo ".claude/agents must be generated files" >&2; exit 1; }
[[ ! -L "$OUT/.codex/agents" ]] || { echo ".codex/agents must be generated files" >&2; exit 1; }

echo "export-template-repo tests passed"
