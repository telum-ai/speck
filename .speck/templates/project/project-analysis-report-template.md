---
speck_version: 10.3.0
template_version: "10.3.0"
artifact_type: project-analysis-report
analyzed_sha: [ANALYZED_SHA]
play_level: [PLAY_LEVEL]
epic_count: [EPIC_COUNT]
lenses: []
---

<!--
FRONTMATTER — keep these lines free of trailing `#` comments. validate-project-analysis.sh reads a
field as everything after the first colon (`fm_value`), so a trailing comment becomes part of the
value. VERIFIED live against the validator: a commented `analyzed_sha` is rejected as "neither a
full 40-character SHA nor the literal 'unknown'"; a commented `lenses: []` counts as ONE declared
lens; and a commented `play_level` matches neither `build` nor `platform` in `required_lens_count`,
which falls through to 0 required lenses — the mandate switched off by a comment nobody read.

  analyzed_sha  `git rev-parse HEAD` — the full 40-char SHA when the analysis ran, or the literal
                `unknown` outside a repository. This is PROVENANCE: what was read. Freshness is a
                different question, answered from git history (see "How this report is gated") and
                never from `analyzed_sha == HEAD` — a report can be stamped at HEAD and be stale
                the moment PRD.md is committed after it.
  play_level    `build` or `platform`. With epic_count it decides the lens tier.
  epic_count    integer.
  lenses        one entry per lens that ACTUALLY ran:

                  lenses:
                    - id: L3
                      name: promise-coverage
                      reviewer: <agent type or session identifier>
                      authored_corpus: false

                Shipped as `[]` on purpose, and the structural check fails on `[]`. Empty means
                "no lens ran", which is the only honest thing a template can say — the same
                discipline as story-template.md's `serves: []`. Mirror every row of the Lens Roster
                table here. `authored_corpus: true` is a disclosure, not a failure to hide: it is
                what makes ANALYSIS_DECORRELATION_UNVERIFIED.P2 mean anything.
-->

# Project Analysis Report: [Project Name]

**Project**: [PROJECT_ID]  
**Date**: [DATE]  
**Scale**: Level [0-4]  
**Gate verdict**: [GATE_VERDICT]

*One verdict, one place. `BLOCKED` when any Issues Found row is Severity `CRITICAL` with Status `open` — epic work does not start. `NEEDS_FIXES` when open findings remain and none is CRITICAL — surfaced loudly, blocks nothing. `CLEAN` when every row is `resolved`, `waived DEC-####`, or `refuted`. The Readiness Assessment at the foot of this report feeds this line — it does not restate it, because two status fields drift and only one of them can be right.*

---

## 📊 Information Sources

- `project.md` → Vision, goals, success metrics
- `PRD.md` → Requirements and scope boundaries
- `epics.md` → Epic breakdown and ordering
- `product-contract.md` → Differentiator pillars, JOB-N, MM-N — the promise side of the coverage matrix
- `project-roadmap.md` (if exists) → Timeline and execution strategy
- `architecture.md` → Architecture decisions and constraints (research embedded)
- `context.md` → Constraints and standards
- `evidence-contract.md` → What counts as proof; read in pairs by L6, because a gate whose precondition contradicts it is CRITICAL by rule
- `project-landscape-overview.md` (if brownfield) → Existing system inventory
- The witness graph → `python3 .speck/scripts/graph/speck_graph.py build <PROJECT_DIR> --stdout` is the ONE reader for MM-N / JOB-N completeness; this report never re-parses `product-contract.md` for them

---

## Lens Roster

*Who looked, with what hostile question, and whether they were reading their own homework.*

**Why the roster exists.** A planning corpus produced through the full canonical Build flow — every skill entered, five skeptical-review primitives, premise-challenge, strict validators green — still carried 1 CRITICAL and 13 HIGH defects (project `001-odd`). Every gate it passed was run by the party that had authored the corpus. That is the failure this section is against: AGENTS.md P4 says the adversary is *structural*, and a lens is evidence only when the reviewer did not write what they are reviewing.

**Tier mandate** — deliberately tiered, because AGENTS.md:37's anti-bloat rule forbids charging a three-epic Build the Platform price:

- **Sprint**, any size — optional.
- **Build, 1–3 epics** — recommended, not gated.
- **Build, 4+ epics** — REQUIRED, three mandatory lenses: **L3** `promise-coverage`, **L6** `cross-artifact-drift`, **L7** `completeness-critic`. Those three and no others, because each catches a defect class that is *structurally invisible to the author* — an absence, a relationship between two files, and the blind spot itself.
- **Platform**, any size — REQUIRED, all seven.

**Lens ids** — the shared vocabulary, the same seven one altitude down in `/analyze --level epic`:

- **L1** `strategic-alignment` · **L2** `epic-boundaries` · **L4** `scope-feasibility` · **L5** `risk` — Platform tier.
- **L3** `promise-coverage` · **L6** `cross-artifact-drift` · **L7** `completeness-critic` — mandatory from Build 4+.

Each lens's **hostile question is copied VERBATIM** from the selected `/analyze --level project` lens node (`references/lenses/project/L#.md`) into the row below. It is not restated in this template: a question stated in two places is a question that drifts, and the roster is a record of what was actually asked.

Every row here also becomes an entry in the `lenses:` frontmatter list — the shape is in the comment at the top of this file, and the two must agree.

| Lens | Hostile question | Reviewer | Authored any corpus artifact? | Findings |
|------|------------------|----------|-------------------------------|----------|
| [e.g., L3 promise-coverage] | [e.g., Which MM-N does no epic carry?] | [e.g., an agent type or session id that did NOT author this corpus] | [e.g., no] | [e.g., 2] |

---

## Executive Summary

[High-level findings and recommendations. Lead with the gate verdict in one plain sentence, then what drove it.]

---

## Analysis Results

### ✅ Strengths
- [What’s well-designed]
- [What’s clear and actionable]
- [What reduces risk]

### ⚠️ Issues Found

**Severity is assigned BY RULE, not at the author's discretion.** Three classes are CRITICAL by construction. An author who grades one of them HIGH has mis-graded it, not exercised judgement:

1. A cross-artifact `contradictory` verdict — two artifacts that cannot both be satisfied.
2. An unaddressed magic moment (MM-N) or job (JOB-N) in the Promise Coverage matrix below.
3. A gate whose precondition contradicts `evidence-contract.md`.

Everything else is author-judged `HIGH` / `MEDIUM` / `LOW`. **Only `CRITICAL` with Status `open` blocks.** The rule is the load-bearing part: of the 14 defects that motivated this section, 13 were graded below CRITICAL by their own author and would have walked straight through a discretion-graded gate.

**Vocabularies** — Severity: `CRITICAL | HIGH | MEDIUM | LOW` · Verdict: `confirmed | refuted` · Status: `open | resolved | waived DEC-####`.

**ID and Verifier carry the decorrelation.** The ID is `<lens id>-<n>`, so the raising lens is readable off the row (`L3-1` was raised by L3), and `Category` names that lens too. **Verifier** is whoever CONFIRMED the finding, and on any `CRITICAL` or `HIGH` row it must be a *different* lens than the one that raised it — a finding checked only by the party that found it is not decorrelated (`ANALYSIS_DECORRELATION_UNVERIFIED.P2`). `refuted` is a real outcome and belongs in the table: a raised-then-refuted finding is evidence the adversary ran.

| ID | Category | Severity | Description | Recommendation | Verifier | Verdict | Status |
|----|----------|----------|-------------|----------------|----------|---------|--------|
| [e.g., L6-1] | [e.g., cross-artifact-drift] | CRITICAL | [Issue] | [Recommendation] | [e.g., L7] | [e.g., confirmed] | [e.g., open] |
| [e.g., L7-1] | [e.g., completeness-critic] | HIGH | [Issue] | [Recommendation] | [e.g., L3] | [e.g., confirmed] | [e.g., resolved] |

---

## 📊 Metrics

### Requirement Coverage
- Total requirements: [X]
- Mapped to epics: [Y] ([Z]%)
- Orphaned: [List]

### Epic Analysis
- Total epics: [X]
- Dependencies: [Y] identified
- Parallel opportunities: [Z]
- Critical path length: [N] epics

### Scope Validation
- Estimated total stories: [X]
- Expected for Level [N]: [Y–Z]
- Assessment: [On track/Over/Under]

### Risk Summary
- High risks: [X]
- Medium risks: [Y]
- Unmitigated: [Z]

### Promise Coverage (Unaddressed-Promise Gap)

*Completeness is computed against the witness graph, not against this file. `python3 .speck/scripts/graph/speck_graph.py build <PROJECT_DIR> --stdout` emits every `magic-moment`, `job` and `differentiator` node; the gate compares that set to the rows below. An MM-N, JOB-N or DIF-N the graph knows about and this matrix does not is `PROMISE_UNCOVERED.P1`. If the graph cannot be read, completeness was **not computed** (`ANALYSIS_COVERAGE_UNCOMPUTED.P2`) — an honest unknown, never a pass.*

- Differentiator pillars (DIF-N) mapped: [e.g., 3] of [e.g., 4] — **only pillars the contract declares as `### DIF-N`**. A §3 written as free prose declares none, and the gate says so rather than guessing (#108).
- Magic moments (MM-N) mapped: [e.g., 5] of [e.g., 6]
- Jobs (JOB-N) mapped: [e.g., 4] of [e.g., 4]

**Status** uses the same vocabulary as the Issues table: `resolved` when at least one epic or story carries the dimension · `open` when nothing does · `waived DEC-####` when a logged decision defers it. An MM-N, JOB-N or DIF-N row left `open` is `CRITICAL` **by rule** and blocks — it does not get to be a HIGH.

| Promise dimension | Source | Epic / story coverage | Status |
|-------------------|--------|----------------------|--------|
| [e.g., MM-2 <magic moment name>] | product-contract §5 | [e.g., E003 / S011] | [e.g., resolved] |
| [e.g., JOB-1 <job name>] | product-contract §4 | [e.g., E001 / S002] | [e.g., resolved] |
| [e.g., DIF-1 <pillar name>] | product-contract §3 | [e.g., E002 / S007] | [e.g., resolved] |

*§3a anti-differentiators are deliberately absent from this matrix. An anti-differentiator is a **constraint**, not a promise — nothing delivers it, so nothing can cover it, and a row demanding coverage could only be closed by deleting the claim.*

---

## Detailed Findings

### Epic Boundary Issues
[Overlap/gaps, boundary problems, coupling risks]

### Requirement Issues
[Unmapped requirements, unclear priorities, untestable items]

### Dependency Concerns
[Critical path bottlenecks, circular deps, sequencing issues]

### Resource Gaps
[Missing skills/resources or unrealistic assumptions]

---

## Recommendations

### Immediate Actions
1. [Most critical fix]
2. [Second priority]

### Before Epic Planning
1. [What must be resolved]
2. [What should be clarified]

### Process Improvements
1. [For this project]
2. [For future projects]

---

## How this report is gated

`bash .speck/scripts/validation/validators/validate-project-analysis.sh --gate <PROJECT_DIR>` exits non-zero on any P1 by default — no `--strict` needed, because a gate that only fires when asked politely is not a gate.

- `UNANALYZED_CORPUS.P1` — the gate applies and no analysis report exists.
- `ANALYSIS_STALE.P1` — `PRD.md`, `epics.md` or `product-contract.md` has a commit **after** this report's last commit. Content freshness, read from git history; with no history available the answer is `unknown`, never `fresh`.
- `ANALYSIS_CRITICAL_OPEN.P1` — a findings row is `CRITICAL` with Status `open`.
- `PROMISE_UNCOVERED.P1` — an MM-N or JOB-N the graph knows about is missing from the coverage matrix, or sits there unresolved.
- `ANALYSIS_DECORRELATION_UNVERIFIED.P2` — fewer lenses than the tier requires, or a CRITICAL/HIGH row whose Verifier is its own lens.
- `ANALYSIS_COVERAGE_UNCOMPUTED.P2` — the graph could not be read, so matrix completeness was not computed.
- `ANALYSIS_GRANDFATHERED.P2` — a pre-v10.3 project running on its exemption marker. Loud and repeated, never a block, until `/analyze --level project` runs once.

---

## Readiness Assessment

- [ ] Strategic alignment confirmed
- [ ] Epic boundaries clean
- [ ] Dependencies manageable
- [ ] Scope appropriate for scale
- [ ] Risks identified and mitigated
- [ ] Resources available
- [ ] Success metrics defined
- [ ] Every mandatory lens for this tier ran, with a reviewer that did not author the corpus

*This checklist feeds the **Gate verdict** at the top of the report. It deliberately does not restate it: a second status field is a second source of truth, and the two drift.*

---
*Generated by /analyze --level project command*
*Template Version: 10.3.0*
