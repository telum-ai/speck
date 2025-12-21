#!/usr/bin/env bash
set -euo pipefail

# Speck MCP config merger.
#
# Speck provides a baseline example:      .cursor/mcp.json.example
# Projects can add a committed overlay:   .cursor/mcp.project.json.example
# This script merges both into a local:   .cursor/mcp.json
#
# - Project overlay wins on key conflicts.
# - `mcpServers` is deep-merged; other top-level keys are shallow-merged.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

BASE_PATH="$REPO_ROOT/.cursor/mcp.json.example"
PROJECT_PATH="$REPO_ROOT/.cursor/mcp.project.json.example"
OUT_PATH="$REPO_ROOT/.cursor/mcp.json"
JSON_MODE=false
DRY_RUN=false

usage() {
  cat <<'EOF'
Usage:
  bash .speck/scripts/bash/merge-mcp-config.sh [--base <path>] [--project <path>] [--out <path>] [--dry-run] [--json]

Defaults:
  --base    .cursor/mcp.json.example
  --project .cursor/mcp.project.json.example (if present)
  --out     .cursor/mcp.json

Notes:
  - `.cursor/mcp.json` is typically git-ignored because it can contain secrets.
  - Commit project-wide additions in `.cursor/mcp.project.json.example`.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE_PATH="${2:-}"; shift 2 ;;
    --project) PROJECT_PATH="${2:-}"; shift 2 ;;
    --out) OUT_PATH="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --json) JSON_MODE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required to merge MCP configs." >&2
  exit 1
fi

python3 - "$BASE_PATH" "$PROJECT_PATH" "$OUT_PATH" "$DRY_RUN" "$JSON_MODE" <<'PY'
import json, os, sys
from typing import Any, Dict

base_path, project_path, out_path, dry_run, json_mode = sys.argv[1:6]
dry_run = dry_run.lower() == "true"
json_mode = json_mode.lower() == "true"

def load_json(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

if not os.path.isfile(base_path):
    raise SystemExit(f"ERROR: Base MCP config not found: {base_path}")

base = load_json(base_path)
project = None
if os.path.isfile(project_path):
    project = load_json(project_path)

result: Dict[str, Any] = {}

# Shallow merge: base then project
result.update(base if isinstance(base, dict) else {})
if isinstance(project, dict):
    for k, v in project.items():
        # Deep merge mcpServers only
        if k == "mcpServers" and isinstance(v, dict) and isinstance(result.get("mcpServers"), dict):
            merged = dict(result["mcpServers"])
            merged.update(v)  # project overrides per-server key
            result["mcpServers"] = merged
        else:
            result[k] = v

# Ensure mcpServers exists as a dict
if "mcpServers" not in result or not isinstance(result["mcpServers"], dict):
    result["mcpServers"] = {}

payload = json.dumps(result, indent=2, sort_keys=True) + "\n"

if not dry_run:
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(payload)

meta = {
    "base": base_path,
    "project": project_path if os.path.isfile(project_path) else "",
    "out": out_path,
    "dry_run": dry_run,
    "merged_servers": sorted(list(result["mcpServers"].keys())),
}

if json_mode:
    print(json.dumps(meta, indent=2))
else:
    print("✅ MCP config merged")
    print(f"- Base:    {meta['base']}")
    if meta["project"]:
        print(f"- Project: {meta['project']}")
    else:
        print("- Project: (none)")
    print(f"- Output:  {meta['out']}{' (dry-run)' if dry_run else ''}")
    print(f"- Servers: {', '.join(meta['merged_servers']) if meta['merged_servers'] else '(none)'}")
PY

