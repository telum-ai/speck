#!/usr/bin/env bash
# validate-profile.sh — Entry point for PROFILE surface validation
#
# Usage: validate-profile.sh [--strict] [WORKSPACE_ROOT]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/validators/validate-readme.sh" "$@"
