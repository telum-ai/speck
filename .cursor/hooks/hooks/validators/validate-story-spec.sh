#!/bin/bash

# Story Spec Validator
# Validates spec.md files against quantitative rules
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

# 1. Check for User Story format
if echo "$content" | grep -q "As a.*I want to.*so that"; then
  log_success "User story format found"
else
  log_error "Missing user story in standard format" \
    "Add: 'As a [user type], I want to [action] so that [benefit]' to spec.md
See: .speck/templates/story/story-template.md for examples"
fi

# 2. Check for acceptance criteria (supports legacy + current formats)
scenario_heading_count=$(echo "$content" | grep -c "^#### Scenario:")
scenario_numbered_count=$(echo "$content" | grep -E -c "^[0-9]+\. \*\*(GIVEN|Given)\*\*")
scenario_bullet_count=$(echo "$content" | grep -E -c "^- \*\*(GIVEN|Given)\*\*")

scenario_count=0
scenario_format=""
if [ "$scenario_heading_count" -gt 0 ]; then
  scenario_count="$scenario_heading_count"
  scenario_format="named"
elif [ "$scenario_numbered_count" -gt 0 ]; then
  scenario_count="$scenario_numbered_count"
  scenario_format="numbered"
elif [ "$scenario_bullet_count" -gt 0 ]; then
  scenario_count="$scenario_bullet_count"
  scenario_format="bulleted"
fi

if [ "$scenario_count" -eq 0 ]; then
  log_error "No acceptance scenarios found" \
    "Add at least one scenario using one of these accepted formats:

Option A (recommended):
#### Scenario: [Name]
- **GIVEN** [initial state]
- **WHEN** [action]
- **THEN** [outcome]

Option B (legacy accepted):
1. **Given** [initial state], **When** [action], **Then** [outcome]"
elif [ "$scenario_count" -gt 5 ]; then
  log_warning "Too many scenarios ($scenario_count > 5)" \
    "Consider splitting into multiple stories. Each story should have 1-5 scenarios.
If scenarios represent different features, create separate stories."
else
  if [ -n "$scenario_format" ]; then
    log_success "Has $scenario_count acceptance scenario(s) ($scenario_format format)"
  else
    log_success "Has $scenario_count acceptance scenario(s)"
  fi
fi

# 3. Check for functional requirements with SHALL/MUST
req_count=$(echo "$content" | grep -c "^- \*\*FR-[0-9]*\*\*:")
if [ "$req_count" -eq 0 ]; then
  log_warning "No formal functional requirements (FR-XXX) found" \
    "Consider adding structured requirements:
- **FR-001**: System SHALL [capability]
Use SHALL for mandatory requirements, SHOULD for recommendations, MAY for optional."
else
  log_success "Has $req_count functional requirement(s)"
  
  # Check if requirements use normative language
  req_with_shall=$(echo "$content" | grep "^- \*\*FR-[0-9]*\*\*:" | grep -c -i "SHALL\|MUST")
  if [ "$req_with_shall" -eq 0 ]; then
    log_warning "Functional requirements don't use normative language (SHALL/MUST)" \
      "Use precise requirement language:
- SHALL/MUST = Mandatory (must be tested)
- SHOULD = Best practice (can deviate with reason)
- MAY = Optional
Example: System SHALL respond within 200ms"
  else
    log_success "Requirements use normative language"
  fi
fi

# 4. Check purpose section length (if present)
if echo "$content" | grep -q "^## Purpose"; then
  purpose_section=$(echo "$content" | sed -n '/^## Purpose/,/^##/p' | sed '1d;$d')
  purpose_length=$(echo "$purpose_section" | wc -c | xargs)

  if [ "$purpose_length" -lt 50 ]; then
    log_warning "Purpose section is very brief ($purpose_length < 50 chars)" \
      "Expand the purpose to explain:
- What problem does this solve?
- Who benefits from this feature?
- Why is this important now?
Aim for 50-300 characters."
  elif [ "$purpose_length" -gt 500 ]; then
    log_warning "Purpose section is very long ($purpose_length > 500 chars)" \
      "Consider condensing to core value proposition. Move details to requirements or plan.md.
Aim for 50-300 characters."
  else
    log_success "Purpose section length appropriate ($purpose_length chars)"
  fi
else
  log_warning "Missing Purpose section" \
    "Add a brief purpose section:
## Purpose
[1-3 sentences describing user value + outcome]"
fi

# 5. Check for [NEEDS CLARIFICATION] markers
clarification_markers=$(echo "$content" | grep -c "\[NEEDS CLARIFICATION")
if [ "$clarification_markers" -gt 0 ]; then
  log_warning "Found $clarification_markers unresolved [NEEDS CLARIFICATION] marker(s)" \
    "Run /story-clarify command to resolve ambiguities before proceeding to /story-plan.
Each marker indicates an uncertainty that could cause rework later."
fi

# 6. Check for state tracking
if echo "$content" | grep -q "^- \[x\] \*\*Specified\*\*"; then
  log_success "Lifecycle state tracking present"
else
  log_warning "Missing lifecycle state tracking checklist" \
    "Add state tracking section to track progress:
## Story Lifecycle State Tracking
- [x] Specified - spec.md created
- [ ] Clarified - Ambiguities resolved
- [ ] Planned - plan.md created
..."
fi

# 7. Check for implementation-detail leakage (heuristic, avoid false positives)
if echo "$content" | grep -Eq '^[[:space:]]*(import|from)[[:space:]]' \
  || echo "$content" | grep -Eq '^[[:space:]]*(class|def|function)[[:space:]]+[A-Za-z_]' \
  || echo "$content" | grep -Eq '^```' \
  || echo "$content" | grep -Eq '^[[:space:]]*(GET|POST|PUT|PATCH|DELETE)[[:space:]]+/' \
  || echo "$content" | grep -Eq '\.(py|ts|tsx|js|jsx|sql)\b'; then
  log_warning "Spec may contain implementation details (code/endpoints/files detected)" \
    "Story specs should focus on WHAT and WHY, not HOW.
Move technical details to plan.md (created during /story-plan).
Keep spec.md focused on user value and requirements."
fi

# === OUTPUT RESULTS ===

if [ -f "$validation_log" ]; then
  echo "" >> "$validation_log"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$validation_log"
  echo -e "File: $file_path" >> "$validation_log"
  echo -e "Errors: ${RED}$errors${NC} | Warnings: ${YELLOW}$warnings${NC}" >> "$validation_log"
  
  if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
    echo -e "${GREEN}✓ Story spec validation passed!${NC}" >> "$validation_log"
  elif [ "$errors" -eq 0 ]; then
    echo -e "${YELLOW}Story spec has warnings. Consider addressing them before /story-plan.${NC}" >> "$validation_log"
  else
    echo -e "${RED}Story spec has errors. Fix before proceeding to /story-plan.${NC}" >> "$validation_log"
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

