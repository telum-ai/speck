#!/usr/bin/env bash
# validate-schema-drift.sh — Schema Parity and Migration Integrity Gate (Speck v7.15; exit-contract
# and matching repair v9.6, #95).
#
# Scans project migrations to build an object inventory, checks for migration-repair footguns,
# and (with --live --target <DATABASE_URL>) verifies the live target DB matches committed
# migrations.
#
# #95 — #64 G1 ("INTEGRATION-GREEN is blind to live schema/migration drift") was filed, closed, and
# its repair shipped as this script in v7.15. It recurred six weeks later in Brightstance with
# database WRITES DESTROYED, because the shipped probe was structurally unable to fail:
#   (a) OBJECTS_FOUND was incremented inside a `find | sort | while read` — a PIPELINE SUBSHELL —
#       so the parent's counter never moved. "Found 0 database objects" printed across 39 real
#       migration files, and the >25-row truncation notice was dead code.
#   (b) the live-catalog comparison (`grep -qi "$type:$name"`) was an unanchored substring match:
#       an expected `table:order` false-PASSED against a catalog holding only `table:orders`.
#   (c) the footgun scan (`git grep -ni "migration repair"`) carried no pathspec, so it convicted
#       Speck's OWN shipped warning text in every downstream repo (7 false P1s on Brightstance).
#   (d) the only path to a non-zero exit ran through the `--live` block, and that block silently
#       downgraded itself (no DB tool, empty introspection) and still printed
#       "✅ Schema verification complete." — an unproven run read exactly like a proven one.
#   (e) the live leg connected to whatever local DB happened to be ambient (DATABASE_URL, a linked
#       `supabase` project) — measured once emitting 32 confident SCHEMA_DRIFT.P0 lines against an
#       UNRELATED project's database.
#   (f) [Tranche B, v9.6/v10] the inventory was OBJECT grain — five `CREATE …` forms matched by
#       per-LINE regex — while BOTH destroyed writes diverged at COLUMN and CONSTRAINT grain.
#       `coaching_sessions.draft_id` arrives as `ALTER TABLE … ADD COLUMN` plus
#       `CREATE UNIQUE INDEX`; `energization` carries an inline `CHECK` in a multi-line
#       `CREATE TABLE`. Across 39 real migration files those three shapes were 17 + 32 + 18
#       statements producing ZERO inventory entries, so no live assertion was ever generated for
#       any of them — while the gate's own checklist (evidence-contract-template.md) promised
#       "every table, COLUMN, type and trigger function". Tranche B replaces the line regexes with
#       a statement-level scanner (see section 3) and adds column/check/constraint/index grain.
#
# ORDER MATTERS AND IT WAS DELIBERATE: (f) landed only AFTER (b). Column names (`id`, `name`,
# `status`) are near-universal substrings, so column grain on top of the old unanchored
# `grep -qi "$type:$name"` would have RAISED the false-pass rate. The comparison is now
# `sp_match_exact` — `grep -qxF`, fixed-string and whole-line — against a catalog normalised to one
# `type:name` token per line. Re-verify that before widening the grain again.
#
# BREAKING, BY DESIGN: a project that has passed this gate since v7.15 can now report real drift on
# its live leg. Every such finding names the table, the column/constraint/index, the migration file
# that declares it, and the fix (see report_drift).
#
# Usage:
#   validate-schema-drift.sh [--live --target <DATABASE_URL>] [--strict] <project-root | database-dir>
#
# Verdict (three-valued, honest exit contract — #95 finding 1d):
#   VERIFIED — the live leg ran against an explicitly named target and the inventory was checked
#              against the real catalog (whether or not drift was found).
#   UNPROVEN — a live check was requested (--live) but could not be completed (no `psql`, a failed
#              connection, an empty introspection). NEVER reads as a pass under --strict.
#   SKIPPED  — nothing to check (no migration directory), OR nothing was asked (no --live), OR
#              --live was given with no --target (refuse to guess a connection — #95 finding 1e).
#              A SKIPPED reached via a caller who explicitly asked for --live is NOT a pass under
#              --strict either — the caller asked for proof and got none.
#
# Exit codes:
#   0 = VERIFIED with no drift, or SKIPPED/UNPROVEN under non-strict (nobody demanded proof), or a
#       clean non-live notice-mode run.
#   1 = drift found (violations), or repair-footgun warnings under --strict, or --live was
#       requested but ended UNPROVEN/SKIPPED-for-missing-target under --strict.
#   2 = invocation error.
#
# Every exit path emits SPECK_GATE_SCOPE / SPECK_GATE_SUBJECT / SPECK_GATE_PREDICATES so a caller
# can tell a real green from a vacuous one without parsing prose (the same vacuity-telemetry
# contract as Speck's other gates). It also emits SPECK_GATE_MODE=notice|live (#95/#98 follow-up,
# v9.6/v10): PREDICATES is ONLY ever incremented inside the --live comparison loop (section 4), so
# every non-live invocation — the common case, measured PREDICATES=0 with exit 0 across 7 real
# repos / 188 migration files — legitimately has zero predicates to report, by design, not by
# defect. Without MODE, a consumer (gate-liveness-probe.sh) cannot tell that honest zero apart from
# a gate that scanned files and compared them against nothing (the #98 GATE_VACUOUS.P1 shape) —
# and DID convict it: a project listing this gate in §6a with a canary key got a false
# GATE_VACUOUS.P1 and a blocked /epic-validate for notice-mode behaving exactly as designed. MODE
# tells the truth about WHICH shape this run is; the probe reads it instead of guessing.
#
# Portable bash 3.2 / macOS. No associative arrays, no mapfile.

set -euo pipefail

# shellcheck disable=SC1091
. "$(dirname "$0")/../../lib/text.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# --- Vacuity telemetry (#95, hardened #95 P2-2): every exit path names what was actually
# scanned/checked — INCLUDING invocation errors, not just the paths that get as far as a project
# root. The defaults + emitter must be defined, and the EXIT trap installed, BEFORE the arg-parse
# loop below: `--bogus` and a valueless `--target` both `exit 2` from inside that loop, and when
# this block lived after the loop (pre-P2-2) those two paths ran before emit_gate_telemetry even
# existed — verified, neither printed a single SPECK_GATE_* line, unlike the "Target not found"
# exit 2 a few lines further down. TELEMETRY_EMITTED guards against a double emission where a
# later call site still invokes emit_gate_telemetry manually right before its own `exit` — the
# trap then fires on top of that and must no-op, not print the block twice.
GATE_SCOPE="none"
OBJECTS_FOUND=0
PREDICATES_EVALUATED=0
# GATE_MODE: "notice" until (and unless) the live leg actually runs a full comparison and reaches
# VERDICT=VERIFIED (section 6 sets it). Every other outcome — no --live, --live with no --target,
# an UNPROVEN connection/introspection failure, or no migration dir at all — genuinely never
# evaluates a predicate, so "notice" is the honest default, not a fallback masking a defect.
GATE_MODE="notice"
TELEMETRY_EMITTED=false
emit_gate_telemetry() {
  [[ "$TELEMETRY_EMITTED" == true ]] && return 0
  TELEMETRY_EMITTED=true
  echo "SPECK_GATE_SCOPE=$GATE_SCOPE"
  echo "SPECK_GATE_SUBJECT=$OBJECTS_FOUND"
  echo "SPECK_GATE_PREDICATES=$PREDICATES_EVALUATED"
  echo "SPECK_GATE_MODE=$GATE_MODE"
}
trap emit_gate_telemetry EXIT

LIVE_MODE=false
STRICT_MODE=false
LIVE_TARGET=""
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --live) LIVE_MODE=true; shift ;;
    --strict) STRICT_MODE=true; shift ;;
    --target)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --target requires a value (a DATABASE_URL psql can connect with)." >&2
        exit 2
      fi
      LIVE_TARGET="$2"
      shift 2
      ;;
    -*) echo "Unknown flag: $1" >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done
# Captured BEFORE any self-downgrade below, so the exit contract can tell "nobody asked for a live
# check" (SKIPPED is honest) apart from "asked for one and didn't get it" (must not read as a pass).
LIVE_REQUESTED="$LIVE_MODE"

if [[ -z "$TARGET" ]]; then
  TARGET="."
fi

if [[ ! -d "$TARGET" && ! -f "$TARGET" ]]; then
  echo -e "${RED}ERROR: Target '$TARGET' not found.${NC}" >&2
  emit_gate_telemetry
  exit 2
fi

# Resolve root path
ROOT_DIR=""
if [[ -d "$TARGET" ]]; then
  ROOT_DIR="$(cd "$TARGET" && pwd)"
else
  ROOT_DIR="$(cd "$(dirname "$TARGET")" && pwd)"
fi

# 1. Scan for migration-repair footguns (statically in git history/repo scripts)
warnings=0
violations=0

echo -e "${BLUE}🔎 Scanning repository for migration-repair footguns...${NC}"

# Find any shell scripts, json, yaml, workflows, or instructions containing "migration repair".
# `-- . ':(exclude).speck'` (#95 finding 1c): Speck's OWN shipped warning text (this header, the
# evidence-contract template's CRITICAL WARNING) SAYS "migration repair" — the phrase this scan is
# looking for — so an unscoped `git grep` convicts Speck's own source in every downstream repo (7
# false P1s measured on Brightstance). The non-git fallback below already excluded .speck; this
# brings the git path to parity with it.
repair_matches=""
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  repair_matches=$(git grep -ni "migration repair" -- . ':(exclude).speck' || true)
else
  # Fallback to standard grep
  repair_matches=$(grep -rni "migration repair" "$ROOT_DIR" --exclude-dir={node_modules,.git,.speck,.cursor} || true)
fi

if [[ -n "$repair_matches" ]]; then
  echo -e "${YELLOW}⚠️  MIGRATION_REPAIR_WARNING.P1: Found references to 'migration repair' in workspace:${NC}"
  echo "$repair_matches" | while read -r match; do
    echo -e "  ${YELLOW}- $match${NC}"
  done
  echo -e "${YELLOW}  Using 'migration repair' or 'repair --status applied' registers migrations in the ledger"
  echo -e "  WITHOUT running their SQL. This is a severe footgun that silently causes schema drift.${NC}"
  warnings=$((warnings + 1))
fi

# 2. Identify migration framework and directory
echo -e "${BLUE}🔎 Identifying migration framework and directories...${NC}"
MIGRATION_TYPE=""
MIGRATION_DIR=""

detect_migration_dir_at() {
  # Sets MIGRATION_TYPE/MIGRATION_DIR and returns 0 on a hit; leaves them untouched on a miss.
  local base="$1"
  if [[ -d "$base/supabase/migrations" ]]; then
    MIGRATION_TYPE="supabase"; MIGRATION_DIR="$base/supabase/migrations"; return 0
  elif [[ -d "$base/migrations" ]]; then
    # Could be postgres, alembic, or other generic SQL migrations
    if ls "$base/migrations"/*.py >/dev/null 2>&1; then
      MIGRATION_TYPE="alembic"
    else
      MIGRATION_TYPE="generic-sql"
    fi
    MIGRATION_DIR="$base/migrations"; return 0
  elif [[ -d "$base/prisma/migrations" ]]; then
    MIGRATION_TYPE="prisma"; MIGRATION_DIR="$base/prisma/migrations"; return 0
  elif [[ -d "$base/alembic/versions" ]]; then
    MIGRATION_TYPE="alembic"; MIGRATION_DIR="$base/alembic/versions"; return 0
  fi
  return 1
}

# Fast path: the four historically-checked root-anchored locations.
detect_migration_dir_at "$ROOT_DIR" || true

# #95 finding 1d: a migration directory living one level below the repo root (Splang:
# backend/alembic/versions, 76 real migration files) was invisible to a root-only check — green
# skip, exit 0, the schema half never ran. Fall back to a BOUNDED search (maxdepth 4, pruning the
# directories migrations never live under) rather than either staying root-anchored forever or an
# unbounded `find` that would wander into node_modules/vendor and slow every invocation down.
if [[ -z "$MIGRATION_TYPE" ]]; then
  while IFS= read -r hit; do
    [[ -z "$hit" ]] && continue
    case "$hit" in
      */supabase/migrations) MIGRATION_TYPE="supabase"; MIGRATION_DIR="$hit"; break ;;
      */prisma/migrations)   MIGRATION_TYPE="prisma";   MIGRATION_DIR="$hit"; break ;;
      */alembic/versions)    MIGRATION_TYPE="alembic";  MIGRATION_DIR="$hit"; break ;;
      */migrations)
        if ls "$hit"/*.py >/dev/null 2>&1; then MIGRATION_TYPE="alembic"; else MIGRATION_TYPE="generic-sql"; fi
        MIGRATION_DIR="$hit"; break ;;
    esac
  done < <(find "$ROOT_DIR" -maxdepth 4 -type d \
             \( -name node_modules -o -name .git -o -name vendor -o -name .venv -o -name venv \
                -o -name dist -o -name build -o -name .speck \) -prune -o \
             -type d \( -path '*/supabase/migrations' -o -path '*/migrations' \
                        -o -path '*/prisma/migrations' -o -path '*/alembic/versions' \) -print \
             2>/dev/null | sort)
fi

if [[ -z "$MIGRATION_TYPE" ]]; then
  GATE_SCOPE="$ROOT_DIR (no migration directory found)"
  echo -e "${GREEN}✅ No database migration directories found. Skipping schema validation.${NC}"
  echo -e "${BLUE}   Verdict: SKIPPED — nothing to check.${NC}"
  emit_gate_telemetry
  if [[ "$STRICT_MODE" == true && $warnings -gt 0 ]]; then
    exit 1
  fi
  exit 0
fi

GATE_SCOPE="$MIGRATION_DIR"
echo -e "  Framework: ${GREEN}$MIGRATION_TYPE${NC}"
echo -e "  Directory: ${GREEN}$MIGRATION_DIR${NC}"

# 3. Build the expected-schema inventory (#95 Tranche B — STATEMENT-LEVEL, column/constraint grain)
#
# WHY A STATEMENT SCANNER AND NOT A SIXTH REGEX.
# The v7.15 probe matched five `CREATE …` forms with per-LINE bash regexes. Both Brightstance
# write-destroying divergences were invisible to it because they are not `CREATE` and not on one
# line: `coaching_sessions.draft_id` arrives as `ALTER TABLE … ADD COLUMN IF NOT EXISTS draft_id
# uuid;` plus `CREATE UNIQUE INDEX … (user_id, draft_id)`, and `energization` carries an inline
# `CHECK (energization >= 1 AND energization <= 10)` inside a multi-line CREATE TABLE. Across 39
# real migration files the three shapes that produce ZERO inventory entries under a line matcher
# were 17 ADD COLUMNs, 32 CHECKs and 18 CREATE INDEXes.
# A line matcher also cannot tell code from a comment or from a string, and reads statements
# inside `DO $$ … $$` (the standard idempotent-column-add idiom) as if they were top level. So the
# scanner below is a real, if small, SQL front end: comment stripping that respects '…', "…" and
# $tag$…$tag$; statement splitting on TOP-LEVEL semicolons only; balanced-paren column-list
# parsing; and one level of recursion into a DO block's body.
#
# ORDERING — WHY THIS IS SAFE TO LAND NOW AND WAS NOT IN v9.6.
# Column names (`id`, `name`, `status`) are near-universal substrings, so column grain on top of an
# UNANCHORED comparison would raise the false-PASS rate rather than lower it. v9.6 landed the
# anchored comparison first: `sp_match_exact` is `grep -qxF` — fixed-string, WHOLE-LINE — against a
# catalog normalised to one `type:name` token per line. Verified before this grain was added.
# Identifiers are additionally folded the way Postgres folds them (unquoted → lowercase, "Quoted"
# → verbatim), which the pre-#95 inventory never did: `CREATE TABLE Orders` used to inventory
# `table:Orders` and could never match a real catalog's `table:orders` under -qxF.
#
# GRAIN KEYS (both sides of the comparison speak exactly these):
#   table:<t>  type:<t>  view:<v>  function:<f>  trigger:<g>   (v7.15 grain, unchanged)
#   column:<table>.<col>        every declared column, from CREATE TABLE and ALTER TABLE ADD COLUMN
#   index:<name>                every named CREATE [UNIQUE] INDEX
#   constraint:<name>           every NAMED constraint (ADD CONSTRAINT / inline CONSTRAINT …)
#   check:<table>.<col>         every column-level CHECK, keyed by COLUMN not by name — Postgres
#                               auto-names anonymous checks (`t_col_check`, `t_col_check1`), so a
#                               name-keyed assertion would be a coin flip; the live side projects
#                               pg_constraint through conkey to the same table.column key.
# Deliberately NOT inventoried, because the key would not be derivable and a wrong key is a false
# P0: unnamed TABLE-level CHECKs (`CHECK (a < b)` as its own table element), unnamed indexes
# (`CREATE INDEX ON t (…)`), and MATERIALIZED VIEWs (absent from pg_views).
#
# DROP/RENAME RECONCILIATION. An inventory built by accretion asserts objects a later migration
# deliberately removed. The scanner emits signed rows (`+`/`-`, plus `!` cascade for a dropped or
# renamed table) in migration order and a reconcile pass keeps the LAST state per key, so
# `ADD COLUMN x` … `DROP COLUMN x` nets to nothing instead of a false P0.
echo -e "${BLUE}🔎 Compiling expected database objects inventory from migrations...${NC}"
OBJECTS_FOUND=0

INVENTORY_FILE=$(mktemp)
RAW_INVENTORY_FILE=$(mktemp)
SCRATCH_FILES="$INVENTORY_FILE $RAW_INVENTORY_FILE"

# The three awk programs below are written to temp files and run with `awk -f` rather than passed
# as a $(cat <<HEREDOC) string: bash 3.2 (the macOS system shell, and Speck's floor) counts
# parentheses inside a command substitution WITHOUT honouring the here-document, so a legitimate
# awk regex such as /^(PRIMARY KEY|UNIQUE)[ (]/ makes the whole script unparseable. Verified.
SQL_SCANNER_AWK=$(mktemp)
PY_SCANNER_AWK=$(mktemp)
RECONCILE_AWK=$(mktemp)
SCRATCH_FILES="$SCRATCH_FILES $SQL_SCANNER_AWK $PY_SCANNER_AWK $RECONCILE_AWK"
# One EXIT trap from here on. Every later `trap ... EXIT` in this script used to REPLACE the
# telemetry trap installed at the top (and each other), so the last one silently owned cleanup and
# telemetry both; SCRATCH_FILES makes the trap body constant and the telemetry unconditional.
# shellcheck disable=SC2064
trap 'rm -f $SCRATCH_FILES; emit_gate_telemetry' EXIT

cat > "$SQL_SCANNER_AWK" <<'AWK'
BEGIN { SQ = sprintf("%c", 39); DQ = sprintf("%c", 34); MODE = "code"; BDEPTH = 0; DTAG = "" }

function spaces(k,   s) { s = ""; while (k-- > 0) s = s " "; return s }
function trim(s) { sub(/^[ \t\r\n]+/, "", s); sub(/[ \t\r\n]+$/, "", s); return s }

# ---- stage 1: comment stripping. State (MODE/BDEPTH/DTAG) is carried ACROSS lines, which is the
# whole point: a `--` inside a string is not a comment, a `;` inside a $$ body is not a statement
# end, and a /* */ can span twenty lines. ----
function strip_line(l,   n, i, c, c2, out, m) {
  n = length(l); i = 1; out = ""
  while (i <= n) {
    c = substr(l, i, 1); c2 = substr(l, i, 2)
    if (MODE == "code") {
      if (c2 == "--") { return out " " }
      if (c2 == "/*") { MODE = "block"; BDEPTH = 1; i += 2; out = out " "; continue }
      if (c == SQ) { MODE = "sq"; out = out c; i++; continue }
      if (c == DQ) { MODE = "dq"; out = out c; i++; continue }
      if (c == "$") {
        m = substr(l, i, 80)
        if (match(m, /^\$([A-Za-z_][A-Za-z0-9_]*)?\$/)) {
          DTAG = substr(m, 1, RLENGTH); MODE = "dollar"
          out = out DTAG; i += RLENGTH; continue
        }
      }
      out = out c; i++; continue
    }
    if (MODE == "block") {
      if (c2 == "/*") { BDEPTH++; i += 2; continue }
      if (c2 == "*/") { BDEPTH--; i += 2; if (BDEPTH <= 0) { MODE = "code"; out = out " " } continue }
      i++; continue
    }
    if (MODE == "sq") {
      if (c == SQ) { if (substr(l, i+1, 1) == SQ) { out = out SQ SQ; i += 2; continue }
                     out = out c; i++; MODE = "code"; continue }
      out = out c; i++; continue
    }
    if (MODE == "dq") {
      if (c == DQ) { if (substr(l, i+1, 1) == DQ) { out = out DQ DQ; i += 2; continue }
                     out = out c; i++; MODE = "code"; continue }
      out = out c; i++; continue
    }
    if (substr(l, i, length(DTAG)) == DTAG) { out = out DTAG; i += length(DTAG); MODE = "code"; continue }
    out = out c; i++
  }
  return out
}

# ---- quote/dollar-quote aware cursor primitives ----
function find_close_q(s, i, q,   n, c) {
  n = length(s)
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == q) { if (substr(s, i+1, 1) == q) { i += 2; continue } return i }
    i++
  }
  return n + 1
}

# skip_atom: if s[i] opens a literal/quoted ident/dollar body, return the index just past its
# close; 0 otherwise. Every scanner below advances through text with this, so no ";" "," "(" ")"
# inside a literal is ever mistaken for structure.
function skip_atom(s, i,   c, m, tag, j) {
  c = substr(s, i, 1)
  if (c == SQ || c == DQ) return find_close_q(s, i + 1, c) + 1
  if (c == "$") {
    m = substr(s, i, 80)
    if (match(m, /^\$([A-Za-z_][A-Za-z0-9_]*)?\$/)) {
      tag = substr(m, 1, RLENGTH)
      j = index(substr(s, i + RLENGTH), tag)
      if (j > 0) return i + RLENGTH + j - 1 + length(tag)
      return length(s) + 1
    }
  }
  return 0
}

function split_statements(s, out,   n, i, st, cnt, c, j, k) {
  for (k in out) delete out[k]
  n = length(s); i = 1; st = 1; cnt = 0
  while (i <= n) {
    j = skip_atom(s, i)
    if (j > 0) { i = j; continue }
    c = substr(s, i, 1)
    if (c == ";") { cnt++; out[cnt] = substr(s, st, i - st); st = i + 1; i++; continue }
    i++
  }
  if (st <= n) { c = substr(s, st, n - st + 1); if (c ~ /[^ \t\r\n]/) { cnt++; out[cnt] = c } }
  return cnt
}

function split_commas(s, out,   n, i, depth, st, cnt, c, j, k) {
  for (k in out) delete out[k]
  n = length(s); i = 1; depth = 0; st = 1; cnt = 0
  while (i <= n) {
    j = skip_atom(s, i)
    if (j > 0) { i = j; continue }
    c = substr(s, i, 1)
    if (c == "(") depth++
    else if (c == ")") depth--
    else if (c == "," && depth == 0) { cnt++; out[cnt] = substr(s, st, i - st); st = i + 1 }
    i++
  }
  c = substr(s, st, n - st + 1)
  if (c ~ /[^ \t\r\n]/) { cnt++; out[cnt] = c }
  return cnt
}

# paren_body: s[i] must be "(". Returns the inner text; sets G_NEXT past the matching ")".
function paren_body(s, i,   n, depth, start, c, j) {
  n = length(s)
  if (substr(s, i, 1) != "(") { G_NEXT = i; return "" }
  depth = 1; i++; start = i
  while (i <= n && depth > 0) {
    j = skip_atom(s, i)
    if (j > 0) { i = j; continue }
    c = substr(s, i, 1)
    if (c == "(") depth++
    else if (c == ")") { depth--; if (depth == 0) break }
    i++
  }
  G_NEXT = i + 1
  return substr(s, start, i - start)
}

# read_ident: Postgres identifier folding. Unquoted -> lowercase (what the catalog stores),
# "Quoted" -> verbatim. A schema qualifier is consumed and DROPPED (the live catalog is queried
# for schema `public`), so `public.orders` and `orders` produce the same key.
function read_ident(s, i,   n, c, out, part) {
  n = length(s); out = ""
  while (i <= n && substr(s, i, 1) ~ /[ \t\r\n]/) i++
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == DQ) {
      i++; part = ""
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == DQ) { if (substr(s, i+1, 1) == DQ) { part = part DQ; i += 2; continue } i++; break }
        part = part c; i++
      }
      out = part
    } else if (c ~ /[A-Za-z0-9_]/) {
      part = ""
      while (i <= n && substr(s, i, 1) ~ /[A-Za-z0-9_]/) { part = part substr(s, i, 1); i++ }
      out = tolower(part)
    } else break
    if (substr(s, i, 1) == ".") { i++; continue }
    break
  }
  G_NEXT = i
  return out
}

# blank_lit: LENGTH-PRESERVING blanking of string-literal contents, so a keyword scan
# (`… CHECK (`) cannot be fooled by the word inside a DEFAULT string, while every index computed
# on the blanked copy still addresses the same character of the original.
function blank_lit(s,   n, i, out, c, j) {
  n = length(s); i = 1; out = ""
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == SQ) {
      j = find_close_q(s, i + 1, SQ)
      if (j > n) { out = out SQ spaces(n - i); i = n + 1; continue }
      out = out SQ spaces(j - i - 1) SQ
      i = j + 1
      continue
    }
    out = out c; i++
  }
  return out
}

function emit(sign, type, name, owner) {
  if (name == "") return
  print sign "\t" type ":" name "\t" FILEBASE "\t" owner
}

# ---- CREATE TABLE ( … ) element parsing: columns, named constraints, column-level CHECKs ----
function scan_table_body(tbl, body,   nn, k, el, EU, col) {
  nn = split_commas(body, TBLEL)
  for (k = 1; k <= nn; k++) {
    el = trim(TBLEL[k])
    if (el == "") continue
    EU = toupper(blank_lit(el))
    if (match(EU, /^CONSTRAINT[ ]/)) {
      col = read_ident(el, RSTART + RLENGTH)
      if (col != "") emit("+", "constraint", col, tbl)
      continue
    }
    # table-level (unnamed) constraint element — no derivable key, deliberately not inventoried
    if (EU ~ /^(PRIMARY KEY|UNIQUE|CHECK|FOREIGN KEY|EXCLUDE|LIKE|PARTITION)[ (]/) continue
    col = read_ident(el, 1)
    if (col == "") continue
    emit("+", "column", tbl "." col, tbl)
    if (toupper(blank_lit(substr(el, G_NEXT))) ~ /(^|[^A-Z0-9_])CHECK[ ]*\(/) emit("+", "check", tbl "." col, tbl)
  }
}

function scan_alter_table(t, U,   i, tbl, nn, k, el, EU, col, name, p) {
  if (!match(U, /^ALTER TABLE (IF EXISTS )?(ONLY )?/)) return
  i = RSTART + RLENGTH
  tbl = read_ident(t, i)
  if (tbl == "") return
  nn = split_commas(substr(t, G_NEXT), ACTS)
  for (k = 1; k <= nn; k++) {
    el = trim(ACTS[k])
    if (el == "") continue
    EU = toupper(blank_lit(el))
    if (match(EU, /^ADD CONSTRAINT (IF NOT EXISTS )?/)) {
      col = read_ident(el, RSTART + RLENGTH)
      if (col != "") emit("+", "constraint", col, tbl)
      continue
    }
    if (match(EU, /^ADD (COLUMN )?(IF NOT EXISTS )?/)) {
      p = RSTART + RLENGTH
      if (substr(EU, p) ~ /^(PRIMARY KEY|UNIQUE|CHECK|FOREIGN KEY|EXCLUDE|CONSTRAINT)[ (]/) continue
      col = read_ident(el, p)
      if (col == "") continue
      emit("+", "column", tbl "." col, tbl)
      if (toupper(blank_lit(substr(el, G_NEXT))) ~ /(^|[^A-Z0-9_])CHECK[ ]*\(/) emit("+", "check", tbl "." col, tbl)
      continue
    }
    if (match(EU, /^DROP CONSTRAINT (IF EXISTS )?/)) {
      col = read_ident(el, RSTART + RLENGTH)
      if (col != "") emit("-", "constraint", col, tbl)
      continue
    }
    if (match(EU, /^DROP (COLUMN )?(IF EXISTS )?/)) {
      col = read_ident(el, RSTART + RLENGTH)
      if (col != "") { emit("-", "column", tbl "." col, tbl); emit("-", "check", tbl "." col, tbl) }
      continue
    }
    if (match(EU, /^RENAME COLUMN /) || match(EU, /^RENAME /)) {
      p = RSTART + RLENGTH
      if (EU ~ /^RENAME TO /) {
        name = read_ident(el, p)
        emit("-", "table", tbl, "")
        emit("!", "cascade", tbl, "")
        if (name != "") emit("+", "table", name, "")
        continue
      }
      col = read_ident(el, p); p = G_NEXT
      if (toupper(substr(el, p)) ~ /^[ ]*TO[ ]/) {
        match(toupper(substr(el, p)), /^[ ]*TO[ ]/)
        name = read_ident(el, p + RLENGTH - 1)
        if (col != "") { emit("-", "column", tbl "." col, tbl); emit("-", "check", tbl "." col, tbl) }
        if (name != "") emit("+", "column", tbl "." name, tbl)
      }
      continue
    }
  }
}

function scan_stmt(t, depth,   U, B, i, j, p, q, tag, inner, cnt, k, tbl, name, own, rest) {
  gsub(/[ \t\r\n]+/, " ", t)
  t = trim(t)
  if (t == "") return
  B = blank_lit(t)
  U = toupper(B)

  # Inside a DO body a DDL statement is wrapped in plpgsql control flow — `BEGIN ALTER TABLE …`,
  # `IF NOT EXISTS (SELECT 1 …) THEN CREATE TYPE …`. Anchoring on ^ would miss every one of them
  # (measured: `notification_enabled`, added by the standard idempotent
  # `DO $$ BEGIN ALTER TABLE … ADD COLUMN …; EXCEPTION WHEN duplicate_column THEN NULL; END $$`
  # idiom, was silently dropped). Re-anchor on the first DDL head instead. U is computed from the
  # literal-blanked copy, so a CREATE inside `EXECUTE '…'` cannot trigger this.
  if (depth > 0 && match(U, /(^|[^A-Z0-9_])(CREATE|ALTER|DROP)[ ]/)) {
    i = RSTART + (substr(U, RSTART, 1) ~ /[A-Z]/ ? 0 : 1)
    t = substr(t, i); B = blank_lit(t); U = toupper(B)
  }

  # DO $$ … $$ — recurse ONCE into the body. The idempotent add-column idiom
  # (`DO $$ BEGIN ALTER TABLE t ADD COLUMN c …; EXCEPTION WHEN duplicate_column THEN NULL; END $$`)
  # is a real declaration and must be inventoried; a line matcher saw its inner `;` as a statement
  # end and its inner text as top-level SQL.
  if (depth == 0 && U ~ /^DO[ $]/) {
    i = index(t, "$")
    if (i > 0) {
      tag = substr(t, i, 80)
      if (match(tag, /^\$([A-Za-z_][A-Za-z0-9_]*)?\$/)) {
        tag = substr(tag, 1, RLENGTH)
        p = i + length(tag)
        j = index(substr(t, p), tag)
        inner = (j > 0) ? substr(t, p, j - 1) : substr(t, p)
        cnt = split_statements(inner, DOSTMT)
        for (k = 1; k <= cnt; k++) scan_stmt(DOSTMT[k], 1)
      }
    }
    return
  }

  if (match(U, /^CREATE (GLOBAL )?(LOCAL )?(TEMPORARY |TEMP |UNLOGGED )?TABLE (IF NOT EXISTS )?/)) {
    i = RSTART + RLENGTH
    tbl = read_ident(t, i)
    if (tbl == "") return
    emit("+", "table", tbl, "")
    rest = substr(t, G_NEXT)
    # only a column list directly after the name — never a paren from `CREATE TABLE x AS SELECT (…)`
    if (rest ~ /^[ ]*\(/) {
      match(rest, /^[ ]*\(/)
      scan_table_body(tbl, paren_body(rest, RLENGTH))
    }
    return
  }
  if (match(U, /^CREATE (UNIQUE )?INDEX (CONCURRENTLY )?(IF NOT EXISTS )?/)) {
    i = RSTART + RLENGTH
    if (substr(U, i) ~ /^ON[ ]/) return   # unnamed index: the server picks the name, no derivable key
    name = read_ident(t, i)
    if (name == "") return
    p = G_NEXT; own = ""
    if (match(toupper(substr(B, p)), /^[ ]*ON (ONLY )?/)) own = read_ident(t, p + RLENGTH)
    emit("+", "index", name, own)
    return
  }
  if (match(U, /^ALTER TABLE /)) { scan_alter_table(t, U); return }
  if (match(U, /^CREATE (OR REPLACE )?TYPE /))                       { name = read_ident(t, RSTART + RLENGTH); emit("+", "type", name, ""); return }
  if (match(U, /^CREATE (OR REPLACE )?(TEMP |TEMPORARY )?VIEW /))     { name = read_ident(t, RSTART + RLENGTH); emit("+", "view", name, ""); return }
  if (match(U, /^CREATE (OR REPLACE )?FUNCTION /))                    { name = read_ident(t, RSTART + RLENGTH); emit("+", "function", name, ""); return }
  if (match(U, /^CREATE (OR REPLACE )?(CONSTRAINT )?TRIGGER /))       { name = read_ident(t, RSTART + RLENGTH); emit("+", "trigger", name, ""); return }
  if (match(U, /^DROP INDEX (CONCURRENTLY )?(IF EXISTS )?/))          { name = read_ident(t, RSTART + RLENGTH); emit("-", "index", name, ""); return }
  if (match(U, /^DROP TYPE (IF EXISTS )?/))                           { name = read_ident(t, RSTART + RLENGTH); emit("-", "type", name, ""); return }
  if (match(U, /^DROP (MATERIALIZED )?VIEW (IF EXISTS )?/))           { name = read_ident(t, RSTART + RLENGTH); emit("-", "view", name, ""); return }
  if (match(U, /^DROP FUNCTION (IF EXISTS )?/))                       { name = read_ident(t, RSTART + RLENGTH); emit("-", "function", name, ""); return }
  if (match(U, /^DROP TRIGGER (IF EXISTS )?/))                        { name = read_ident(t, RSTART + RLENGTH); emit("-", "trigger", name, ""); return }
  if (match(U, /^DROP TABLE (IF EXISTS )?/)) {
    cnt = split_commas(substr(t, RSTART + RLENGTH), ACTS)
    for (k = 1; k <= cnt; k++) {
      name = read_ident(ACTS[k], 1)
      if (name != "") { emit("-", "table", name, ""); emit("!", "cascade", name, "") }
    }
    return
  }
}

function process_file(   cnt, si) {
  if (RAW == "") return
  cnt = split_statements(RAW, STMT)
  for (si = 1; si <= cnt; si++) scan_stmt(STMT[si], 0)
  RAW = ""
}

FNR == 1 {
  if (NR > 1) process_file()
  RAW = ""; MODE = "code"; BDEPTH = 0; DTAG = ""
  NFP = split(FILENAME, FP, "/"); FILEBASE = FP[NFP]
}
{ RAW = RAW strip_line($0) "\n" }
END { process_file() }
AWK

# Alembic/Python scanner. The pre-#95 branch matched exactly `op.create_table` on one line — on a
# 76-file Alembic tree that is table names and nothing else, no columns, no indexes, no
# constraints, and every `op.create_table(` whose args wrap to the next line missed outright.
cat > "$PY_SCANNER_AWK" <<'AWK'
BEGIN { SQ = sprintf("%c", 39); DQ = sprintf("%c", 34); TRIPLE = "" }

function trim(s) { sub(/^[ \t\r\n]+/, "", s); sub(/[ \t\r\n]+$/, "", s); return s }

# Strip `#` comments, quote-aware, with triple-quote state carried across lines: `# ` inside a
# string or a docstring is data, and stripping it would unbalance every quote after it.
function py_strip(l,   n, i, c, c3, out, q) {
  n = length(l); i = 1; out = ""
  while (i <= n) {
    c = substr(l, i, 1); c3 = substr(l, i, 3)
    if (TRIPLE != "") {
      if (c3 == TRIPLE) { out = out c3; TRIPLE = ""; i += 3; continue }
      out = out c; i++; continue
    }
    if (c3 == SQ SQ SQ || c3 == DQ DQ DQ) { TRIPLE = c3; out = out c3; i += 3; continue }
    if (c == "#") return out " "
    if (c == SQ || c == DQ) {
      q = c; out = out c; i++
      while (i <= n) {
        c = substr(l, i, 1)
        if (c == "\\") { out = out substr(l, i, 2); i += 2; continue }
        out = out c; i++
        if (c == q) break
      }
      continue
    }
    out = out c; i++
  }
  return out
}

function skip_atom(s, i,   c, q, n) {
  c = substr(s, i, 1)
  if (c != SQ && c != DQ) return 0
  q = c; n = length(s); i++
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { i += 2; continue }
    i++
    if (c == q) return i
  }
  return n + 1
}

function paren_body(s, i,   n, depth, start, c, j) {
  n = length(s)
  if (substr(s, i, 1) != "(") { G_NEXT = i; return "" }
  depth = 1; i++; start = i
  while (i <= n && depth > 0) {
    j = skip_atom(s, i)
    if (j > 0) { i = j; continue }
    c = substr(s, i, 1)
    if (c == "[") depth++
    else if (c == "]") depth--
    else if (c == "(") depth++
    else if (c == ")") { depth--; if (depth == 0) break }
    i++
  }
  G_NEXT = i + 1
  return substr(s, start, i - start)
}

function split_commas(s, out,   n, i, depth, st, cnt, c, j, k) {
  for (k in out) delete out[k]
  n = length(s); i = 1; depth = 0; st = 1; cnt = 0
  while (i <= n) {
    j = skip_atom(s, i)
    if (j > 0) { i = j; continue }
    c = substr(s, i, 1)
    if (c == "(" || c == "[" || c == "{") depth++
    else if (c == ")" || c == "]" || c == "}") depth--
    else if (c == "," && depth == 0) { cnt++; out[cnt] = substr(s, st, i - st); st = i + 1 }
    i++
  }
  c = substr(s, st, n - st + 1)
  if (c ~ /[^ \t\r\n]/) { cnt++; out[cnt] = c }
  return cnt
}

# strlit: the value of a positional arg that is a string literal, or of `op.f('name')`.
function strlit(a,   s, q, n, i, c, out) {
  s = trim(a)
  if (s ~ /^op\.f[ ]*\(/) { match(s, /^op\.f[ ]*\(/); s = trim(paren_body(s, RLENGTH)) }
  if (s == "") return ""
  q = substr(s, 1, 1)
  if (q != SQ && q != DQ) return ""
  n = length(s); i = 2; out = ""
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { out = out substr(s, i + 1, 1); i += 2; continue }
    if (c == q) break
    out = out c; i++
  }
  return out
}

function emit(sign, type, name, owner) {
  if (name == "") return
  print sign "\t" type ":" name "\t" FILEBASE "\t" owner
}

function handle_op(fn, body,   na, k, tbl, name, col, a) {
  na = split_commas(body, ARGS)
  if (na < 1) return
  if (fn == "create_table") {
    tbl = strlit(ARGS[1]); if (tbl == "") return
    emit("+", "table", tbl, "")
    for (k = 2; k <= na; k++) {
      a = trim(ARGS[k])
      if (a ~ /^sa\.Column[ ]*\(/) {
        match(a, /^sa\.Column[ ]*\(/)
        col = strlit(first_arg(paren_body(a, RLENGTH)))
        if (col != "") emit("+", "column", tbl "." col, tbl)
      }
    }
    return
  }
  if (fn == "add_column") {
    tbl = strlit(ARGS[1]); if (tbl == "" || na < 2) return
    a = trim(ARGS[2])
    if (a ~ /^sa\.Column[ ]*\(/) {
      match(a, /^sa\.Column[ ]*\(/)
      col = strlit(first_arg(paren_body(a, RLENGTH)))
      if (col != "") emit("+", "column", tbl "." col, tbl)
    }
    return
  }
  if (fn == "drop_column") {
    tbl = strlit(ARGS[1]); if (tbl == "" || na < 2) return
    col = strlit(ARGS[2])
    if (col != "") { emit("-", "column", tbl "." col, tbl); emit("-", "check", tbl "." col, tbl) }
    return
  }
  if (fn == "drop_table") {
    tbl = strlit(ARGS[1]); if (tbl == "") return
    emit("-", "table", tbl, ""); emit("!", "cascade", tbl, "")
    return
  }
  if (fn == "create_index") {
    name = strlit(ARGS[1]); tbl = (na >= 2) ? strlit(ARGS[2]) : ""
    emit("+", "index", name, tbl); return
  }
  if (fn == "drop_index") { emit("-", "index", strlit(ARGS[1]), ""); return }
  if (fn == "create_check_constraint" || fn == "create_unique_constraint" ||
      fn == "create_foreign_key" || fn == "create_primary_key") {
    name = strlit(ARGS[1]); tbl = (na >= 2) ? strlit(ARGS[2]) : ""
    emit("+", "constraint", name, tbl); return
  }
  if (fn == "drop_constraint") {
    name = strlit(ARGS[1]); tbl = (na >= 2) ? strlit(ARGS[2]) : ""
    emit("-", "constraint", name, tbl); return
  }
}

function first_arg(body,   n) { n = split_commas(body, FA); return (n >= 1) ? FA[1] : "" }

function process_file(   rest, base, call, fn, popen, adv, body) {
  if (RAW == "") return
  rest = RAW; base = 0
  while (match(rest, /op\.[A-Za-z_]+[ \t]*\(/)) {
    call = substr(rest, RSTART, RLENGTH)
    fn = call; sub(/^op\./, "", fn); sub(/[ \t]*\($/, "", fn)
    popen = base + RSTART + RLENGTH - 1
    body = paren_body(RAW, popen)
    handle_op(fn, body)
    adv = RSTART + RLENGTH - 1
    rest = substr(rest, adv + 1); base += adv
  }
  RAW = ""
}

FNR == 1 {
  if (NR > 1) process_file()
  RAW = ""; TRIPLE = ""
  NFP = split(FILENAME, FP, "/"); FILEBASE = FP[NFP]
}
{ RAW = RAW py_strip($0) " " }
END { process_file() }
AWK

# Reconcile signed rows into a final inventory: LAST state per key wins, in first-seen order.
# `!` cascades a table drop/rename to everything keyed on that table (its columns, its column-level
# CHECKs, and every index/constraint the scanner recorded as owned by it).
cat > "$RECONCILE_AWK" <<'AWK'
BEGIN { FS = "\t"; nord = 0 }
{
  sign = $1; key = $2; src = $3; own = $4
  if (sign == "!") {
    pfx = key; sub(/^cascade:/, "", pfx)
    for (k in state) {
      if (k ~ ("^(column|check):" pfx "\\.")) state[k] = "-"
      else if (owner[k] != "" && owner[k] == pfx) state[k] = "-"
    }
    next
  }
  if (!(key in seen)) { seen[key] = 1; ord[++nord] = key }
  state[key] = sign; source[key] = src; owner[key] = own
}
END { for (i = 1; i <= nord; i++) { k = ord[i]; if (state[k] == "+") print k ":" source[k] } }
AWK

# The file list is materialised first rather than piped straight into xargs: `xargs -r` (skip the
# run when stdin is empty) is a GNU extension, and without it a BSD xargs on an empty migration
# directory invokes `awk -f prog` with no operands. NUL-delimited + `sort -z` so the scanner sees
# files in migration order (the DROP/RENAME reconciliation depends on that order) and a path with a
# space or newline in it cannot split.
FILELIST_FILE=$(mktemp)
SCRATCH_FILES="$SCRATCH_FILES $FILELIST_FILE"
scan_rc=0
: > "$RAW_INVENTORY_FILE"
if [[ "$MIGRATION_TYPE" == "supabase" || "$MIGRATION_TYPE" == "generic-sql" || "$MIGRATION_TYPE" == "prisma" ]]; then
  find "$MIGRATION_DIR" -type f -name "*.sql" -print0 2>/dev/null | sort -z > "$FILELIST_FILE" || scan_rc=$?
  if [[ "$scan_rc" -eq 0 && -s "$FILELIST_FILE" ]]; then
    xargs -0 awk -f "$SQL_SCANNER_AWK" < "$FILELIST_FILE" > "$RAW_INVENTORY_FILE" || scan_rc=$?
  fi
elif [[ "$MIGRATION_TYPE" == "alembic" ]]; then
  find "$MIGRATION_DIR" -type f -name "*.py" -print0 2>/dev/null | sort -z > "$FILELIST_FILE" || scan_rc=$?
  if [[ "$scan_rc" -eq 0 && -s "$FILELIST_FILE" ]]; then
    xargs -0 awk -f "$PY_SCANNER_AWK" < "$FILELIST_FILE" > "$RAW_INVENTORY_FILE" || scan_rc=$?
  fi
fi
if [[ "$scan_rc" -ne 0 ]]; then
  echo -e "${RED}ERROR: the migration scanner failed (awk exit $scan_rc). Refusing to report a
  partial inventory as a complete one — a truncated inventory is exactly the silent-green failure
  #95 exists to close.${NC}" >&2
  emit_gate_telemetry
  exit 2
fi

awk -f "$RECONCILE_AWK" "$RAW_INVENTORY_FILE" > "$INVENTORY_FILE"

OBJECTS_FOUND=$(awk 'END { print NR + 0 }' "$INVENTORY_FILE")
grain_count() { awk -v p="$1" 'index($0, p) == 1 { n++ } END { print n + 0 }' "$INVENTORY_FILE"; }
N_COLUMNS=$(grain_count "column:")
N_CHECKS=$(grain_count "check:")
N_CONSTRAINTS=$(grain_count "constraint:")
N_INDEXES=$(grain_count "index:")
N_OBJECTS=$((OBJECTS_FOUND - N_COLUMNS - N_CHECKS - N_CONSTRAINTS - N_INDEXES))

echo -e "  Found ${GREEN}$OBJECTS_FOUND${NC} database objects across migration files."
echo -e "    grain: ${GREEN}$N_OBJECTS${NC} object(s) · ${GREEN}$N_COLUMNS${NC} column(s) · ${GREEN}$N_CHECKS${NC} column CHECK(s) · ${GREEN}$N_CONSTRAINTS${NC} named constraint(s) · ${GREEN}$N_INDEXES${NC} index(es)"

# mask_db_url — never echo a bare connection string (it may carry a password) into gate output.
mask_db_url() {
  printf '%s' "$1" | sed -E 's#(://[^:/@]+):[^@/]*@#\1:****@#'
}

# report_drift <grain> <name> <source-migration-file>
#
# THIS IS THE PAIRING FOR THE BREAKING CHANGE. Column/constraint/index grain means a project that
# has passed this gate since v7.15 can now report real drift — that is the entire point, but a
# finding is only worth its interruption if the reader can act on it without opening the script.
# Every line below names the TABLE, the COLUMN/CONSTRAINT/INDEX, the MIGRATION FILE that declares
# it, and the concrete next move; the column and check lines also name the runtime symptom, because
# in both Brightstance fires the symptom (a write silently returning 0 rows) was what the team saw
# and the schema was the last place anyone looked.
report_drift() {
  local grain="$1" nm="$2" src="$3" tbl col
  case "$grain" in
    column)
      tbl="${nm%%.*}"; col="${nm#*.}"
      echo -e "${RED}❌ SCHEMA_DRIFT.P0: column \"$tbl.$col\" is declared by migration '$src' but does NOT exist in the live target.${NC}"
      echo -e "${RED}   FIX: apply '$src' to this target (it is pending), or reconcile the migration with the schema the target really has.${NC}"
      echo -e "${RED}   UNTIL THEN: every insert/update that sends \"$col\" is rejected WHOLE (PostgREST PGRST204 / Postgres 42703) and the row is never written.${NC}"
      ;;
    check)
      tbl="${nm%%.*}"; col="${nm#*.}"
      echo -e "${RED}❌ SCHEMA_DRIFT.P0: the CHECK constraint on \"$tbl.$col\" declared by migration '$src' is absent from the live target.${NC}"
      echo -e "${RED}   FIX: apply '$src' to this target, or drop the constraint from the migration if the target is intentionally looser.${NC}"
      echo -e "${RED}   NOTE: existence is not acceptance. A CHECK that EXISTS on both sides can still refuse the exact value your client sends (SQLSTATE 23514) — this leg cannot see that; assert the SQLSTATE of a real constrained write.${NC}"
      ;;
    constraint)
      echo -e "${RED}❌ SCHEMA_DRIFT.P0: constraint '$nm' declared by migration '$src' does NOT exist in the live target.${NC}"
      echo -e "${RED}   FIX: apply '$src' to this target, or remove the constraint from the migration.${NC}"
      ;;
    index)
      echo -e "${RED}❌ SCHEMA_DRIFT.P0: index '$nm' declared by migration '$src' does NOT exist in the live target.${NC}"
      echo -e "${RED}   FIX: apply '$src' to this target. UNTIL THEN any ON CONFLICT clause naming this index's columns has no arbiter and the upsert fails (Postgres 42P10) — the write is lost, not retried.${NC}"
      ;;
    *)
      echo -e "${RED}❌ SCHEMA_DRIFT.P0: Expected database $grain '$nm' (defined in $src) not found in the live target database!${NC}"
      echo -e "${RED}   FIX: apply '$src' to this target, or reconcile the migration with the target's real schema.${NC}"
      ;;
  esac
}

VERDICT="SKIPPED"     # default; overwritten below once we know what actually happened
SKIP_REASON="no --live requested"

# 4. If --live, perform active drift checks against the target DB
if [[ "$LIVE_MODE" == true ]]; then
  echo -e "${BLUE}🔎 Live mode enabled. Querying target database to verify schema parity...${NC}"

  if [[ -z "$LIVE_TARGET" ]]; then
    # #95 finding 1e: the old code fell through to whatever DATABASE_URL happened to be ambient,
    # or whatever project `supabase db query` happened to be linked to — measured once emitting 32
    # confident SCHEMA_DRIFT.P0 lines against an UNRELATED project's database. An explicit target
    # is now REQUIRED for the live leg: no guessing, no ambient DATABASE_URL, no "whatever's
    # linked". Without one this is a configuration gap, not an attempted-and-failed check.
    echo -e "${YELLOW}⚠️  --live given with no --target <DATABASE_URL>. Refusing to guess a connection (#95).${NC}"
    LIVE_MODE=false
    SKIP_REASON="--live given with no --target"
  elif ! command -v psql >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  --target given but 'psql' is not on PATH — cannot connect.${NC}"
    LIVE_MODE=false
    VERDICT="UNPROVEN"
  else
    echo -e "  Target: ${GREEN}$(mask_db_url "$LIVE_TARGET")${NC}"

    # The live projection must speak EXACTLY the inventory's grain keys, or the new column /
    # constraint / index rows would be unmatchable and fire as drift on a correct database.
    # `check:` is projected through pg_constraint.conkey to table.column rather than by constraint
    # NAME: Postgres auto-names an anonymous column CHECK `<table>_<column>_check`, with a numeric
    # suffix on collision, so a name-keyed assertion is a coin flip while the column it constrains
    # is exact.
    introspection_sql="
      SELECT 'table:' || tablename FROM pg_tables WHERE schemaname = 'public'
      UNION ALL
      SELECT 'view:' || viewname FROM pg_views WHERE schemaname = 'public'
      UNION ALL
      SELECT 'type:' || typname FROM pg_type t JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'public'
      UNION ALL
      SELECT 'function:' || proname FROM pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public'
      UNION ALL
      SELECT 'trigger:' || tgname FROM pg_trigger WHERE tgisinternal = false
      UNION ALL
      SELECT 'column:' || c.relname || '.' || a.attname
        FROM pg_attribute a
        JOIN pg_class c ON c.oid = a.attrelid
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
       WHERE n.nspname = 'public' AND a.attnum > 0 AND NOT a.attisdropped
         AND c.relkind IN ('r','p','v','m','f')
      UNION ALL
      SELECT 'index:' || indexname FROM pg_indexes WHERE schemaname = 'public'
      UNION ALL
      SELECT 'constraint:' || con.conname
        FROM pg_constraint con JOIN pg_catalog.pg_namespace n ON n.oid = con.connamespace
       WHERE n.nspname = 'public'
      UNION ALL
      SELECT DISTINCT 'check:' || cl.relname || '.' || a.attname
        FROM pg_constraint con
        JOIN pg_class cl ON cl.oid = con.conrelid
        JOIN pg_catalog.pg_namespace n ON n.oid = cl.relnamespace
        JOIN pg_attribute a ON a.attrelid = cl.oid AND a.attnum = ANY (con.conkey)
       WHERE con.contype = 'c' AND n.nspname = 'public';
    "

    live_objects_file=$(mktemp)
    psql_err_file=$(mktemp)
    SCRATCH_FILES="$SCRATCH_FILES $live_objects_file $psql_err_file"

    live_query_rc=0
    psql "$LIVE_TARGET" -tA -c "$introspection_sql" > "$live_objects_file" 2>"$psql_err_file" || live_query_rc=$?

    if [[ "$live_query_rc" -ne 0 ]]; then
      err_line="$(sp_trim "$(sp_head 1 "$(cat "$psql_err_file" 2>/dev/null)")")"
      echo -e "${YELLOW}⚠️  Could not query the target database (${err_line:-psql exited $live_query_rc}).${NC}"
      LIVE_MODE=false
      VERDICT="UNPROVEN"
    elif [[ ! -s "$live_objects_file" ]]; then
      echo -e "${YELLOW}⚠️  Database introspection returned empty results (verify connection/credentials/schema).${NC}"
      LIVE_MODE=false
      VERDICT="UNPROVEN"
    else
      # #95 finding 1b: normalise the live catalog to one trimmed "type:name" token per line, then
      # compare WHOLE-LINE. The old `grep -qi "$type:$name" "$live_objects_file"` was an
      # unanchored substring match: an expected `table:order` false-PASSED because it is a literal
      # prefix of a real `table:orders` line. Trimming (not truncating) both sides preserves the
      # original comment's intent ("allowing whitespace/schema prefixes" — psql -tA output can
      # carry incidental padding); comparing whole-line after that closes the false-pass without
      # reintroducing it as a false negative.
      norm_live_file=$(mktemp)
      SCRATCH_FILES="$SCRATCH_FILES $norm_live_file"
      while IFS= read -r lline; do
        [[ -z "$lline" ]] && continue
        printf '%s\n' "$(sp_trim "$lline")" >> "$norm_live_file"
      done < "$live_objects_file"

      drift_count=0
      while IFS= read -r expected; do
        [[ -z "$expected" ]] && continue
        IFS=':' read -r type name source <<< "$expected"
        PREDICATES_EVALUATED=$((PREDICATES_EVALUATED + 1))
        if ! sp_match_exact "$type:$name" "$norm_live_file"; then
          report_drift "$type" "$name" "$source"
          drift_count=$((drift_count + 1))
          violations=$((violations + 1))
        fi
      done < "$INVENTORY_FILE"

      VERDICT="VERIFIED"
      GATE_MODE="live"
      if [[ $drift_count -eq 0 ]]; then
        echo -e "${GREEN}✅ Active schema verification passed! Live DB contains all expected database objects.${NC}"
      else
        echo -e "${RED}❌ Active schema verification failed with $drift_count object drift(s).${NC}"
      fi
    fi
  fi
fi

# 5. Non-live / not-actually-verified output (notice-mode guide, or the honest verdict statement)
if [[ "$LIVE_MODE" == false ]]; then
  # VERDICT/SKIP_REASON are already correct here: the live block above set VERDICT=UNPROVEN (and
  # left it alone) on every failure-to-complete path; every other false-LIVE_MODE path (never
  # asked, or asked with no --target) left the SKIPPED default from before section 4 in place,
  # with SKIP_REASON already naming which of the two it was.
  echo -e "\n${BLUE}🧭 Speck G1 Schema Verification (Notice Only Mode):${NC}"
  echo -e "  To prevent live schema-drift, verify the following expected objects exist in your target DB:"
  echo -e "  -------------------------------------------------------------------------------------"
  head -n 25 "$INVENTORY_FILE" | while read -r line; do
    [[ -z "$line" ]] && continue
    IFS=':' read -r type name source <<< "$line"
    echo -e "  - [ ] Expected ${GREEN}$type${NC} ${YELLOW}'$name'${NC} (from $source)"
  done
  if [[ $OBJECTS_FOUND -gt 25 ]]; then
    echo -e "  - ... and $((OBJECTS_FOUND - 25)) more objects."
  fi
  echo -e "  -------------------------------------------------------------------------------------"
  echo -e "  Run with ${GREEN}--live --target <DATABASE_URL>${NC} to run active drift assertions against a real database."
fi

# 6. The three-valued verdict (#95): an UNPROVEN run, or a SKIPPED run the caller explicitly
# demanded proof for (--live with no reachable target), must not read as a pass. A run that never
# asked for a live check (no --live) or found nothing to check (no migration dir) SKIPS honestly —
# that is not a lie, because nobody claimed proof.
case "$VERDICT" in
  VERIFIED)
    if [[ $violations -eq 0 ]]; then
      echo -e "${GREEN}✅ Schema verification: VERIFIED — live catalog checked, $PREDICATES_EVALUATED assertion(s), 0 drift.${NC}"
    fi
    ;;
  UNPROVEN)
    echo -e "${YELLOW}⚠️  Schema verification: UNPROVEN — a live check was requested but did not complete. This is NOT a pass.${NC}"
    ;;
  SKIPPED)
    echo -e "${BLUE}ℹ️  Schema verification: SKIPPED — ${SKIP_REASON}. This is NOT a pass; no live objects were checked.${NC}"
    ;;
esac

if [[ "$STRICT_MODE" == true ]]; then
  if [[ $violations -gt 0 ]]; then
    echo -e "${RED}❌ Validation failed. Found $violations schema drift or migration errors.${NC}"
    emit_gate_telemetry
    exit 1
  fi
  if [[ "$VERDICT" == "UNPROVEN" ]]; then
    echo -e "${RED}❌ Validation failed under --strict: schema parity is UNPROVEN, not verified (#95 — an unproven run must not read as a pass).${NC}"
    emit_gate_telemetry
    exit 1
  fi
  if [[ "$VERDICT" == "SKIPPED" && "$LIVE_REQUESTED" == true ]]; then
    echo -e "${RED}❌ Validation failed under --strict: --live was requested but SKIPPED (${SKIP_REASON}) — refusing to pass silently (#95).${NC}"
    emit_gate_telemetry
    exit 1
  fi
  if [[ $warnings -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Validation warnings found but passed. Run without warnings for complete confidence.${NC}"
  fi
fi

emit_gate_telemetry
exit 0
