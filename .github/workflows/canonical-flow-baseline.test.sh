#!/usr/bin/env bash
# Regression test for .github/workflows/canonical-flow-baseline.yml
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKFLOW="$ROOT/.github/workflows/canonical-flow-baseline.yml"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[[ -f "$WORKFLOW" ]] || fail "workflow file not found: $WORKFLOW"

# The label-approval gate (FLOW_BASELINE_APPROVED) is a snapshot of the
# triggering event's payload. Without `labeled`/`unlabeled` in the trigger's
# `types:`, adding or removing the approval label after the PR is opened
# never re-runs the guard, so the gate is either unreachable or goes stale.
on_block="$(awk '/^on:/{flag=1; next} /^[a-zA-Z]/{flag=0} flag' "$WORKFLOW")"
echo "$on_block" | grep -q "pull_request_target:" \
  || fail "expected pull_request_target trigger, got:\n$on_block"

types_line="$(echo "$on_block" | grep -A1 "pull_request_target:" | tail -n1)"
echo "$types_line" | grep -q "types:" \
  || fail "pull_request_target has no 'types:' list (defaults to opened/synchronize/reopened only, excluding labeled/unlabeled): $types_line"

for required_type in opened synchronize reopened labeled unlabeled; do
  echo "$types_line" | grep -q "$required_type" \
    || fail "pull_request_target types: is missing '$required_type': $types_line"
done

echo "PASS: canonical-flow-baseline.yml re-evaluates on labeled/unlabeled"
