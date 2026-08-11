# Pattern: When a Class Bites Twice, the Deliverable Is a Chokepoint Gate — Not a Third Fix

**Category**: testing (gotcha + gate-design, doctrine-level)
**Discovered**: 2026-07, issue #100 (extends #88, #93 class 4, #87, #76.4)
**Validated In**: Streb, Splang, Brightstance (all Speck v9.5.0) — this repo's own v10.0.0 finish pass independently reproduced every sub-mechanism below in Speck's own scripts
**Occurrences**: 6+ shipped recipes across three products; 5 of the sub-mechanisms below re-observed in Speck's own `.speck/scripts/` during the same release that files this pattern

## Problem

A defect class is fixed at the instance the reporter happened to be looking at. The fix is correct,
the test is real, the report is honest — and the same shape ships again somewhere the fixer never
looked. The natural response is a third instance fix. That is the wrong response, and repeating it
does not converge: the class re-offends because the **enforcement point is at the leaves**, one leaf
per fix, and there is always one more leaf.

The strongest tell that this is happening: **the class re-offends against a rule that is already
written down.** Streb's `coach-lexicon.md` §5c stated *"every surface that defaults a failed read's
`data` to `[]` or `0` converts 'I couldn't read your plan' into 'you have no plan'"* since fire F182.
The identical defect shipped **four more times** after that sentence was written (F191, F192, F193,
F208). A rule stated in a spec cannot fail a build. Four defects against a documented rule is proof
the rule was never the missing piece.

## Solution

**Mechanism.** A class is fixed per-instance, at the leaf the reporter was looking at. Nothing in the
normal fix workflow ever converts "I fixed this twice" into "the place I am fixing it is wrong" —
that conversion has to be a deliberate, required step.

**The tell.** Grep the *shape* that recurred (a defaulted-empty read, a hand-copied constant, a
try/except that swallows a failure), not the *symbol* that happened to be wrong this time. A class
that re-offends **against a documented rule** is the strongest single tell — it proves the missing
piece is not the rule.

**Gate shape.** On the second confirmed instance of the same shape:

1. **A chokepoint gate is the deliverable, and the third instance fix is not.** Floor the predicate
   at the mapper / chokepoint every reader routes through. Enumerate the **readers**, not the
   writers — a safety or privacy predicate gets exactly one implementation.
2. **Inverted polarity.** The gate proves a site acceptable by **detection plus an explicit
   exception**, never by belief. See the companion pattern
   `inverted-polarity-exception-registry.md` for the full registry design (this is the shape most of
   the six recipe patterns in this directory use).
3. **The scanner is mutation-proven against its own blind spots** — against the class's *past*
   instances (reverting the earlier fix must make it fire again), and its own parse/scan failure
   path must **FAIL**, never report an empty, clean-looking result.

**The bounding exception.** Not every twice-seen shape earns a gate, and a gate built on a shape the
scanner cannot judge is worse than none — it flags correct sites, gets skipped by habit, and the
class ships **un-guarded with a green test standing over it**. Streb's failed-read registry declines
one shape explicitly rather than flag it:

> *"NOT COVERED, deliberately... In THIS codebase the dominant instance of that shape is CORRECT...
> Telling those apart from the real thing needs dataflow this scanner does not do."*

So the rule is **≥2 instances AND a syntactically decidable shape**. When the shape is not decidable,
the honest deliverable is a named, in-file declination plus the chokepoint refactor — not a scanner
that will be wrong some of the time and trusted all of the time.

### The scanner's own blind spots are the class's next hiding place (sub-pattern)

This is the sharpest sub-mechanism, because it produces a *clean report over a live leak* — worse
than no gate at all, because it is trusted. Splang's PII-logging gate reported PASS three ways blind:
it recognised a receiver only when spelled `logger`/`log`/`logging` (ten real call sites through
inline `logging.getLogger(...)` scanned zero); a `SyntaxError` in the target file was caught, printed
to stderr, and `[]` returned — **the same value a clean file returns**, so the one state where the
scanner inspected nothing read as PASS; and its PII name list was missing a name the codebase
actually uses (`contact`, not `phone`/`email`).

**A class gate is not admissible evidence until three things are recorded:**
(a) it fires on the class's **past instances** when the earlier fix is reverted;
(b) its scan **coverage** is asserted non-zero and enumerated, not merely non-crashing;
(c) its own parse/scan failure path is a **FAIL**, never an empty result read as clean.

## This repo's own evidence (Speck v10.0.0, same finish pass that files this pattern)

Five instances of this exact mechanism were found and repaired inside `.speck/scripts/` while this
release was being finished — worth citing because a pattern with a real scar attached gets followed;
an abstract one does not.

1. **A guard shadowed by a broader default, structurally dark.** Speck's git pre-commit loader was
   appended to the **end** of the target hook file. A hook from pre-commit.com, Husky v0.x, or any
   hand-rolled hook ending in `exec …`/`exit 0` **ends the shell process before Speck's block ever
   runs** — chmod succeeds, the marker string is in the file, `grep`-for-marker reports installed, and
   every commit-path gate (`validate-template.sh --strict`, the staged banned-language lint,
   `speck_graph.py lint-refs`) was silently dark. Fixed by splicing the loader immediately **above**
   the terminator instead of appending below it (`CHANGELOG.md` v10.0.0, "What goes red on upgrade
   day"). The regression test for this is instructive on its own: **hook reachability is now asserted
   by EXECUTION, not by grepping for the installer marker** — a marker-grep passes on exactly the
   dead-block case the fix closes, per the `npm test` release note *"Hook reachability is asserted BY
   EXECUTION, not by grepping for the marker; a grep passes on exactly the dead-block case it fixes."*
   This is class #1 from issue #93 verbatim (*"a broad adjacent default shadows"* a guard that is
   itself correct), and CRLF-terminated hooks were 100% dark with no warning at all, because
   `exec …\r` never matched the old terminator scan either.

2. **A gate's scope list hardcoded in three places that had already drifted.** The §6a gate-registry
   column set (`Gate ID | Command | Stage | Domain | Scope | Subject | Canary | Waiver`) used to be
   declared independently in the header-printer, the row-printf, **and** two positional-column
   validators — `.speck/scripts/seed-gate-registry.sh:23-27` records the scar directly: *"the header
   text and the row printf used to be TWO independently hardcoded strings — nothing forced their
   field counts to agree, and the three readers (this script + the two validators) had ALREADY
   drifted from each other."* Repair: one `GATE_REGISTRY_COLUMNS` array is now the single source, and
   both validators became **header-keyed** (`validate-gate-liveness.sh:63`, `gate-liveness-probe.sh:88,136`)
   — they resolve every column by name from the header row instead of by position, so a column
   insertion changes the shape in lockstep everywhere instead of in whichever of three places someone
   remembered to touch.

3. **A test that survives its own fix being reverted, twice, because a section-body grep is satisfied
   by the template's own explanatory boilerplate.** `.speck/scripts/validation/validators/validate-harden-report.sh`
   shipped two independent instances of the identical vacuity: a body-wide `grep` for the mutation
   verdict codes (`GUARD_MUTATION_PROVEN` etc., `:121-130`) and a body-wide `grep` for the counter-test
   class codes (`DEFECT-PINNING` etc., `:200-207`) both passed on **every** report the shipped
   template produces — because both templates ship a prose paragraph inside the same section that
   names all the codes as documentation. A row reading `| n/a | n/a | n/a | n/a | n/a | looks fine
   to me |` was accepted. The comment left in place at the fix site names the repair generally:
   *"READ THE ROWS, NEVER THE SECTION BODY... A verdict is a CELL a script printed, so a cell is
   what gets read."* The fix narrows each check to the **last cell of a data row** (or a
   line-scoped grep on the specific labelled line), never a grep over the whole section's prose.

4. **A wiring assertion placed first in an `&&` chain, suppressing the 30 suites it exists to assert
   about.** `packages/cli/lib/version-parity.test.js` asserts *"every `*.test.sh` under
   `.speck/scripts` is wired into the npm test chain"* — its own comment records *"twice in one
   release a finished `*.test.sh` landed outside the npm test chain — ~105 assertions dark on
   arrival, both times caught by review rather than by a gate."* The chain in `package.json`'s
   `test` script is a hand-maintained `&&` list with no globs. Placed early in that list, a failure
   in the wiring-assertion itself would short-circuit the chain and **abort every suite after it**
   — the assertion whose entire job is to prove nothing is silently unwired would itself silently
   suppress everything downstream of it. It now runs **last** in the chain, specifically so it can
   never suppress the suites it exists to assert about.

5. **A vendor-specific error-message assertion that would go red on a correct producer under a
   different awk.** `.speck/scripts/seed-gate-registry.test.sh:196-211` originally asserted the
   literal stderr string `awk: not enough args in printf` for a desync mutation. That string is BSD
   awk's (macOS). Under `mawk` — the Debian/Ubuntu default, and `.speck/scripts` ships into
   downstream projects whose runner OS nothing pins — a short printf silently prints empty fields and
   **exits 0**, so the literal-string assertion would fail red against a perfectly correct producer.
   The fix, left as a comment at the site: *"the portable invariant is the DESYNC ITSELF: either the
   producer refuses (non-zero exit) or it emits a row with fewer columns than its own header. The
   stderr text survives only as a non-fatal note."* Assert the **behavioural invariant** a tool
   guarantees across implementations, never the **exact wording** a specific vendor's binary happens
   to emit.

## When to Use

- A defect class has shipped **twice** (or more) — at any point after the second confirmed instance,
  before writing the third fix.
- The class is **syntactically decidable** — expressible as a grep/AST shape a scanner can judge
  without dataflow or semantic reasoning it does not have.
- The rule already exists in prose (a spec, a lexicon, a code comment) and is still recurring — the
  strongest trigger of all, because it proves prose does not enforce.

## When NOT to Use

- A single instance. One occurrence is a bug fix, not a class — writing a gate on n=1 is premature
  and usually wrong-shaped, because the "shape" hasn't been observed twice yet to generalize from.
- The shape requires judgement a scanner cannot make (see Streb's declined `?? []` example above).
  Write the declination in the file, in words, instead — see `inverted-polarity-exception-registry.md`.
- The gate itself cannot be mutation-proven against its own blind spots. An unprovable gate is
  decoration; ship the declination instead until it can be proven.

## Related Patterns

- `mirror-sweep.md` — the discovery half: how you find the *second* instance of a class before a user
  does, along the four axes (surface, representation, moment, direction).
- `inverted-polarity-exception-registry.md` — the reconciled registry gate shape referenced by step 2
  above; canonical when the chokepoint gate needs to hold a running list of accepted exceptions.
- `recipe-*.md` in this directory — six proven, shipped instances of this pattern, each with its own
  MECHANISM / TELL / GATE SHAPE / EXCEPTION.

## Source

- Filed as: ISSUE #100 (extends #88, #93 class 4, #87, #76.4), a cross-product retrospective over
  Streb, Brightstance and Splang at Speck v9.5.0.
- This repo's own grounding: `.speck/scripts/validation/pre-commit-hook.sh` (splice
  point), `.speck/scripts/seed-gate-registry.sh` / `validate-gate-liveness.sh` /
  `gate-liveness-probe.sh` (header-keyed columns), `.speck/scripts/validation/validators/validate-harden-report.sh`
  (row-cell vs section-body reads), `packages/cli/lib/version-parity.test.js` + `package.json`
  `test` script (chain ordering), `.speck/scripts/seed-gate-registry.test.sh` (awk portability) — all
  at Speck v10.0.0, `CHANGELOG.md` "What goes red on upgrade day" and "Tests" sections.
