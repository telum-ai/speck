#!/usr/bin/env bash
# validate-two-carrier.test.sh — smoke tests for the #103 two-carrier positional-table-read check.
#
# RED-FIRST DISCIPLINE (#103's own standard): Test 1's fixture is GENERATED AT TEST TIME by
# `git show 0e7ae68^:.speck/scripts/validation/validators/validate-gate-liveness.sh` — the real,
# shipped-then-fixed bug this check exists to catch (Canary/Waiver silently re-mapped by a column
# insert), as it stood immediately before commit 0e7ae68 ("feat(v10): ... header-keyed §6a ...").
# Provenance is MECHANICAL, not asserted: an earlier version of this file pasted a hand-trimmed
# excerpt while describing it as the historical file, which is exactly the kind of unearned
# provenance claim this repo's audit history makes load-bearing. If the commit is unreachable
# (shallow clone, tarball install), Test 1 SKIPS loudly — it is never silently counted as passed.
# If Test 1 ever goes green, the check has regressed to vacuous against the case it was built for.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VALIDATOR="$ROOT/.speck/scripts/validation/validators/validate-two-carrier.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0
skips=0
expect_violation() {
  local label="$1" target="$2"
  local out rc=0
  out="$(bash "$VALIDATOR" --strict "$target" 2>&1)" || rc=$?
  if [[ $rc -ne 1 ]]; then
    echo "ERROR: $label — expected exit 1 (violation under --strict), got $rc"
    echo "$out"
    fails=$((fails + 1))
    return
  fi
  if ! grep -q "POSITIONAL_TABLE_READ.P1" <<<"$out"; then
    echo "ERROR: $label — exit was 1 but no POSITIONAL_TABLE_READ.P1 finding printed"
    echo "$out"
    fails=$((fails + 1))
    return
  fi
  echo "  ✓ $label"
}

expect_clean() {
  local label="$1" target="$2"
  local out rc=0
  out="$(bash "$VALIDATOR" --strict "$target" 2>&1)" || rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "ERROR: $label — expected exit 0 (clean), got $rc"
    echo "$out"
    fails=$((fails + 1))
    return
  fi
  if grep -q "POSITIONAL_TABLE_READ.P1" <<<"$out"; then
    echo "ERROR: $label — exit was 0 but a POSITIONAL_TABLE_READ.P1 finding was printed anyway"
    echo "$out"
    fails=$((fails + 1))
    return
  fi
  echo "  ✓ $label"
}


# Provenance is mechanical: the fixture is fetched from git, byte-for-byte, not transcribed here.
HIST_COMMIT="0e7ae68^"
HIST_PATH=".speck/scripts/validation/validators/validate-gate-liveness.sh"
echo "Test 1 (RED): the real pre-fix validate-gate-liveness.sh ($HIST_COMMIT) is a violation"
HIST_FIXTURE="$TMP/pre-fix-validate-gate-liveness.sh"
hist_ok=false
if git -C "$ROOT" cat-file -e "$HIST_COMMIT:$HIST_PATH" 2>/dev/null; then
  if git -C "$ROOT" show "$HIST_COMMIT:$HIST_PATH" > "$HIST_FIXTURE" 2>/dev/null; then
    hist_ok=true
  fi
fi

if [[ "$hist_ok" == true ]]; then
  hist_lines="$(wc -l < "$HIST_FIXTURE" | tr -d ' ')"
  hist_sha="$(git -C "$ROOT" rev-parse --short "$HIST_COMMIT" 2>/dev/null || echo unknown)"
  echo "  fixture: git show $HIST_COMMIT:$HIST_PATH  →  $hist_lines lines, blob from commit $hist_sha"
  expect_violation "pre-fix validate-gate-liveness.sh (real regression, $HIST_COMMIT, unedited)" "$HIST_FIXTURE"

  # NEGATIVE CONTROL for the "a single comment defeats the gate" defect. Evidence C used to be a
  # file-wide keyword co-occurrence over the whole file, prose included, so appending ONE line of
  # commentary to the real buggy file flipped it to clean at exit 0. The file most likely to carry
  # such a comment is one whose author KNOWS it reads positionally — the exact population this gate
  # exists to catch. Both of the auditor's proven exoneration lines are re-run here; both must
  # still convict.
  cp "$HIST_FIXTURE" "$TMP/hist-plus-terse-comment.sh"
  printf '%s\n' '# getcolumn' >> "$TMP/hist-plus-terse-comment.sh"
  expect_violation "real buggy file + '# getcolumn' (terse keyword comment) still convicted" \
    "$TMP/hist-plus-terse-comment.sh"

  cp "$HIST_FIXTURE" "$TMP/hist-plus-prose-comment.sh"
  printf '%s\n' '# NOTE: a future version should resolve the header column by name.' \
    >> "$TMP/hist-plus-prose-comment.sh"
  expect_violation "real buggy file + a header-mentioning prose comment still convicted" \
    "$TMP/hist-plus-prose-comment.sh"

  # And the inverse, so the comment-stripping is not just "ignore everything": adding REAL
  # header-name resolution CODE to the same file must clear it. This is what proves the check
  # keys on the resolution, not on the absence of the word.
  cp "$HIST_FIXTURE" "$TMP/hist-plus-real-resolver.sh"
  cat >> "$TMP/hist-plus-real-resolver.sh" <<'RESOLVER'
resolve_columns_from_header() {
  local header="$1"
  COL_ID=0
}
RESOLVER
  expect_clean "real buggy file + an actual resolve_columns_from_header() definition is cleared" \
    "$TMP/hist-plus-real-resolver.sh"
else
  echo "  ⚠ SKIP: $HIST_COMMIT:$HIST_PATH is unreachable (shallow clone / non-git checkout)."
  echo "    Test 1 and its comment negative-controls did NOT run — they are skipped, not passed."
  skips=$((skips + 4))
fi


echo ""
echo "Test 2 (GREEN, regression/false-positive guard): the REAL shipped, header-keyed readers stay clean"
expect_clean "validate-gate-liveness.sh (shipped, header-keyed)" "$ROOT/.speck/scripts/validation/validators/validate-gate-liveness.sh"
# NOTE ON WHAT THIS SECOND ASSERTION DOES AND DOES NOT PROVE. gate-liveness-probe.sh does carry
# an unrelated same-file positional `ext|rel|fp` pipe format ~195 lines from its §6a extraction.
# But it is NOT a negative control for the WINDOW: it defines and calls
# resolve_columns_from_header, so Evidence C exonerates it at ANY window size (verified by
# rescanning it with WINDOW raised to 100000 — the verdict does not move). It is a genuine
# regression guard for "a correct header-keyed reader stays clean"; it earns nothing about the
# window's upper bound, and this suite does not claim it does.
expect_clean "gate-liveness-probe.sh (shipped, header-keyed — a correct-reader guard, NOT a window calibration)" "$ROOT/.speck/scripts/validation/validators/gate-liveness-probe.sh"


echo ""
echo "Test 3: minimal synthetic GOOD fixture (header-keyed, small) is clean"
cat > "$TMP/good-minimal.sh" <<'GOOD'
#!/usr/bin/env bash
set -euo pipefail
block="$(awk '
  /^### 6a\./ { ins=1; next }
  ins && /^#{2,3} / { ins=0 }
  ins && /^\|/ { print }
' "$1" 2>/dev/null || true)"

split_row() {
  local line="$1" i cell
  local -a raw=()
  IFS='|' read -r -a raw <<< "$line" || true
  ROW_CELLS=()
  for (( i=1; i<${#raw[@]}; i++ )); do ROW_CELLS+=("${raw[$i]}"); done
}

resolve_columns_from_header() {
  split_row "$1"
  local i lc
  for (( i=0; i<${#ROW_CELLS[@]}; i++ )); do
    lc="$(printf '%s' "${ROW_CELLS[$i]}" | tr '[:upper:]' '[:lower:]')"
    case "$lc" in
      "gate id"*) COL_ID=$i ;;
      command*)   COL_CMD=$i ;;
    esac
  done
}

while IFS= read -r row; do
  split_row "$row"
  gid="${ROW_CELLS[$COL_ID]}"
done <<< "$block"
GOOD
expect_clean "synthetic header-keyed fixture" "$TMP/good-minimal.sh"


echo ""
echo "Test 4: minimal synthetic BAD fixture (positional, no header resolution) is a violation"
cat > "$TMP/bad-minimal.sh" <<'BADHEAD'
#!/usr/bin/env bash
set -euo pipefail
block="$(awk '
  /^### 6a\./ { ins=1; next }
  ins && /^\|/ { print }
' "$1" 2>/dev/null || true)"
BADHEAD
# pad with ~70 lines of unrelated content to prove the window catches a realistic gap, not
# just an adjacent-line case
for i in $(seq 1 70); do printf '# padding line %s -- unrelated commentary, not code\n' "$i"; done >> "$TMP/bad-minimal.sh"
cat >> "$TMP/bad-minimal.sh" <<'BADTAIL'
while IFS= read -r row; do
  gid=$(printf '%s' "$row" | awk -F'|' '{print $2}')
  cmd=$(printf '%s' "$row" | awk -F'|' '{print $3}')
done <<< "$block"
BADTAIL
expect_violation "synthetic positional fixture, 70-line gap (inside WINDOW)" "$TMP/bad-minimal.sh"


echo ""
echo "Test 5: a positional pull FAR outside the window (>150 lines from the table-row filter) is NOT flagged"
cat > "$TMP/far-apart.sh" <<'FARHEAD'
#!/usr/bin/env bash
set -euo pipefail
block="$(awk '
  ins && /^\|/ { print }
' "$1" 2>/dev/null || true)"
FARHEAD
for i in $(seq 1 170); do printf '# padding line %s -- an unrelated, later section of the same file\n' "$i"; done >> "$TMP/far-apart.sh"
cat >> "$TMP/far-apart.sh" <<'FARTAIL'
unrelated_internal_line="a|b|c"
ext=$(printf '%s' "$unrelated_internal_line" | awk -F'|' '{print $1}')
FARTAIL
expect_clean "positional pull 170+ lines from the table-row filter (outside WINDOW, by design — disclosed false-negative)" "$TMP/far-apart.sh"


echo ""
echo "Test 6: a file with no markdown-table evidence at all is clean, and not counted in PREDICATES"
cat > "$TMP/no-table.sh" <<'NOTABLE'
#!/usr/bin/env bash
set -euo pipefail
name=$(echo "hello world" | cut -d' ' -f2)
echo "$name"
NOTABLE
out="$(bash "$VALIDATOR" --strict "$TMP/no-table.sh" 2>&1)"
if grep -q "^SPECK_GATE_PREDICATES=0$" <<<"$out" && ! grep -q "POSITIONAL_TABLE_READ" <<<"$out"; then
  echo "  ✓ no-table file: PREDICATES=0, no finding"
else
  echo "ERROR: expected PREDICATES=0 and no finding for a file with no table evidence"
  echo "$out"
  fails=$((fails + 1))
fi


echo ""
echo "Test 7: without --strict, a violation is reported but exit stays 0"
rc=0
out="$(bash "$VALIDATOR" "$TMP/bad-minimal.sh" 2>&1)" || rc=$?
if [[ $rc -eq 0 ]] && grep -q "POSITIONAL_TABLE_READ.P1" <<<"$out"; then
  echo "  ✓ non-strict: violation printed, exit 0"
else
  echo "ERROR: expected exit 0 with a printed finding in non-strict mode, got rc=$rc"
  echo "$out"
  fails=$((fails + 1))
fi


echo ""
echo "Test 8: directory scan aggregates SUBJECT/PREDICATES across files and finds the one violation"
mkdir -p "$TMP/dirscan"
cp "$TMP/good-minimal.sh" "$TMP/dirscan/reader-good.sh"
cp "$TMP/bad-minimal.sh" "$TMP/dirscan/reader-bad.sh"
cp "$TMP/no-table.sh" "$TMP/dirscan/unrelated.sh"
rc=0
out="$(bash "$VALIDATOR" --strict "$TMP/dirscan" 2>&1)" || rc=$?
if [[ $rc -ne 1 ]]; then
  echo "ERROR: directory scan — expected exit 1, got $rc"; echo "$out"; fails=$((fails + 1))
elif ! grep -q "^SPECK_GATE_SUBJECT=3$" <<<"$out"; then
  echo "ERROR: directory scan — expected SPECK_GATE_SUBJECT=3 (3 .sh files)"; echo "$out"; fails=$((fails + 1))
elif ! grep -q "^SPECK_GATE_PREDICATES=2$" <<<"$out"; then
  echo "ERROR: directory scan — expected SPECK_GATE_PREDICATES=2 (2 table-reading files)"; echo "$out"; fails=$((fails + 1))
elif ! grep -q "Found 1 positional-table-read violation" <<<"$out"; then
  echo "ERROR: directory scan — expected exactly 1 violation"; echo "$out"; fails=$((fails + 1))
else
  echo "  ✓ directory scan: SUBJECT=3, PREDICATES=2, 1 violation"
fi


echo ""
echo "Test 9: invocation error on a missing target exits 2"
rc=0
bash "$VALIDATOR" --strict "$TMP/does-not-exist.sh" >/dev/null 2>&1 || rc=$?
if [[ $rc -eq 2 ]]; then
  echo "  ✓ missing target: exit 2"
else
  echo "ERROR: expected exit 2 for a missing target, got $rc"
  fails=$((fails + 1))
fi


echo ""
echo "Test 10: the A↔B window is BIDIRECTIONAL — the same reader is convicted in either source order"
# Two functionally identical readers of the same table, differing ONLY in where the `/^\|/` row
# extractor sits relative to the positional pull. A forward-only window (Evidence B armed only
# AFTER an Evidence A hit) cleared the second one — and process substitution is the more idiomatic
# bash of the two, so the forward-only version exempted the commoner shape.
cat > "$TMP/order-pipe-first.sh" <<'ORDA'
#!/usr/bin/env bash
set -euo pipefail
rows="$(awk '/^\|/{print}' "$1")"
while IFS= read -r row; do
  gid=$(printf '%s' "$row" | awk -F'|' '{print $2}')
  cmd=$(printf '%s' "$row" | awk -F'|' '{print $3}')
  printf '%s %s\n' "$gid" "$cmd"
done <<< "$rows"
ORDA
cat > "$TMP/order-procsub-last.sh" <<'ORDB'
#!/usr/bin/env bash
set -euo pipefail
while IFS= read -r row; do
  gid=$(printf '%s' "$row" | awk -F'|' '{print $2}')
  cmd=$(printf '%s' "$row" | awk -F'|' '{print $3}')
  printf '%s %s\n' "$gid" "$cmd"
done < <(awk '/^\|/{print}' "$1")
ORDB
expect_violation "extractor ABOVE the positional pull (pipe-first order)" "$TMP/order-pipe-first.sh"
expect_violation "extractor BELOW the positional pull (process-substitution order)" "$TMP/order-procsub-last.sh"


echo ""
echo "Test 11: the shape of a real in-repo instance is convicted (retired live-file fixture)"
# RETIRED AS THE FILE'S OWN NOTE INSTRUCTED. This originally asserted against the LIVE
# validate-coverage-matrix.sh, which pulled $10/$11 out of "Cell status grid" rows by hard-coded
# position while its `/^\|/` extraction sat BELOW them — the instance that took this gate's field
# value from zero to non-zero. That file is now header-resolved, so the live assertion went red.
#
# A test asserting a LIVE defect as its expected value is #99's counter-test class: the suite ends
# up holding the bug in place, and the honest fix looks like the breaking change. What is worth
# pinning is the DETECTION CAPABILITY, not the continued existence of the bug — so the shape is
# frozen here, below-extraction ordering and all, and the real file is free to be correct.
cat > "$TMP/coverage-matrix-shape.sh" <<'CMS'
#!/usr/bin/env bash
set -euo pipefail
content="$(cat "$1")"
gap_count=0; total=0
while IFS= read -r row; do
  # Status = 9th data column (field 10), Evidence = 10th (field 11).
  status=$(printf '%s' "$row" | awk -F'|' '{s=$10; gsub(/^[ \t]+|[ \t]+$/,"",s); print s}')
  evidence=$(printf '%s' "$row" | awk -F'|' '{e=$11; gsub(/^[ \t]+|[ \t]+$/,"",e); print e}')
  [[ -z "$status" ]] && continue
  ((total++))
  [[ "$status" == GAP ]] && ((gap_count++))
done < <(echo "$content" | awk '/^## Cell status grid/{ins=1;next} ins && /^## /{ins=0} ins && /^\|/{print}')
echo "$gap_count/$total"
CMS
expect_violation "the coverage-matrix shape: \$10/\$11 pulled ABOVE a below-sitting /^\\|/ extraction" \
  "$TMP/coverage-matrix-shape.sh"

# And the counterpart: the file as it stands TODAY, header-resolved, must be clean. This is the
# assertion that would have gone red had the fix been wrong rather than merely late.
expect_clean "validate-coverage-matrix.sh as it stands today (header-resolved)" \
  "$ROOT/.speck/scripts/validation/validators/validate-coverage-matrix.sh"


echo ""
echo "Test 12: evidence is read from CODE, not prose — a commented-out positional pull is not a violation"
# The mirror of the Test 1 negative controls. Comment-stripping must cut both ways: prose cannot
# exonerate a positional reader, and prose cannot convict a file that has none.
cat > "$TMP/commented-out-pull.sh" <<'CMT'
#!/usr/bin/env bash
set -euo pipefail
rows="$(awk '/^\|/{print}' "$1")"
while IFS= read -r row; do
  # gid=$(printf '%s' "$row" | awk -F'|' '{print $2}')   # the old positional read, replaced
  printf '%s\n' "$row"
done <<< "$rows"
CMT
expect_clean "a positional pull that exists only inside comments" "$TMP/commented-out-pull.sh"


echo ""
echo "Test 13: ORDINARY BOILERPLATE does not satisfy Evidence C"
# The failure mode this repo has already shipped twice is a rule whose body is satisfied by
# unrelated everyday code. Evidence C requires an identifier that binds a resolution VERB to a
# header/column NOUN as a whole segment, so a `get_color`/`getcolor` helper — ordinary in any
# script — must NOT exonerate a positional reader, while `getcolumn`/`get_col_index` must.
mk_named_reader() {
  local fn="$1" out="$2"
  cat > "$out" <<EOF
#!/usr/bin/env bash
set -euo pipefail
rows="\$(awk '/^\\|/{print}' "\$1")"
$fn() { :; }
while IFS= read -r row; do
  gid=\$(printf '%s' "\$row" | awk -F'|' '{print \$2}')
  printf '%s\n' "\$gid"
done <<< "\$rows"
EOF
}
for fn in get_color getcolor header_row; do
  mk_named_reader "$fn" "$TMP/named-$fn.sh"
  expect_violation "a positional reader that merely defines $fn() is still convicted" "$TMP/named-$fn.sh"
done
for fn in getcolumn get_col_index column_index; do
  mk_named_reader "$fn" "$TMP/named-$fn.sh"
  expect_clean "a reader that defines $fn() is treated as header-resolving" "$TMP/named-$fn.sh"
done


echo ""
echo "Test 14: the header's WINDOW disclosure is MECHANICAL, not asserted"
# validate-two-carrier.sh's header states that gate-liveness-probe.sh is exonerated by Evidence C
# at ANY window size, i.e. that it does NOT calibrate WINDOW's upper bound. That is a claim about
# behaviour, so it is executed here rather than trusted: rescan it with WINDOW raised to 100000
# and the verdict must not move. If someone later removes that file's header resolution, this
# fails and the header comment has to be rewritten — the disclosure cannot rot silently.
BIGWIN="$TMP/bigwindow-validator.sh"
sed 's/^  WINDOW = 150$/  WINDOW = 100000/' "$VALIDATOR" > "$BIGWIN"
bigwin_patched="$(grep -c 'WINDOW = 100000' "$BIGWIN" || true)"
PROBE="$ROOT/.speck/scripts/validation/validators/gate-liveness-probe.sh"
rc_norm=0; bash "$VALIDATOR" --strict "$PROBE" >/dev/null 2>&1 || rc_norm=$?
rc_big=0;  bash "$BIGWIN"    --strict "$PROBE" >/dev/null 2>&1 || rc_big=$?
if [[ "$bigwin_patched" -ne 1 ]]; then
  echo "ERROR: could not patch WINDOW in the validator — the disclosure test did not actually run"
  fails=$((fails + 1))
elif [[ $rc_norm -eq 0 && $rc_big -eq 0 ]]; then
  echo "  ✓ gate-liveness-probe.sh is clean at WINDOW=150 and at WINDOW=100000 (Evidence C, not the window)"
else
  echo "ERROR: WINDOW disclosure is stale — probe verdict at WINDOW=150 was rc=$rc_norm, at 100000 rc=$rc_big."
  echo "       The header comment in validate-two-carrier.sh must be rewritten to match."
  fails=$((fails + 1))
fi


echo ""
if [[ $fails -gt 0 ]]; then
  echo "FAILED: $fails validate-two-carrier.test.sh assertion(s) failed"
  exit 1
fi
if [[ $skips -gt 0 ]]; then
  echo "PASSED WITH $skips SKIPPED assertion(s) — see the ⚠ SKIP notice(s) above. Skipped ≠ passed."
fi
echo "All validate-two-carrier tests passed successfully!"
exit 0
