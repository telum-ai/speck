#!/usr/bin/env bash

# check-artifact-template-drift.sh
# Wrapper script around check-artifact-template-drift.js

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

node "$SCRIPT_DIR/check-artifact-template-drift.js" "$@"
