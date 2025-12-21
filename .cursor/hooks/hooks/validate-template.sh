#!/bin/bash

# Automated Template Validation Hook
# Runs after file edits to validate Speck artifacts against quantitative rules
# Provides enriched error messages with remediation guidance

# NOTE: Hooks should never crash the editor experience. If dependencies (jq/python)
# are missing or input is malformed, we skip validation gracefully.

set -euo pipefail

# Read input from stdin (file_path and edits)
input=$(cat)

# Extract file_path from Cursor hook JSON input.
file_path=""
if command -v jq >/dev/null 2>&1; then
  file_path=$(echo "$input" | jq -r '.file_path' 2>/dev/null || true)
elif command -v python3 >/dev/null 2>&1; then
  file_path=$(python3 -c 'import json,sys; print((json.loads(sys.stdin.read() or "{}").get("file_path") or ""))' <<<"$input" 2>/dev/null || true)
fi

if [[ -z "$file_path" || "$file_path" == "null" ]]; then
  exit 0
fi

# Only validate Speck artifacts (not code, not .cursor, not .speck)
if [[ "$file_path" == *".cursor/"* ]] || [[ "$file_path" == *".speck/"* ]]; then
  exit 0
fi

# Only validate markdown files in specs/ directory
if [[ "$file_path" != *"specs/"* ]] || [[ "$file_path" != *".md" ]]; then
  exit 0
fi

# Determine file type by name
filename=$(basename "$file_path")
case "$filename" in
  spec.md)
    validation_type="story-spec"
    ;;
  epic.md)
    validation_type="epic-spec"
    ;;
  plan.md)
    validation_type="story-plan"
    ;;
  tasks.md)
    validation_type="story-tasks"
    ;;
  epic-tech-spec.md)
    validation_type="epic-tech-spec"
    ;;
  validation-report.md)
    validation_type="validation-report"
    ;;
  PRD.md)
    validation_type="prd"
    ;;
  *)
    # Not a known template, skip validation
    exit 0
    ;;
esac

# Run validation based on type
case "$validation_type" in
  story-spec)
    bash "$(dirname "$0")/validators/validate-story-spec.sh" "$file_path"
    ;;
  epic-spec)
    bash "$(dirname "$0")/validators/validate-epic-spec.sh" "$file_path"
    ;;
  story-plan)
    bash "$(dirname "$0")/validators/validate-story-plan.sh" "$file_path"
    ;;
  story-tasks)
    bash "$(dirname "$0")/validators/validate-story-tasks.sh" "$file_path"
    ;;
  epic-tech-spec)
    bash "$(dirname "$0")/validators/validate-epic-tech-spec.sh" "$file_path"
    ;;
  *)
    # No validator implemented yet
    exit 0
    ;;
esac

exit 0

