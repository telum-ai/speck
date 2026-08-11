#!/usr/bin/env bash
set -euo pipefail

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
