#!/usr/bin/env bash
set -euo pipefail

# Backward-compatible wrapper
bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sync-claude-runtime.sh"
