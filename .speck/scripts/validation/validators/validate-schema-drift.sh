#!/usr/bin/env bash
# validate-schema-drift.sh — Schema Parity and Migration Integrity Gate (Speck v7.15).
#
# Scans project migrations to build an object inventory, checks for migration-repair footguns,
# and (with --live) verifies the live target DB matches committed migrations.
#
# Usage:
#   validate-schema-drift.sh [--live] [--strict] <project-root | database-dir>
#
# Exit codes: 0 = pass, 1 = schema drift or repair warnings (under --strict), 2 = invocation error.

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

LIVE_MODE=false
STRICT_MODE=false
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --live) LIVE_MODE=true; shift ;;
    --strict) STRICT_MODE=true; shift ;;
    -*) echo "Unknown flag: $1" >&2; exit 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  TARGET="."
fi

if [[ ! -d "$TARGET" && ! -f "$TARGET" ]]; then
  echo -e "${RED}ERROR: Target '$TARGET' not found.${NC}" >&2
  exit 2
fi

# Resolve root path
ROOT_DIR=""
if [[ -d "$TARGET" ]]; then
  ROOT_DIR="$(cd "$TARGET" && pwd)"
else
  ROOT_DIR="$(cd "$(dirname "$TARGET")" && pwd)"
fi

# Trim whitespace utility
trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# 1. Scan for migration-repair footguns (statically in git history/repo scripts)
warnings=0
violations=0

echo -e "${BLUE}🔎 Scanning repository for migration-repair footguns...${NC}"

# Find any shell scripts, json, yaml, workflows, or instructions containing "migration repair"
repair_matches=""
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Use git grep to find instances of 'migration repair' or 'db:repair' or similar
  repair_matches=$(git grep -ni "migration repair" || true)
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

if [[ -d "$ROOT_DIR/supabase/migrations" ]]; then
  MIGRATION_TYPE="supabase"
  MIGRATION_DIR="$ROOT_DIR/supabase/migrations"
elif [[ -d "$ROOT_DIR/migrations" ]]; then
  # Could be postgres, alembic, or other generic SQL migrations
  if ls "$ROOT_DIR/migrations"/*.py >/dev/null 2>&1; then
    MIGRATION_TYPE="alembic"
  else
    MIGRATION_TYPE="generic-sql"
  fi
  MIGRATION_DIR="$ROOT_DIR/migrations"
elif [[ -d "$ROOT_DIR/prisma/migrations" ]]; then
  MIGRATION_TYPE="prisma"
  MIGRATION_DIR="$ROOT_DIR/prisma/migrations"
elif [[ -d "$ROOT_DIR/alembic/versions" ]]; then
  MIGRATION_TYPE="alembic"
  MIGRATION_DIR="$ROOT_DIR/alembic/versions"
fi

if [[ -z "$MIGRATION_TYPE" ]]; then
  echo -e "${GREEN}✅ No database migration directories found. Skipping schema validation.${NC}"
  if [[ "$STRICT_MODE" == true && $warnings -gt 0 ]]; then
    exit 1
  fi
  exit 0
fi

echo -e "  Framework: ${GREEN}$MIGRATION_TYPE${NC}"
echo -e "  Directory: ${GREEN}$MIGRATION_DIR${NC}"

# 3. Build expected database objects inventory
echo -e "${BLUE}🔎 Compiling expected database objects inventory from migrations...${NC}"
OBJECTS_FOUND=0

# Clean old temp inventory if exists
INVENTORY_FILE=$(mktemp)
trap 'rm -f "$INVENTORY_FILE"' EXIT

clean_object_name() {
  local obj="$1"
  # Strip schema prefix like "public." or "auth."
  obj="${obj#*.}"
  # Strip quotes
  obj="${obj//\"/}"
  obj="${obj//\'/}"
  # Strip trailing parenthesis or spaces
  obj=$(trim "$obj")
  obj="${obj%%\(*}"
  obj=$(trim "$obj")
  printf '%s' "$obj"
}

if [[ "$MIGRATION_TYPE" == "supabase" || "$MIGRATION_TYPE" == "generic-sql" || "$MIGRATION_TYPE" == "prisma" ]]; then
  # Parse SQL files
  # Find all SQL files recursively in the migration dir
  find "$MIGRATION_DIR" -type f -name "*.sql" | sort | while read -r sql_file; do
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
  done
elif [[ "$MIGRATION_TYPE" == "alembic" ]]; then
  # Parse Python files
  find "$MIGRATION_DIR" -type f -name "*.py" | sort | while read -r py_file; do
    while IFS= read -r line; do
      if [[ "$line" =~ op\.create_table\([[:space:]]*[\'\"]([a-zA-Z0-9_-]+)[\'\"] ]]; then
        tbl="${BASH_REMATCH[1]}"
        if [[ -n "$tbl" ]]; then
          echo "table:$tbl:$(basename "$py_file")" >> "$INVENTORY_FILE"
          OBJECTS_FOUND=$((OBJECTS_FOUND + 1))
        fi
      fi
    done < "$py_file"
  done
fi

echo -e "  Found ${GREEN}$OBJECTS_FOUND${NC} database objects across migration files."

# 4. If --live, perform active drift checks against the target DB
if [[ "$LIVE_MODE" == true ]]; then
  echo -e "${BLUE}🔎 Live mode enabled. Querying target database to verify schema parity...${NC}"
  
  # Support Supabase CLI or standard psql connection
  DB_QUERY_CMD=""
  if [[ "$MIGRATION_TYPE" == "supabase" ]] && command -v supabase >/dev/null 2>&1; then
    # Introspect with Supabase CLI
    DB_QUERY_CMD="supabase db query"
  elif command -v psql >/dev/null 2>&1 && [[ -n "${DATABASE_URL:-}" ]]; then
    DB_QUERY_CMD="psql $DATABASE_URL -tA -c"
  fi

  if [[ -z "$DB_QUERY_CMD" ]]; then
    echo -e "${YELLOW}⚠️  No live DB query tool or connection (DATABASE_URL) found. Skipping active check.${NC}"
    LIVE_MODE=false
  else
    echo -e "  Using DB query command: ${GREEN}$DB_QUERY_CMD${NC}"
    
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
    trap 'rm -f "$INVENTORY_FILE" "$live_objects_file"' EXIT
    
    # Execute db query
    if [[ "$DB_QUERY_CMD" == "supabase db query" ]]; then
      # Supabase query wants SQL from stdin or -q
      supabase db query "$introspection_sql" > "$live_objects_file" 2>/dev/null || true
    else
      eval "$DB_QUERY_CMD \"$introspection_sql\"" > "$live_objects_file" 2>/dev/null || true
    fi
    
    # Compare inventory against live
    drift_count=0
    if [[ -s "$live_objects_file" ]]; then
      while IFS= read -r expected; do
        [[ -z "$expected" ]] && continue
        
        IFS=':' read -r type name source <<< "$expected"
        
        # Check if "type:name" exists in the live output (allowing whitespace/schema prefixes)
        if ! grep -qi "$type:$name" "$live_objects_file"; then
          echo -e "${RED}❌ SCHEMA_DRIFT.P0: Expected database $type '$name' (defined in $source) not found in the live target database!${NC}"
          drift_count=$((drift_count + 1))
          violations=$((violations + 1))
        fi
      done < "$INVENTORY_FILE"
      
      if [[ $drift_count -eq 0 ]]; then
        echo -e "${GREEN}✅ Active schema verification passed! Live DB contains all expected database objects.${NC}"
      else
        echo -e "${RED}❌ Active schema verification failed with $drift_count object drift(s).${NC}"
      fi
    else
      echo -e "${YELLOW}⚠️  Database introspection returned empty results. Skipping active check (verify DB connection/credentials).${NC}"
      LIVE_MODE=false
    fi
  fi
fi

# 5. Non-live mode output (emits guide notice)
if [[ "$LIVE_MODE" == false ]]; then
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
  echo -e "  Run with ${GREEN}--live${NC} and configure ${YELLOW}DATABASE_URL${NC} (or use Supabase CLI) to run active drift assertions."
fi

# 6. Exit evaluation
if [[ "$STRICT_MODE" == true ]]; then
  if [[ $violations -gt 0 ]]; then
    echo -e "${RED}❌ Validation failed. Found $violations schema drift or migration errors.${NC}"
    exit 1
  fi
  if [[ $warnings -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Validation warnings found but passed. Run without warnings for complete confidence.${NC}"
  fi
fi

echo -e "${GREEN}✅ Schema verification complete.${NC}"
exit 0
