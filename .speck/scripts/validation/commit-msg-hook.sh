#!/usr/bin/env bash

# Speck Git Commit-Message Hook Guard
# Validates that commits containing non-trivial code modifications carry at least one learning tag.
#
# To skip intentionally: git commit --no-verify

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

COMMIT_MSG_FILE="$1"

# 1. Detect if any non-trivial source code is being modified
# Filter out documentation, specs, assets, config files.
staged_code_files=()
while IFS= read -r file; do
  if [[ -f "$file" ]]; then
    ext="${file##*.}"
    # Only target standard developer source files
    if [[ "$ext" =~ ^(js|jsx|ts|tsx|py|rs|go|cs|rb|php|java|cpp|h|c|sh|swift|kt|vue|svelte|scala|pl|pm)$ ]]; then
      # Skip spec/plan files under specs/ just in case, and internal scripts
      if [[ "$file" != *"specs/"* && "$file" != *".speck/"* ]]; then
        staged_code_files+=("$file")
      fi
    fi
  fi
done < <(git diff --cached --name-only --diff-filter=ACM || true)

# If no source code files are changed, proceed without checks (zero-friction for docs/chore commits)
if [[ ${#staged_code_files[@]} -eq 0 ]]; then
  exit 0
fi

# 2. Check the commit message for learning tags
commit_text=$(cat "$COMMIT_MSG_FILE" || true)

has_learning_tag=false
if grep -q -E '(PATTERN|GOTCHA|PERF|ARCH|RULE|DEBT):' "$COMMIT_MSG_FILE"; then
  has_learning_tag=true
fi

# If we already have a learning tag, we're Golden!
if [[ "$has_learning_tag" == true ]]; then
  exit 0
fi

# 3. Detect Play Level
PLAY_LEVEL="platform" # Default fallback
PROJECT_JSON=".speck/project.json"

if [[ -f "$PROJECT_JSON" ]]; then
  # Extract play_level using basic sed (avoid jq dependency in raw git hooks)
  level=$(grep -o '"play_level"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROJECT_JSON" 2>/dev/null | sed -E 's/.*"([^"]*)"$/\1/' || true)
  if [[ -n "$level" ]]; then
    PLAY_LEVEL="$level"
  fi
fi

# 4. Enforce or Warn based on Play Level
if [[ "$PLAY_LEVEL" == "platform" ]]; then
  # Rigid Platform-level enforcement
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${RED}ERROR: Commit rejected. Non-trivial code files were modified but no Speck${NC}"
  echo -e "${RED}learning tag was found in your commit message.${NC}"
  echo -e "\n${YELLOW}Please add at least one learning tag to the commit message body:${NC}"
  echo -e "  • ${GREEN}PATTERN:${NC} - A reusable code pattern you discovered"
  echo -e "  • ${GREEN}GOTCHA:${NC}  - A surprise or pitfall you encountered"
  echo -e "  • ${GREEN}PERF:${NC}    - A performance insight or optimization"
  echo -e "  • ${GREEN}ARCH:${NC}    - An architecture decision or structural insight"
  echo -e "  • ${GREEN}RULE:${NC}    - A project Cursor rule update that is needed"
  echo -e "  • ${GREEN}DEBT:${NC}    - A technical debt that was created"
  echo -e "\n${BLUE}Example commit body:${NC}"
  echo -e "  GOTCHA: iOS cert requires Apple Developer account - 45min setup time"
  echo -e "  PERF: Query time reduced from 500ms to 50ms - Indexed on user_id"
  echo -e "\n${YELLOW}Bypass with 'git commit --no-verify' if this is a legacy chore/refactor.${NC}"
  echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  exit 1
else
  # Friendly warning for Build or Sprint level (always exit 0 to proceed)
  echo -e "${YELLOW}🥓 Wholesome Bro Warning: Staged code changed without a learning tag!${NC}"
  echo -e "Yo, bro! I noticed you are committing some sick code changes but didn't list any"
  echo -e "learning tags (like PATTERN: or GOTCHA:). If you learned anything on this run,"
  echo -e "adding a tag to your commit message helps feed our awesome retrospective loop!"
  echo -e "${GREEN}Keep crushing it, my dude! 🔥${NC}\n"
  exit 0
fi
