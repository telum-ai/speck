#!/bin/bash

# FELT-GOOD Axis Validator
# Validates validation-report.md and epic-validation-report.md files for Three-Axis compliance.
#
# Philosophy: FELT-GOOD is an axis the AI evaluates DIRECTLY via the naive-hostile LARP.
# It is NOT gated behind a mandatory human sign-off. This validator therefore enforces
# that FELT-GOOD was actually COVERED (felt_axis is ai-verified or human-verified) for
# consumer UX-RC+ claims — not that a human attested to it. A human taste review is an
# optional stronger signal (felt_axis: human-verified), never a prerequisite.

set -euo pipefail

strict=false
if [[ "${1:-}" == "--strict" ]]; then
  strict=true
  shift
fi

file_path="${1:-}"

# Skip if file doesn't exist
if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  echo "Error: File path not specified or file does not exist." >&2
  exit 1
fi

# Read file content
content=$(cat "$file_path")

# Validation output
errors=0
warnings=0

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_error() {
  echo -e "${RED}ERROR:${NC} $1" >&2
  if [[ -n "${2:-}" ]]; then
    echo -e "${BLUE}Fix:${NC} $2" >&2
  fi
  echo "" >&2
  ((errors++))
}

log_warning() {
  echo -e "${YELLOW}WARNING:${NC} $1" >&2
  if [[ -n "${2:-}" ]]; then
    echo -e "${BLUE}Suggestion:${NC} $2" >&2
  fi
  echo "" >&2
  ((warnings++))
}

log_success() {
  echo -e "${GREEN}✓${NC} $1"
}

# Helper: is the readiness state UX-RC or higher (consumer UI-facing states)?
is_ux_rc_or_higher() {
  case "$1" in
    UX-RC|COMMERCIAL-RC|SHIP-RC|SHIP) return 0 ;;
    *) return 1 ;;
  esac
}

# === VALIDATION RULES ===

# 1. Assert the Readiness axes block header exists (loose match — v8.2.0 adds a 4th
#    axis, so accept both "Three-Axis …" and "Four-Axis … (… / TASTE)").
if echo "$content" | grep -qE "^## 🧭 .*Readiness \("; then
  log_success "Readiness axes header found"
else
  log_error "Missing the Readiness axes header (e.g. '## 🧭 Four-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD / TASTE)')" \
    "Add the Readiness axes section to your validation report."
fi

# 2. Assert felt_axis frontmatter exists and is valid
if echo "$content" | grep -q "^felt_axis:[[:space:]]*"; then
  felt_axis=$(echo "$content" | grep "^felt_axis:[[:space:]]*" | sed -E 's/felt_axis:[[:space:]]*(.*)/\1/' | tr -d '[]' | xargs || true)
  log_success "felt_axis frontmatter found: '$felt_axis'"
  if [[ "$felt_axis" != "uncovered" && "$felt_axis" != "ai-verified" && "$felt_axis" != "human-verified" ]]; then
    log_error "Invalid felt_axis value: '$felt_axis'" \
      "felt_axis must be one of: 'uncovered', 'ai-verified', or 'human-verified'."
  fi
else
  log_error "Missing 'felt_axis' frontmatter field" \
    "Add 'felt_axis: [uncovered | ai-verified | human-verified]' to the YAML frontmatter at the top of the file."
  felt_axis=""
fi

# 3. Detect Project Archetype
TARGET_DIR=$(dirname "$file_path")
project_archetype="consumer_product" # Default fallback (strictest)
project_json=""
dir="$TARGET_DIR"
while [[ "$dir" != "/" && -n "$dir" ]]; do
  if [[ -f "${dir}/project.json" ]]; then
    project_json="${dir}/project.json"
    break
  elif [[ -f "${dir}/.speck/project.json" ]]; then
    project_json="${dir}/.speck/project.json"
    break
  fi
  dir=$(dirname "$dir")
done

if [[ -f "$project_json" ]]; then
  archetype=$(grep -o '"project_archetype"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_json" 2>/dev/null | sed -E 's/.*"([^"]*)"$/\1/' || true)
  if [[ -n "$archetype" ]]; then
    project_archetype="$archetype"
  fi
fi

# 4. Parse claimed readiness state
claimed_state=""
if echo "$content" | grep -q "^readiness_state_claimed:[[:space:]]*"; then
  claimed_state=$(echo "$content" | grep "^readiness_state_claimed:[[:space:]]*" | sed -E 's/readiness_state_claimed:[[:space:]]*(.*)/\1/' | tr -d '[]' | xargs || true)
fi

# Fallback: parse the "Claiming:" line in the body
if [[ -z "$claimed_state" ]]; then
  claimed_state_line=$(echo "$content" | grep -i "Claiming:" | head -n 1 || true)
  if [[ -n "$claimed_state_line" ]]; then
    claimed_state=$(echo "$claimed_state_line" | grep -oE '(NO-SHIP|IMPL-GREEN|INTEGRATION-GREEN|UX-RC|API-RC|COMMERCIAL-RC|SHIP-RC|SHIP)' | head -n 1 || true)
  fi
fi

# 5. Enforce that FELT-GOOD is COVERED (by the AI) for consumer UX-RC+ claims.
#    The AI covers FELT-GOOD via the naive-hostile LARP — it is NOT deferred to a human.
#    'uncovered' means the naive-hostile pass never ran, which is a blocker at UX-RC+.
if [[ "$project_archetype" == "consumer_product" && -n "$claimed_state" ]]; then
  if is_ux_rc_or_higher "$claimed_state"; then
    if [[ "$felt_axis" == "uncovered" ]]; then
      log_error "Consumer product claiming $claimed_state has an uncovered FELT-GOOD axis" \
        "The AI must run the naive-hostile LARP and record a taste verdict (felt_axis: ai-verified). FELT-GOOD is AI-evaluated — do not leave it uncovered or defer it to a human."
    elif [[ "$felt_axis" == "ai-verified" || "$felt_axis" == "human-verified" ]]; then
      log_success "FELT-GOOD axis is covered ($felt_axis) for $claimed_state"
    fi
  fi
fi

# 6. Flag unqualified "verified" or "validated" in the readiness claim with no axis named.
claim_section=$(echo "$content" | awk '/^## 🎯 Readiness State Claim/{flag=1;next}/^## /{flag=0}flag' || true)
if [[ -n "$claim_section" ]]; then
  if echo "$claim_section" | grep -qiE "verified|validated"; then
    if ! echo "$claim_section" | grep -qiE "correct|on-contract|felt-good"; then
      log_error "Unqualified 'verified' or 'validated' claim found in Readiness State Claim section" \
        "Do not use unqualified 'verified' or 'validated' claims without naming the axis (CORRECT, ON-CONTRACT, or FELT-GOOD)."
    fi
  fi
fi

# Exit status
if [[ "$errors" -gt 0 ]]; then
  if [[ "$strict" == "true" ]]; then
    echo -e "${RED}Validation FAILED with $errors error(s).${NC}" >&2
    exit 1
  else
    echo -e "${YELLOW}Validation completed with $errors error(s) (ignored without --strict).${NC}"
  fi
fi

echo -e "${GREEN}Validation PASSED.${NC}"
exit 0
