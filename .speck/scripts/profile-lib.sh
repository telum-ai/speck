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

# speck_workspace_version <workspace_root>
# The ONE read of "which Speck version is this workspace on".
#
# THE SCAR: two files answered this question from two different sources and disagreed by
# construction. detect-version.sh read `.speck/project.json` → `speck_version` FIRST and
# returned it; migrate.sh wrote that field as the literal '7.0.0'; the CLI's saveVersion()
# only ever writes `.speck/VERSION`. So every upgrade advanced VERSION and left the field
# frozen — a workspace on 9.5.0 reported 7.0.0 — while profile-lib.sh, reading the OTHER
# file, quietly returned a different answer for the same repo.
#
# `.speck/VERSION` is what the installer writes on every init and upgrade, so `.speck/VERSION`
# is authoritative. The project.json field is ADVISORY: it is used only when there is no
# VERSION file at all (a genuinely pre-VERSION legacy install), and otherwise only compared —
# loudly, on stderr, because a stale advisory field is a real defect and the operator is the
# only one who can fix it.
#
# Prints the version on stdout, or the empty string when the workspace carries no marker at
# all. The caller owns the fallback: "6" and "unknown" are different right answers.
speck_workspace_version() {
  local workspace_root="$1"
  local version_file="$workspace_root/.speck/VERSION"
  local project_json="$workspace_root/.speck/project.json"
  local authoritative="" advisory=""

  if [[ -f "$version_file" ]]; then
    authoritative="$(tr -d '[:space:]' < "$version_file")"
  fi

  if [[ -f "$project_json" ]]; then
    # The path is an ARGUMENT, never interpolated into the source. Interpolating it into a
    # Python string literal — open('$project_json') — made a workspace at `.../kjetil's ws`
    # close the literal early; python3 died on a SyntaxError and `2>/dev/null || echo ''`
    # swallowed it whole. Silent and asymmetric: with a VERSION file the disagreement warning
    # simply stopped firing, and with no VERSION file the only signal there was got lost, so an
    # 8.2.0 legacy workspace reported the v6 default and mis-routed migration and gate logic.
    # Same idiom as read_config_excludes in banned-language-lint.sh.
    advisory="$(python3 - "$project_json" 2>/dev/null <<'PY' || echo ''
import json, sys
try:
    with open(sys.argv[1]) as f:
        d = json.load(f)
    print(d.get('speck_version', '') or '')
except Exception:
    print('')
PY
)"
    advisory="${advisory//[[:space:]]/}"
  fi

  if [[ -n "$authoritative" ]]; then
    if [[ -n "$advisory" && "$advisory" != "$authoritative" ]]; then
      speck_warn_version_disagreement "$workspace_root" "$authoritative" "$advisory"
    fi
    printf '%s' "$authoritative"
    return
  fi

  # No VERSION file: pre-VERSION legacy install, where the advisory field is the only signal.
  printf '%s' "$advisory"
}

# speck_warn_version_disagreement <workspace_root> <authoritative> <advisory>
# Warn ONCE per process per workspace, on stderr only — every caller of the version helpers
# captures stdout with $(…), so a warning on stdout would corrupt the value it is warning about.
speck_warn_version_disagreement() {
  local workspace_root="$1" authoritative="$2" advisory="$3"
  local key
  key="$(printf '%s' "$workspace_root" | tr -c '[:alnum:]' '_')"
  local guard="SPECK_VERSION_WARNED_${key}"
  [[ -n "${!guard:-}" ]] && return 0
  printf -v "$guard" '%s' 1
  export "${guard}"
  {
    echo "⚠️  Speck version disagreement in $workspace_root"
    echo "      .speck/VERSION              = $authoritative   (authoritative — written by every init/upgrade)"
    echo "      project.json speck_version  = $advisory   (advisory — stale)"
    echo "    Using $authoritative. Fix: set \"speck_version\": \"$authoritative\" in .speck/project.json,"
    echo "    or delete the field entirely — .speck/VERSION is the source of truth."
  } >&2
}

profile_read_speck_version() {
  local workspace_root="$1"
  local v
  v="$(speck_workspace_version "$workspace_root")"
  if [[ -n "$v" ]]; then
    printf '%s' "$v"
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
