#!/usr/bin/env bash
# regenerate-project-readme.sh — Refresh root README from Speck truth artifacts
#
# Usage:
#   regenerate-project-readme.sh [OPTIONS] [PROJECT_ID] [WORKSPACE_ROOT]
#
# Options:
#   --check              Drift check only, no writes
#   --surface=package|landing|og   Target a PROFILE surface
#   --epic-validated=E###  Update magic-moments table after epic validate PASS
#
# Exit: 0 ok, 1 no project, 2 README lacks SPECK markers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=profile-lib.sh
source "$SCRIPT_DIR/profile-lib.sh"

CHECK_ONLY=false
SURFACE=""
EPIC_VALIDATED=""
PROJECT_ID=""
WORKSPACE_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK_ONLY=true; shift ;;
    --surface=*) SURFACE="${1#*=}"; shift ;;
    --epic-validated=*) EPIC_VALIDATED="${1#*=}"; shift ;;
    --epic-validated) EPIC_VALIDATED="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$PROJECT_ID" ]]; then PROJECT_ID="$1"
      elif [[ -z "$WORKSPACE_ROOT" || "$WORKSPACE_ROOT" == "$1" ]]; then WORKSPACE_ROOT="$1"
      fi
      shift
      ;;
  esac
done

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
README_PATH="$WORKSPACE_ROOT/README.md"
TEMPLATE_PATH="$WORKSPACE_ROOT/.speck/templates/project/readme-template.md"
SPECS_ROOT="$WORKSPACE_ROOT/specs/projects"

PROJECT_ID="$(profile_resolve_project_id "$WORKSPACE_ROOT" "$PROJECT_ID")"
if [[ -z "$PROJECT_ID" ]]; then
  echo "ERROR: No project ID found" >&2
  exit 1
fi

PROJECT_DIR="$SPECS_ROOT/$PROJECT_ID"
PROJECT_MD="$PROJECT_DIR/project.md"
CONTRACT="$PROJECT_DIR/product-contract.md"
STATE="$PROJECT_DIR/project-state.md"

if [[ "$CHECK_ONLY" == true || "$SURFACE" == "check" ]]; then
  exec "$SCRIPT_DIR/profile-drift-check.sh" "$WORKSPACE_ROOT" "$PROJECT_ID"
fi

if [[ "$SURFACE" == "landing" || "$SURFACE" == "og" ]]; then
  PROMISE="$(profile_extract_paid_promise "$CONTRACT")"
  echo "PROFILE_SURFACE_CHECK surface=${SURFACE} project=${PROJECT_ID}"
  # Check-only: grep common landing paths for hero copy overlap
  for f in "$WORKSPACE_ROOT"/app/**/page.tsx "$WORKSPACE_ROOT"/src/**/landing*.tsx; do
    [[ -f "$f" ]] || continue
    if [[ -n "$PROMISE" ]] && grep -qi "$(echo "$PROMISE" | cut -c1-40)" "$f" 2>/dev/null; then
      echo "  OK: $f appears aligned with paid promise"
    else
      echo "  WARN: $f may drift from product-contract Section 1"
    fi
  done
  exit 0
fi

if [[ "$SURFACE" == "package" ]]; then
  PITCH="$(profile_extract_readme_oneliner "$README_PATH")"
  PKG="$WORKSPACE_ROOT/package.json"
  if [[ -f "$PKG" && -n "$PITCH" ]]; then
    python3 -c "
import json, sys
p = sys.argv[1]
with open('$PKG') as f: d = json.load(f)
cur = d.get('description', '')
if not cur or cur.startswith('REPLACE') or len(cur) < 5:
    d['description'] = p[:160]
    with open('$PKG', 'w') as f: json.dump(d, f, indent=2); f.write('\n')
    print('PACKAGE_DESCRIPTION_UPDATED')
else:
    print('PACKAGE_DESCRIPTION_PRESERVED (user-owned)')
" "$PITCH"
  fi
  exit 0
fi

if [[ ! -f "$TEMPLATE_PATH" ]]; then
  echo "ERROR: Missing template at $TEMPLATE_PATH" >&2
  exit 1
fi

if [[ -f "$README_PATH" ]] && ! grep -q '<!-- SPECK:START -->' "$README_PATH"; then
  echo "ERROR: README.md lacks SPECK markers. Run 'speck upgrade'." >&2
  exit 2
fi

extract_project_title() {
  local project_md="$1"
  [[ -f "$project_md" ]] || return
  local title
  title="$(grep -m1 '^# ' "$project_md" 2>/dev/null | sed 's/^# //' || true)"
  if [[ -n "$title" && "$title" != "Project Specification" && "$title" != "Project" ]]; then
    echo "$title"; return
  fi
  grep -m1 '^\*\*Project Name\*\*:' "$project_md" 2>/dev/null | sed 's/^\*\*Project Name\*\*:[[:space:]]*//' || true
}

extract_readiness() {
  local state="$1"
  [[ -f "$state" ]] || return
  grep -m1 '^\*\*Readiness\*\*:' "$state" 2>/dev/null | sed 's/^\*\*Readiness\*\*:[[:space:]]*//' || \
  grep -m1 'Readiness state' "$state" 2>/dev/null | sed 's/.*:[[:space:]]*//' || echo "Spec phase"
}

extract_vision_blurb() {
  local project_md="$1"
  [[ -f "$project_md" ]] || return
  awk '/^## Vision|^## Overview|^## Problem/ { in_s=1; next } /^## / && in_s { exit } in_s && /^[^#-]/ && NF { gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (length($0) > 20) { print; exit } }' "$project_md" 2>/dev/null || true
}

TITLE="$(extract_project_title "$PROJECT_MD")"
PROMISE="$(profile_extract_paid_promise "$CONTRACT")"
VISION="$(extract_vision_blurb "$PROJECT_MD")"
READINESS="$(extract_readiness "$STATE")"
SPECK_VER="$(profile_read_speck_version "$WORKSPACE_ROOT")"

PITCH="$PROMISE"
[[ -z "$PITCH" ]] && PITCH="$VISION"
[[ -z "$PITCH" ]] && PITCH="[One-line elevator pitch — what is this product/service/system?]"
[[ -z "$TITLE" ]] && TITLE="[Project Name]"

FOOTER="<!-- SPECK:START -->
Built with [Speck 🥓](https://github.com/telum-ai/speck) — evidence-driven specification methodology (speck ${SPECK_VER}).
Methodology docs: [.speck/README.md](.speck/README.md) · Project state: [project-state.md](specs/projects/${PROJECT_ID}/project-state.md) · Decisions: [project-decisions-log.md](specs/projects/${PROJECT_ID}/project-decisions-log.md)
<!-- SPECK:END -->"

if [[ -f "$README_PATH" ]]; then
  USER_BODY="$(python3 -c "
import re
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

# AUTO-SYNC blocks (always overwrite from source)
USER_BODY="$(python3 << PYEOF
import re, os

body = """$USER_BODY"""
project_dir = "$PROJECT_DIR"
contract = os.path.join(project_dir, "product-contract.md")

def extract_section1(path):
    if not os.path.isfile(path):
        return ""
    in_s = False
    for line in open(path):
        if re.match(r'^## 1\.|^## Section 1', line):
            in_s = True
            continue
        if in_s and re.match(r'^## [0-9]+\.', line):
            break
        if in_s and line.strip() and not line.startswith('#'):
            return line.strip()
    return ""

pattern = re.compile(
    r'<!-- PROFILE:AUTO-SYNC source=([^ ]+) section=([0-9]+) -->\s*[\s\S]*?\s*<!-- /PROFILE:AUTO-SYNC -->',
    re.MULTILINE
)

def replacer(m):
    src = m.group(1)
    sec = m.group(2)
    path = os.path.join(project_dir, src) if not src.startswith('/') else src
    if sec == '1' and 'product-contract' in src:
        text = extract_section1(path)
        if text:
            return f'<!-- PROFILE:AUTO-SYNC source={src} section={sec} -->\n> {text}\n<!-- /PROFILE:AUTO-SYNC -->'
    return m.group(0)

body = pattern.sub(replacer, body)
print(body, end='')
PYEOF
)"

section_still_placeholder() {
  local current="$1" placeholder="$2"
  [[ "$current" == "$placeholder" ]] || [[ "$current" == *"$placeholder"* ]]
}

update_line() {
  local pattern="$1" replacement="$2"
  USER_BODY="$(echo "$USER_BODY" | python3 -c "
import re, sys
pattern, repl = sys.argv[1], sys.argv[2]
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

# Epic-validated: update magic moments table row if section exists
if [[ -n "$EPIC_VALIDATED" ]]; then
  EPIC_DIR="$PROJECT_DIR/epics/${EPIC_VALIDATED}"
  VAL_REPORT="$EPIC_DIR/epic-validation-report.md"
  READINESS_EPIC="pending"
  VAL_DATE="$(date +%Y-%m-%d)"
  if [[ -f "$VAL_REPORT" ]]; then
    READINESS_EPIC="$(grep -m1 'Readiness' "$VAL_REPORT" 2>/dev/null | sed 's/.*:[[:space:]]*//' || echo 'validated')"
  fi
  if echo "$USER_BODY" | grep -q '## Magic moments'; then
    USER_BODY="$(echo "$USER_BODY" | sed "s/| ${EPIC_VALIDATED} .* |/| ${EPIC_VALIDATED} | ✅ ${READINESS_EPIC} | ${VAL_DATE} |/" 2>/dev/null || echo "$USER_BODY")"
  fi
  if echo "$USER_BODY" | grep -q '## Recently validated'; then
    USER_BODY="${USER_BODY}

- **${EPIC_VALIDATED}** — ${READINESS_EPIC} (${VAL_DATE})"
  fi
fi

{
  echo "$USER_BODY"
  echo ""
  echo "$FOOTER"
  echo ""
} > "$README_PATH"

echo "README_REGENERATED project=${PROJECT_ID} title=${TITLE}"
exit 0
