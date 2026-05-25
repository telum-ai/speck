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

# Auto-detect AI Agent environment to enforce strictness on agents while remaining gentle on manual human edits.
# Checks indicators across Claude Code, Cursor, Codex, and CI/CD environments.
is_agent=false
if [[ -n "${CLAUDE_CODE:-}" || -n "${CLAUDE_AGENT_ID:-}" || -n "${CURSOR_AGENT:-}" || -n "${COMPOSER_AGENT:-}" || -n "${SPECK_STRICT:-}" || -n "${GITHUB_ACTIONS:-}" ]]; then
  is_agent=true
fi

strict=$is_agent
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

# === STEP 1: Run Python-based Template Placeholder Scanner ===
if command -v python3 >/dev/null 2>&1; then
  if ! python3 - "$file_path" << 'EOF'
import sys
import re

file_path = sys.argv[1]
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

errors = []

# Find suspected bracketed placeholders
matches = re.finditer(r'\\?\[([^\]]+)\]', content)
for m in matches:
    full_match = m.group(0)
    bracket_content = m.group(1).strip()
    
    # Ignore escaped brackets or empty/checkbox styles
    if re.match(r'^[ xXP]$', bracket_content):
        continue
        
    # Ignore short numeric/citation styles, e.g. [1], [^1]
    if re.match(r'^(\^?[0-9]+|[a-zA-Z0-9_-]+)$', bracket_content) and len(bracket_content) <= 5:
        if not any(p in bracket_content.lower() for p in ["id", "name", "topic", "type", "action", "benefit", "desc"]):
            continue
            
    # Check if followed by markdown link/ref chars: `(`, `[`, or `:`
    end_idx = m.end()
    if end_idx < len(content):
        after_text = content[end_idx:end_idx+20].strip()
        if after_text.startswith('(') or after_text.startswith('[') or after_text.startswith(':'):
            continue
        
    # Suspected bracketed placeholder
    is_placeholder = False
    lower_content = bracket_content.lower()
    
    common_terms = [
        "user type", "action", "benefit", "description", "initial state", "outcome", 
        "name", "service", "framework", "language", "entity", "relationship", "how to verify",
        "metric", "target", "security", "approach", "what this", "how the", "how to", "topic",
        "some", "here", "write", "implement", "add", "placeholder", "xxx"
    ]
    
    if any(term in lower_content for term in common_terms):
        is_placeholder = True
    elif " " in bracket_content:
        is_placeholder = True
        
    if is_placeholder:
        line_num = content[:m.start()].count('\n') + 1
        errors.append(f"Line {line_num}: Unreplaced placeholder '{full_match}' found.")

# Look for generic ID patterns
generic_id_patterns = [
    (r'\bT(X{2,}|[A-Za-z0-9_]*XXX[A-Za-z0-9_]*)\b', "Generic task ID (e.g. TXXX, T000)"),
    (r'\bFR-[A-Za-z0-9_]*XXX[A-Za-z0-9_]*\b', "Generic functional requirement ID (e.g. FR-XXX)"),
    (r'\bS(X{2,}|[A-Za-z0-9_]*XXX[A-Za-z0-9_]*)\b', "Generic story ID (e.g. SXXX)"),
    (r'\bE(X{2,}|[A-Za-z0-9_]*XXX[A-Za-z0-9_]*)\b', "Generic epic ID (e.g. EXXX)"),
]

for pattern, desc in generic_id_patterns:
    for m in re.finditer(pattern, content):
        line_num = content[:m.start()].count('\n') + 1
        errors.append(f"Line {line_num}: Found unreplaced {desc} '{m.group(0)}'.")

if errors:
    print(f"\033[0;31mERROR: Placeholder validation failed for {file_path}\033[0m")
    for err in errors:
        print(f"  \033[1;33m- {err}\033[0m")
    sys.exit(1)
sys.exit(0)
EOF
  then
    if [[ "$strict" == true ]]; then
      exit 1
    fi
  fi
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
