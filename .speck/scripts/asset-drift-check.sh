#!/usr/bin/env bash
# asset-drift-check.sh — Flag duplicated SVG path geometry (asset dual-encoding)
#
# Usage:
#   .speck/scripts/asset-drift-check.sh [WORKSPACE_ROOT]
#
# Scans source files for non-trivial SVG path d="..." literals duplicated across
# 2+ files. Surfaces ASSET_DRIFT.P1 — brand geometry should have a single source.
#
# Exit codes:
#   0 — no duplicates
#   1 — duplicate geometry found
#   2 — invocation error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="${1:-}"

if [[ -z "$WORKSPACE_ROOT" ]]; then
  WORKSPACE_ROOT="$(pwd)"
  cur="$WORKSPACE_ROOT"
  while [[ "$cur" != "/" ]]; do
    if [[ -d "$cur/.speck" ]] || compgen -G "$cur/specs/projects/*/project.md" >/dev/null 2>&1; then
      WORKSPACE_ROOT="$cur"
      break
    fi
    cur="$(dirname "$cur")"
  done
fi

if [[ ! -d "$WORKSPACE_ROOT" ]]; then
  echo "ERROR: Workspace root not found: $WORKSPACE_ROOT" >&2
  exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 required for asset-drift-check" >&2
  exit 2
fi

python3 "$SCRIPT_DIR/asset-drift-check.py" "$WORKSPACE_ROOT"
