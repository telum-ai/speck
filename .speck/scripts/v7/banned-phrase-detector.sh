#!/usr/bin/env bash
# banned-phrase-detector.sh — Scan agent self-summaries / validation reports / commit messages
# for banned phrases that hide gaps in evidence.
#
# Different from banned-language-lint.sh:
#   - banned-language-lint.sh checks USER-FACING product copy against product-contract.md
#   - banned-phrase-detector.sh checks AGENT-AUTHORED docs against a fixed list of
#     methodology-hostile phrases that indicate over-optimism or skipped verification
#
# Usage:
#   .speck/scripts/banned-phrase-detector.sh <file-or-text>
#   echo "..." | .speck/scripts/banned-phrase-detector.sh -
#
# Exit codes:
#   0 = no banned phrases detected
#   1 = banned phrases found (re-audit required)
#   2 = invocation error

set -euo pipefail

# Fixed list of methodology-hostile phrases.
# These signal that the agent skipped enumeration / verification.
BANNED_PHRASES=(
  "ready for launch"
  "outside autonomous reach"
  "premium polish complete"
  "should work in production"
  "tests pass therefore done"
  "tests pass therefore"
  "the AI agent confirmed"
  "no regressions"  # without clean-state proof
  "ready to deploy"
  "ready to ship"
  "this is shippable"
  "all clear"
  "looking good"
  "everything works"
  "fully tested"  # without test count + evidence
  "comprehensive testing"  # without specifics
  "production-ready"
  "battle-tested"
  "rock-solid"
  "rest assured"
  "trust me"
  "out of scope for AI"
  "beyond what AI can do"
  "would require human"
  "AI can't do this"
)

INPUT=""
if [[ $# -eq 0 ]]; then
  echo "Usage: banned-phrase-detector.sh <file-or-text> | -" >&2
  exit 2
elif [[ "$1" == "-" ]]; then
  INPUT="$(cat)"
elif [[ -f "$1" ]]; then
  INPUT="$(cat "$1")"
  SOURCE_FILE="$1"
else
  INPUT="$1"
fi

FOUND=0
HITS=()

for phrase in "${BANNED_PHRASES[@]}"; do
  # Case-insensitive substring match
  if echo "$INPUT" | grep -iq -- "$phrase"; then
    HITS+=("$phrase")
    FOUND=1
  fi
done

if [[ $FOUND -eq 1 ]]; then
  echo "❌ Banned phrases detected:"
  for h in "${HITS[@]}"; do
    echo "   • \"$h\""
  done
  echo ""
  echo "Why this matters:"
  echo "  These phrases historically hide skipped verification. Speck v7 requires that"
  echo "  validation reports and self-summaries enumerate WHAT was verified, not assert"
  echo "  confidence."
  echo ""
  echo "Required action:"
  echo "  For each banned phrase, REPLACE with one of:"
  echo "    - A specific evidence link (path to artifact)"
  echo "    - An enumeration of what WAS proven (with evidence) AND what was NOT"
  echo "    - A specific readiness state claim with gate criteria evidence"
  echo ""
  echo "Or: run /audit to enumerate gaps that the banned phrase was glossing over."
  exit 1
else
  echo "✅ No banned phrases detected."
  exit 0
fi
