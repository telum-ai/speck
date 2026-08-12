#!/usr/bin/env bash
# ADR-0011-positive-quality-profile-and-entry-routing.test.sh
#
# THE DEFECT this pins: ADR-0011 declares Class "spine + skill-catalog + jit + gate" —
# a catalog expansion (project-profile added, project-readme demoted) AND a gate change
# (PROFILE fails closed) — but shipped with neither the `## Budget delta` nor the
# `## Evidence` section that docs/decisions/TEMPLATE.md makes mandatory and that
# docs/methodology/evolution.md:7-9 requires for exactly those two change classes:
#   "Always-on / catalog expansion requires: budget room or equal retirement ...
#    fail-closed A1-lite candidate-corpus score against the immutable baseline
#    for gate changes."
# No script under .speck/scripts/ or CI enforces ADR structure — this test is the
# only guard, run it directly: bash docs/decisions/ADR-0011-*.test.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
ADR="$ROOT/docs/decisions/ADR-0011-positive-quality-profile-and-entry-routing.md"

FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAILED=1; }

[[ -f "$ADR" ]] || { echo "  ✗ ADR-0011 not found at $ADR"; exit 1; }

echo "── ADR-0011: mandatory TEMPLATE.md sections present"

if grep -Fq '## Budget delta' "$ADR"; then
  pass "has a ## Budget delta section"
else
  fail "missing ## Budget delta (mandatory per docs/decisions/TEMPLATE.md)"
fi

if grep -Fq '## Evidence' "$ADR"; then
  pass "has an ## Evidence section"
else
  fail "missing ## Evidence (mandatory per docs/decisions/TEMPLATE.md)"
fi

echo "── ADR-0011: Budget delta is filled in, not a blank template table"

budget_block="$(awk '/^## Budget delta/{flag=1; next} /^## /{flag=0} flag' "$ADR")"
if [[ -n "$budget_block" ]] && grep -Eq '[0-9]' <<<"$budget_block"; then
  pass "Budget delta table carries real numbers"
else
  fail "Budget delta section is empty or has no measured values"
fi

if grep -Fq 'Equal retirement' <<<"$budget_block" || grep -Fiq 'equal retirement' <<<"$budget_block"; then
  pass "Budget delta states the equal-retirement accounting for the catalog change"
else
  fail "Budget delta does not account for equal retirement (project-profile added / project-readme demoted)"
fi

echo "── ADR-0011: Evidence covers the gate-change requirement (A1-lite vs. immutable baseline)"

evidence_block="$(awk '/^## Evidence/{flag=1; next} /^## /{flag=0} flag' "$ADR")"
if grep -Fiq 'A1-lite' <<<"$evidence_block" && grep -Fiq 'baseline' <<<"$evidence_block"; then
  pass "Evidence cites an A1-lite score against the immutable baseline"
else
  fail "Evidence does not cite a fail-closed A1-lite candidate-corpus score against the immutable baseline"
fi

if [[ "$FAILED" == 0 ]]; then
  echo "✅ ADR-0011: all tests passed"
else
  echo "❌ ADR-0011: FAILURES"
  exit 1
fi
