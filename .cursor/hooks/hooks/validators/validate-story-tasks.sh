#!/bin/bash

# Story Tasks Validator
# Validates tasks.md files against quantitative rules
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

# 1. Check for YAML frontmatter with status tracking
if echo "$content" | grep -q "^---$" && echo "$content" | sed -n '/^---$/,/^---$/p' | grep -q "status:"; then
  log_success "YAML frontmatter with status tracking found"
  
  # Extract status value
  status=$(echo "$content" | sed -n '/^---$/,/^---$/p' | grep "status:" | sed 's/.*status:[[:space:]]*//' | tr -d '"')
  if [ -n "$status" ]; then
    case "$status" in
      pending|in_progress|completed)
        log_success "Status is valid: $status"
        ;;
      *)
        log_warning "Status has unexpected value: $status" \
          "Use one of: pending | in_progress | completed
These values help the orchestrator track implementation progress."
        ;;
    esac
  fi
else
  log_warning "Missing YAML frontmatter with status tracking" \
    "Add YAML frontmatter at the top of tasks.md for orchestration:
---
status: pending  # pending | in_progress | completed
---

The orchestrator uses this to detect implementation progress."
fi

# 2. Count total tasks (accept [ ] + [x]/[X])
total_tasks=$(echo "$content" | grep -E -c "^- \[[ xX]\] T[0-9]+")
completed_tasks=$(echo "$content" | grep -E -c "^- \[[xX]\] T[0-9]+")

if [ "$total_tasks" -eq 0 ]; then
  log_error "No tasks found in tasks.md" \
    "Add tasks using format:
- [ ] T001 [Description]
- [ ] T002 [Description]

Tasks should be concrete, actionable items from plan.md."
else
  log_success "Has $total_tasks task(s), $completed_tasks completed"
  
  # Check for too many tasks
  if [ "$total_tasks" -gt 20 ]; then
    log_warning "Story has many tasks ($total_tasks > 20)" \
      "Consider breaking into multiple stories. Stories with >20 tasks are hard to review.
Apply simplicity-first: Can this be done in <100 lines of code?"
  fi
  
  # Calculate completion percentage
  if [ "$total_tasks" -gt 0 ]; then
    completion_pct=$((completed_tasks * 100 / total_tasks))
    if [ "$completion_pct" -eq 100 ]; then
      log_success "All tasks complete! Ready for /story-validate"
    elif [ "$completion_pct" -gt 0 ]; then
      log_success "Progress: $completion_pct% complete ($completed_tasks/$total_tasks)"
    fi
  fi
fi

# 3. Check for phase organization (accept legacy '## Phase' and current '### Phase')
if echo "$content" | grep -E -q "^##+ Phase"; then
  log_success "Tasks organized into phases"
  
  # Count phases
  phase_count=$(echo "$content" | grep -E -c "^##+ Phase")
  if [ "$phase_count" -gt 5 ]; then
    log_warning "Many phases ($phase_count > 5)" \
      "Consider simplifying. Too many phases suggests over-planning.
Typical story: 3-4 phases (Setup, Core, Tests, Docs)"
  fi
else
  log_warning "Tasks not organized into phases" \
    "Organize tasks using phases for clarity:
### Phase 1: Setup
- [ ] T001 ...

### Phase 2: Core Implementation
- [ ] T002 ..."
fi

# 4. Check for parallel tasks marker [P]
parallel_tasks=$(echo "$content" | grep -c "\[P\]")
if [ "$parallel_tasks" -gt 0 ]; then
  log_success "Has $parallel_tasks task(s) marked for parallel execution"
else
  log_warning "No parallel tasks marked" \
    "Mark independent tasks with [P] for parallel execution:
- [ ] T004 [P] Write unit tests for X
- [ ] T005 [P] Write unit tests for Y

Speeds up implementation by allowing concurrent work."
fi

# 5. Check for test tasks
test_tasks=$(echo "$content" | grep -i -c "test\|spec")
if [ "$test_tasks" -eq 0 ]; then
  log_warning "No test tasks found" \
    "Add test tasks following TDD approach:
- [ ] TXXX Write failing test for [feature]
- [ ] TXXX Implement [feature] to pass test
- [ ] TXXX Remove .skip() marker from test

See @testing.mdc for patterns."
else
  log_success "Has $test_tasks test-related task(s)"
fi

# 6. Check for task IDs in sequence
task_ids=$(echo "$content" | grep -o "T[0-9]\+" | sed 's/T//' | sort -n)
if [ -n "$task_ids" ]; then
  # Check for gaps
  expected=1
  has_gaps=false
  for id in $task_ids; do
    if [ "$id" -ne "$expected" ]; then
      has_gaps=true
      break
    fi
    expected=$((expected + 1))
  done
  
  if [ "$has_gaps" = true ]; then
    log_warning "Task IDs have gaps in sequence" \
      "Use sequential IDs: T001, T002, T003...
Makes it easier to reference and track tasks."
  else
    log_success "Task IDs are sequential"
  fi
fi

# 7. Check for ambiguous task descriptions
if echo "$content" | grep -q "TODO\|FIXME\|TBD\|\[?\]"; then
  log_warning "Found ambiguous task descriptions (TODO/FIXME/TBD)" \
    "Make all tasks concrete and actionable.
Replace 'TODO: figure out' with specific tasks.
If uncertain, run /story-clarify before creating tasks."
fi

# 8. Check for simplicity (line count of new code)
if echo "$content" | grep -qi "new file\|create file"; then
  new_files=$(echo "$content" | grep -c -i "new file\|create file")
  if [ "$new_files" -gt 3 ]; then
    log_warning "Story creates many new files ($new_files > 3)" \
      "Simplicity-first principle: Start with single file until proven insufficient.
Only add files when you have evidence of need (3+ use cases).
Review: Can this be simpler?"
  fi
fi

# === OUTPUT RESULTS ===

if [ -f "$validation_log" ]; then
  echo "" >> "$validation_log"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$validation_log"
  echo -e "File: $file_path" >> "$validation_log"
  echo -e "Errors: ${RED}$errors${NC} | Warnings: ${YELLOW}$warnings${NC}" >> "$validation_log"
  
  if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
    echo -e "${GREEN}✓ Tasks validation passed!${NC}" >> "$validation_log"
  elif [ "$errors" -eq 0 ]; then
    echo -e "${YELLOW}Tasks have warnings. Consider addressing them.${NC}" >> "$validation_log"
  else
    echo -e "${RED}Tasks have errors. Fix before /story-implement.${NC}" >> "$validation_log"
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

