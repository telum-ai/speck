#!/bin/bash

# FELT-GOOD Axis Validator
# Validates validation-report.md and epic-validation-report.md files for Three-Axis compliance.
# Enforces that consumer SHIP-RC+ claims require human-verified FELT-GOOD attestation.

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

# === VALIDATION RULES ===

# 1. Assert Three-Axis block header exists
if echo "$content" | grep -q "^## 🧭 Three-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD)"; then
  log_success "Three-Axis Readiness header found"
else
  log_error "Missing required header: '## 🧭 Three-Axis Readiness (CORRECT / ON-CONTRACT / FELT-GOOD)'" \
    "Add the Three-Axis Readiness section to your validation report."
fi

# 2. Assert felt_axis frontmatter exists
if echo "$content" | grep -q "^felt_axis:[[:space:]]*"; then
  felt_axis=$(echo "$content" | grep "^felt_axis:[[:space:]]*" | sed -E 's/felt_axis:[[:space:]]*(.*)/\1/' | tr -d '[]' | xargs || true)
  log_success "felt_axis frontmatter found: '$felt_axis'"
  if [[ "$felt_axis" != "uncovered" && "$felt_axis" != "human-verified" ]]; then
    log_error "Invalid felt_axis value: '$felt_axis'" \
      "felt_axis must be either 'uncovered' or 'human-verified'."
  fi
else
  log_error "Missing 'felt_axis' frontmatter field" \
    "Add 'felt_axis: [uncovered | human-verified]' to the YAML frontmatter at the top of the file."
  felt_axis=""
fi

# 3. Detect Project Archetype
TARGET_DIR=$(dirname "$file_path")
project_archetype="consumer_product" # Default fallback
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

# 4. Check Claimed Readiness State
claimed_state=""
if echo "$content" | grep -q "^readiness_state_claimed:[[:space:]]*"; then
  claimed_state=$(echo "$content" | grep "^readiness_state_claimed:[[:space:]]*" | sed -E 's/readiness_state_claimed:[[:space:]]*(.*)/\1/' | tr -d '[]' | xargs || true)
elif echo "$content" | grep -q "^readiness_state_claimed[[:space:]]*=[[:space:]]*"; then
  claimed_state=$(echo "$content" | grep "^readiness_state_claimed[[:space:]]*=[[:space:]]*" | sed -E 's/readiness_state_claimed[[:space:]]*=[[:space:]]*/\1/' | xargs || true)
fi

# Fallback check in body if frontmatter parse failed or not a standard validation report
if [[ -z "$claimed_state" ]]; then
  claimed_state_line=$(echo "$content" | grep -i "Claiming:" | head -n 1 || true)
  if [[ -n "$claimed_state_line" ]]; then
    claimed_state=$(echo "$claimed_state_line" | grep -oE '(NO-SHIP|IMPL-GREEN|INTEGRATION-GREEN|UX-RC|API-RC|COMMERCIAL-RC|SHIP-RC|SHIP)' | head -n 1 || true)
  fi
fi

# 5. Enforce consumer SHIP-RC+ FELT-GOOD human attestation
if [[ "$project_archetype" == "consumer_product" ]]; then
  if [[ "$claimed_state" == "SHIP-RC" || "$claimed_state" == "SHIP" ]]; then
    if [[ "$felt_axis" != "human-verified" ]]; then
      log_error "Consumer product claiming $claimed_state requires 'felt_axis: human-verified'" \
        "You must perform a human taste review and set 'felt_axis: human-verified' in frontmatter."
    fi
    
    # Check for attestation file citation or existence
    has_attestation=false
    if echo "$content" | grep -qE "larp-recordings/[a-zA-Z0-9_-]+-felt-attestation\.md"; then
      has_attestation=true
    fi
    
    # Also check if any felt-attestation.md file exists in larp-recordings directory
    if [ -d "$TARGET_DIR/larp-recordings" ]; then
      if ls "$TARGET_DIR/larp-recordings"/*felt-attestation.md >/dev/null 2>&1; then
        has_attestation=true
      fi
    fi
    
    if [[ "$has_attestation" == "false" ]]; then
      log_error "Consumer product claiming $claimed_state requires a human FELT attestation file" \
        "Create a human taste attestation file at 'larp-recordings/<sha>-felt-attestation.md' and cite it in the report."
    fi
  fi
fi

# 6. Flag unqualified "verified" or "validated" in the readiness claim with no axis
# Extract the Readiness State Claim section
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
