#!/usr/bin/env bash
set -euo pipefail

# Speck context helper.
#
# Prints project/epic/story context files in inheritance order. This is a
# convenience tool for humans and agents; the authoritative sources are the
# context.md files themselves.

PROJECT=""
EPIC=""
STORY=""
JSON_MODE=false

usage() {
  cat <<'EOF'
Usage:
  .speck/scripts/bash/get-context.sh --project <PROJECT_DIR_NAME> [--epic <EPIC_DIR_NAME>] [--story <STORY_DIR_NAME>] [--json]

Examples:
  .speck/scripts/bash/get-context.sh --project 001-my-app
  .speck/scripts/bash/get-context.sh --project 001-my-app --epic 002-auth --story 001-login
EOF
}

is_pathish() {
  case "$1" in
    /*|./*|../*) return 0 ;;
    *) return 1 ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT="${2:-}"; shift 2 ;;
    --epic) EPIC="${2:-}"; shift 2 ;;
    --story) STORY="${2:-}"; shift 2 ;;
    --json) JSON_MODE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: --project is required" >&2
  usage
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

project_dir="$REPO_ROOT/specs/projects/$PROJECT"
if is_pathish "$PROJECT"; then
  project_dir="$PROJECT"
fi

if [[ ! -d "$project_dir" ]]; then
  echo "ERROR: Project directory not found: $project_dir" >&2
  exit 1
fi

epic_dir=""
story_dir=""

if [[ -n "$EPIC" ]]; then
  epic_dir="$project_dir/epics/$EPIC"
  if is_pathish "$EPIC"; then
    epic_dir="$EPIC"
  fi
  if [[ ! -d "$epic_dir" ]]; then
    echo "ERROR: Epic directory not found: $epic_dir" >&2
    exit 1
  fi
fi

if [[ -n "$STORY" ]]; then
  if [[ -z "$epic_dir" ]]; then
    echo "ERROR: --story requires --epic (story paths are nested under an epic)" >&2
    exit 1
  fi
  story_dir="$epic_dir/stories/$STORY"
  if is_pathish "$STORY"; then
    story_dir="$STORY"
  fi
  if [[ ! -d "$story_dir" ]]; then
    echo "ERROR: Story directory not found: $story_dir" >&2
    exit 1
  fi
fi

project_context="$project_dir/context.md"
epic_context=""
story_context=""

if [[ -n "$epic_dir" ]]; then
  epic_context="$epic_dir/context.md"
fi

if [[ -n "$story_dir" ]]; then
  story_context="$story_dir/context.md"
fi

if [[ "$JSON_MODE" = true ]]; then
  export SPECK_CONTEXT_PROJECT_DIR="$project_dir"
  export SPECK_CONTEXT_EPIC_DIR="$epic_dir"
  export SPECK_CONTEXT_STORY_DIR="$story_dir"
  export SPECK_CONTEXT_PROJECT_FILE="$project_context"
  export SPECK_CONTEXT_EPIC_FILE="$epic_context"
  export SPECK_CONTEXT_STORY_FILE="$story_context"

  python3 - <<'PY'
import json, os

def exists(p: str) -> bool:
    return bool(p) and os.path.isfile(p)

print(json.dumps(
    {
        "project_dir": os.environ.get("SPECK_CONTEXT_PROJECT_DIR", ""),
        "epic_dir": os.environ.get("SPECK_CONTEXT_EPIC_DIR", ""),
        "story_dir": os.environ.get("SPECK_CONTEXT_STORY_DIR", ""),
        "files": {
            "project_context": {
                "path": os.environ.get("SPECK_CONTEXT_PROJECT_FILE", ""),
                "exists": exists(os.environ.get("SPECK_CONTEXT_PROJECT_FILE", "")),
            },
            "epic_context": {
                "path": os.environ.get("SPECK_CONTEXT_EPIC_FILE", ""),
                "exists": exists(os.environ.get("SPECK_CONTEXT_EPIC_FILE", "")),
            },
            "story_context": {
                "path": os.environ.get("SPECK_CONTEXT_STORY_FILE", ""),
                "exists": exists(os.environ.get("SPECK_CONTEXT_STORY_FILE", "")),
            },
        },
        "note": "Context inheritance order: project → epic → story. Missing files simply mean no additional context at that level.",
    },
    indent=2,
))
PY
  exit 0
fi

echo "# Speck Context Snapshot"
echo ""
echo "- Project: $(basename "$project_dir")"
if [[ -n "$epic_dir" ]]; then
  echo "- Epic: $(basename "$epic_dir")"
fi
if [[ -n "$story_dir" ]]; then
  echo "- Story: $(basename "$story_dir")"
fi
echo "- Generated (UTC): $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

echo "## Project Context"
echo "_File_: \`$project_context\`"
echo ""
if [[ -f "$project_context" ]]; then
  cat "$project_context"
else
  echo "_No project context.md found._"
fi
echo ""

if [[ -n "$epic_context" ]]; then
  echo "## Epic Context"
  echo "_File_: \`$epic_context\`"
  echo ""
  if [[ -f "$epic_context" ]]; then
    cat "$epic_context"
  else
    echo "_No epic context.md found._"
  fi
  echo ""
fi

if [[ -n "$story_context" ]]; then
  echo "## Story Context"
  echo "_File_: \`$story_context\`"
  echo ""
  if [[ -f "$story_context" ]]; then
    cat "$story_context"
  else
    echo "_No story context.md found._"
  fi
  echo ""
fi


