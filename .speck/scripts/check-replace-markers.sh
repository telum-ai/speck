#!/usr/bin/env bash
# check-replace-markers.sh — Pre-ship lint for REPLACE_BEFORE_SHIP tokens
#
# Usage:
#   .speck/scripts/check-replace-markers.sh [path]
#
# Behavior:
#   - Scans the given path (default: specs/) recursively for the literal
#     token REPLACE_BEFORE_SHIP: anywhere in a .md file.
#   - Reports artifact + line + count.
#   - Exit code 0: clean.
#   - Exit code 1: at least one token found — artifact cannot claim ship-readiness.
#
# Speck v7.2+ pattern. Any truth artifact carrying this token is incomplete.
# /speck-recheck and /story-validate / /epic-validate / /project-validate
# call this script and refuse to advance the readiness state past IMPL-GREEN
# while any tokens remain.

set -euo pipefail

ROOT="${1:-specs/}"

if [[ ! -d "$ROOT" ]]; then
  if [[ -f "$ROOT" ]]; then
    HITS=$(grep -c "REPLACE_BEFORE_SHIP:" "$ROOT" 2>/dev/null || echo 0)
    if [[ "$HITS" -eq 0 ]]; then
      echo "✅ check-replace-markers: $ROOT — clean"
      exit 0
    else
      echo "❌ check-replace-markers: $ROOT — $HITS token(s) remaining"
      grep -nH "REPLACE_BEFORE_SHIP:" "$ROOT"
      exit 1
    fi
  fi
  echo "ERROR: path not found: $ROOT" >&2
  exit 2
fi

# Aggregate counts per file
HIT_FILES=$(grep -rln --include='*.md' "REPLACE_BEFORE_SHIP:" "$ROOT" 2>/dev/null || true)

if [[ -z "$HIT_FILES" ]]; then
  echo "✅ check-replace-markers: $ROOT — clean (no REPLACE_BEFORE_SHIP tokens)"
  exit 0
fi

TOTAL=0
echo "❌ check-replace-markers: $ROOT — REPLACE_BEFORE_SHIP tokens found"
echo ""
echo "| Artifact | Token count |"
echo "|----------|-------------|"

while IFS= read -r f; do
  count=$(grep -c "REPLACE_BEFORE_SHIP:" "$f" 2>/dev/null || echo 0)
  if [[ "$count" -gt 0 ]]; then
    echo "| $f | $count |"
    TOTAL=$((TOTAL + count))
  fi
done <<< "$HIT_FILES"

echo ""
echo "Total: $TOTAL token(s) remaining across $(echo "$HIT_FILES" | wc -l | tr -d ' ') file(s)"
echo ""
echo "Resolution: every REPLACE_BEFORE_SHIP token must be filled or removed"
echo "before the artifact can claim a readiness state above IMPL-GREEN."

exit 1
