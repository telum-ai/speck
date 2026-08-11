# Speck Changelog

## v11.0.0 — 2026-08-09 — Subtraction + JIT + meta-methodology

Speck's always-on surface shrank with teeth. Host loaders (Cursor / Claude Code / Codex) set the
ceilings; P1–P4 and prove gates stayed load-bearing.

### Budget (before → after)

| Metric | Before (~10.5) | After (11.0) |
|--------|----------------|--------------|
| AGENTS.md | ~62810 bytes / 578 lines | **11274 bytes / 103 lines** |
| Auto skill description sum | ~30k chars | **6614 chars** (specific trigger contracts) |
| Auto skill entries | 76 after initial v11 pass | **60** |
| Domain/integration skills | ~20 | **0** (deleted) |
| `disable-model-invocation: true` | inverted / scattered | **machine-owned family policy** |

### Immune system

- `validate-corpus-budget.sh` hard-fails regressions (AGENTS ≤16KiB/≤200 lines; desc ≤120/≤10k sum;
  disable-model allowlist; skill body ≤200; ref nodes ≤120 lines/≤8KiB; declared branch-byte caps;
  direct router ownership; no missing or ref-to-ref continuation edges).
- A1-lite: 12 seeded fixtures / 6 classes; fail closed on wrong verdicts, harness errors, immutable-baseline
  regressions, and candidate-corpus capability deletion; `bash tests/eval/score.sh` → `tests/eval/reports/`.
- GitHub Actions runs the complete repository suite and PR/push whitespace checks.
- Methodology ADRs: `docs/decisions/` + `docs/history/north-stars/v11.md`.

### Catalog surgery

- Deleted generic domain skills (Stripe/Clerk/Supabase/…/`model-selection`). Substitutes: recipes +
  Context7 / official docs JIT.
- Visual-testing hosts folded under `visual-testing/references/`.
- Oversized/branching skills → real router-owned DAG nodes; single always-loaded `procedure.md` pointers are rejected.
- Analyze/adjust now have one canonical automatic entry. Analyze stages one compact scope core, one reviewer lens, then the report template; adjust loads one blast-radius branch.
- Analyze checks every conditional flow slot already reached and records `included`, `not-applicable`, or `missing`. Its project/epic compatibility shims and the generic retrospective router were deleted; validation and retrospective remain level-specific.
- Audit now carries its common adversarial procedure inline and loads only the UI supplement when applicable. PROVE has one sequence: audit implementation, LARP the real experience, use visual testing as UI evidence inside LARP, then validate readiness.
- Migration repair now enters through one staged `speck-migrate` skill. It selects only the oldest active scaffold, proof, graph, or upgrade procedure; the three version-specific skill directories were deleted.
- All 60 automatic descriptions use third-person WHAT + specific WHEN; lifecycle WHERE or sibling boundaries appear only when selection-critical (ADR-0008).
- A 67-case always-on routing suite covers every automatic skill with near-neighbor exclusions. Evaluation runs and reports are generated locally and ignored; only harness code and release conclusions are versioned.
- The complete project/epic/story flow is always in AGENTS context; JIT references explain gates without carrying competing sequences (ADR-0009).
- Encyclopedic AGENTS sections → `.speck/reference/` (canonical-routing, command-phases, host-capabilities).
- Evidence-contract template principle-compressed (≤400 lines); detail JIT under `.speck/reference/evidence-*`.

### Host wiring

- `.agents/skills` → `.cursor/skills` (Codex discovery); `smartSync` creates the symlink on upgrade.
- `CLAUDE.md` is a managed `@AGENTS.md` import; init/upgrade merges it without overwriting user instructions.
- Upgrade `REMOVE_FILES` deletes retired domain + visual-testing host skill dirs from consumer projects.
- `sync-claude-runtime.sh` syncs **skills only** (no longer clobbers generated agents/).

### Current runtime boundary

- `AGENTS.md` now teaches only the current method in plain language. Release rationale lives under
  `docs/history/`; maintainers use `docs/methodology/` and `tests/eval/` without shipping them into projects.
- `.speck/reference/` is explicitly shipped because AGENTS and skills depend on it at runtime.
- Vanilla Speck no longer seeds or overwrites `.speck/patterns/learned/`; upgrades remove only the exact
  former framework files and preserve project-created learning.
- Template export now emits the same curated runtime boundary as init/upgrade, including host-native
  generated agents, while excluding methodology evaluation and history.
- Upgrade removes framework-owned `.speck/eval/` and `.speck/feedback/` leaked by older template exports.

### Release evidence retained

- The frozen 24-run paired tournament observed a 1.00x composite quality ratio: hidden scorer −4.7 points, blinded decorrelated judge +9.8 points, and the predeclared composite −0.4 with a confidence interval crossing zero.
- V11 reduced mean input tokens 15.6%, uncached input tokens 31.7%, and wall time 21.9%; all 8 applicable v11 transcripts passed REACH, SELECTIVITY, TIMING, and GATE_USE.
- Real-project entry canaries preserved mandatory recheck precedence and proved that live graph P1 findings outrank stale project-state prose. Generated transcripts and reports remain reproducible local output, not versioned methodology context.
- This supports a substantially leaner, more inspectable release candidate without claiming a universal quality increase; replication across another model/host and a longitudinal multi-story project remains the next confidence step.

### Agent prose + load DAG

AGENTS.md / skills / skill `references/` / `.speck/reference/` are dense imperative instructions
(ADR-0003/0004). Field evidence for analyze gates (`001-odd` / #106) lives in ADR-0004 + CHANGELOG only.

Skill load (ADR-0005): complete map in `docs/decisions/skill-load-map.md`. Load contracts and post-hoc
transcript tests prove selected context, timing, sibling exclusion, and closure-gate use. Skill frontmatter
contains only trigger metadata; redundant `paths:` hints were removed.

---

## v10.5.0 — 2026-08-07 — Nine gates, and the population each one never reached

Nine issues from one epic in one project, and eight of them are the same sentence: **a check that
was correct about the thing it looked at, and never looked at the thing it was for.**

Not one of these is a wrong answer. Every one is a *right answer over the wrong subject* — which is
the failure this whole line of releases exists to kill, arriving nine more times inside the gates
themselves.

### #109 — the banned-language gate ran below its own early exit

The hook exits early when no spec markdown and no README is staged. That sentence describes **every
ordinary code-only commit** — which is the entire population of a gate whose subject is user-visible
copy in source files. The block sat under it: authored, correct, wired, and structurally unreachable
for every commit it existed to guard.

The file already named this exact class, two blocks above the exit, in its own comment — the
two-carrier and bound-fusion blocks were deliberately placed above the exit for that reason. This
one was not.

Worse than the miss: the hook printed `✓ No Speck specifications or README staged for commit.` and
never mentioned the lint. **A commit that was never scanned and a commit that scanned clean produced
identical output.** The block moved above the exit, and `pre-commit-hook.test.sh` now DRIVES THE
HOOK — the only way to test reach — with four cases including the reported one. Against the old
hook, two of them go red with that exact green line in the output.

### #111 — the copy gate was blind to most real JSX, and said nothing

A `>`…`<` text run was revealed only if it held none of `; { } = ( )`. Six three-line components
differing only in those characters: **one of six fired.** And `SPECK_GATE_UNPARSED=0` on every run,
because a rejected text run took neither of the two honest paths the filter documents — it was not
scanned whole, and it was not counted. Clean file, unread file, byte-identical output.

Braces are out of the reject set. In JSX `{` opens an *expression container*; the prose around it is
still prose, and Prettier **manufactures** the blind shape — it emits `{" "}` at every long-line
wrap, on exactly the long lines that long-form copy produces. The container's contents stay hidden,
because `{apiClient}` is an identifier and revealing it would re-open the false-conviction class
`--strings-only` exists to close.

What is still refused is now **counted and named**: `SPECK_GATE_TEXT_RUNS_REJECTED`, per file. That
half was worth shipping even alone — it converts a blind spot into a residual you can look at.

### #110, #112, #113 — three ways to be wrong about §6a

- **#112** — every cell is de-backticked now. `gate_sig` already stripped backticks from the Command
  cell; the Scope cell one screen away did not, and went straight to
  `git ls-files -- ':(glob)`src/**`'`, which matches nothing. **The shipped template writes every
  Scope cell backticked.** So Speck's own template produced rows the shipped validator read as
  unresolvable, and the project that quietly dropped the backticks to silence the warning was the one
  that ended up correct. Read the other way: the vacuity check #98 installed was evaluating nothing.
- **#113** — §6a row extraction is bounded to the table carrying the `Gate ID` header. It used to
  take every `|`-line up to the next heading, with the header found by a separate grep — so §6a, the
  section reserved for documenting what a gate does *not* cover, was hostile to the measurement
  tables that documentation naturally takes. Six phantom gates from one residual matrix. The observed
  workaround was to render it as a fenced code block with a parenthetical explaining why, which is a
  formatting choice forced on a document by its reader.
- **#110** — the hook directory is resolved from `core.hooksPath`, not hardcoded to `.husky`. A
  project committing `.githooks/pre-push` got `SCRIPT_UNREFERENCED.P1` for a gate that was wired,
  running, and observed blocking a red push. Husky still works: `core.hooksPath` points at the
  generated `.husky/_` dispatcher, so the resolver peels one `/_`.

### #114 — four ways the mutation harness refused legitimate evidence

Together these meant **no DB guard, no Next.js e2e guard, and no file below a `/*` in prose could
produce mutation evidence** — and each failure was reported as the *site's* fault.

- **A path is not a verb.** `cl_looks_destructive` was handed the whole invocation, so
  `npx vitest run src/lib/deploy/region.test.ts` was "unsafe" while the same command on
  `sha.test.ts` was "safe". It bites hardest where mutation evidence matters most: a guard protecting
  a deploy pipeline lives in a file named after the thing it guards. The operative tool is classified
  first, and path-shaped arguments are redacted before the verb scan — `vitest run x && supabase db
  push` is still refused.
- **A vendor name is not danger.** Every other alternative in the denylist is `<tool> <verb>`;
  `supabase` sat there alone and refused `supabase status` — a read-only command — along with a
  container named `supabase_db_odd` and any path containing the string. The denylist refused the CLI
  and the allowlist refused the raw client, so **no admissible applier existed for any DB-migration
  guard.** Vendor entries are verb-scoped now, and `--applier` is a real step: "bring the system to
  the mutated state", run after the mutation, with its own safety rule and an explicit `--applier-ack`
  for the cases that still trip the denylist.
- **Two greens that meant opposite things.** `GUARD_MUTATION_GREEN.P2` is documented as "the mutation
  happened and the suite did not notice — write the honest scope onto the test". For a migration
  nobody applied, the guard is not blind at all; it reddens hard the moment the mutation reaches a
  database. That case is now `GUARD_MUTATION_UNOBSERVABLE.P2`, and a harness that could not run the
  guard at all is `GUARD_UNMUTATED_HARNESS.P2` — because an author who reads "already red" as a
  verdict on their gate deletes a working gate, or tunes something until it goes green.
  `cl_link_node_modules` also clones instead of symlinking under Turbopack, which rejects a symlink
  escaping the project root and killed the whole e2e layer of any Next 16 project.
- **`/*` inside a string is not a comment.** A doc comment holding the literal `` `@sentry/*` ``
  opened a block that never closed, so every later line in the file was classified as prose and every
  mutation site refused — with a message blaming the site. Literals are blanked before the delimiters
  are counted.

Every refusal now **names the token that fired**. The same ask arrived from three independent
stories, which is what a message that sends the reader to a 40-alternative regex earns.

### #116 — the documented invocation hung forever

`dirname "validation-report.md"` is `.`, and `dirname "."` is `.`, so the project-root walk in
`validate-felt-axis.sh` and its taste twin never advanced. The relative path is the invocation the
`story-validate` skill documents; two validator agents on two different stories each lost a run to
it. The argument is canonicalized, and the walk breaks on any fixed point. The regression test uses
a **timeout as the assertion** — a hang has to be a red test, not a hung suite.

### #118 — one escaped pipe shifted every column after it

`IFS='|'` splits on `\|` too — the only way to write a literal pipe in a markdown cell. Header-keying
made it **worse**: the header row has no escaped pipe, so it yielded correct indexes, and the data
row yielded one extra cell. On the validator that decides whether an epic may close, Grain read
Backing and Status read Grain. The author wrote `discharged`; the row meant `impl-green`.

A matrix row *will* carry a pipe — the Backing column holds evidence, and evidence is commands. The
row citing the shell pipeline that produced its own evidence is the row most likely to be silently
re-read. `sp_row_protect` / `sp_row_restore` live in `text.sh` with the other idioms, and both
matrix readers use them. Paired with a **cause-agnostic** check: a row whose cell count disagrees
with the header is reported, whatever produced the divergence.

### #115 — "client bundle" meant three things and the gate knew one

A Server Component rendering `process.env.<SERVER_ONLY_VAR>` delivers the value to the browser via
prerendered HTML **and** the RSC flight payload. A scan scoped to `.next/static/**` printed CLEAN
over both. The phrase carries an implicit Pages-Router-era definition, and the gate inherited it.

The evidence-contract template now defines **"client bundle" = everything the browser can receive**,
enumerated per framework, and requires **one liveness self-test direction per enumerated surface**.
That second rule is the one that would have caught it: the gate *had* a self-test, and the self-test
only planted a canary where the scan already looked — proving the machinery, not the coverage.

### Verification

Every fix above is pinned by a test that was **observed going red against the pre-fix code**, not
merely added. The #111 matrix reproduces the issue's six-fixture table verbatim (1 of 6 firing
before, 3 firing and 3 counted after); #109's two reach tests fail against the old hook with its
`✓ No Speck specifications or README staged` line in the output; #114 §4 fails with the exact
`is a comment, a docstring or blank` message the field report quoted.

## v10.4.0 — 2026-08-07 — A marker nobody read, and a promise with no name

Two issues, and the same sentence describes both: **a check whose vocabulary was narrower than its
subject, reporting a verdict over the part it happened to understand.**

### #107 — `[!]` BLOCKED tasks were not counted as done. They were counted as nothing.

The field report said blocked tasks "read as done". The mechanism is worse than that. The total was
counted with the character class `[ xX]` and the completions with `[xX]`, so a `- [!] T014` line
matched **neither**. It did not inflate the numerator — it was **erased from both**. A tasks.md with
18 tasks, 5 of them blocked, reported *"13 of 13 complete · Ready for /story-validate"*, and one of
the five that vanished was the load-bearing observation task for its AC.

That is the dark-gate shape at its purest: an orchestrator reading that line advances the story, and
nothing anywhere prints differently. A green and an erasure are the same string.

The denominator is now `\[.\]` — **any** single-character marker. A task is a task whatever glyph its
author reached for, and a marker the validator has never heard of must change a count it cannot be
silently dropped from. `[x]` is complete, `[!]` is blocked, `[ ]` is pending, and anything else is
incomplete **and named**, because an unrecognised marker resolving quietly to "not done" is how the
next `[!]` gets invented and mis-read again.

Blocked tasks are now listed, not just counted — a count tells you to look, the list tells you
where — and `--strict` rejects. The Ready verdict is additionally guarded on the blocked count,
which is redundant while the arithmetic is right and is there precisely because #107 reached the
field as a *wrong verdict* produced by arithmetic that was not.

**`[!]` was never in `tasks-template.md`.** It was a field convention the validator had no vocabulary
for, which is the actual root cause — so the marker table is in the template now. The fix is not the
regex.

This validator also shipped **eleven minor versions with no test suite at all**. It has one now, with
mutation controls; one of them reproduces the field report verbatim.

### #108 — differentiator pillars get ids, closing the limit v10.3 disclosed

v10.3 made promise coverage a hard gate and could only reach MM-N and JOB-N. §3 was one free-prose
sentence with no id, so the gate emitted an honest *"pillars: not evaluated"* rather than claim a
verdict it could not compute. Filed rather than buried, and closed here.

§3 pillars are now `### DIF-N` headings — the **same grammar as `### MM-N`**, deliberately: the
number is the machine key, the title is for humans, sub-lettered ids (`DIF-2a`) are real ids. The
witness graph extracts them, so `PROMISE_UNCOVERED.P1` reaches a pillar no epic delivers, and the
severity mapping rule reaches the class so a pillar gap cannot be authored down to HIGH.

**§3a anti-differentiators deliberately get no ids.** An anti-differentiator is a *constraint*, not a
promise: nothing delivers it, so nothing can cover it, and a coverage gate over it would produce
findings closable only by deleting the claim. A test asserts they never node-ify.

**The upgrade is a no-op until a contract opts in, and that is measured rather than argued.** Adding
a node kind is the change that can silently force a witness rebuild across the whole installed base
— `_graph_signature` hashes nodes and edges, so one extra node anywhere reddens every committed
witness. No contract on disk carries a `### DIF-N` heading, so the extractor emits nothing and the
signature is byte-identical; the test compares a fresh compile against the pre-change graph and
asserts equality, then asserts the signature *does* move once a pillar is declared. v10.1's
node-schema change needed `REBUILD_WITNESS_GRAPH_ID`; the difference between that release and this
one is that assertion, not a claim in this file.

## v10.3.0 — 2026-08-07 — The adversary reaches the plan

Two field reports from one session (#105, #106). They look unrelated — a shell parser and a
methodology gate — and they are the same defect at two altitudes: **a check that reported a verdict
it had not earned**, in both cases by inspecting less than it appeared to.

### #106 — `/project-analyze` is required, decorrelated, and consequential

The report is the argument. A planning corpus produced through the FULL canonical Build flow — every
skill entered, templates read, five skeptical-review primitives, `/speck-premise-challenge`, strict
validators green, a decision log with 3+ alternatives per lock — still carried **1 CRITICAL and 13
HIGH defects**. Every one survived every inline gate. All 14 were found by a single decorrelated
multi-lens pass, and the CRITICAL was a promise-level contradiction: the evidence contract banned
n=1 evidence while a gate required that same magic moment validated at n=1 by construction.

The structural cause, in P4's own words: **the adversary is supposed to be structural, but at
project-plan level it was opt-in — and the party opting in was the author.** Speck already gets this
right downstream (`/audit` is non-skippable; the Verify-Skills Gate rejects self-audits). The
planning corpus — the highest-leverage artifacts in the system, which every epic inherits — had the
weakest adversarial treatment in the canon.

So: required after `/project-plan`, before any `/epic-specify`, at Platform and at Build with 4+
epics — the threshold that already forces architecture + ux-strategy. Below it, optional and
recommended. `/epic-analyze` carries the same contract one altitude down, because fixing only the
project altitude would have closed the named gap and opened a new one directly beneath it.

**The lens tier is 3 at Build-4+ and 7 at Platform, and that is a decision, not a default.** The
field evidence came from seven lenses, which argues for seven everywhere. AGENTS.md's own anti-bloat
rule argues the other way, and it wins below Platform: the three that are mandatory — promise
coverage, cross-artifact drift, completeness critic — are the three whose defect classes are
*structurally invisible to the author* (an absence, a relation between two files, and the blind spot
itself). A lens whose reviewer authored a corpus artifact does not count toward the tier.

**Severity is assigned by rule, not by the author.** Three classes are CRITICAL by construction: a
cross-artifact `contradictory` verdict, an unaddressed MM-N/JOB-N, and a gate precondition that
contradicts the evidence contract. This is the load-bearing paragraph, and it is worth saying why:
of the 14 defects that motivated the issue, **13 were graded below CRITICAL by their own author**. A
discretion-graded gate would have passed all 13 and blocked one.

Enforced by `validate-project-analysis.sh --gate` (exit 1 on any P1 with **no flag required** — a
finding that only fires when asked for is not a gate), reached from `/epic-specify` through
`check-epic-prereqs.sh`, and from the pre-commit hook on a staged `epic.md`. Promise-coverage
completeness reads MM-N/JOB-N from the **witness graph** rather than re-grepping `product-contract.md`:
design invariant 2 forbids a parallel truth, and a second MM parser is a two-carrier interval by
construction.

### ⚠️ Upgrade day — the gate is real forward and advisory backward

Every project on disk planned its corpus before this gate existed and could not have satisfied it.
The `v10-3-analysis-gate-grandfather` migration writes a per-project
`<PROJECT_DIR>/.analysis-gate-grandfathered` marker to each project that shows `/project-plan` ran
(`PRD.md` **and** `epics.md`) with no analysis report. While present: a loud notice that repeats on
every run, and **never a block**. Projects planned on v10.3+ have no marker and do block.

That asymmetry is the disclosed cost of not turning an entire estate red on the upgrade commit — an
estate that arrives red gets bypassed rather than fixed. The marker does not delete itself; once a
report exists beside it the gate calls the exemption **spent** and prints the `rm` that retires it,
because an exemption outliving its reason is how a gate turns off with nobody deciding to turn it off.

### #105 — the wave-safety parser, and what it was not checking

The reported bug was a crash: an `epics.md` whose only parallel cell read `Yes (distinct surfaces;
E003 zero migrations)` aborted at `wave_epics_: unbound variable`. The crash was the *harmless* half.
The other half — the exact-match `parallel_lower == "yes"` — meant every annotated cell was silently
filed as serial, so the wave was never collision-checked and the run exited 0 with a green tick.

Rewriting the parser to fix that surfaced a class of the same thing, each verified by running it:
`None` / `none` / `N/A` / `TBD` / `zero` / en-dash all parsed as real migration lists and fabricated
collisions — while `zero` is the word AGENTS.md itself uses for that state; a markdown-link value was
discarded as a placeholder and hid a real collision; `- **Migrations**:` parsed as no migrations at
all; a `## Story Estimates` table parsed as a concurrency wave; the word "Touch-points" in prose
after the last epic reopened the block; a duplicate wave row silently erased the first row's
collisions; `E002 + E003` collapsed to one token and skipped the pair.

And one that was never reported, more severe than either reported bug: an Epics cell of
`E002:-$(touch /tmp/PWNED)` reached `eval` and **executed** — verified by the file appearing on disk.
The eval-based pseudo-associative array is gone entirely rather than sanitised; keys are validated
against `^E[0-9]+$` before storage, so the payload is now a named `WAVE_EPIC_UNPARSED.P2` finding.

**Wave safety runs at pre-commit, and it is ADVISORY this release — a gate that still cannot fail a
build.** That is a half-measure and is labelled as one rather than shipped as enforcement. The bug
being fixed is a *false negative*, so the fixed validator sees collisions the broken one hid — real
ones, in plans that have read green their whole life. Blocking on arrival would be green→red on the
upgrade commit for a collision the author did not introduce. Promotion to blocking is one line, and
it belongs to a release where the field has watched it print first. For the same reason it gets **no
§6a row**: §6a is the CI-*enforced* registry, and declaring `stage: pre-commit` for a check that
cannot reject anything is a label outrunning its status — the two existing advisory blocks are
deliberately absent from it too.

### Two over-corrections, found by re-running the issue instead of re-reading the fix

Both were authored *by* the #105 rewrite and caught only when the original repro was replayed against
the finished validator. Recorded because the lesson generalises: the riskiest moment for a false
negative is the commit that closes one.

- The touch-points header was anchored on `**`. The shipped template emits bold, so every fixture in
  the suite passed — while a hand-written `Touch-points:` captured nothing and two epics sharing a
  model file reported a clean PASS. A validator that reads only the shape its own template emits is
  checking its scaffolding, not the corpus. The discriminator is now the shape of a *header* (a
  colon with nothing after it), which keeps the anti-prose property the anchor was reaching for.
- The exposure line printed `epics with touch-points: 3` for a run that captured zero, because it
  counted registered `### EXXX` headers — epics that *exist*, not epics that were *read*. That line
  exists solely to distinguish a real green from a green that inspected nothing, and it was
  reporting the verdict's confidence instead of its reach. It now reads `parsed/total`.

### Fixed

- `count_epics()` in the analysis gate returned the `epics/` **directory** count whenever it was
  non-zero and consulted `epics.md` only as a fallback, while `check-epic-prereqs.sh` one frame up
  took the MAX of both. A project with 4 planned epics and its first epic dir scaffolded — the most
  common state a project is ever in — read 4 there and 1 here, so the gate reported "not applicable"
  and passed clean. **The entire #106 gate would have shipped inert**, and an inert gate and a
  satisfied gate print the same exit code. Both counters now take the MAX, and a test asserts they
  agree on one fixture, because the duplication is the real defect.
- `project-analysis-report.md` and `epic-analysis-report.md` fell through `validate-template.sh`'s
  `*) exit 0` arm, so every section their templates declared was unenforceable by construction —
  the hole `validate-harden-report.sh` was written to close for one artifact. Both now route to a
  structural validator, vintage-bound on `artifact_type:` so no report already on disk is convicted.
- The wave-safety banner printed a frozen `v7.18.0`; it reads `.speck/VERSION`.

## v10.2.0 — 2026-08-02 — The backlog closes

Closes the last three open issues from the field-filed audit-doctrine series (#93, #96, #101), and
puts every remaining orphan validator on a real invocation path.

### §11a — the Standard Probe Library (#101)

Buildable at last, because v10.1 shipped the type vocabulary it needed. §11a ships as a **sibling**
of §11, not an extension of it — §11 is byte-untouched and its P4 ("do not grow this list to close a
gap") is restated in §11a's own opening, because the issue was explicit that the two sections have
different shapes and only one of them is closed.

Eight closed classes, each carrying an admissible substrate, its required negative controls, and a
first-class **declared exception**. `PROBE_SUBSTRATE_MISMATCH.P1` is now a real lookup — claim type →
admissible citation types → is the cited type in the set — rather than an inference over a string
that carried no type.

Three properties worth stating because each was a decision, not an accident:

- **Unknown never convicts.** An untyped discharge artifact is `PROBE_SUBSTRATE_UNKNOWN.P3` at exit
  0. Admissibility is a property of the *pair*; an unknown type means the pair is INCOMPLETE, not
  inadmissible. Resolving incomplete to inadmissible would redden every un-stamped project on
  upgrade day while claiming a verdict it never computed.
- **Absence and inapplicability are mechanically distinguishable** — the same law as
  `GATE_EMPTY_LEGITIMATE` vs `GATE_VACUOUS`. A class that does not apply is *declared*
  (`n/a:<reason>`, or `waived DEC-####` resolved against the decisions log); a bare `n/a`, a
  DEC-less waiver, or a **deleted row** is a finding.
- **The registry cannot be edited into agreement with itself.** The lookup routes off the compiled
  claim type, never the cell, so weakening a row's claim type raises `PROBE_LIBRARY_DRIFT.P2` *and*
  leaves the mismatch firing.

The shipped template ships §11a undischarged on purpose, so the unedited artifact is the sin: exactly
8 `PROBE_UNDECLARED.P1`, and 0 once every exception is filled. Pinned in both directions.

### Every gate now has a caller

This release closes a backlog about gates that certify what they never inspected, so it swept its own
tree for the same defect: all 65 scripts under `.speck/scripts`, grepped repo-wide, with prose-only
mentions discarded so a mention could not pass as an invocation.

- `validate-evidence-citations.sh` and the §11a check are **declared** as standing §6a rows (emitted
  through the same producer as recipe gates, so a column insert shifts them identically) and
  **executed** at seed/amend time. Stage is `manual` honestly — nothing on the commit path invokes
  them yet, and declaring a stage a gate does not fire at is exactly the divergence
  `validate-gate-liveness.sh` exists to catch.
- `validate-two-carrier.sh` (#103) runs on the pre-commit path over **changed shell files only** —
  not a repo-wide scan, which would be both slow and blocking.
- **`banned-phrase-detector.sh` had no caller at all** — no hook, no skill, no CI, no §6a row, no
  test — while `docs/frontier/` asserted it was covered by a lane that does not exist in this repo.
  It scans agent-authored prose for the "production-ready / no regressions / rock-solid" register
  that stands in for evidence, so a commit message is precisely its subject. Wired into
  `commit-msg-hook.sh`, **advisory**: it prints, it never blocks, and it never changes the exit code.
  A phrase list is a nudge, not a proof — and a gate that newly rejected commits on wording would be
  turning a green repo red on the upgrade commit.

### #96 — the graph remainder

Finding 4's decidable slice (`PROMISE_FIDELITY` / `WIRING_UNRESOLVED`, minted inside `check_graph()`
so they reach every existing consumer without a new hook), the project-state **Proof column** derived
from the graph rather than hand-authored — a hand-authored proof column would be #93 class 2 by
construction — and a deterministic, documented gap-source ordering, because the order decides what
the next session works on.

### #93 class 3 — a quality bound fused to an existence bound

The one class of the original five that had no mechanism, and the discriminator was sharp enough to
mechanize after all: **self-held is fine when the bound governs CONTENT; pathological when it decides
EXISTENCE.** `validate-bound-fusion.sh` looks for the fusion — a single self-authored field that both
grades quality and gates advancement — and is deliberately precise rather than broad, because a check
that convicts an honest "not ready yet" would train exactly the routing-around the class describes.

### Fixed

- `.claude/loop.md` invoked `.speck/scripts/v7/regenerate-project-state.sh` — a path that does not
  exist, so that loop step was a silent no-op pointed at the script this release makes load-bearing.
- Two measurement comments that disagreed with each other, and one that pinned a live corpus with no
  SHA so it re-rotted on the next commit to an unrelated repo. The figures live in one place now, and
  the durable claim is the ratio, not the absolute count.
- A `pass` that executed unconditionally after a `break 2`, printing a ✓ beside its own ✗. It never
  hid the failure — but a green tick next to a red cross, in a suite whose subject is honest
  verdicts, is the wrong artifact.

## v10.1.0 — 2026-08-02 — Minor-capable migrations, typed citations, observation exposure

Works the open half of the audit-doctrine backlog (#93 / #96 / #100 / #101 / #103 / #104). The
headline is unglamorous and unblocks the rest: **migrations can now ship on a minor.**

### ⚠️ Upgrade day

- **The witness graph is rebuilt for you.** v10.1 adds `entry_point` and `wiring_witness` to `prm`
  and `story` nodes, and `_graph_signature()` hashes the full node list — so every `witness.json`
  committed under v10.0.0 would otherwise compare unequal to a fresh compile and report
  `GRAPH_CAP = STALE` on a project nobody touched. `v10-1-rebuild-witness-graph` runs on upgrade and
  rebuilds each project's graph. Measured end to end: `INTEGRATION-GREEN` before, `STALE` with the
  scripts landed and the migration not yet run, `INTEGRATION-GREEN` after — and a second run is a
  no-op.
- **Citation types are stamped for you** by `v10-1-stamp-citation-types`, where they can be derived
  unambiguously. Ambiguous citations are left untyped on purpose: a wrong type produces a confident
  false admissibility verdict, which is worse than no verdict. The stamp preserves your authored cell
  padding byte-for-byte and refuses to touch a table that has no `Claim` column; because the stamped
  cell's *content* grows, rendered column alignment in stamped rows does widen. Re-aligning is a
  separate, opt-in pass. If a write turns out not to be a pure in-cell annotation, the migration
  restores the file and stays pending rather than recording a lie.

### The migration lane goes minor-capable

`appliesTo` receives full versions now, not just majors — `atOrAfter('10.1.0')` fires on a minor,
`crossesMajor(10)` preserves the v10 semantics exactly. A frozen 19-crossing decision table, captured
from v10.0.0 *before* the refactor and asserted through `pendingMigrations()` rather than by calling
the predicate directly, proves every historical decision is unchanged.

This was a self-inflicted repeat: the registry shipped version-agnostic while its predicate stayed
major-only, so a migration registered on a minor could never fire — the same constraint that forced
v9.6 and v10 into one major, and precisely #103's class (two halves of one mechanism on different
clocks). The compat path is not cosmetic: handed a version string, an old two-parameter predicate
evaluates `NaN >= 10` → false and the migration silently never runs, so dispatch is by predicate
shape and a new predicate that could receive the wrong arguments gets a loud warning.

Multi-hop works: `10.0 → 10.3` replays 10.1, 10.2 and 10.3 once each in version order, and a throwing
migration records `failed`, keeps its siblings running, and stays pending. `speck migrate --list`
prints the introducing release for every pending and applied entry.

### Typed evidence citations (#101)

§11a was not implementable as specified — `PROBE_SUBSTRATE_MISMATCH.P1` cannot be computed from a
`path@sha` string that carries no type. So this builds the thing upstream of it: a closed citation-type
vocabulary and a machine-readable admissibility table, so *"a mocked-client test cannot discharge what
the deployment ACCEPTS"* becomes a lookup instead of an inference.

`CITATION_UNTYPED` is **P3, non-blocking** — every artifact downstream is untyped, so anything harsher
would brick every project on upgrade day.

### Observation exposure (#104)

`observe-guard.sh` is the counterpart `mutate-guard.sh` never had. Mutation proves a *test* can fail;
nothing proved an *observation* ever had the chance to — **a green reports its verdict, never its
exposure**, so confidence accumulates on run count rather than on chances to fail. It runs the
*shipped* invocation and diffs local flags against the container/deploy command (the scar: a bearer
token in a URL path segment was invisible locally under `--log-level warning` and reproduced in one
request under the image's own INFO default), and it asks what a green **licenses** — waiting is
harmless unexposed; closing a fire or writing REFUTED on a live credential is not.

### Graph, and #100's namespace question

The freshness leg reaches `gate_graph` without turning `/story-implement` into a mutating step, and
degrades on a read-only tree instead of raising. `MAPPED_UNWITNESSED` adoption is scoped per-epic, so
the first honest row a team fills does not cap the whole project — a gate whose entire cost lands on
the first step is a gate people route around. The graph's findings namespace is authoritative and any
project-level view derives from it, because a derived view cannot drift.

### Honest scope of the two new checks

`validate-two-carrier.sh` (#103) and `validate-evidence-citations.sh` (#101) **exist and are proven,
and are not yet on a gate path** — no hook, no CI step, no §6a row invokes them. They are usable by
hand today. Saying so plainly matters in a release line about gates that certify what they never
inspected.

`validate-two-carrier.sh` found a real instance on its first run: `validate-coverage-matrix.sh` pulled
`$10`/`$11` out of the cell-status grid by hard-coded position — the same shape that made §6a unsafe
to extend, and live in Speck's own tree while v10.1 was *adding two persona columns* that would have
shifted every field. It is header-resolved now. The test that pinned it has been retired into a frozen
fixture: an assertion naming a live defect as its expected value is #99's counter-test class, where
the suite holds the bug in place and the honest fix looks like the breaking change.

## v10.0.0 — 2026-08-02 — Evidence has to be evidence

Fourteen field-filed issues from three Speck-managed products (Streb, Brightstance, Splang)
collapsed into a handful of mechanisms, and two dominated:

**A gate that reports green having inspected nothing.** A lint whose terms could never match. A
`--staged` scan matching 0 of 1194 files. A schema probe printing `Found 0 database objects` and
exiting 0. A witness graph printing `GRAPH_CAP = SHIP` because someone deleted the file that caps it.

**A proof derived from prose the gated party wrote.** `serves` edges minted from any bare `MM-N`
token in a story body — 10 of 15 false in one project, 8 of them from sentences reading *"None
claimed"*. A verdict regex that matched negations, so *"MM-1 was NOT judged"* cleared the gate. A
Discharge cell reading *"OPEN — not discharged"* resolving promise conservation.

In every case the gate ran, passed, and was honest.

This release fixes the instances, lands the chokepoints, and — because it crosses a major — carries
the artifact changes on a real migration lane rather than deferring them.

> **The v9.6.0 work is included here.** It was developed and committed as 9.6.0 but never tagged;
> the version was folded into this major so the whole set ships behind one migration.

### ⚠️ What goes red on upgrade day — read this first

- **Your `.git/hooks/pre-commit` gates may have been dark, and this turns them on.** Speck appended
  its loader to the END of an existing hook. A hook from pre-commit.com, Husky v0.x, or any
  hand-rolled one ending in `exec …`/`exit 0` ends the shell process, so everything appended was
  structurally unreachable — chmod succeeded, the marker was in the file, and every commit-path gate
  was silently dark. The loader is now spliced immediately ABOVE the terminator. From your next sync,
  `validate-template.sh --strict`, `validate-profile.sh`, `speck_graph.py lint-refs` and the staged
  banned-language lint run for the first time. Expect them to have something to say. Escapes, in
  order: fix what they report · `git commit --no-verify` for one commit · move the gate into
  `.pre-commit-config.yaml` as a `repo: local` hook (the warning prints the YAML).
  **CRLF (Windows/WSL) hooks are rescued too** — `exec …\r` never matched the terminator scan, so
  those repos were 100% dark with no warning at all.
  Speck's block now runs LATER in your hook (above the terminator, not near the top), so it lands
  after your `export PATH`/nvm/asdf setup and after your own `SKIP_HOOKS` guard — your documented
  bypass now correctly exempts Speck's gates, which it previously did not.
- **A malformed `## 7. Banned Language` row now fails the full scan and CI.** The extractor split
  column 1 on `/` and `,` with no paren awareness, so `| "sett" (Norwegian for rep/set) |` became
  two unmatchable fragments. Both reported zero hits — indistinguishable from compliance; one project
  had 12 of 64 rows dead. An unmatchable term is now a **PARSE DEFECT**. Fix the row by balancing the
  parentheses. **Pre-commit is advisory for this**, so a typo'd row can never make your repo
  uncommittable — including the commit that fixes it.
- **Terms that were silently dead will start firing, on code nobody changed.** `"sett" (Norwegian for
  rep/set)` now extracts as the live term `sett`. Fix the copy, narrow the §7 row, or exclude the
  file via `banned_language.exclude`. Matching is a fixed string (`-F`) now, not a half-escaped
  regex, so a term like `C++` or `a|b` no longer behaves as one.
- **`speck_graph.py check` exits non-zero on a stale or corrupt witness**, and a corrupt or
  unreadable `witness.json` caps `GRAPH_CAP` at INTEGRATION-GREEN. Destroying the tamper-evidence
  artifact used to REMOVE the ceiling it exists to enforce. No Speck-shipped hook calls `check`, so
  no automated gate newly blocks — but if you wired it into CI, run `build` and commit the witness
  first. An ABSENT witness is a different fact: `GRAPH_UNBUILT.P3`, non-capping, so the v8→v9
  installed base is not demoted.
- **`--live --strict` on `validate-schema-drift.sh` now requires `--target`.** `--live` used to
  connect to whatever was ambient and was once measured emitting 32 confident `SCHEMA_DRIFT.P0` lines
  against an unrelated project's database. One-line CI fix:
  `--live --strict --target "$DATABASE_URL" .`. An UNPROVEN or SKIPPED run no longer reads as a pass.
- **Schema drift is now COLUMN and CONSTRAINT grain.** #64 G1 was filed, closed, and its repair
  shipped in v7.15 — then the class recurred six weeks later with database WRITES DESTROYED, because
  the probe inventoried objects while both divergences were a column and a constraint. The column
  that destroyed every write was `coaching_sessions.draft_id`. A project passing this gate since
  v7.15 can now report real drift; the finding names the table, the column, and the declaring
  migration file.
- **`serves` edges now come from story frontmatter, not prose.** Run
  `speck_graph.py migrate --lift-serves` — it DRY-RUNS by default and prints every current
  prose-derived edge with its source line, so you can see what would be asserted on your behalf
  before writing it. Registered on the v10 lane.
- **Promise conservation requires a structured token.** A Discharge, DEC or pilot-gated Backing cell
  carrying only prose no longer resolves a row. Find yours with:
  `bash .speck/scripts/validation/validators/validate-traceability-matrix.sh specs/projects/<id>`
- **Harden reports are structurally validated for the first time, at EVERY vintage.** The four base
  sections (`## 1. Defect Description` / `## 2. Root Cause Analysis` / `## 3. Remediations` /
  `## 4. Readiness Re-assessment`) are now required unconditionally — deliberate, and disclosed
  rather than vintage-gated, because those four headings have been byte-identical in the template
  since v7.13.0, so only a hand-written report that never followed the structure is convicted. Find
  affected files with:
  `grep -rLE '^## 1\. Defect Description' --include='*harden-report*.md' specs/`
- **`check-replace-markers.sh` catches genuine markers it used to miss** — one ending the line, or
  whose hint opens with a quote or backtick, on artifacts previously reported clean.
- **`--verify-receipt` is a gate now, not a suggestion.** `validate-template.sh` calls
  `mutate-guard.sh --verify-receipt` on every validation report and combines its exit code. Until
  now the cross-check had no caller outside SKILL.md prose — a rule stated in a skill cannot fail a
  build, which is the shape this release exists to remove. The adoption gradient is unchanged: a
  repo that never emitted a receipt degrades to `RECEIPT_MISSING.P2` at exit 0, and a report with no
  Mutation Record rows to `RECEIPT_NO_CITATIONS.P2` at exit 0. **Only a contradiction blocks** — a
  cited site whose pinned content does not recompute at the pinned SHA, or a claimed verdict
  stronger than the one recorded.
- **A report can no longer declare itself pre-v10 to escape the v10 rules.** Deleting
  `mutation_record: required` and the `## 2b.` heading used to drop a whole report to pre-v10
  vintage, turning every v10 rule into a NOTICE — findable in about a minute by anyone under a
  blocking pre-commit, and indistinguishable from an honest legacy artifact. Vintage is now DERIVED
  from the project's `.speck/VERSION` plus whether the file is untracked or modified, so a v10
  workspace produces v10 artifacts whatever the frontmatter claims. **Artifacts already on disk —
  tracked and unmodified — keep their self-declared vintage**, which is what keeps "no data
  migration needed" true. Editing and re-staging a legacy report brings it into scope.

### New — mutation as evidence (CP-6)

Three issues asked for "prove the guard actually fires" in three vocabularies. One primitive:

- **`mutate-guard.sh`** mutates in a THROWAWAY WORKTREE, so there is nothing to revert and an
  interrupted run cannot leave a mutated production file behind. It refuses a pattern that does not
  match exactly `--match-count` times, a comment or docstring, a test/fixture target, a byte-identical
  edit, an already-red target, and a run with no GREEN CONTROL — the control is what distinguishes
  "I broke the file" from "I hit the predicate".
- **`## 🧬 Mutation Record`** in the story and epic validation-report templates, and a Counter-Test
  sweep (§2b) plus Guardrail Mutation-Proof and Class Recurrence Check in the harden template.
  Verdicts: `GUARD_MUTATION_PROVEN` · `GUARD_MUTATION_GREEN.P2` · `GUARD_UNMUTATED.P2`.
- **`harden-report` is no longer exempt from structural validation.** It previously fell through
  `validate-template.sh` to `exit 0`, which meant any section these rules added was unenforceable
  prose by construction. That routing was the actual chokepoint.
- **KNOWN LIMIT, stated rather than implied:** the validator enforces that a verdict was RECORDED,
  not that a mutation was RUN. `--verify-receipt` cross-checks a receipt where one exists and
  degrades to `RECEIPT_MISSING.P2` (non-blocking) where it does not.

### New — `GATE_VACUOUS` (the third verdict)

v9-era §6a proved a gate was WIRED and LOAD-BEARING. Neither answers the third question: **did it
look at anything?** Gates now publish `SPECK_GATE_SCOPE` / `SUBJECT` / `PREDICATES` / `MODE` on every
exit path, §6a carries `Scope` and `Subject` columns, and `GATE_VACUOUS.P1` fires when a gate exits 0
having inspected an empty corpus over a non-empty scope — **or** having evaluated zero predicates.
Both dimensions are required: this family's vacuity is usually a dead predicate set, not an empty
subject set. A legitimately empty run (`GATE_EMPTY_LEGITIMATE`) is a note, never a finding.

### New — the migration lane

`registerMigration()` + a per-project applied ledger in `.speck/project.json`. Each migration runs at
most once, records after EACH step so a crash mid-run resumes, and a throw records `failed` (never
`applied`) so siblings continue and the id stays pending. `speck migrate --list/--run`, guarded on
workspace identity.

### New configuration

- **`banned_language.scope`** — `"any-depth"` is now the DEFAULT (a `src`/`app`/… directory is in
  scope wherever it sits, so a monorepo's `frontend/src/**` is finally reached; the old root-anchored
  globs matched 0 of 1194 tracked files in one repo and 0 of 590 in another). `"legacy-root"` restores
  the old behaviour. Carried by `v10-banned-language-scope-any-depth`.
- **`--strings-only`** (default) — §7 terms match locale VALUES and string literals / JSX text, never
  keys, identifiers, imports or comments. This is what made the scope default safe to flip: without
  it, Speck's own shipped phrase class `("our backend", "API", "database")` convicted
  `import { createClient } from "./api"`. Files the lexer cannot parse are reported in
  `SPECK_GATE_UNPARSED` rather than silently scanned whole or silently skipped.
- **`banned_language.exclude`** (array, additive), **`exclude_defaults`** (bool), `--exclude-glob`,
  and `--advisory-parse-defects` (implied by `--staged`).

### Gates that stop lying — no action needed

- **A fully-filled `evidence-contract.md` or `product-contract.md` passes validation for the first
  time.** Both validators ran an unanchored `grep -q "REPLACE_BEFORE_SHIP"` matching the bare word
  inside those artifacts' OWN convention prose — and since `pre-commit-hook.sh` routes staged specs
  through `validate-template.sh --strict`, projects reached a state where **Speck's own generated
  output could not be committed**.
- **`[NEEDS USER REVIEW]` is no longer rejected as scaffold residue** — a marker Speck's own templates
  mandate agents emit. The allowlist now lives in one file read by both sides.
- **The banned-language verdict no longer depends on whether ripgrep is installed.** `rg --files`
  honours `.gitignore` and `find` did not — the same tree scored exit 0 with rg and exit 1 without it.
- **Build caches and binaries are never scanned.** A dot-directory is refused as a scope root under
  any-depth (an `android/app/.cxx/**` cache produced 58 convictions on compiled `.o` files), and
  binary matches — which carry no line number, so the visibility mask provably cannot reach them —
  are dropped.
- **Speck's own machinery, vendored trees and test files are excluded** — `.speck`, `specs`, `.venv`,
  `Pods`, `target`, `DerivedData`, `.gradle`, `coverage`, and language-agnostic test globs, because a
  vocabulary guard whose regex literals ARE the banned words must not be convicted by the gate it
  protects.
- **A `>10`-hit term no longer aborts the run** (SIGPIPE under `pipefail` killed it at 141 with every
  remaining term unscanned).
- **A §6a Domain like `backend-tests` now matches its canary.** BSD `tr` parsed the leading `-` of
  `tr '-_ '` as an option and died, so the domain split produced nothing and THE CANARY NEVER RAN.
  Failed closed, which is why it survived — the symptom was a cap nobody traced to a quoting bug.
- **Speck read the wrong version for any workspace whose path contains an apostrophe**, and
  `.speck/VERSION` is now authoritative over `project.json`'s advisory `speck_version` — `migrate.sh`
  wrote a hardcoded `7.0.0` there and nothing updated it, so `detect-version.sh` reported **7.0.0 for
  a workspace on 9.5.0**.
- **`validate-visual-assets.sh`**: WebP assets could never pass on macOS (BSD `od` through
  `cut -d' '` truncated the signature), and a single apostrophe anywhere on a manifest row made
  `xargs` exit on an unterminated quote and `set -e` kill the validator — 7 of 23 `ui-spec.md` files
  in one project failed strict validation for that reason alone.
- **`validate-felt-axis.sh` / `validate-taste-axis.sh`** required a parenthetical axis list, rejecting
  a template-conformant `## 🧭 Four-Axis Readiness` at the FIRST check so no real assertion was
  reached. Both files' own comments called the match "loose"; the regex disagreed.

### New — learned patterns, and four probe extractions

`.speck/patterns/learned/testing/` was a directory Speck created and never filled. It now carries
**#100's six class-gate recipes**, each as mechanism → tell → gate shape → **bounding exception** —
the exception is not optional, because #93 and #100 are both explicit that several of these repairs
are wrong applied universally, and a pattern file that drops its boundary gets applied by an agent
that cannot see one. The **mirror sweep** ships alongside them: grep the *shape*, not the symbol that
happened to be wrong.

From **#101**, the four increments that are implementable today (its §11a registry stays an open
design question — `PROBE_SUBSTRATE_MISMATCH.P1` cannot be computed from a `path@sha` string carrying
no type):

- A **claim-type admissibility axis** in the evidence contract. §2 was indexed by PLATFORM and never
  by CLAIM TYPE, so nothing said that a green mutation-verified suite is inadmissible for *"what can
  this principal SEE"*, or that a props-level a11y assertion is inadmissible for *"does it fit"*.
- Two missing personas — **`second-actor`** and `impatient`. #84's set is consumer breadth: one
  identity in many states. None of its personas is a second ACTOR, which makes identity and tenancy
  defects as invisible to it as to a single-user suite. `second-actor` is the persona that would have
  caught the cross-user write.
- An **`entitlement-gate.canary`**, riding the shipped #88 machinery.
- A **post-merge semantic gate** for parallel execution. #68.1 prevents an Alembic head collision at
  plan time and has no gate that catches one after a merge — its framing is that a git-clean merge is
  clean. Two heads arrived from a git-clean merge six weeks after #68 closed.

### New — `.speck/scripts/lib/text.sh`

Five defects across four validators were one class: a bash text idiom used for structured-data work
without accounting for `set -euo pipefail`. `sp_trim` (no `xargs` — it does shell QUOTE PROCESSING,
crashing on an apostrophe and silently stripping quotes on the success path), `sp_head` (never
SIGPIPEs), `sp_split_toplevel` (paren-aware), `sp_parens_balanced` (the dead-term tell),
`sp_match_exact` (so `table:order` cannot false-PASS against `table:orders`).

### Tests

+11 suites wired into `npm test`, several for scripts that had never had one. `scaffold-clean.test.sh`
builds a project from the current templates verbatim and asserts every shipped scanner returns zero
findings — **paired with a negative control**, because a scaffold-clean assertion alone is passed by a
scanner that over-excludes. Hook reachability is asserted BY EXECUTION, not by grepping for the
marker; a grep passes on exactly the dead-block case it fixes. `version-parity.test.js` fails when a
`*.test.sh` exists but is not in the chain, and runs LAST so it can never suppress the suites it
asserts about.

Three control points that shipped unpinned are pinned now: `GATE_MODE` (the exemption KEY — mutating
`live`→`notice` left both suites green, which would let a `--live` run evaluating zero predicates be
excused as legitimate), `gate_registry_separator()` (a hardcoded separator silently yields a 7-column
header over a 6-column separator), and **the canary library itself** — deleting any `.canary` file
left every suite in the repo green, so the library that exists to prove gates are load-bearing was
not itself load-bearing.

One portability bug worth naming because it would have fired on someone else's machine, not ours: a
mutation assertion pinned the literal stderr `awk: not enough args in printf`, which is BSD awk. Under
**mawk** — the Debian/Ubuntu default — a short printf prints empty fields and exits 0, so the
assertion would have gone RED against a perfectly correct producer. Re-asserted on column count.

`validate-template.sh` now prints ONE final verdict on the readiness-evidence branch. Combining exit
codes meant a green `✅ Validation PASSED` from one sub-check could sit directly above a blocking
`RECEIPT_MISMATCH.P1` from the next — the exit code was right and the finding was printed, but the
last words on the log said the opposite.

Cross-repo acceptance vs v9.5.0 across five real projects: no green→red flip. npm test green.

## v9.6.0 — folded into v10.0.0 (never tagged)

Fourteen field-filed issues from three Speck-managed products collapsed into a handful of
mechanisms, and the same one dominated: **a gate that reports green having inspected nothing.**
A lint whose terms could never match. A `--staged` scan matching 0 of 1194 files. A schema probe
printing `Found 0 database objects` and exiting 0. A witness graph printing `GRAPH_CAP = SHIP`
because someone deleted the file that caps it. In every case the gate ran, passed, and was honest.

This release fixes the instances **and** lands the chokepoints — one shared text library, one
telemetry contract, and the first tests several of these scripts have ever had.

Everything here is script-side. Nothing requires a downstream artifact to change: a v9.x minor
runs no migration (`detectMigration()` keys off the major), so anything needing artifact changes —
the §6a `Scope`/`Subject` columns, the `GATE_VACUOUS` verdict, structured `serves:` frontmatter,
the mutation-record slot — is deferred to v10, where a real migration can carry it.

### ⚠️ What goes red on upgrade day — read this first

- **Your `.git/hooks/pre-commit` gates may have been dark, and this turns them on.** Speck appended
  its loader to the END of an existing hook. A hook from pre-commit.com, Husky v0.x, or any hand-rolled
  one ending in `exec …`/`exit 0` ends the shell process, so everything appended was structurally
  unreachable — chmod succeeded, the marker was in the file, and every commit-path gate was silently
  dark. The loader is now spliced immediately ABOVE the terminator. From your next sync,
  `validate-template.sh --strict`, `validate-profile.sh`, `speck_graph.py lint-refs` and the staged
  banned-language lint run for the first time. Expect them to have something to say. Escapes, in order:
  fix what they report · `git commit --no-verify` for one commit · move the gate into
  `.pre-commit-config.yaml` as a `repo: local` hook (the warning prints the YAML).
- **CRLF (Windows/WSL) hooks are rescued too**, with the same consequence — `exec …\r` never matched
  the terminator scan, so those repos were 100% dark with no warning at all.
- **Speck's block now runs LATER in your hook.** Inserted above the terminator rather than near the top,
  so it lands after your `export PATH`/nvm/asdf setup and after your own `if [ -n "$SKIP_HOOKS" ]; then
  exit 0; fi` guard. Your documented bypass now correctly exempts Speck's gates — it previously did not,
  and with `|| exit $?` Speck would block a commit you had deliberately exempted.
- **A malformed `## 7. Banned Language` row now fails the full scan and CI.** The extractor split column 1
  on `/` and `,` with no paren awareness, so `| "sett" (Norwegian for rep/set) |` became two unmatchable
  fragments. Both reported zero hits — indistinguishable from compliance; one project had 12 of 64 rows
  dead. An unmatchable term is now a **PARSE DEFECT**: `🧨 1 §7 term(s) can NEVER match`, exit 1. Fix the
  row by balancing the parentheses. **Pre-commit is advisory for this** (`--staged` implies the new
  `--advisory-parse-defects`), so a typo'd row can never make your repo uncommittable — including the
  commit that fixes it.
- **Terms that were silently dead will start firing, on code nobody changed.** The same fix means
  `"sett" (Norwegian for rep/set)` now extracts as the live term `sett`. Measured: HEAD exit 0 →
  v9.6 `❌ "sett" — 1 hit(s)`, exit 1. Fix the copy, narrow the §7 row, or exclude the file via
  `banned_language.exclude`. Terms appearing in both the §7 table and the Banned Phrase Classes list
  are now deduplicated (+16 phantom hits on one project's total).
- **Matching is a fixed string (`-F`) now, not a half-escaped regex.** The old hand-rolled `sed` escape
  left `]`, `-` and others live, so `C++` or `a|b` behaved as a regex.
- **`speck_graph.py check` exits non-zero on a stale or corrupt witness.** It returned 0 before, so
  `build && check` chains read a 142-commits-behind witness as a pass. No Speck-shipped hook calls
  `check`, so no automated Speck gate newly blocks — but if you wired it into your own CI, run `build`
  and commit the witness first. It now prints `GRAPH_CAP = STALE` rather than a number: a report about a
  different tree has no cap worth quoting onward.
- **A corrupt or unreadable `witness.json` caps GRAPH_CAP at INTEGRATION-GREEN.** Destroying the
  tamper-evidence artifact used to REMOVE the ceiling it exists to enforce — `check`, `gap` and the
  written `road-to-completion.md` all printed `SHIP` next to the warning.
- **`--live --strict` on `validate-schema-drift.sh` now requires `--target`.** `--live` used to connect
  to whatever was ambient and was once measured emitting 32 confident `SCHEMA_DRIFT.P0` lines against an
  unrelated project's database. One-line CI fix: `--live --strict --target "$DATABASE_URL" .`. The live
  leg is psql-only now.
- **An UNPROVEN or SKIPPED schema-drift run no longer reads as a pass.** Three-valued verdict —
  VERIFIED / UNPROVEN / SKIPPED. Under `--strict`, UNPROVEN and "asked for `--live`, got SKIPPED" both
  exit 1. The unconditional `✅ Schema verification complete.` line is gone.
- **check-replace-markers.sh catches genuine markers it used to miss.** A marker ending the line, or whose
  hint opens with a quote or backtick, is now correctly caught — on artifacts previously reported clean.

### New configuration

- **`banned_language.scope`** (`.speck/project.json`) — `"legacy-root"` (**default**: product surfaces
  recognised only at the repo root, exactly as ≤9.5) or `"any-depth"` (a `src`/`app`/`pages`/… directory
  is in scope wherever it sits, so a monorepo's `frontend/src/**` is reached). **Monorepos should opt in**
  — measured, the root-anchored globs matched 0 of 1194 tracked files in one repo and 0 of 590 in another,
  so the commit-path gate was always-green. An unrecognised value warns and falls back rather than failing
  the gate. Note: under `legacy-root`, a repo with no root-level product directory still falls back to
  scanning the whole workspace minus the deny list — pre-existing behaviour, unchanged, not something
  `scope` defuses.
  *Why opt-in and not the default:* combined with whole-file scanning it convicts ordinary code using
  Speck's OWN shipped phrase class `❌ Technical architecture language ("our backend", "API", "database")`.
  A `frontend/src/lib/client.ts` holding `import { createClient } from "./api"` goes from exit 0 to two
  hits. Flipping the default is a v10 item, gated on a user-visible-string filter landing first.
- **`banned_language.exclude`** (array, additive) and **`banned_language.exclude_defaults`** (bool), plus
  a repeatable **`--exclude-glob`**.
- **`--advisory-parse-defects`** — report an unmatchable §7 term but exit 0. Implied by `--staged`.

### Gates that stop lying — no action needed

- **A fully-filled `evidence-contract.md` or `product-contract.md` passes validation for the first time.**
  Both validators ran an unanchored `grep -q "REPLACE_BEFORE_SHIP"` matching the bare word inside those
  artifacts' own PLACEHOLDER CONVENTION prose, so a correctly-completed artifact still failed — and since
  `pre-commit-hook.sh` routes staged specs through `validate-template.sh --strict`, projects reached a
  state where **Speck's own generated output could not be committed**. Both now delegate to
  `check-replace-markers.sh` instead of keeping a second, independently-buggy copy of the rule.
- **`[NEEDS USER REVIEW]` is no longer rejected as scaffold residue** — a marker Speck's own templates
  mandate agents emit, and which `project-state-template.md` greps for to build a section. The allowlist
  lives in one shared file, `.speck/scripts/lib/sanctioned-markers.txt`, read rather than duplicated, so
  emitter and rejecter cannot drift apart again.
- **`check-replace-markers.sh` no longer convicts Speck's own template text** — `project-state-template.md`'s
  permanently-required "Outstanding REPLACE_BEFORE_SHIP markers" section produced 3 permanent,
  un-clearable hits in every scaffolded project. Citations are recognised structurally; the fenced-code
  exemption is scoped to shell fences only, so a genuine marker in a YAML fence is still caught.
- **The banned-language verdict no longer depends on whether ripgrep is installed.** `rg --files` honours
  `.gitignore` and `find` did not — the same tree scored exit 0 with rg and exit 1 without it. The fallback
  now drops VCS-ignored files via `git check-ignore` (which consults the index, so tracked files are never
  dropped). Aligned fallback→rg deliberately: that direction can only remove files from a scan, so it
  cannot turn a green repo red.
- **Speck's own machinery, vendored trees and test files are no longer scanned.** `.speck`, `specs`,
  `.cursor`, `.venv`, `venv`, `.tox`, `Pods`, `target`, `.build`, `DerivedData`, `.gradle`, `coverage`
  join the deny list — the fallback scan reported 4025 hits for `plan` on one repo, top hits being Speck's
  own templates. Default test exclusions are language-agnostic now (`**/test_*.py`, `**/tests.py`,
  `**/*_test.*`, `**/*Test.*`, `**/*_spec.*`, `**/tests/**`, `**/spec/**`, `**/__mocks__/**`, `**/e2e/**`),
  because a vocabulary guard whose regex literals ARE the banned words must not be convicted by the gate
  it protects — and Speck ships django-htmx, go-templ-htmx and expo-fastapi recipes, not just JS/TS.
- **A `>10`-hit term no longer aborts the run.** `echo "$out" | head -n 10` SIGPIPEs the producer and,
  under `set -o pipefail`, killed the run at 141 with every remaining term unscanned.
- **An ABSENT `witness.json` is no longer reported as GRAPH_STALE.** It gets its own honest, non-capping
  code, `GRAPH_UNBUILT.P3`. Two absences, two facts: a destroyed witness is tampering and caps; a
  never-built one just needs `build`. Every project migrating from v8 has no witness on upgrade day, and
  capping them would have demoted the whole installed base on a minor bump.
- **`/epic-validate` and `/story-validate` stop letting the schema-parity row be ticked without evidence.**
  The instruction said `--strict`, which never asks the live leg to run — reporting SKIPPED and exiting 0
  while the template lets the agent check "Live DB schema matches migrations" as a pass.
- **Speck read the wrong version for any workspace whose path contains an apostrophe** —
  `.speck/project.json` was read by interpolating the path into Python source, so the read died on a
  SyntaxError that `2>/dev/null` swallowed. Separately, **`.speck/VERSION` is now authoritative** and
  `project.json`'s `speck_version` advisory: `migrate.sh` wrote a hardcoded `7.0.0` there and nothing ever
  updated it, so `detect-version.sh` reported **7.0.0 for a workspace on 9.5.0** while `profile-lib.sh`
  reported 9.5.0 for the same repo. Disagreement now warns loudly.
- **Every banned-language and schema-drift exit path publishes `SPECK_GATE_SCOPE` / `SPECK_GATE_SUBJECT` /
  `SPECK_GATE_PREDICATES`,** so a caller can tell a real green from a vacuous one without parsing prose.
  The lint also prints term health — `evaluated · fired · zero-hit (compliant) · could not match` —
  because zero hits is only evidence when the term COULD have matched. `PREDICATES` is load-bearing: this
  gate's vacuity is a dead predicate set, not an empty subject set.
- **`validate-visual-assets.sh`**: WebP assets could never pass on macOS (BSD `od` piped through
  `cut -d' '`, which does not collapse repeated delimiters, truncated the signature to `52`). And a single
  apostrophe anywhere on a manifest row — even in an uncaptured column — made `xargs` exit on an
  unterminated quote and `set -e` kill the validator. Measured: 7 of 23 `ui-spec.md` files in one project
  failed strict validation for that reason alone.
- **`validate-felt-axis.sh` / `validate-taste-axis.sh`** accepted `## 🧭 Four-Axis Readiness` only with a
  parenthetical axis list, rejecting a template-conformant header at the FIRST check so no real assertion
  was ever reached. Both files' own comments called the match "loose"; the regex disagreed.

### New — `.speck/scripts/lib/text.sh`

Five defects across four validators were one class: a bash text idiom used for structured-data work
without accounting for `set -euo pipefail`. The idioms now live in one tested library —
`sp_trim` (no `xargs`, which does shell QUOTE PROCESSING and both crashes on an apostrophe and silently
strips quotes/unescapes backslashes on the success path), `sp_head` (never SIGPIPEs its producer),
`sp_split_toplevel` (paren- and quote-aware), `sp_strip_qualifier`, `sp_strip_decoration`,
`sp_normalize_term`, `sp_parens_balanced` (the dead-term tell), `sp_match_exact` (fixed-string
whole-line, so `table:order` cannot false-PASS against a catalog holding only `table:orders`).

### Tests

+7 suites wired into `npm test`, several for scripts that had never had one: `lib/text.test.sh`,
`detect-version.test.sh`, `check-replace-markers.test.sh`, `validation/scaffold-clean.test.sh`,
`validate-visual-assets.test.sh`, `validate-schema-drift.test.sh`, `sync.hooks.test.js`.

`scaffold-clean.test.sh` is the one that ends the class: it builds a project from the current templates
verbatim and asserts every shipped scanner returns zero findings — **paired with a negative control**,
because a scaffold-clean assertion alone is passed by a scanner that over-excludes and certifies nothing.
Hook reachability is asserted BY EXECUTION, not by grepping for the marker; a grep passes on exactly the
dead-block case it fixes. npm test green.

## v9.5.0 — 2026-07-21 — Per-harness agent tiering (decoupled, generated)

`speck-*` agents are now tiered by role and generated per harness, replacing the symlink layout
that was invalid for two of three runtimes.

- **Model-tiering doctrine** — every agent is assigned a `tier` (frontier / mid / mechanical) by
  role: frontier only at decomposition, design, and the adversarial audit (`speck-architect`,
  `speck-planner`, `speck-auditor`) — never cheaping the planner or the auditor. Rationale: once a
  frontier planner collapses ambiguity into an explicit spec cheap workers just follow, but a weak
  spec taxes the whole worker fleet (Cursor agent-swarm economics — same 100% result at 8× lower
  cost with a frontier planner + cheap workers).
- **Per-harness generation** — the source of truth is `.cursor/agents/*.md` (`tier:` field + role
  body); `generate-agents.js` derives every model and stamps three real files:
  `.claude/agents/*.md` (`opus`/`sonnet`/`haiku`), `.cursor/agents/*.md`
  (`claude-opus-4-8-thinking-high` / `composer-2.5`), `.codex/agents/*.toml` (`gpt-5.6-sol` /
  `-terra` / `-luna` + `developer_instructions`). Each harness reads its own grammar + model
  vocabulary — the old `.claude`/`.codex` symlinks into `.cursor` were invalid (Cursor has no bare
  aliases and no Sonnet/Haiku; Codex reads TOML, not markdown, so the `.codex` symlink was
  non-functional). Model maps verified against `cursor-agent --list-models` + Codex smoke tests.
- **sync.js** — agents are copied as real per-harness dirs (`ALWAYS_OVERWRITE` + preserve); skills
  stay symlinked. Legacy agent symlinks are safely unlinked (never followed) on upgrade.
- **Enforcement** — `agent-model-tiers.test.js` (tier↔role + generated-in-sync-with-source, fail
  loud on hand-edit) and `sync.agents-decouple.test.js` (the symlink→real-dir migration).
  Regenerate after editing source with `npm run gen-agents`.

+8 tests (agent tiering + decouple migration). npm test green.

## v9.4.0 — 2026-07-21 — Verdict extraction → the real `UNJUDGED_SURFACE` gate

The IS-IT-GOOD machinery becomes graph-visible: `UNJUDGED_SURFACE` turns from an honest pending note
into a **computed gate** — without crossing the anti-rubber-stamp line.

- **Verdict extraction** — the extractor scans each story's validation artifacts (`validation-report.md`,
  `connoisseur-critique.md`, `larp-recordings/*findings*.md`) for a magic-moment reference within reach
  of an explicit verdict token (`GOOD`/`BAD`/`PASS`/`FAIL`/`✅`/`❌`/`scored`/`judged`) → a `verdict` node
  + a `judges` edge to the `MM-N` (normalizing `MM3` → `MM-3`).
- **`UNJUDGED_SURFACE.P2`** — every promised `MM-N` must have a recorded verdict. Migration-aware: if no
  MM anywhere is judged yet, LARP simply hasn't run → honest cap (not a block); once any MM is judged, an
  unjudged MM caps `ux-rc+` (the `/epic-validate` gate blocks the transition on it).
- **The anti-rubber-stamp line holds exactly:** the graph proves a verdict *was recorded* (the machinery
  ran), never that it is *honest* — a recorded **BAD** verdict still counts as judged; the honesty of the
  verdict stays owned by `/audit` + the LARP. So an agent can't dodge the gate with a bare token without
  the adversary catching a fabricated one.
- `gap` now reports real `MM:<judged>/<total>·judged`; the "pending v9.4" placeholder is gone. Only
  `ORPHAN_CODE` remains honestly not-evaluated (needs tests-as-join, v9.5 / v10).

+2 tests (34 total). npm test green.

## v9.3.0 — 2026-07-21 — Conservation, cycles, cascade in the graph (retire-ready, parity-proven)

The graph now *independently* enforces the checks the bespoke validators own — the prerequisite for
retiring them. Parity-gated per Kjetil's "delete only on proof" call.

- **`UNMAPPED_PROMISE.P1`** — the conservation anti-join (graph form of `validate-traceability-matrix.sh`'s
  default-mode open-row check): once an epic has `epic-breakdown.md`, every PRM must resolve (discharge
  edge / DEC / pilot-gated). Resolution is judged by **edge presence or terminal status**, so a `mapped`
  row (assigned, pending) passes and only a truly-`open` row flags — **parity-proven = the script's set
  (0 on Streb, 0 on Splang; 1 on a synthetic open row)**. Pre-breakdown open rows are guided, not blocked.
- **`DEP_CYCLE.P1`** — a circular `depends_on` has no valid build order; detected via DFS.
- **`cascade` query** (`speck_graph.py cascade <dir> --dec DEC-NNNN`) — reverse-reachability to the
  still-`discharged` promises a (superseded) DEC descopes: the graph form of `compute-cascade.sh`'s DEC half.
- **Real subtraction:** recheck's redundant per-epic `validate-traceability-matrix.sh` default-mode run is
  folded into the single graph `check` (which now covers conservation + link rot + phantom + cycle).

**Honest retirement status — no file deleted yet, on purpose.** The parity work surfaced two real blockers:
`validate-traceability-matrix.sh` interleaves conservation with the v8.5 grain **teeth** (BLOCK enforcement
the graph doesn't yet own → the file shrinks, can't delete, until the v9.4 grain-gate); `compute-cascade.sh`
also handles contract-section cascades the graph doesn't model. The graph is *retire-ready*; the deletions
land when each blocker clears. Deleting either now would strip a live safety check — parity-proven-delete
means we don't. +3 tests (32 total). npm test green.

## v9.2.0 — 2026-07-20 — Drive to done: `gap` + native `/goal` (leverage, don't reimplement)

The fourth motion — DRIVE — that closes Promise→Build→Prove into a self-terminating loop toward
*actual* 100%. Speck does **not** reimplement `/goal`'s loop (native `/goal` is Claude Code's
prompt-Stop-hook / Codex's thread-scoped goal); it supplies the three things native `/goal` can't
compute, and directs the user to run `/goal` (a client command a skill cannot invoke for you):

- **`speck_graph.py gap <dir>`** — folds the structural remainder (`check_graph`) + validation-report
  axis frontmatter (`felt_axis`/`taste_axis`/`readiness`) + magic/JTBD into ONE evaluator-legible
  `SPECK-GAP:` line (the evaluator reads only surfaced text and runs no tools). Terminates on
  `SPECK-GAP: none`. Axis extraction is best-effort + honest — reports without the frontmatter count as
  uncovered, never silently passed.
- **`speck_graph.py gap <dir> --emit-goal [--target ship-rc|ship]`** — prints a ready-to-run `/goal …`
  completion condition using Codex's six components (outcome · verification surface · constraints ·
  boundaries · iteration policy · blocked-stop), with anti-gaming baked in: the success token must be
  literal `gap` stdout, `GRAPH_STALE` catches a hand-edited witness.json, and every gate stays authoritative.
- **AGENTS.md "Drive to Done"** section: the routing table (gap item → owning skill) + the hierarchy
  (`/goal` = conductor/loop; Speck skills = players/work; the graph = score/condition+evidence).
  User-initiated with a mandatory turn bound; STOP-BLOCKED at owner-gated inches (taste forks, contract
  pivots, price, deploy). Full workflow/sequence in `docs/history/north-stars/v9.md` §6.

+2 tests (29 total). npm test green. (MM "judged" stays honestly pending verdict extraction, v9.4.)

## v9.1.0 — 2026-07-20 — The road to completion (the graph, re-projected)

`speck_graph.py road <dir>` → `specs/projects/<id>/graph/road-to-completion.md`: the graph's findings
re-projected into four **ordered** buckets whose sequence *is* the dependency order —
**🧹 TIDY** (stale/unmigrated/dangling/dup — messy but correct, make it legible) →
**🗑 REMOVE** (orphans — don't build on them; deletion is always a separate human gesture) →
**🔨 BUILD** (phantom promises, orphan stories — make what the contract promised) →
**🔬 PROVE** (unjudged surfaces, `[pre-v9-proof]` caps, grain deficits — climb to the ceiling).
Header carries `GRAPH_CAP`, the blocking-`.P1` count, and the single next action; each row is
`{item · where · gate-code · resolve-with-skill}`. This is Kjetil's "perfect road to completion" — any
project, any state, gets a crystal-clear worklist of what to tidy, remove, build, and prove.

DERIVED + disposable: the road carries a never-hand-edit banner and the `GRAPH_STALE` law applies to
itself (a road disagreeing with a fresh compile is stale — regenerate, don't patch), so it never becomes
a ninth authored copy. Pending gates (`ORPHAN_CODE`, `UNJUDGED_SURFACE`) render as honest lines, never
false-clean. `/speck-graph-up` Phase 4 emits it. +2 tests (27 total). npm test green.

> Sequencing note: the road (this arc) ships before the retire-and-prove deletions — those land in a
> following minor after the byte-parity tests on Streb + Splang pass. Additive-first, delete-on-proof.

## v9.0.0 — 2026-07-20 — The Witness Graph is the Spine (major)

v9 promotes the witness graph from a late gate into the project's **spine** — the derived,
content-hashed index that project-state renders from, that the forcing gates fire off, that
`road-to-completion.md` re-projects, and that native `/goal` drives against to reach *actual* 100%.
Full architecture (incl. the `/goal` workflow, hierarchy, and sequence): `docs/history/north-stars/v9.md`.
Shipping incrementally (v9.0 → v9.5); this is the **additive spine + forcing** arc — no deletions yet.

### Forcing: "you cannot advance if the graph lacks what it needs" — without bricking greenfield
One signal makes it safe: **id-scheme adoption**, counted from the graph (never asserted). Rot in an
*adopted* scope BLOCKS (`.P1`); the **identical** structural absence in an *un-adopted* scope GUIDES
(a cap), never blocks. Same missing structure = a wall for a rotted project, a guide-rail for a fresh one.

- New scoped forcing primitive: `speck_graph.py gate <dir> [--story ID | --epic ID]` (exit 1 = blocked),
  with a **reachability** check — a story must trace UP to a promise (a PRM discharges to it, or it serves
  an `MM-N`/`JOB-N`) once its epic has adopted a promise ledger. An orphan specified-but-unwired story
  raises `ORPHAN_STORY.P1`. Proven on Streb + Splang.
- Wired at the boundaries (all python3-guarded; absent → WARN + proceed, CI is the backstop):
  **First Actions step 0** (`build && check`; a hard `.P1` → "repair the graph first", `GRAPH_CAP` caps
  the session); **`check-story-prereqs.sh`** (the reachability gate before implementation);
  **`pre-commit-hook.sh`** (rejects a staged spec edit that introduces a dangling ref against an adopted
  scheme — you cannot commit rot in). The epic-validate step-5d gate shipped in v8.8.

### Migration: `.v9-graph-needed` marker + `/speck-graph-up` (heal the road already walked)
- `migrate.js` gains chain-aware `graphV9` detection (a v6→v9 jump runs scaffoldV7 → reproveV8 → graphV9
  in dependency order) + `writeV9GraphMarker` (`.speck/.v9-graph-needed`), the v9 analog of the v8-reprove
  marker. An engagement with the marker present refuses feature work until the graph is established.
- New `/speck-graph-up` skill: Phase 0 chain-preflight (catch-up/reprove first) → 1 harden identity
  (`migrate --apply`, resolve lint-refs) → 2 build → 3 **retroactive cleanup** (dry-run-first reconcilers:
  version-as-staleness `[pre-v9-proof]` caps, matrix-grain reconcile, prose↔canonical readiness render,
  un-graded re-grade — heal stale digests + over-claimed matrices) → 4 emit road + render project-state
  from the graph → 5 finalize. Any project, any state, ends with an excellent graph and a legible road.

### Also
- +3 forcing tests (25 total) in the graph suite; +5 migrate tests (13 total) for `graphV9` /
  `writeV9GraphMarker`. `docs/history/north-stars/v9.md` is the canonical v9 record. AGENTS.md banner → v9 with
  the graph-spine + `/goal` doctrine. `npm test` green.

### Roadmap (each a committed, parity-gated arc)
- **v9.1** retire-and-prove: delete `compute-cascade.sh` + the traceability conservation branch after a
  byte-parity test on Streb + Splang; CI asserts the bespoke-validator count drops.
- **v9.2** `speck_graph.py road` + project-state renders from the graph (kills digest-rot).
- **v9.3** `speck_graph.py gap --emit-goal` + the `/goal` drive doctrine + the thin `/speck-goal` primer.
- **v9.4** verdict extraction → real `UNJUDGED_SURFACE`; grain teeth migrate off the last parser.
- **v9.5** tests-as-join → real `ORPHAN_CODE` (honestly not-evaluated until then).

## v8.8.0 — 2026-07-20 — Witness Graph Phase 2–3: agent queries + the forcing gates, wired into the lifecycle

Builds on v8.7.0's identity + extractor. Turns the graph from a linter into the **first-class forcing
function** Kjetil specified — loud where things aren't traced right, and a genuine context-assembly
engine — while holding the anti-rubber-stamp law: it proves `traceable · complete · fresh` and never
certifies `faithful · good · excellent` (those stay owned by the four-axis LARP + `/audit`; the graph
*feeds* the adversary, it never replaces judgment).

### Agent-facing queries — the fix for Speck's named failure mode ("not having the right context")
- `query <PROJECT_DIR> <node-id>` — a node's raw in/out edges (story, `MM-N`, `PRM`, `DEC`, `AC-N`).
- `context <PROJECT_DIR> <story-id>` — the story's **context pack in one lookup**, replacing a
  seven-file tree walk: promises discharged (PRM + source `MM-N`/`JOB-N`/`FR`), magic moments served,
  `AC-N` anchors, `depends_on`/`blocks`, and the DECs constraining its epic. Wired into
  `/story-implement` pickup.

### The forcing gates — `check <PROJECT_DIR>` (caps or blocks; NEVER grants)
- **BLOCK (P1):** `DANGLING_REF` (discharge/dep → non-existent story or `AC-N`), `DUP_ID` (two story
  dirs sharing an S-number in one epic), `PHANTOM_PROMISE` (an `MM-N`/`JOB-N` the contract promises but
  no story delivers — "build the right thing").
- **CAP (fold into MAX-claimable, like `MATRIX_GRAIN_CAP`):** `GRAPH_UNMIGRATED.P3` (un-adopted id
  scheme), `GRAPH_STALE.P2` (committed `witness.json` ≠ a fresh compile — freshness is computed, never
  asserted). `GRAPH_CAP` caps an un-migrated/stale graph at `INTEGRATION-GREEN`.
- **NOT-evaluated, never a pass:** `ORPHAN_CODE` (pending tests-as-join, P5) and `UNJUDGED_SURFACE`
  (pending verdict extraction) are reported as honest pending — the graph refuses to rubber-stamp what
  it cannot yet prove.

### Wired into the lifecycle (a forcing function nothing calls isn't one)
- `/epic-validate` step 5d: `build` + `check`; P1 findings block the readiness transition, `GRAPH_CAP`
  folds into MAX-claimable (same idiom as gate-liveness / grain teeth).
- `/recheck` step 2: `lint-refs` as a parallel drift detector (`DANGLING_REF.P1` / `DUP_ID.P1` /
  advisory `GRAPH_UNMIGRATED.P3`) — structural link rot invisible to prose scans.
- `AGENTS.md`: the witness graph is now a documented Context-Rot Defense + canonical `graph/` artifact;
  qualified-id naming reconciled to field reality (dir-basename epics, ordinal shorthand).

### Also
- +5 hostile assertions (query, context, phantom-promise block, no-rubber-stamp, fully-served clear) —
  15 total, wired into `npm test`. Design status updated in `docs/graph/witness-graph-design.md`.

## v8.7.0 — 2026-07-20 — Witness Graph Phase 1: identity hardening + the dangling-reference gate

The first arc of the **Speck Witness Graph** — a DERIVED, tamper-evident graph of everything Speck
traces (design: `docs/graph/witness-graph-design.md`). Speck v8 already *was* a knowledge graph (~35
edge types, ~138 instances), but stored as prose and enforced by ~30 bespoke regex-parsers whose
entire scar history (#76.3/#83/#85/#87) is format-drift bugs. Half the edges have teeth; the other
half — every id and name — is free text string-matched across 3–6 artifacts with no resolver. The
graph is compiled from the markdown (never hand-authored), so to fake an edge you must fake the
reality it is extracted from: **automatic derivation is the precondition for a loud, un-gameable
forcing function.** It proves `traceable · complete · fresh`; it never claims `faithful · good` —
those stay owned by `/audit`, LARP, and the canaries (the anti-rubber-stamp law).

### Identity model (the prerequisite — extraction over ambiguous keys yields a confidently-wrong graph)
- **`AC-N` is now a real, resolvable anchor** — defined in the story template §2b (each acceptance
  scenario is `#### AC-N — <name>`). The conservation law's `S012 / AC-3` discharge finally points at
  something that exists; a matrix row naming a missing `AC-N` is a `DANGLING_REF.P1`.
- **`MM-N` magic-moment ids** (product-contract §5) and **`JOB-N` JTBD ids** (§2/§4) — the number,
  not the free-text name, is the machine key.
- **Scope-qualified references** — canonical epic id is the dir basename (field reality:
  `004-ai-core-workout-gen`, not a fictional `E004`); cross-epic refs resolve by ordinal shorthand
  (`004/S012`), full-dir, or bare-within-epic. `readiness_state_verified` is the single machine field.

### The extractor + `lint-refs` gate (`.speck/scripts/graph/speck_graph.py`, stdlib-only, portable)
- `build` compiles `specs/projects/<id>/graph/witness.json` — content-hashed nodes, per-edge
  resolution, a `generator_completeness` honesty stamp, `built_against_sha`. Tables are parsed **by
  header name, never column position** — retiring the #83/#85 positional-parse scar class.
- `lint-refs` is the first forcing gate, and it is **migration-aware** (mirrors gate-liveness
  UNVERIFIED-vs-DISARMED): a dangling ref is real rot (`DANGLING_REF.P1`, BLOCK) only when the id
  SCHEME is established — a missing story is always rot; an `AC-N`/`MM-N` ref into a scope that hasn't
  adopted the scheme yet degrades to `GRAPH_UNMIGRATED.P3` (degrade-to-honest, never a false P1).
  Also catches `DUP_ID.P1` (two story dirs sharing an S-number in one epic).
- **Proven on real repos on the first run**: caught Streb's dangling `blocks: S010`/`S042` (the
  epic-breakdown rot), Splang's renumbered `S006/AC-1` discharge and a real `S007` duplicate-id
  collision — defects that were previously invisible. Clears the FTR-A1 "measured defects caught" bar.

### Generic migration (`speck_graph.py migrate`, dry-run by DEFAULT, `--apply` to write)
Works on any live Speck project. Confidently auto-numbers acceptance scenarios to `AC-N` (§2-scoped,
idempotent, non-destructive); reports heterogeneous surfaces (MM/JOB headings) for manual review
rather than mangling them.

### Also
- Fixed the live `template-manifest.json` drift the connection-model sweep surfaced (Three-Axis →
  Four-Axis readiness; persona-larp `Taste Judgment Rubric` → `IS-IT-GOOD` critique) — the schema
  detector's own reference data had rotted.
- 10-assertion hostile test suite wired into `npm test`. Ships to consuming repos via the existing
  recursive sync. Next arcs: the extractor's `query`/`context` packs (P2/P4), the orphan/phantom/
  un-judged forcing gates (P3), and tests-as-join fine grain (P5).

## v8.6.0 — 2026-07-18 — Gate-liveness Phase 2: prove the gate is load-bearing (#88)

Phase 1 (v8.3.0) proved a §6a gate is **wired** (reachable at its declared stage). Phase 2 proves it is **load-bearing**: for each gate that carries a canary token, inject a deliberate defect in the domain the gate owns, run the gate, and assert it goes **red for the right reason**. "A guardrail you haven't watched fail is a guardrail you're assuming." The level above §13 (`tests pass → done`) is `the gate is green → the gate ran` — this closes it. Designed via a 3-architecture adversarial synthesis (one ADOPT-SPINE + two GRAFT-ONLY); shipped against Kjetil's decisions (split from the #87 grain flip; ship 3 canaries).

### The probe (`gate-liveness-probe.sh`, opt-in `--require-liveness`)
Per canaried gate: resolve the **exact committed invocation** Phase 1 already knows (probe the gate that *ships* — `--staged` and all) → **safety-screen** against a destructive-verb denylist (never probe a deploy/migrate gate) → isolate in a **throwaway git worktree** (the real tree is never the write surface — INVARIANT-ZERO holds on a mid-run kill) → **baseline green** → inject the canary + `git add` (so `--staged` gates observe it) → **mutated run** → attribute the failure to the injected defect (fingerprint) → revert → assert `$ROOT` byte-identical.

**Multi-surface + attribution (the load-bearing insight the adversarial pass forced in).** A single-file canary greens on a *partially-dark* gate and falsely certifies it live. `banned-language` injects one file **per extension-class present in the gate's required scope** and takes a per-surface verdict — which is exactly what catches the real shipped **#85** (`rg --type=ui` that skipped `.astro`): the `.tsx` surface is caught, the `.astro` surface stays green → `GATE_DISARMED.P1 (scope-hole: .astro)`. The wiring check structurally cannot see this.

### Three outcomes — the fail-closed tension, resolved
- **`GATE_LIVE`** — watched it fail on every injected surface.
- **`GATE_DISARMED.P1`** — baseline green, defect injected in the gate's required scope, gate **still green**. The one positive block; hard-blocks only at COMMERCIAL-RC / SHIP-RC (mirrors Phase 1).
- **`GATE_LIVENESS_UNVERIFIED.P2`** — couldn't apply/attribute the canary (unknown key, no green baseline, red-unattributable, unsafe-to-probe, infra-bound). Degrade-to-honest — **caps** the claimable state (fold into `MAX claimable`, like `MATRIX_GRAIN_CAP`), never a false-P1, never blocks dev.

Fail-closed on **safety** (a destructive command is never executed) and on **claims**; degrade-to-honest on **applicability**. "Couldn't run the canary" ≠ "ran it and the gate slept" — only the second blocks.

### Canary library + vocabulary (ship 3)
Speck-owned `.canary` records under `.speck/scripts/validation/canaries/` (flat KEY=VALUE, ALWAYS_OVERWRITE — a project can only reference a canary Speck reviewed). Three functional canaries ship: **`banned-language`** (Tier A, multi-surface, real §7 term — the #85 catch), **`lint-error`** (Tier B, ruff/flake8/eslint), **`unit-tripwire`** (Tier B, pytest/vitest — a universal weak floor that proves the runner is invoked, not that coverage is complete). Two declared-degrading (`a11y-role`, `integration-invariant`) ship in the vocabulary for projects to seed; `exempt:<reason>` marks a deliberately un-probeable gate (e2e/deploy). `validate-recipes.sh` enforces the closed vocabulary (unknown key = error; a canary on a destructive command = error). Reference recipe `react-fastapi-postgres` (+ `capacitor-wrapped-web`) wired to the 3 functional canaries + an `exempt:` e2e gate.

### Cadence + wiring
Opt-in and lazy (mutation runs are too slow for a push): runs at `/epic-validate`, `/project-validate`, on-demand at `/audit` — **never** on push or in the always-on `/recheck` shell (which learns the two new finding classes but does not run the probe). New hostile test suite (10 assertions: LIVE, DISARMED, DISARMED scope-hole, unknown-key / baseline-red / red-unattributable / unsafe-to-probe UNVERIFIED, staged-mutation LIVE, INVARIANT-ZERO, real-PATH-preserved), wired into `npm test`. Closes #88.

## v8.5.0 — 2026-07-18 — Grain teeth enforced: WARN → BLOCK at the validate gate (#87)

v8.4.0 shipped discharge grain-awareness with the two grain teeth **surfaced-only (WARN)** and pre-committed the flip to BLOCK for v8.5.0. This is that flip — kept as its own focused release so the enforcement change is legible and attributable, with Phase 2 gate-liveness (#88) landing separately.

### The flip
Under `--require-evidence` (the `/epic-validate` gate), `validate-traceability-matrix.sh` now **BLOCKS** (exit 1) on a grain violation instead of warning:
- **Tooth 1** — a discharged row's `Grain` exceeds its story's **effective** state (a `[pre-v8-proof]` cap wins over the numeric claim). A row cannot be proven at a grain higher than its story reached.
- **Tooth 2** — a product-grain (≥ ux-rc) row whose discharging report cites **no walk-evidence** artifact (LARP / screenshot / evidence path).
- **Invalid grain token** — a `Grain` cell that isn't a readiness-ladder enum (+ optional `[pre-v8-proof]`).

Grain violations are a **separate, additive** exit-1 block from promise conservation — the conservation logic is byte-for-byte unchanged since v8.3. The grain surface/floor line (`MATRIX_GRAIN_CAP`) still prints first, so a failing run still tells `/epic-validate` the honest ceiling.

### The fast path stays soft
Default mode (pre-commit / `/recheck`) keeps grain findings **surfaced-only (WARN, non-blocking)** — enforcement lives at the validate gate, not the commit. Absent grain is never a violation in any mode, so a legacy or reconciled matrix (`—` / `integration-green [pre-v8-proof]`) does not newly fail. New regression test asserts the fast path never blocks; the four grain-teeth tests now assert the block. `npm test` green.

## v8.4.0 — 2026-07-17 — Discharge grain-awareness + Promise↔Source fidelity (#87, #86)

A `discharged` traceability row was **grain-blind**: the status means "a story's evidence satisfied a story's AC", but the Coverage Summary reads to a founder as "the product does this" — and every one of Splang's 16 false discharges lived in that gap (a unit test imported a helper the route never called; a lint scanned source, the product ships a build). Worse, `/speck-reprove` correctly capped v7 green `[pre-v8-proof]` **on the reports only** — the matrices kept asserting the capped readiness, so report and matrix contradicted each other in the same epic dir (#87). Separately, the conservation gate reads a row's bookkeeping columns but never its `Source`/`Promise`, so a row can name a promise the product doesn't keep and the gate prints green (#86). Designed via 3 architectures, adversarially synthesized, and shipped against Kjetil's blessed decisions (cap = MIN grain over ALL discharged rows; teeth WARN now, BLOCK in v8.5.0).

### Grain — a second, orthogonal axis on the matrix (#87)
- New `Grain (proven-at)` column in `traceability-matrix-template.md` §2 (between Backing and Status), valued from the existing readiness ladder (`impl-green | integration-green | ux-rc | …`, optionally ` [pre-v8-proof]`). **Status answers "resolved?" (conservation, unchanged); Grain answers "at what grain?".** A `[pre-v8-proof]` row is STILL `discharged` — conservation math is byte-identical. Grain is per-(row × evidence): one story can discharge PRM-A via a unit test (`impl-green`) and PRM-B via a build-LARP (`ux-rc`) — the story's single `readiness_state_verified` is only the ceiling.
- **Parser rewrite** — `validate-traceability-matrix.sh` and `compute-cascade.sh` both dropped their fragile positional 6-vs-7-column heuristic for a **header-keyed** parser (bash 3.2, no associative arrays/mapfile): read the `| PRM-ID | … |` header once, resolve each column by name, pluck data cells by recorded index. Back-compatible with 6/7-col matrices; correctly reads Status in an 8-col matrix (the old heuristic would have mistaken Grain for Status in `compute-cascade`, silently breaking cascade blast-radius detection).
- **Soft teeth (WARN in v8.4.0 → BLOCK in v8.5.0)** under `--require-evidence`: grain ≤ the discharging story's **effective** state (a `[pre-v8-proof]` stamp caps at integration-green); and a ≥ ux-rc row must **cite walk-evidence** in its report. Absent grain is NEVER a conservation violation. Always-on surface line splits product-grain vs story-grain counts and prints a **GRAIN FLOOR**.
- **`MATRIX_GRAIN_CAP`** = MIN grain over ALL discharged rows, emitted for `/epic-validate` to fold into **MAX claimable = MIN(story states, MATRIX_GRAIN_CAP)**. An un-graded discharged row is treated as story-grain (integration-green) — so an un-graded matrix **cannot back a UX-RC claim** (the #87-correct humble default; migration = untrusted-by-omission, no backfill).

### Reprove reconcile — close the report↔matrix contradiction (#87)
- New `reconcile-matrix-grain.sh <PROJECT_DIR>` (wired as `/speck-reprove` **Phase 1.5**): for every `discharged` row whose story report is pre-v8-stamped/capped, writes the row's Grain to the effective (capped) state `[pre-v8-proof]` — the same sentinel the reports carry, so matrix and report converge and `MATRIX_GRAIN_CAP` drops the epic to its honest ceiling. Reads the effective cap (never the preserved numeric), inserts the Grain column if the matrix is 6/7-col, never auto-promotes, Status untouched, idempotent.
- `staleness-check.sh` now flags an un-reconciled matrix (report capped `[pre-v8-proof]` but matrix un-graded) as `V8_STALE` → routes to `/speck-reprove` under the existing `V8_REPROVE.P1` family (no new drift enum). Counts wired into the reprove report template + `/recheck`.

### Promise↔Source fidelity, honestly split (#86)
- **Structural** (`--check-fidelity`, opt-in, WARN-only, never touches the conservation exit code): for each row, checks the named `Source` artifact/anchor **exists** (phantom-source WARN) and the `Promise` shares salient vocabulary with it (vocabulary-drift WARN). States plainly — in code and docs — that this is PRESENCE + OVERLAP and **provably cannot** catch the live #86 miss.
- **Semantic** — a "Promise↔Source Fidelity Sweep" added to `/speck-audit` (reuses the adversarial `@speck-auditor` harness): reads the named Source clause + Promise + discharged predicate and returns `faithful | drift | contradictory`, hunting "X only if Y" promises the discharge never guards. `contradictory` on a `discharged` row → P1 punch-list; `drift` → P2. Opt-in, sampled on load-bearing Sources (differentiator/magic-moment mandatory).

### Notes
- Grain-vs-surface (v1): any ≥ ux-rc tier satisfies the product-grain floor (not surface-dependent yet — follow-up). Effective-state cap reads the `[pre-v8-proof]` report stamp (project-state cap detection is a follow-up).
- The `[pre-v8-proof]` sentinel lives in both a report (story-level fact) and a matrix Grain cell (row-level fact): genuinely different facts sharing a token — NOT a one-fact-two-homes violation.
- Traceability template `structure_version` 7.14.0 → 8.4.0 (required_headers unchanged — no existing matrix goes structurally invalid). New `reconcile-matrix-grain.test.sh` + 9 new validator cases + an 8-col cascade regression, all wired into `npm test`. #88 (Phase 2 canary-liveness) stays open — separate tracked work.

## v8.3.0 — 2026-07-17 — Gate-liveness: check the gates actually run (#88, Phase 1)

v8's thesis is "verification-shaped evidence lies — evaluate on the real artifact." One link it didn't reach: nothing checked that the gates `evidence-contract.md` §6 declares actually **run**. A gate that never runs is indistinguishable from a passing one — both leave every validator green, and the dark one manufactures a clean evidence trail. Three §6-declared gates were dark for 20 days in a live repo (Splang) while every Speck check read green. Designed via 3 architectures, adversarially scored, synthesized.

### The wiring check (always-on, cheap)
- **§6a CI-Enforced Gate Registry** — a machine-readable table in evidence-contract (`Gate ID | Command/Script | Stage | Domain | Canary | Waiver`), **seeded** from a new recipe `evidence_contract.ci_gates` block via `seed-gate-registry.sh` (scaffolded, not hand-authored — an un-seeded project isn't dark, it's seeded on first contract generation).
- **`validate-gate-liveness.sh`** builds each gate's firing-set from the project's **committed** config (`.pre-commit-config.yaml`, `.husky`, `package.json`, Speck's hook, `.github/workflows`) — never the ephemeral `.git/hooks` — and diffs the declared stage against it. All three real dark-gate bugs collapse to one case, "declared ∉ firing": `GATE_WIRING_DRIFT.P1` (declared pre-push, wired `stages:[manual]`), `CI_TRUNK_EXCLUDED.P1` (a `ci:` gate whose workflow ignores trunk), `SCRIPT_UNREFERENCED.P1` (a §6a script never called on the commit path). Unrecognized hook/CI system → `GATE_WIRING_UNVERIFIED` (degrade-to-honest, never false-green / false-P1).
- **Agreement, not "everything everywhere"**: a gate legitimately off the fast path declares `stage: manual`; a should-be-wired gate accepts a logged exception via `waived DEC-####` (the DEC must resolve, or `GATE_WAIVER_UNBACKED`). The sin is the silent divergence.
- **Cadence**: wiring runs at `/audit`, `/recheck` (new drift class), and readiness transitions; **hard-blocks only at COMMERCIAL-RC / SHIP-RC** (enumerate-and-warn below). Near-zero always-on.
- Fixes the incidental `validate-evidence-contract` §5/§6/§7 label off-by-one (and adds the previously-missing §7 check).

Phase 2 (opt-in mutation/canary liveness — inject a defect, assert the gate goes red) is next. This release seeds `ci_gates` in `react-fastapi-postgres` (+ `capacitor-wrapped-web` via `extends`); remaining recipes degrade to a P3 nudge until seeded. New test suite (8 cases: all three dark-gate bugs + waiver + degrade + empty-`.git/hooks`-must-not-P1), wired into `npm test`.

## v8.2.1 — 2026-07-17 — Fix: banned-language silent-green on non-web files (#85) + traceability success-string honesty (#86)

Two fixes from the evidence-integrity family filed against Splang (#85–#88): a green gate that doesn't mean what it claims.

### #85 — `banned-language-lint` scanned ~0 files on non-web projects and reported green
When `ripgrep` is installed, the lint used a `--type=ui` extension allowlist that omitted `.astro` (and `.dart` / `.swift` / `.kt` / `.php` / … — platforms Speck supports elsewhere), so the fast branch silently scanned a subset and printed "✅ No banned-language violations" while the `grep` fallback would have caught the term. On an Astro project it scanned **zero** pages. Fix: the rg branch now scans ALL textual files (excluding the same build/vendor dirs as the fallback) — no allowlist, so the two branches agree — plus a loud **"scanned 0 files"** guard so a green result on nothing can't pass silently. New regression test (V8).

### #86 — traceability success string over-claimed
`validate-traceability-matrix.sh` verifies promise **conservation** (every PRM row resolves) but printed "✅ Promise conservation holds — no promise evaporated", a stronger claim than the check makes. The message now states exactly what was verified (rows RESOLVE) and explicitly disclaims fidelity/grain. (The deeper Promise↔Source fidelity check + the discharge grain field from #87 are in design.)

## v8.2.0 — 2026-07-16 — TASTE axis (4th) + exhaustive torture tier (#84)

Two recurring gaps in LARP/validate: (1) **coverage narrowness** — a composed walk runs one persona / one seed / one viewport / happy-path (the Splang cross-epic P0 class); (2) **taste was not first-class** — "technically correct and legible" can still be cheap-feeling. Designed via 3 architectures per pillar, adversarially scored, synthesized.

### TASTE — a 4th non-collapsible readiness axis
CORRECT / ON-CONTRACT / FELT-GOOD / **TASTE**. Implemented as **Job C · IS-IT-CRAFTED** in `/speck-larp` — a connoisseur-hostile pass over the SAME screenshots Job B captures (one extra evaluation, **no new capture cost** at normal tier). FELT-GOOD stays "not broken / confusing" (legibility); TASTE is "crafted / premium / it sings" (connoisseur).
- **Dual-anchored**: Anchor A (product-relative) = new `product-contract.md` **§6b Aesthetic Contract** + `design-system.md`; Anchor B (universal) = the `visual-quality` skill's principles (reused, not duplicated). HARD declared rules → BAD (may block); FUZZY intent → fork only. Under-specified intent → `taste_anchor: universal-only` (anti-masquerade) + a `/project-design-system` nudge. The same treatment can be excellent taste in one product and awful in another.
- **Owner-sovereign**: the pass **surfaces Aesthetic Forks** for the owner and never resolves subjective taste unilaterally; conservative auto-fix (named-rule violations + hard-objective defects only). A **severe BAD** (≥2 pixel-grounded craft violations on a flagship surface) or a named-declared-rule violation **caps the state**.
- New `validate-taste-axis.sh` (+ test) mirrors `validate-felt-axis.sh`; `taste_axis` / `taste_anchor` frontmatter + a Four-Axis section across all three validation-report templates; new lazy `connoisseur-critique-template.md`. Consumer archetypes must cover TASTE at UX-RC+.

### Exhaustive torture tier (opt-in) + coverage matrix
`/project-validate --exhaustive` — the cross-epic breadth orchestrator (where the Splang composition P0 lived).
- **GENERATE** (always-on, cheap): a script-authored `coverage-matrix.md` skeleton — the runtime analog of `traceability-matrix.md` — so breadth GAPs are visible-not-silent even if you never pay to fill them.
- **FILL** (opt-in, expensive): persona-army × route × {happy, error, empty, loading} × viewport × theme, N-sample input variety with **deterministic** `banned-language-lint` per generative cell (the deterministic cure for a stale word slipping a single happy-path seed), full-page axe + Lighthouse, §11 resilience cells, fanned out via `@speck-validator`.
- **VALIDATE**: `validate-coverage-matrix.sh` fails on un-run/un-waived cells or surrogate (no-evidence) RUNs. Breadth **caps, never raises**, the state. New `generate-coverage-matrix.sh` (deterministic v1 + `chain-partial` self-check), `validate-coverage-matrix.sh` (+ test), `coverage-matrix-template.md`.

### Notes
Neither pillar adds a new readiness **state** — both are modifiers (`taste_axis`; coverage tier + breadth cap). Net always-on ≈ +30 lines (§6b + the four-axis reframe); all heavy machinery lazy-loaded. New tests wired into `npm test` (full suite green). AGENTS.md, evidence-contract, product-contract, the report templates, and the larp/validate skills all reframed to four axes.

## v8.1.4 — 2026-07-16 — Fix: banned-language §7 extractor blind to code-formatted terms (#83)

`banned-language-lint.sh` (and `validate-product-contract.sh` rule 10) extracted §7 banned terms from column 1 but didn't strip markdown backticks or a trailing `*(qualifier)*` note. A project that code-formats its banned terms — natural for single words, e.g. `` | `host`, `organizer` *(of the user)* | … | `` — had them extracted as `` `host` `` / `` `organizer` *(of the user)* ``, so `grep -w` searched for the backtick-delimited literal and **never matched the bare word in source**. A shipped `✦ HOST` UI pill (the exact §7-banned differentiator word) passed the lint — a false-green in a gate whose entire job is to catch banned language.

Both §7 extractors now strip backticks and trailing `*(qualifier)*` notes before whole-word grepping. New regression test (V7): a backtick+qualifier §7 row now matches the bare word in code. Same robustness family as #81/#82 — opposite direction (a false *negative*, not a false positive).

## v8.1.3 — 2026-07-12 — Fix: product-contract validator rule 10 residual (#82)

Follow-up to #81. Rule 10 still flagged an *established domain term* that the contract's own §7 ❌ list scopes to "on user surfaces" when it legitimately appeared in §1 promise prose and §5 magic-moment `Surface:`/`Trigger:` spec-definitions (the same case as the already-exempted `Validation step`). Repro: Splang's `subset` — a load-bearing domain term (62 uses in shipped code) declared as internal→public vocabulary. #81's fix dropped the flag count 8→1; this closes the last one.

Two additions to rule 10:
- Skip §5 `**Surface**:` / `**Trigger**:` spec-definition lines (mirrors the existing `**Validation step**` skip).
- Exempt any banned term the contract itself declares as domain vocabulary in §6 (Public Language / API taxonomy) — an established internal→public name appearing in §1–§5 spec-prose is not a user-surface leak.

A real leak still fails — a pure copy-voice banned phrase (e.g. "crushing it", not §6 vocabulary) in the §1 promise or a §5 user-facing string is caught (new test). The #81 fixtures stay green.

## v8.1.2 — 2026-07-12 — Fix: product-contract validator rule 10 false-positives (#81)

`validate-product-contract.sh` rule 10 (the self-banned-language check) scanned the whole file excluding only §7, so it hard-failed **correct** contracts whose by-design vocabulary sections legitimately name banned terms — §6 taxonomy (`| mesocycle | Training Block |`), §3a anti-differentiators ("no mesocycle templates"), `Bad:`/❌ example copy, §5 "Validation step" LARP methodology (`simulator` as test tooling), and inline-code identifiers. Because `validate-template.sh --strict` runs in the pre-commit hook, the first legitimate edit to a migrated project's `product-contract.md` (e.g. the v8.1.0 market-claim re-stamp) was rejected — with `--no-verify` the only escape, the exact gate-bypass v8 forbids.

Rule 10 now scans only the product-**voice** sections (§1–§5), stops at §6, and skips §3a, markdown tables, `Bad:`/❌ examples, `Validation step` lines, `(internal only)` callouts, and inline-code. A real leak (banned term in the §1 promise or §5 magic-moment copy) still fails — verified by a new test (legit meta-mentions pass; §1 leak fails). Same false-positive class as the already-fixed #63.

## v8.1.1 — 2026-07-12 — Cruft cleanup + broken-ref fix

Housekeeping pass (two reference-verified cruft sweeps). No methodology behavior change; fixes broken skill commands and removes dead weight.

### Fixed
- 4 skills (project-validate, story-validate, speck-catch-up, project-readme) referenced `.speck/scripts/validation/validate-readme.sh` — the file lives in `validators/`, so the command was a guaranteed file-not-found. Corrected.
- 13 template frontmatters `speck_version: 7.x` → `8.0` (`detect-version.sh` reads this field; new artifacts were mis-detected as v7 and could wrongly trip the v8 re-prove gate).

### Removed (dead / superseded, zero callers — all verified)
- Root `VERSION` (redundant with `.speck/VERSION`); `.speck/scripts/v7/` symlink shim; `sync-claude-commands.sh` wrapper; `audit.sh` (superseded by the `/audit` skill; checked a retired v6 model + a non-existent `quickstart.md`); `add-recipe-evidence-defaults.sh` (completed one-off v6-era migration).
- CLI dead code: `getAllFiles()`, `downloadRelease()`, and 4 no-op legacy exports (`loadIgnorePatterns`/`shouldIgnore`/`planSync`/`executeSync`); dedup'd `isSpeckMarketingReadme` (feedback.js now imports the single source from sync.js).

### De-versioned / wired
- 10 active skills + 6 footer example stamps de-versioned (kept legit provenance like "v6 projects" and "added in v7.2+"); phantom `/speck-primitives-init` command replaced with the real registry path.
- Wired 3 on-disk-but-never-run checks into `npm test`: `claude-settings.test.js`, `validate-recipes.sh`, `validate-artifact-docs.sh`.

## v8.1.0 — 2026-07-12 — Market-claim staleness recheck + §2a↔§3 reconciliation (#80)

Competitive / differentiator claims were captured once at planning time and rotted silently — true when written, false weeks later. Streb's "no competitor offers real-time autoregulation + LLM coaching" was true in 2026-05 and false ~8 weeks later (SensAI, Ray, WHOOP Coach, JuggernautAI, Fitbod); nothing in Speck flagged it. v8.1.0 attaches a mechanism (P2) to those claims. Design: 3 independent architectures, adversarially scored, synthesized.

### The mechanism
- **Unforgeable market stamp** — an inline `*[market-verified <date> | verdict | sources | scan: <report>]*` line under §3, written ONLY by `stamp-market.sh`, which refuses without an existing sourced scan report (and, for `holds`, `sources ≥ floor`). No claim reads fresh without evidence behind it. Inline (not the EOF footer) so it never collides with `stamp-truth.sh`.
- **Split clock** — absolute "no competitor does X" claims get a tight `market_absolute_claim_days` (default 30, below the observed rot); generic differentiators get `market_scan_cadence_days` (default 45 consumer/SaaS/paid-API, 90 infra/backend).
- **A — detector** `market-staleness-check.sh` (cheap, no-web) in the `/recheck` fan-out: `MARKET_DRIFT.P1` (absolute claim unverified/stale past the tight clock, honest `verdict: eroded|false`, or a missing cited report — phantom evidence) / `.P2` (generic past cadence, provisional baseline, under-sourced). Fires on FILLED claim values only and competitor-relative frames only (no bare only/first/unique) — no rollout false-positive flood.
- **B — cadence scan** `/speck-frontier-scan --product`: reuses the 4-angle web-scan machinery re-pointed at a product's live market; writes `project-market-research-report-<date>.md` (existing routing glob), proposes `/project-adjust` deltas, re-stamps. No new skill.
- **C — reconciliation** `market-reconcile-check.sh` + `validate-product-contract.sh`: keeps §3 never weaker than the §2a defensible wedge — `WEDGE_DRIFT.P1` (§3 empty while §2a states a wedge, or §2a self-flags §3 as thin/copyable — the Brightstance case) blocks the contract stamp; `.P2` (low §3↔§2a overlap) routes to the auditor. Handles both §2a and legacy standalone `value-defensibility.md`.
- **Blast radius**: `MARKET_DRIFT` / `WEDGE_DRIFT` are P1, not P0 — they do NOT block `/story-implement` (a stale claim is not a runtime defect); they block `COMMERCIAL-RC` / `SHIP-RC` and generating marketing copy from the spec.

### Config (all optional in `.speck/project.json`, absent = safe default)
`market_absolute_claim_days` (30), `market_scan_cadence_days` (45 / 90 by archetype), `market_sources_floor` (3), `market_scan` (`false` opts a claim-free internal tool out).

### Files
New: `.speck/scripts/market-staleness-check.sh`, `market-reconcile-check.sh`, `stamp-market.sh` (+ `.test.sh` for both detectors, wired into `npm test`). Edited: `speck-recheck`, `speck-frontier-scan`, `project-product-contract` skills; `product-contract-template.md`; `validate-product-contract.sh` (+ test); one `AGENTS.md` discipline row. Additive, no migration. `.speck/VERSION` / root `package.json` / `packages/cli/package.json` → 8.1.0.

## v8.0.1 — 2026-07-10 — Fix: upgrade no longer deletes project-custom skills/agents

Data-loss-class fix found live during the keegt v6.1.12→v8.0.0 upgrade (captured via the
v8 feedback discipline: `.speck/feedback/2026-07-10-v8-upgrade-session.md` in keegt).

### The bug
`.cursor/skills` and `.cursor/agents` are ALWAYS_OVERWRITE directories — `smartSync` does a
wholesale `rmSync` + re-copy on every `speck upgrade`/`speck init`. But project-custom skills
MUST live in `.cursor/skills` (`.claude/skills` and `.codex/skills` are symlinks into it), so
every upgrade silently deleted them. Keegt lost its four `keegt-content-*` skills (recovered
from git; an uncommitted custom skill would have been unrecoverable). `--dry-run` did not
disclose the wholesale replacement.

### The fix
- `PRESERVE_UNKNOWN_SUBDIRS = ['.cursor/skills', '.cursor/agents']`: during the replace, any
  subdirectory NOT shipped by the Speck source tree is snapshotted and restored (same machinery
  as `PRESERVE_SUBDIRS`). Speck-shipped dirs (including retired-skill shims) are still fully
  overwritten; explicit removals via `REMOVE_FILES` still apply afterward.
- New `packages/cli/lib/sync.preserve.test.js` (4 tests: custom skill survives, shipped skill
  fully overwritten, stale files inside shipped dirs do not survive, custom agent survives) —
  wired into `npm test`.

### Version
- `VERSION`, root `package.json`, `packages/cli/package.json` → `8.0.1`.

### Docs — README rendering & de-versioning
- Fixed GitHub's "Unable to render rich display" on all three workflow diagrams: slash-command node labels (`A[/speck …]`) were parsed as mermaid parallelogram-shape syntax and failed the whole graph. Every label is now quoted (`A["/speck …"]`); verified by rendering all three to SVG.
- De-versioned the README (it is not a changelog): dropped the "v7" title, the dead `**Speck Version**` footer (read by nothing — `sync.js` only parses the `AGENTS.md` copy), the "shift from v6" note, the "v7.7+" / "in v8" inline stamps, and the "Core v7 Concepts" heading.
- Relocated the two major-version migration sections (v6→v7, v7→v8) into `DEVELOPMENT.md#migration-major-version-upgrades`, leaving a short version-agnostic pointer under "Keeping Speck Updated".
- Reconciled `.speck/VERSION` 8.0.0 → 8.0.1 (the bump commit missed this authoritative file) and the `AGENTS.md` version footer → 8.0.1.

## v8.0.0 — 2026-07-03 — Evaluation Over Verification

The v7 patch line fought agent green-hacking by writing down ever more explicit checks. That is self-defeating: an agent optimizes to satisfy the *letter* of any enumerated gate (Goodhart), and the enumeration itself becomes the context-rot that crowds out common sense. v8 changes **what the agent optimizes for** — from "produce green evidence" to "find what is wrong" — and **shrinks the corpus** so common sense fits back in context. Design: `docs/history/north-stars/v8.md`.

### The four principles (the spine — govern every gate)
- **P1 — Evaluation over verification.** Every gate's default flips from "confirm the claim" to "find what is wrong." A clean pass is the residue of a genuine attempt to break it.
- **P2 — No claim without a mechanism.** Every claim points to the observed mechanism that makes it true (fired endpoint, written row, real forbidden-op attempted as a real least-privileged principal, logged real attempt, value-defensibility artifact). Claimed-without-mechanism = automatic fail.
- **P3 — "Can't reach it" is a finding, not an excuse.** Unreachable-by-automation is the default hypothesis for unreachable-by-some-user; a named blocker requires a logged, reproduced real attempt.
- **P4 — The adversary is structural, not a checklist.** Truth-seeking is owned by a separately-incentivized evaluator measured by defects found. Probe lists prompt the adversary's imagination; they don't define "done."

### The five issues collapse to the principles (holistic, not surgical)
- **#78 (LARP verifies, doesn't evaluate) → P1.** `speck-larp` + `persona-larp-template` split into **DOES-IT-WORK** (functional) vs **IS-IT-GOOD** (experiential), with forced per-screen pixel-grounded adversarial critique, a Common-Sense Defect Sweep, and "un-adjudicated screenshot = surrogate proof."
- **#74 (price vs free substitute) → P2.** New value-defensibility / WTP-vs-$0-substitute gate across `product-contract-template` §2a, `evidence-contract` COMMERCIAL-RC, `speck-premise-challenge`, and `speck-skeptical-review`.
- **#75 (AI action-claims / laundered "unreachable" / sweep home) → P2 + P3.** Action-claim audit in LARP; "LARP must reach everything" reach doctrine + diagnostic playbook.
- **#76.1 (named-blocker cap by assertion) → P3.** `INTEGRATION-GREEN` caps now require a logged, reproduced failure of the actual LARP recipe (fixed in `story-validate`, `epic-validate`, `speck-larp`).
- **#76.2 / #76.4 / #77.1 / #77.2 → P2 / P1 / audit.** `speck-audit` retooled for mechanism-grounded negative-test authenticity (real least-privileged principal attempts the forbidden op), skipped≠run, story-level random-order rerun, and an exhaustive reader/writer sweep for privacy epics.
- **#76.3 →** local fix: `validate-traceability-matrix.sh` now extracts the first canonical readiness-state token via an enum helper (+ test).

### Consolidation (the bloat cut — ~a third off the always-on surface)
- **Retired to alias-shims**: `epic-outline`, `story-outline` (→ `/speck-skeptical-review` + `/speck-decision-log`), `story-analyze` (→ consistency at the tail of `/story-tasks` + adversarial `/audit`). Deleted the two orphan templates `outline-template.md` + `analysis-report-template.md`. Fixed `story-implement`'s stale hard requirement on `analysis-report.md` (now optional) and reoriented the `story` orchestrator, `story-plan`, `story-specify`, `story-clarify`, and `breakdown-template` flows.
- **Scan unified**: `project/epic/story-scan` are thin shims over `speck-scan --level`.
- **`--level` dispatchers**: new `validate` / `retrospective` / `adjust` / `analyze` unified entry points route to the preserved per-level specialists (dispatcher pattern — no lossy merge; direct `project/epic/story-*` names still work).
- **Visual-testing**: the 6 host variants are demoted to `disable-model-invocation: true` lazy sub-rules of the one `visual-testing` coordinator (host table loads the right one on demand).
- **Integration patterns**: the 20 integration/domain skills (~6.2k lines, incl. the `model-selection` meta-pattern) are demoted to `disable-model-invocation: true` and indexed at the existing `.speck/patterns/library/README.md` (loaded on demand — no duplicate index). Deleted the content-free `ai-api-integration` stub.

### Migration — mechanical instantly, truth deliberately (cap-and-worklist)
- **Layer 1 (mechanical)**: `migrate.js` detects the v7→v8 (and v6→v8) crossing and writes a repo-level `.speck/.v8-reprove-needed` marker (analog of v6→v7's `.migration-needs-catchup`); `upgrade.js` prints the re-prove guidance. `.speck/VERSION` + both `package.json` bumped to `8.0.0`. Shims/lazy-patterns/reconcile ride the existing `smartSync` pipeline. New `migrate.test.js` (8 tests).
- **Layer 2 (semantic)**: **version-as-staleness** — `staleness-check.sh` flags any artifact stamped `< speck 8` as `V8_STALE`; `/recheck` raises `V8_REPROVE.P1` and routes to the new **`/speck-reprove`** skill. Re-prove triages suspect green against P1–P4, **caps effective shippable state at `INTEGRATION-GREEN`**, reverts consumer **FELT-GOOD to `uncovered`**, preserves each historical claim stamped `[pre-v8-proof]`, and emits `project-v8-reprove-report.md` (new template + canonical routing). Nothing is reset to zero; nothing suspect keeps claiming ship-readiness.

### Version
- `.speck/VERSION`, root `package.json`, and `packages/cli/package.json` → `8.0.0`. `AGENTS.md` reframed around P1–P4 with the first-action v8 re-prove check.

## v7.20.1 — 2026-07-02 — Correction: FELT-GOOD is AI-Evaluated, Not a Mandatory Human Gate

Corrects the core semantics of the FELT-GOOD axis shipped in v7.20.0. The previous release treated FELT-GOOD as human-owned and explicitly NOT AI-satisfiable, demanding a `larp-recordings/<sha>-felt-attestation.md` human sign-off before a consumer product could reach `SHIP-RC`. That contradicted the entire premise of the naive-hostile LARP: an AI can and should understand and apply first-impression taste judgment. This release makes the AI the primary evaluator of FELT-GOOD.

### FELT-GOOD is AI-Evaluated (#73 correction)
- **AI covers taste** — The AI now evaluates the FELT-GOOD axis directly by running the naive-hostile LARP (First-Viewport Reaction + taste-judgment rubric) and recording a verdict. A clean pass yields `felt_axis: ai-verified`.
- **Human review is optional** — A human taste review (`larp-recordings/<sha>-felt-attestation.md`) is now an *optional stronger signal* that promotes the axis to `felt_axis: human-verified`. It is never a prerequisite for shipping.
- **New `felt_axis` value** — Added `ai-verified` to the `felt_axis` frontmatter enum (`[uncovered | ai-verified | human-verified]`) in the story and epic validation report templates.

### Enforcement Now Checks Coverage, Not Human Sign-Off
- **`validate-felt-axis.sh` rewritten** — For consumer archetypes at `UX-RC` or higher, the validator now fails when FELT-GOOD is left `uncovered` (naive-hostile pass never ran) instead of failing when a human attestation is absent. `ai-verified` is sufficient; `human-verified` also passes. Unqualified "verified/validated" claims with no named axis still fail.
- **Tests updated** — `validate-felt-axis.test.sh` now asserts: consumer UX-RC + `ai-verified` passes; consumer UX-RC/SHIP-RC + `uncovered` fails; consumer SHIP-RC + `ai-verified` passes (no human demanded); `human-verified` passes; unqualified claim fails.

### Docs & Skills Realigned
- **AGENTS.md, evidence-contract, validate skills, speck-larp, persona template, premise-challenge** — Reframed so the AI owns the FELT-GOOD taste judgment via the naive-hostile LARP, with human review as an optional override. Removed "human-owned / NOT AI-satisfiable / uncovered (human required)" framing. The anti-laundering rule ("never launder a taste miss as uncatchable by automation") is retained and reinforced — the AI must run the naive lens.

## v7.20.0 — 2026-07-02 — Three-Axis Readiness Model, Premise-Challenge (Anti-Spec) Pass, Naive-Hostile LARP, and Hard Human FELT Gate

Addresses Issue #73 by making the FELT-GOOD (naive first-impression taste) axis a structural, human-owned, non-substitutable part of Speck's readiness apparatus.

### Three-Axis Readiness Model (#73)
- **Three-Axis Framing** — Decomposed readiness claims into CORRECT (correctness), ON-CONTRACT (conformance), and FELT-GOOD (taste). Added three-axis framing across `AGENTS.md`, `evidence-contract-template.md`, `validation-report-template.md`, `epic-validation-report-template.md`, and `template-manifest.json`.
- **FELT: uncovered** — Enforced that consumer product claims must render `FELT: uncovered (human required)` until a human taste review lands, capping the state at `UX-RC`.

### Premise-Challenge (Anti-Spec) Pass (#73)
- **New Skill** — Added `.cursor/skills/speck-premise-challenge/SKILL.md` to question whether the product contract's underlying design decisions are good (distinct from skeptical review and audit).
- **Hooks & Integration** — Integrated premise-challenge hooks into `project-product-contract`, `story-validate`, `epic-validate`, and `AGENTS.md` skills list and always-on table.

### Naive-Hostile LARP Persona (#73)
- **Naive-Hostile Persona** — Added a canonical context-stripped "Naive-Hostile First-Timer" persona to `persona-larp-template.md` and `evidence-contract-template.md` §4.
- **First-Viewport Reaction** — Added a "First-Viewport Reaction" rubric (What is this? / Who's asking? / Why now? / Why should I care?) where confusion/disorientation/revulsion are first-class PASS-blocking findings.
- **Behavior Rule** — Integrated a mandatory naive-hostile pass for consumer onboarding/first-run surfaces into `speck-larp/SKILL.md`.

### Hard Human FELT Gate & Attestation (#73)
- **Human Taste Review** — Made FELT-GOOD taste review human-owned and explicitly NOT AI-satisfiable.
- **Attestation Convention** — Introduced the `larp-recordings/<sha>-felt-attestation.md` convention in `evidence-contract-template.md`, `story-validate`, and `epic-validate`.

### Enforcement Validator & Tests (#73)
- **New Validator** — Added `.speck/scripts/validation/validators/validate-felt-axis.sh` and `.speck/scripts/validation/validators/validate-felt-axis.test.sh` to enforce Three-Axis blocks, `felt_axis` frontmatter, and human attestation for consumer SHIP-RC+ claims.
- **Test Suite** — Wired the new validator test into `package.json` `test` script.

## v7.19.0 — 2026-07-01 — Parallel Execution Skill, Seam Contract Template, and Continuous Feedback Capture

Introduces two large new capabilities (#69.2 and #72) to formally document parallel execution choreography and establish an always-on continuous feedback capture loop.

### Parallel Conductor Recipe & Seam Contracts (#69.2)
- **Parallel Execution Skill** — Added `.cursor/skills/parallel-execution/SKILL.md` (symlinked to `.claude` and `.codex`) to document the Parallel-Conductor Pattern (worktree-per-chunk, file-cluster chunking, seam contracts, chunk briefs, merge choreography, and `--no-ff` clean merges).
- **Seam Contract Template** — Added `.speck/templates/project/seam-contract-template.md` and registered it in `template-manifest.json` and `validate-template.sh`.

### Continuous Feedback Capture (#72)
- **Feedback Skill** — Added `.cursor/skills/speck-feedback/SKILL.md` to maintain a running `.speck/feedback/<date>-<session>.md` file, search existing issues on `telum-ai/speck` via `gh`, and draft comments/issues for user confirmation.
- **Inline Capture Triggers** — Added inline triggers to `story-validate`, `epic-validate`, `speck-audit`, `speck-learn`, and `AGENTS.md` Always-On Discipline table to capture the moment a gate is bypassed, a skill is ambiguous, or a Speck behavior is patched.

## v7.18.0 — 2026-07-01 — Wave Safety, Cascade Grep Fallback, Product Contract Self-Consistency, and Non-Deferrable UI LARP

Introduces major methodology enhancements and validator scripts (#68 and #69) to support safe parallel epic execution, robust cascade tracking, self-consistent product contracts, and non-deferrable UI LARP gates.

### Parallel Wave Safety & Concurrency (#68.1)
- **Wave Safety Validator** — Added `validate-wave-safety.sh` to check `epics.md` waves and declared touch-points, flagging collisions on migrations or identical model/service files.
- **Touch-points Field** — Added a `Touch-points (creates/modifies)` field to the epics list template.
- **Schema-Freeze Pattern** — Promoted the "schema-freeze foundation epic" pattern in `AGENTS.md` concurrency doctrine.

### Cascade Fallback & Routing (#68.2)
- **Pre-Matrix Grep Fallback** — Hardened `compute-cascade.sh` to fall back to scanning `specs/**` for changed contract or decision references when no traceability matrices exist yet.
- **Strategic Adjust Routing** — Added routing hints in `speck`, `project-specify`, and `project-product-contract` skills to suggest `/project-adjust` when a directional change is requested on a completed/validated project.

### Product Contract Self-Consistency (#68.3)
- **Self-Banned Language Check** — Extended `validate-product-contract.sh` to extract banned terms from Section 7 and scan the rest of the contract, failing on self-violations.
- **Verification Hooks** — Integrated this check into `project-product-contract` review, `speck-audit`, and the test suite.

### Non-Deferrable UI LARP Gate (#69.1)
- **Required UI LARP** — Made the browser cold-start LARP required and non-deferrable for UI archetypes in `epic-validate`, `story-validate`, `speck-larp`, and `evidence-contract-template.md`.
- **LARP Setup Recipe** — Added a sandbox-friendly setup recipe (throwaway DB, loopback backdoors, localStorage token re-injection, and mock servers) to bypass external dependencies.

### Multi-Lens Audit (#69.3 / #70.3)
- **N-Skeptic Default** — Made N-independent diverse-lens auditors (Security/Privacy, Performance/Scalability, UX/Accessibility) the default for P0/P1-risk and privacy-sensitive stories in `speck-audit` and `AGENTS.md`.

## v7.17.1 — 2026-07-01 — Story Prerequisite State Parsing, Analysis Report Warning, and Traceability Matrix Cross-Referencing

Addresses critical feedback items (#70 and #71) to relax prereq gates and enforce real evidence cross-referencing in the traceability matrix.

### Story Prerequisite Gate (#70)
- **State Parser Relaxation (#70.1)** — Relaxed state parsing in `check-story-prereqs.sh` to support markdown-bold `**Status**: Specified` and `**Current State**: Specified` markers generated by standard story templates. Added `lifecycle_state: Specified` to the story spec template frontmatter as a stable token.
- **Analysis-Report Warn-Only (#70.2)** — Downgraded `analysis-report.md` from a hard gate blocker to a warning in `check-story-prereqs.sh`, aligning with the v7 deprecation of the standalone `/story-analyze` step. Updated the rejection instructions to guide developers to `/story-tasks` and `/speck-audit`.

### Traceability Matrix Cross-Referencing (#71)
- **Evidence Verification** — Upgraded `validate-traceability-matrix.sh` under `--require-evidence` to cross-reference story validation reports. For each `discharged` promise, it verifies the corresponding story validation report exists, is at least `INTEGRATION-GREEN`, and cites the `PRM-NNN` or `AC-x` ID.
- **Status-Only Mode** — Added a `--status-only` flag to bypass cross-referencing for quick status-only checks.
- **Test Suite** — Expanded `validate-traceability-matrix.test.sh` to fully test the cross-referencing logic and mock story validation report states.

### Stamp Hardening (#68.4)
- **Double-v Prevention** — Hardened `stamp-truth.sh` to defensively strip any leading `v` from the version string, preventing `speck vv7.x` stamps.

## v7.17.0 — 2026-06-28 — Irreversible-Action Control Tiers, Rules-vs-Contracts Boundaries, VCS-as-Eval Signals, and Continuous SOTA Scanning

Introduces advanced SOTA agentic software engineering practices, adding irreversible-action autonomy levels, strict document boundaries, automated Git VCS performance analytics, resilient research fallbacks, and a continuous SOTA frontier scanning ritual.

### Irreversible-Action Autonomy Tiers (G+)
- **Action Control Tiers** — Added structured irreversible-action autonomy levels to `evidence-contract-template.md` (Tiers 0-3). Tiers autonomy by action blast radius (reversible local edits to irreversible/costly production drops), establishing minimum readiness states and recorded human approval token gates before execution.
- **Compliance Probe** — Added a corresponding "Irreversible-action tier compliance check" to the Adversarial Probe Suite to verify that no Tier 2 or Tier 3 actions are executed without human authorization recorded in the trajectory log.

### Rules-vs-Contracts Separation (D)
- **Governance Boundaries** — Added strict document boundaries to `project-evidence-contract/SKILL.md` delineating the roles of workspace configuration (`AGENTS.md`), the product promise (`product-contract.md`), and verification proof rules (`evidence-contract.md`) to prevent competing constitutions and instruction rot.

### VCS-as-Eval Metrics (E)
- **VCS Performance Signals** — Created `compute-eval-signals.sh` and its robust suite `compute-eval-signals.test.sh` to extract agentic metrics (override rates, code survival rates, and agent-vs-human distribution) from real Git history, treating the VCS as an unbiased evaluation engine.
- **Signal Drift Monitoring** — Integrated VCS evaluation analytics directly into the `/recheck` process skill across all three primary hosts (Cursor, Claude, and Codex) to monitor and flag `EVAL_SIGNAL_DRIFT.P2` breaches in CI and runtime.

### Continuous SOTA Frontier-Scanning (FTR)
- **Frontier-Scan skill** — Created a self-refreshing process skill `speck-frontier-scan` (`.cursor/skills/speck-frontier-scan/SKILL.md`) to execute continuous, cited audits on SOTA autonomous software engineering standards, synthesizing deltas and generating dated SOTA reports.
- **Resilient Fallbacks (F)** — Toughened `just-in-time-research` with instant drop-tier fallback handling to bypass tool and quota outages (such as Perplexity API limits) gracefully.

### Ambition & Provenance Polish (J & K)
- **Spec-to-Deployed Provenance (J)** — Extended the evidence contract template SHIP gate to require Spec-to-Deployed Behavior Provenance logs, mapping live artifacts to their triggering commit SHA and Speck matrix lines.
- **EARS Acceptance Criteria (K)** — Added EARS Natural Language Templates (`WHEN <trigger>, the system SHALL <response>`) to `story-specify` to eliminate downstream story interpretation ambiguity.

## v7.16.0 — 2026-06-23 — Agent Skill Execution, Change Cascade Blast-Radius, Continuous Lifecycle, and Legibility Probes

Addresses issues #66 and #67 to introduce first-class agent tool support, post-validation directional changes, automated reverse-cascade computation, continuous lifecycle triage, and UX comprehension checks.

### Parallel-Epic Field Learnings (#66)
- **Agent Skill-Tool Grant (#66.1)** — Added `Skill` to the `tools:` list of all 5 lane agents (`speck-coder`, `speck-auditor`, `speck-validator`, `speck-planner`, `speck-scribe`), enabling them to execute the full Speck skills required by the Verify-Skills Gate. Documented a `general-purpose` agent fallback for hosts restricting custom-role tool lists.
- **Transcript Grep-Verify & Independent Auditor (#66.2)** — Codified a concrete verify recipe in the Verify-Skills Gate (`AGENTS.md`, `.cursor/skills/epic/SKILL.md`, `parallel-epic-execution.md`): the conductor must grep sub-agent transcripts for `"name":"Skill"` to prevent hand-rolled or copy-pasted report simulation. Mandated a genuinely independent `@speck-auditor` agent (citing field evidence where separate audits caught 4 critical bugs that self-audits missed).
- **Web LARP & Env Cautions (#66.3)** — Added cautions to `speck-larp` and `visual-testing-web` for production-build testing. Click/hydration failures on hot-reload dev servers are suspect (HMR websocket reconnects false-BLOCKED); client bundles inline environment variables like `NEXT_PUBLIC_*` at build-time, so server shell variables do not update browser bundles (split-brain).
- **Epic Retrospective Fallback Inputs (#66.4)** — Updated `epic-retrospective` to accept the `orchestration-ledger`, `validation-report.md` files, and `audit-report.md` files as sanctioned fallback synthesis inputs when per-story `story-retro.md` files are absent under parallel-conductor worktrees.
- **Merge & Worktree Discipline (#66.5, #66.6)** — Documented `lint-staged` conflicted merge corruption (husky stashing drops auto-merged files, writing broken single-parent commits) and mandated resolving with `git commit --no-verify` and parent verification (`git show --stat HEAD` having 2 parents). Documented worktree hygiene (removing with regular `git worktree remove` to prevent forced-overwrite loss of uncommitted dirty WIP under concurrency) and killed-agent WIP restoration (`git add -A && commit`).
- **Supabase & Balance Discipline (#66.7)** — Redefining database functions via `CREATE OR REPLACE FUNCTION` in forward migrations must be diffed against the *latest* prior migration definition across the entire codebase to prevent silent regression overrides. A story that decrements a balance owns the symmetric refund/re-credit logic in the same story.

### Continuous Lifecycle & Project Adjustments (#67)
- **Project Adjustment Stage & Template** — Introduced a new `/project-adjust` stage for project-level directional changes (strategic pivots, product contract revisions). Created `project-adjust-template.md` (report type `project-adjust-report`) and registered it in `template-manifest.json` and `validate-template.sh`.
- **Change-Cascade Blast-Radius Computer** — Created `compute-cascade.sh` and `compute-cascade.test.sh` to automatically scan all epic traceability matrices for affected epics/stories matching a superseded decision (`DEC-NNNN`) or modified contract section. Integrates into `/speck-recheck` under `CASCADE_STALE.P1` taxonomy.
- **Continuous Lifecycle Router** — Reframed post-validation lifecycle as non-terminal ("v1 shipped, evolving"). Added a **Post-Completion Triage Router** to `AGENTS.md` and `/speck` to direct post-validation feedback into `/harden` (defect), `/story-adjust` / `/epic-adjust` (redesign), or `/project-adjust` (pivot) based on level and intent. Softened `project-retrospective` terminal framing.
- **Comprehension & Legibility Probe** — Added a "Comprehension / Legibility probe" class to §11 of `evidence-contract-template.md` to verify a first-time user can state the product value and call-to-action within 5 seconds of the JTBD cold-start. Integrated into `project-validate` JTBD walkthrough as a `LEGIBILITY.P1` gate that caps project status below `SHIP-RC` on failure.

## v7.15.0 — 2026-06-21 — Deliberate Adjustments, Migration Parity, Clean-Build LARPs, and Matrix Retrofitting

Addresses multiple crucial feedback items (#64 and #65) to tighten the loop between validated specifications and live runtime reality, preventing promise evaporation and simulation drift.

### Deliberate Post-Validation Re-engineering (#65)
- **New `/story-adjust` and `/epic-adjust` stages** — Deliberate redesigns, visual overhauls, and IA shifts are now handled as first-class citizens. Modeled as siblings to `/harden` (which is reserved exclusively for defect/bug fixes), these stages require delta re-specification in specs/experience-chains/wireframes, promise conservation, forced decision logs, and delta-focused re-auditing + re-validation.
- **Adjust Report templates** — New `story-adjust-template.md` and `epic-adjust-template.md` to cleanly document and re-stamp deliberate changes. Registered and checked for structural template drift.

### Migration Schema-Drift Blind Spot (#64 G1)
- **Live-Schema Parity check** — INTEGRATION-GREEN now requires live database schemas to match committed migrations. Banish "ledger-repair" false-greens.
- **Write-path verification** — Real database writes are required for DB-backed projects, preventing fail-closed reads from silently hiding missing tables.
- **Drift Probe validator** — New `validate-schema-drift.sh` script to statically check for migration-repair footguns and query target databases to verify schema parity. Integrated into `/speck-recheck` and validation report templates.

### Clean-Build UX-RC LARP (#64 G2)
- **Stale build-cache protection** — Any formal `UX-RC` or higher claim now strictly requires a clean production build (build cache cleared, e.g., Next.js caches) of the SHA under test to prevent incremental compiled asset false-greens. Added to evidence-contract §8/§13/§14, `speck-larp` skill, and validation templates.

### Full-Gate Delegated Sub-agents (#64 G3)
- **Full pre-commit validation** — Sub-agent return contracts now require running and reporting the project's full pre-commit gate checks (eslint, tsc typecheck, tests, build, banned-language) under `gate_checks` rather than tests+typecheck alone. The conductor's Verify-Skills Gate enforces this to block "simulated" green merges.

### Traceability-Matrix Retrofit & Pilot Gating (#64 G4)
- **Retrofit / Finalization Mode** — Supports seeding matrices directly from existing audits or code scans on pre-built epics, allowing consolidated high-level rows citing fine-grained backing references in a new `Backing` column.
- **`pilot-gated` lifecycle status** — Traceability matrices now support `pilot-gated` as a terminal status under `--require-evidence` to track pilot-only deferred commitments with backing refs.
- **Matrix test suite** — New `validate-traceability-matrix.test.sh` to fully verify mapping successes, pilot-gated validations, and failures.

## v7.14.2 — 2026-06-16 — banned-language-lint macOS + upgrade-commit regressions (Speilet V5–V6)

Speilet feedback on v7.14.1: the upgrade that shipped E002 V1–V4 could not be committed on macOS without `--no-verify`. Two regressions in `banned-language-lint.sh` blocked every commit (V5) and false-positive on Speck framework files during upgrade commits (V6).

### Bug fixes (P0/P1)
- **V5 — bash 3.2 empty-array crash** — Restored empty-safe `set -- ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}` on line 40. Pre-commit always invokes `--staged` with no extra args; expanding empty `"${EXTRA_ARGS[@]}"` under `set -u` crashes macOS default bash 3.2 before any scan runs.
- **V6 — staged-mode path scoping** — `--staged` now mirrors non-staged scope: only `src/`, `app/`, `pages/`, `components/`, `public/`, `locales/`, `i18n/`. Framework (`.speck/`, `.cursor/`), `specs/`, and profile docs are excluded — so a Speck upgrade commit staging dozens of methodology files no longer false-positives on ordinary English in Speck's own docs.
- **Regression tests** — New `banned-language-lint.test.sh` wired into `npm test` (empty-array idiom + staged scoping).

## v7.14.1 — 2026-06-16 — Integration Smoke, Cap Integrity, API-RC, Validator UX (Speilet E002 learnings)

Speilet E002 build/validate feedback (V1–V4). An LLM epic passed `/epic-validate` at IMPL-GREEN and a full adversarial `/audit` with the external model never called — mocks and code review structurally could not see transport failures. This release closes that gap plus readiness-cap laundering and validator false positives.

### Methodology (P1)
- **`INTEGRATION-GREEN` readiness state** — New gate between IMPL-GREEN and UX-RC/API-RC: for each external service in evidence-contract §7, at least one real round-trip must succeed before claiming integration-green (catches 429/auth/payload failures mocks cannot see). Documented in `evidence-contract.md` §8, AGENTS.md readiness table, `/story-validate` + `/epic-validate`.
- **Cap Status: evidence-pending vs implementation-pending** — Deferral tables in story/epic validation reports now require `Cap Status`. `implementation-pending` (unbuilt code path) caps verified state at `NO-SHIP` — cannot launder unbuilt code as IMPL-GREEN. Enforced in `/story-validate` + `/epic-validate`.

### Methodology (P2)
- **`API-RC` evidence partition** — Backend analog of UX-RC partition in `evidence-contract.md` §8: autonomous (schema tests, operational walkthrough, DX quickstart) vs human/creds-gated (live sandbox creds, compliance scans, prod load). `/epic-validate` explicitly declares `API-RC` for backend epics.
- **Validator false-positive fixes** — Placeholder scanner skips bracketed code tokens in prose (`[BULK_MODEL, ESCALATION_MODEL]`, paths with extensions). Story-spec user-story regex accepts `As a|an|the`. Regression tests added.

## v7.14.0 — 2026-06-10 — Anti-Simulation, Promise Conservation, Concurrency Hardening (Flyt E002 learnings)

Flyt E002 feedback (Parts 1+2) + GH issues #62/#63. Speck's gates verified *construction quality* but not *skill execution* (Part 1) nor *contract coverage* (Part 2) — both biggest failures were founder-caught, not gate-caught. This release closes both with verifiable delegation and a promise-conservation law backed by a real blocking validator.

### Methodology (P1)
- **Promise Conservation (the conservation law)** — Every enumerable upstream promise (product-contract §, each FR/NFR, every wireframe screen/element/state, every experience-chain seam) gets a `PRM-NNN` row in the new `traceability-matrix.md` and MUST resolve to a story+AC, a DEC descope, or a visibly-open row. Produced by `/epic-plan` (which now loads `product-contract.md` + `experience-chain.md` — previously a real gap), blocked on by `/epic-analyze` (unmapped row = P1), cited by `/story-validate`, and re-walked with evidence by `/epic-validate`. Enforced by `validate-traceability-matrix.sh` (default + `--require-evidence` modes), wired into pre-commit and `/recheck` (`PROMISE_DRIFT.P1`).
- **Design docs are promises** — "Wireframes are inspiration" is now banned. A drawn element or stated seam is a commitment: enumerate it into the matrix or DEC it out. Doctrine added to AGENTS.md + wireframes/experience-chain templates.
- **Anti-simulation: Verify-Skills Gate** — Orchestrators (`/epic`, `/story`) and any conductor MUST verify ≥2 real skill invocations (`speck-audit` + `story-validate` for stories) and template-compliant reports before accepting a delegated result. New sub-agent return contract `{ readiness_state, pass, p0p1, artifact_paths, skills_invoked }`. Never merge on a self-reported verdict; advance on evidence, not file-presence.
- **Chaining/continuation** — `story-specify`, `epic-specify`, and `speck-audit` closers no longer read as turn boundaries in orchestrated/background runs — proceed to the next step; the menu shows only in interactive single-step mode.
- **Autonomous-vs-gated UX-RC partition** — `evidence-contract.md` §8 splits UX-RC evidence into AUTONOMOUS (production build + browser/headless LARP + stored axe JSON + JTBD walkthrough — never deferrable) vs HUMAN/CREDS-GATED (live provider sends, human panels, live NFR). Cannot sit at "IMPL-GREEN, UX-RC deferred" while the autonomous portion is undone. Resolves the prior dev-server vs built-artifact tension. `/epic-validate` + `/speck-larp` now drive the real built app and store axe JSON. Validation report templates require each deferral classified `autonomous-not-done` (blocker) vs `human/creds-gated`.
- **Parallel-epic-execution pattern** — New `.speck/patterns/learned/process/parallel-epic-execution.md` (conductor + durable orchestration-ledger that survives compaction/spend/rate-limit resets, with verify-skills gate and concurrency guards baked in) + `orchestration-ledger-template.md`.

### Concurrency hardening (P1/P2)
- **Push-before-spawn** — `git push origin main` the planning corpus before spawning any worktree wave (worktrees branch from `origin/main`, not local HEAD) + sub-agent precondition guards.
- **Worktree disk hygiene** — Mandatory `git worktree remove --force` after each merge; disk is shared cross-session state (E002 hit `ENOSPC` across ~35 worktrees, froze every session).
- **Migration version coordination** — Require real wall-clock `date -u +%Y%m%d%H%M%S` (not rounded placeholders) + per-epic offset bands (E002 and E003 both picked `…120000`).

### Bug fixes (P2)
- **#62** `settings-drift-check.sh` — replaced `mapfile` (bash 4+) with a portable read-loop so it runs on macOS default bash 3.2; added a `.speck/scripts` portability lint to the test suite to keep `mapfile`/`readarray` out.
- **#63** `banned-language-lint.sh` — the §7 extractor now splits column-1 terms on `/` and `,` into individual phrases (so `"exposes" / "reveals"` actually matches prose); dropped `specs/` from the default scan scope (no more self-flagging on product-contract §7); added whole-word (`-w`) matching so `tone` no longer trips on `atone`.
- `validate-readiness-evidence.sh` — now also scans `screenshots/` and `larp-evidence/` (not only `larp-recordings/`); guarded empty-array expansion that crashed on bash 3.2; rejection text rewritten to guide-not-block.
- `validate-visual-assets.sh` — SVG-tag check rewritten as robust glob match (was a `=~` regex syntax-error risk).
- `validate-template.sh` placeholder rejection rewritten to guide-not-block (points agents to invoke the producing skill, not hand-write around the check).
- Supabase recipe + skill note: bundle secret-scans MUST allowlist public env prefixes (`NEXT_PUBLIC_*` / `PUBLIC_*` / `EXPO_PUBLIC_*`) — the anon key is public by design.

## v7.13.3 — 2026-06-07 — Concurrent Multi-Epic Execution (Flyt platform learnings)

Flyt concurrent-epic methodology feedback (2026-06-07): first-class doctrine for running 2+ epics in parallel without truth-artifact merge races.

### Methodology (P1)
- **Concurrent Multi-Epic Execution** — New AGENTS.md doctrine: worktree-per-epic isolation, daily rebase cadence, DEC bands, project-state merge-only regen, migration ownership, and epic concurrency waves.
- **Epic Concurrency Waves** — `epics-list-template.md` + `/project-plan` require wave assignment (parallel slices vs integrator epics) with rebase cadence for Platform / 4+ epic projects.
- **project-state merge-only** — `/project-state` skips local overwrite on `epic/*` branches; regeneration deferred to merge-to-main.
- **Per-epic DEC bands** — `/speck-decision-log` assigns IDs within epic bands (`E002` → `DEC-0201+`) instead of global sequential grab.
- **Parallel epic spawn** — `/speck` pre-routing validates wave safety and sets up worktrees before routing to `/epic`.

### Papercuts (P2)
- **Migration ownership rule** — Documented in AGENTS.md + epics template: own-your-tables, freeze foundation/shared tables, mandatory 14-digit UTC migration timestamps.

## v7.13.2 — 2026-06-06 — Redesign Pivot Refinements (Streb E011→E012 learnings)

Streb redesign-pivot methodology feedback (2026-06-06): closes transformational-product blind spots and validator papercuts.

### Methodology (P1)
- **Ambition-Aware UI Path** — `/epic-specify` Optional Step Evaluation now loads `product-contract.md` / `ux-strategy.md` and flags **Redesign Ambition** when brownfield code exists but differentiating surfaces require a first-principles redraw. Rubric Mode is prohibited unless founder explicitly confirms surfaces are modality-adequate.
- **Promise-Coverage Check** — `/epic-analyze` and `/project-analyze` map differentiator pillars + magic moments to stories/FRs; zero coverage flags as **P1 unaddressed-promise gap** (absence detection, not just contradiction).

### Papercuts (P2)
- **Forbidding-Context Language Guards** — `banned-language-lint.sh` + `filter-forbidding-context.py` ignore hits in `NOT This` / `Banned` / `Avoid` table columns and forbidding blockquotes.
- **Staged Banned-Language Lint** — `--staged` mode scans only git-staged files; wired into pre-commit hook.
- **`validate-epic-spec.sh`** — Parses `X-Y` story estimate ranges (uses max); fixes overview-length heuristic (awk instead of BSD sed alternation bug).
- **Decision Log Index Reconciliation** — `speck-decision-log` scans `### DEC-NNNN` headings as source of truth; auto-rebuilds missing/stale index tables.
- **Staleness False-DRIFT Fix** — `staleness-check.sh` uses `git rev-list --count` on the artifact; count ≤ 1 = FRESH after normal stamp-then-commit flow.

## v7.13.1 — 2026-06-06 — Form Validation Matrix, Test Hygiene, Keystone Pattern, /harden flow

Flyt E001 platform-run methodology feedback (2026-06-06): closes gaps between green gates and real human done-ness.

### Methodology & Templates
- **Form Validation Matrix** — Added required `Form Validation & UX State Matrix` to `ui-spec-template.md` (field -> rule -> exact inline message, Submit Pending, Double-Submit Protection, Aria-Live announcements) and updated `story-ui-spec` skill.
- **Pass-Count Honesty & Test Hygiene** — Added tautologies (`expect(true).toBe(true)`), silent collect-time skips, and API-bypassed forms to `evidence-contract-template.md` Invalid Proof Sources (anti-proof). Enforced in `speck-audit` Step 10d.
- **Keystone Dependencies Pattern** — Codified human-provisioned credentials skip-with-reason rules in `evidence-contract-template.md` Section 8, and integrated skip caps into `story-validate`.
- **Primary JTBD Cold-Start LARP** — Elevated cold-start E2E LARP as the mandatory primary gate for `epic-validate`, with graceful degradation rules for parallel subagent watchdog stalls.
- **Mandatory Deferrals/Not Verified Disclosures** — Added required `What this validation did NOT verify / Deferrals` section to story/epic validation reports.
- **Resilient Regex Parser** — Updated `validate-story-spec.sh` to gracefully accept both `**Status**:` and `**Current State**:` header tags.
- **Artifact-Config Drift (SHIP-RC Class)** — Explicitly defined baked envs, redirect allowlists, signing certificates, and native webview wrapper behaviors as a `device-walk` (SHIP-RC) class, preventing false `UX-RC` claims on dev server builds.
- **Boundary-Crossing Error Attribution** — Generalised error boundary requirements in `speck-audit` Step 9c to ensure caught errors spanning multiple boundaries (e.g. SDK + own backend) distinguish exactly which boundary failed.

### New Skills & Flows
- **`/harden` flow** — Introduced lightweight post-validation fix lifecycle skill and template (`harden-template.md`) to capture post-ship defects, root causes, regression guards, and readiness re-assessments without full spec/plan/tasks ceremony.

## v7.12.1 — 2026-05-31 — Rendering Gotchas, Asset Drift, Brownfield Rubric Mode

Splang methodology feedback (2026-05-31): closes gaps in what truth artifacts and drift detectors track.

### Methodology
- **Rendering Gotchas** — `## Rendering Gotchas` table in `primitives-registry-template.md`; `/audit` step 10b and visual-quality skill grep anti-pattern signatures from `design-system/primitives.md` (correct code, wrong pixels).
- **Asset single-source** — Single-Source Rule in `design-system-template.md`; new `asset-drift-check.sh` flags duplicate SVG path geometry across 2+ files; wired into `/recheck` as `ASSET_DRIFT.P1`.
- **Brownfield Rubric Mode** — `/epic-specify` branches greenfield vs brownfield UI: existing surfaces use Rubric Mode (shared Screen Rubric in ux-strategy/primitives.md) instead of per-surface journey + wireframes.

## v7.11.1 — 2026-05-31 — Unified README (canonical `.speck/README.md` + root symlink)

### Documentation
- **Single canonical README** — Merged root installation/update/contributor sections into `.speck/README.md` (methodology + setup in one place).
- **Framework repo symlink** — Root `README.md` is now `README.md → .speck/README.md` so GitHub visitors see the full guide; user projects unchanged (CLI still syncs only `.speck/README.md` and preserves project PROFILE README).

## v7.11.0 — 2026-05-31 — Template-Drift Detection, Numeric JTBD Scoring & Quality-Judgment Loop

Addresses GitHub Issue #60 (methodology — evidence quality and judgment gaps).

### Core Features
- **Intra-v7 Template-Drift Detection** — Added `template-manifest.json` and `check-artifact-template-drift.sh` to recursively check instantiated artifacts for missing required template sections. Wired into `speck upgrade` output, `/recheck`, and `/speck-catch-up --phase=refresh`.
- **Numeric JTBD Scoring & Quality-Judgment Loop** — Added canonical 0-10 scoring protocol with hard caps (completeness ceilings, active findings caps) to `evidence-contract-template.md`. Scorecards added to story and epic validation reports.
- **Anti-Theater Scorecard Validator** — Programmatic validation in `validate-readiness-evidence.sh` to flag reused note inflation and "all 10s" claims with active findings.
- **`speck validate --active-only`** — Skip historical or excluded legacy artifacts during validation to prevent hook bypass pressure on migrated projects.

### Templates
- **`product-contract-template.md`** — Added Signal -> Reaction Ledger, Human Language Pass guidelines, and Density Budget prompt.
- **`evidence-contract-template.md`** — Added Quality Judgment & Scoring Protocol, Longitudinal Proof Mode, and LARP Runway.
- **`persona-larp-template.md`** — Added +2 taste-rubric rows ("Surface economy" and "Progressive disclosure"), Longitudinal Proof Mode timeline requirements, and Build Fingerprint fields.
- **`story-template.md` & `validation-report-template.md`** — Added Human Language Pass, JTBD Quality Scorecard, and template versioning.
- **`epic-validation-report-template.md`** — Added Epic JTBD Quality Scorecard and Human Language Pass.

## v7.10.1 — 2026-05-26 — Orchestrator driving pattern correction

**Fixes v7.10.0 regression**: `/story` and `/epic` orchestrators incorrectly documented that sub-skills should NOT be invoked. That was wrong.

### Skills
- **`/story` and `/epic`** — **REQUIRED** driving pattern: invoke each downstream skill's `SKILL.md` in canonical order; explicit ANTI-PATTERN list for inline artifact authoring without skill invocation
- Epic orchestrator MUST delegate per-story work to `/story`

## v7.10.0 — 2026-05-26 — E000 execution feedback (templates, patterns, validators)

Incorporates post-E000 feedback: version-pin freshness, typecheck in verification, orchestrator clarity, feedback round-trip visibility, and validator fixes V6/V7.

### Templates (P1–P2)
- **`epic-tech-spec-template.md`** — Version-Pin Freshness Check with `npm view` command + verification table
- **`tasks-template.md`** — Phase 5 verification includes explicit **typecheck** step (Vitest/esbuild masks strict TS errors)

### Skills (P3)
- **`/story` and `/epic` orchestrators** — ~~driving-pattern clarification: agent drives chain directly~~ **superseded by v7.10.1** — orchestrators MUST invoke downstream skills

### Methodology docs (P5–P6)
- **`.speck/templates/feedback/template.md`** — canonical feedback file structure (symptom + repro + patch + proposal)
- **`.speck/patterns/constitution-as-code.md`** — Platform pattern for ESLint/CI mechanical constitution enforcement
- **`.speck/scripts/banned-language-lint-staged.sh`** — lint-staged wrapper with auto project-dir detection

### CLI (P4)
- **`speck upgrade`** — prints which prior feedback items (V1–V7, H1–H4, P1–P6) are addressed by the upgrade

### Validators (V6–V7)
- **`validate-artifact-docs.sh`** — aligned to v7 AGENTS.md routing; deprecated `epic-outline.md`/`outline.md` removed; README gaps advisory only
- **`validate-recipes.sh`** — validates `extends:` chain integrity (missing parents, cycles); wired into CI

## v7.9.2 — 2026-05-25 — larp-play import fix

- **`larp-play.js`** — remove unused `readlineInteractive` import from `feedback.js` (would fail at module load if the export is absent)

## v7.9.1 — 2026-05-25 — Validator robustness pass

Fixes five false-positive / lifecycle-blindness classes in the pre-commit validation pipeline reported during a Platform-level E000 session (see `feedback.md`).

### Pre-commit hook (V1)
- **`pre-commit-hook.sh`** — empty `staged_specs` array no longer fails with `unbound variable` under `set -u`; early-exit before array expansion when no specs or README are staged

### Placeholder scanner (V2–V4)
- **Multi-line bracket false-positive** — bracket regex constrained to single lines (`[^\]\n]+`) so multi-line TypeScript/JSON/YAML blocks are not treated as one giant placeholder
- **Fenced code block skip** — Python scanner ignores all content inside ` ``` ` blocks (eliminates substring hits like `[{ "name": "next" }]`)
- **Generic-ID descriptive references** — `FR-XXX`-style mentions in citation context (`(e.g. FR-XXX)`, `-style`, `no FR-XXX`, `descriptive`, etc.) no longer flagged as unreplaced template tokens

### Story spec lifecycle (V5)
- **`validate-story-spec.sh`** — `Draft (Placeholder)` specs from `/epic-breakdown` get loose validation (YAML frontmatter + Draft checkbox only); full user-story/FR/Purpose gates engage once `/story-specify` advances to `Specified`

### Regression tests
- **`.speck/scripts/validation/test-fixtures/`** — known-good fixtures for each false-positive class
- **`validate-template.test.sh`** — wired into `npm test`

## v7.9.0 — 2026-05-25 — Visual assets pipeline + autonomous LARP playback

Engine-and-Steering-Wheel release: deterministic CLI engines for LARP playback, context compaction, learning-tag enforcement, and programmatic validation gates — all wired into skills so agents never need to "break the glass."

### Autonomous LARP Player
- **`speck larp-play`** — headless Playwright playback of persona scripts from `personas/*.md`; guided manual walkthrough fallback when Playwright is unavailable
- Captures screenshots and accessibility trees to `larp-recordings/` for evidence-backed validation

### Learning-tag commit hook
- **`.speck/scripts/validation/commit-msg-hook.sh`** — enforces `PATTERN:` / `GOTCHA:` / `PERF:` / `ARCH:` / `RULE:` / `DEBT:` tags on code commits
- Platform play level: hard block; Build/Sprint: friendly warning
- Auto-installed via `speck upgrade` / `speck init` sync (`installCommitMsgHook` in `sync.js`)

### Context compaction
- **`speck compress`** — bundles validated epic story folders into `.speck/archive/<project>-<epic>-stories.tar.gz`; generates `validated-summary.md`
- **`speck decompress`** — restores story directories on demand

### Visual assets pipeline
- **`design-system-template.md`** — Visual Assets Registry section
- **`ui-spec-template.md`** — Declared Visual Assets Manifest table
- **`story-tasks`** skill — auto-generates asset creation tasks from ui-spec manifest
- **`validate-visual-assets.sh`** — programmatic SVG/WebP existence and well-formedness checks

### Readiness evidence + pre-impl gates
- **`validate-readiness-evidence.sh`** — blocks `UX-RC`+ claims without `larp-recordings/` evidence files
- **`check-story-prereqs.sh`** — deterministic gate before `/story-implement` (spec/plan/tasks/analysis-report)
- **`story-validate` / `epic-validate`** — local-first multi-modal visual review instructions for agents (Read tool on screenshots)

## v7.8.0 — 2026-05-25 — Claude settings sync + lifecycle Stop hook

Fixes Stop-hook infinite loops on epic/project sessions and closes the silent-drift gap for `.claude/settings.json`.

### Stop hook (H1)
- **`.claude/hooks/stop-gate.sh`** — command-type Stop gate; lifecycle-scoped by directory walk
- Story directories: informational `tasks.md` / YAML status checks only
- Epic/project/workspace: never gates on `tasks.md` — eliminates prompt-loop token waste

### Settings reconciliation (H2 + H4)
- **`_speck_managed`** sentinel in `settings.json.example` — Speck owns `hooks.Stop`, `hooks.SessionStart`, `hooks.PostToolUse`
- **`packages/cli/lib/claude-settings.js`** — drift detection + reconcile preserving user `permissions`, `env`, custom hooks
- **`speck reconcile-settings`** CLI command (`--dry-run` supported)
- **`speck upgrade` / `speck init`** auto-reconcile Speck-managed blocks after sync

### Drift detection (H3)
- **`.speck/scripts/settings-drift-check.sh`** — `SETTINGS_DRIFT.P0` for managed-block diffs + legacy prompt Stop hooks
- **`/recheck`** skill runs settings drift in parallel with PROFILE drift
- **`speck feedback`** surfaces SETTINGS friction signals

### Upstream (H5)
- Documented ask: Claude Code Stop hooks could support `cwd_matcher`, `max_iterations`, and prompt-type exit semantics — filed as coordination need in feedback channel

## v7.7.0 — 2026-05-25 — PROFILE pillar enforcement

Completes PROFILE as a structurally enforced fourth pillar (validators, readiness gates, graded drift, multi-surface hooks).

### Structural enforcement
- **`validate-readme.sh`** + **`profile-drift-check.sh`** — P1/P2/P3 graded drift; README validator mirrors product-contract validators
- **Pre-commit** validates staged root `README.md` via `validate-profile.sh`
- **`evidence-contract.md`** — PROFILE Gate Criteria subsection under Section 7 readiness gates
- **SHIP-RC+** blocked on `PROFILE_DRIFT.P1` (story-validate, project-validate, recheck)

### Propagation
- **`speck upgrade`** auto-runs README footer regen via `runReadmeRegen()`
- **`regenerate-project-readme.sh`** — `--check`, `--surface=package|landing`, `--epic-validated=E###`, `PROFILE:AUTO-SYNC` markers
- **Epic validate/retro** updates README magic-moments / recently-validated sections
- **`/speck-catch-up --phase=profile`** — brownfield backfill for v7.6→v7.7 projects

### Templates + skills
- `project.md` PROFILE surfaces table; `ui-spec-template.md` PROFILE impact section
- `readme-template.md` magic-moments + recently-validated tables
- Updated project-readme, recheck, catch-up, story-validate, project-validate skills

## v7.6.0 — 2026-05-25 — README ownership + PROFILE pillar

Minor release fixing root README identity confusion and introducing PROFILE as a fourth methodology pillar.

### Root README ownership (CLI)
- **Behavior Before**: `speck init` copied Speck marketing content to root `README.md`. `speck upgrade` silently overwrote it whenever the first line still read `# Speck 🥓`.
- **Behavior After**: Init writes a project skeleton from `.speck/templates/project/readme-template.md`. Upgrade merges only the `<!-- SPECK:START -->` footer, auto-repairs legacy Speck-marketing READMEs, and never copies the Speck repo README to projects.

### `/project-readme` skill + regeneration script
- New `.speck/scripts/regenerate-project-readme.sh` fills scaffold sections from `project.md`, `product-contract.md`, and `project-state.md` while preserving user-edited content.
- Wired into `/project-specify`, `/project-product-contract`, `/project-state`, `/recheck`, and `/speck-catch-up` finalize — README evolves with the canonical workflow, not manual-only.

### PROFILE pillar
- Extended mental model: PROMISE → BUILD → PROVE → **PROFILE** (public face).
- Root `README.md` is the center-of-gravity PROFILE artifact; drift vs `product-contract.md` flagged on `/recheck`.

### Other
- `speck feedback`: fixed workspace `.speck/project.json` detection; added PROFILE friction signals.
- Docs updated for dual-README distinction (root vs `.speck/README.md`).

## v7.5.2 — 2026-05-25 — Pre-commit placeholder false-positive fix

Patch release tightening the template placeholder scanner so legitimate spec content no longer blocks commits.

### Pre-commit placeholder validation
- **Behavior Before**: The placeholder scanner (added in v7.5.0) flagged any bracketed text with a space as an unreplaced template token — including SHA stamp footers, prose annotations like `[moved E007]`, and lines that cite template markers in passing.
- **Behavior After**: Allowlists SHA stamp footers, skips citation-context lines, and only flags brackets that match known template placeholder patterns. Documented `git commit --no-verify` as the intentional bypass in `pre-commit-hook.sh`.

## v7.5.1 — 2026-05-25 — Methodology ordering fixes and timeless templates

Patch release correcting misleading phase guidance and removing historical version chatter from core templates.

### 1. Project-validate ordering (skills)
- **Behavior Before**: Several skills (`project-plan`, `project-architecture`, `speck`) suggested running `/project-validate` immediately after planning or `/project-analyze`, before epic implementation — treating it as a design go/no-go gate.
- **Behavior After**: Skills now state that `/project-analyze` is a planning-phase quality check and `/project-validate` is strictly the final post-implementation release gate (after all epics are validated).

### 2. Timeless template copy (no narrative version labels)
- **Behavior Before**: Core templates embedded comparative copy (`Speck v7`, `v6`, `v7.2+`) in comments and hardcoded `speck v7.0.0` footer examples, leaking migration history into every new project artifact.
- **Behavior After**: Sanitized `product-contract`, `evidence-contract`, `project-decisions-log`, `experience-chain`, and `story` templates — version-neutral guidance, `PLACEHOLDER CONVENTION` without version suffixes, and `Speck Version` fields left for `stamp-truth.sh` at verify time.

## v7.5.0 — 2026-05-25 — Speck v7 Script Consolidation & Contract Validation

Speck v7.5.0 completes our validation coverage by introducing first-class template validators for the project-level contracts (Product Contract and Evidence Contract), while consolidating duplicated v7 scripts to enforce a single source of truth.

### 1. Script Consolidation & Symlink Parity (Single Source of Truth)
*   **Behavior Before**: Duplicate versions of core methodology scripts (like `stamp-truth.sh`, `staleness-check.sh`, `banned-language-lint.sh`) were maintained under `.speck/scripts/` and `.speck/scripts/v7/`. These versions frequently diverged, leading to silent bugs where older scripts were missing features (like dynamic version parsing).
*   **Behavior After**: Completely deleted legacy files (`migrate-to-v7.sh` and `add-recipe-evidence-defaults.sh`) and consolidated duplicated files under `.speck/scripts/v7/` into relative symbolic links pointing directly back to their parent folder equivalents. This establishes a clean, unified execution base with zero-drift.

### 2. First-Class Promise & Prove Contract Validators
*   **Behavior Before**: While story and epic template structures were strictly validated by git and editor hooks, the Product Contract (governing the Paid Promise) and Evidence Contract (governing target platforms and proof sources) were completely unvalidated, allowing incorrect or incomplete contract files to pass through unnoticed.
*   **Behavior After**: Built two brand new, custom validation scripts under `.speck/scripts/validation/validators/`:
    *   `validate-product-contract.sh`: Validates YAML frontmatter, enforces the existence of Sections 1 to 7, and strictly blocks unreplaced `REPLACE_BEFORE_SHIP` placeholders.
    *   `validate-evidence-contract.sh`: Validates YAML frontmatter, enforces the existence of target platforms, valid/invalid proof sources, and sections 1 to 6.
    *   Updated the central `validate-template.sh` router to automatically parse and dispatch `product-contract.md` and `evidence-contract.md` files to their new validators.

## v7.4.0 — 2026-05-24 — Speck v7 Claude-First Compatibility & Advanced Orchestration

Speck v7.4.0 is a major upgrade leveraging modern Claude Code automation, scheduled loops, and specialized agent teams, while establishing a robust, host-agnostic validation core that guarantees zero regressions and flawless compatibility for Cursor and Codex.

### 1. Unified Validation Core & Single Source of Truth
*   **Behavior Before**: Template validators (e.g. `validate-story-spec.sh`, `validate-story-tasks.sh`) lived in Cursor-specific directories under `.cursor/hooks/hooks/validators/`. This made validation logic unavailable to other environments unless manually duplicated, causing spec-checking behavior to diverge across tools.
*   **Behavior After**: Centralized all template validation rules into a unified, host-agnostic bash core under `.speck/scripts/validation/validators/`, reducing duplicate code by over 1,100 lines. All hosts (Claude Code, Cursor, Codex, and CI) now call the exact same validation engine.

### 2. Claude-Native Hooks and settings.json Safeguards
*   **Behavior Before**: Non-interactive template validation was only available on Cursor via `afterFileEdit` hooks, while Claude Code had no automated spec enforcement or session safeguards.
*   **Behavior After**: Overhauled `.claude/settings.json.example` to declare narrow, safe Claude hooks:
    *   **`PostToolUse` (Edit|Write)**: Intercepts file edits via a custom adapter at `.claude/hooks/after-file-edit.sh` to validate markdown specs on the fly.
    *   **`SessionStart` (Compaction Reminders)**: Automatically re-injects `project-state.md` into the LLM context at start and compaction, preventing context-rot during long turns.
    *   **`Stop` (Exit Gates)**: Intercepts exit prompts to verify task completion and decision log status before allowing the session to close.

### 3. Dynamic Dual-Host MCP Config Merger
*   **Behavior Before**: MCP server setup and template sync guides were Cursor-exclusive, forcing Claude Code users to manually copy configurations and manage separate environments.
*   **Behavior After**: Created `.speck/mcp/servers.example.json` as the unified baseline source. Extended `.speck/scripts/bash/merge-mcp-config.sh` to generate local configs for BOTH Cursor (`.cursor/mcp.json`) and Claude Code (`.mcp.json`) simultaneously, with both safely gitignored to avoid secret leaks.

### 4. Specialized Checked-In Subagents
*   **Behavior Before**: Orchestrator commands only ran sequentially in the main conversation. Spawning specialized perspectives or running concurrent task teams was not structurally supported.
*   **Behavior After**: Checked in five custom subagents (`speck-scribe`, `speck-planner`, `speck-coder`, `speck-auditor`, `speck-validator`) under `.cursor/agents/` (cleanly symlinked to `.claude/agents/` and `.codex/agents/` via sync script). 
    *   **Worktree Isolation**: The `@speck-coder` is configured with `isolation: worktree` so it automatically implements tasks in a dedicated, conflict-free checkout of the codebase.
    *   **Agent Teams**: Users can now spin up parallel peer reviews or dual-implementations using Claude's teammate mode with custom roles (e.g. "@speck-coder" + "@speck-auditor").

### 5. Speck Maintenance Loops (`loop.md`)
*   **Behavior Before**: Spec drift, staleness, and scaffolding tokens could only be caught by manually triggering `/recheck` or waiting until a final validation command.
*   **Behavior After**: Checked in `.claude/loop.md` to establish a scheduled workspace guard. Running `/loop 1h` now automates staleness-checks, replace-marker scans, and lints dynamically in the background.

### 6. Host Capability Matrix & Fallbacks
*   **Behavior Before**: No explicit documentation outlining feature differences across platforms.
*   **Behavior After**: Added a dedicated **Host Capability Matrix** to `AGENTS.md` and updated key process skills (`speck-larp`, `speck-recheck`, `story-validate`) with clear fallbacks. If running on a host without subagents, the agent is directed to execute the same checklist items sequentially in the main context, maintaining complete procedural parity.

## v7.3.0 — 2026-05-16 — Speck v7 Generalization Tightening

Speck v7.3.0 introduces a major evolutionary step, transitioning Speck from a SaaS-focused web/mobile methodology into a **universally generalized, always-on development framework**. It resolves key cross-primitive orchestration gaps, enforces strict gate discipline, and introduces first-class project archetypes so that infrastructure, backends, internal tools, and client products are all spec-driven and validated with equal rigor.

### 1. Canonical Ordering Authority (`AGENTS.md`)
*   **Behavior Before**: Individual skill files (e.g. `project-specify`, `speck`, `story-ui-spec`) had their own ad-hoc "next steps" and "Smart Suggestions" sections. Agents reading these files would frequently diverge from the canonical phases in `AGENTS.md`, resulting in flow "split-brain" where they skipped required contract or context phases.
*   **Behavior After**: `AGENTS.md` is established as the **only** canonical ordering authority. All individual skills have had their ad-hoc suggestions normalized or stripped; they now explicitly redirect agents to `AGENTS.md`'s `## 📋 The Speck Command Phases` for phase transitions, while skills focus strictly on their own executional step.

### 2. First-Class Archetype Axis & System Proof Profile (PROMISE/BUILD/PROVE)
*   **Behavior Before**: Product contracts, evidence contracts, and validation checkpoints heavily overfit B2C/SaaS UI-heavy assumptions. Infrastructure, API, and pure backend epics were forced to include fake human personas, user-facing "banned words", and UI-based "magic moments", or bypass validation entirely.
*   **Behavior After**: Introduced `project_archetype` in `.speck/project.json` (values: `consumer_product`, `b2b_saas`, `internal_tool`, `infra_service`, `backend_api`). All core templates and skills adapt dynamically:
    *   **The Promise**: Under `infra_service` or `backend_api`, Section 1 ("Paid Promise") becomes the **Operational SLA**, Section 2 ("Primary Persona") becomes the **Primary Consumer/Client Service**, Section 4 ("JTBD Scorecard") becomes the **Operational Invariants Scorecard** (Latency, Throughput, Durability, Resiliency, Security), and Section 5 ("Magic Moments") becomes **Operational Milestones**. Section 6/7 transform into **API & System Taxonomy** and **Banned System Anti-Patterns**.
    *   **The Prove**: Pre-validation gates (`story-validate`, `epic-validate`, `/recheck`) automatically bypass human `/larp` for non-UI archetypes, requiring **System Operational Scenario Walkthroughs** (Options B stress-testing, schema conformance, concurrency race-condition lints, and connection pooling tests) instead.

### 3. Hard-Enforced Mandatory-Next Gates
*   **Behavior Before**: Agents could finish `story-implement` and immediately jump into editing or specifying a completely different story, leaving implementation un-audited or un-validated, propagating spec/code drift.
*   **Behavior After**: Stateful, hard-coded checks now block drift:
    *   `story-implement` completion strictly requires `/audit` then `/story-validate` next. Transitioning to another story's tasks or code is blocked until validation passes.
    *   Starting or specifying a new epic via `/epic-specify` is blocked if any prior completed epic in the workspace is outstanding validation (unless it is the Infrastructure `E000` epic).

### 4. First-Time Comprehension Gate & Evaluative Change Explanation
*   **Behavior Before**: Validation reports passed if components rendered and tests succeeded, completely ignoring whether a first-time user actually understood what they were looking at, why it mattered, or what to do next.
*   **Behavior After**:
    *   All UI validation gates (`story-validate` and `epic-validate`) now enforce a **First-Time User Comprehension Rubric** (What am I seeing? Why does it matter? What do I do next?). If user comprehension is blocked or has friction (scoring ❌ on visual clutter or clear calls-to-action), the UI validation **fails**, and the verified state is hard-capped at `IMPL-GREEN`.
    *   Any evaluative step (`/story-validate`, `/epic-validate`, `/recheck`) that changes or overrides a previous verdict/rating is required to write an explicit `### Evaluative Drift / Change Explanation` section documenting the exact reasoning.

### 5. New Orchestration Wrapper Commands (`/epic`, `/story`)
*   **Behavior Before**: Users and agents had to manually invoke separate, granular phase commands (specify → clarify → plan → tasks → implement → validate) sequentially, leading to execution lag and high command overhead.
*   **Behavior After**: Created two stateful wrapper skills (`/epic` and `/story`) that act as deterministic orchestrators. They automatically scan the workspace, detect the active item's current lifecycle state, resume the sequence, and execute downstream commands step-by-step, halting only on genuine decision-gates (unlocked questions) or P0 quality/drift findings.

### 6. Minimalist Scaffolding Bootstrap
*   **Behavior Before**: Initializing a new project generated placeholder templates for all nine possible documents (`PRD.md`, `architecture.md`, `ux-strategy.md`, etc.) immediately. This cluttered the directory and confused state engines, making it appear that those phases were complete when they were actually empty stubs.
*   **Behavior After**: The `create-new-project.sh` script is strictly stripped back. It now scaffolds only the folder boundaries and `project.md`. All other artifacts are created and populated on demand by their corresponding canonical command phases (e.g. `/project-context` creates `context.md` only when run), keeping the workspace clean and honest.

---

## v7.2.0 — 2026-05-16 — Splang field-test response

Speck v7.2.0 is the first version shaped by **real field-test feedback** from a v6 → v7 upgrade on a 21-UI-epic, 12-ship-round brownfield project (Splang). The feedback was high quality and identified 10 concrete friction points that broke the v7.1.0 model at scale. v7.2.0 addresses every one of them.

### Recipe composition (F2 — biggest leverage)

Recipes can now compose. A recipe declares `extends: <parent-recipe>` and `overlay:` blocks; the loader walks the chain and shallow-merges the parent, then applies the overlay. List fields use `_additional` suffix to indicate append semantics.

- **New recipe**: `capacitor-wrapped-web` — `extends: react-fastapi-postgres` with iOS + Android native-shell evidence rules, store-launch epics, and native-shell bootstrap epic
- **Updated docs**: `.speck/recipes/README.md` now explains composition with worked examples
- Hybrid stacks (React + FastAPI + Postgres + Capacitor, e.g.) no longer require manual evidence-contract surgery

### Phased catch-up (F3 — makes large brownfield usable)

`/speck-catch-up` now accepts `--phase=<name>`:

```
/speck-catch-up --phase=triage         (Phase 0 only — produces migration-estimate.md)
/speck-catch-up --phase=contracts      (Phases 1+2)
/speck-catch-up --phase=decisions      (Phase 3)
/speck-catch-up --phase=epic-artifacts (Phase 4)
/speck-catch-up --phase=honesty        (Phase 5 — auto-detects 5a/5b/5c)
/speck-catch-up --phase=state          (Phase 6)
/speck-catch-up --phase=plan           (Phase 7)
/speck-catch-up --phase=finalize       (Phase 8)
/speck-catch-up --phase=all            (default — runs everything)
```

Large brownfield projects (10+ epics) can checkpoint and commit between phases instead of doing one giant change.

### Auto-detected Phase 5 honesty pass (F1)

Phase 5 now auto-detects which sub-mode applies based on what's on disk:

- **Mode 5a** — story-level `validation-report.md` files exist → per-story walk, downgrades unsupported PASS claims
- **Mode 5b** — only ship docs (`docs/archive/ship/SHIP_R*.md` etc.) exist → feature-area floor at IMPL-GREEN + per-magic-moment LARP requirements in catch-up plan
- **Mode 5c** — no prior readiness claims → no-op

Splang-shaped projects (ship-doc-only readiness records) now have a real honesty path instead of catch-up silently no-op-ing.

### REPLACE_BEFORE_SHIP markers (F4)

Templates now use the literal token `REPLACE_BEFORE_SHIP: <hint>` for placeholders that MUST be filled. Easy to grep, impossible to miss.

- New script: `.speck/scripts/check-replace-markers.sh` — exit code 1 if any token remains
- `/speck-recheck` now runs this scanner in its drift detection
- Any artifact carrying a `REPLACE_BEFORE_SHIP:` token cannot claim a readiness state above `IMPL-GREEN`
- The catch-up skill is required to replace every token in artifacts it fills

### Canonical retroactive caveat (F5)

The decisions-log template now ships with a `<!-- CATCH-UP-ONLY -->` caveat block that `/speck-catch-up` uncomments when reconstructing the log from git history. No more agents inventing their own retroactive-hypothesis language. Per-entry `Reconstructed: true` flag makes retroactive entries searchable.

### User-review surface (F6)

`project-state.md` now includes auto-populated appendices:

- **Sections Awaiting User Review** — every `[NEEDS USER REVIEW]` marker across truth artifacts, in one place
- **Outstanding REPLACE_BEFORE_SHIP markers** — every incomplete token, in one place

The user no longer has to grep for ambiguous sections — they show up on the first read.

### Feedback command (F7)

```bash
npx github:telum-ai/speck feedback --topic catchup
```

Drafts a `.speck/feedback/<date>-<topic>.md` file with auto-collected (non-source) context: workspace version, repo HEAD, projects detected, friction signals (e.g., un-filled scaffold banners, `REPLACE_BEFORE_SHIP:` token counts, `[NEEDS USER REVIEW]` counts, large catch-up plans).

**No network calls. No telemetry.** The file is yours. You decide whether to submit it as a GitHub issue. Topics: `catchup | migration | recipe | methodology | cli | docs | other`.

### Two-step upgrade messaging (F8)

The `npx speck upgrade` banner and `migration-report.md` now explicitly say:

1. This was step 1 (scaffolding)
2. **Do NOT commit yet**
3. Run `/speck-catch-up` on a `speck-v7-migration` staging branch
4. Bundle scaffolding + catch-up into one commit (or one PR for review)

No more confusing the user into committing scaffolded-template state to main.

### Migration estimate before commitment (F9)

`/speck-catch-up --phase=triage` now writes `migration-estimate.md` listing:

- Engagement triage table (what was found)
- Phase 5 mode (5a/5b/5c) and why
- Per-phase effort estimate (minutes/hours)
- Post-catch-up remediation backlog estimate (deferred to project-catch-up-plan.md)

Set realistic expectations before starting the long-running work.

### Brownfield experience-chain exemption (F10)

UI epics that pre-date v7 no longer block catch-up on `experience-chain.md`. Instead:

- New template: `.speck/templates/epic/experience-chain-historical-template.md` (`brownfield_exempt: true`)
- Catch-up Phase 4 generates one historical stub per pre-v7 UI epic from story specs + git history
- `/epic-plan` accepts the historical marker (won't refuse to run)
- `/epic-validate` generates the FULL `experience-chain.md` on the fly when the epic is next re-validated (deferred-generation pattern)
- New epics still require a real upfront chain — exemption is one-time, per-epic

Removes "20-hour silent debt" of v7 migration on UI-heavy brownfield projects.

### Other improvements

- `migrate.sh` marker append is now idempotent (re-runs don't duplicate)
- `stamp-truth.sh` reads version dynamically from `.speck/VERSION`
- CLI banner includes `feedback` command and links the staging-branch pattern

### Files added

- `.cursor/skills/speck-catch-up/SKILL.md` (rewritten for phases + auto-detection)
- `.speck/scripts/check-replace-markers.sh`
- `.speck/templates/epic/experience-chain-historical-template.md`
- `.speck/recipes/capacitor-wrapped-web/recipe.yaml`
- `packages/cli/lib/commands/feedback.js`

### Files updated

- Five templates (product-contract, evidence-contract, experience-chain, decisions-log, project-state) — `REPLACE_BEFORE_SHIP:` convention
- `.cursor/skills/speck-recheck/SKILL.md` — marker scanning
- `.speck/recipes/README.md` — composition primitive docs
- `.speck/scripts/migrate.sh` — staging-branch guidance + idempotent marker
- `packages/cli/bin/speck.js`, `packages/cli/lib/commands/upgrade.js` — feedback command + two-step messaging

### Migration from v7.1.0

No data migration. The new behavior kicks in on the next `npx speck upgrade`. If you upgraded to v7.0.0 or v7.1.0 already and have lingering scaffold-banner artifacts, run `/speck-catch-up --phase=triage` to see what needs filling.

### Acknowledgment

Thanks to the Splang field test for the high-quality feedback that shaped this release. The `SPECK_V7_UPGRADE_FEEDBACK.md` from that project is the template for how feedback should look. `npx speck feedback` exists to make that kind of feedback easier to produce going forward.

---

## v7.1.0 — 2026-05-16 — Brownfield catch-up + cleanup

The first follow-up to v7.0.0. Targets one specific gap: when a v6 project upgrades to v7, the migration script only scaffolds **empty** template artifacts. The project itself still carries v6 debt — over-optimistic PASS claims with no runtime evidence, surrogate proof from old validation reports, scattered specs that haven't been consolidated, decisions buried in git history rather than logged. v7.0.0 left it to the user to know they should run the seven individual filler skills.

v7.1.0 makes the brownfield catch-up **canonical and automatic**.

### Added

- **`/speck-catch-up`** — A new brownfield reconstruction skill. Treats a freshly-migrated project as a brownfield import and:
  1. Backfills `product-contract.md` from `project.md` + `PRD.md` + `ux-strategy.md` + `domain-model.md` + `constitution.md`
  2. Backfills `evidence-contract.md` from the active recipe's `evidence_contract:` defaults
  3. Reconstructs `project-decisions-log.md` from git history (architecture / design-system / plan commits + learning tags)
  4. Backfills `experience-chain.md` for each existing UI epic
  5. **Honesty pass** — for each existing story marked PASS in v6: cross-references with `evidence-contract.md`, downgrades unsupported claims to `IMPL-GREEN`, flags surrogate proof
  6. Regenerates `project-state.md` to reflect the post-honesty-pass reality
  7. Writes `project-catch-up-plan.md` with prioritized P0–P3 remediation work
- **`.speck/.migration-needs-catchup`** marker file — written by `.speck/scripts/migrate.sh` whenever it runs. Lists every project that needs catch-up.
- **AGENTS.md "First Actions" rule #1** — agents now check for the marker / scaffold banner on every engagement and run `/speck-catch-up` BEFORE any feature work
- **CLI `upgrade` output** — when v6 → v7 migration runs, the CLI's final banner now spells out exactly what catch-up does and why it's required, instead of pretending the scaffolds are sufficient

### Changed

- `.speck/scripts/migrate.sh` — scaffold banners now name `/speck-catch-up` as the primary path; the individual skills are the manual fallback
- `.speck/README.md` — "Migrating from v6" section rewritten as a two-step process (scaffolding then catch-up)
- Symlinks confirmed canonical: `.claude/{skills,agents}` and `.codex/{skills,agents}` are already symlinks to `.cursor/{skills,agents}` (git mode `120000`) — no work needed here, just confirmed during this release

### Removed

- `.speck/field-test-protocol.md` — internal release-prep doc that shouldn't have been distributed as part of Speck. Per-project field-testing is the user's responsibility, not something Speck prescribes globally.

### Migration

There is no migration required from v7.0.0 to v7.1.0. The new behavior kicks in:
- On the next `npx github:telum-ai/speck upgrade` (which syncs the new skill + updated migrate.sh + updated AGENTS.md)
- On the next engagement where an agent sees a v6 project being upgraded — the marker is detected, catch-up runs automatically

If you upgraded to v7.0.0 already and have lingering scaffold-banner artifacts, run `/speck-catch-up` directly.

---

## v7.0.0 — 2026-05-16 — Promise → Build → Prove

The biggest release in Speck's history. Speck shifts from *spec-driven development* (write specs, then code) to **evidence-driven specification** (every spec assertion compiles to evidence; every claim ties to runtime proof; every truth artifact is SHA-stamped against current HEAD).

**Migration is automatic.** Running `npx github:telum-ai/speck upgrade` from any v6 project will detect the major-version bump, sync the new files, and additively scaffold v7 artifacts into every project under `specs/projects/`. No deletions, no destructive moves. You can also run `npx github:telum-ai/speck migrate` at any time to re-run the migration idempotently.

### Three new pillars

| Pillar | Center-of-gravity artifact | What it carries |
|--------|----------------------------|------------------|
| **PROMISE** (the contract) | `product-contract.md` | Paid promise, differentiator, JTBD scorecard, magic moments, public/banned language, AI behavior contract, longitudinal axes |
| **BUILD** (the work) | `spec.md`, `tasks.md`, `experience-chain.md` | Reordered story spec (UX first, implementation last); mandatory `experience-chain.md` for UI epics; primitives registry |
| **PROVE** (the truth) | `project-state.md`, `evidence-contract.md`, runtime LARP | Auto-regenerated state, per-platform proof rules, persona-driven runtime evidence |

### New commands

- **`/recheck`** — Mandatory on engagement gaps. SHA-drift detection, persona LARP cold-start, third-party risk surface scan, principle compliance scan
- **`/larp [persona]`** — First-class runtime LARP per platform (driven by recipe `visual_testing` config). Produces checked-in evidence: screenshots, AX trees, transcripts, timings
- **`/audit`** — Adversarial skeptical audit between implement and validate. Auditor doesn't trust the implementer's report
- **`/project-state`** — Auto-regenerated single-page status. First read on engagement
- **`/project-product-contract`** — Creates `product-contract.md`
- **`/project-evidence-contract`** — Creates `evidence-contract.md`
- **`/epic-experience-chain`** — Required for UI epics; defines screen seams + emotional state
- **`/speck-skeptical-review`** — Anti-premature-commitment primitive (N≥3 alternatives with tradeoff scoring)
- **`/speck-decision-log`** — Append-only `project-decisions-log.md` at every phase boundary
- **`/speck-scan`** — Unified scan skill replacing project-scan / epic-scan / story-scan
- **`/speck-migrate`** — Idempotent v6→v7 migration (runs automatically on upgrade)

### New mechanisms (always-on, unconditional)

| Discipline | When | Why |
|------------|------|-----|
| First-read `project-state.md` | Every engagement | Single-page current state, replaces ad-hoc handoff docs |
| Engagement-gap `/recheck` | >2 weeks idle OR new agent pickup | Drift detection before any new feature work |
| Decision-lock log | Every phase boundary | Locked decisions with SHA + alternatives in `project-decisions-log.md` |
| Skeptical-review | Before any non-trivial proposal locks | N≥3 alternatives with tradeoff scoring + rationale |
| Skeptical `/audit` | Between implement and validate | Auditor independence from implementer |
| Runtime `/larp` | Every UI story/epic validate gate | Specs are hypotheses; runtime is truth |
| Readiness-state declaration | At every validate | One of NO-SHIP / IMPL-GREEN / UX-RC / COMMERCIAL-RC / SHIP-RC / SHIP |
| SHA stamps | On every truth artifact write | Detects drift; stale = "proposal" |
| Banned-phrase detector | In every agent self-summary | Phrases like "ready for launch" trigger re-audit |
| Banned-language lint | On every commit + at `/audit` | Catches terminology drift before it ships |
| Evidence-or-it-didn't-happen | Every validation gate | "Tests pass" is one signal, not proof |

### New readiness state taxonomy (replaces PASS/FAIL)

| State | Meaning | Gate criteria |
|-------|---------|---------------|
| `NO-SHIP` | One or more hard blockers remain | Default when blocked |
| `IMPL-GREEN` | Tests / lint / types pass | Unit + integration green |
| `UX-RC` | Primary user flows pass in target runtime | Persona LARP recorded against built artifact (not dev server) |
| `COMMERCIAL-RC` | Billing / entitlements / support / legal pass | Per `evidence-contract.md` (paid products only) |
| `SHIP-RC` | All core gates pass, pending release ops | Runtime LARP against launch build (not dev server) |
| `SHIP` | Production / live proof complete | Post-deploy smoke + healthcheck green |

### Subtractions and consolidations

- `AGENTS.md`: 1269 → ~330 lines. Now a table of contents + routing tree, not an encyclopedia
- `.speck/README.md`: 1535 → ~430 lines
- Story spec template **reordered**: user experience first, implementation last
- `domain-model.md`, `ux-strategy.md`, `constitution.md`, `design-system.md` standalone files are **optional at Build** (their content lives in `product-contract.md`); still required at Platform
- `architecture.md` optional at Build (required if 4+ epics — composition fallacy gate)
- `epic-outline`, `story-outline`, `story-analyze` deprecated with shims (folded into `/audit` + `/speck-skeptical-review`)
- `project-scan`, `epic-scan`, `story-scan` consolidated into single `/scan [level]` skill
- 20 domain skills (Stripe, Clerk, Supabase, Firebase, etc.) moved to lazy-loaded patterns library — no longer pre-loaded into every agent context

### Context-rot defenses

- Layered loading: `project-state.md` first, deeper docs on-demand
- SHA-stamped truth: stale artifacts revert to "proposal" status and cannot serve as inputs to downstream decisions until re-verified
- Canonical-doc routing tree in `AGENTS.md`: forbids non-canonical filenames in `specs/`
- File-size discipline: SKILL.md target ~150 lines, templates are checklists

### Recipes

- All 14 recipes (`.speck/recipes/*/recipe.yaml`) gained an `evidence_contract:` block with platform-specific valid/invalid proof sources, required LARP scope per readiness state, and required static/live-service evidence

### Migration mechanics

- `.speck/scripts/migrate.sh` — additive migration script (never deletes v6 artifacts)
- `.speck/scripts/stamp-truth.sh` — apply/update SHA stamp footer
- `.speck/scripts/staleness-check.sh` — detect drift between artifacts and HEAD
- `.speck/scripts/banned-language-lint.sh` — enforce product-contract banned language
- `.speck/scripts/banned-phrase-detector.sh` — flag methodology-hostile phrases in agent summaries
- `.speck/scripts/detect-version.sh` — version detection from `project.json` / frontmatter / footer
- `.speck/scripts/regenerate-project-state.sh` — hint script for project-state regeneration
- `.speck/scripts/add-recipe-evidence-defaults.sh` — one-off applied to v6 recipes during release prep
- CLI `upgrade` command **auto-detects** the v6→v7 boundary and runs the migration for every project — no user action required

### Compatibility

- v6 projects continue to work — the migration is additive
- v6 commands (`/story-analyze`, `/epic-outline`, `/story-outline`, `/project-scan`, etc.) remain present with deprecation notices in their descriptions pointing to their v7 equivalents
- Recipes are backward-compatible; the new `evidence_contract:` block is additive
- `speck_version` in `.speck/project.json` defaults to `7.0.0` for new projects; v6 projects get bumped automatically on upgrade

---

## v6.x

See git history. v6 was the spec-driven development era. v7 is the evidence-driven specification era.

---

*[as of SHA `6cdfad8` | verified 2026-05-16 | speck v7.2.0]*
