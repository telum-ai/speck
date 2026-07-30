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
# The repair below is mechanical, not a grain extension: column/constraint-level inventory (ALTER
# TABLE ... ADD COLUMN, CHECK constraints, CREATE INDEX) is explicitly OUT of scope here — see #95
# for why landing it before (b)'s anchored matching would RAISE the false-pass rate.
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
# contract as Speck's other gates).
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
TELEMETRY_EMITTED=false
emit_gate_telemetry() {
  [[ "$TELEMETRY_EMITTED" == true ]] && return 0
  TELEMETRY_EMITTED=true
  echo "SPECK_GATE_SCOPE=$GATE_SCOPE"
  echo "SPECK_GATE_SUBJECT=$OBJECTS_FOUND"
  echo "SPECK_GATE_PREDICATES=$PREDICATES_EVALUATED"
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

clean_object_name() {
  local obj="$1"
  # Strip schema prefix like "public." or "auth."
  obj="${obj#*.}"
  # Strip quotes
  obj="${obj//\"/}"
  obj="${obj//\'/}"
  # Strip trailing parenthesis or spaces
  obj=$(sp_trim "$obj")
  obj="${obj%%\(*}"
  obj=$(sp_trim "$obj")
  printf '%s' "$obj"
}

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

# 3. Build expected database objects inventory
echo -e "${BLUE}🔎 Compiling expected database objects inventory from migrations...${NC}"
OBJECTS_FOUND=0

# Clean old temp inventory if exists
INVENTORY_FILE=$(mktemp)
trap 'rm -f "$INVENTORY_FILE"' EXIT

# #95 finding 1a: `find … | sort | while read` runs the loop body in a PIPELINE SUBSHELL, so
# increments to OBJECTS_FOUND inside it never reach this (the parent) shell — the script's own
# headline read "Found 0 database objects" across 39 real migration files, and the >25-row
# truncation notice below was provably unreachable. Process-substituting the `find` output
# (`done < <(...)`) keeps the while loop in THIS shell instead.
if [[ "$MIGRATION_TYPE" == "supabase" || "$MIGRATION_TYPE" == "generic-sql" || "$MIGRATION_TYPE" == "prisma" ]]; then
  # Parse SQL files
  while IFS= read -r sql_file; do
    while IFS= read -r line; do
      # Match table creations
      if [[ "$line" =~ [Cc][Rr][Ee][Aa][Tt][Ee][[:space:]]+[Tt][Aa][Bb][Ll][Ee][[:space:]]+([Ii][Ff][[:space:]]+[Nn][Oo][Tt][[:space:]]+[Ee][Xx][Ii][Ss][Tt][Ss][[:space:]]+)?([a-zA-Z0-9_\.\"\']+) ]]; then
        tbl="${BASH_REMATCH[2]}"
        tbl=$(clean_object_name "$tbl")
        if [[ -n "$tbl" ]]; then
          echo "table:$tbl:$(basename "$sql_file")" >> "$INVENTORY_FILE"
          OBJECTS_FOUND=$((OBJECTS_FOUND + 1))
        fi
      fi
      # Match custom types (enums, composites)
      if [[ "$line" =~ [Cc][Rr][Ee][Aa][Tt][Ee][[:space:]]+[Tt][Yy][Pp][Ee][[:space:]]+([a-zA-Z0-9_\.\"\']+) ]]; then
        tp="${BASH_REMATCH[1]}"
        tp=$(clean_object_name "$tp")
        if [[ -n "$tp" ]]; then
          echo "type:$tp:$(basename "$sql_file")" >> "$INVENTORY_FILE"
          OBJECTS_FOUND=$((OBJECTS_FOUND + 1))
        fi
      fi
      # Match views
      if [[ "$line" =~ [Cc][Rr][Ee][Aa][Tt][Ee][[:space:]]+([Oo][Rr][[:space:]]+[Rr][Ee][Pp][Ll][Aa][Cc][Ee][[:space:]]+)?[Vv][Ii][Ee][Ww][[:space:]]+([a-zA-Z0-9_\.\"\']+) ]]; then
        vw="${BASH_REMATCH[2]}"
        vw=$(clean_object_name "$vw")
        if [[ -n "$vw" ]]; then
          echo "view:$vw:$(basename "$sql_file")" >> "$INVENTORY_FILE"
          OBJECTS_FOUND=$((OBJECTS_FOUND + 1))
        fi
      fi
      # Match functions
      if [[ "$line" =~ [Cc][Rr][Ee][Aa][Tt][Ee][[:space:]]+([Oo][Rr][[:space:]]+[Rr][Ee][Pp][Ll][Aa][Cc][Ee][[:space:]]+)?[Ff][Uu][Nn][Cc][Tt][Ii][Oo][Nn][[:space:]]+([a-zA-Z0-9_\.\"\']+) ]]; then
        fn="${BASH_REMATCH[2]}"
        fn=$(clean_object_name "$fn")
        if [[ -n "$fn" ]]; then
          echo "function:$fn:$(basename "$sql_file")" >> "$INVENTORY_FILE"
          OBJECTS_FOUND=$((OBJECTS_FOUND + 1))
        fi
      fi
      # Match triggers
      if [[ "$line" =~ [Cc][Rr][Ee][Aa][Tt][Ee][[:space:]]+[Tt][Rr][Ii][Gg][Gg][Ee][Rr][[:space:]]+([a-zA-Z0-9_\.\"\']+) ]]; then
        trg="${BASH_REMATCH[1]}"
        trg=$(clean_object_name "$trg")
        if [[ -n "$trg" ]]; then
          echo "trigger:$trg:$(basename "$sql_file")" >> "$INVENTORY_FILE"
          OBJECTS_FOUND=$((OBJECTS_FOUND + 1))
        fi
      fi
    done < "$sql_file"
  done < <(find "$MIGRATION_DIR" -type f -name "*.sql" | sort)
elif [[ "$MIGRATION_TYPE" == "alembic" ]]; then
  # Parse Python files
  while IFS= read -r py_file; do
    while IFS= read -r line; do
      if [[ "$line" =~ op\.create_table\([[:space:]]*[\'\"]([a-zA-Z0-9_-]+)[\'\"] ]]; then
        tbl="${BASH_REMATCH[1]}"
        if [[ -n "$tbl" ]]; then
          echo "table:$tbl:$(basename "$py_file")" >> "$INVENTORY_FILE"
          OBJECTS_FOUND=$((OBJECTS_FOUND + 1))
        fi
      fi
    done < "$py_file"
  done < <(find "$MIGRATION_DIR" -type f -name "*.py" | sort)
fi

echo -e "  Found ${GREEN}$OBJECTS_FOUND${NC} database objects across migration files."

# mask_db_url — never echo a bare connection string (it may carry a password) into gate output.
mask_db_url() {
  printf '%s' "$1" | sed -E 's#(://[^:/@]+):[^@/]*@#\1:****@#'
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

    # We will do a live query to check existence of tables/types/views/etc.
    # To avoid complex cross-platform setups, we can pull all public tables and views.
    # Let's run a query to get all public tables, views, triggers, functions, and custom types.
    introspection_sql="
      SELECT 'table:' || tablename FROM pg_tables WHERE schemaname = 'public'
      UNION ALL
      SELECT 'view:' || viewname FROM pg_views WHERE schemaname = 'public'
      UNION ALL
      SELECT 'type:' || typname FROM pg_type t JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace WHERE n.nspname = 'public'
      UNION ALL
      SELECT 'function:' || proname FROM pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace WHERE n.nspname = 'public'
      UNION ALL
      SELECT 'trigger:' || tgname FROM pg_trigger WHERE tgisinternal = false;
    "

    live_objects_file=$(mktemp)
    psql_err_file=$(mktemp)
    trap 'rm -f "$INVENTORY_FILE" "$live_objects_file" "$psql_err_file"' EXIT

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
      trap 'rm -f "$INVENTORY_FILE" "$live_objects_file" "$psql_err_file" "$norm_live_file"' EXIT
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
          echo -e "${RED}❌ SCHEMA_DRIFT.P0: Expected database $type '$name' (defined in $source) not found in the live target database!${NC}"
          drift_count=$((drift_count + 1))
          violations=$((violations + 1))
        fi
      done < "$INVENTORY_FILE"

      VERDICT="VERIFIED"
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
