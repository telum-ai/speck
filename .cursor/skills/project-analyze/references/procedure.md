The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## Step 0: Read Template First

**Before any other action** — read this template now using the Read tool:
```
.speck/templates/project/project-analysis-report-template.md
```
The template defines the required frontmatter, sections and column headers for `project-analysis-report.md`. Reading it first ensures your findings land in a structured report. Note: `/project-analyze` is a planning-phase design check. It is NOT `/project-validate`, which is the final post-implementation release gate.

**Checkpoint**: After reading, note the top-level sections from the template. Then continue to "Why this is no longer optional".

---

## Why this is no longer optional (#106)

Until v10.3 this skill was opt-in at exactly the altitude where the author self-certifies. Field evidence says that does not hold.

Project `001-odd` produced its planning corpus through the **full canonical Build flow** — every skill entered, five `/speck-skeptical-review` primitives run at the locks, `/speck-premise-challenge` run on the surfaces, every strict validator green. The corpus still carried **1 CRITICAL and 13 HIGH defects**. None of them were found by any inline gate. All of them were found by one adversarial 7-lens pass run by reviewers who had not written the corpus.

Read why each inline primitive *could not* have caught them — this is mechanical, not a discipline failure:

| Primitive | What its aperture is | Why the defects were outside it |
|-----------|----------------------|----------------------------------|
| `/speck-skeptical-review` | ONE decision, at the moment it locks: N≥3 alternatives + tradeoffs | Enumerating alternatives for lock X says nothing about whether X contradicts lock Y, made in a different session against a different artifact. The primitive's object is a decision, never a *pair* of decisions. |
| `/speck-premise-challenge` | ONE surface, judged by a hostile user: onboarding, empty state, paywall, error, celebration | A contradiction between a gate's precondition and the evidence contract has no surface and produces no felt-bad. Nothing in a taste instrument's aperture points at it. |
| Strict validators | ONE artifact, structurally: sections present, references resolve, shapes conform | Two artifacts that are each individually well-formed, and that cannot both be satisfied, pass every file-local check. Both files are green; the *pair* is the defect, and no validator reads the pair. |

The common cause, and the reason this skill exists in its current form: **all three run BY the author, IN the authoring context, against artifacts the author just wrote.** Same author, same context, shared blind spots by construction. A promise-level contradiction between two artifacts survived all of them because no single-artifact review can see a contradiction that only exists BETWEEN artifacts — and no self-review is incentivised to find the one finding that would force it to redo the work.

This is **P4** at planning altitude: the adversary is structural, not a checklist. `/audit` already applies it after implementation (`speck-audit` step 1b, and its "independent auditor, never the implementer" rule). This skill is the same idiom one altitude up.

---

## Role separation — who may run a lens

Mirror `/audit`, do not invent a second scheme.

1. **A lens is run by a reviewer that did not author the corpus.** Concretely: a separate subagent (`@speck-auditor` or a general-purpose agent with the Skill tool), a separate session, or a different model. The conductor dispatches; the planner does not grade its own plan.
2. **Lenses run against the same corpus but do not see each other's findings** until verification. Sharing findings first collapses N reviewers into one.
3. **The verifier of a finding is never the lens that raised it**, and never the corpus author.
4. **Record who ran what.** Every lens gets a row in `## Lens Roster` with its `Reviewer` and an honest `Authored any corpus artifact?` answer. `true` in that column is not a failure — it is a disclosure, and it is what lets a reader discount the finding set correctly.

If you are a single agent with no dispatch available, you may still run the lenses sequentially in separate passes — but say so in the Reviewer column, and read "The honest limit" at the bottom of this file before you write `CLEAN`.

---

## The lens roster (tiered)

### Scope: when the gate applies

| Play level | Epics | `/project-analyze` |
|-----------|-------|--------------------|
| Sprint | any | optional |
| Build | 1–3 | recommended, not gated |
| **Build** | **4+** | **REQUIRED — 3 mandatory lenses** |
| **Platform** | any | **REQUIRED — all 7 lenses** |

Read `.speck/project.json` → `play_level` (no file, or no field, means **Platform** — Speck's documented back-compat rule, so an unconfigured project is gated, never silently exempt); count the epics via `### E###` headings in `epics.md` and the `epics/` subdirectories, whichever is higher. The 4+ trigger is the same one `/project-plan`'s Build Complexity Gate already uses — at 4+ epics a Build is a full product and its corpus is genuinely multi-artifact.

### Why three at Build and not seven — the anti-bloat trade

AGENTS.md:37 is explicit: *"When a gap appears, install it as a principle — do not grow the checklist (that is how green becomes theater and context rots)."* A seven-lens mandate on every 4-epic Build would be exactly the checklist growth that rule forbids. So the mandate is sized by a test, not by appetite:

> **Mandate a lens only where the defect class it catches is structurally invisible to the author. Leave the rest to the tier where governance depth already justifies them.**

Three lenses pass that test:

- **promise-coverage (L3)** — the defect is an *absence*. An author reading any single artifact cannot see what is missing from the set; absence has no anchor to notice.
- **cross-artifact drift (L6)** — the defect exists only in the *relationship* between two artifacts. Structurally unreachable from inside either one. This is #106's motivating defect class.
- **completeness critic (L7)** — the author's blind spot is definitionally what they did not write. Asking the author what they forgot is asking the blind spot to describe itself.

The other four — strategic alignment, epic boundaries, scope feasibility, risk — read one artifact against a stated goal the author already holds. A well-run authoring pass genuinely can make those judgments about its own work; they are quality lenses, not blind-spot lenses. They are mandatory at Platform because Platform's corpus spans more artifacts and more owners, which is where "the author already holds the goal" stops being true.

That is the trade: **the mandate tracks structural invisibility, not thoroughness.** These four lenses were already in this skill as analysis dimensions A–E and they were run every time — and the 001-odd corpus still shipped 14 defects. What was missing was not more of them; it was L6, L7, and a reviewer who had not written the corpus.

### The seven lenses

Each lens's question is phrased to **find what is wrong** (P1), never to confirm the plan.

| # | Lens | Hostile question | Reads | Uniquely catches | Tier |
|---|------|------------------|-------|------------------|------|
| L1 | `strategic-alignment` | "Name a PRD goal whose success metric cannot distinguish being met from being missed. Which vision commitment in `project.md` does the epic set silently drop?" | `project.md`, `PRD.md`, `product-contract.md`, `context.md` | Goals that survive as prose but have no measurable form; research findings quoted but never acted on | Platform |
| L2 | `epic-boundaries` | "Find two epics that both own the same requirement. Find one requirement no epic owns. Find a dependency cycle, or an epic that cannot deliver standalone value." | `epics.md`, `PRD.md`, `project-roadmap.md` | Overlap, gaps, cycles, coupling that makes the declared wave structure unsafe | Platform |
| **L3** | **`promise-coverage`** | **"Which MM-N or JOB-N does the graph know about that appears in no epic and no story? Which differentiator pillar in `product-contract.md` §3 is named nowhere in `epics.md`?"** | `product-contract.md` §3/§3a/§5, `epics.md`, every `epic-breakdown.md`, the witness graph | The unaddressed-promise gap — a paid promise with zero project-level coverage | **Build 4+ · Platform** |
| L4 | `scope-feasibility` | "Which epic's story estimate is a placeholder someone typed? What in this plan cannot be built at the declared scale, with the declared constraints?" | `epics.md`, `context.md`, `architecture.md`, `.speck/project.json` | Scale mismatch against the level's story band; constraints in `context.md` the plan quietly violates | Platform |
| L5 | `risk` | "Which risk's mitigation is itself unbuilt work that appears in no epic? Which single dependency, if it fails, strands more than one epic?" | `PRD.md`, `architecture.md`, `epics.md`, `context.md` | Mitigations that are aspirations; unowned technical unknowns; fallback plans with no home | Platform |
| **L6** | **`cross-artifact-drift`** | **"Name two artifacts in this corpus that cannot both be satisfied. Where does `PRD.md` promise what `product-contract.md` bans, `epics.md` schedule what `context.md` forbids, or `evidence-contract.md` demand proof from a surface no epic builds?"** | Every project artifact, **read in pairs** | The contradiction that exists only BETWEEN artifacts — invisible to any file-local check, and the #106 motivating class | **Build 4+ · Platform** |
| **L7** | **`completeness-critic`** | **"What is absent from this corpus entirely? What question will a reader ask on day one that no artifact answers? What must an epic author invent because nobody decided it?"** | The whole corpus, plus the template set that says what a corpus of this level should contain | Whole missing dimensions — the class no per-artifact validator can flag, because there is no artifact to flag | **Build 4+ · Platform** |

Lens ids are the shared vocabulary — write them into the report frontmatter as `id: L3`, `name: promise-coverage`. `/epic-analyze` uses the same seven ids one altitude down.

---

## Execution

### 1. Establish scope and tier

- Read `.speck/project.json` → `play_level`. Count epics in `epics.md`.
- Load the corpus: `project.md`, `PRD.md`, `epics.md`, `product-contract.md`, `context.md`, `architecture.md`, `evidence-contract.md`, `project-roadmap.md`, `project-landscape-overview.md`, `project-decisions-log.md` — whichever exist.
- If `project.md`, `PRD.md` or `epics.md` is missing: ERROR "Required files not found. Run `/project-plan` first."
- Record `git rev-parse HEAD` — the full 40-char SHA goes into the report's `analyzed_sha`.

### 2. Build the promise inventory from the graph — never a second parser

The coverage matrix must be complete against the same source the gate reads, or the matrix and the gate disagree about what a promise is. `speck_graph.py` already extracts `MM-N` and `JOB-N` from `product-contract.md`, and its design invariant forbids a parallel truth. So read it, do not re-grep:

```bash
python3 .speck/scripts/graph/speck_graph.py build specs/projects/[PROJECT_ID] --stdout \
  | python3 -c "import json,sys; [print(n['id'], n['kind'], n.get('title','')) for n in json.load(sys.stdin)['nodes'] if n['kind'] in ('magic-moment','job')]"
```

Every id this prints needs a row in the coverage matrix. If `python3` is missing or the build fails, say so in the report — completeness was **not computed**. The gate emits `ANALYSIS_COVERAGE_UNCOMPUTED.P2` for exactly this state. An honest unknown, never a silent pass, and never a hand-rolled `grep '### MM-'` standing in for it.

### 3. Run the lenses — decorrelated, in parallel

Dispatch one reviewer per lens in the tier. Give each reviewer: its hostile question verbatim, the artifacts it reads, and nothing else — no other lens's findings, no author commentary defending the corpus.

Each lens returns findings only. It does not assign final severity (step 5 does) and it does not adjudicate its own findings (step 4 does).

Old dimensions map straight onto the roster if you are reading a pre-v10.3 report: A Strategic Alignment → L1 · B Epic Coherence → L2 · C Scope Feasibility → L4 · D Requirement Coverage → L3 + L7 · E Risk Assessment → L5. The deep-dive checks still belong to their lens — epic-pair overlap/gap/cycle analysis to L2, PRD requirement traceability to L3, the level story-band check (L1: 1–10 · L2: 5–15 · L3: 12–40 · L4: 40+) to L4.

### 4. Adversarial verification of every finding

Mirror `/audit` step 1b. `N` = the tier's lens count (3 at Build 4+, 7 at Platform).

- Each finding is handed to a **verifier that is not the lens that raised it** and not the corpus author.
- The verifier's job is to **refute** — P1 turned on the finding itself. It lands exactly one verdict: `confirmed` or `refuted`.
- **A refutation must quote the artifact text that makes the finding false.** "I don't think so" is not a refutation. An unrefuted finding stands as `confirmed`.
- Refuting a CRITICAL-by-rule finding (step 5) requires showing the *rule* does not apply — e.g. quoting both artifacts and demonstrating they CAN both be satisfied. A judgment call cannot refute a mapping rule.
- Disagreement on a non-CRITICAL finding → **majority-refute**: with N lenses, the finding stands if a majority of the lenses that examined it agree it is real.
- **A `refuted` finding stays in the table.** Deleting it destroys the evidence that the pass happened, and a report that shows only survivors is indistinguishable from one that never looked.

Write `Verifier` and `Verdict` into every Issues Found row.

### 5. Severity — assigned BY RULE

> Severity is assigned BY RULE, not at the author's discretion. These are CRITICAL by construction:
> - a cross-artifact `contradictory` verdict (two artifacts that cannot both be satisfied — this is the #106 motivating defect class);
> - an unaddressed magic moment (MM-N) or job (JOB-N) in the promise-coverage matrix;
> - a gate whose precondition contradicts the evidence contract.
>
> Everything else is author-judged HIGH/MEDIUM/LOW. Only CRITICAL with Status `open` blocks.

This paragraph is the load-bearing one. Without it, severity is whatever the analysing agent types into a free-text cell about its own corpus — and applied to #106's own field evidence, **13 of the 14 confirmed defects would have passed the gate.** The rule exists so that the three defect classes that motivated the gate cannot be graded down by the party the gate is aimed at.

Vocabularies are fixed: Severity `CRITICAL | HIGH | MEDIUM | LOW` · Verdict `confirmed | refuted` · Status `open | resolved | waived DEC-####`. A waiver is a real decision-log entry — run `/speck-decision-log`, do not type a DEC id that does not exist.

### 6. Compose the report

Write to `[PROJECT_DIR]/project-analysis-report.md`, following the template exactly.

**Frontmatter (v10.3+ vintage — this is what makes the report visible to the gate):**

```yaml
---
artifact_type: project-analysis-report
speck_version: 10.3.0
analyzed_sha: <full 40-char SHA of HEAD when the analysis ran>
play_level: build                            # build | platform
epic_count: 6
lenses:
  - id: L3
    name: promise-coverage
    reviewer: <agent type or session identifier>
    authored_corpus: false
---
```

A report with no `artifact_type: project-analysis-report` is pre-v10.3 vintage and exempt from the structural checks — that exemption is what lets this change ship with no data migration. It is **not** a way to dodge the gate: a post-v10.3 project with no recognisable report is `UNANALYZED_CORPUS.P1`, which is worse than a report with findings.

**Required structural elements** (columns resolved by header name, in any order):

- `## Lens Roster` — `Lens | Hostile question | Reviewer | Authored any corpus artifact? | Findings`
- `### ⚠️ Issues Found` — `ID | Category | Severity | Description | Recommendation | Verifier | Verdict | Status`
- `### Promise Coverage (Unaddressed-Promise Gap)` — `Promise dimension | Source | Epic / story coverage | Status`
- A `**Gate verdict**: BLOCKED | NEEDS_FIXES | CLEAN` line

Keep the report's other sections — strengths, metrics, detailed findings, recommendations, readiness assessment. The lens work replaces the self-certified verdict, not the substance.

**Commit the report after the corpus it analyses.** Freshness is content-based: the gate compares the last commit touching `PRD.md` / `epics.md` / `product-contract.md` against the last commit touching the report. Edit any of the three afterwards and the report is `ANALYSIS_STALE.P1` — re-run this skill.

### 7. Declare the gate verdict

| Verdict | Condition | Consequence |
|---------|-----------|-------------|
| **BLOCKED** | ≥1 Issues Found row with Severity `CRITICAL` and Status `open` | Epic work does not start. `/epic-specify` and every downstream epic skill are gated behind this. |
| **NEEDS_FIXES** | Open findings remain, none CRITICAL | Surfaced loudly; blocks nothing. The owner chooses. |
| **CLEAN** | Every row `resolved`, `waived DEC-####`, or `refuted` | Clear to proceed to epic work. |

The reader — anyone about to start epic work, including a delegated subagent — checks with:

```bash
bash .speck/scripts/validation/check-epic-prereqs.sh specs/projects/[PROJECT_ID]
```

Exit 0 = clear · 1 = gate rejected · 2 = invocation error. The gate itself is:

```bash
bash .speck/scripts/validation/validators/validate-project-analysis.sh --gate specs/projects/[PROJECT_ID]
```

It exits 1 on any P1 by default — no `--strict` needed, which is what makes it a gate rather than a report. `--strict` additionally escalates P2 to exit 1.

### Gate P-codes

| Code | Fires when |
|------|-----------|
| `UNANALYZED_CORPUS.P1` | The gate applies (Build 4+ / Platform) and no analysis report exists |
| `ANALYSIS_STALE.P1` | `PRD.md` / `epics.md` / `product-contract.md` has a commit AFTER the report's last commit |
| `ANALYSIS_CRITICAL_OPEN.P1` | A findings row with Severity CRITICAL and Status open |
| `PROMISE_UNCOVERED.P1` | An `MM-N` / `JOB-N` the graph knows about is absent from the coverage matrix, or present with an unresolved status |
| `ANALYSIS_DECORRELATION_UNVERIFIED.P2` | Fewer lenses than the tier requires, or a CRITICAL/HIGH row whose `Verifier` equals its Lens |
| `ANALYSIS_COVERAGE_UNCOMPUTED.P2` | The graph could not be read, so matrix completeness was not computed |
| `ANALYSIS_GRANDFATHERED.P2` | A pre-v10.3 project exempted by its marker |

**Grandfathering, stated plainly.** A project that already ran `/project-plan` before v10.3 is not blocked — it carries a per-project marker and gets `ANALYSIS_GRANDFATHERED.P2`: a loud, repeated notice on every gate run until it runs `/project-analyze` once. Projects planned after this release **do** block. The gate is real forward and advisory backward, and that asymmetry is disclosed here rather than hidden in the validator.

### 8. Output summary

```
✅ Project Analysis Complete

Tier: [Build 4+ / Platform] — [3/7] lenses required, [N] run
Gate verdict: [BLOCKED / NEEDS_FIXES / CLEAN]

Findings: [X] raised · [Y] confirmed · [Z] refuted
  CRITICAL open: [N]   HIGH: [N]   MEDIUM: [N]   LOW: [N]

Promise coverage: [A]/[B] MM-N · [C]/[D] JOB-N   [computed from graph / NOT COMPUTED]

Open CRITICALs:
1. [ID] — [one line]

Next:
[BLOCKED]      → fix / waive by DEC / refute the CRITICALs, re-run /project-analyze
[NEEDS_FIXES]  → owner decides; epic work may start
[CLEAN]        → /epic-specify "E001: [Name]"

Verify:  bash .speck/scripts/validation/check-epic-prereqs.sh specs/projects/[PROJECT_ID]
Report:  project-analysis-report.md
```

---

## The honest limit — read this before writing CLEAN

**The decorrelation check is STRUCTURAL, not evidentiary.** A single agent can author a lens roster, fill in a Verifier column with names, and pass every check in this skill. Nothing in the gate observes that a second reviewer ever existed.

The gate's honest claim is exactly this, and no more:

> A roster was declared at the required width, and each CRITICAL/HIGH finding names a verifier distinct from its lens.

That is a real claim and it is worth having — it makes the absence of separation visible and it forces the roster to be written down. It is not a claim that the lenses were independent. Writing "decorrelated" on a pass that a single agent produced alone, without the Reviewer column saying so, is the label overclaiming its status — which is the exact failure mode #106 is about. Fill the `Authored any corpus artifact?` column honestly; a `true` there costs nothing and tells the reader what the pass is worth.

**The canon has one stronger mechanism, and a conductor should also run it when the stakes justify it.** The **Verify-Skills Gate** greps the sub-agent's transcript for real `"name":"Skill"` invocations before accepting a delegated result — it observes that the work happened rather than trusting the report of it. See `.speck/patterns/learned/process/parallel-epic-execution.md` (Verify-Skills Gate) and AGENTS.md → *Delegated execution: verify skills ran before accepting results*. When a project's planning corpus is about to fan out into parallel epic waves, dispatch the lenses as real subagents and verify their transcripts — that is what upgrades this gate from structural to evidentiary.

---

## Behavior Rules

- NEVER assign severity by judgment where the mapping rule assigns it by construction
- NEVER let the lens that raised a finding be its own verifier
- NEVER delete a `refuted` finding — the refutation is the evidence the pass happened
- NEVER hand-grep `### MM-N` in place of the graph reader — one source of truth, or the matrix and the gate disagree
- NEVER write `CLEAN` while an `MM-N` / `JOB-N` sits uncovered — that is CRITICAL by rule
- NEVER claim decorrelation the Reviewer column does not show
- ALWAYS write the v10.3 frontmatter, including the full 40-char `analyzed_sha`
- ALWAYS commit the report after the corpus it analyses
- ALWAYS re-run after editing `PRD.md`, `epics.md` or `product-contract.md`

## Integration Points

- Reads: `project.md`, `PRD.md`, `epics.md`, `product-contract.md`, `context.md`, `architecture.md`, `evidence-contract.md`, `project-roadmap.md`, `project-decisions-log.md`, the witness graph
- Writes: `[PROJECT_DIR]/project-analysis-report.md`
- Invokes: `speck_graph.py build --stdout` (read-only), `/speck-decision-log` (on a waiver)
- Enforced by: `validate-project-analysis.sh --gate` (blocking), surfaced through `check-epic-prereqs.sh` at `/epic-specify`; the report's structure by `validate-template.sh --strict` on the staged file
- Required before: `/epic-specify` and all epic work, at Build with 4+ epics and at Platform
- Sibling one altitude down: `/epic-analyze` (same seven lens ids, same mapping rule, same limit)
