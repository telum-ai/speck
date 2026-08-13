#!/usr/bin/env bash
# lifecycle-state-reachability.test.sh
#
# THE DEFECT this pins (v11.0.0): the story/epic state ladder and the stop-gates lived ONLY inside
# `.cursor/skills/{story,epic}/SKILL.md`, both of which carry `disable-model-invocation: true`.
# A driving loop — native `/goal`, or the manual check→gap→repair loop — is told by gap-routes.md to
# "resume the story flow at its first missing step", but could not load the skill that defines what
# the steps are or which gates may not be skipped. The autonomous path, the one that most needs a
# stop-gate, was the one path structurally unable to reach one.
#
# The property: the ladder and the stop-gates live in a reference reachable by BOTH drivers, exactly
# once, and every consumer points at it.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
REF="$ROOT/.speck/reference/lifecycle-state.md"
FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }

echo "── lifecycle-state.md exists and is reachable without a user-only skill"
[[ -f "$REF" ]] && pass "the reference exists" || { fail "missing $REF"; exit 1; }

echo "── it carries the load-bearing content"
for needle in "Story states" "Epic states" "Stop-gates" "Anti-patterns"; do
  grep -q "$needle" "$REF" && pass "carries '$needle'" || fail "'$needle' missing from the reference"
done

echo "── every consumer routes to it"
for consumer in \
  ".speck/reference/gap-routes.md" \
  ".cursor/skills/story/SKILL.md" \
  ".cursor/skills/epic/SKILL.md"; do
  if grep -q "lifecycle-state.md" "$ROOT/$consumer"; then
    pass "$consumer routes to the reference"
  else
    fail "$consumer does not route to lifecycle-state.md"
  fi
done

echo "── the goal loop is told it cannot use the user-only orchestrators"
grep -qi "user-only" "$ROOT/.speck/reference/gap-routes.md" \
  && pass "gap-routes states the orchestrators are unreachable to a driving loop" \
  || fail "gap-routes must say why it routes to granular skills"

echo "── ONE source: the skills must not re-carry the ladder they point at"
for skill in .cursor/skills/story/SKILL.md .cursor/skills/epic/SKILL.md; do
  n="$(grep -c 'State = \*\*' "$ROOT/$skill" || true)"
  [[ "$n" -eq 0 ]] && pass "$(basename "$(dirname "$skill")") carries no second copy of the ladder" \
                   || fail "$skill still inlines $n ladder rule(s) — two sources drift"
done

echo "── the reference stays reachable: it must not itself become model-invocation gated"
if grep -rlq "disable-model-invocation: true" "$ROOT/.speck/reference/" 2>/dev/null; then
  fail "a reference file must never be invocation-gated — that recreates the defect"
else
  pass "references carry no invocation gate"
fi

if [[ "$FAILED" == 0 ]]; then
  echo "✅ lifecycle-state reachability: all tests passed"
else
  echo "❌ lifecycle-state reachability: FAILURES"
  exit 1
fi
