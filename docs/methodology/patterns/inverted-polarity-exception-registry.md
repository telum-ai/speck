# Pattern: Inverted-Polarity Exception Registry — the Reusable Chokepoint-Gate Shape

**Category**: testing (gate design)
**Discovered**: 2026-07, issue #100 §2 (reconciles two independently-converged designs from Streb)
**Validated In**: Streb — fully implemented twice (`backend/tests/test_failed_read_is_not_empty.py`,
761 lines / 35 entries; `apps/mobile/__tests__/guards/failed-read-is-not-empty.guard.test.ts`, 542
lines / 15 entries); Splang — as a scanner + a dedicated blind-spot test file
**Occurrences**: 2 full implementations (Python + TypeScript), 1 scanner variant

## Problem

Once a defect class earns a chokepoint gate (see `class-gate-not-a-third-fix.md`), the gate needs
somewhere to record the sites that are correctly exempt — a bare `?? []` that really is fine at this
one call site, a read whose failure genuinely should render as empty. The naive design is a registry
of **instances**: a hand-maintained list of "known-good" sites. That design decays silently. Streb's
own earlier production-writer registry named a writer by hand and nothing checked the name — two
columns sat unwritten for the project's whole life while their entry claimed a writer existed for
them.

## Solution

**Mechanism.** Flip the registry's polarity. **Detection is the proof; the registry holds only
exceptions.** A site is proven acceptable by *detection plus an explicit exception*, never by an
entry someone wrote from belief. A list of *instances* rots silently, because nothing forces it to
stay current with the code. A list of *exceptions* fails loudly the moment the world changes under
it, because the detector re-finds every site on every run and the registry only has to account for
the ones it should not flag.

**Gate shape — seven mechanics, each closing one specific way a registry decays:**

1. **Detection is the proof; the registry holds only exceptions.** The chokepoint scanner runs on
   every commit and re-discovers every matching site. The registry is not a source of sites — it is
   a set of dispositions for the sites the scanner already found.
2. **A typed posture prefix — no fourth thing an entry can say.** Every entry in Streb's registry is
   exactly one of three postures: `NOT-A-READ:` (the matched code is not actually a read of user
   data), `FAIL-CLOSED:` (the default direction is the safe one), `DEFECT:` (a real instance — states
   what the user is told and where). Enforced mechanically: a test asserts every entry declares which
   of the three it is.
3. **Posture is chosen by consequence, not convenience.** Fail-closed is correct for a safety or
   authorization read (an authorization check that denies on a failed read cannot grant anything) and
   **wrong** for entitlement, where failing closed converts a transient read failure into a paywall
   the user cannot retry past. This has to be a structural decision (which HTTP status the server
   returns, which status the client treats as an entitlement boundary), not a convention in prose —
   see the companion decision rule in `class-gate-not-a-third-fix.md`'s sibling classes.
4. **Belief-words are rejected.** A dedicated test fails on any entry containing a belief word (e.g.
   "looks fine") and fails any entry under a minimum length, with a message that demands the caller,
   the surface, or what the default denies. There must be nowhere in the format to write an
   unsubstantiated assurance.
5. **The ratchet fires in both directions.** One test asserts the class cannot grow silently (every
   swallowed read in the codebase is registered); a second test asserts the registry has **no
   phantom entries** — an entry whose site no longer matches the detector gets deleted by the
   guard itself, with a message explaining why (someone fixed or moved it). A guardrail that only
   complains about *new* holes turns into decoration the moment the old ones get fixed and nobody
   removes their now-stale entries.
6. **The count is capped, and the cap only ratchets down.** The number of `DEFECT` entries is
   asserted with an upper bound whose comment states plainly: raising the cap is the defect, lowering
   it is the work. Prefer **equality** over `<=` where practical — a `<=` cap silently reacquires
   slack when defects are fixed without anyone lowering the ceiling, so the class can grow back to
   the old number without the gate saying a word. `== CAP` forces the commit that fixes a defect to
   lower the cap in the same commit, making the ratchet mechanical rather than a habit.
7. **Keyed by `module::function`, never by line.** Production files are edited constantly; a
   line-keyed registry invalidates itself on every unrelated commit above the entry, which is how a
   gate ends up permanently red — and then permanently skipped with `--no-verify`.

**The bounding exception.** This shape is for classes that are **syntactically decidable but not
uniformly correct** — where the right answer genuinely varies by call site and needs a human
disposition recorded once. It is the wrong tool for a class where every instance is simply wrong (use
a plain forbidding lint instead — no registry needed) and for a class not yet proven at ≥2 instances
(see `class-gate-not-a-third-fix.md` for the trigger condition).

## When to Use

- The chokepoint-gate trigger from `class-gate-not-a-third-fix.md` has fired, **and** some matching
  sites are legitimately correct as written (not every instance of the shape is a defect).
- The class has a decidable posture set — safety/entitlement/honesty, or an equivalent small,
  enumerable set of "why this is/isn't a defect here" categories.

## When NOT to Use

- Every matching site is wrong. A registry adds bookkeeping with no payoff; ship a scanner with no
  exception list at all.
- The disposition can't be checked mechanically (mechanic 4 fails — an entry could plausibly just
  assert "looks fine" and no reviewer would catch it). If belief-words can't be rejected
  automatically, the registry format needs redesigning before it ships, not after.

## Related Patterns

- `class-gate-not-a-third-fix.md` — the trigger condition and the umbrella doctrine this registry
  design instantiates.
- `recipe-failed-read-is-not-empty.md` — the reference implementation this pattern is extracted from,
  with the full posture-by-consequence worked example.
- `recipe-pii-redaction-chokepoint.md` — a scanner variant of the same detection-is-proof shape,
  documented with its own three recorded blind spots.

## Source

- ISSUE #100 §2, reconciling two independently-converged Streb implementations at HEAD `edd6e9f04`
  (Speck v9.5.0): `backend/tests/test_failed_read_is_not_empty.py:33-38,49-60,106-118` and
  `apps/mobile/__tests__/guards/failed-read-is-not-empty.guard.test.ts`. The equality-vs-`<=` cap
  refinement (mechanic 6) is issue #100 §2a, found on read rather than claimed by the retro: at
  verification time the backend registry held 20 `DEFECT` entries against a cap of 21, and mobile
  held 9 against a cap of 12 — three fixed defects' worth of silent slack on the mobile side.
