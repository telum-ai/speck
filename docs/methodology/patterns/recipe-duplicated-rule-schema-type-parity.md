# Pattern: Duplicated-Rule Gate — Schema↔Type Parity by Derivation, Not Snapshot

**Category**: testing (class-gate recipe)
**Discovered**: 2026-07, issue #100 §4b (extends #93 class 4)
**Validated In**: Brightstance (Speck v9.5.0) — `types/__tests__/database-enum-parity.test.ts`
(reference); Splang — a live, unfixed counter-example in the same codebase
**Occurrences**: 2 (a single constraint redefined twice, chased by hand both times — the trigger for
building the reference implementation)

## Problem

A rule — a constant, an enum, a threshold, a predicate — legitimately needs to exist in two
languages or two files (a Postgres `CHECK` constraint and a TypeScript union; a product-contract
prose list and a runtime banned-terms array). This is not a mistake in itself: sometimes the rule
really does need to live in both places. What's a mistake is joining the two copies with **nothing
but a comment claiming they mirror each other.** The two copies drift the first time either side
changes, and nothing notices — a comment asserting parity is documentation, not enforcement, and
`class-gate-not-a-third-fix.md`'s mirror-sweep pattern names the corollary directly: *"a comment
claiming two lists mirror each other is a defect, not documentation."*

## Solution

**Mechanism.** A hand-copied second copy of a rule is correct exactly once — at the moment it was
copied. Every edit to the canonical side after that is a silent drift unless something re-derives or
re-diffs the second side on every run.

**The tell.** Any constant, enum, lexicon or predicate that appears as literal text in two files with
no test importing or deriving one from the other. A prose comment saying "keep this in sync with
X" is itself the tell — it is an admission that nothing enforces the sync it asks for.

**Gate shape — a parity test that imports both copies or derives one from the canonical source at
test time**, never a third, separately-maintained snapshot (a checked-in copy is just a slower
drift). The reference implementation earns four properties worth copying wholesale:

1. **It derives, not snapshots.** It reads the migrations from disk at test time and computes the
   *effective* allow-list — files in chronological filename order, later `CHECK` definitions
   superseding earlier ones for the same (table, column), `ALTER TYPE … ADD VALUE` accumulating onto
   `CREATE TYPE`. It does not trust a single migration file in isolation; it replays the whole
   history the way Postgres would.
2. **It names the authority direction.** SQL is the deployed truth — when the two disagree, the
   application-side type is what moves, never the migration (which has already run in production and
   cannot be un-run by editing a test).
3. **It solves the "no runtime value" problem without a third copy.** A TypeScript union has no
   runtime representation to test against; the fix is to declare the list once as an `as const` array
   and derive the union type from it — one declaration, two projections, rather than a union
   hand-typed to match an array hand-typed to match a migration.
4. **It asserts its own parser first.** A regex that matches nothing reads exactly like a pass
   (`[] === []`) — before any parity comparison runs, a dedicated test block asserts the parser's own
   behaviour (supersession, table scoping, comment stripping). A vacuous green is the one failure
   mode a schema-parity test cannot afford, because the whole test exists to catch silence.

**The bounding exception, and the counter-example that argues for making this a standard gate rather
than a one-off.** Splang's banned-language rule lives in a product contract's prose section **and**
in a hardcoded pattern array, joined by nothing but a comment naming the prose section as the source
of truth. Neither side parses the other at test time. The gate was **half** the contract — the
hardcoded array carried roughly half the terms the prose banned, missing among others the product's
own core differentiator term. The repo had diagnosed the drift and fixed the *contents* once, while
leaving the *mechanism* that produced the drift fully intact — which is exactly what this gate, built
once as a standard, would prevent from recurring.

## When to Use

- Any rule that legitimately needs a runtime representation in a language with no way to read a
  markdown/prose source directly (a TS union backing a DB enum; a hardcoded array backing a spec
  section).
- Any constraint that has already drifted once — the strongest trigger, matching
  `class-gate-not-a-third-fix.md`'s general "≥2 instances" rule.

## When NOT to Use

- The second copy is not actually needed — collapse to one source and a direct import/read instead of
  building a parity test to guard a duplication that could simply be deleted.
- The two "copies" are at genuinely different levels of abstraction and are not meant to be
  identical (e.g. a UI validation rule that is intentionally *stricter* than the DB constraint it
  layers on top of) — parity-testing them would force a false equivalence; document the intentional
  gap instead.

## Related Patterns

- `class-gate-not-a-third-fix.md` — the "comment claiming parity is a defect, not documentation"
  corollary this recipe is built to prevent.
- `mirror-sweep.md` — often the discipline that surfaces a legitimately-duplicated rule in the first
  place (the "representation" axis).

## Source

- Reference implementation: Brightstance `types/__tests__/database-enum-parity.test.ts`, verified at
  HEAD `264fb33` (Speck v9.5.0). The recurrence it was built for:
  `commercial_funnel_events.event_name` redefined twice (`20260329113000`, `20260330093000`), each
  time chased by hand.
- Counter-example: Splang `backend/tests/unit/test_runtime_banned_language.py` /
  `test_banned_language_two_tier_gate.py`, both read at HEAD `89468af1` — confirmed neither parses
  the canonical prose source at test time as of that verification.
- Filed as: ISSUE #100 §1b table row 6, §4b.
