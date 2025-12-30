#!/bin/bash

# Story Plan Validator
# Validates plan.md files against quantitative rules
# Provides enriched error messages with remediation guidance

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

# 1. Check for technical approach section (supports legacy + current formats)
has_approach=false
has_legacy=false

if echo "$content" | grep -q "## Technical Approach\|## Approach\|## Implementation Approach"; then
  has_approach=true
fi

if echo "$content" | grep -q "^## Technical Context" && echo "$content" | grep -q "^## Phase"; then
  has_legacy=true
fi

if [ "$has_approach" = true ]; then
  log_success "Technical approach section found"

  # Check length
  approach=$(echo "$content" | sed -n '/^## Technical Approach\|^## Approach\|^## Implementation Approach/,/^##/p' | sed '1d;$d')
  approach_length=$(echo "$approach" | wc -c | xargs)

  if [ "$approach_length" -lt 100 ]; then
    log_warning "Technical approach is very brief ($approach_length < 100 chars)" \
      "Expand to explain:
- HOW will this be implemented?
- What existing patterns are you following?
- What new patterns are needed (with evidence)?
Aim for 100-500 characters."
  fi
elif [ "$has_legacy" = true ]; then
  log_success "Legacy plan format detected (Technical Context + Phases)"
  log_warning "No explicit '## Technical Approach' section (recommended)" \
    "Add a brief '## Technical Approach' section summarizing the implementation approach and key decisions.
This helps tasks.md generation and review."
else
  log_error "Missing implementation approach/structure" \
    "Add either:

Option A (recommended):
## Technical Approach
[How this will be implemented, patterns used, etc.]

Option B (legacy accepted):
## Technical Context
...
## Phase 1: Design & Contracts
..."
fi

# 2. Check for data model reference
plan_dir=$(dirname "$file_path")
if [ -f "$plan_dir/data-model.md" ]; then
  log_success "data-model.md exists"
else
  if echo "$content" | grep -qi "database\|model\|entity\|schema"; then
    log_warning "Plan mentions data but no data-model.md found" \
      "Create data-model.md to document:
- Entities and relationships
- Schema changes needed
- Migration strategy
Run /story-plan creates this automatically."
  fi
fi

# 3. Check for contracts directory
if [ -d "$plan_dir/contracts" ]; then
  contract_count=$(find "$plan_dir/contracts" -name "*.yaml" -o -name "*.json" | wc -l)
  log_success "contracts/ directory exists with $contract_count contract(s)"
else
  if echo "$content" | grep -qi "API\|endpoint\|interface\|contract"; then
    log_warning "Plan mentions APIs but no contracts/ directory found" \
      "Create contracts/ directory with API contract files:
contracts/
  api-endpoints.yaml  # Request/response schemas
  events.yaml         # Event schemas
Run /story-plan creates this automatically."
  fi
fi

# 4. Check for complexity justification
if echo "$content" | grep -qi "abstract\|framework\|pattern\|design pattern\|architecture"; then
  if ! echo "$content" | grep -qi "evidence\|measurement\|3+ use cases\|performance\|scale"; then
    log_warning "Complexity mentioned without evidence" \
      "Simplicity-first principle: Require evidence for complexity.
Add one of:
- Performance evidence: Measured X ms, target <Y ms
- Scale evidence: Must support N users/requests
- Abstraction evidence: Same code in 3+ places
See AGENTS.md 'Simplicity-First Principles'"
  else
    log_success "Complexity justified with evidence"
  fi
fi

# 5. Check for file count estimate
new_files=$(echo "$content" | grep -c -i "new file\|create file")
if [ "$new_files" -gt 3 ]; then
  log_warning "Plan mentions creating many files ($new_files > 3)" \
    "Simplicity-first: Start with single file until proven insufficient.
Default solution: <100 lines in one file.
Only create additional files when you have evidence of need.
Can this be simpler?"
fi

# 6. Check for dependencies documentation
if echo "$content" | grep -q "## Dependencies\|## Prerequisites"; then
  log_success "Dependencies section found"
else
  log_warning "No dependencies section found" \
    "Document what this story depends on:
## Dependencies
- Requires: [Other story/feature]
- Provides: [What other stories can use]"
fi

# 7. Check for architecture decision gate
if echo "$content" | grep -q "Architecture Decision Gate\|## Architecture"; then
  log_success "Architecture considerations documented"
else
  if echo "$content" | grep -qi "cross-cutting\|new pattern\|external dependency\|security-critical"; then
    log_warning "Seems complex but no architecture section" \
      "Consider documenting architectural decisions:
## Architecture
[Why this approach, alternatives considered, trade-offs]

For simple stories, this can be brief or omitted."
  fi
fi

# 8. Check for testing strategy
if echo "$content" | grep -qi "test\|testing strategy\|TDD"; then
  log_success "Testing strategy mentioned"
else
  log_warning "No testing strategy mentioned" \
    "Add testing approach:
## Testing Strategy
- Unit tests: [What to test]
- Integration tests: [What to test]
- Contract tests: [What to validate]
See Speck docs in `.speck/README.md` (or your project’s `.cursor/rules/` if you maintain one)."
fi

# === OUTPUT RESULTS ===

if [ -f "$validation_log" ]; then
  echo "" >> "$validation_log"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$validation_log"
  echo -e "File: $file_path" >> "$validation_log"
  echo -e "Errors: ${RED}$errors${NC} | Warnings: ${YELLOW}$warnings${NC}" >> "$validation_log"
  
  if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
    echo -e "${GREEN}✓ Story plan validation passed!${NC}" >> "$validation_log"
  elif [ "$errors" -eq 0 ]; then
    echo -e "${YELLOW}Story plan has warnings. Consider addressing before /story-tasks.${NC}" >> "$validation_log"
  else
    echo -e "${RED}Story plan has errors. Fix before proceeding to /story-tasks.${NC}" >> "$validation_log"
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

