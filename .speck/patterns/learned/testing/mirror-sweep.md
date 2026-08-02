# Pattern: The Mirror Sweep — Find the Second Instance Before a User Does

**Category**: testing (process discipline)
**Discovered**: 2026-07, issue #100 §4 (extends #93 class 4's second-order-cost observation)
**Validated In**: Streb, Splang, Brightstance (all Speck v9.5.0), 11+ instances across the three
products by the fires' own logs
**Occurrences**: 11+ (three of the four axes below each independently attested by named commits)

## Problem

#93 class 4 already names the second-order cost of a fix that lands on only the instance the
reporter was looking at: with no slot for the missing distinction, *"the unknown gets built as a
duplicate component, and the copies drift immediately — nothing enforced the second copy; nothing
would have."* #93's repair — install a slot so the duplicate never gets built — is upstream and
correct, but it has no answer for two things: a rule that **legitimately** lives in two places
(see `recipe-duplicated-rule-schema-type-parity.md`), and **how you find the second copy at all**.
This pattern is the discovery half.

A fix lands on the instance the reporter happened to be looking at. The same rule usually exists
elsewhere, and "elsewhere" is not random — it falls on four predictable axes. Finding it *now*, in
the same session as the fix, is far cheaper than finding it after a user does.

## Solution

**Mechanism.** After any defect fix, before closing it out, sweep the same rule across four axes.
Each axis is answered with a path (the second instance found) or an explicit **"none exists"** — the
explicit negative is what turns this from a vague prompt into an actual checklist. A silently-skipped
axis is indistinguishable from a swept-and-clean one; only a stated negative proves the sweep ran.

**The four axes, and why direction pays the most:**

1. **SURFACE** — the same rule, on a sibling screen/endpoint/consumer. Splang: the AI-provenance fix
   landed on `BringSomeoneDrawer.tsx`. A separate hardening commit, days later, found the identical
   defect on `pages/activity/index.tsx` — *"the locked-in invite passed a template off as the AI's
   draft"* — because nobody had asked what the mirror of the drawer fix was.
2. **REPRESENTATION** — the same fact, rendered a second way. Brightstance: an ending slider's
   resting position was read back to the user as a value they never reported, on a screen one step
   downstream of where an identical fabrication had already been removed.
3. **MOMENT** — the same rule, enforced at one point in time but not another. Splang: a connection
   could commit **after** the block that is supposed to forbid it — the rule existed at *read* time
   and not at *commit* time, and closing it needed a new lock plus a 394-line integration test, not a
   copy-paste of the read-time check.
4. **DIRECTION** — undo vs apply, read vs write, client vs server. **This is the highest-yield axis
   and has no prior art before this issue.** Streb taught every UNDO handler to report a partial
   restore (F130). **Not one forward APPLY path learned it** — a hunt aimed at a class already fixed
   *that same morning* found ten more instances (F137/F138). Four commit subjects tell the whole
   story on their own:
   ```
   harden(F138): the two undos F130 missed, and an acceptance that eased one week of three
   harden(F137 P0/P1): the apply paths learn the honesty the undo paths got this morning
   ```

**Gate shape.** A required MIRROR step in the harden/audit workflow, run immediately after the fix
and before closing the finding: for each of the four axes, name the second instance or write
**"none exists"** explicitly. Treat an un-answered axis as an open item, not a completed sweep.

**The bounding exception.** The mirror sweep is a discovery discipline, not a gate that blocks a
merge — it does not need mutation-proving the way a chokepoint scanner does (see
`class-gate-not-a-third-fix.md`). Its only failure mode is being skipped silently, which is why the
explicit "none exists" is mandatory rather than optional: a blank axis and a swept-clean axis must
be visually distinguishable in the report.

## When to Use

- Immediately after any defect fix, as a required step before the finding is marked closed — not a
  separate later pass.
- Especially when the fix itself was reactive (a user or a fire found it) rather than proactive (a
  gate caught it) — reactive fixes are the ones most likely to have unswept siblings.
- Direction (axis 4) deserves deliberate attention even when the other three feel exhausted — it is
  the axis with the least intuitive pull and the highest observed yield.

## When NOT to Use

- Don't let the sweep grow into open-ended exploration of the whole codebase — it is bounded to the
  four axes for *this* rule, not a general audit. If a sweep turns into a multi-day hunt, that is a
  sign the class needs the chokepoint-gate treatment from `class-gate-not-a-third-fix.md` instead of
  another manual sweep.
- Don't skip the explicit negative to save time. A skipped axis costs nothing today and an unswept
  regression tomorrow — the whole value of the pattern is in the recorded "none exists," not in the
  sweeping itself.

## Related Patterns

- `class-gate-not-a-third-fix.md` — what to do once the *same* rule has been found twice via this
  sweep: the deliverable stops being another fix and becomes a chokepoint gate.
- `recipe-duplicated-rule-schema-type-parity.md` — the case the sweep sometimes surfaces where the
  rule *legitimately* lives in two places, and the answer is a parity test rather than consolidation.

## Source

- First discovered: ISSUE #100 §4 (extends #93 class 4's second-order-cost observation, which itself
  had no answer for discovery or for legitimate duplication).
- Evidence: Streb commits `396115878`, `6306cc8bf`, `ba5078d2d`, `ad3164070` (direction axis);
  Splang commits `6f6f4f4a`, `5359ff71`, `85b7aebd` (surface + moment axes); Brightstance `3ef24b3`
  (representation axis, commit + touched file verified; the claim that the upstream screen was fixed
  first is from the fire report, not independently re-bisected).
