#!/usr/bin/env bash
# validate-schema-drift.test.sh — first-ever regression tests for validate-schema-drift.sh (#95).
#
# #64 G1 ("INTEGRATION-GREEN is blind to live schema/migration drift") was filed, closed, and its
# repair shipped as this script in v7.15 — then recurred six weeks later in Brightstance with
# database WRITES DESTROYED, because the shipped probe was structurally unable to fail:
#   (a) the object counter lived inside a `find | while read` subshell, so it was always 0 and the
#       script's own headline read "Found 0 database objects" across 39 real migration files;
#   (b) the live-catalog comparison was an unanchored substring match, so an expected `table:order`
#       false-PASSED against a live catalog holding only `table:orders`;
#   (c) the footgun scan (`git grep -ni "migration repair"`) had no pathspec, so it convicted
#       Speck's own shipped source/templates in every downstream repo;
#   (d) the only path to a non-zero exit ran through a block (`--live`) that silently disabled
#       itself on missing tooling/creds and still printed "✅ Schema verification complete.";
#   (e) the live leg connected to whatever local DB happened to be ambient (DATABASE_URL / a
#       linked supabase project), which once fired 32 confident SCHEMA_DRIFT.P0 lines against an
#       UNRELATED project's database.
# Each test below is red against the pre-#95 script and green after the repair.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
VAL="$ROOT/.speck/scripts/validation/validators/validate-schema-drift.sh"
FAILED=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; echo "----- output (rc=$RC) -----"; echo "$OUT"; echo "----------------------------"; FAILED=1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# run <dir> <flag...>  — cd into <dir> and invoke the validator with target "."  This mirrors real
# usage (`bash validate-schema-drift.sh --strict .` from the project root — the issue's own repro
# command) and matters concretely for test 3: the script's footgun scan runs `git grep` against
# whatever repo the CWD sits in, so an un-cd'd invocation from inside the Speck repo itself would
# scan Speck's own tree instead of the fixture.
run() {
  local d="$1"; shift
  RC=0
  OUT="$(cd "$d" && bash "$VAL" "$@" . 2>&1)" || RC=$?
  # ANSI-stripped copy for assertions that span a color-coded number/word (the script wraps values
  # like the object count in ${GREEN}...${NC}, which would otherwise split e.g. "Found 3 database
  # objects" across escape codes and silently produce false negatives in a plain grep).
  PLAIN="$(printf '%s' "$OUT" | sed -E $'s/\x1b\\[[0-9;]*m//g')"
}

# --- fixtures -----------------------------------------------------------------------------------

mk_supabase_3_objects() { # dir — 3 CREATE TABLE across 2 files (defect a: object counter)
  mkdir -p "$1/supabase/migrations"
  cat > "$1/supabase/migrations/0001_init.sql" <<'SQL'
CREATE TABLE IF NOT EXISTS public.orders (
  id uuid PRIMARY KEY
);
CREATE TABLE public.customers (
  id uuid PRIMARY KEY
);
SQL
  cat > "$1/supabase/migrations/0002_more.sql" <<'SQL'
CREATE TABLE public.widgets (
  id uuid PRIMARY KEY
);
SQL
}

mk_supabase_1_table() { # dir  table_name — a single-table migration dir
  mkdir -p "$1/supabase/migrations"
  cat > "$1/supabase/migrations/0001_init.sql" <<SQL
CREATE TABLE public.$2 (
  id uuid PRIMARY KEY
);
SQL
}

mk_nested_alembic() { # dir — Splang-shape: backend/alembic/versions, one level below a bare
                       # root-anchored check (defect e's "bound the migration-root discovery")
  mkdir -p "$1/backend/alembic/versions"
  cat > "$1/backend/alembic/versions/0001_sessions.py" <<'PY'
def upgrade():
    op.create_table('sessions',
        sa.Column('id', sa.Integer, primary_key=True),
    )
PY
}

mk_fake_psql() { # dir  catalog_file — a stub `psql` on PATH that ignores its real args (target,
                  # -tA, -c, the introspection SQL) and just cats a canned catalog. Good enough:
                  # the validator's OWN comparison logic is what these tests are exercising, not
                  # a real Postgres round-trip.
  mkdir -p "$1/bin"
  cat > "$1/bin/psql" <<EOF
#!/usr/bin/env bash
cat "$2"
EOF
  chmod +x "$1/bin/psql"
}

mk_fake_psql_fail() { # dir — a stub `psql` that always exits non-zero (a real connection failure:
                       # bad host, auth rejected, network unreachable). Exercises the live_query_rc
                       # != 0 branch, distinct from mk_fake_psql's success stub.
  mkdir -p "$1/bin"
  cat > "$1/bin/psql" <<'EOF'
#!/usr/bin/env bash
echo "psql: error: connection to server failed" >&2
exit 1
EOF
  chmod +x "$1/bin/psql"
}

mk_fake_psql_empty() { # dir — a stub `psql` that exits 0 but prints nothing (introspection
                        # returned zero rows: wrong schema, empty database, disconnected catalog).
  mkdir -p "$1/bin"
  cat > "$1/bin/psql" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$1/bin/psql"
}

mk_git_repair_footgun() { # dir — "migration repair" ONLY inside .speck/, nowhere else
  mkdir -p "$1"
  git -C "$1" init -q
  git -C "$1" config user.email t@t.example
  git -C "$1" config user.name test
  mkdir -p "$1/.speck/templates"
  mk_supabase_1_table "$1" orders
  echo "CRITICAL WARNING: never run 'migration repair' against production" > "$1/.speck/templates/evidence-contract-template.md"
  git -C "$1" add -A
  git -C "$1" commit -q -m init
}

# --- tests ---------------------------------------------------------------------------------------

# 1. defect (a): the object counter must not always read 0. `find | sort | while read` runs the
#    increment in a PIPELINE SUBSHELL — the parent's OBJECTS_FOUND never moves.
d="$T/t1"; mk_supabase_3_objects "$d"
run "$d"
echo "$PLAIN" | grep -q "Found 3 database objects" \
  && pass "defect a: object counter (SQL branch) counts 3, not 0" \
  || fail "defect a: expected 'Found 3 database objects across migration files.'"

# 2. defect (a), alembic branch: same subshell bug, second parser.
d="$T/t2"; mkdir -p "$d/alembic/versions"
cat > "$d/alembic/versions/0001_x.py" <<'PY'
def upgrade():
    op.create_table('accounts',
        sa.Column('id', sa.Integer, primary_key=True),
    )
PY
run "$d"
echo "$PLAIN" | grep -q "Found 1 database objects" \
  && pass "defect a: object counter (alembic branch) counts 1, not 0" \
  || fail "defect a: alembic branch counter should be 1"

# 3. defect (c): footgun scan must exclude .speck — Speck's own shipped warning text says
#    "migration repair" so an unscoped `git grep` convicts Speck's own source in every downstream
#    repo (measured: 7 false P1s on Brightstance). Fixture puts the phrase ONLY inside .speck/.
d="$T/t3"; mk_git_repair_footgun "$d"
run "$d"
echo "$OUT" | grep -q "MIGRATION_REPAIR_WARNING" \
  && fail "defect c: .speck should be excluded from the footgun scan (got a false MIGRATION_REPAIR_WARNING)" \
  || pass "defect c: .speck excluded from footgun scan, no false MIGRATION_REPAIR_WARNING"

# 4. defect (d)/(b): the exit contract must not be self-disabling. `--live --strict` with no way
#    to reach a database (no --target, and neither `supabase` nor `psql` reachable — PATH is
#    scrubbed to make this deterministic regardless of what's installed on the dev box running
#    the test) must NOT exit 0 — that silent pass is exactly how both Brightstance
#    write-destroying fires shipped.
d="$T/t4"; mk_supabase_1_table "$d" orders
PATH="/usr/bin:/bin" run "$d" --live --strict
{ [[ "$RC" != 0 ]]; } \
  && pass "defect d: --live --strict with no reachable DB is non-zero (not a silent pass)" \
  || fail "defect d: --live --strict with no DB access must not exit 0"

# 5. defect (d): the same run must not claim "Schema verification complete" — an unproven run must
#    not read as a pass, in the OUTPUT text as much as the exit code.
d="$T/t5"; mk_supabase_1_table "$d" orders
run "$d" --live
echo "$OUT" | grep -q "Schema verification complete\." \
  && fail "defect d: an unproven/skipped run must not print the bare pass message" \
  || pass "defect d: unproven/skipped run does not claim 'Schema verification complete.'"

# 6. defect (e): the live leg must take an EXPLICIT target rather than connecting to whatever is
#    ambient (DATABASE_URL, a linked supabase project) — that ambient connection once fired 32
#    confident SCHEMA_DRIFT.P0 lines against an unrelated project's database.
d="$T/t6"; mk_supabase_1_table "$d" orders
mk_fake_psql "$T/t6env" "$T/t6env/catalog.txt"
printf 'table:orders\n' > "$T/t6env/catalog.txt"
PATH="$T/t6env/bin:$PATH" run "$d" --live --strict --target "postgres://fake/db"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -qi "VERIFIED"; } \
  && pass "defect e: an explicit --target reaches a real (VERIFIED) live check" \
  || fail "defect e: --target should let the live leg run and report VERIFIED (rc=$RC)"

# 7. defect (b): the live comparison must be an EXACT type:name match, not a substring. A catalog
#    holding only `table:orders` must NOT satisfy an expectation of `table:order` — the old
#    `grep -qi "$type:$name"` treated the shorter expected name as a substring of the longer real
#    one and false-PASSED.
d="$T/t7"; mk_supabase_1_table "$d" order
mk_fake_psql "$T/t7env" "$T/t7env/catalog.txt"
printf 'table:orders\n' > "$T/t7env/catalog.txt"
PATH="$T/t7env/bin:$PATH" run "$d" --live --strict --target "postgres://fake/db"
{ [[ "$RC" != 0 ]] && echo "$OUT" | grep -q "SCHEMA_DRIFT.P0" && echo "$OUT" | grep -q "'order'"; } \
  && pass "defect b: 'order' vs live-only 'orders' is caught as drift, not a substring false-pass" \
  || fail "defect b: expected SCHEMA_DRIFT.P0 for 'order' (catalog only has 'orders')"

# 8. defect (b), positive control: an EXACT match must still pass (the anchoring fix must not
#    become a false NEGATIVE for real matches, e.g. whitespace around a catalog line).
d="$T/t8"; mk_supabase_1_table "$d" orders
mk_fake_psql "$T/t8env" "$T/t8env/catalog.txt"
printf '  table:orders  \n' > "$T/t8env/catalog.txt"
PATH="$T/t8env/bin:$PATH" run "$d" --live --strict --target "postgres://fake/db"
{ [[ "$RC" == 0 ]] && ! echo "$OUT" | grep -q "SCHEMA_DRIFT.P0"; } \
  && pass "defect b positive control: exact (whitespace-padded) match still passes" \
  || fail "defect b positive control: 'orders' vs 'orders' (padded) should not drift (rc=$RC)"

# 9. "bound the migration-root discovery": a migration directory one level below the four
#    root-anchored paths (Splang: backend/alembic/versions, 76 real files) must be found, not
#    silently skipped as "no migration directories found".
d="$T/t9"; mk_nested_alembic "$d"
run "$d"
echo "$PLAIN" | grep -q "Found 1 database objects" \
  && pass "bounded discovery: backend/alembic/versions (one level deep) is found" \
  || fail "bounded discovery: nested alembic dir should be discovered, not skipped"

# 10. vacuity telemetry: every exit path names its scope/subject/predicate counts so a caller can
#     tell a real green from a vacuous one without parsing prose.
d="$T/t10"; mk_supabase_3_objects "$d"
run "$d"
{ echo "$OUT" | grep -q "^SPECK_GATE_SCOPE=" && echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=3$" && echo "$OUT" | grep -q "^SPECK_GATE_PREDICATES="; } \
  && pass "vacuity telemetry: SPECK_GATE_SCOPE/SUBJECT/PREDICATES emitted" \
  || fail "vacuity telemetry: expected SPECK_GATE_SCOPE/SUBJECT/PREDICATES lines"

# 11. backward compatibility: a plain default invocation (no --live, no --strict, nothing to
#     check against live) still exits 0 — nobody asked for proof, so SKIPPED is honest, not a
#     failure. This must keep working for the very common non-live notice-mode callers.
d="$T/t11"; mk_supabase_3_objects "$d"
run "$d"
{ [[ "$RC" == 0 ]]; } \
  && pass "backward-compat: plain notice-mode invocation still exits 0" \
  || fail "backward-compat: default invocation should not start failing (rc=$RC)"

# 12. P2-1 (adversarial review, #95 follow-up): the UNPROVEN verdict is the CORE of the exit
#     contract, but until now nothing reached `if [[ "$VERDICT" == "UNPROVEN" ]]` at the
#     --strict exit gate — test 4 above passes --live --strict with NO --target, which takes the
#     SKIPPED+LIVE_REQUESTED branch instead, a DIFFERENT code path. Replacing that UNPROVEN check
#     with `if false` left all 11 original tests green. This test forces the live leg to actually
#     run (via --target and a stub `psql` on PATH) and then fail to connect, landing on
#     `live_query_rc -ne 0` → VERDICT=UNPROVEN → the --strict UNPROVEN gate.
d="$T/t12"; mk_supabase_1_table "$d" orders
mk_fake_psql_fail "$T/t12env"
PATH="$T/t12env/bin:$PATH" run "$d" --live --strict --target "postgres://fake/db"
{ [[ "$RC" != 0 ]] && echo "$OUT" | grep -q "UNPROVEN"; } \
  && pass "P2-1: psql connection failure (--target given, psql exits non-zero) is UNPROVEN, non-zero under --strict" \
  || fail "P2-1: expected UNPROVEN + non-zero exit for a failed psql connection (rc=$RC)"

# 13. P2-1, second UNPROVEN entry point: psql exits 0 but the introspection query returns zero
#     rows (empty catalog) — a DIFFERENT branch (`! -s "$live_objects_file"`) from test 12's
#     nonzero-exit branch, both of which must reach the same UNPROVEN verdict and --strict gate.
d="$T/t13"; mk_supabase_1_table "$d" orders
mk_fake_psql_empty "$T/t13env"
PATH="$T/t13env/bin:$PATH" run "$d" --live --strict --target "postgres://fake/db"
{ [[ "$RC" != 0 ]] && echo "$OUT" | grep -q "UNPROVEN"; } \
  && pass "P2-1: psql exits 0 with empty introspection is UNPROVEN, non-zero under --strict" \
  || fail "P2-1: expected UNPROVEN + non-zero exit for an empty introspection result (rc=$RC)"

# 14. P2-2 (adversarial review, #95 follow-up): telemetry must fire on invocation-error exits too,
#     not just the ones reached after the migration-dir scan. `--bogus` exits 2 from INSIDE the
#     arg-parse loop, which used to run before emit_gate_telemetry was even defined — verified, no
#     SPECK_GATE_* line printed. The trap installed above the parse loop must cover this.
d="$T/t14"; mk_supabase_1_table "$d" orders
run "$d" --bogus
{ [[ "$RC" == 2 ]] && echo "$OUT" | grep -q "^SPECK_GATE_SCOPE=" && echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=" && echo "$OUT" | grep -q "^SPECK_GATE_PREDICATES="; } \
  && pass "P2-2: an unknown flag (--bogus, exit 2) still emits SPECK_GATE_* telemetry" \
  || fail "P2-2: expected SPECK_GATE_SCOPE/SUBJECT/PREDICATES on the --bogus invocation-error exit (rc=$RC)"

# 15. P2-2, second invocation-error entry point: `--target` with no following value also exits 2
#     from inside the same arg-parse loop, before the old (post-loop) telemetry definition. Called
#     directly (not via `run`) because `run` always appends a trailing "." positional arg, which
#     would silently BECOME --target's value and mask the very case this test exists to cover.
d="$T/t15"; mk_supabase_1_table "$d" orders
RC=0
OUT="$(cd "$d" && bash "$VAL" --target 2>&1)" || RC=$?
{ [[ "$RC" == 2 ]] && echo "$OUT" | grep -q "^SPECK_GATE_SCOPE=" && echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=" && echo "$OUT" | grep -q "^SPECK_GATE_PREDICATES="; } \
  && pass "P2-2: --target with no value (exit 2) still emits SPECK_GATE_* telemetry" \
  || fail "P2-2: expected SPECK_GATE_SCOPE/SUBJECT/PREDICATES on the --target-with-no-value exit (rc=$RC)"

if [[ "$FAILED" == 0 ]]; then echo "✅ validate-schema-drift: all tests passed"; else echo "❌ validate-schema-drift: FAILURES"; exit 1; fi
