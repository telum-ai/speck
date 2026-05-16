#!/usr/bin/env bash
# banned-language-lint.sh — Enforce product-contract.md banned language across the codebase
#
# Reads banned terms from `specs/projects/<id>/product-contract.md` Section 7 (Banned Language)
# and greps user-visible surfaces for any matches.
#
# Usage:
#   .speck/scripts/banned-language-lint.sh [PROJECT_DIR] [TARGET_PATHS...]
#
# If PROJECT_DIR is omitted, walks up from cwd. If TARGET_PATHS is omitted, scans
# common user-visible paths (src/, app/, pages/, components/, public/, locales/).
#
# Exit codes:
#   0 = no violations
#   1 = violations found
#   2 = invocation error (no product-contract.md, etc.)

set -euo pipefail

PROJECT_DIR="${1:-}"

# Locate project dir
if [[ -z "$PROJECT_DIR" ]] || [[ "$PROJECT_DIR" == -* ]]; then
  PROJECT_DIR=""
  cur="$(pwd)"
  while [[ "$cur" != "/" ]]; do
    if compgen -G "$cur/specs/projects/*/product-contract.md" >/dev/null 2>&1; then
      PROJECT_DIR="$(echo "$cur"/specs/projects/*/ | head -n1)"
      PROJECT_DIR="${PROJECT_DIR%/}"
      WORKSPACE_ROOT="$cur"
      break
    fi
    cur="$(dirname "$cur")"
  done
else
  shift
  WORKSPACE_ROOT="$(cd "$PROJECT_DIR" && cd ../.. && pwd)"
fi

if [[ -z "${PROJECT_DIR:-}" ]] || [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: Could not locate project directory with product-contract.md." >&2
  exit 2
fi

PRODUCT_CONTRACT="$PROJECT_DIR/product-contract.md"

if [[ ! -f "$PRODUCT_CONTRACT" ]]; then
  echo "ERROR: product-contract.md not found at $PRODUCT_CONTRACT" >&2
  exit 2
fi

# Extract banned terms from product-contract.md Section 7
# The table format is: | [Banned Term] | [where] | [why] | [Use instead] |
# We extract the first column where it's not the header / dividers / placeholder.
TMP_TERMS=$(mktemp)
awk '
  /^## 7\. Banned Language/ { in_section=1; next }
  /^## [0-9]/ && in_section { in_section=0 }
  in_section && /^\|/ {
    # Skip header row (contains "Banned Term") and divider
    if ($0 ~ /Banned Term/) next
    if ($0 ~ /^\|[ \t-]+\|/) next
    # Extract first cell content
    line=$0
    sub(/^\| */, "", line)
    sub(/ *\|.*/, "", line)
    # Skip placeholder/template rows
    if (line ~ /^\[/) next
    if (line == "") next
    print line
  }
' "$PRODUCT_CONTRACT" > "$TMP_TERMS"

# Also extract categorical bans (### Banned Phrase Classes lines starting with "- ❌")
awk '
  /^### Banned Phrase Classes/ { in_section=1; next }
  /^### / && in_section { in_section=0 }
  in_section && /^- ❌/ {
    line=$0
    sub(/^- ❌[[:space:]]*/, "", line)
    # Extract phrases in quotes
    while (match(line, /"[^"]+"/)) {
      phrase = substr(line, RSTART+1, RLENGTH-2)
      print phrase
      line = substr(line, RSTART + RLENGTH)
    }
  }
' "$PRODUCT_CONTRACT" >> "$TMP_TERMS"

BANNED_COUNT=$(wc -l < "$TMP_TERMS" | tr -d ' ')

if [[ "$BANNED_COUNT" -eq 0 ]]; then
  echo "⚠️  No banned terms extracted from product-contract.md Section 7."
  echo "    Either the section is empty, or it uses an unrecognized format."
  rm -f "$TMP_TERMS"
  exit 0
fi

# Default target paths (common user-visible surfaces)
if [[ $# -eq 0 ]]; then
  TARGETS=()
  for p in src app pages components public locales i18n; do
    if [[ -d "$WORKSPACE_ROOT/$p" ]]; then
      TARGETS+=("$WORKSPACE_ROOT/$p")
    fi
  done
  if [[ ${#TARGETS[@]} -eq 0 ]]; then
    # Fall back to entire workspace, excluding node_modules / specs / vendor
    TARGETS=("$WORKSPACE_ROOT")
  fi
else
  TARGETS=("$@")
fi

# Check if rg is available; fall back to grep otherwise
if command -v rg >/dev/null 2>&1; then
  GREP_TOOL="rg --hidden --no-heading --line-number --color=never --glob=!{node_modules,.git,specs,vendor,dist,build,.next,out,.cache}/** --type-add=ui:*.{tsx,jsx,ts,js,vue,svelte,html,md,mdx,json,po,strings,xml,yaml,yml}"
  GREP_INVOKE="$GREP_TOOL --type=ui"
else
  GREP_TOOL="grep -rIn"
  GREP_INVOKE="$GREP_TOOL --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=specs --exclude-dir=vendor --exclude-dir=dist --exclude-dir=build --exclude-dir=.next --exclude-dir=out --exclude-dir=.cache"
fi

ANY_VIOLATIONS=0
TOTAL_HITS=0

echo "🔍 Banned-language lint — Project: $PROJECT_DIR"
echo "   Terms to check: $BANNED_COUNT"
echo "   Targets: ${TARGETS[*]}"
echo ""

while IFS= read -r term; do
  # Skip blank lines and obvious garbage
  [[ -z "$term" ]] && continue
  # Escape regex special chars for literal match (basic)
  esc_term="$(printf '%s' "$term" | sed -e 's/[.[\*^$()+?{|]/\\&/g')"
  # Run case-insensitive search
  output=$($GREP_INVOKE -i "$esc_term" "${TARGETS[@]}" 2>/dev/null || true)
  if [[ -n "$output" ]]; then
    hits=$(echo "$output" | wc -l | tr -d ' ')
    TOTAL_HITS=$((TOTAL_HITS + hits))
    ANY_VIOLATIONS=1
    echo "❌ \"$term\" — $hits hit(s)"
    echo "$output" | head -n 10 | sed 's/^/      /'
    if [[ $hits -gt 10 ]]; then
      echo "      ... ($((hits - 10)) more)"
    fi
    echo ""
  fi
done < "$TMP_TERMS"

rm -f "$TMP_TERMS"

if [[ $ANY_VIOLATIONS -eq 1 ]]; then
  echo "📊 Total banned-language hits: $TOTAL_HITS"
  echo ""
  echo "Each hit should be:"
  echo "  1. Replaced with the term in product-contract.md 'Use instead' column"
  echo "  2. OR added as a legitimate exception (rare — usually in error messages from external libs)"
  exit 1
else
  echo "✅ No banned-language violations found."
  exit 0
fi
