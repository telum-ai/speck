#!/bin/bash

# Epic Tech Spec Validator
# Validates epic-tech-spec.md files against quantitative rules
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

# 1. Check for technical approach section
if echo "$content" | grep -q "## Technical Approach\|## Architecture\|## System Design"; then
  log_success "Technical approach section found"
else
  log_error "Missing technical approach section" \
    "Add a technical approach explaining:
## Technical Approach
[How the epic will be implemented technically]"
fi

# 2. Check for technology stack section
if echo "$content" | grep -q "## Technology Stack\|## Tech Stack\|## Technologies"; then
  log_success "Technology stack section found"
else
  log_warning "Missing technology stack section" \
    "Document the technologies used:
## Technology Stack
- Backend: [Framework/language]
- Frontend: [Framework]
- Database: [Type]"
fi

# 3. Check for data model or entities section
if echo "$content" | grep -q "## Data Model\|## Entities\|## Domain Model"; then
  log_success "Data model section found"
else
  log_warning "No data model section found" \
    "Consider documenting key entities:
## Data Model
- [Entity]: [Purpose and key attributes]"
fi

# 4. Check for API contracts or interfaces
if echo "$content" | grep -q "## API\|## Contracts\|## Interfaces\|## Endpoints"; then
  log_success "API/interfaces section found"
else
  log_warning "No API/interfaces section found" \
    "Document epic-level API design:
## API Design
- [Endpoint/Interface]: [Purpose]"
fi

# 5. Check for testing strategy
if echo "$content" | grep -q "## Testing\|## Test Strategy\|## Quality"; then
  log_success "Testing strategy section found"
else
  log_warning "Missing testing strategy" \
    "Add testing approach:
## Testing Strategy
- Unit tests: [Coverage targets]
- Integration tests: [Key scenarios]"
fi

# 6. Check for story breakdown reference
if echo "$content" | grep -q "## Stories\|## Story Breakdown\|## Implementation Stories"; then
  log_success "Story breakdown section found"
else
  log_warning "No story breakdown section" \
    "Reference or list planned stories:
## Stories
See epic-breakdown.md for detailed story mapping."
fi

# 7. Check for performance considerations
if echo "$content" | grep -q "## Performance\|## Scalability\|## NFR"; then
  log_success "Performance/NFR section found"
else
  log_warning "No performance considerations" \
    "Document performance requirements:
## Performance Requirements
- [Metric]: [Target]"
fi

# 8. Check for security considerations
if echo "$content" | grep -q "## Security\|## Authentication\|## Authorization"; then
  log_success "Security section found"
else
  log_warning "No security considerations" \
    "Consider documenting security approach:
## Security
- [Security consideration]: [Approach]"
fi

# 9. Check for complexity without evidence
if echo "$content" | grep -qi "abstract\|framework\|generic\|future-proof"; then
  if ! echo "$content" | grep -qi "evidence\|measured\|users\|use cases"; then
    log_warning "Complexity mentioned without evidence" \
      "Per simplicity-first principles, add evidence for complexity:
- Performance: 'Measured X ms, target <Y ms'
- Scale: 'Must support N concurrent users'
- Abstraction: 'Same code in 3+ places'
See AGENTS.md 'Simplicity-First Principles'"
  fi
fi

# === OUTPUT RESULTS ===

if [ -f "$validation_log" ]; then
  echo "" >> "$validation_log"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$validation_log"
  echo -e "File: $file_path" >> "$validation_log"
  echo -e "Errors: ${RED}$errors${NC} | Warnings: ${YELLOW}$warnings${NC}" >> "$validation_log"
  
  if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
    echo -e "${GREEN}✓ Epic tech spec validation passed!${NC}" >> "$validation_log"
  elif [ "$errors" -eq 0 ]; then
    echo -e "${YELLOW}Epic tech spec has warnings. Consider addressing before /epic-breakdown.${NC}" >> "$validation_log"
  else
    echo -e "${RED}Epic tech spec has errors. Fix before proceeding to /epic-breakdown.${NC}" >> "$validation_log"
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

