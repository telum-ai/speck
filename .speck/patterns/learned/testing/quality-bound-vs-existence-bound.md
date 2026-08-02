# Pattern: A Quality Bound Fused to an Existence Bound — the Gate That Can Never Fail Loudly

**Category**: testing (gotcha + gate-design, doctrine-level; #93's class 3 — **mechanized in
v10.2**, after two passes concluded it could not be)
**Discovered**: 2026-07, issue #93 §3, revisited alongside #103, mechanized 2026-08 (v10.2)
**Validated In**: Speck's own readiness-state machinery (below), now under a shipped regression
gate — `.speck/scripts/validation/validators/validate-bound-fusion.sh`.
**Occurrences**: named as the sharpest of #93's five classes; this pattern is its first write-up
with a worked discriminator applied to a real system, and v10.2 is the first pass that turned the
discriminator into an executing check.

## Problem

"Not good enough yet" and "not yet" are indistinguishable in an artifact when a single field is
asked to carry both. A **quality bound** ("is this good enough") and an **existence bound** ("does
this exist / run / integrate at all") are different questions with different owners and different
failure modes — but nothing forces them into different fields, and the natural author's instinct is
to fold "not ready" into one bar and raise it when in doubt. Fused, **the quality bar ANNEXES the
go/no-go**: every blocked thing now reads as merely unripe, and the gate can never fail *loudly*,
because a low bar and a missing feature both render as the identical "not there yet."

This is distinct from #93's other classes even though the SYMPTOM looks similar (a gate that
should have caught something, didn't):

- **Not class #1** (a guard that never runs) — here the gate runs, every time, on unforgeable
  input.
- **Not class #2** (a gate whose evidence the gated party also authors) — here the input is not
  forgeable; the party being gated cannot manufacture a pass by writing prose.
- **The defect is that the gate's JOB CREPT.** It runs correctly on the right input and still
  cannot distinguish two situations that need different responses, because both situations are
  represented by the same value.

## The discriminator

**Self-held is fine when the bound governs CONTENT; pathological when it decides EXISTENCE.**

A quality bound may legitimately be self-assessed, self-attested, or judged by the same party doing
the work — that is not class #2's forgeability problem, because a quality bound is not a go/no-go;
raising or lowering it changes how GOOD the verdict says the thing is, not WHETHER a verdict can be
rendered at all. An existence bound must never be self-held in the same field as a quality bound,
because the moment it is, a low quality score and a genuinely absent feature become the same
observation, and the reader — human or gate — has no way to ask "which one is this?"

Concretely: it is fine for a team to self-certify *"our onboarding flow feels premium"* (content).
It is pathological for *"our onboarding flow feels premium"* to be the ONLY channel through which
anyone learns *"our onboarding flow exists and runs"* (existence) — because now a team that ships a
rough-but-working flow and a team that ships nothing at all produce the identical signal.

## Repair

**Separate the two. Never raise the bar.** The fix to a fused bound is not "demand a higher-quality
self-attestation" (which only makes the annexation worse — it now takes MORE unripeness before the
existence question even gets asked) — it is giving existence and quality **different slots**, so a
reader can tell "this doesn't exist" apart from "this exists and isn't good enough" by inspecting
the artifact, not by inferring intent from a single number or word.

## Worked example: Speck's own readiness-state ladder (an already-correct instance, cited as the
## positive case, since it clarifies the discriminator better than a violation would)

Speck's `readiness_state_claimed`/`readiness_state_verified` field is a single eight-rung ladder —
`NO-SHIP | IMPL-GREEN | INTEGRATION-GREEN | UX-RC | API-RC | COMMERCIAL-RC | SHIP-RC | SHIP` — which
LOOKS, on first read, exactly like the fusion this pattern warns about: one field, one string,
spanning both "does the code exist and run" (the bottom three rungs) and "is it good enough to ship
to a real user" (the top rungs, explicitly quality-gated by the FELT-GOOD/TASTE axes). Checking
whether Speck itself commits the fusion is a fair test of the discriminator.

It does not, and the reason is checkable: **the existence floor and the quality ceiling are capped
by disjoint blocker classes, and the quality-only blockers are structurally prevented from reaching
below the existence floor.**

- **Existence-only blockers cap the existence rungs.** `validation-report-template.md`: an
  `implementation-pending` row caps the verified state at `NO-SHIP` outright ("Unbuilt code cannot
  pass as IMPL-GREEN or higher"); an `autonomous-not-done` row caps at `IMPL-GREEN`/
  `INTEGRATION-GREEN`. Both are EXISTENCE facts (code is present, code is wired) with no taste
  component at all.
- **Quality-only blockers cap only the quality rungs, never the existence floor.**
  `validate-felt-axis.sh`'s `is_ux_rc_plus()` gates FELT-GOOD coverage (`felt_axis: uncovered` is a
  blocker) **only** for `UX-RC|COMMERCIAL-RC|SHIP-RC|SHIP` — verified directly in the shipped
  script (`:64-67`). A story with catastrophic taste — a severe BAD craft violation, per
  `validation-report-template.md:48`, "caps the claimable state" — is capped **down to** below
  UX-RC, never down to below `INTEGRATION-GREEN`. A team can honestly claim "this is built and
  wired, and it looks ugly" as two separate, simultaneously true facts: `readiness_state_verified:
  INTEGRATION-GREEN` (existence, unaffected by taste) plus a taste verdict recorded separately in
  the LARP findings (content, self-held, never gating the existence claim).

## The mechanism (v10.2) — `validate-bound-fusion.sh`

Two earlier passes concluded this class had no mechanical tell. **It does**, and the reason both
passes missed it is instructive: they went looking for the tell **in the artifact**, where it
genuinely is not there. In a validation report, "not good enough yet" and "not yet" are
indistinguishable — that is the class's premise, so any check reading reports would either convict
honest "not ready" reports or convict nothing. And convicting an honest "not ready" is the worse
error by a distance, because it teaches authors to route around the state, which is the very
behaviour this class describes.

**The tell is not in the artifact. It is in the machinery.** In the artifact the two bounds are
fused and undecidable; in the code that *renders* the verdict, the rungs a quality axis is allowed
to gate are written down as an enumerated set — `case "$1" in UX-RC|COMMERCIAL-RC|SHIP-RC|SHIP)
return 0 ;;`. That set is decidable, and whether it intersects the existence floor is a
set-intersection, not a judgment call. Move the subject from the artifact to the machinery and the
class stops being unmechanizable.

`.speck/scripts/validation/validators/validate-bound-fusion.sh` asserts, over Speck's own
validators:

- **A. Non-empty rung scope.** Every quality-axis validator has an enforcement rung-set. Deleting
  the predicate is the *easier* fusion than widening it — with no rung scope the axis blocks
  everywhere, floor included — so "no predicate found" is reported as `BOUND_FUSION_UNDECIDABLE.P2`,
  never as clean.
- **B. Disjointness.** That rung-set does not intersect `NO-SHIP | IMPL-GREEN | INTEGRATION-GREEN`.
  A one-token edit adding `INTEGRATION-GREEN` to either `case` arm reads as a tightening, ships
  silently, and is `BOUND_FUSION.P1`.
- **C. Non-empty subject.** Every quality axis the shipped template declares (`*_axis:` in
  frontmatter) is enforced by a validator this check actually inspected. A green from a check whose
  subject set went empty reads identically to a green from a check that looked at everything;
  `BOUND_FUSION_NO_SUBJECT.P2` keeps them apart.
- **D. Ladder liveness.** The existence rungs it reasons about are verified present in the ladder
  parsed from `validation-report-template.md`. A renamed rung yields
  `BOUND_FUSION_LADDER_DRIFT.P2`, not a stale green.

Two precision properties matter more than coverage here, and both are asserted in the suite rather
than argued: **parse ≠ gate** (both validators enumerate every rung in a `grep -oE` to READ a
claimed state; extracting a rung and gating on one are different acts, and conflating them would
make the check red on arrival against correct code), and **code ≠ prose** (both validators narrate
the ladder at length in their headers; every line is comment-stripped before evidence is read).
Most importantly, **no artifact can move this check's verdict** — pinned by a test that drops a
genuine `NO-SHIP` report with both axes `uncovered` into the tree and asserts the output does not
change by a byte. It cannot convict an honest "not ready", because it cannot see one.

### The residual this does NOT mechanize, located and named

`validation-report-template.md:48` states that a **severe BAD** taste verdict *"caps the claimable
state"* — and names **no floor**. Every other cap directive in the template names its rung
explicitly (`MUST cap at NO-SHIP`; `cap at IMPL-GREEN/INTEGRATION-GREEN`). On its face, then, the
one quality cap in the machinery is unbounded and may be read as capping below the existence floor —
this pattern's exact fusion, in prose. It is deliberately **not** turned into a check: a grep over
template prose is the shape of rule this repo has already shipped vacuous twice (a rule the shipped
template's own boilerplate satisfies), and the repair is one human sentence, not a scanner.

**The repair, for whoever owns that template:** name the floor — *"caps the claimable state at
UX-RC"* — so the craft verdict cannot be read as reaching the existence rungs it does not own.

### Where it runs

`.speck/scripts/validation/pre-commit-hook.sh`, **above** the hook's early exit (the check's trigger
is an edit to a validator or to `validation-report-template.md` — a code commit, which is exactly
what that early exit discards). It fires only when that machinery is touched: the check reads the
machinery, not the commit, so running it constantly would be noise, while running it on the edit
that can change its answer is the whole point. Advisory at v10.2, same rationale as the two-carrier
block: measure the field value before letting it stop a commit.

## When to Use

- Designing or reviewing any ladder, enum, or single-field readiness signal that is meant to answer
  more than one underlying question ("does it exist" AND "is it good").
- A gate whose failure message reads as generic ("not ready," "not verified," "blocked") for
  reasons that, on inspection, are actually different in kind (missing vs. rough).

## When NOT to Use

- A field that only ever answers ONE question (pure existence, or pure quality) — nothing to
  separate.
- A quality bound that legitimately gates a QUALITY-shaped claim (Speck's UX-RC/COMMERCIAL-RC/
  SHIP-RC rungs, by design, ARE quality-gated — that is what those rungs mean, and gating them on
  taste is correct, not a violation of this pattern). Only flag a quality bound when it reaches
  below the existence floor it does not own.

## Related Patterns

- `two-carrier-interval-doctrine.md` — issue #103, filed alongside this pattern; a different axis
  (WHEN a gate's verdict is valid, across a clock boundary) rather than this one (WHAT KIND of
  question a gate's verdict is allowed to answer).
- `class-gate-not-a-third-fix.md` — the umbrella doctrine for this pattern family. #93 class 3 was
  the one class in the original five with no shipped mechanism; v10.2 closed that, and the way it
  closed generalizes: **when a class looks unmechanizable, check whether you are looking at the
  wrong subject.** The artifact is where the two bounds are fused and undecidable; the machinery
  that renders the verdict is where the same distinction is written down as an enumerated set.

## Source

- Filed as: ISSUE #93 §3 ("A quality bound fused to an existence bound").
- This repo's own grounding (cited as the POSITIVE / already-correct case):
  `.speck/templates/story/validation-report-template.md:38,48,204,216-217` (existence-only
  blocker classes: `implementation-pending`, `autonomous-not-done`; the TASTE severe-BAD cap
  language), `.speck/scripts/validation/validators/validate-felt-axis.sh:64-67`
  (`is_ux_rc_plus()`, the felt/taste gate scoped strictly to `UX-RC` and above) — all at Speck
  v10.0.0.
