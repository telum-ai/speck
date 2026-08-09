#!/usr/bin/env bash
# validate-corpus-budget.sh — Speck v11 always-on / skill-catalog ceilings
# Usage: bash validate-corpus-budget.sh [REPO_ROOT]
set -euo pipefail

ROOT="${1:-}"
if [[ -z "$ROOT" ]]; then
  ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
fi
cd "$ROOT"

AGENTS="$ROOT/AGENTS.md"
SKILLS="$ROOT/.cursor/skills"
GF="$ROOT/.speck/corpus-budget-grandfather.txt"
PY="$ROOT/.speck/scripts/validation/validators/_corpus_budget_lib.py"

MAX_AGENTS_BYTES=16384
MAX_AGENTS_LINES=200
MAX_DESC_CHARS=120
MAX_DESC_SUM=10000
MAX_BODY_LINES=200

fail=0
report() { printf '%s\n' "$*"; }
err() { report "FAIL: $*"; fail=1; }

if [[ ! -f "$AGENTS" ]]; then
  err "AGENTS.md missing"
  exit 1
fi

agents_bytes=$(wc -c < "$AGENTS" | tr -d ' ')
agents_lines=$(wc -l < "$AGENTS" | tr -d ' ')
report "AGENTS.md bytes=$agents_bytes (max $MAX_AGENTS_BYTES) lines=$agents_lines (max $MAX_AGENTS_LINES)"
[[ "$agents_bytes" -le "$MAX_AGENTS_BYTES" ]] || err "AGENTS.md bytes $agents_bytes > $MAX_AGENTS_BYTES"
[[ "$agents_lines" -le "$MAX_AGENTS_LINES" ]] || err "AGENTS.md lines $agents_lines > $MAX_AGENTS_LINES"

if command -v rg >/dev/null 2>&1; then
  if rg -n '^## .*[🧭🧱🏁🚦🎚️📁🗺️📋⚖️🧠🔌🎛️🦾🧪🚨📊🎯📚]' "$AGENTS" >/dev/null 2>&1; then
    err "AGENTS.md has emoji section headers (agent-prose doctrine)"
  fi
fi

# Python does skill catalog checks (portable; no bash4 assoc arrays)
python3 "$PY" "$ROOT" "$MAX_DESC_CHARS" "$MAX_DESC_SUM" "$MAX_BODY_LINES" "$GF" || fail=1

if [[ "$fail" -ne 0 ]]; then
  report "corpus-budget: FAILED"
  exit 1
fi
report "corpus-budget: PASS"
exit 0
