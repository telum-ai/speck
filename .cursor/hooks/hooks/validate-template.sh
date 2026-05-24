#!/usr/bin/env bash

# Speck Cursor Hook Wrapper: afterFileEdit
# Extracts file_path from Cursor payload and forwards to the host-neutral validators.
#
# NOTE: Hooks should never crash the editor experience. If dependencies (jq/python)
# are missing or input is malformed, we skip validation gracefully.

set -euo pipefail

# Read input from stdin (file_path and edits)
input=$(cat || true)

# Extract file_path from Cursor hook JSON input.
file_path=""
if command -v jq >/dev/null 2>&1; then
  file_path=$(echo "$input" | jq -r '.file_path' 2>/dev/null || true)
elif command -v python3 >/dev/null 2>&1; then
  file_path=$(python3 -c 'import json,sys; print((json.loads(sys.stdin.read() or "{}").get("file_path") or ""))' <<<"$input" 2>/dev/null || true)
fi

if [[ -z "$file_path" || "$file_path" == "null" ]]; then
  exit 0
fi

# Run core Speck validation
bash .speck/scripts/validation/validate-template.sh "$file_path"

exit 0
