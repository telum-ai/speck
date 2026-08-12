#!/usr/bin/env bash
# profile-drift-check.sh — Compatibility wrapper for the registry-backed PROFILE gate.
# Usage: profile-drift-check.sh [--claim STATE] [--surface NAME] [WORKSPACE_ROOT] [PROJECT_ID]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required for profile-drift-check.sh" >&2
  exit 1
fi

exec python3 "$SCRIPT_DIR/profile-surface-check.py" "$@"
