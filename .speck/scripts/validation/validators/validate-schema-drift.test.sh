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
# 3 CREATE TABLEs + their 3 `id` columns. The count is 6, not 3, since Tranche B: columns are
# inventory entries now. Both halves are asserted so the number cannot drift silently.
{ echo "$PLAIN" | grep -q "Found 6 database objects" \
  && echo "$PLAIN" | grep -q "Expected table 'orders'" \
  && echo "$PLAIN" | grep -q "Expected column 'orders.id'"; } \
  && pass "defect a: object counter (SQL branch) counts 6, not 0" \
  || fail "defect a: expected 'Found 6 database objects' + table AND column entries"

# 2. defect (a), alembic branch: same subshell bug, second parser.
d="$T/t2"; mkdir -p "$d/alembic/versions"
cat > "$d/alembic/versions/0001_x.py" <<'PY'
def upgrade():
    op.create_table('accounts',
        sa.Column('id', sa.Integer, primary_key=True),
    )
PY
run "$d"
# table:accounts + column:accounts.id — the Alembic branch reads sa.Column() children since
# Tranche B, where it used to see only the op.create_table name.
{ echo "$PLAIN" | grep -q "Found 2 database objects" && echo "$PLAIN" | grep -q "Expected column 'accounts.id'"; } \
  && pass "defect a: object counter (alembic branch) counts 2, not 0" \
  || fail "defect a: alembic branch counter should be 2 (table + column)"

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
# The stub catalog must carry the COLUMN too: since Tranche B a real catalog that has `orders`
# but not `orders.id` is a catalog that genuinely drifted, and asserting it passes would be
# asserting the bug.
printf 'table:orders\ncolumn:orders.id\n' > "$T/t6env/catalog.txt"
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
printf '  table:orders  \n  column:orders.id  \n' > "$T/t8env/catalog.txt"
PATH="$T/t8env/bin:$PATH" run "$d" --live --strict --target "postgres://fake/db"
{ [[ "$RC" == 0 ]] && ! echo "$OUT" | grep -q "SCHEMA_DRIFT.P0"; } \
  && pass "defect b positive control: exact (whitespace-padded) match still passes" \
  || fail "defect b positive control: 'orders' vs 'orders' (padded) should not drift (rc=$RC)"

# 9. "bound the migration-root discovery": a migration directory one level below the four
#    root-anchored paths (Splang: backend/alembic/versions, 76 real files) must be found, not
#    silently skipped as "no migration directories found".
d="$T/t9"; mk_nested_alembic "$d"
run "$d"
echo "$PLAIN" | grep -q "Found 2 database objects" \
  && pass "bounded discovery: backend/alembic/versions (one level deep) is found" \
  || fail "bounded discovery: nested alembic dir should be discovered, not skipped"

# 10. vacuity telemetry: every exit path names its scope/subject/predicate counts so a caller can
#     tell a real green from a vacuous one without parsing prose.
d="$T/t10"; mk_supabase_3_objects "$d"
run "$d"
{ echo "$OUT" | grep -q "^SPECK_GATE_SCOPE=" && echo "$OUT" | grep -q "^SPECK_GATE_SUBJECT=6$" && echo "$OUT" | grep -q "^SPECK_GATE_PREDICATES="; } \
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

# =================================================================================================
# #95 TRANCHE B — column/constraint grain, statement-level scanner.
#
# THE SCAR THIS SUITE GUARDS. #64 G1's repair shipped as this script in v7.15 and the class recurred
# six weeks later with database WRITES DESTROYED — a person completed an entire exercise and the
# table was never written, twice over, on two independent paths, on every deployment the project
# has. The probe was OBJECT grain (tables/types/views/functions/triggers) while both destroyed
# writes diverged at COLUMN and CONSTRAINT grain. The column that destroyed every write was
# `coaching_sessions.draft_id`, added by `ALTER TABLE ... ADD COLUMN` and arbitrated by a
# `CREATE UNIQUE INDEX` — two statement forms the five line-regexes could not see, in a file the
# line matcher also could not read correctly (multi-line statements, DO $$ blocks, comments).
# Every fixture below is written in the shape the real fires had.
# =================================================================================================

mk_brightstance_shape() { # dir — the two real Brightstance migrations, reduced
  mkdir -p "$1/supabase/migrations"
  cat > "$1/supabase/migrations/20251201132040_create_initial_schema.sql" <<'SQL'
-- initial schema; this comment contains a ; and a decoy CREATE TABLE phantom_from_a_comment (
/* and so does this
   block comment: CREATE TABLE phantom_from_a_block (x int);
*/
CREATE TABLE public.coaching_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  energization integer NOT NULL CHECK (energization >= 1 AND energization <= 10),
  note text DEFAULT 'a literal holding a ; and the word CHECK (and an open paren',
  CONSTRAINT coaching_sessions_note_len CHECK (char_length(note) < 500)
);
SQL
  cat > "$1/supabase/migrations/20260727090400_session_idempotency_key.sql" <<'SQL'
ALTER TABLE public.coaching_sessions
  ADD COLUMN IF NOT EXISTS draft_id uuid;
CREATE UNIQUE INDEX IF NOT EXISTS coaching_sessions_user_draft_uniq
  ON public.coaching_sessions (user_id, draft_id);
DO $$
BEGIN
  ALTER TABLE public.coaching_sessions ADD COLUMN notification_enabled boolean DEFAULT false;
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;
ALTER TABLE public.coaching_sessions ADD CONSTRAINT coaching_sessions_draft_fk
  FOREIGN KEY (draft_id) REFERENCES public.drafts(id);
SQL
}

# 16. THE HEADLINE. `coaching_sessions.draft_id` — the column that destroyed every write — must be
#     in the inventory. It arrives via a MULTI-LINE `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`,
#     which is neither one of the five CREATE forms nor on one line, so the pre-Tranche-B probe
#     produced ZERO entries for it and therefore never generated a live assertion.
d="$T/t16"; mk_brightstance_shape "$d"
run "$d"
echo "$PLAIN" | grep -q "Expected column 'coaching_sessions.draft_id'" \
  && pass "Tranche B: multi-line ALTER TABLE ADD COLUMN is inventoried (draft_id)" \
  || fail "Tranche B: expected column 'coaching_sessions.draft_id' in the inventory"

# 17. The UNIQUE INDEX that arbitrates the ON CONFLICT for that same write — also multi-line, also
#     zero entries before Tranche B.
echo "$PLAIN" | grep -q "Expected index 'coaching_sessions_user_draft_uniq'" \
  && pass "Tranche B: multi-line CREATE UNIQUE INDEX is inventoried" \
  || fail "Tranche B: expected index 'coaching_sessions_user_draft_uniq' in the inventory"

# 18. The inline column CHECK — the second destroyed write (`energization = 0` -> SQLSTATE 23514).
#     Keyed by table.column, because Postgres auto-names anonymous checks.
echo "$PLAIN" | grep -q "Expected check 'coaching_sessions.energization'" \
  && pass "Tranche B: inline column CHECK is inventoried, keyed table.column" \
  || fail "Tranche B: expected check 'coaching_sessions.energization' in the inventory"

# 19. Named constraints, both spellings: inline `CONSTRAINT ... CHECK (...)` inside CREATE TABLE,
#     and `ALTER TABLE ... ADD CONSTRAINT`.
{ echo "$PLAIN" | grep -q "Expected constraint 'coaching_sessions_note_len'" \
  && echo "$PLAIN" | grep -q "Expected constraint 'coaching_sessions_draft_fk'"; } \
  && pass "Tranche B: named constraints (inline CONSTRAINT + ADD CONSTRAINT) are inventoried" \
  || fail "Tranche B: expected both named constraints in the inventory"

# 20. Columns declared inside a MULTI-LINE CREATE TABLE body. The old probe inventoried the table
#     and nothing inside it, which is precisely the gap the evidence-contract checklist denied
#     ("every table, COLUMN, type and trigger function").
{ echo "$PLAIN" | grep -q "Expected column 'coaching_sessions.user_id'" \
  && echo "$PLAIN" | grep -q "Expected column 'coaching_sessions.energization'"; } \
  && pass "Tranche B: columns inside a multi-line CREATE TABLE body are inventoried" \
  || fail "Tranche B: expected user_id and energization columns in the inventory"

# 21. ANTI-VACUITY / the reason this is a scanner and not a sixth regex. A line-oriented matcher
#     cannot tell code from a comment or from a string literal. The fixture hides `CREATE TABLE`
#     inside a `--` comment, inside a `/* */` comment, and the word CHECK plus an unbalanced paren
#     and a `;` inside a DEFAULT string. NONE of them may appear in the inventory, and the string
#     must not swallow the rest of the statement either.
# The two negatives are conjoined with a POSITIVE ("the real table IS there"), because a pure
# negative assertion passes on empty output — i.e. it would report green if the validator crashed
# or printed nothing at all, which is the vacuous-test failure mode this whole gate exists about.
{ echo "$PLAIN" | grep -q "Expected table 'coaching_sessions'" \
  && ! echo "$PLAIN" | grep -q "phantom_from_a_comment" \
  && ! echo "$PLAIN" | grep -q "phantom_from_a_block"; } \
  && pass "Tranche B: CREATE TABLE inside -- and /* */ comments produces no phantom inventory" \
  || fail "Tranche B: a commented-out CREATE TABLE leaked into the inventory (or nothing was scanned at all)"
{ echo "$PLAIN" | grep -q "Expected column 'coaching_sessions.note'" \
  && ! echo "$PLAIN" | grep -q "Expected check 'coaching_sessions.note'"; } \
  && pass "Tranche B: a ';' + 'CHECK (' inside a DEFAULT string is data, not structure" \
  || fail "Tranche B: the DEFAULT string literal was parsed as SQL structure"

# 22. `DO $$ ... $$` — the standard idempotent add-column idiom. The body's `;` are not statement
#     ends and its DDL is wrapped in plpgsql control flow, so both the splitter and the matcher
#     have to handle it.
echo "$PLAIN" | grep -q "Expected column 'coaching_sessions.notification_enabled'" \
  && pass "Tranche B: ADD COLUMN inside a DO block is inventoried" \
  || fail "Tranche B: expected column 'coaching_sessions.notification_enabled' (DO block)"

# 23. THE LIVE LEG, AND THE BREAKING CHANGE'S PAIRING. A catalog that has the table but NOT the
#     column is exactly the deployment both Brightstance fires shipped against: the pre-Tranche-B
#     probe reported it green and exited 0. It must now be SCHEMA_DRIFT.P0 — and the finding must
#     be actionable on its own, naming the table, the column, the declaring migration file and the
#     fix, because the operator's symptom is a write returning 0 rows, not a schema message.
d="$T/t23"; mk_brightstance_shape "$d"
mk_fake_psql "$T/t23env" "$T/t23env/catalog.txt"
cat > "$T/t23env/catalog.txt" <<'CAT'
table:coaching_sessions
column:coaching_sessions.id
column:coaching_sessions.user_id
column:coaching_sessions.energization
column:coaching_sessions.note
column:coaching_sessions.notification_enabled
check:coaching_sessions.energization
constraint:coaching_sessions_note_len
constraint:coaching_sessions_draft_fk
index:coaching_sessions_user_draft_uniq
CAT
PATH="$T/t23env/bin:$PATH" run "$d" --live --strict --target "postgres://fake/db"
{ [[ "$RC" != 0 ]] \
  && echo "$PLAIN" | grep -q 'SCHEMA_DRIFT.P0: column "coaching_sessions.draft_id"' \
  && echo "$PLAIN" | grep -q "20260727090400_session_idempotency_key.sql" \
  && echo "$PLAIN" | grep -q "FIX:"; } \
  && pass "Tranche B: a table-present/column-absent catalog is P0 drift naming table, column, migration and fix" \
  || fail "Tranche B: expected an actionable SCHEMA_DRIFT.P0 for the missing draft_id column (rc=$RC)"

# 24. POSITIVE CONTROL for 23 — without it, test 23 would also pass if the new grain simply failed
#     everything. Same fixture, catalog completed with the one missing column: VERIFIED, exit 0.
d="$T/t24"; mk_brightstance_shape "$d"
mk_fake_psql "$T/t24env" "$T/t24env/catalog.txt"
cp "$T/t23env/catalog.txt" "$T/t24env/catalog.txt"
echo "column:coaching_sessions.draft_id" >> "$T/t24env/catalog.txt"
PATH="$T/t24env/bin:$PATH" run "$d" --live --strict --target "postgres://fake/db"
{ [[ "$RC" == 0 ]] && ! echo "$PLAIN" | grep -q "SCHEMA_DRIFT.P0" && echo "$PLAIN" | grep -q "VERIFIED"; } \
  && pass "Tranche B positive control: a complete column-grain catalog is VERIFIED, exit 0" \
  || fail "Tranche B positive control: a matching catalog must not drift (rc=$RC)"

# 25. DROP/RENAME RECONCILIATION. An inventory built by pure accretion asserts objects a later
#     migration deliberately removed — a brand-new false-P0 class that column grain would have
#     introduced wholesale (a scratch column added in migration 3 and dropped in migration 4 is
#     absent from every live catalog, correctly). Added-then-dropped must net to nothing.
d="$T/t25"; mkdir -p "$d/supabase/migrations"
cat > "$d/supabase/migrations/0001_init.sql" <<'SQL'
CREATE TABLE public.orders (id uuid PRIMARY KEY, legacy_note text);
CREATE TABLE public.temp_scratch (id uuid);
SQL
cat > "$d/supabase/migrations/0002_cleanup.sql" <<'SQL'
ALTER TABLE public.orders DROP COLUMN legacy_note;
DROP TABLE public.temp_scratch;
SQL
run "$d"
{ echo "$PLAIN" | grep -q "Expected column 'orders.id'" \
  && ! echo "$PLAIN" | grep -q "legacy_note" \
  && ! echo "$PLAIN" | grep -q "temp_scratch"; } \
  && pass "Tranche B: DROP COLUMN / DROP TABLE reconcile away (no accretion false P0)" \
  || fail "Tranche B: a dropped column/table survived into the inventory"

# 26. Alembic grain. The pre-#95 Python branch matched exactly `op.create_table` on ONE line — on a
#     76-file Alembic tree that is table names and nothing else.
d="$T/t26"; mkdir -p "$d/alembic/versions"
cat > "$d/alembic/versions/0002_add.py" <<'PYFIX'
"""add draft id

Revision: 0002  # this hash inside a docstring must not unbalance the comment stripper
"""
def upgrade():
    op.add_column(
        'coaching_sessions',
        sa.Column('draft_id', sa.Uuid(), nullable=True),
    )
    op.create_index('ix_sessions_draft', 'coaching_sessions', ['draft_id'], unique=True)
    op.create_check_constraint('ck_energization', 'coaching_sessions', 'energization >= 1')
PYFIX
run "$d"
{ echo "$PLAIN" | grep -q "Expected column 'coaching_sessions.draft_id'" \
  && echo "$PLAIN" | grep -q "Expected index 'ix_sessions_draft'" \
  && echo "$PLAIN" | grep -q "Expected constraint 'ck_energization'"; } \
  && pass "Tranche B: Alembic op.add_column / op.create_index / op.create_check_constraint inventoried" \
  || fail "Tranche B: the Alembic branch is still op.create_table-only"

# 27. Postgres identifier folding. The catalog stores unquoted identifiers lowercased, and the
#     comparison is `grep -qxF` — case-SENSITIVE — so an inventory that preserved the source's
#     capitalisation could never match a real catalog. This is a false-P0 hazard that column grain
#     multiplies (columns are written mixed-case far more often than tables).
d="$T/t27"; mkdir -p "$d/supabase/migrations"
printf 'CREATE TABLE public.Orders (Id uuid, "MixedCase" text);\n' > "$d/supabase/migrations/0001.sql"
mk_fake_psql "$T/t27env" "$T/t27env/catalog.txt"
printf 'table:orders\ncolumn:orders.id\ncolumn:orders.MixedCase\n' > "$T/t27env/catalog.txt"
PATH="$T/t27env/bin:$PATH" run "$d" --live --strict --target "postgres://fake/db"
{ [[ "$RC" == 0 ]] && ! echo "$PLAIN" | grep -q "SCHEMA_DRIFT.P0"; } \
  && pass "Tranche B: unquoted identifiers fold to lowercase, quoted ones stay verbatim" \
  || fail "Tranche B: identifier folding mismatch against a real (lowercased) catalog (rc=$RC)"

# 28. GRAIN PARITY BETWEEN THE TWO SIDES. The inventory and the live catalog projection are two
#     independent pieces of text that must speak EXACTLY the same keys; a new grain added to the
#     scanner and forgotten in the introspection SQL fires as drift on a perfectly correct
#     database, which is worse than the gap it replaced. The tests above stub `psql` and therefore
#     never execute the real query, so this asserts the coupling directly on the source — the same
#     "deliberately coupled so a desync fails loudly" discipline as GATE_REGISTRY_COLUMNS.
sql_block="$(sed -n '/introspection_sql="/,/^    "$/p' "$VAL")"
missing=""
for g in "'table:'" "'view:'" "'type:'" "'function:'" "'trigger:'" "'column:'" "'index:'" "'constraint:'" "'check:'"; do
  # substring test in pure bash, deliberately not `echo … | grep -q`: under `pipefail` a pipeline
  # reports the FIRST command's status, so a producer failure would read as a non-match (or vice
  # versa) and this assertion would silently stop asserting.
  [[ "$sql_block" == *"$g"* ]] || missing="$missing $g"
done
{ [[ -n "$sql_block" ]] && [[ -z "$missing" ]]; } \
  && pass "Tranche B: the live introspection SQL projects every grain the scanner inventories" \
  || fail "Tranche B: live projection is missing grain(s):${missing:- (introspection_sql block not found)}"

# =================================================================================================
# v10 FINISH PASS (cluster Z2, item 1) — GATE_MODE is the exemption KEY gate-liveness-probe.sh uses
# to tell "notice mode, honestly nothing to compare" (GATE_PREDICATES_LEGITIMATE) apart from "claimed
# a live comparison but evaluated ZERO predicates" (must convict GATE_VACUOUS.P1) — but until now
# nothing in this suite observed the MODE line at all: mutating GATE_MODE="live" -> GATE_MODE="notice"
# at the one live-VERDICT=VERIFIED site (validate-schema-drift.sh:~1063) left every test above green.
# =================================================================================================

# 29. A --live run that reaches VERDICT=VERIFIED must emit SPECK_GATE_MODE=live — the signal the
#     probe relies on to tell a genuine live comparison apart from an honest non-live notice run.
d="$T/t29"; mk_supabase_1_table "$d" orders
mk_fake_psql "$T/t29env" "$T/t29env/catalog.txt"
printf 'table:orders\ncolumn:orders.id\n' > "$T/t29env/catalog.txt"
PATH="$T/t29env/bin:$PATH" run "$d" --live --strict --target "postgres://fake/db"
{ [[ "$RC" == 0 ]] && echo "$OUT" | grep -q "^SPECK_GATE_MODE=live$"; } \
  && pass "GATE_MODE: a --live run reaching VERDICT=VERIFIED emits SPECK_GATE_MODE=live" \
  || fail "GATE_MODE: expected SPECK_GATE_MODE=live on a VERIFIED --live run (rc=$RC)"

# 30. MUTATION PROOF for #29 — reverting the live-VERDICT GATE_MODE assignment in a SCRATCH COPY
#     (never the shipped script) must turn test 29's own fixture back into a MODE=notice report,
#     confirming that assignment is the real control point and not a default/unreached branch. This
#     is the exact mutation the maintainer verified against the shipped script (asserted below to
#     match exactly once, so the sed can't silently touch the wrong site or several).
[[ "$(grep -c 'GATE_MODE="live"' "$VAL")" == "1" ]] \
  || fail "mutation setup: expected exactly one 'GATE_MODE=\"live\"' site in $VAL — script structure changed?" ""
# The scratch copy must live at the SAME relative depth as the shipped script — it sources
# ../../lib/text.sh by a path relative to its own location (line 82), which a bare $T/*.sh copy
# cannot resolve.
SCRATCHROOT30="$T/scratch-schema-drift-tree-30"
mkdir -p "$SCRATCHROOT30/.speck/scripts/validation/validators" "$SCRATCHROOT30/.speck/scripts/lib"
cp "$ROOT/.speck/scripts/lib/text.sh" "$SCRATCHROOT30/.speck/scripts/lib/text.sh"
SCRATCH30="$SCRATCHROOT30/.speck/scripts/validation/validators/validate-schema-drift.sh"
cp "$VAL" "$SCRATCH30"
sed -i.bak 's/GATE_MODE="live"/GATE_MODE="notice"/' "$SCRATCH30"
grep -q 'GATE_MODE="live"' "$SCRATCH30" && fail "mutation setup: sed did not remove GATE_MODE=\"live\" from the scratch copy" ""
d="$T/t30"; mk_supabase_1_table "$d" orders
RC=0
OUT="$(cd "$d" && PATH="$T/t29env/bin:$PATH" bash "$SCRATCH30" --live --strict --target "postgres://fake/db" . 2>&1)" || RC=$?
{ echo "$OUT" | grep -q "^SPECK_GATE_MODE=notice$" && ! echo "$OUT" | grep -q "^SPECK_GATE_MODE=live$"; } \
  && pass "MUTATION PROOF: reverting the live-VERDICT GATE_MODE assignment makes a VERIFIED run report MODE=notice (real control point)" \
  || fail "MUTATION PROOF FAILED: reverting GATE_MODE=\"live\" did not change the emitted MODE line" "$OUT"

if [[ "$FAILED" == 0 ]]; then echo "✅ validate-schema-drift: all tests passed"; else echo "❌ validate-schema-drift: FAILURES"; exit 1; fi
