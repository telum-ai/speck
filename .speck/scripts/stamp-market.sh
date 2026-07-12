#!/usr/bin/env bash
# stamp-market.sh — the SOLE writer of the inline market-verified stamp on §3 (issue #80)
#
# A market claim reads "fresh" only when a real, sourced re-validation stands behind
# it (P2 — no claim without a mechanism). This writer enforces that: it refuses to
# emit a VERIFIED stamp unless the cited scan report exists and the source floor is
# met. speck-frontier-scan --product calls it after authoring the scan report.
#
# The stamp lives INLINE, on the line immediately after "**Core differentiator**:"
# in product-contract.md — deliberately NOT the EOF footer, so it never collides
# with stamp-truth.sh's SHA-stamp machinery.
#
# Usage:
#   stamp-market.sh <product-contract.md> --baseline
#       Writes the at-lock provisional:  *[market-verified: unverified | staged <today>]*
#   stamp-market.sh <product-contract.md> --verdict <holds|eroded|false> --sources <N> --scan <report-filename>
#       Writes the verified stamp (requires the report to exist; holds requires sources >= floor).
#
# Exit: 0 = stamped, 1 = refused / invocation error

set -euo pipefail

CONTRACT="${1:-}"
if [[ -z "$CONTRACT" || ! -f "$CONTRACT" ]]; then
  echo "ERROR: pass a product-contract.md path as \$1" >&2
  exit 1
fi
shift

MODE="verified"
VERDICT="" ; SOURCES="" ; SCAN=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --baseline) MODE="baseline"; shift ;;
    --verdict)  VERDICT="${2:-}"; shift 2 ;;
    --sources)  SOURCES="${2:-}"; shift 2 ;;
    --scan)     SCAN="${2:-}"; shift 2 ;;
    *) echo "ERROR: unknown arg '$1'" >&2; exit 1 ;;
  esac
done

TODAY=$(date +%Y-%m-%d)
PROJECT_DIR="$(cd "$(dirname "$CONTRACT")" && pwd)"

if [[ "$MODE" == "baseline" ]]; then
  STAMP="*[market-verified: unverified | staged $TODAY]*"
else
  # Verified stamp — enforce the mechanism.
  case "$VERDICT" in
    holds|eroded|false) ;;
    *) echo "ERROR: --verdict must be one of holds|eroded|false" >&2; exit 1 ;;
  esac
  if [[ -z "$SCAN" ]]; then
    echo "ERROR: --scan <report-filename> required for a verified stamp (no claim without a mechanism)" >&2
    exit 1
  fi
  if [[ ! -f "$PROJECT_DIR/$SCAN" ]]; then
    echo "ERROR: refusing to stamp — cited scan report '$SCAN' does not exist in $PROJECT_DIR" >&2
    exit 1
  fi
  [[ "$SOURCES" =~ ^[0-9]+$ ]] || { echo "ERROR: --sources <N> (integer) required" >&2; exit 1; }

  # Source floor (default 3) applies to a 'holds' verdict; an honest eroded/false
  # verdict is allowed to stand regardless (it forces a fix, not a green light).
  FLOOR=3
  PJ=""
  cur="$PROJECT_DIR"
  while [[ "$cur" != "/" ]]; do
    [[ -f "$cur/.speck/project.json" ]] && { PJ="$cur/.speck/project.json"; break; }
    cur="$(dirname "$cur")"
  done
  if [[ -n "$PJ" ]]; then
    f=$(grep -oE '"market_sources_floor"[[:space:]]*:[[:space:]]*[0-9]+' "$PJ" 2>/dev/null | grep -oE '[0-9]+' | tail -1 || true)
    [[ -n "$f" ]] && FLOOR="$f"
  fi
  if [[ "$VERDICT" == "holds" && "$SOURCES" -lt "$FLOOR" ]]; then
    echo "ERROR: refusing to stamp verdict:holds with $SOURCES source(s) (< floor $FLOOR)" >&2
    exit 1
  fi
  STAMP="*[market-verified $TODAY | verdict: $VERDICT | sources: $SOURCES | scan: $SCAN]*"
fi

# Replace any existing market stamp; else insert right after the differentiator line.
TMP=$(mktemp)
awk -v stamp="$STAMP" '
  /^\*\[market-verified/ { next }                       # drop old stamp
  { print }
  /^\*\*Core differentiator\*\*:/ && !done { print stamp; done=1 }
  END { if (!done) exit 7 }
' "$CONTRACT" > "$TMP" || {
  rc=$?
  rm -f "$TMP"
  if [[ "$rc" -eq 7 ]]; then
    echo "ERROR: could not find a '**Core differentiator**:' line in $CONTRACT to anchor the stamp" >&2
  fi
  exit 1
}
mv "$TMP" "$CONTRACT"
echo "✅ Market-stamped: $CONTRACT"
echo "   $STAMP"
