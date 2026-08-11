#!/bin/bash

# Evidence Contract Validator
# Validates evidence-contract.md files against structure and completeness rules.
# Provides enriched error messages with remediation guidance.

strict=false
if [[ "${1:-}" == "--strict" ]]; then
  strict=true
  shift
fi

file_path="${1:-}"

# Skip if file doesn't exist
if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
  exit 0
fi

# Read file content
content=$(cat "$file_path")

# Validation output file
validation_log="/tmp/speck-validation-$(date +%s).log"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

errors=0
warnings=0

# Function to write validation message
log_error() {
  echo -e "${RED}ERROR:${NC} $1" >> "$validation_log"
  echo -e "${BLUE}Fix:${NC} $2" >> "$validation_log"
  echo "" >> "$validation_log"
  ((errors++))
}

log_warning() {
  echo -e "${YELLOW}WARNING:${NC} $1" >> "$validation_log"
  echo -e "${BLUE}Suggestion:${NC} $2" >> "$validation_log"
  echo "" >> "$validation_log"
  ((warnings++))
}

log_success() {
  echo -e "${GREEN}✓${NC} $1" >> "$validation_log"
}

# === VALIDATION RULES ===

# 1. Frontmatter check
if echo "$content" | grep -q "artifact_type:[[:space:]]*evidence-contract"; then
  log_success "Frontmatter contains valid artifact_type: evidence-contract"
else
  log_error "Missing or invalid frontmatter 'artifact_type: evidence-contract'" \
    "Add or correct the YAML frontmatter at the top of the file:
---
speck_version: 7.0
artifact_type: evidence-contract
play_levels: [build, platform]
---"
fi

# 2. Check for Section 1: Target Launch Platforms
if echo "$content" | grep -q "^## 1\."; then
  log_success "Section 1 (Target Launch Platforms) found"
else
  log_error "Missing Section 1 (Target Launch Platforms)" \
    "Ensure Section 1 header is present:
## 1. Target Launch Platforms"
fi

# 3. Check for Section 2: Valid Proof Sources
if echo "$content" | grep -q "^## 2\."; then
  log_success "Section 2 (Valid Proof Sources) found"
else
  log_error "Missing Section 2 (Valid Proof Sources)" \
    "Ensure Section 2 header is present:
## 2. Valid Proof Sources (per platform)"
fi

# 4. Check for Section 3: Invalid Proof Sources
if echo "$content" | grep -q "^## 3\."; then
  log_success "Section 3 (Invalid Proof Sources) found"
else
  log_error "Missing Section 3 (Invalid Proof Sources)" \
    "Ensure Section 3 header is present:
## 3. Invalid Proof Sources (anti-proof)"
fi

# 5. Check for Section 4: Required Runtime LARP / Integration Stress Tests
if echo "$content" | grep -q "^## 4\."; then
  log_success "Section 4 (Required Runtime LARP / Integration Stress Tests) found"
else
  log_error "Missing Section 4 (Required Runtime LARP / Integration Stress Tests)" \
    "Ensure Section 4 header is present:
## 4. Required Runtime LARP / Integration Stress Tests"
fi

# 6. Check for Section 5: Quality Judgment & Scoring Protocol
if echo "$content" | grep -q "^## 5\."; then
  log_success "Section 5 (Quality Judgment & Scoring Protocol) found"
else
  log_error "Missing Section 5 (Quality Judgment & Scoring Protocol)" \
    "Ensure Section 5 header is present:
## 5. Quality Judgment & Scoring Protocol"
fi

# 7. Check for Section 6: Required Static Evidence
if echo "$content" | grep -q "^## 6\."; then
  log_success "Section 6 (Required Static Evidence) found"
else
  log_error "Missing Section 6 (Required Static Evidence)" \
    "Ensure Section 6 header is present:
## 6. Required Static Evidence"
fi

# 8. Check for Section 7: Required Live-Service Evidence (was previously unchecked — #88)
if echo "$content" | grep -q "^## 7\."; then
  log_success "Section 7 (Required Live-Service Evidence) found"
else
  log_error "Missing Section 7 (Required Live-Service Evidence)" \
    "Ensure Section 7 header is present:
## 7. Required Live-Service Evidence"
fi

# 8. Scan for unreplaced REPLACE_BEFORE_SHIP placeholders
#
# P2-4 (#93): this used to be `grep -q "REPLACE_BEFORE_SHIP"` — unanchored,
# no colon required — which matches the bare word inside this artifact's
# OWN PLACEHOLDER CONVENTION prose (evidence-contract-template.md's "Tokens
# of the form REPLACE_BEFORE_SHIP followed by a colon and a hint MUST..."),
# so a fully-filled evidence-contract.md still failed this check. Same
# class of bug as #89 (a plain grep convicting Speck's own template text),
# just living here instead of check-replace-markers.sh — and that script
# already carries the fix (genuine-marker detection: a real marker has hint
# content after its colon; a citation form doesn't). Delegate to it instead
# of maintaining a second, independently-buggy reimplementation of the same
# rule.
CRM_SCRIPT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)/check-replace-markers.sh"
if [[ ! -f "$CRM_SCRIPT" ]]; then
  log_error "check-replace-markers.sh not found at expected path" \
    "This check depends on .speck/scripts/check-replace-markers.sh — restore it before validating."
elif bash "$CRM_SCRIPT" "$file_path" >/dev/null 2>&1; then
  log_success "No 'REPLACE_BEFORE_SHIP' placeholders found"
else
  log_error "Found unreplaced 'REPLACE_BEFORE_SHIP' placeholders" \
    "Search for all occurrences of 'REPLACE_BEFORE_SHIP' and fill in concrete values."
fi

# 9. PROFILE Gate Criteria
profile_section="$(printf '%s\n' "$content" | awk '
  /^### ([0-9]+[a-z]?[.] )?PROFILE Gate Criteria[[:space:]]*$/ { active=1 }
  active && /^##[^#]/ { exit }
  active { print }
')"
if [[ -z "$profile_section" ]]; then
  log_error "Missing PROFILE Gate Criteria subsection" \
    "Add ### PROFILE Gate Criteria under Section 7, or run /speck-catch-up --phase=profile"
else
  profile_contract_valid=true
  for declaration in \
    'PROFILE_REGISTRY=project.md#PROFILE surfaces' \
    'PROFILE_GATE_COMMAND=bash .speck/scripts/profile-drift-check.sh --claim <state>' \
    'PROFILE_COVERAGE=every-row' \
    'PROFILE_P1_BLOCKS=true' \
    'PROFILE_MISSING_POLICY=finding' \
    'PROFILE_UNREACHABLE_POLICY=finding' \
    'PROFILE_PLACEHOLDER_POLICY=finding'; do
    if ! printf '%s\n' "$profile_section" | grep -Fqx "$declaration"; then
      profile_contract_valid=false
    fi
  done
  if [[ "$profile_contract_valid" == true ]]; then
    log_success "Binding multi-surface PROFILE machine contract found"
  else
    log_error "PROFILE Gate Criteria is shape-only or incomplete" \
      "Restore the authoritative PROFILE_REGISTRY, PROFILE_GATE_COMMAND, PROFILE_COVERAGE, PROFILE_P1_BLOCKS, and missing/unreachable/placeholder policy declarations."
  fi
fi

# === OUTPUT RESULTS ===

if [ -f "$validation_log" ]; then
  echo "" >> "$validation_log"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$validation_log"
  echo -e "File: $file_path" >> "$validation_log"
  echo -e "Errors: ${RED}$errors${NC} | Warnings: ${YELLOW}$warnings${NC}" >> "$validation_log"
  
  if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
    echo -e "${GREEN}✓ Evidence Contract validation passed!${NC}" >> "$validation_log"
  elif [ "$errors" -eq 0 ]; then
    echo -e "${YELLOW}Evidence Contract has warnings. Consider addressing them.${NC}" >> "$validation_log"
  else
    echo -e "${RED}Evidence Contract has errors. Fix before claiming readiness.${NC}" >> "$validation_log"
  fi
  
  # Display validation results
  cat "$validation_log"
  
  # Clean up
  rm "$validation_log"
fi

if [ "$strict" = true ] && [ "$errors" -gt 0 ]; then
  exit 1
fi

exit 0
