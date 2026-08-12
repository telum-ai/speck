#!/usr/bin/env bash
set -euo pipefail

# Full standalone enforcement. This file is sha256-protected in
# tests/eval/semantic-conservation/baseline.json's protected_files, which is
# what makes tampering it visible to the trusted pull_request_target job
# (.github/workflows/canonical-flow-baseline.yml -> the "Evaluate candidate
# with trusted semantic runner" step, which flags any protected file whose
# content changed without a baseline update). Do NOT route this guard's
# decision logic through tests/eval/skill-routing/guard-baseline-change.sh
# (or any other unprotected file): that file is not in protected_files, so an
# edit there would silently change this guard's behavior with nothing to
# catch it — this restores from exactly that regression. Bootstrap policy is
# stricter than the canonical-flow guard's: a base commit missing this
# baseline still requires the flow-baseline-change-approved label.
#
# usage: guard-baseline-change.sh <base-sha> [head-sha]
BASE_SHA="${1:?usage: guard-baseline-change.sh <base-sha> [head-sha]}"
HEAD_SHA="${2:-HEAD}"
BASELINE_PATH="tests/eval/semantic-conservation/baseline.json"
APPROVED="${FLOW_BASELINE_APPROVED:-false}"

if ! git cat-file -e "$BASE_SHA:$BASELINE_PATH" 2>/dev/null; then
  if [[ "$APPROVED" == "true" ]]; then
    echo "semantic-conservation baseline: externally approved bootstrap"
    exit 0
  fi
  echo "SEMANTIC_CONSERVATION_BASELINE_CHANGE.P1: baseline introduction requires the flow-baseline-change-approved PR label" >&2
  exit 1
fi

if git diff --quiet "$BASE_SHA...$HEAD_SHA" -- "$BASELINE_PATH"; then
  echo "semantic-conservation baseline: unchanged"
  exit 0
fi

if [[ "$APPROVED" == "true" ]]; then
  echo "semantic-conservation baseline: externally approved"
  exit 0
fi

echo "SEMANTIC_CONSERVATION_BASELINE_CHANGE.P1: baseline changed without the flow-baseline-change-approved PR label" >&2
exit 1
