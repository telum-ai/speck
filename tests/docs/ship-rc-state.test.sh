#!/usr/bin/env bash
# ship-rc.test.sh
#
# THE DEFECT this pins: project-validate/references/states/ship-rc.md claims
# the README + PROFILE-drift gate is "required (post-write)" — but for
# project-validate the actual mechanism is a STOP gate inside spine.md's
# "## 3. Pre-validate gates (STOP on fail)" section (`profile-drift-check.sh
# --claim "$claimed_state"`, "Any PROFILE_DRIFT.P1 -> STOP"), run BEFORE the
# report is written, not after. project-validate/references/post-write.md
# never mentions profile-drift-check or PROFILE at all — it only runs the
# felt-axis/taste-axis validators and writes the three project outputs. An
# agent trusting the "(post-write)" label looks for the PROFILE gate in the
# wrong phase of the flow and can walk straight past a real STOP gate.
#
# (This is the sibling of the byte-identical story-validate/epic-validate
# copies of this file, out of this lane's ownership — see the lane's
# handoffs for that cross-file duplication. This test only pins the label
# accuracy of the ONE file this lane owns.)
#
# Run directly: bash .cursor/skills/project-validate/references/states/ship-rc.test.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
SHIP_RC="$ROOT/.cursor/skills/project-validate/references/states/ship-rc.md"
SPINE="$ROOT/.cursor/skills/project-validate/references/spine.md"
POST_WRITE="$ROOT/.cursor/skills/project-validate/references/post-write.md"

FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }

[[ -f "$SHIP_RC" ]] || { echo "  ✗ ship-rc.md not found at $SHIP_RC"; exit 1; }
[[ -f "$SPINE" ]] || { echo "  ✗ spine.md not found at $SPINE"; exit 1; }
[[ -f "$POST_WRITE" ]] || { echo "  ✗ post-write.md not found at $POST_WRITE"; exit 1; }

profile_line="$(grep -F 'profile-drift-check' "$SHIP_RC" || true)"
if [[ -z "$profile_line" ]]; then
  fail "ship-rc.md no longer names the profile-drift-check gate at all"
else
  pass "ship-rc.md names the profile-drift-check gate"
fi

echo "── project-validate/states/ship-rc.md: phase label matches where the gate actually lives"

pre_validate_block="$(awk '/^## 3\. Pre-validate gates/{flag=1; next} /^## /{flag=0} flag' "$SPINE")"
gate_is_pre_validate=0
grep -Fq 'profile-drift-check' <<<"$pre_validate_block" && gate_is_pre_validate=1
gate_is_post_write=0
grep -Fq 'profile-drift-check' "$POST_WRITE" && gate_is_post_write=1

if grep -Fq '(post-write)' "$SHIP_RC"; then
  if [[ "$gate_is_post_write" == 1 ]]; then
    pass "labeled (post-write) and post-write.md really runs the gate"
  else
    fail "labeled (post-write) but post-write.md never mentions profile-drift-check — the real gate is spine.md's Pre-validate gates section"
  fi
elif grep -Fq '(pre-validate)' "$SHIP_RC"; then
  if [[ "$gate_is_pre_validate" == 1 ]]; then
    pass "labeled (pre-validate) and spine.md's Pre-validate gates section really runs the gate"
  else
    fail "labeled (pre-validate) but spine.md's Pre-validate gates section never mentions profile-drift-check"
  fi
else
  fail "ship-rc.md's PROFILE-drift line carries no recognizable phase label"
fi

if [[ "$FAILED" == 0 ]]; then
  echo "✅ project-validate/states/ship-rc.md: all tests passed"
else
  echo "❌ project-validate/states/ship-rc.md: FAILURES"
  exit 1
fi
