#!/usr/bin/env bash
# Detect which Speck version a project/artifact uses.
#
# Reads (in order):
# 1. .speck/project.json speck_version field
# 2. The file's frontmatter speck_version: field
# 3. The file's SHA stamp footer "speck vX.Y.Z" marker
#
# Prints one of:
#   7.0.0   (or whatever version is detected)
#   6       (legacy v6 — no version marker found, but Speck dir exists)
#   none    (no Speck markers found)
#
# Usage:
#   detect-version.sh            # check .speck/project.json
#   detect-version.sh <file>     # check a specific artifact

set -euo pipefail

TARGET="${1:-}"

# Workspace root
ROOT="$(pwd)"
while [[ "$ROOT" != "/" && ! -d "$ROOT/.speck" ]]; do
  ROOT="$(dirname "$ROOT")"
done

if [[ ! -d "$ROOT/.speck" ]]; then
  echo "none"
  exit 0
fi

# Mode 1: no arg — check project.json, then .speck/VERSION, then fall back
if [[ -z "$TARGET" ]]; then
  PROJECT_JSON="$ROOT/.speck/project.json"
  if [[ -f "$PROJECT_JSON" ]]; then
    VERSION=$(python3 -c "
import json
try:
    with open('$PROJECT_JSON') as f:
        d = json.load(f)
    print(d.get('speck_version', ''))
except Exception:
    print('')
" 2>/dev/null)
    if [[ -n "$VERSION" ]]; then
      echo "$VERSION"
      exit 0
    fi
  fi
  # Framework-level version (set by the CLI on upgrade)
  if [[ -f "$ROOT/.speck/VERSION" ]]; then
    cat "$ROOT/.speck/VERSION"
    exit 0
  fi
  # No markers anywhere — legacy v6 default for backward compat
  echo "6"
  exit 0
fi

# Mode 2: file-specific
if [[ ! -f "$TARGET" ]]; then
  echo "none"
  exit 0
fi

# Check frontmatter for speck_version
FM_VERSION=$(awk '
  /^---$/ { in_fm = !in_fm; next }
  in_fm && /^speck_version:/ { print $2; exit }
' "$TARGET" 2>/dev/null || true)
if [[ -n "$FM_VERSION" ]]; then
  echo "$FM_VERSION"
  exit 0
fi

# Check SHA stamp footer for "speck vX.Y.Z"
FOOTER_VERSION=$(grep -oE 'speck v[0-9]+\.[0-9]+\.[0-9]+' "$TARGET" | head -n1 | sed 's/speck v//' || true)
if [[ -n "$FOOTER_VERSION" ]]; then
  echo "$FOOTER_VERSION"
  exit 0
fi

# Fall back to project-level
exec "$0"
