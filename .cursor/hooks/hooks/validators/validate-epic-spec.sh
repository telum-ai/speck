#!/bin/bash

# Epic Spec Validator
# Validates epic.md files against quantitative rules
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

# 1. Check for epic overview/purpose
if echo "$content" | grep -q "## Overview\|## Purpose\|## Epic Overview"; then
  log_success "Epic overview/purpose section found"
  
  # Check length
  overview=$(echo "$content" | sed -n '/^## Overview\|^## Purpose\|^## Epic Overview/,/^##/p' | sed '1d;$d')
  overview_length=$(echo "$overview" | wc -c | xargs)
  
  if [ "$overview_length" -lt 100 ]; then
    log_warning "Epic overview is very brief ($overview_length < 100 chars)" \
      "Expand the overview to explain:
- What capability does this epic deliver?
- What user problems does it solve?
- How does it fit into the project vision?
Aim for 100-500 characters."
  elif [ "$overview_length" -gt 1000 ]; then
    log_warning "Epic overview is very long ($overview_length > 1000 chars)" \
      "Consider condensing to core value. Move details to epic-tech-spec.md.
Aim for 100-500 characters for scannability."
  else
    log_success "Epic overview length appropriate ($overview_length chars)"
  fi
else
  log_error "Missing epic overview/purpose section" \
    "Add an overview section explaining:
## Overview
[What this epic delivers and why it matters]"
fi

# 2. Check for success criteria
if echo "$content" | grep -q "## Success Criteria\|## Definition of Done"; then
  log_success "Success criteria found"
else
  log_warning "Missing success criteria section" \
    "Add measurable success criteria:
## Success Criteria
- [ ] Criterion 1 (how to verify)
- [ ] Criterion 2 (how to verify)"
fi

# 3. Check for functional requirements
req_count=$(echo "$content" | grep -c "^\*\*FR-.*\*\*:")
if [ "$req_count" -eq 0 ]; then
  log_warning "No formal functional requirements found" \
    "Consider adding epic-level requirements:
**FR-EPIC-001**: System SHALL [capability]
Use SHALL for mandatory, SHOULD for recommended, MAY for optional."
else
  log_success "Has $req_count functional requirement(s)"
  
  # Check normative language
  req_with_shall=$(echo "$content" | grep "^\*\*FR-.*\*\*:" | grep -c -i "SHALL\|MUST")
  if [ "$req_with_shall" -eq 0 ]; then
    log_warning "Requirements don't use normative language (SHALL/MUST)" \
      "Use precise language in requirements:
- SHALL/MUST = Mandatory
- SHOULD = Recommended
- MAY = Optional"
  else
    log_success "Requirements use normative language"
  fi
fi

# 4. Check estimated stories count
estimated_stories=$(echo "$content" | grep -i "Estimated Stories" | grep -o "[0-9]\+")
if [ -z "$estimated_stories" ]; then
  log_warning "No story count estimate found" \
    "Add estimate: **Estimated Stories**: X-Y
Helps with epic sizing and planning. Typical epic: 3-15 stories."
elif [ "$estimated_stories" -gt 20 ]; then
  log_warning "Epic estimates >20 stories" \
    "Consider splitting into multiple epics. Epics >15 stories are hard to manage.
Use 10-minute understandability rule: Can you explain this epic in <10 minutes?"
else
  log_success "Story estimate within reasonable range"
fi

# 5. Check for state tracking
if echo "$content" | grep -q "^- \[x\] \*\*Specified\*\*"; then
  log_success "Lifecycle state tracking present"
else
  log_warning "Missing lifecycle state tracking checklist" \
    "Add state tracking to monitor epic progress:
## Epic Lifecycle State Tracking
- [x] Specified - epic.md created
- [ ] Clarified - Ambiguities resolved
- [ ] Architected - epic-architecture.md created
..."
fi

# 6. Check for [NEEDS CLARIFICATION] markers
clarification_markers=$(echo "$content" | grep -c "\[NEEDS CLARIFICATION")
if [ "$clarification_markers" -gt 0 ]; then
  log_warning "Found $clarification_markers unresolved [NEEDS CLARIFICATION] marker(s)" \
    "Run /epic-clarify to resolve before /epic-plan.
Unresolved ambiguities cascade to all stories in the epic."
fi

# 7. Check for dependencies section
if echo "$content" | grep -q "## Dependencies\|## Integration Points"; then
  log_success "Dependencies/integration section found"
else
  log_warning "No dependencies section found" \
    "Document what this epic depends on and what depends on it:
## Dependencies
- Depends on: [Other epic/system]
- Provides to: [Other epic/system]"
fi

# 8. Check for implementation details leaking into epic spec
if echo "$content" | grep -qi "class\|function\|endpoint\|database schema\|table structure"; then
  log_warning "Epic spec may contain implementation details" \
    "Epic specs should focus on WHAT capability and WHY, not HOW.
Move technical details to epic-architecture.md or epic-tech-spec.md.
Keep epic.md strategic and non-technical."
fi

# === OUTPUT RESULTS ===

if [ -f "$validation_log" ]; then
  echo "" >> "$validation_log"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$validation_log"
  echo -e "File: $file_path" >> "$validation_log"
  echo -e "Errors: ${RED}$errors${NC} | Warnings: ${YELLOW}$warnings${NC}" >> "$validation_log"
  
  if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
    echo -e "${GREEN}✓ Epic spec validation passed!${NC}" >> "$validation_log"
  elif [ "$errors" -eq 0 ]; then
    echo -e "${YELLOW}Epic spec has warnings. Consider addressing before /epic-plan.${NC}" >> "$validation_log"
  else
    echo -e "${RED}Epic spec has errors. Fix before proceeding to /epic-plan.${NC}" >> "$validation_log"
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

