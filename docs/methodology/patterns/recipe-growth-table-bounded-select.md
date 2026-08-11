# Pattern: Growth-Table Bounded Select — PostgREST's `max_rows` Silently Truncating an Unbounded `.select()`

**Category**: testing (class-gate recipe)
**Discovered**: 2026-07, issue #100 §1b
**Validated In**: Streb (Speck v9.5.0) — `apps/mobile/__tests__/guards/growth-table-bounded-select.guard.test.ts`
**Occurrences**: recurring class across any Supabase/PostgREST project with an unbounded-growth table

## Problem

A table that grows without bound (sessions, sets, events, log rows) gets read with a plain
`.select()` and no explicit range or limit. It works in every test and in early production, because
the row count starts under the server's configured `max_rows` (PostgREST's default response cap).
Once a real user accumulates more rows than that ceiling, the read **silently truncates** — no error,
no warning, just fewer rows than actually exist, returned as if they were the complete set. The
failure mode is invisible until an account is old enough to trip it, which is exactly the account a
demo or QA pass never reaches.

## Solution

**Mechanism.** PostgREST enforces a server-side row cap on any request that doesn't set its own
range. The client-side code has no way to distinguish "these are all the rows" from "this is the
first N rows of more" unless it checks the response's own signal (a `Content-Range` header, or an
explicit count) — and most call sites never do, because the happy path looks identical either way.

**The tell.** Grep for `.select(` calls against a table known to grow unbounded, with no accompanying
`.range()`/`.limit()` **and** no check of the returned count against the configured ceiling.

**Gate shape.** A guard that reads the actual configured ceiling from the source of truth
(`supabase/config.toml`'s `max_rows`, not a hardcoded guess that will drift from it the moment
someone changes the config) and asserts every read of a declared growth table either bounds itself
explicitly or checks for truncation. The ceiling **must** be read from config at test time — a
hardcoded copy of "1000" is the same drift risk the registry-hardcoded-in-three-places scar in
`class-gate-not-a-third-fix.md` describes, just for a single integer instead of a column list.

**The bounding exception.** A table with a product-level natural cap well under the configured
`max_rows` (e.g. "a user has at most 12 active goals") does not need bounded-select handling — the
real invariant is "can this table's row count for one owner ever exceed `max_rows`," not "is this
table unbounded in the schema." Declare the growth tables explicitly rather than scanning every
`.select()` in the codebase; a table that is bounded by product design is a declared exemption, not
a gap in coverage.

## When to Use

- Any Supabase/PostgREST-backed project with at least one table whose per-owner row count grows
  without a product-enforced ceiling (workout sets, chat messages, activity events, audit logs).

## When NOT to Use

- Non-PostgREST backends with different pagination defaults — the specific `max_rows` mechanism does
  not apply, though the general lesson (check your ORM/API layer's silent-truncation default)
  transfers.
- Tables with a hard product-level cap below the server's response ceiling.

## Related Patterns

- `class-gate-not-a-third-fix.md` — the hardcoded-ceiling drift risk this recipe deliberately avoids
  by reading `max_rows` from config at test time is the same shape as that pattern's "gate scope
  hardcoded in three places" sub-mechanism.

## Source

- Reference implementation: Streb `apps/mobile/__tests__/guards/growth-table-bounded-select.guard.test.ts`,
  verified at HEAD `edd6e9f04` (Speck v9.5.0); ceiling sourced from `supabase/config.toml`.
- Filed as: ISSUE #100 §1b, table row 2.
