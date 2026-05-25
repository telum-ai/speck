#!/usr/bin/env bash

# Speck Claude Hook Wrapper: PostToolUse (Edit|Write)
#
# Replay stdin payload to extract edited file path and call host-neutral validators.

set -euo pipefail

payload="$(cat || true)"

# Extract file_path from Claude hook JSON input.
file_path=""
if command -v jq >/dev/null 2>&1; then
  file_path=$(echo "$payload" | jq -r '.tool_input.file_path' 2>/dev/null || true)
elif command -v python3 >/dev/null 2>&1; then
  file_path=$(python3 -c 'import json,sys; print((json.loads(sys.stdin.read() or "{}").get("tool_input", {}).get("file_path") or ""))' <<<"$payload" 2>/dev/null || true)
fi

if [[ -z "$file_path" || "$file_path" == "null" ]]; then
  exit 0
fi

# Run core Speck validation in strict mode to ensure absolute agent compliance
bash .speck/scripts/validation/validate-template.sh --strict "$file_path"

exit 0
