#!/usr/bin/env bash
# stamp-truth.sh — Apply or refresh the v7 SHA stamp footer on a truth artifact
#
# Usage:
#   .speck/scripts/stamp-truth.sh <path-to-truth-artifact>
#
# Behavior:
#   - Appends or updates the footer:
#       ---
#       *[as of SHA `<short-hash>` | verified <YYYY-MM-DD> | speck v7.0.0]*
#   - The stamp is idempotent: if an existing stamp is detected at the bottom,
#     it is replaced rather than appended.
#   - Uses git's current HEAD short SHA as the version anchor.
#   - Sets verified date to today.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: stamp-truth.sh <path-to-truth-artifact>" >&2
  exit 1
fi

TARGET="$1"

if [[ ! -f "$TARGET" ]]; then
  echo "ERROR: file not found: $TARGET" >&2
  exit 1
fi

CURRENT_SHA=$(git -C "$(dirname "$TARGET")" rev-parse --short HEAD 2>/dev/null || echo "unstamped")
TODAY=$(date +%Y-%m-%d)

# Resolve Speck version dynamically from the framework so stamps always
# reflect the version that produced them. Search up from the target's
# directory for the nearest .speck/VERSION file.
SPECK_VERSION="unknown"
SEARCH="$(cd "$(dirname "$TARGET")" 2>/dev/null && pwd)"
while [[ -n "$SEARCH" && "$SEARCH" != "/" ]]; do
  if [[ -f "$SEARCH/.speck/VERSION" ]]; then
    SPECK_VERSION="$(cat "$SEARCH/.speck/VERSION" | tr -d '[:space:]')"
    break
  fi
  SEARCH="$(dirname "$SEARCH")"
done

STAMP="*[as of SHA \`$CURRENT_SHA\` | verified $TODAY | speck v$SPECK_VERSION]*"

# Strip any existing stamp at the end (last 1-3 lines if matching)
TMP=$(mktemp)
# Remove trailing blank lines, then check last non-blank line
awk 'BEGIN{p=0} {a[NR]=$0} END{
  # Find last non-blank line
  last=NR
  while(last>0 && a[last] ~ /^[[:space:]]*$/) last--
  # If last non-blank line is a stamp, also strip the preceding "---" if present
  if (a[last] ~ /^\*\[as of SHA `[^`]+` \| verified [0-9-]+ \| speck v[0-9.]+\]\*$/) {
    end=last-1
    # Skip trailing separator
    while(end>0 && a[end] ~ /^[[:space:]]*$/) end--
    if (end>0 && a[end] == "---") end--
    while(end>0 && a[end] ~ /^[[:space:]]*$/) end--
  } else {
    end=last
  }
  for(i=1;i<=end;i++) print a[i]
}' "$TARGET" > "$TMP"

# Append the fresh stamp
{
  cat "$TMP"
  echo ""
  echo "---"
  echo ""
  echo "$STAMP"
} > "$TARGET"

rm -f "$TMP"

echo "✅ Stamped: $TARGET"
echo "   $STAMP"
