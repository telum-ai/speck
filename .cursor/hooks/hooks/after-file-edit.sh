#!/usr/bin/env bash
#
# Speck Hook Dispatcher: afterFileEdit
#
# Why this exists:
# - Cursor only supports a single hooks.json. This dispatcher keeps Speck's
#   methodology hooks stable while allowing projects to add their own hooks
#   without editing template-managed files.
#
# Extension points (project-managed):
# - .cursor/hooks/hooks/hooks.d/afterFileEdit/pre/*.sh
# - .cursor/hooks/hooks/hooks.d/afterFileEdit/post/*.sh
#
# Each script receives the same JSON payload on stdin as the Cursor hook.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read stdin once and replay to each hook.
payload="$(cat || true)"

run_hook() {
  local script="$1"
  [[ -f "$script" ]] || return 0
  # Never crash the editor experience.
  echo "$payload" | bash "$script" || true
}

run_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  shopt -s nullglob
  local scripts=("$dir"/*.sh)
  shopt -u nullglob
  if (( ${#scripts[@]} == 0 )); then
    return 0
  fi
  for s in "${scripts[@]}"; do
    run_hook "$s"
  done
}

# Project pre-hooks (optional)
run_dir "$HOOKS_DIR/hooks.d/afterFileEdit/pre"

# Speck hooks (stable)
run_hook "$HOOKS_DIR/log-file-edit.sh"
run_hook "$HOOKS_DIR/validate-template.sh"

# Project post-hooks (optional)
run_dir "$HOOKS_DIR/hooks.d/afterFileEdit/post"

exit 0

