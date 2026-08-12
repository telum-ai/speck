#!/usr/bin/env bash
# epic.test.sh
#
# THE DEFECT this pins: the adjust epic branch instructed the agent to update
# `journey.md`, a filename that is not canonical anywhere in Speck. The
# canonical home for an epic journey map is `user-journey.md`
# (.speck/reference/canonical-routing.md, epic-journey/SKILL.md's writer, and
# every downstream reader: epic-plan, epic-wireframes, story-plan,
# story-ui-spec). `/adjust --level epic` on a UX-heavy epic either splits the
# journey map into a bespoke second file or silently drops the journey delta —
# and violates AGENTS.md's always-on gate: "Never invent filenames under
# `specs/`; read `.speck/reference/canonical-routing.md` when writing an
# artifact." Run directly: bash .cursor/skills/adjust/references/epic.test.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
BRANCH="$ROOT/.cursor/skills/adjust/references/epic.md"

FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }

[[ -f "$BRANCH" ]] || { echo "  ✗ epic.md branch not found at $BRANCH"; exit 1; }

echo "── adjust/references/epic.md: journey artifact name is canonical"

# A bare "journey.md" (not preceded by "user-") is the defect. Bare word-boundary
# match on "journey.md" not preceded by "user-".
if grep -Eq '(^|[^-])\bjourney\.md\b' "$BRANCH"; then
  fail "references a bare journey.md (not canonical anywhere in Speck)"
else
  pass "does not reference a bare journey.md"
fi

if grep -Fq 'user-journey.md' "$BRANCH"; then
  pass "references the canonical user-journey.md"
else
  fail "does not reference user-journey.md, the canonical epic journey map filename"
fi

if [[ "$FAILED" == 0 ]]; then
  echo "✅ adjust/references/epic.md: all tests passed"
else
  echo "❌ adjust/references/epic.md: FAILURES"
  exit 1
fi
