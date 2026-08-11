# Pattern: Failed-Read-Is-Not-Empty — a Caught Read Failure Rendered as a Genuine Zero

**Category**: testing (class-gate recipe)
**Discovered**: 2026-07, issue #100 §1, §2, §3
**Validated In**: Streb (Speck v9.5.0), both a Python backend registry and a TypeScript mobile
registry — `backend/tests/test_failed_read_is_not_empty.py` (761 lines, 35 entries: 20 `DEFECT` / 8
`FAIL-CLOSED` / 7 `NOT-A-READ`) and `apps/mobile/__tests__/guards/failed-read-is-not-empty.guard.test.ts`
(542 lines, 15 entries: 9 / 3 / 3)
**Occurrences**: 5 shipped instances against a rule already stated in the project's canonical
lexicon (F182, F191, F192, F193, F208)

## Problem

A `try`/`except` (or `catch`) around a data read defaults the caught branch to `[]`, `0`, `null`, or
an equivalent "empty" value. This is a completely ordinary defensive-coding instinct, and it converts
**"I couldn't read your plan"** into **"you have no plan"** — a transient failure and a genuine
absence render identically to the user, and every downstream consumer that trusts the empty value as
real inherits the lie. At the top of the ladder, a **failed read became a destructive write** — code
that treated "no rows came back" as "there is nothing to preserve" and proceeded to overwrite.

## Solution

**Mechanism.** "I don't know" and "there is none" are semantically opposite and syntactically
identical the moment a caught exception's handler returns the same shape an honest empty result
would return. The instinct that produces this ("never let an exception crash the render") is correct
about *not crashing* and wrong about *what to render instead*.

**The tell.** A `catch`/`except` block around a read whose handler returns `[]`, `0`, `null`, or
`false` — the same literal an honest "nothing here" result would produce. Distinguish from a
genuinely absent case (the read succeeded and returned nothing) by checking whether the block is
catching a **failure**, not observing a **result**.

**Gate shape — the `inverted-polarity-exception-registry.md` pattern, applied to this specific class.**
Every swallowed-read site is enumerated and given one of three postures:
- `NOT-A-READ:` — the try body is not actually a read of user data (a cache warm, a best-effort
  prefetch with no user-facing consequence).
- `FAIL-CLOSED:` — the default direction is the safe one. Correct for a safety or authorization read:
  an authorization/claim check that denies on a failed read cannot grant anything it shouldn't.
- `DEFECT:` — a real instance. States what the user is told and where.

Posture is chosen by **consequence, not convenience** — this is the sharpest exception inside the
recipe: fail-closed is **wrong** for entitlement. Failing closed on an entitlement read converts a
transient read failure into a paywall the user cannot retry past. Splang encodes this structurally
rather than in copy: the server answers **503** for an unreadable subscription, and both clients
decode an entitlement boundary only from **429** — so the upsell copy is *unreachable*, not merely
unwritten, for the wrong failure mode.

**Why this is `class-gate-not-a-third-fix.md`'s diagnosis one level down (§3):** the rule — *"every
surface that defaults a failed read's `data` to `[]` or `0` converts 'I couldn't read your plan' into
'you have no plan'"* — had been stated in Streb's canonical lexicon since fire F182. Four more
instances shipped **after** that sentence was written, at three independent layers **in the same six
lines** for one of them (server `except → []`, client service `catch → []`, component `catch → []`).
A rule in a spec cannot fail a build; only the registry gate did.

**The bounding exception.** Enumerate every syntactic shape of the class before claiming a gate
closes it — Streb's mobile guard names three (`SWALLOWED`, `NOT-OK`, `TWO-STATE`) and one fire had
shipped two of them in the same six lines. Closing one shape and declaring the class closed is a
partial gate wearing a full gate's report.

## When to Use

- Any read whose result is rendered to a user or fed to a downstream decision, wrapped in exception
  handling that returns an "empty" value on failure.
- Especially state that gates a user-facing claim about **existence** ("you have a plan," "you have
  talked to your coach," "your subscription is active").

## When NOT to Use

- A read whose failure mode is a genuinely absent line with no claim attached (a read-only display
  that simply shows nothing) — the same discriminator issue #93 class 4 draws: does the fallback
  **speak**? Silence never needs this registry; a claim always does.

## Related Patterns

- `inverted-polarity-exception-registry.md` — the general registry shape this recipe is the canonical
  reference implementation of; read that pattern for the full seven-mechanic design (belief-word
  rejection, both-direction ratchet, equality-capped count, `module::function` keying).
- `class-gate-not-a-third-fix.md` — the doctrine this recipe's five-instance recurrence against a
  documented rule is the sharpest evidence for.

## Source

- Reference implementation: Streb `backend/tests/test_failed_read_is_not_empty.py` and
  `apps/mobile/__tests__/guards/failed-read-is-not-empty.guard.test.ts`, verified at HEAD `edd6e9f04`
  (Speck v9.5.0).
- Filed as: ISSUE #100 §1b table row 5, §2, §3.
