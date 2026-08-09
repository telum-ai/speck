# project-analyze — procedure

Prereq: project planning complete (`project.md`, `PRD.md`, `epics.md`).
Output: `[PROJECT_DIR]/project-analysis-report.md` (template: `.speck/templates/project/project-analysis-report-template.md`).
Enforced by: `validate-project-analysis.sh --gate`; `check-epic-prereqs.sh` at `/epic-specify`.
NOT `/project-validate` — that is post-implementation release gate.

## 0. Template

Read `.speck/templates/project/project-analysis-report-template.md` before writing.

## 1. Scope and tier

| Play level | Epics | Gate |
|------------|-------|------|
| Sprint | any | optional |
| Build | 1–3 | recommended |
| Build | 4+ | REQUIRED — 3 lenses (L3, L6, L7) |
| Platform | any | REQUIRED — all 7 lenses |

- Read `.speck/project.json` → `play_level` (missing = Platform).
- Count epics: max of `### E###` in `epics.md` and `epics/` dirs.
- STOP if `project.md`, `PRD.md`, or `epics.md` missing — run `/project-plan` first.
- Load corpus: `project.md`, `PRD.md`, `epics.md`, `product-contract.md`, `context.md`, `architecture.md`, `evidence-contract.md`, `project-roadmap.md`, `project-landscape-overview.md`, `project-decisions-log.md` — whichever exist.
- Record `git rev-parse HEAD` → `analyzed_sha`.

## 2. Role separation (P4)

1. Each lens: reviewer who did **not** author the corpus (subagent / other session / other model).
2. Lenses do not share findings until verification.
3. Verifier ≠ lens that raised the finding; verifier ≠ corpus author.
4. Every lens row records `Reviewer` and `Authored any corpus artifact?` honestly.
5. Solo agent allowed only if Reviewer column discloses it — do not claim decorrelation beyond that.

## 3. Lenses

Hostile question = find what is wrong. Never confirm the plan. Same ids as `/epic-analyze`.

| # | id | Hostile question (abbrev) | Tier |
|---|-----|---------------------------|------|
| L1 | strategic-alignment | PRD goal whose success metric cannot distinguish met from missed; vision commitment in `project.md` silently dropped by epic set | Platform |
| L2 | epic-boundaries | Two epics own same requirement; requirement no epic owns; dependency cycle; epic cannot deliver standalone value | Platform |
| L3 | promise-coverage | MM-N/JOB-N in graph with no epic/story/DEC/pilot-gate; differentiator pillar in `product-contract.md` §3 named nowhere in `epics.md` | Build 4+ · Platform |
| L4 | scope-feasibility | Placeholder epic estimate; plan unbuildable at declared scale/constraints; level story-band violated (L1: 1–10 · L2: 5–15 · L3: 12–40 · L4: 40+) | Platform |
| L5 | risk | Mitigation is unbuilt work in no epic; single dependency failure strands multiple epics; unknown treated as known | Platform |
| L6 | cross-artifact-drift | Two project artifacts that cannot both be satisfied (PRD vs product-contract, epics vs context, evidence-contract vs surfaces built) | Build 4+ · Platform |
| L7 | completeness-critic | Absent dimension an epic author must invent; day-one question no artifact answers; unmentioned failure/empty/permission | Build 4+ · Platform |

## 4. Promise inventory (graph only)

```bash
python3 .speck/scripts/graph/speck_graph.py build specs/projects/[PROJECT_ID] --stdout \
  | python3 -c "import json,sys; [print(n['id'], n['kind'], n.get('title','')) for n in json.load(sys.stdin)['nodes'] if n['kind'] in ('magic-moment','job')]"
```

Every printed id → coverage matrix row.
Graph unavailable → report `NOT COMPUTED` (gate: `ANALYSIS_COVERAGE_UNCOMPUTED.P2`). Never hand-grep `### MM-`.

## 5. Run lenses

Dispatch one reviewer per required lens. Inputs: hostile question + artifact list only.
Lens returns findings only — no final severity, no self-adjudication.

## 6. Verify findings

- Hand each finding to a different verifier. Verdict: `confirmed` | `refuted`.
- Refutation must quote artifact text. Unrefuted → `confirmed`.
- CRITICAL-by-rule refutation must show the rule does not apply.
- Non-CRITICAL disagreement → majority-refute (N = tier lens count).
- Keep `refuted` rows in the table.
- Write `Verifier` + `Verdict` on every Issues Found row.

## 7. Severity (by rule)

CRITICAL by construction:
- cross-artifact `contradictory` (two artifacts cannot both be satisfied)
- unaddressed MM-N or JOB-N in coverage matrix
- gate precondition contradicts evidence contract

Else: HIGH | MEDIUM | LOW by judgment.
Only CRITICAL + Status `open` blocks.
Vocab: Severity `CRITICAL|HIGH|MEDIUM|LOW` · Verdict `confirmed|refuted` · Status `open|resolved|waived DEC-####`.
Waiver → real `/speck-decision-log` entry.

## 8. Write report

Path: `[PROJECT_DIR]/project-analysis-report.md`. Match template.

Frontmatter required:

```yaml
---
artifact_type: project-analysis-report
speck_version: 11.0.0
analyzed_sha: <40-char HEAD>
play_level: build
epic_count: <int>
lenses:
  - id: L3
    name: promise-coverage
    reviewer: <id>
    authored_corpus: false
---
```

Required:
- `## Lens Roster` — `Lens | Hostile question | Reviewer | Authored any corpus artifact? | Findings`
- `### Issues Found` — `ID | Category | Severity | Description | Recommendation | Verifier | Verdict | Status`
- `### Promise Coverage (Unaddressed-Promise Gap)` — `Promise dimension | Source | Epic / story coverage | Status`
- `**Gate verdict**: BLOCKED | NEEDS_FIXES | CLEAN`
- Keep strengths, metrics, detailed findings, recommendations, readiness assessment per template.

Commit report after the corpus it analyses. Edit `PRD.md` / `epics.md` / `product-contract.md` after report → `ANALYSIS_STALE.P1`.

## 9. Verdict

| Verdict | Condition | Next |
|---------|-----------|------|
| BLOCKED | ≥1 CRITICAL open | Fix / waive / refute; re-run |
| NEEDS_FIXES | Open non-CRITICAL | Owner decides; epic work may start |
| CLEAN | All resolved / waived / refuted | `/epic-specify` |

Validate:

```bash
bash .speck/scripts/validation/validate-template.sh --strict [PROJECT_DIR]/project-analysis-report.md
bash .speck/scripts/validation/validators/validate-project-analysis.sh --gate specs/projects/[PROJECT_ID]
bash .speck/scripts/validation/check-epic-prereqs.sh specs/projects/[PROJECT_ID]
```

Exit 0 = clear · 1 = gate rejected · 2 = invocation error. `--strict` on gate escalates P2 to exit 1.

## Gate codes

| Code | When |
|------|------|
| `UNANALYZED_CORPUS.P1` | Gate applies; no report |
| `ANALYSIS_STALE.P1` | PRD/epics/product-contract commit after report |
| `ANALYSIS_CRITICAL_OPEN.P1` | CRITICAL open |
| `PROMISE_UNCOVERED.P1` | MM/JOB missing or unresolved in matrix |
| `ANALYSIS_DECORRELATION_UNVERIFIED.P2` | Too few lenses, or Verifier == Lens on CRITICAL/HIGH |
| `ANALYSIS_COVERAGE_UNCOMPUTED.P2` | Graph unread |
| `ANALYSIS_GRANDFATHERED.P2` | Pre-v10.3 marker present — notice only, does not block |

Decorrelation check is structural (roster width + distinct verifier names), not proof a second mind existed. High stakes: dispatch real subagents; verify Skill invocations before accepting.

## NEVER / ALWAYS

- NEVER judge severity where the mapping rule assigns CRITICAL
- NEVER self-verify a finding
- NEVER delete `refuted` rows
- NEVER hand-grep MM/JOB instead of the graph
- NEVER write CLEAN with uncovered MM/JOB
- NEVER claim decorrelation the Reviewer column contradicts
- ALWAYS write frontmatter + full `analyzed_sha`
- ALWAYS commit report after corpus; re-run after corpus edits
