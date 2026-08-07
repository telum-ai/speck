---
speck_version: 10.3.0
template_version: "10.3.0"
artifact_type: epic-analysis-report
analyzed_sha: [ANALYZED_SHA]
lenses: []
---

<!--
FRONTMATTER — keep these lines free of trailing `#` comments. validate-project-analysis.sh reads a
field as everything after the first colon (`fm_value`), so a trailing comment becomes part of the
value. VERIFIED live against the validator: a commented `analyzed_sha` is rejected as "neither a
full 40-character SHA nor the literal 'unknown'", and a commented `lenses: []` counts as ONE
declared lens rather than none.

  analyzed_sha  `git rev-parse HEAD` — the full 40-char SHA when the analysis ran, or the literal
                `unknown` outside a repository. This is PROVENANCE: what was read. Freshness is a
                different question, answered from git history (see "How this report is gated") and
                never from `analyzed_sha == HEAD` — a report can be stamped at HEAD and be stale
                the moment epic-tech-spec.md is committed after it.
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

  `play_level` and `epic_count` are deliberately absent — they are PROJECT facts, and this report
  inherits the project's tier rather than re-declaring it. Two declarations of one tier drift, and
  the epic-altitude copy is the one nobody re-checks.
-->

# Epic Analysis Report: [Epic Name]

**Epic**: [EPIC_ID]  
**Project**: [PROJECT_ID]  
**Date**: [DATE]  
**Gate verdict**: [GATE_VERDICT]

*One verdict, one place. `BLOCKED` when any Issues Found row is Severity `CRITICAL` with Status `open` — story work does not start. `NEEDS_FIXES` when open findings remain and none is CRITICAL — surfaced loudly, blocks nothing. `CLEAN` when every row is `resolved`, `waived DEC-####`, or `refuted`. The Readiness Checklist at the foot of this report feeds this line — it does not restate it, because two status fields drift and only one of them can be right.*

---

## 📊 Information Sources

- `epic.md` → Requirements and success criteria
- `epic-tech-spec.md` → Technical design (research embedded)
- `epic-breakdown.md` → Story mapping and sequencing
- `epic-codebase-scan*.md` (if any) → Brownfield constraints/patterns
- `product-contract.md` → Differentiator pillars, JOB-N, MM-N — the promise side of the coverage matrix
- `evidence-contract.md` → What counts as proof; read in pairs by L6, because a gate whose precondition contradicts it is CRITICAL by rule
- `PRD.md` / `architecture.md` / `context.md` → Project constraints
- The witness graph → `python3 .speck/scripts/graph/speck_graph.py build <PROJECT_DIR> --stdout` is the ONE reader for MM-N / JOB-N completeness; this report never re-parses `product-contract.md` for them

---

## Lens Roster

*Who looked, with what hostile question, and whether they were reading their own homework.*

**Why the roster exists.** A planning corpus produced through the full canonical Build flow — every skill entered, five skeptical-review primitives, premise-challenge, strict validators green — still carried 1 CRITICAL and 13 HIGH defects (project `001-odd`). Every gate it passed was run by the party that had authored the corpus. That is the failure this section is against: AGENTS.md P4 says the adversary is *structural*, and a lens is evidence only when the reviewer did not write what they are reviewing.

**Tier mandate** — the epic inherits the PROJECT's tier (`play_level` and `epic_count` in `project-analysis-report.md`, or `.speck/project.json`), so one project cannot be adversarial at one altitude and self-certified at the other:

- **Sprint**, any size — optional.
- **Build, 1–3 epics** — recommended, not gated.
- **Build, 4+ epics** — REQUIRED, three mandatory lenses: **L3** `promise-coverage`, **L6** `cross-artifact-drift`, **L7** `completeness-critic`. Those three and no others, because each catches a defect class that is *structurally invisible to the author* — an absence, a relationship between two files, and the blind spot itself.
- **Platform**, any size — REQUIRED, all seven.

**Lens ids** — the shared vocabulary, the same seven ids one altitude up in `/project-analyze`:

- **L1** `strategic-alignment` · **L2** `story-boundaries` · **L4** `scope-feasibility` · **L5** `risk` — Platform tier.
- **L3** `promise-coverage` · **L6** `cross-artifact-drift` · **L7** `completeness-critic` — mandatory from Build 4+.

Each lens's **hostile question is copied VERBATIM** from `/epic-analyze` → *The seven lenses* into the row below. It is not restated in this template: a question stated in two places is a question that drifts, and the roster is a record of what was actually asked.

Every row here also becomes an entry in the `lenses:` frontmatter list — the shape is in the comment at the top of this file, and the two must agree.

| Lens | Hostile question | Reviewer | Authored any corpus artifact? | Findings |
|------|------------------|----------|-------------------------------|----------|
| [e.g., L3 promise-coverage] | [e.g., Which MM-N does no story carry?] | [e.g., an agent type or session id that did NOT author this corpus] | [e.g., no] | [e.g., 2] |

---

## Executive Summary

[Overall assessment and top recommendations in 3–8 sentences. Lead with the gate verdict in one plain sentence, then what drove it.]

---

## Coverage Analysis

### Requirement Coverage
- User Stories: [X] total
- With Stories in breakdown: [Y] ([Z]%)
- With validation approach: [A] ([B]%)

### Technical Coverage
- Architecture supports all stories: ✅/❌
- APIs specified: [X of Y]
- Data models defined: ✅/❌
- Integration points defined: ✅/❌

### Promise Coverage (Unaddressed-Promise Gap)

*Completeness is computed against the witness graph, not against this file. `python3 .speck/scripts/graph/speck_graph.py build <PROJECT_DIR> --stdout` emits every `magic-moment` and `job` node; the gate compares that set to the rows below. An MM-N or JOB-N the graph knows about and this matrix does not is `PROMISE_UNCOVERED.P1`. If the graph cannot be read, completeness was **not computed** (`ANALYSIS_COVERAGE_UNCOMPUTED.P2`) — an honest unknown, never a pass.*

*Absence is not inconsistency — zero coverage is a finding in its own right, so every dimension gets a row whether or not this epic carries it. At epic altitude the coverage cell names the story or FR (`S### / FR-###`); the column keeps the project-altitude header so one validator reads both.*

- Differentiator pillars mapped: [e.g., 2] of [e.g., 4]
- Magic moments (MM-N) mapped: [e.g., 3] of [e.g., 6]
- Jobs (JOB-N) mapped: [e.g., 2] of [e.g., 4]

**Status** uses the same vocabulary as the Issues table: `resolved` when at least one story or FR carries the dimension · `open` when nothing does · `waived DEC-####` when a logged decision defers it. An MM-N or JOB-N row left `open` is `CRITICAL` **by rule** and blocks — it does not get to be a HIGH.

| Promise dimension | Source | Epic / story coverage | Status |
|-------------------|--------|----------------------|--------|
| [e.g., MM-2 <magic moment name>] | product-contract §5 | [e.g., S011 / FR-014] | [e.g., resolved] |
| [e.g., JOB-1 <job name>] | product-contract §4 | [e.g., S002 / FR-003] | [e.g., resolved] |
| [e.g., Differentiator: <pillar name>] | product-contract §3 | [e.g., S007] | [e.g., resolved] |
| [e.g., Anti-differentiator guard: <item>] | product-contract §3a | [e.g., S009] | [e.g., resolved] |

---

## Analysis Results

### ✅ Strengths
- [What’s well-designed]
- [What’s clear and actionable]
- [What reduces risk]

### ⚠️ Issues Found

**Severity is assigned BY RULE, not at the author's discretion.** Three classes are CRITICAL by construction. An author who grades one of them HIGH has mis-graded it, not exercised judgement:

1. A cross-artifact `contradictory` verdict — two artifacts that cannot both be satisfied.
2. An unaddressed magic moment (MM-N) or job (JOB-N) in the Promise Coverage matrix above.
3. A gate whose precondition contradicts `evidence-contract.md`.

Everything else is author-judged `HIGH` / `MEDIUM` / `LOW`. **Only `CRITICAL` with Status `open` blocks.** The rule is the load-bearing part: of the 14 defects that motivated this section, 13 were graded below CRITICAL by their own author and would have walked straight through a discretion-graded gate.

**Vocabularies** — Severity: `CRITICAL | HIGH | MEDIUM | LOW` · Verdict: `confirmed | refuted` · Status: `open | resolved | waived DEC-####`.

**ID and Verifier carry the decorrelation.** The ID is `<lens id>-<n>`, so the raising lens is readable off the row (`L3-1` was raised by L3), and `Category` names that lens too. **Verifier** is whoever CONFIRMED the finding, and on any `CRITICAL` or `HIGH` row it must be a *different* lens than the one that raised it — a finding checked only by the party that found it is not decorrelated (`ANALYSIS_DECORRELATION_UNVERIFIED.P2`). `refuted` is a real outcome and belongs in the table: a raised-then-refuted finding is evidence the adversary ran.

| ID | Category | Severity | Description | Recommendation | Verifier | Verdict | Status |
|----|----------|----------|-------------|----------------|----------|---------|--------|
| [e.g., L3-1] | [e.g., promise-coverage] | CRITICAL | [Issue] | [Recommendation] | [e.g., L6] | [e.g., confirmed] | [e.g., open] |
| [e.g., L6-1] | [e.g., cross-artifact-drift] | HIGH | [Issue] | [Recommendation] | [e.g., L7] | [e.g., confirmed] | [e.g., resolved] |

---

## Dependency Analysis

### Critical Path

[S001] → [S004] → [S005] → [S020]  
**Duration**: [X] days

### Parallel Opportunities

- Phase 2: [X] stories can run in parallel
- Phase 3: [Y] stories can run in parallel

### Blockers

- External: [List]
- Technical: [List]

---

## Technical Validation

### Architecture
- Supports all stories: ✅/❌
- Security addressed: ✅/❌
- Performance strategy adequate: ✅/❌

### Technology Stack
- All choices justified: ✅/❌
- Licenses compatible: ✅/❌
- Team skills adequate: ✅/❌

---

## Risk Summary

| Risk | Level | Mitigation | Status |
|------|-------|------------|--------|
| [Risk] | High | [Strategy] | ⚠️ Partial |

---

## Quality Gates

### Test Coverage Plan
- Unit: [Target]% specified
- Integration: [X] scenarios
- E2E: [Y] journeys
- Performance: [Z] benchmarks

### Documentation
- API docs: Planned/Missing
- User docs: Planned/Missing
- Dev docs: Planned/Missing

---

## Recommendations

### Must Fix
1. [Critical issue]
2. [Critical issue]

### Should Fix
1. [Important issue]
2. [Important issue]

### Consider
1. [Enhancement]
2. [Enhancement]

---

## How this report is gated

`bash .speck/scripts/validation/validators/validate-project-analysis.sh --gate <PROJECT_DIR>` exits non-zero on any P1 by default — no `--strict` needed, because a gate that only fires when asked politely is not a gate. `check-epic-prereqs.sh [--strict] <PROJECT_DIR> [--epic <EPIC_ID>]` is the caller that escalates it at epic altitude: exit 0 clear, 1 rejected, 2 invocation error.

- `UNANALYZED_CORPUS.P1` — the gate applies and no analysis report exists.
- `ANALYSIS_STALE.P1` — a corpus artifact has a commit **after** this report's last commit. Content freshness, read from git history; with no history available the answer is `unknown`, never `fresh`.
- `ANALYSIS_CRITICAL_OPEN.P1` — a findings row is `CRITICAL` with Status `open`.
- `PROMISE_UNCOVERED.P1` — an MM-N or JOB-N the graph knows about is missing from the coverage matrix, or sits there unresolved.
- `ANALYSIS_DECORRELATION_UNVERIFIED.P2` — fewer lenses than the tier requires, or a CRITICAL/HIGH row whose Verifier is its own lens.
- `ANALYSIS_COVERAGE_UNCOMPUTED.P2` — the graph could not be read, so matrix completeness was not computed.
- `ANALYSIS_GRANDFATHERED.P2` — a pre-v10.3 project running on its exemption marker. Loud and repeated, never a block, until the analysis runs once.

---

## Readiness Checklist

- [ ] All user stories are represented as stories in epic-breakdown.md
- [ ] Dependencies mapped (no cycles)
- [ ] Architecture and interfaces are clear
- [ ] Tests are planned for critical flows
- [ ] Risks have mitigations
- [ ] Team alignment confirmed
- [ ] Every mandatory lens for this tier ran, with a reviewer that did not author the corpus

*This checklist feeds the **Gate verdict** at the top of the report. It deliberately does not restate it: a second status field is a second source of truth, and the two drift.*

---
*Generated by /epic-analyze command*  
*Template Version: 10.3.0*
