#!/usr/bin/env bash
# profile-drift-check.sh — Graded PROFILE drift detection (P1/P2/P3)
#
# Usage: .speck/scripts/profile-drift-check.sh [WORKSPACE_ROOT] [PROJECT_ID]
#
# Exit: 0 no P1, 1 P1 drift found, 2 missing project/README

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=profile-lib.sh
source "$SCRIPT_DIR/profile-lib.sh"

WORKSPACE_ROOT="${1:-$(pwd)}"
PROJECT_ID="${2:-}"
README_PATH="$WORKSPACE_ROOT/README.md"
SPECS_ROOT="$WORKSPACE_ROOT/specs/projects"

PROJECT_ID="$(profile_resolve_project_id "$WORKSPACE_ROOT" "$PROJECT_ID")"
if [[ -z "$PROJECT_ID" ]]; then
  echo "ERROR: No project ID found" >&2
  exit 2
fi

PROJECT_DIR="$SPECS_ROOT/$PROJECT_ID"
CONTRACT="$PROJECT_DIR/product-contract.md"

if [[ ! -f "$README_PATH" ]]; then
  echo "PROFILE_DRIFT.P1: README.md missing at workspace root"
  exit 1
fi

P1=0 P2=0 P3=0

# P3: orphan placeholders
if profile_has_orphan_placeholders "$README_PATH"; then
  echo "PROFILE_DRIFT.P3: README contains unreplaced scaffold placeholders"
  P3=$((P3 + 1))
fi

# P3: footer version stale
SPECK_VER="$(profile_read_speck_version "$WORKSPACE_ROOT")"
if grep -q '<!-- SPECK:START -->' "$README_PATH"; then
  if ! grep -q "speck ${SPECK_VER}" "$README_PATH" && ! grep -q "speck v${SPECK_VER#v}" "$README_PATH"; then
    echo "PROFILE_DRIFT.P3: README footer Speck version stale (expected ${SPECK_VER})"
    P3=$((P3 + 1))
  fi
else
  echo "PROFILE_DRIFT.P1: README lacks SPECK:START..END markers"
  P1=$((P1 + 1))
fi

# P1/P2: one-liner vs paid promise
ONELINER="$(profile_extract_readme_oneliner "$README_PATH")"
PROMISE=""
if [[ -f "$CONTRACT" ]]; then
  PROMISE="$(profile_extract_paid_promise "$CONTRACT")"
fi

if [[ -n "$ONELINER" && -n "$PROMISE" ]]; then
  OVERLAP="$(profile_token_overlap_pct "$ONELINER" "$PROMISE")"
  if [[ "$OVERLAP" -lt 20 ]]; then
    echo "PROFILE_DRIFT.P1: README one-liner unrelated to product-contract Section 1 (${OVERLAP}% token overlap)"
    echo "  README:    $ONELINER"
    echo "  CONTRACT:  $PROMISE"
    P1=$((P1 + 1))
  elif [[ "$OVERLAP" -lt 60 ]]; then
    echo "PROFILE_DRIFT.P2: README one-liner partially diverged from product-contract (${OVERLAP}% overlap)"
    P2=$((P2 + 1))
  fi
elif [[ -n "$PROMISE" && -z "$ONELINER" ]]; then
  echo "PROFILE_DRIFT.P2: README missing blockquote one-liner (product-contract exists)"
  P2=$((P2 + 1))
fi

# Legacy Speck marketing
FIRST_LINE="$(head -1 "$README_PATH" | tr -d '\r')"
if [[ "$FIRST_LINE" == "# Speck"* ]]; then
  echo "PROFILE_DRIFT.P1: README still has legacy Speck marketing title"
  P1=$((P1 + 1))
fi

echo "PROFILE_DRIFT_SUMMARY P1=${P1} P2=${P2} P3=${P3} project=${PROJECT_ID}"
[[ "$P1" -gt 0 ]] && exit 1
exit 0
