#!/usr/bin/env bash
# Tests for migrate.sh's project.json reconciliation.
#
# THE SCAR, PART ONE (fixed earlier): this script wrote the literal '7.0.0' into
# .speck/project.json → speck_version. Nothing else in Speck ever wrote that field, so
# every project that ran the migration reported 7.0.0 forever while .speck/VERSION
# advanced underneath it. detect-version.test.sh pins that half.
#
# THE SCAR, PART TWO (this file): the repair kept the ORIGINAL delivery mechanism —
# a python3 -c whose source has the path interpolated into a string literal. A workspace
# at `.../kjetil's ws` closes that literal early, python3 dies on a SyntaxError, and
# `set -euo pipefail` takes the whole migration down with it — leaving the field frozen
# at exactly the stale value the repair existed to unfreeze. profile-lib.sh had already
# been converted to pass the path as an ARGUMENT for this reason; migrate.sh, the file
# that writes the field, had not.
#
# Every case runs the real script against a real workspace, because the defect is
# end-to-end: the unit under test is "what is on disk when the script exits".
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
SCRIPTS="$ROOT/.speck/scripts"

FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "      expected: [${2-}]"; echo "      actual:   [${3-}]"; FAILED=1; }
eq() { # eq <label> <expected> <actual>
  if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1" "$2" "$3"; fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# mkws <dir-name> [project.json speck_version]
# Build a throwaway workspace holding real copies of the scripts under test. The
# directory NAME is the parameter under test in the apostrophe case, so it is quoted
# everywhere and never re-derived.
mkws() {
  local name="$1" pj_version="${2-}"
  local ws="$TMP/$name"
  mkdir -p "$ws/.speck/scripts/lib" "$ws/.speck/templates" "$ws/specs/projects/demo"
  cp "$SCRIPTS/migrate.sh" "$SCRIPTS/profile-lib.sh" "$ws/.speck/scripts/"
  cp "$SCRIPTS/lib/text.sh" "$ws/.speck/scripts/lib/" 2>/dev/null || true
  printf '9.6.0\n' > "$ws/.speck/VERSION"
  if [[ -n "$pj_version" ]]; then
    printf '{\n  "play_level": "build",\n  "speck_version": "%s"\n}\n' "$pj_version" > "$ws/.speck/project.json"
  fi
  printf '# demo\n' > "$ws/specs/projects/demo/project.md"
  printf '%s' "$ws"
}

# read_field <project.json path>
# The path is an ARGUMENT, never interpolated — a helper carrying the very bug under
# test would fail every apostrophe case for the wrong reason.
read_field() {
  python3 - "$1" <<'PY'
import json, sys
try:
    print(json.load(open(sys.argv[1])).get('speck_version', ''))
except Exception as e:
    print(f'READ-ERROR: {e}')
PY
}

echo "── migrate.sh reconciles speck_version to .speck/VERSION"

WS_PLAIN="$(mkws plain 7.0.0)"
OUT_PLAIN="$( (cd "$WS_PLAIN" && bash .speck/scripts/migrate.sh specs/projects/demo) 2>&1 || echo "MIGRATE-EXIT-$?" )"
eq "a stale 7.0.0 field is rewritten to the installed version" "9.6.0" "$(read_field "$WS_PLAIN/.speck/project.json")"

echo "── migrate.sh creates project.json carrying the installed version"

WS_NEW="$(mkws fresh "")"
(cd "$WS_NEW" && bash .speck/scripts/migrate.sh specs/projects/demo) >/dev/null 2>&1 || true
eq "a created project.json is not stamped 7.0.0" "9.6.0" "$(read_field "$WS_NEW/.speck/project.json")"

echo "── a workspace path with an apostrophe"

# The reproduction. Before the fix this run died on a python SyntaxError and `set -e`
# aborted the migration, leaving the field at exactly the stale value it came in with.
WS_APOS="$(mkws "kjetil's ws" 7.0.0)"
APOS_RC=0
APOS_OUT="$( (cd "$WS_APOS" && bash .speck/scripts/migrate.sh specs/projects/demo) 2>&1 )" || APOS_RC=$?
eq "migrate.sh completes at an apostrophe path" "0" "$APOS_RC"
eq "the field is still reconciled, not frozen at 7.0.0" "9.6.0" "$(read_field "$WS_APOS/.speck/project.json")"

# A SyntaxError is the specific failure this guards; name it, so a future regression
# reports the cause rather than only the symptom. Captured first, matched second —
# `cmd | grep -q` under pipefail reports cmd's status, not the match.
if [[ "$APOS_OUT" == *"SyntaxError"* ]]; then
  fail "no python SyntaxError in the output" "(no SyntaxError)" "$APOS_OUT"
else
  pass "no python SyntaxError in the output"
fi

# And the migration report the script promises actually exists — proof it ran to the end
# rather than exiting early with the field already written.
if [[ -f "$WS_APOS/specs/projects/demo/migration-report.md" ]]; then
  pass "migration-report.md written at an apostrophe path"
else
  fail "migration-report.md written at an apostrophe path" "file exists" "missing"
fi

if [[ "$FAILED" == 0 ]]; then
  echo "✅ migrate.sh: all tests passed"
else
  echo "❌ migrate.sh: FAILURES"
  exit 1
fi
