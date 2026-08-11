#!/usr/bin/env bash
# profile-drift-check.sh — Compatibility wrapper for the registry-backed PROFILE gate.
# Usage: profile-drift-check.sh [--claim STATE] [--surface NAME] [WORKSPACE_ROOT] [PROJECT_ID]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/profile-surface-check.py" "$@"
