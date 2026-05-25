#!/usr/bin/env bash
# Lifecycle-aware Stop-hook gate for Speck v7.8+
#
# Exit 0 = allow stop
# Exit 1 = informational warning (still allows stop — never infinite-loop)
# Exit 2 = hard block (unused by default; reserved for future gates)

set -euo pipefail

SCOPE="workspace"
STORY_DIR=""

# Walk up from PWD to find a story directory (robust vs cwd-only regex)
check_dir="${PWD}"
while [[ "$check_dir" != "/" && -n "$check_dir" ]]; do
  base="$(basename "$check_dir")"
  if [[ "$base" =~ ^S[0-9]{3}- ]]; then
    parent="$(basename "$(dirname "$check_dir")")"
    if [[ "$parent" == "stories" ]]; then
      epic_dir="$(basename "$(dirname "$(dirname "$check_dir")")")"
      if [[ "$epic_dir" =~ ^E[0-9]{3}- ]]; then
        STORY_DIR="$check_dir"
        SCOPE="story"
        break
      fi
    fi
  fi
  check_dir="$(dirname "$check_dir")"
done

if [[ "$SCOPE" != "story" ]]; then
  # Epic / project / workspace — never gate on tasks.md
  exit 0
fi

if [[ ! -f "$STORY_DIR/tasks.md" ]]; then
  echo "Stop gate (info): no tasks.md in $(basename "$STORY_DIR") — expected before /story-implement, not at epic/project phases" >&2
  exit 0
fi

STATUS="$(awk '/^---$/{f=!f; next} f && /^status:/{print $2; exit}' "$STORY_DIR/tasks.md" 2>/dev/null || true)"

if [[ -z "$STATUS" ]]; then
  echo "Stop gate (info): tasks.md in $(basename "$STORY_DIR") lacks YAML status — set before /story-validate" >&2
  exit 1
fi

exit 0
