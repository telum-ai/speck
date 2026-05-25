#!/bin/bash

# Product Contract Validator
# Validates product-contract.md files against structure and completeness rules.
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
if echo "$content" | grep -q "artifact_type:[[:space:]]*product-contract"; then
  log_success "Frontmatter contains valid artifact_type: product-contract"
else
  log_error "Missing or invalid frontmatter 'artifact_type: product-contract'" \
    "Add or correct the YAML frontmatter at the top of the file:
---
speck_version: 7.0
artifact_type: product-contract
play_levels: [build, platform]
---"
fi

# 2. Check for Section 1: The Paid Promise / Operational SLA
if echo "$content" | grep -q "^## 1\."; then
  log_success "Section 1 (The Paid Promise / Operational SLA) found"
else
  log_error "Missing Section 1 (The Paid Promise / Operational SLA)" \
    "Ensure Section 1 header is present:
## 1. The Paid Promise / Operational SLA"
fi

# 3. Check for Section 2: Primary Persona / Consumer
if echo "$content" | grep -q "^## 2\."; then
  log_success "Section 2 (Primary Persona / Consumer) found"
else
  log_error "Missing Section 2 (Primary Persona / Consumer)" \
    "Ensure Section 2 header is present:
## 2. Primary Persona / Consumer"
fi

# 4. Check for Section 3: The Differentiator
if echo "$content" | grep -q "^## 3\."; then
  log_success "Section 3 (The Differentiator) found"
else
  log_error "Missing Section 3 (The Differentiator)" \
    "Ensure Section 3 header is present:
## 3. The Differentiator"
fi

# 5. Check for Section 4: JTBD / Operational Invariants Scorecard
if echo "$content" | grep -q "^## 4\."; then
  log_success "Section 4 (JTBD / Operational Invariants Scorecard) found"
else
  log_error "Missing Section 4 (JTBD / Operational Invariants Scorecard)" \
    "Ensure Section 4 header is present:
## 4. JTBD Scorecard / Operational Invariants Scorecard"
fi

# 6. Check for Section 5: Magic Moments / Operational Milestones
if echo "$content" | grep -q "^## 5\."; then
  log_success "Section 5 (Magic Moments / Operational Milestones) found"
else
  log_error "Missing Section 5 (Magic Moments / Operational Milestones)" \
    "Ensure Section 5 header is present:
## 5. Magic Moments / Operational Milestones"
fi

# 7. Check for Section 6: Public Language / API & System Taxonomy
if echo "$content" | grep -q "^## 6\."; then
  log_success "Section 6 (Public Language / API & System Taxonomy) found"
else
  log_error "Missing Section 6 (Public Language / API & System Taxonomy)" \
    "Ensure Section 6 header is present:
## 6. Public Language / API & System Taxonomy"
fi

# 8. Check for Section 7: Banned Language / System Anti-Patterns
if echo "$content" | grep -q "^## 7\."; then
  log_success "Section 7 (Banned Language / System Anti-Patterns) found"
else
  log_error "Missing Section 7 (Banned Language / System Anti-Patterns)" \
    "Ensure Section 7 header is present:
## 7. Banned Language / System Anti-Patterns"
fi

# 9. Scan for unreplaced REPLACE_BEFORE_SHIP placeholders
if echo "$content" | grep -q "REPLACE_BEFORE_SHIP"; then
  log_error "Found unreplaced 'REPLACE_BEFORE_SHIP' placeholders" \
    "Search for all occurrences of 'REPLACE_BEFORE_SHIP' and fill in concrete values."
else
  log_success "No 'REPLACE_BEFORE_SHIP' placeholders found"
fi

# === OUTPUT RESULTS ===

if [ -f "$validation_log" ]; then
  echo "" >> "$validation_log"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$validation_log"
  echo -e "File: $file_path" >> "$validation_log"
  echo -e "Errors: ${RED}$errors${NC} | Warnings: ${YELLOW}$warnings${NC}" >> "$validation_log"
  
  if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
    echo -e "${GREEN}✓ Product Contract validation passed!${NC}" >> "$validation_log"
  elif [ "$errors" -eq 0 ]; then
    echo -e "${YELLOW}Product Contract has warnings. Consider addressing them.${NC}" >> "$validation_log"
  else
    echo -e "${RED}Product Contract has errors. Fix before claiming readiness.${NC}" >> "$validation_log"
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
