# Pattern: A Quality Bound Fused to an Existence Bound — the Gate That Can Never Fail Loudly

**Category**: testing (gotcha + gate-design, doctrine-level; #93's class 3, the one class in that
series with no shipped mechanism)
**Discovered**: 2026-07, issue #93 §3, revisited alongside #103
**Validated In**: analysis of Speck's own readiness-state machinery (below) — no third-party
instance re-verified in this pass.
**Occurrences**: named as the sharpest of #93's five classes; this pattern is its first write-up
with a worked discriminator applied to a real system.

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

**The mechanical tell this yields, described but not shipped as a check here** (this cluster's
owned files are `.speck/patterns/learned/` and `validate-two-carrier.sh`; a new gate for this would
need a new validator file outside that scope — disclosed rather than built past the boundary): a
regression check would assert, from `validation-report-template.md` and `validate-felt-axis.sh`
together, that **the set of blocker classes permitted to cap `NO-SHIP`/`IMPL-GREEN`/
`INTEGRATION-GREEN` (existence) and the set of blocker classes permitted to cap `UX-RC` and above
(quality) are disjoint** — i.e., that no felt/taste/aesthetic signal appears among the conditions
gating the bottom three rungs, and no `implementation-pending`/`autonomous-not-done`-shaped
existence blocker is the ONLY thing standing between a story and a quality-rung claim it has
otherwise earned. If a future edit to either file lets a taste judgment cap below
`INTEGRATION-GREEN`, or lets an existence gap hide behind a quality-sounding justification, THAT
edit is the fusion this pattern warns against, and it would be silent — this is exactly why #93
files this class as having "no mechanism": the violation is a structural property of two files
staying disjoint over time, not a single value a script can grep once and be done with.

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
- `class-gate-not-a-third-fix.md` — the umbrella doctrine for this pattern family; #93 class 3 is
  the one class in the original five with no shipped mechanism, which this pattern's "mechanical
  tell, described but not built" section is honest about rather than fabricating a check.

## Source

- Filed as: ISSUE #93 §3 ("A quality bound fused to an existence bound").
- This repo's own grounding (cited as the POSITIVE / already-correct case):
  `.speck/templates/story/validation-report-template.md:38,48,204,216-217` (existence-only
  blocker classes: `implementation-pending`, `autonomous-not-done`; the TASTE severe-BAD cap
  language), `.speck/scripts/validation/validators/validate-felt-axis.sh:64-67`
  (`is_ux_rc_plus()`, the felt/taste gate scoped strictly to `UX-RC` and above) — all at Speck
  v10.0.0.
