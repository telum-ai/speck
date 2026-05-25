#!/usr/bin/env bash
# regenerate-project-readme.sh — Refresh root README from Speck truth artifacts
#
# User-owned sections above <!-- SPECK:START --> are preserved once edited.
# Placeholder sections matching readme-template.md are auto-filled from specs.
# The SPECK:START..END footer is always managed.
#
# Usage:
#   .speck/scripts/regenerate-project-readme.sh [PROJECT_ID] [WORKSPACE_ROOT]
#
# Exit codes:
#   0 — README updated or already current
#   1 — No project found
#   2 — README exists but lacks SPECK markers (run speck upgrade to repair)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="${2:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
PROJECT_ID="${1:-}"
README_PATH="$WORKSPACE_ROOT/README.md"
TEMPLATE_PATH="$WORKSPACE_ROOT/.speck/templates/project/readme-template.md"
SPECS_ROOT="$WORKSPACE_ROOT/specs/projects"

resolve_project_id() {
  if [[ -n "$PROJECT_ID" ]]; then
    echo "$PROJECT_ID"
    return
  fi

  local pj="$WORKSPACE_ROOT/.speck/project.json"
  if [[ -f "$pj" ]]; then
    local active
    active="$(python3 -c "
import json, sys
try:
    d = json.load(open('$pj'))
    print(d.get('_active_project') or d.get('active_project') or '')
except Exception:
    print('')
" 2>/dev/null || echo '')"
    if [[ -n "$active" ]]; then
      echo "$active"
      return
    fi
  fi

  if [[ ! -d "$SPECS_ROOT" ]]; then
    echo ""
    return
  fi

  local count=0
  local sole=""
  for d in "$SPECS_ROOT"/*; do
    [[ -d "$d" ]] || continue
    sole="$(basename "$d")"
    count=$((count + 1))
  done

  if [[ "$count" -eq 1 ]]; then
    echo "$sole"
  else
    echo ""
  fi
}

extract_first_heading() {
  local file="$1"
  [[ -f "$file" ]] || return
  grep -m1 '^# ' "$file" 2>/dev/null | sed 's/^# //' || true
}

extract_project_title() {
  local project_md="$1"
  [[ -f "$project_md" ]] || return
  local title
  title="$(extract_first_heading "$project_md")"
  if [[ -n "$title" && "$title" != "Project Specification" && "$title" != "Project" ]]; then
    echo "$title"
    return
  fi
  grep -m1 '^\*\*Project Name\*\*:' "$project_md" 2>/dev/null | sed 's/^\*\*Project Name\*\*:[[:space:]]*//' || true
}

extract_paid_promise() {
  local contract="$1"
  [[ -f "$contract" ]] || return
  awk '
    /^## 1\.|^## Section 1|^# Section 1/ { in_s=1; next }
    /^## [0-9]+\./ && in_s { exit }
    in_s && /^[^#]/ && NF { gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (length($0) > 10) { print; exit } }
  ' "$contract" 2>/dev/null || true
}

extract_readiness() {
  local state="$1"
  [[ -f "$state" ]] || return
  grep -m1 '^\*\*Readiness\*\*:' "$state" 2>/dev/null | sed 's/^\*\*Readiness\*\*:[[:space:]]*//' || \
  grep -m1 'Readiness state' "$state" 2>/dev/null | sed 's/.*:[[:space:]]*//' || \
  echo "Spec phase"
}

extract_vision_blurb() {
  local project_md="$1"
  [[ -f "$project_md" ]] || return
  awk '
    /^## Vision|^## Overview|^## Problem/ { in_s=1; next }
    /^## / && in_s { exit }
    in_s && /^[^#-]/ && NF { gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (length($0) > 20) { print; exit } }
  ' "$project_md" 2>/dev/null || true
}

read_speck_version() {
  local v="$WORKSPACE_ROOT/.speck/VERSION"
  if [[ -f "$v" ]]; then
    cat "$v" | tr -d '\n'
  else
    echo "unknown"
  fi
}

section_still_placeholder() {
  local current="$1"
  local placeholder="$2"
  [[ "$current" == "$placeholder" ]] || [[ "$current" == *"$placeholder"* ]]
}

PROJECT_ID="$(resolve_project_id)"
if [[ -z "$PROJECT_ID" ]]; then
  echo "ERROR: No project ID found. Pass PROJECT_ID or set _active_project in .speck/project.json" >&2
  exit 1
fi

PROJECT_DIR="$SPECS_ROOT/$PROJECT_ID"
if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: Project directory not found: $PROJECT_DIR" >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE_PATH" ]]; then
  echo "ERROR: Missing template at $TEMPLATE_PATH" >&2
  exit 1
fi

if [[ -f "$README_PATH" ]] && ! grep -q '<!-- SPECK:START -->' "$README_PATH"; then
  echo "ERROR: README.md lacks SPECK markers. Run 'speck upgrade' to repair legacy Speck marketing README." >&2
  exit 2
fi

PROJECT_MD="$PROJECT_DIR/project.md"
CONTRACT="$PROJECT_DIR/product-contract.md"
STATE="$PROJECT_DIR/project-state.md"

TITLE="$(extract_project_title "$PROJECT_MD")"
PROMISE="$(extract_paid_promise "$CONTRACT")"
VISION="$(extract_vision_blurb "$PROJECT_MD")"
READINESS="$(extract_readiness "$STATE")"
SPECK_VER="$(read_speck_version)"

PITCH="$PROMISE"
if [[ -z "$PITCH" ]]; then
  PITCH="$VISION"
fi
if [[ -z "$PITCH" ]]; then
  PITCH="[One-line elevator pitch — what is this product/service/system?]"
fi

if [[ -z "$TITLE" ]]; then
  TITLE="[Project Name]"
fi

# Build footer (always managed)
FOOTER="<!-- SPECK:START -->
Built with [Speck 🥓](https://github.com/telum-ai/speck) — evidence-driven specification methodology (speck ${SPECK_VER}).
Methodology docs: [.speck/README.md](.speck/README.md) · Project state: [project-state.md](specs/projects/${PROJECT_ID}/project-state.md) · Decisions: [project-decisions-log.md](specs/projects/${PROJECT_ID}/project-decisions-log.md)
<!-- SPECK:END -->"

# Parse existing user body or start from template
if [[ -f "$README_PATH" ]]; then
  USER_BODY="$(python3 -c "
import re, sys
content = open('$README_PATH').read()
m = re.search(r'^(.*?)(?=<!-- SPECK:START -->)', content, re.DOTALL)
print(m.group(1).rstrip() if m else content.rstrip())
")"
else
  USER_BODY="$(python3 -c "
import re
t = open('$TEMPLATE_PATH').read()
m = re.search(r'^(.*?)(?=<!-- SPECK:START -->)', t, re.DOTALL)
print(m.group(1).rstrip() if m else t.rstrip())
")"
fi

# Apply placeholder-safe fills
update_line() {
  local pattern="$1"
  local replacement="$2"
  USER_BODY="$(echo "$USER_BODY" | python3 -c "
import re, sys
pattern = sys.argv[1]
repl = sys.argv[2]
body = sys.stdin.read()
if re.search(pattern, body, re.MULTILINE):
    body = re.sub(pattern, repl, body, count=1, flags=re.MULTILINE)
print(body, end='')
" "$pattern" "$replacement")"
}

if section_still_placeholder "$(echo "$USER_BODY" | head -1)" "# [Project Name]"; then
  update_line '^# \[Project Name\]' "# $TITLE"
fi

if echo "$USER_BODY" | grep -q '> \[One-line elevator pitch'; then
  update_line '^> \[One-line elevator pitch[^\]]*\]' "> $PITCH"
fi

if echo "$USER_BODY" | grep -q 'PROJECT_ID'; then
  USER_BODY="$(echo "$USER_BODY" | sed "s|PROJECT_ID|${PROJECT_ID}|g")"
fi

if echo "$USER_BODY" | grep -q '\*\*Status\*\*: Spec phase'; then
  update_line '^\*\*Status\*\*: Spec phase' "**Status**: ${READINESS}"
fi

if echo "$USER_BODY" | grep -q '\[Project description — placeholder for user to fill\]'; then
  if [[ -n "$VISION" && "$VISION" != "$PITCH" ]]; then
    update_line '^\[Project description — placeholder for user to fill\]' "$VISION"
  fi
fi

# Write final README
{
  echo "$USER_BODY"
  echo ""
  echo "$FOOTER"
  echo ""
} > "$README_PATH"

echo "README_REGENERATED project=${PROJECT_ID} title=${TITLE}"
exit 0
