#!/usr/bin/env bash
# validate-readme.sh — PROFILE validator for root README.md
#
# Usage: validate-readme.sh [--strict] [WORKSPACE_ROOT]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../../profile-lib.sh
source "$LIB_DIR/profile-lib.sh"

strict=false
WORKSPACE_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) strict=true; shift ;;
    *) WORKSPACE_ROOT="$1"; shift ;;
  esac
done

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(pwd)}"
README_PATH="$WORKSPACE_ROOT/README.md"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'
errors=0
warnings=0

log_error() { echo -e "${RED}ERROR:${NC} $1"; errors=$((errors + 1)); }
log_warn() { echo -e "${YELLOW}WARNING:${NC} $1"; warnings=$((warnings + 1)); }
log_ok() { echo -e "${GREEN}✓${NC} $1"; }

if [[ ! -f "$README_PATH" ]]; then
  log_error "README.md missing at workspace root"
  [[ "$strict" == true && "$errors" -gt 0 ]] && exit 1
  exit 0
fi

CONTENT="$(cat "$README_PATH")"
FIRST_LINE="$(head -1 "$README_PATH" | tr -d '\r')"

if [[ "$FIRST_LINE" == "# Speck"* ]]; then
  log_error "Legacy Speck marketing README detected — run speck upgrade or project-profile"
else
  log_ok "Not legacy Speck marketing README"
fi

if echo "$CONTENT" | grep -q '<!-- SPECK:START -->' && echo "$CONTENT" | grep -q '<!-- SPECK:END -->'; then
  log_ok "SPECK:START..END markers present"
else
  log_error "Missing <!-- SPECK:START --> or <!-- SPECK:END --> markers"
fi

if profile_has_orphan_placeholders "$README_PATH"; then
  log_error "Unreplaced scaffold placeholders in README"
else
  log_ok "No orphan scaffold placeholders"
fi

if grep -q '^> ' "$README_PATH"; then
  log_ok "Elevator pitch blockquote present"
else
  log_warn "No blockquote one-liner (^> ) in README"
fi

PROJECT_ID="$(profile_resolve_project_id "$WORKSPACE_ROOT" "")"
if [[ -n "$PROJECT_ID" ]]; then
  if grep -q "specs/projects/${PROJECT_ID}/" "$README_PATH"; then
    log_ok "Spec links reference project ${PROJECT_ID}"
  else
    log_warn "README links may not reference active project ${PROJECT_ID}"
  fi
  if [[ -d "$WORKSPACE_ROOT/specs/projects/$PROJECT_ID" ]]; then
    log_ok "Project directory exists: specs/projects/${PROJECT_ID}"
  else
    log_warn "Linked project directory missing: specs/projects/${PROJECT_ID}"
  fi
fi

SPECK_VER="$(profile_read_speck_version "$WORKSPACE_ROOT")"
if grep -q "speck ${SPECK_VER}\|speck v${SPECK_VER#v}" "$README_PATH"; then
  log_ok "Footer Speck version matches .speck/VERSION (${SPECK_VER})"
else
  if [[ "$strict" == true ]]; then
    log_error "Footer Speck version stale (expected ${SPECK_VER}) — run speck upgrade or project-profile"
  else
    log_warn "Footer Speck version may be stale (expected ${SPECK_VER})"
  fi
fi

# Drift check
if [[ -f "$LIB_DIR/profile-drift-check.sh" ]]; then
  DRIFT_RC=0
  DRIFT_OUT="$(bash "$LIB_DIR/profile-drift-check.sh" "$WORKSPACE_ROOT" "${PROJECT_ID:-}" 2>&1)" || DRIFT_RC=$?
  saw_summary=false
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$line" == PROFILE_DRIFT.P1* ]]; then
      log_error "${line#PROFILE_DRIFT.P1: }"
    elif [[ "$line" == PROFILE_DRIFT.P2* ]]; then
      log_warn "${line#PROFILE_DRIFT.P2: }"
    elif [[ "$line" == PROFILE_DRIFT.P3* ]]; then
      log_warn "${line#PROFILE_DRIFT.P3: }"
    elif [[ "$line" == PROFILE_DRIFT_SUMMARY* ]]; then
      saw_summary=true
    fi
  done <<< "$DRIFT_OUT"
  if [[ "$DRIFT_RC" -eq 2 ]]; then
    log_error "PROFILE drift checker could not resolve the active project"
  elif [[ "$saw_summary" != true ]]; then
    # The checker exits 0 on a clean pass and 1 when it finds a P1, but always prints a
    # PROFILE_DRIFT_SUMMARY line on every real run (rc 2 is the one deliberate exception,
    # handled above). No summary line means the checker itself failed — a missing
    # interpreter, a crash, a bad wrapper — not that the surfaces are clean, so this must
    # not read as a pass regardless of DRIFT_RC.
    log_error "PROFILE drift checker did not complete (rc=$DRIFT_RC): ${DRIFT_OUT:-no output}"
  fi
else
  log_error "PROFILE drift checker missing: $LIB_DIR/profile-drift-check.sh"
fi

echo ""
echo "Errors: $errors | Warnings: $warnings"
if [[ "$errors" -gt 0 ]]; then
  [[ "$strict" == true ]] && exit 1
fi
exit 0
