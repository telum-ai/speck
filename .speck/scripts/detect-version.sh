#!/usr/bin/env bash
# Detect which Speck version a project/artifact uses.
#
# Project mode (no argument) reads `.speck/VERSION` — the file the installer writes on
# every init and upgrade. `.speck/project.json`'s `speck_version` is ADVISORY only; it is
# consulted when there is no VERSION file, and otherwise only compared (loudly, on stderr).
# That precedence is not cosmetic: this script used to read project.json FIRST, migrate.sh
# wrote that field as the literal '7.0.0', and nothing has updated it since — so an upgraded
# 9.5.0 workspace reported 7.0.0 while profile-lib.sh, reading VERSION, reported 9.5.0 for
# the same repo. One read now, in speck_workspace_version() over in profile-lib.sh.
#
# Artifact mode (with a file argument) reads, in order:
# 1. The file's frontmatter speck_version: field
# 2. The file's SHA stamp footer "speck vX.Y.Z" marker
# 3. Falls back to project mode
#
# Prints one of:
#   9.5.0   (or whatever version is detected)
#   6       (legacy v6 — no version marker found, but Speck dir exists)
#   none    (no Speck markers found)
#
# Usage:
#   detect-version.sh            # workspace version
#   detect-version.sh <file>     # check a specific artifact

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=profile-lib.sh
. "$SCRIPT_DIR/profile-lib.sh"

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

# Mode 1: no arg — the workspace version, via the single shared read
if [[ -z "$TARGET" ]]; then
  VERSION="$(speck_workspace_version "$ROOT")"
  if [[ -n "$VERSION" ]]; then
    echo "$VERSION"
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
