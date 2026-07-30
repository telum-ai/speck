#!/usr/bin/env bash
# detect-version.test.sh — tests for the ONE read of "which Speck version is this workspace on".
#
# THE SCAR this pins: a workspace whose `.speck/VERSION` read 9.5.0 had
# `detect-version.sh` return 7.0.0. Two files answered the same question from two
# different sources — detect-version.sh from `project.json.speck_version`, profile-lib.sh
# from `.speck/VERSION` — and the source detect-version.sh trusted was written HARDCODED
# to 7.0.0 by migrate.sh and never touched again by any upgrade. The stale field won by
# construction, and the two readers disagreed in silence on every upgraded repo.
#
# Every case below is written against a REAL workspace on disk, invoked exactly the way
# the callers invoke it, because the defect only shows up end-to-end.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../" && pwd)"
SCRIPTS="$ROOT/.speck/scripts"

FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "      expected: [${2-}]"; echo "      actual:   [${3-}]"; FAILED=1; }
eq() { # eq <label> <expected> <actual>
  if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1" "$2" "$3"; fi
}
contains() { # contains <label> <needle> <haystack>
  if [[ "$3" == *"$2"* ]]; then pass "$1"; else fail "$1" "*$2*" "$3"; fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# mkws <name> [version-file-contents] [project.json speck_version]
# Build a throwaway workspace carrying a real copy of the scripts under test.
mkws() {
  local name="$1" version="${2-}" pj_version="${3-}"
  local ws="$TMP/$name"
  mkdir -p "$ws/.speck/scripts/lib"
  cp "$SCRIPTS/detect-version.sh" "$ws/.speck/scripts/"
  cp "$SCRIPTS/profile-lib.sh" "$ws/.speck/scripts/"
  cp "$SCRIPTS/lib/text.sh" "$ws/.speck/scripts/lib/" 2>/dev/null || true
  [[ -n "$version" ]] && printf '%s\n' "$version" > "$ws/.speck/VERSION"
  if [[ -n "$pj_version" ]]; then
    printf '{\n  "play_level": "build",\n  "speck_version": "%s"\n}\n' "$pj_version" > "$ws/.speck/project.json"
  fi
  echo "$ws"
}

echo "── detect-version.sh: .speck/VERSION is authoritative"

# The headline reproduction. project.json says 7.0.0 (what migrate.sh hardcoded years
# ago); .speck/VERSION says 9.5.0 (what the installer actually wrote this morning).
WS="$(mkws upgraded 9.5.0 7.0.0)"
OUT="$(cd "$WS" && bash .speck/scripts/detect-version.sh 2>/dev/null || true)"
eq "an upgraded 9.5.0 project reports 9.5.0, not the stale project.json field" "9.5.0" "$OUT"

# The disagreement must not be silent — a stale advisory field is a real defect in the
# project, and the operator is the only one who can fix it.
ERR="$(cd "$WS" && bash .speck/scripts/detect-version.sh 2>&1 >/dev/null || true)"
contains "disagreement warns loudly" "9.5.0" "$ERR"
contains "the warning names the stale value" "7.0.0" "$ERR"
contains "the warning names the file to fix" "project.json" "$ERR"

# …and the warning must go to stderr only: every caller captures stdout with $(…).
eq "stdout stays parseable (warning on stderr)" "9.5.0" "$OUT"

echo "── detect-version.sh and profile-lib.sh answer identically"

# The silent split: two readers, two sources, same repo. They must be one read now.
# shellcheck source=/dev/null
. "$WS/.speck/scripts/profile-lib.sh"
PROFILE_OUT="$(profile_read_speck_version "$WS" 2>/dev/null || true)"
eq "profile-lib agrees with detect-version" "$OUT" "$PROFILE_OUT"

echo "── fallbacks"

# No VERSION file at all: a genuinely pre-VERSION legacy install. project.json is then
# the only signal there is, so it is honoured rather than ignored.
WS_LEGACY="$(mkws legacy "" 7.0.0)"
OUT_LEGACY="$(cd "$WS_LEGACY" && bash .speck/scripts/detect-version.sh 2>/dev/null || true)"
eq "no VERSION file → the advisory field is used" "7.0.0" "$OUT_LEGACY"

# VERSION alone, no project.json — the shape of a fresh install.
WS_FRESH="$(mkws fresh 9.5.0 "")"
OUT_FRESH="$(cd "$WS_FRESH" && bash .speck/scripts/detect-version.sh 2>/dev/null || true)"
eq "VERSION alone is returned" "9.5.0" "$OUT_FRESH"
ERR_FRESH="$(cd "$WS_FRESH" && bash .speck/scripts/detect-version.sh 2>&1 >/dev/null || true)"
eq "agreement is quiet (no warning when there is nothing to warn about)" "" "$ERR_FRESH"

# Agreement between the two files is also quiet.
WS_AGREE="$(mkws agree 9.5.0 9.5.0)"
ERR_AGREE="$(cd "$WS_AGREE" && bash .speck/scripts/detect-version.sh 2>&1 >/dev/null || true)"
eq "matching values are quiet" "" "$ERR_AGREE"

# No marker anywhere → the documented legacy-v6 default, unchanged.
WS_NONE="$(mkws bare "" "")"
OUT_NONE="$(cd "$WS_NONE" && bash .speck/scripts/detect-version.sh 2>/dev/null || true)"
eq "no marker anywhere → legacy 6" "6" "$OUT_NONE"

echo "── a workspace path with an apostrophe still reads correctly"

# THE SCAR: speck_workspace_version() read project.json by INTERPOLATING the path into a
# Python string literal — open('$project_json'). A workspace at `.../kjetil's ws` closed the
# literal early, python3 died on a SyntaxError, and `2>/dev/null || echo ''` swallowed it
# whole. The failure is silent and asymmetric: with a VERSION file present the disagreement
# warning simply never fires, and with no VERSION file the advisory value is lost entirely, so
# the workspace reports the legacy-v6 default and mis-routes migration and gate logic. Ironic
# in the batch that stood up lib/text.sh precisely to end hand-rolled quoting — so the path is
# passed as an ARGUMENT now, the way read_config_excludes in banned-language-lint.sh does it.
WS_APOS="$(mkws "kjetil's ws" 9.5.0 7.0.0)"
OUT_APOS="$(cd "$WS_APOS" && bash .speck/scripts/detect-version.sh 2>/dev/null || true)"
eq "apostrophe path still reports the authoritative version" "9.5.0" "$OUT_APOS"
ERR_APOS="$(cd "$WS_APOS" && bash .speck/scripts/detect-version.sh 2>&1 >/dev/null || true)"
contains "apostrophe path still warns about the stale advisory field" "7.0.0" "$ERR_APOS"

# The louder half: with no VERSION file the advisory field is the ONLY signal, so losing it
# turns a real 8.2.0 legacy workspace into a reported "6".
WS_APOS_LEGACY="$(mkws "therese's legacy" "" 8.2.0)"
OUT_APOS_LEGACY="$(cd "$WS_APOS_LEGACY" && bash .speck/scripts/detect-version.sh 2>/dev/null || true)"
eq "apostrophe path, no VERSION → the advisory field, not the v6 default" "8.2.0" "$OUT_APOS_LEGACY"

echo "── detect-version.sh <file> (artifact mode is unchanged)"
WS_FM="$(mkws artifact 9.5.0 "")"
printf -- '---\nspeck_version: 8.0\n---\n\n# doc\n' > "$WS_FM/doc.md"
OUT_FM="$(cd "$WS_FM" && bash .speck/scripts/detect-version.sh doc.md 2>/dev/null || true)"
eq "frontmatter still wins for a specific artifact" "8.0" "$OUT_FM"
printf -- '# doc\n\n*[as of SHA abc1234 | verified 2026-01-01 | speck v7.2.0]*\n' > "$WS_FM/footer.md"
OUT_FOOT="$(cd "$WS_FM" && bash .speck/scripts/detect-version.sh footer.md 2>/dev/null || true)"
eq "SHA-stamp footer still read for a specific artifact" "7.2.0" "$OUT_FOOT"
# An artifact with no marker at all falls back to the project — which must be the
# authoritative project answer, not the stale one.
printf -- '# plain\n' > "$WS_FM/plain.md"
OUT_PLAIN="$(cd "$WS_FM" && bash .speck/scripts/detect-version.sh plain.md 2>/dev/null || true)"
eq "unmarked artifact falls back to the authoritative project version" "9.5.0" "$OUT_PLAIN"

echo "── migrate.sh writes the version it actually migrated to"

# migrate.sh wrote '7.0.0' as a literal in three places. That literal is what froze the
# advisory field for every project that ever ran it.
WS_MIG="$(mkws migrated 9.5.0 7.0.0)"
mkdir -p "$WS_MIG/.speck/templates" "$WS_MIG/specs/projects/demo"
cp "$SCRIPTS/migrate.sh" "$WS_MIG/.speck/scripts/"
printf '# demo\n' > "$WS_MIG/specs/projects/demo/project.md"
MIG_OUT="$(cd "$WS_MIG" && bash .speck/scripts/migrate.sh specs/projects/demo 2>&1 || true)"
# Argument, not interpolation — the same trap the apostrophe cases above pin, and a test
# helper that carries it would fail for the wrong reason the day $TMP grows a quote.
PJ_AFTER="$(python3 - "$WS_MIG/.speck/project.json" <<'PY'
import json, sys
print(json.load(open(sys.argv[1])).get('speck_version', ''))
PY
)"
eq "migrate.sh does not re-freeze the field at 7.0.0" "9.5.0" "$PJ_AFTER"
# And after migrating, the two readers still agree — which is the whole point.
OUT_MIG="$(cd "$WS_MIG" && bash .speck/scripts/detect-version.sh 2>/dev/null || true)"
eq "post-migration detection matches .speck/VERSION" "9.5.0" "$OUT_MIG"
if [[ "$PJ_AFTER" != "9.5.0" ]]; then
  echo "      (migrate.sh output was: $(printf '%s' "$MIG_OUT" | tr '\n' '|'))"
fi

if [[ "$FAILED" == 0 ]]; then
  echo "✅ detect-version.sh: all tests passed"
else
  echo "❌ detect-version.sh: FAILURES"
  exit 1
fi
