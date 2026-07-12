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

# 10. Self-banned language check (smart-exclude Section 7 itself)
if echo "$content" | grep -q "^## 7\."; then
  # Extract banned terms from Section 7
  TMP_TERMS=$(mktemp)
  awk '
    /^## 7\. Banned Language/ { in_section=1; next }
    /^## [0-9]/ && in_section { in_section=0 }
    in_section && /^\|/ {
      if ($0 ~ /Banned Term/) next
      if ($0 ~ /^\|[ \t-]+\|/) next
      line=$0
      sub(/^\| */, "", line)      # strip leading "| "
      sub(/ *\|.*/, "", line)     # keep ONLY column 1
      if (line ~ /^\[/) next      # skip placeholder rows
      if (line == "") next
      n = split(line, parts, /[\/,]/)
      for (i = 1; i <= n; i++) {
        p = parts[i]
        gsub(/"/, "", p)             # strip quotes
        sub(/^[ \t]+/, "", p)        # trim leading ws
        sub(/[ \t]+$/, "", p)        # trim trailing ws
        if (p != "" && p !~ /^\[/) print p
      }
    }
  ' "$file_path" > "$TMP_TERMS"

  awk '
    /^### Banned Phrase Classes/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    in_section && /^- ❌/ {
      line=$0
      sub(/^- ❌[[:space:]]*/, "", line)
      while (match(line, /"[^"]+"/)) {
        phrase = substr(line, RSTART+1, RLENGTH-2)
        print phrase
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$file_path" >> "$TMP_TERMS"

  banned_count=$(wc -l < "$TMP_TERMS" | tr -d ' ')
  if [[ "$banned_count" -gt 0 ]]; then
    self_violations=0
    while IFS= read -r term; do
      [[ -z "$term" ]] && continue
      esc_term="$(printf '%s' "$term" | sed -e 's/[.[\*^$()+?{|]/\\&/g')"

      # Find matching lines in original file excluding Section 7
      matching_lines=$(awk '
        /^## 7\. Banned Language/ { in_section=1; next }
        /^## [0-9]/ && in_section { in_section=0 }
        !in_section { print NR ":" $0 }
      ' "$file_path" | grep -i -w "$esc_term" || true)

      if [[ -n "$matching_lines" ]]; then
        log_error "Product Contract self-violates banned term '${term}'" \
          "Remove the banned term '${term}' from the contract text. Found at:\n${matching_lines}"
        self_violations=$((self_violations + 1))
      fi
    done < "$TMP_TERMS"
    
    if [[ "$self_violations" -eq 0 ]]; then
      log_success "Product Contract is self-consistent (no self-violations of banned terms)"
    fi
  fi
  rm -f "$TMP_TERMS"
fi

# 11. §2a ↔ §3 reconciliation (issue #80): the canonical §3 differentiator must never
#     be weaker than the project's own §2a defensible-wedge analysis.
RECONCILE_SCRIPT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)/market-reconcile-check.sh"
if [[ -f "$RECONCILE_SCRIPT" && "$(basename "$file_path")" == "product-contract.md" ]]; then
  recon_dir="$(cd "$(dirname "$file_path")" 2>/dev/null && pwd)"
  recon_out=$(bash "$RECONCILE_SCRIPT" "$recon_dir" 2>/dev/null || true)
  if echo "$recon_out" | grep -q "WEDGE_DRIFT.P1"; then
    log_error "§3 differentiator is weaker than the §2a defensible wedge (or §3 is empty while §2a states a wedge)" \
      "Promote the §2a wedge into §3 — the canonical differentiator must be at least as defensible as your own value-defensibility analysis.
Detail: $(echo "$recon_out" | grep 'WEDGE_DRIFT.P1' | head -1)"
  elif echo "$recon_out" | grep -q "WEDGE_DRIFT.P2"; then
    log_warning "§3 differentiator and §2a wedge share few tokens — confirm §3 leads with the defensible wedge" \
      "$(echo "$recon_out" | grep 'WEDGE_DRIFT.P2' | head -1)"
  else
    log_success "§3 differentiator is consistent with the §2a defensible wedge"
  fi
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
