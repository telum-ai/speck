#!/usr/bin/env bash
set -euo pipefail

# Canonical-flow baseline guard: protects tests/eval/skill-routing/baseline.json
# and .speck/reference/skill-routing-cases.json (U4: the cases file carries
# minimum_accuracy and every routing prompt and used to be unguarded — an
# edit there needed no flow-baseline-change-approved label). A base commit
# missing a guarded path is bootstrap and passes unlabeled.
#
# This script intentionally carries its own full enforcement logic rather
# than delegating to (or sharing decision logic with)
# tests/eval/semantic-conservation/guard-baseline-change.sh, and that script
# does not delegate here either. This file is NOT in
# tests/eval/semantic-conservation/baseline.json's protected_files, so an
# edit to it carries no tamper-evidence for the trusted pull_request_target
# job (.github/workflows/canonical-flow-baseline.yml) — a prior consolidated
# version routed the protected semantic-conservation guard's enforcement
# through this unprotected file, which let that edit-here-neuter-there path
# go undetected. Keep the two guards independent even though it duplicates
# ~20 lines; do not re-consolidate without also adding this file's path to
# semantic-conservation's protected_files (integrator-owned).
#
# usage: guard-baseline-change.sh <base-sha> [head-sha]
BASE_SHA="${1:?usage: guard-baseline-change.sh <base-sha> [head-sha]}"
HEAD_SHA="${2:-HEAD}"
APPROVED="${FLOW_BASELINE_APPROVED:-false}"

for BASELINE_PATH in \
  tests/eval/skill-routing/baseline.json \
  .speck/reference/skill-routing-cases.json
do
  if ! git cat-file -e "$BASE_SHA:$BASELINE_PATH" 2>/dev/null; then
    echo "canonical-flow baseline ($BASELINE_PATH): bootstrap (no baseline on PR base)"
    continue
  fi

  if git diff --quiet "$BASE_SHA...$HEAD_SHA" -- "$BASELINE_PATH"; then
    echo "canonical-flow baseline ($BASELINE_PATH): unchanged"
    continue
  fi

  if [[ "$APPROVED" == "true" ]]; then
    echo "canonical-flow baseline ($BASELINE_PATH): externally approved"
    continue
  fi

  echo "CANONICAL_FLOW_BASELINE_CHANGE.P1: baseline changed without the flow-baseline-change-approved PR label ($BASELINE_PATH)" >&2
  exit 1
done
