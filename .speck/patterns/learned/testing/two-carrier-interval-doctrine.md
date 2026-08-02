# Pattern: Two-Carrier Interval — a Change Whose Two Halves Ride Different Clocks Is Destructive Only in the Window, and the Window Is Invisible Because Both Sides Are Green

**Category**: testing (gotcha + gate-design, doctrine-level; extends `class-gate-not-a-third-fix.md`
and #93's five-class series with a sixth)
**Discovered**: 2026-07/08, issue #103
**Validated In**: Speck's own release process — three verified same-week instances in
`.speck/scripts` release plumbing (below); issue #103 also reports four same-day instances
"across product-deploy and brain-infra" outside this repo, not independently re-verified here.
**Occurrences**: 3 verified in this repo's own history; mechanical detector for one syntactic
sub-shape shipped alongside this pattern as `validate-two-carrier.sh`.

## Problem

A change has two halves that ship on **different carriers with different clocks**: code and its
migration, a schema and its consumer, a config and the image that bakes it, a spec artifact and
the index that points at it, a template and every reader of the artifact it produces. Each half is
individually correct, individually tested, and individually green. Nothing here is vacuous,
forgeable, or unreached — the failure classes #93 catalogued do not apply. **The defect exists
only in the window where one half has landed and the other has not**, and that window is invisible
precisely *because* every gate is green on both sides of it: the fast half's gate certifies the
fast half, the slow half's gate certifies the slow half, and nothing certifies the seam.

The convicting question is not *"is this correct?"* — both halves answer yes. It is **"what is
true between the two landings, and for how long?"**

## The tell

**You cannot see it in either diff.** A diff shows one carrier at a time; the defect lives in the
relationship between two commits (or two deploy events) that never appear in the same diff at all.
**You see it in the deploy graph** — the two paths to production and their relative latencies: a
push-triggered job vs. a nightly, a fast app deploy vs. a manual DB step, a committed derived
artifact vs. the source it derives from (cf. `class-gate-not-a-third-fix.md`'s companion failure
#96, which is the *stale* case of this same axis — the derived artifact never catching up at all,
rather than catching up late).

## The mechanism, worked in this repo

Speck's own §6a CI-Enforced Gate Registry is the doctrine's own grounding instance. Two carriers:

- **Fast**: `.speck/scripts/**` ships to every downstream project via `ALWAYS_OVERWRITE` on
  `speck sync`/`speck upgrade` — instant, no ledger, no opt-in.
- **Slow**: artifact migrations (`registerMigration`) run separately, per-project, via
  `speck migrate --run`, gated on the project's own applied-ledger in `.speck/project.json`.

A column inserted into the §6a table's schema (`Scope`/`Subject`, v9.6/v10, #98) is exactly a
two-carrier change: the TABLE'S SHAPE and the SCRIPTS THAT READ IT can now drift, because the
scripts ship on the fast clock and any given project's own §6a table content ships on whatever
clock its own edits ride. **The interval was inert, and only because §6a parsing had already been
converted to header-keyed** (`validate-gate-liveness.sh`/`gate-liveness-probe.sh`, verified against
the real pre-fix code in `validate-two-carrier.test.sh` Test 1): a reader that resolves `Scope`/
`Subject`/`Canary`/`Waiver` by column NAME reads an unmigrated 6-column table and gets an honestly
empty `Scope`/`Subject` — nothing crashes, nothing misreads, the new predicates simply don't fire
yet. Had the readers stayed **positional**, the identical column insert would have been
**destructive**: every `Canary`/`Waiver` cell silently re-mapped to `Scope`/`Subject`'s old
position, converting a real waiver into a phantom canary declaration with no error anywhere.

Two more instances, same repo, same week:

- **The migration registry was built version-agnostic while its own firing predicate stayed
  major-only.** `registerMigration({appliesTo, ...})` shipped (fast carrier: the lane itself,
  `.speck/scripts`) before `appliesTo` was taught to fire on a minor version bump (slow carrier:
  the predicate logic, cluster B1's fix) — so a migration registered on a minor could never fire.
  This interval was **not** merely inert-and-waiting; it was silently **inert forever** until the
  predicate half landed, which is the same failure shape from the opposite direction: an interval
  with no defined end date is not "short," it just hasn't been measured as long yet.
- **`speck migrate --run` resolved `from`-version and `to`-version from two sources with different
  reliability.** In a non-workspace directory, one source defaulted rather than failing, so the
  command reported `"✅ 2 applied"` and scaffolded `.speck/project.json` in a directory that was
  never a real project. This is the two-carrier hazard at its sharpest: the two "carriers" here are
  two *code paths inside the same command*, not two deploy events — proof the doctrine is about
  clock-independence, not about deploy topology specifically.

## The repair shape

The unit of correctness is **the change plus its slowest carrier**, never the change alone.

1. **Order for inertness — ask this FIRST, in order, before anything else.** *Is the first half
   inert until its partner lands?* Land the half that is a no-op without its partner: the additive
   column before the writer, the new key before the reader, the target before the pointer, the
   header-keyed reader before the header ever gains a column. **If yes, the split is not merely
   acceptable — it is CORRECT**, not a compromise. This is exactly what expand/contract exists
   for, and is why forcing atomicity everywhere would be a worse failure (see the bounding
   exception below).
2. **If it cannot be inert, price the interval.** Ask whether the window is *recoverable* (a
   retry, a backfill, a revert restores the world exactly) or *accumulating* (writes land in a
   shape nothing can read back — a migration silently marked `applied` with nothing run, a project
   file scaffolded in the wrong place). **Accumulating ⇒ the split is not allowed, regardless of
   how short the window is expected to be.** A window measured in minutes that accumulates
   unrecoverable state is worse than a window measured in days that is provably inert.
3. **A gate that spans one carrier cannot certify a two-carrier change.** A green from the fast
   lane's tests is not evidence about the slow lane, and vice versa. Either the gate asserts the
   partner's arrival explicitly, or its verdict is scoped honestly to its own half — composing with
   #98's `SPECK_GATE_SCOPE` telemetry (a gate that publishes what it covered makes a partial
   certification legible instead of silently read as a whole one).

## The discriminator, stated once, in order

Ask repair 1's question first, always: **is the first half inert until its partner lands?**

- **Yes** → the split is correct. Stop here. Do not apply repair 2 or 3's stricter tests to a
  pattern that already passed the first one — that over-application is itself a failure mode (see
  below).
- **No** → move to repair 2. Recoverable → the split is acceptable with the interval priced and
  disclosed. Accumulating → the split is not allowed, however short the window.

## The bounding exception (load-bearing)

Not every two-carrier change is a hazard, and treating every one as if it were would be a worse
failure than the one this pattern closes. **Forcing atomicity everywhere serialises deploys and
pushes teams toward big-bang releases — the exact failure mode incremental delivery, and
expand/contract migration specifically, exist to prevent.** A gate built on "flag any change that
touches two carriers" would convict routine, correct, additive migrations at the same rate as real
hazards, and a check that fires on every expand/contract is worse than no check at all: it trains
reviewers to wave through its warnings, and the real instance ships alongside a hundred false ones.
The discriminator above is not a suggestion to apply loosely — the ORDER matters. A reviewer who
jumps straight to "is this recoverable?" without first asking "is this even destructive while
inert?" will flag correct expand/contract work as a hazard.

## Mechanical check (the decidable subset)

`validate-two-carrier.sh` implements ONE syntactically decidable slice of this doctrine: a shell
script that extracts rows from a markdown pipe-table and pulls a specific column by **hard-coded
integer position**, with no evidence anywhere in the file of resolving that position from the
header row's column NAMES first. This is the exact syntactic shape of the §6a grounding instance
above, mutation-proven against the real pre-fix code (`validate-two-carrier.test.sh` Test 1, a
verbatim excerpt of `validate-gate-liveness.sh` as it stood at commit `0e7ae68^`) and against a
real false-positive risk in the same file family (`gate-liveness-probe.sh`'s own unrelated,
single-clock internal pipe protocol, Test 2).

**What the check does NOT decide** — disclosed, not silently skipped: the "two deploy paths with
different latencies" shape (a push-triggered job vs. a nightly, a fast app deploy vs. a manual DB
step) needs to know what the slow carrier *does* with what the fast carrier shipped — a semantic
judgment about whether the target degrades gracefully, which no syntactic scanner can make. A
check that fired on every two-cadence CI setup would be exactly the over-correction the bounding
exception above warns against. That shape is left to a human answering this pattern's discriminator
question directly, not mechanized.

## When to Use

- Any change where two artifacts, two deploy paths, or two code paths that can complete at
  different times both need to be true for the system to be correct.
- Especially: a shared schema (a table header, a config shape, an API contract) and the readers of
  data governed by that schema, when the schema and the readers ship on different clocks (a
  synced/generated file vs. hand-maintained consumers, a fast CI job vs. a slow migration).

## When NOT to Use

- A change that is genuinely atomic (one commit, one deploy, one carrier) — this doctrine has
  nothing to add.
- A two-carrier change where the first half is provably inert alone — per the discriminator, this
  is the CORRECT pattern, not a risk to mitigate further. Do not chase repairs 2/3 once repair 1
  answers yes.

## Related Patterns

- `class-gate-not-a-third-fix.md` — the umbrella doctrine for gate-design patterns in this
  directory; this pattern is issue #103, the sixth class in the #93/#100 series, and the first
  where nothing is vacuous or forgeable — the defect is purely temporal.
- `quality-bound-vs-existence-bound.md` — issue #93 class 3, filed alongside this pattern; a
  different axis (what a gate is allowed to decide) rather than this one (when a gate's verdict is
  valid).

## Source

- Filed as: ISSUE #103 ("Audit doctrine (6/N)"), extending the #93/#100 series.
- This repo's own grounding: `.speck/scripts/seed-gate-registry.sh` (`GATE_REGISTRY_COLUMNS`,
  the single source for the §6a shape), `.speck/scripts/validation/validators/validate-gate-liveness.sh`
  and `gate-liveness-probe.sh` (header-keyed §6a readers, commit `0e7ae68`, "feat(v10): the
  migration lane, header-keyed §6a, and no proof from prose"), `packages/cli/lib/migrate.js`
  (`registerMigration`, the applied-ledger, `speck migrate --list/--run`) — all at Speck v10.0.0.
- Mechanical check: `.speck/scripts/validation/validators/validate-two-carrier.sh` +
  `validate-two-carrier.test.sh`.
