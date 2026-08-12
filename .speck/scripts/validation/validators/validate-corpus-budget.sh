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
GF="$ROOT/.speck/corpus-budget-grandfather.txt"
PY="$ROOT/.speck/scripts/validation/validators/_corpus_budget_lib.py"
BUDGETS="$ROOT/.speck/reference/skill-load-budgets.json"

MAX_DESC_CHARS=120
MAX_DESC_SUM=10000
MAX_BODY_LINES=200

fail=0
report() { printf '%s\n' "$*"; }
err() { report "FAIL: $*"; fail=1; }

# The AGENTS.md ceiling is declared once, in skill-load-budgets.json's
# `ceilings` object — not restated as a literal in this script, ADR-0001,
# docs/history/north-stars/v11.md, CHANGELOG.md and
# packages/cli/lib/agent-model-tiers.test.js, where the five copies could
# (and did) drift apart. Fall back to the historical defaults only when the
# registry has NO ceilings block at all, so minimal test fixtures without a
# full .speck/reference/skill-load-budgets.json keep working. A ceilings
# block that IS present but malformed (wrong type, a missing key, non-
# positive) is a declared-but-unenforced ceiling — the same "gate reports a
# verdict it did not compute from the declared source" class this registry
# was built to close — so that case is a loud FAIL, never a silent
# fall-back to the historical default.
MAX_AGENTS_BYTES=16384
MAX_AGENTS_LINES=200
if [[ -f "$BUDGETS" ]]; then
  ceilings="$(python3 -c '
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except (OSError, ValueError):
    sys.exit(0)
c = data.get("ceilings")
if c is None:
    sys.exit(0)
if not isinstance(c, dict):
    print("ERROR skill-load-budgets.json ceilings must be an object")
    sys.exit(0)
b, l = c.get("agents_bytes"), c.get("agents_lines")
valid_b = isinstance(b, int) and not isinstance(b, bool) and b > 0
valid_l = isinstance(l, int) and not isinstance(l, bool) and l > 0
if valid_b and valid_l:
    print("OK", b, l)
else:
    print(
        "ERROR skill-load-budgets.json ceilings.agents_bytes and "
        "ceilings.agents_lines must both be present positive integers "
        f"(got agents_bytes={b!r} agents_lines={l!r})"
    )
' "$BUDGETS")"
  case "$ceilings" in
    OK\ *)
      read -r _ MAX_AGENTS_BYTES MAX_AGENTS_LINES <<<"$ceilings"
      ;;
    ERROR*)
      err "${ceilings#ERROR }"
      ;;
    *)
      : # no ceilings block declared at all — keep the historical defaults
      ;;
  esac
fi

if [[ ! -f "$AGENTS" ]]; then
  err "AGENTS.md missing"
  exit 1
fi

agents_bytes=$(wc -c < "$AGENTS" | tr -d ' ')
agents_lines=$(wc -l < "$AGENTS" | tr -d ' ')
report "AGENTS.md bytes=$agents_bytes (max $MAX_AGENTS_BYTES) lines=$agents_lines (max $MAX_AGENTS_LINES)"
[[ "$agents_bytes" -le "$MAX_AGENTS_BYTES" ]] || err "AGENTS.md bytes $agents_bytes > $MAX_AGENTS_BYTES"
[[ "$agents_lines" -le "$MAX_AGENTS_LINES" ]] || err "AGENTS.md lines $agents_lines > $MAX_AGENTS_LINES"

# AGENTS.md emoji-header + agent-prose linting lives in the Python half
# (lint_agent_prose), which every host has via python3 — no optional
# ripgrep dependency, and no second, drifting copy of the emoji set.
# Python does skill catalog checks (portable; no bash4 assoc arrays)
python3 "$PY" "$ROOT" "$MAX_DESC_CHARS" "$MAX_DESC_SUM" "$MAX_BODY_LINES" "$GF" || fail=1

if [[ "$fail" -ne 0 ]]; then
  report "corpus-budget: FAILED"
  exit 1
fi
report "corpus-budget: PASS"
exit 0
