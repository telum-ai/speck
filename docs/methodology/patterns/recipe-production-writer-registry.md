# Pattern: Production-Writer Registry — a Column Read by Production and Written Only by Seed Code

**Category**: testing (class-gate recipe)
**Discovered**: 2026-07, issue #100 §1b (extends #93 class 4 / #76.4's reader-enumeration principle)
**Validated In**: Streb (Speck v9.5.0) — `backend/tests/larp/test_seeded_columns_have_production_writers.py`
**Occurrences**: ≥7 (the guard's own history records an instance-seven rebuild — see below)

## Problem

A column exists in the schema, production code reads it, and something reads as correct — but
**nothing in the production write path ever populates it.** It carries whatever the seed script, a
fixture, or a migration's backfill happened to write once, and reads as live data forever. This is
invisible from the read side: the column has a value, the value looks plausible, and the app renders
it. It is only visible by asking "what writes this, in the actually-deployed write path?" — a
question no ordinary test asks, because ordinary tests assert what a read *returns*, not what
*produced* it.

## Solution

**Mechanism.** Seed/fixture/migration code is a **legitimate** writer at setup time and an
**illegitimate** one at steady state. A column that only ever receives its value from one of those
paths, never from a production write, is either dead (should be removed) or broken (should be wired)
— and either way the current state is a silent lie: "profile settings" that reads correctly forever
because nothing wrote either of two columns for the project's whole life.

**The tell.** Grep every column a production **read** path selects; cross-reference against every
column a production **write** path (not a seed, fixture, or migration) actually sets. A column in
the read set and absent from the write set is the shape.

**Gate shape.** An AST-driven registry, keyed by table+column, asserting that every column read by
production code appears in at least one **production** write path. This is a positive-detection
gate, not an exception registry — there is no legitimate "this column is read-only forever by
design" case that isn't better expressed as removing the read.

**The rebuild is the pattern's own best evidence for `class-gate-not-a-third-fix.md`'s scanner-blind-spot
sub-pattern:** the guard's own header records that its first version covered the seed's `users`
payload only, and two later fires (F64, F71) landed in tables it could not see — *"it now covers
EVERY table the seed writes, via one AST parser that understands all four shapes the seed uses."*
A registry that only covers the shapes someone thought to enumerate at v1 is itself an instance of
the class it exists to close.

**The bounding exception.** A column legitimately populated only by an admin/ops tool (not by the
seed, and not by end-user-facing production code) is a real exception — assert the actual writer
class (admin path) rather than widening "production" to include it silently.

## When to Use

- Any schema with seed data or fixtures that could plausibly be mistaken for real production output
  — which is most schemas with a demo/staging seed.
- After any fire where a column read as "working" turned out to hold stale seed data.

## When NOT to Use

- Single-tenant scripts or throwaway prototypes with no seed/production distinction.
- Columns that are genuinely computed/derived at read time (no writer to check for).

## Related Patterns

- `class-gate-not-a-third-fix.md` — this recipe's rebuild-at-instance-seven is a direct instance of
  the "scanner's own blind spots" sub-pattern.
- `mirror-sweep.md` — the discipline that should have found the other tables before instance seven did.

## Source

- Reference implementation: Streb `backend/tests/larp/test_seeded_columns_have_production_writers.py`,
  verified at HEAD `edd6e9f04` (Speck v9.5.0). Rebuild note quoted from the file's own header,
  `:26-32`.
- Filed as: ISSUE #100 §1b, table row 1.
