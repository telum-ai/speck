#!/usr/bin/env bash

# Central Automated Template Validation Router
# Routes Speck artifacts to their respective validators.
#
# Usage:
#   bash validate-template.sh <file_path> [--strict]
#
# Accepts:
#   file_path: Relative or absolute path to the file to validate.
#   --strict:  Exit with non-zero code on validation errors.

set -euo pipefail

strict=false
file_path=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      strict=true
      shift
      ;;
    *)
      if [[ -z "$file_path" ]]; then
        file_path="$1"
      else
        echo "ERROR: Unknown or duplicate argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$file_path" ]]; then
  echo "ERROR: Missing file path argument" >&2
  exit 1
fi

# Skip if file doesn't exist
if [[ ! -f "$file_path" ]]; then
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

# Determine validation type by filename
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
  *)
    # Not a tracked template, skip
    exit 0
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
strict_flag=""
if [[ "$strict" == true ]]; then
  strict_flag="--strict"
fi

# Run validator
case "$validation_type" in
  story-spec)
    bash "$SCRIPT_DIR/validators/validate-story-spec.sh" $strict_flag "$file_path"
    ;;
  epic-spec)
    bash "$SCRIPT_DIR/validators/validate-epic-spec.sh" $strict_flag "$file_path"
    ;;
  story-plan)
    bash "$SCRIPT_DIR/validators/validate-story-plan.sh" $strict_flag "$file_path"
    ;;
  story-tasks)
    bash "$SCRIPT_DIR/validators/validate-story-tasks.sh" $strict_flag "$file_path"
    ;;
  epic-tech-spec)
    bash "$SCRIPT_DIR/validators/validate-epic-tech-spec.sh" $strict_flag "$file_path"
    ;;
esac
