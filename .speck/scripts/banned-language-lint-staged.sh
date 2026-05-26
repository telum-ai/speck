#!/usr/bin/env bash
# lint-staged wrapper for banned-language-lint.sh
# Auto-detects PROJECT_DIR from cwd; forwards staged file paths as arguments.
#
# Usage in lint-staged / Husky:
#   "bash .speck/scripts/banned-language-lint-staged.sh"
#
# Equivalent to:
#   bash -c 'bash .speck/scripts/banned-language-lint.sh "" "$@"' _ "$@"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/banned-language-lint.sh" "" "$@"
