#!/usr/bin/env bash
# profile-lib.sh — Shared PROFILE extraction helpers (sourced, not executed)

profile_resolve_project_id() {
  local workspace_root="$1"
  local project_id="${2:-}"
  local specs_root="$workspace_root/specs/projects"

  if [[ -n "$project_id" ]]; then
    echo "$project_id"
    return
  fi

  local pj="$workspace_root/.speck/project.json"
  if [[ -f "$pj" ]]; then
    local active
    active="$(python3 -c "
import json
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

  if [[ ! -d "$specs_root" ]]; then
    echo ""
    return
  fi

  local count=0 sole=""
  for d in "$specs_root"/*; do
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

profile_extract_paid_promise() {
  local contract="$1"
  [[ -f "$contract" ]] || return
  awk '
    /^## 1\.|^## Section 1|^# Section 1/ { in_s=1; next }
    /^## [0-9]+\./ && in_s { exit }
    in_s && /^[^#]/ && NF { gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (length($0) > 10) { print; exit } }
  ' "$contract" 2>/dev/null || true
}

profile_extract_readme_oneliner() {
  local readme="$1"
  [[ -f "$readme" ]] || return
  grep -m1 '^> ' "$readme" 2>/dev/null | sed 's/^> //' || true
}

profile_read_speck_version() {
  local workspace_root="$1"
  local v="$workspace_root/.speck/VERSION"
  if [[ -f "$v" ]]; then
    tr -d '\n' < "$v"
  else
    echo "unknown"
  fi
}

profile_token_overlap_pct() {
  local a="$1"
  local b="$2"
  python3 -c "
import re, sys
a, b = sys.argv[1], sys.argv[2]

def tokens(s):
    return set(re.findall(r'[a-zA-Z0-9]{3,}', s.lower()))

ta, tb = tokens(a), tokens(b)
if not ta or not tb:
    print('0')
    sys.exit(0)
inter = len(ta & tb)
shorter = min(len(ta), len(tb))
print(int(round(100 * inter / shorter)))
" "$a" "$b" 2>/dev/null || echo "0"
}

profile_has_orphan_placeholders() {
  local readme="$1"
  [[ -f "$readme" ]] || return 1
  grep -q '\[Project Name\]' "$readme" && return 0
  grep -q 'PROJECT_ID' "$readme" && return 0
  grep -q '\[One-line elevator pitch' "$readme" && return 0
  grep -q '\[Project description — placeholder' "$readme" && return 0
  grep -q '\[How to use / install / contribute — placeholder\]' "$readme" && return 0
  return 1
}
