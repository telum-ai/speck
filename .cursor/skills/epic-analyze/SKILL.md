---
name: epic-analyze
description: Required, decorrelated adversarial analysis of the epic planning corpus — run after epic-tech-spec.md and epic-breakdown.md exist, before any story work begins. The lenses are run by reviewers who did NOT author the corpus; the mandate is 3 lenses at Build with 4+ epics, all 7 at Platform. An open CRITICAL blocks story work. FIRST ACTION after loading: read template at .speck/templates/epic/epic-analysis-report-template.md before any context loading or artifact generation.
disable-model-invocation: false
---


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Template First

**Before any other action** — read this template now using the Read tool:
```
.speck/templates/epic/epic-analysis-report-template.md
```
The template defines the required frontmatter, sections and column headers for `epic-analysis-report.md`. Reading it first ensures your cross-artifact analysis produces findings in the expected structure.

**Checkpoint**: After reading, note the top-level sections from the template. Then continue to "Why this is no longer optional".

---

## Why this is no longer optional (#106)

Until v10.3 this skill was opt-in at exactly the altitude where the author self-certifies. Field evidence at the project altitude says that does not hold, and nothing about the epic corpus makes it hold better.

Project `001-odd` produced its planning corpus through the **full canonical Build flow** — every skill entered, five `/speck-skeptical-review` primitives run at the locks, `/speck-premise-challenge` run on the surfaces, every strict validator green. The corpus still carried **1 CRITICAL and 13 HIGH defects**. None were found by any inline gate. All were found by one adversarial 7-lens pass run by reviewers who had not written the corpus.

Read why each inline primitive *could not* have caught them — this is mechanical, not a discipline failure:

| Primitive | What its aperture is | Why the defects were outside it |
|-----------|----------------------|----------------------------------|
| `/speck-skeptical-review` | ONE decision, at the moment it locks: N≥3 alternatives + tradeoffs | Enumerating alternatives for lock X says nothing about whether X contradicts lock Y, made in a different session against a different artifact. Its object is a decision, never a *pair* of decisions. |
| `/speck-premise-challenge` | ONE surface, judged by a hostile user: onboarding, empty state, paywall, error, celebration | A contradiction between the tech spec's stated seam and the breakdown's story boundaries has no surface and produces no felt-bad. Nothing in a taste instrument's aperture points at it. |
| Strict validators | ONE artifact, structurally: sections present, references resolve, shapes conform | `epic-tech-spec.md` and `epic-breakdown.md` can each be perfectly well-formed and still be unsatisfiable together. Both files are green; the *pair* is the defect, and no validator reads the pair. |

The common cause: **all three run BY the author, IN the authoring context, against artifacts the author just wrote.** Same author, same context, shared blind spots by construction. No single-artifact review can see a contradiction that only exists BETWEEN artifacts, and no self-review is incentivised to find the one finding that would force it to redo the work.

This is **P4** at epic-planning altitude: the adversary is structural, not a checklist. `/audit` already applies it after implementation (`speck-audit` step 1b, and its "independent auditor, never the implementer" rule). This skill is the same idiom, run before a single story is specified.

---

## Role separation — who may run a lens

Mirror `/audit`, do not invent a second scheme.

1. **A lens is run by a reviewer that did not author the corpus.** Concretely: a separate subagent (`@speck-auditor` or a general-purpose agent with the Skill tool), a separate session, or a different model. Whoever ran `/epic-plan` and `/epic-breakdown` does not grade them.
2. **Lenses run against the same corpus but do not see each other's findings** until verification. Sharing findings first collapses N reviewers into one.
3. **The verifier of a finding is never the lens that raised it**, and never the corpus author.
4. **Record who ran what.** Every lens gets a row in `## Lens Roster` with its `Reviewer` and an honest `Authored any corpus artifact?` answer. `true` there is not a failure — it is a disclosure, and it is what lets a reader discount the finding set correctly.

If you are a single agent with no dispatch available, you may still run the lenses sequentially in separate passes — but say so in the Reviewer column, and read "The honest limit" at the bottom of this file before you write `CLEAN`.

---

## The lens roster (tiered)

### Scope: when the gate applies

| Play level | Epics in project | `/epic-analyze` |
|-----------|------------------|-----------------|
| Sprint | any | optional |
| Build | 1–3 | recommended, not gated |
| **Build** | **4+** | **REQUIRED per epic — 3 mandatory lenses** |
| **Platform** | any | **REQUIRED per epic — all 7 lenses** |

Read `.speck/project.json` → `play_level` (no file, or no field, means **Platform** — Speck's documented back-compat rule, so an unconfigured project is gated, never silently exempt); count the epics via `### E###` headings in `epics.md` and the `epics/` subdirectories, whichever is higher. Same trigger as `/project-analyze`, same reason: at 4+ epics the corpus is genuinely multi-artifact and the seams between epics start carrying weight.

### Why three at Build and not seven — the anti-bloat trade

AGENTS.md:37 is explicit: *"When a gap appears, install it as a principle — do not grow the checklist (that is how green becomes theater and context rots)."* A seven-lens mandate on every epic of every 4-epic Build would be exactly the checklist growth that rule forbids — and it would be paid per epic, so the cost compounds where the project-level cost is paid once. So the mandate is sized by a test, not by appetite:

> **Mandate a lens only where the defect class it catches is structurally invisible to the author. Leave the rest to the tier where governance depth already justifies them.**

Three lenses pass that test:

- **promise-coverage (L3)** — the defect is an *absence*. An author reading any single artifact cannot see what is missing from the set; absence has no anchor to notice. At epic altitude this is also the promise-evaporation check that `traceability-matrix.md` exists to make walkable.
- **cross-artifact drift (L6)** — the defect exists only in the *relationship* between two artifacts. Structurally unreachable from inside either one. This is #106's motivating defect class, and the epic corpus has more artifact pairs than the project corpus: `epic.md` ↔ tech spec ↔ breakdown ↔ experience chain ↔ wireframes ↔ matrix.
- **completeness critic (L7)** — the author's blind spot is definitionally what they did not write. Asking the author what they forgot is asking the blind spot to describe itself. At this altitude what is forgotten becomes what a story author silently invents.

The other four — strategic alignment, story boundaries, scope feasibility, risk — read one artifact against a stated goal the author already holds. A well-run authoring pass genuinely can make those judgments about its own work; they are quality lenses, not blind-spot lenses. They are mandatory at Platform because Platform's corpus spans more artifacts and more owners, which is where "the author already holds the goal" stops being true.

That is the trade: **the mandate tracks structural invisibility, not thoroughness.** These four lenses were already in this skill as analysis aspects A–E and they were run every time — and the 001-odd corpus still shipped 14 defects. What was missing was not more of them; it was L6, L7, and a reviewer who had not written the corpus.

### The seven lenses

Same seven ids as `/project-analyze`, aimed one altitude down. Each question is phrased to **find what is wrong** (P1), never to confirm the plan.

| # | Lens | Hostile question | Reads | Uniquely catches | Tier |
|---|------|------------------|-------|------------------|------|
| L1 | `strategic-alignment` | "Which project promise does this epic claim to serve but nowhere implement? Which `epic.md` success criterion has no measurable form anywhere in the tech spec? Which constitution MUST rule does the architecture section quietly break?" | `epic.md`, `epic-tech-spec.md`, `PRD.md`, `product-contract.md`, `constitution.md` (epic + project) | Success criteria that survive as prose; **constitution violations** — flag with the exact principle and the offending section | Platform |
| L2 | `story-boundaries` | "Find two stories that both own the same acceptance criterion. Find an AC no story owns. Find a dependency cycle in the breakdown, or a story that cannot be validated on its own." | `epic-breakdown.md`, `epic-tech-spec.md`, `epic.md` | Overlap, gaps, cycles, stories that are bundles wearing one id — L2 one altitude down from epic boundaries | Platform |
| **L3** | **`promise-coverage`** | **"Which MM-N or JOB-N does the graph know about that this epic touches and no story covers? Which `PRM-NNN` row in the matrix has no discharging story, no descope DEC, and is not `pilot-gated`? Which wireframe screen and which experience-chain seam has no row at all?"** | `product-contract.md` §3/§3a/§5, `epic.md`, `epic-breakdown.md`, `traceability-matrix.md`, story specs, the witness graph | The unaddressed-promise gap and **promise evaporation** — including the un-enumerated promise, which the matrix validator cannot catch because there is no row to fail | **Build 4+ · Platform** |
| L4 | `scope-feasibility` | "Which story estimate is a placeholder someone typed? Which critical path is longer than the epic's declared shape admits? Which parallel opportunity is unsafe because the two stories touch the same file?" | `epic-breakdown.md`, `context.md`, `epic-tech-spec.md` | Effort fiction, critical-path bottlenecks, parallelism that will collide at merge | Platform |
| L5 | `risk` | "Which technical unknown is scheduled as if it were known? Which risk's mitigation is itself unbuilt work that appears in no story? Which external blocker has no fallback?" | `epic.md`, `epic-tech-spec.md`, `epic-codebase-scan*.md`, `context.md` | Mitigations that are aspirations; unowned unknowns; technical debt taken without a home | Platform |
| **L6** | **`cross-artifact-drift`** | **"Name two of `epic.md` / `epic-tech-spec.md` / `epic-breakdown.md` / `experience-chain.md` / `wireframes.md` / `user-journey.md` / `traceability-matrix.md` that cannot both be satisfied. Where does the tech spec design a seam the breakdown splits across two stories, or a journey stage that no story grouping reflects?"** | Every epic artifact, **read in pairs**, plus the project constraints they inherit | The contradiction that exists only BETWEEN artifacts — invisible to any file-local check, and the #106 motivating class. Also the "UX artifacts present but not incorporated in the tech spec" drift | **Build 4+ · Platform** |
| **L7** | **`completeness-critic`** | **"What is absent from this corpus entirely? What will a story author have to invent because nobody decided it? Which failure mode, empty state or permission boundary does no artifact mention?"** | The whole epic corpus, plus the template set that says what an epic corpus of this level should contain | Whole missing dimensions — the class no per-artifact validator can flag, because there is no artifact to flag | **Build 4+ · Platform** |

Lens ids are the shared vocabulary — write them into the report frontmatter as `id: L3`, `name: promise-coverage`.

---

## Execution

### 1. Establish scope and tier

- Read `.speck/project.json` → `play_level`. Count epics in `epics.md`.
- Load the epic corpus: `epic.md`, `epic-tech-spec.md`, `epic-breakdown.md`, `traceability-matrix.md`, `experience-chain.md`, `user-journey.md`, `wireframes.md`, `epic-codebase-scan*.md`, plus project-level `PRD.md`, `architecture.md`, `context.md`, `product-contract.md`.
- **Load the constitution chain if present**: `[EPIC_DIR]/constitution.md` and `specs/projects/[PROJECT_ID]/constitution.md`. The combined rule set is the authority for L1's compliance question.
- If `epic.md`, `epic-tech-spec.md` or `epic-breakdown.md` is missing: ERROR "Complete epic planning first."
- Research is embedded in `epic-tech-spec.md` — there is no separate `research.md` to validate.
- Record `git rev-parse HEAD` — the full 40-char SHA goes into the report's `analyzed_sha`.

### 2. Build the promise inventory from the graph — never a second parser

The coverage matrix must be complete against the same source the gate reads, or the matrix and the gate disagree about what a promise is. `speck_graph.py` already extracts `MM-N` and `JOB-N` from `product-contract.md`, and its design invariant forbids a parallel truth. So read it, do not re-grep:

```bash
python3 .speck/scripts/graph/speck_graph.py build specs/projects/[PROJECT_ID] --stdout \
  | python3 -c "import json,sys; [print(n['id'], n['kind'], n.get('title','')) for n in json.load(sys.stdin)['nodes'] if n['kind'] in ('magic-moment','job')]"
```

Every id this prints that falls inside this epic's scope needs a row in the coverage matrix. If `python3` is missing or the build fails, say so in the report — completeness was **not computed**. The gate emits `ANALYSIS_COVERAGE_UNCOMPUTED.P2` for exactly this state. An honest unknown, never a silent pass, and never a hand-rolled `grep '### MM-'` standing in for it.

If the epic is backend-only and a magic moment is UI-only, record it as a **deferral with the epic that will carry it named** — do not silently pass.

### 3. Walk the traceability matrix — the conservation law (keeps its own P1 BLOCK)

`/epic-analyze` runs AFTER `/epic-breakdown`, so every `PRM-NNN` row MUST now resolve to a story+AC, a DEC, or `pilot-gated`:

```bash
bash .speck/scripts/validation/validators/validate-traceability-matrix.sh [EPIC_DIR]
```

- Any open/unmapped row is a **P1 BLOCK** ("promise evaporation: PRM-NNN has no discharging story, no descope DEC, and is not pilot-gated"). The orchestrator already halts on P1.
- If the matrix was retrofitted, verify consolidated rows cite fine-grained backing references in the Backing column (no silent truncation) and that `pilot-gated` rows cite pilot references.
- Spot-check completeness: each wireframe screen/element and each experience-chain seam needs a row. **A promise that was never enumerated cannot be caught by the validator** — a missing row is itself a P1 ("un-enumerated promise"), and it is L3's job to find it.
- `traceability-matrix.md` absent entirely → **P1 BLOCK**: "no traceability matrix — re-run `/epic-plan` step 6b."

This P1 BLOCK is a pre-existing epic-level rule and it is **not** routed through the severity mapping in step 5 — it halts on its own terms. Record the finding in the Issues Found table as well, at the severity the mapping rule gives it: an undischarged `PRM-NNN` that carries an `MM-N` or `JOB-N` is CRITICAL by rule; otherwise it is author-judged.

### 4. Run the lenses — decorrelated, in parallel

Dispatch one reviewer per lens in the tier. Give each reviewer: its hostile question verbatim, the artifacts it reads, and nothing else — no other lens's findings, no author commentary defending the corpus.

Each lens returns findings only. It does not assign final severity (step 6 does) and it does not adjudicate its own findings (step 5 does).

Old aspects map straight onto the roster if you are reading a pre-v10.3 report: A Requirement Coverage → L3 + L7 · B Technical Coherence → L1 + L6 · C Task Completeness → L2 + L4 · D Risk → L5 · E Quality Coverage → L7 · F Constitution Compliance → L1 · G UX Artifact Integration → L6 · H Promise Coverage + Conservation → L3. The deep-dive checks still belong to their lens — the story traceability matrix (`User Story | Tech Spec Section | Task ID | Test Coverage`) to L3, dependency and critical-path analysis to L2 and L4, technical-debt assessment to L5.

### 5. Adversarial verification of every finding

Mirror `/audit` step 1b. `N` = the tier's lens count (3 at Build 4+, 7 at Platform).

- Each finding is handed to a **verifier that is not the lens that raised it** and not the corpus author.
- The verifier's job is to **refute** — P1 turned on the finding itself. It lands exactly one verdict: `confirmed` or `refuted`.
- **A refutation must quote the artifact text that makes the finding false.** "I don't think so" is not a refutation. An unrefuted finding stands as `confirmed`.
- Refuting a CRITICAL-by-rule finding (step 6) requires showing the *rule* does not apply — e.g. quoting both artifacts and demonstrating they CAN both be satisfied. A judgment call cannot refute a mapping rule.
- Disagreement on a non-CRITICAL finding → **majority-refute**: with N lenses, the finding stands if a majority of the lenses that examined it agree it is real.
- **A `refuted` finding stays in the table.** Deleting it destroys the evidence that the pass happened, and a report that shows only survivors is indistinguishable from one that never looked.

Write `Verifier` and `Verdict` into every Issues Found row.

### 6. Severity — assigned BY RULE

> Severity is assigned BY RULE, not at the author's discretion. These are CRITICAL by construction:
> - a cross-artifact `contradictory` verdict (two artifacts that cannot both be satisfied — this is the #106 motivating defect class);
> - an unaddressed magic moment (MM-N) or job (JOB-N) in the promise-coverage matrix;
> - a gate whose precondition contradicts the evidence contract.
>
> Everything else is author-judged HIGH/MEDIUM/LOW. Only CRITICAL with Status `open` blocks.

This paragraph is the load-bearing one. Without it, severity is whatever the analysing agent types into a free-text cell about its own corpus — and applied to #106's own field evidence, **13 of the 14 confirmed defects would have passed the gate.** The rule exists so that the three defect classes that motivated the gate cannot be graded down by the party the gate is aimed at.

Vocabularies are fixed: Severity `CRITICAL | HIGH | MEDIUM | LOW` · Verdict `confirmed | refuted` · Status `open | resolved | waived DEC-####`. A waiver is a real decision-log entry — run `/speck-decision-log`, do not type a DEC id that does not exist. (The `P1` / `P2` codes in step 3 are punch-list codes and stay as they are; they are a different vocabulary for a different mechanism.)

### 7. Compose the report

Write to `[EPIC_DIR]/epic-analysis-report.md`, following the template exactly.

**Frontmatter (v10.3+ vintage — this is what makes the report visible to the gate):**

```yaml
---
artifact_type: epic-analysis-report
speck_version: 10.3.0
analyzed_sha: <full 40-char SHA of HEAD when the analysis ran>
lenses:
  - id: L3
    name: promise-coverage
    reviewer: <agent type or session identifier>
    authored_corpus: false
---
```

`play_level` and `epic_count` are project-level fields — they do not belong in an epic report. A report with no `artifact_type: epic-analysis-report` is pre-v10.3 vintage and exempt from the structural checks; that exemption is what lets this change ship with no data migration. It is **not** a way to dodge the gate: a post-v10.3 epic with no recognisable report is `UNANALYZED_CORPUS.P1`, which is worse than a report with findings.

**Required structural elements** (columns resolved by header name, in any order):

- `## Lens Roster` — `Lens | Hostile question | Reviewer | Authored any corpus artifact? | Findings`
- `### ⚠️ Issues Found` — `ID | Category | Severity | Description | Recommendation | Verifier | Verdict | Status`
- `### Promise Coverage (Unaddressed-Promise Gap)` — `Promise dimension | Source | Epic / story coverage | Status`
- A `**Gate verdict**: BLOCKED | NEEDS_FIXES | CLEAN` line

Keep the report's other sections — coverage analysis, dependency analysis, technical validation, risk summary, quality gates, recommendations, readiness checklist. The lens work replaces the self-certified verdict, not the substance.

**Commit the report after the corpus it analyses.** Freshness is content-based: the gate compares the last commit touching the corpus against the last commit touching the report. Edit the tech spec or the breakdown afterwards and the report is `ANALYSIS_STALE.P1` — re-run this skill.

### 8. Declare the gate verdict

| Verdict | Condition | Consequence |
|---------|-----------|-------------|
| **BLOCKED** | ≥1 Issues Found row with Severity `CRITICAL` and Status `open` | Story work does not start on this epic. |
| **NEEDS_FIXES** | Open findings remain, none CRITICAL | Surfaced loudly; blocks nothing. The owner chooses. |
| **CLEAN** | Every row `resolved`, `waived DEC-####`, or `refuted` | Clear to proceed to `/story-specify`. |

The reader — anyone about to start story work, including a delegated subagent — checks with:

```bash
bash .speck/scripts/validation/check-epic-prereqs.sh specs/projects/[PROJECT_ID] --epic [EPIC_ID]
```

Exit 0 = clear · 1 = gate rejected · 2 = invocation error. Be precise about what that command proves: it gates the **project-level** analysis before an epic is specified, and `--epic [EPIC_ID]` names the epic being specified so the output says which one. It does not re-read this report.

**What enforces this report** is the structural validator, routed per-file and run by the pre-commit hook on every staged report:

```bash
bash .speck/scripts/validation/validate-template.sh --strict [EPIC_DIR]/epic-analysis-report.md
```

It rejects a v10.3-vintage report whose Lens Roster, Issues Found columns, Promise Coverage matrix or Gate verdict line is missing. The **verdict itself** — an open CRITICAL means story work does not start — is discipline the orchestrator enforces by halting on it, the same way it halts on the step 3 P1 BLOCK. Say the verdict out loud in your summary; a conductor reading the report is the mechanism.

### Gate P-codes

Minted by `validate-project-analysis.sh`. In `--gate <PROJECT_DIR>` mode (what `check-epic-prereqs.sh` escalates) it emits the blocking codes below; against this file it runs in structural mode, where the same vocabulary describes what a malformed report is missing.

| Code | Fires when |
|------|-----------|
| `UNANALYZED_CORPUS.P1` | The gate applies (Build 4+ / Platform) and no analysis report exists |
| `ANALYSIS_STALE.P1` | A corpus artifact has a commit AFTER the report's last commit |
| `ANALYSIS_CRITICAL_OPEN.P1` | A findings row with Severity CRITICAL and Status open |
| `PROMISE_UNCOVERED.P1` | An `MM-N` / `JOB-N` the graph knows about is absent from the coverage matrix, or present with an unresolved status |
| `ANALYSIS_DECORRELATION_UNVERIFIED.P2` | Fewer lenses than the tier requires, or a CRITICAL/HIGH row whose `Verifier` equals its Lens |
| `ANALYSIS_COVERAGE_UNCOMPUTED.P2` | The graph could not be read, so matrix completeness was not computed |
| `ANALYSIS_GRANDFATHERED.P2` | A pre-v10.3 project exempted by its marker |

**Grandfathering, stated plainly.** A project that already ran `/project-plan` before v10.3 is not blocked — it carries a per-project marker and gets `ANALYSIS_GRANDFATHERED.P2`: a loud, repeated notice on every gate run until it runs the analysis once. Projects planned after this release **do** block. The gate is real forward and advisory backward, and that asymmetry is disclosed here rather than hidden in the validator.

### 9. Output summary

```
✅ Epic Analysis Complete — [EPIC_ID]

Tier: [Build 4+ / Platform] — [3/7] lenses required, [N] run
Gate verdict: [BLOCKED / NEEDS_FIXES / CLEAN]

Findings: [X] raised · [Y] confirmed · [Z] refuted
  CRITICAL open: [N]   HIGH: [N]   MEDIUM: [N]   LOW: [N]

Promise coverage: [A]/[B] MM-N · [C]/[D] JOB-N   [computed from graph / NOT COMPUTED]
Traceability conservation: [clean / N unmapped PRM rows — P1 BLOCK]

Open CRITICALs:
1. [ID] — [one line]

Next:
[BLOCKED]      → fix / waive by DEC / refute the CRITICALs, re-run /epic-analyze
[NEEDS_FIXES]  → owner decides; story work may start
[CLEAN]        → /story-specify for the first story in Phase 1

Verify:  bash .speck/scripts/validation/check-epic-prereqs.sh specs/projects/[PROJECT_ID] --epic [EPIC_ID]
Report:  epic-analysis-report.md
```

---

## The honest limit — read this before writing CLEAN

**The decorrelation check is STRUCTURAL, not evidentiary.** A single agent can author a lens roster, fill in a Verifier column with names, and pass every check in this skill. Nothing in the gate observes that a second reviewer ever existed.

The gate's honest claim is exactly this, and no more:

> A roster was declared at the required width, and each CRITICAL/HIGH finding names a verifier distinct from its lens.

That is a real claim and it is worth having — it makes the absence of separation visible and it forces the roster to be written down. It is not a claim that the lenses were independent. Writing "decorrelated" on a pass that a single agent produced alone, without the Reviewer column saying so, is the label overclaiming its status — which is the exact failure mode #106 is about. Fill the `Authored any corpus artifact?` column honestly; a `true` there costs nothing and tells the reader what the pass is worth.

**The canon has one stronger mechanism, and a conductor should also run it when the stakes justify it.** The **Verify-Skills Gate** greps the sub-agent's transcript for real `"name":"Skill"` invocations before accepting a delegated result — it observes that the work happened rather than trusting the report of it, and `epic-analyze` is one of the two invocations it already requires of a delegated epic. See `.speck/patterns/learned/process/parallel-epic-execution.md` (Verify-Skills Gate) and AGENTS.md → *Delegated execution: verify skills ran before accepting results*. When an epic is about to fan out into parallel story work, dispatch the lenses as real subagents and verify their transcripts — that is what upgrades this gate from structural to evidentiary.

---

## Behavior Rules

- NEVER assign severity by judgment where the mapping rule assigns it by construction
- NEVER let the lens that raised a finding be its own verifier
- NEVER delete a `refuted` finding — the refutation is the evidence the pass happened
- NEVER hand-grep `### MM-N` in place of the graph reader — one source of truth, or the matrix and the gate disagree
- NEVER treat a missing `traceability-matrix.md` row as absence of a promise — an un-enumerated promise is a P1 of its own
- NEVER write `CLEAN` while an `MM-N` / `JOB-N` sits uncovered — that is CRITICAL by rule
- NEVER claim decorrelation the Reviewer column does not show
- ALWAYS write the v10.3 frontmatter, including the full 40-char `analyzed_sha`
- ALWAYS commit the report after the corpus it analyses
- ALWAYS re-run after editing the tech spec, the breakdown, or the matrix

## Integration Points

- Reads: `epic.md`, `epic-tech-spec.md`, `epic-breakdown.md`, `traceability-matrix.md`, `experience-chain.md`, `user-journey.md`, `wireframes.md`, `epic-codebase-scan*.md`, `constitution.md` (epic + project), `PRD.md`, `architecture.md`, `context.md`, `product-contract.md`, the witness graph
- Writes: `[EPIC_DIR]/epic-analysis-report.md`
- Invokes: `validate-traceability-matrix.sh`, `speck_graph.py build --stdout` (read-only), `/speck-decision-log` (on a waiver)
- Enforced by: `validate-template.sh --strict` on the report (routed to `validate-project-analysis.sh`, structural mode, run by pre-commit on staged files)
- Upstream gate: `check-epic-prereqs.sh specs/projects/[PROJECT_ID] --epic [EPIC_ID]` — the project-level analysis must be clear before this epic is specified
- Required before: `/story-specify` and all story work, at Build with 4+ epics and at Platform
- Sibling one altitude up: `/project-analyze` (same seven lens ids, same mapping rule, same limit)
