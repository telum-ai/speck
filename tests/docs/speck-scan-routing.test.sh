#!/usr/bin/env bash
# SKILL.test.sh (speck-scan)
#
# THE DEFECT this pins: this PR swept /audit, /larp, /recheck to their speck-
# prefixed names and added _corpus_budget_lib.py's SHORT_ROUTE_REPLACEMENTS
# lint to keep them swept, but left /scan unswept in the very skill that PR
# edited (this file). .cursor/skills/ has speck-scan, project-scan, epic-scan,
# story-scan — no bare `scan` skill — so an agent following the Purpose line
# or the completion banner and invoking /scan gets no skill. Run directly:
# bash .cursor/skills/speck-scan/SKILL.test.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
SKILL="$ROOT/.cursor/skills/speck-scan/SKILL.md"

FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }

[[ -f "$SKILL" ]] || { echo "  ✗ speck-scan/SKILL.md not found at $SKILL"; exit 1; }

echo "── speck-scan/SKILL.md: no stale bare /scan route"

# A bare "/scan" (not "/speck-scan", "/project-scan", "/epic-scan", "/story-scan")
# is the retired, unresolvable route. Exclude the "Compatibility aliases" line's
# legitimate mentions of /project-scan /epic-scan /story-scan by requiring the
# slash be a non-word boundary before "scan".
if grep -Eq '(?<![A-Za-z0-9._/-])/scan(?![-/A-Za-z0-9])' "$SKILL" 2>/dev/null; then
  fail "still references bare /scan (grep -P)"
elif grep -Eq '(^|[^A-Za-z0-9._/-])/scan([^-/A-Za-z0-9]|$)' "$SKILL"; then
  fail "still references bare /scan"
else
  pass "no bare /scan reference remains"
fi

if grep -Fq '/speck-scan' "$SKILL"; then
  pass "references the live /speck-scan route"
else
  fail "does not reference /speck-scan anywhere"
fi

if [[ "$FAILED" == 0 ]]; then
  echo "✅ speck-scan/SKILL.md: all tests passed"
else
  echo "❌ speck-scan/SKILL.md: FAILURES"
  exit 1
fi
