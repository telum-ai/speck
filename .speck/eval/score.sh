#!/usr/bin/env bash
# A1-lite scorer — seeded defect fixtures
# check.sh exit 0 => defect DETECTED (CATCH); exit 1 => not detected (MISS)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIX="$ROOT/.speck/eval/fixtures"
OUT="$ROOT/.speck/eval/reports"
mkdir -p "$OUT"
REPORT="$OUT/latest.md"
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

caught=0
missed=0
total=0

{
  echo "# A1-lite scorecard"
  echo
  echo "Generated: $STAMP"
  echo
  echo "| Fixture | Class | Expect | Result |"
  echo "|---------|-------|--------|--------|"
} > "$REPORT"

for d in "$FIX"/*/manifest.json; do
  id=$(basename "$(dirname "$d")")
  dir="$FIX/$id"
  expect=$(python3 -c "import json;print(json.load(open('$dir/manifest.json'))['expect'])")
  class=$(python3 -c "import json;print(json.load(open('$dir/manifest.json'))['class'])")
  result="MISS"
  if bash "$dir/check.sh" >/dev/null 2>&1; then
    result="CATCH"
  fi
  total=$((total+1))
  ok=0
  if [[ "$expect" == "catch" && "$result" == "CATCH" ]]; then ok=1; fi
  if [[ "$expect" == "clean-pass" && "$result" == "MISS" ]]; then ok=1; fi
  if [[ "$ok" -eq 1 ]]; then
    caught=$((caught+1))
  else
    missed=$((missed+1))
  fi
  echo "| $id | $class | $expect | $result |" >> "$REPORT"
done

rate=$(python3 -c "print(round(100.0*$caught/max($total,1),1))")
{
  echo
  echo "## Summary"
  echo
  echo "- fixtures: $total"
  echo "- correct: $caught"
  echo "- incorrect: $missed"
  echo "- rate_pct: $rate"
  echo
  echo "Measured-win rule: new always-on/gate needs defect-catch↑ and false-green not↑, or equal retirement, or spine ADR (\`docs/decisions/\`)."
} >> "$REPORT"

cat "$REPORT"
cp "$REPORT" "$OUT/baseline.md"
