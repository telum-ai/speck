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

# 2. Count tasks. EVERY marker enters the denominator; only [x]/[X] is complete.
#
# The bug this replaces (#107, found in the field on E000/S004): the total was counted with the
# character class `[ xX]`, so a task marked `[!]` matched NEITHER the total NOR the completed
# pattern. It did not read as incomplete — it was ERASED. A tasks.md with 18 tasks, 5 of them
# blocked, reported "13 of 13 complete · Ready for /story-validate", and one of the vanished five
# was the load-bearing observation task for AC-1.
#
# That is the dark-gate shape: a green that never had the chance to catch what it exists to catch,
# and the failure direction leaves no trace, because a story whose blocked work disappeared and a
# story that is genuinely done print the same line.
#
# So the denominator is now `\[.\]` — any single-character marker. A task is a task whatever glyph
# its author reached for, and a marker this validator has never heard of must change the count it
# cannot be silently dropped from. Classification is the narrow part:
#   [x] [X]  complete
#   [!]      BLOCKED — reported separately, and it suppresses the Ready verdict outright
#   [ ]      incomplete, the ordinary case
#   anything else  incomplete AND NAMED, because an unrecognised marker resolving quietly to
#                  "not done" is how the next `[!]` gets invented and silently mis-read again.
#
# `[!]` was never in tasks-template.md — it is a field convention this validator had no vocabulary
# for. It is documented in the template now, so the fix is not just this regex.
total_tasks=$(echo "$content" | grep -E -c "^- \[.\] T[0-9]+")
completed_tasks=$(echo "$content" | grep -E -c "^- \[[xX]\] T[0-9]+")
blocked_tasks=$(echo "$content" | grep -E -c "^- \[!\] T[0-9]+")
unknown_markers=$(echo "$content" | grep -E "^- \[.\] T[0-9]+" | grep -E -v "^- \[[ xX!]\] T[0-9]+" || true)
unknown_count=0
if [ -n "$unknown_markers" ]; then
  unknown_count=$(echo "$unknown_markers" | grep -c . || true)
fi

if [ "$total_tasks" -eq 0 ]; then
  log_error "No tasks found in tasks.md" \
    "Add tasks using format:
- [ ] T001 [Description]
- [ ] T002 [Description]

Tasks should be concrete, actionable items from plan.md."
else
  log_success "Has $total_tasks task(s), $completed_tasks completed, $blocked_tasks blocked"

  # A blocked task is a FINDING, not a footnote. It is the story telling you, in its own file, that
  # acceptance-critical work cannot proceed — so it is surfaced whether or not anything else is
  # wrong, and it is an error under --strict rather than a line someone might scroll past.
  if [ "$blocked_tasks" -gt 0 ]; then
    blocked_list=$(echo "$content" | grep -E "^- \[!\] T[0-9]+" | sed 's/^/    /')
    if [ "$strict" = true ]; then
      log_error "$blocked_tasks task(s) marked BLOCKED [!] — this story is not ready to advance" \
        "Unblock or re-scope them, then re-run. Blocked tasks:
$blocked_list

A blocked task is not an incomplete task you can finish later in the same pass — it is a
dependency the story cannot satisfy on its own. Advancing past it moves the block downstream
where it costs more to find."
    else
      log_warning "$blocked_tasks task(s) marked BLOCKED [!]" \
        "Blocked tasks:
$blocked_list"
    fi
  fi

  # An unrecognised marker is neither complete nor honestly incomplete — it is unreadable, and the
  # validator says so rather than folding it into a count it cannot justify.
  if [ "$unknown_count" -gt 0 ]; then
    log_warning "$unknown_count task(s) use a marker this validator does not recognise" \
      "Counted as INCOMPLETE. Use [ ] pending · [x] complete · [!] blocked.
$(echo "$unknown_markers" | sed 's/^/    /')"
  fi

  # Check for too many tasks
  if [ "$total_tasks" -gt 20 ]; then
    log_warning "Story has many tasks ($total_tasks > 20)" \
      "Consider breaking into multiple stories. Stories with >20 tasks are hard to review.
Apply simplicity-first: Can this be done in <100 lines of code?"
  fi
  
  # Calculate completion percentage
  if [ "$total_tasks" -gt 0 ]; then
    completion_pct=$((completed_tasks * 100 / total_tasks))
    # The Ready verdict is guarded on the blocked count as well as the percentage, and the
    # redundancy is deliberate. Fixing the denominator already makes 13-of-18 read 72%, so this
    # branch is unreachable while the count is right — which is exactly why it is here. #107 was a
    # counting bug that reached the field as a WRONG VERDICT, and the verdict should not depend on
    # one arithmetic expression staying correct forever. A story with an explicitly blocked task is
    # not ready, at any percentage.
    if [ "$blocked_tasks" -gt 0 ]; then
      log_success "Progress: $completion_pct% complete ($completed_tasks/$total_tasks) — NOT ready: $blocked_tasks blocked"
    elif [ "$completion_pct" -eq 100 ]; then
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

See Speck docs in \`.speck/README.md\` (or your project’s \`.cursor/rules/\` if you maintain one)."
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
