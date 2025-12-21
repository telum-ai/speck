#!/bin/bash
# Learning Capture: Log all file edits for retrospective analysis
# Cursor Hook: afterFileEdit
# Input: JSON with file_path and edits array

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Parse file path (prefer jq, fallback to python). If parsing fails, skip gracefully.
FILE_PATH=""
if command -v jq >/dev/null 2>&1; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.file_path' 2>/dev/null || true)
elif command -v python3 >/dev/null 2>&1; then
    FILE_PATH=$(python3 -c 'import json,sys; print((json.loads(sys.stdin.read() or "{}").get("file_path") or ""))' <<<"$INPUT" 2>/dev/null || true)
fi

if [[ -z "$FILE_PATH" || "$FILE_PATH" == "null" ]]; then
    exit 0
fi

# Skip if file is in exempt directories
if [[ "$FILE_PATH" == *"/.cursor/"* ]] || [[ "$FILE_PATH" == *"/.speck/"* ]]; then
    exit 0
fi

# If jq isn't available, fall back to python to write the log (simpler than re-implementing JSON parsing in bash).
if ! command -v jq >/dev/null 2>&1; then
    if ! command -v python3 >/dev/null 2>&1; then
        exit 0
    fi

    python3 - <<'PY' <<<"$INPUT"
import json
import os
import sys
from datetime import datetime, timezone

try:
    data = json.loads(sys.stdin.read() or "{}")
except Exception:
    sys.exit(0)

file_path = data.get("file_path") or ""
if not file_path:
    sys.exit(0)

if "/.cursor/" in file_path or "/.speck/" in file_path:
    sys.exit(0)

file_dir = os.path.dirname(file_path)
filename = os.path.basename(file_path)
log_file = os.path.join(file_dir, ".learning.log")

ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
edits = data.get("edits") or []

def trunc(value: object, n: int = 200) -> str:
    if value is None:
        return ""
    s = str(value)
    return s[:n]

os.makedirs(file_dir, exist_ok=True)
with open(log_file, "a", encoding="utf-8") as f:
    f.write(f"=== EDIT: {ts} ===\n")
    f.write(f"File: {filename}\n")
    f.write(f"Full Path: {file_path}\n")
    f.write(f"Edit Count: {len(edits)}\n\n")

    for i, edit in enumerate(edits, start=1):
        if isinstance(edit, dict):
            old = edit.get("old_string")
            new = edit.get("new_string")
        else:
            old = None
            new = None

        old_str = trunc(old if old is not None else "(new file)")
        new_str = trunc(new)

        f.write(f"Edit {i}:\n")
        f.write(f"  Changed from: {old_str}...\n")
        f.write(f"  Changed to: {new_str}...\n\n")

    f.write("---\n\n")

sys.exit(0)
PY

    exit 0
fi

# Get directory of the edited file
FILE_DIR=$(dirname "$FILE_PATH")
FILENAME=$(basename "$FILE_PATH")

# Create .log file in same directory
LOG_FILE="$FILE_DIR/.learning.log"

# Get timestamp
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Parse edits array length
EDIT_COUNT=$(echo "$INPUT" | jq '.edits | length')

# Append to log file
{
    echo "=== EDIT: $TIMESTAMP ==="
    echo "File: $FILENAME"
    echo "Full Path: $FILE_PATH"
    echo "Edit Count: $EDIT_COUNT"
    echo ""
    
    # Log each edit
    for i in $(seq 0 $((EDIT_COUNT - 1))); do
        OLD=$(echo "$INPUT" | jq -r ".edits[$i].old_string // \"(new file)\"" | head -c 200)
        NEW=$(echo "$INPUT" | jq -r ".edits[$i].new_string" | head -c 200)
        
        echo "Edit $((i + 1)):"
        echo "  Changed from: ${OLD}..."
        echo "  Changed to: ${NEW}..."
        echo ""
    done
    
    echo "---"
    echo ""
} >> "$LOG_FILE"

exit 0

