#!/usr/bin/env bash
# Regression tests for .github/workflows/quality.yml
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKFLOW="$ROOT/.github/workflows/quality.yml"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[[ -f "$WORKFLOW" ]] || fail "workflow file not found: $WORKFLOW"

# Superseded runs (e.g. a rebase-and-fixup session pushing several commits to
# an open PR) must be cancelled, not left to burn a runner slot to completion.
grep -q "^concurrency:" "$WORKFLOW" \
  || fail "workflow has no top-level concurrency: block"
grep -q "cancel-in-progress: *true" "$WORKFLOW" \
  || fail "concurrency block does not set cancel-in-progress: true"

# On branch creation or a force-push to main, github.event.before is the
# all-zeros SHA or an object no longer reachable from any ref. Diffing
# against it unconditionally makes `git diff --check` fatal, turning the
# quality job red with no real whitespace problem.
push_step="$(awk '/Reject whitespace errors in pushed commit/{flag=1} flag{print} flag && /^$/{exit}' "$WORKFLOW")"
[[ -n "$push_step" ]] || fail "could not locate the push whitespace-check step"
echo "$push_step" | grep -Eq '0{40}|ZERO_SHA|zero.?sha' \
  || fail "push whitespace-check step does not guard against the zero SHA on branch creation / force-push:\n$push_step"

echo "PASS: quality.yml has a cancelling concurrency group and guards the zero-SHA push case"
