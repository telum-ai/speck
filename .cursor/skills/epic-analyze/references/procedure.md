# epic-analyze — procedure

Prereq: epic planning complete (`epic.md`, `epic-tech-spec.md`, `epic-breakdown.md`).
Output: `[EPIC_DIR]/epic-analysis-report.md` (template: `.speck/templates/epic/epic-analysis-report-template.md`).
Enforced by: `validate-template.sh --strict` on the report; story work gated at Build 4+ / Platform.

## 0. Template

Read `.speck/templates/epic/epic-analysis-report-template.md` before writing.

## 1. Scope and tier

| Play level | Epics in project | Gate |
|------------|------------------|------|
| Sprint | any | optional |
| Build | 1–3 | recommended |
| Build | 4+ | REQUIRED — 3 lenses (L3, L6, L7) |
| Platform | any | REQUIRED — all 7 lenses |

- Read `.speck/project.json` → `play_level` (missing = Platform).
- Count epics: max of `### E###` in `epics.md` and `epics/` dirs.
- STOP if `epic.md`, `epic-tech-spec.md`, or `epic-breakdown.md` missing.
- Load epic corpus + project `PRD.md`, `architecture.md`, `context.md`, `product-contract.md`, constitutions if present.
- Record `git rev-parse HEAD` → `analyzed_sha`.

## 2. Role separation (P4)

1. Each lens: reviewer who did **not** author the corpus (subagent / other session / other model).
2. Lenses do not share findings until verification.
3. Verifier ≠ lens that raised the finding; verifier ≠ corpus author.
4. Every lens row records `Reviewer` and `Authored any corpus artifact?` honestly.
5. Solo agent allowed only if Reviewer column discloses it — do not claim decorrelation beyond that.

## 3. Lenses

Hostile question = find what is wrong. Never confirm the plan.

| # | id | Hostile question (abbrev) | Tier |
|---|-----|---------------------------|------|
| L1 | strategic-alignment | Project promise claimed but unimplemented; success criterion without measure; constitution MUST broken | Platform |
| L2 | story-boundaries | Shared AC; orphan AC; dependency cycle; non-solo-validatable story | Platform |
| L3 | promise-coverage | MM-N/JOB-N in scope with no story/DEC/pilot-gated; wireframe/seam with no matrix row | Build 4+ · Platform |
| L4 | scope-feasibility | Placeholder estimate; critical path longer than shape; unsafe parallel file collision | Platform |
| L5 | risk | Unknown treated as known; mitigation not in any story; blocker with no fallback | Platform |
| L6 | cross-artifact-drift | Two epic artifacts that cannot both be satisfied | Build 4+ · Platform |
| L7 | completeness-critic | Absent dimension a story author must invent; unmentioned failure/empty/permission | Build 4+ · Platform |

## 4. Promise inventory (graph only)

```bash
python3 .speck/scripts/graph/speck_graph.py build specs/projects/[PROJECT_ID] --stdout \
  | python3 -c "import json,sys; [print(n['id'], n['kind'], n.get('title','')) for n in json.load(sys.stdin)['nodes'] if n['kind'] in ('magic-moment','job')]"
```

Every printed id in this epic's scope → coverage matrix row.
Graph unavailable → report `NOT COMPUTED` (gate: `ANALYSIS_COVERAGE_UNCOMPUTED.P2`). Never hand-grep `### MM-`.
UI-only MM on backend epic → deferral naming the carrying epic; never silent pass.

## 5. Traceability conservation

```bash
bash .speck/scripts/validation/validators/validate-traceability-matrix.sh [EPIC_DIR]
```

- Open/unmapped `PRM-NNN` → P1 BLOCK (promise evaporation).
- Missing `traceability-matrix.md` → P1 BLOCK: re-run `/epic-plan` step 6b.
- Un-enumerated promise (no row) → P1 via L3.

## 6. Run lenses

Dispatch one reviewer per required lens. Inputs: hostile question + artifact list only.
Lens returns findings only — no final severity, no self-adjudication.

## 7. Verify findings

- Hand each finding to a different verifier. Verdict: `confirmed` | `refuted`.
- Refutation must quote artifact text. Unrefuted → `confirmed`.
- CRITICAL-by-rule refutation must show the rule does not apply.
- Keep `refuted` rows in the table.
- Write `Verifier` + `Verdict` on every Issues Found row.

## 8. Severity (by rule)

CRITICAL by construction:
- cross-artifact `contradictory` (two artifacts cannot both be satisfied)
- unaddressed MM-N or JOB-N in coverage matrix
- gate precondition contradicts evidence contract

Else: HIGH | MEDIUM | LOW by judgment.
Only CRITICAL + Status `open` blocks.
Vocab: Severity `CRITICAL|HIGH|MEDIUM|LOW` · Verdict `confirmed|refuted` · Status `open|resolved|waived DEC-####`.
Waiver → real `/speck-decision-log` entry.

## 9. Write report

Path: `[EPIC_DIR]/epic-analysis-report.md`. Match template.

Frontmatter required:

```yaml
---
artifact_type: epic-analysis-report
speck_version: 11.0.0
analyzed_sha: <40-char HEAD>
lenses:
  - id: L3
    name: promise-coverage
    reviewer: <id>
    authored_corpus: false
---
```

Required:
- `## Lens Roster` — `Lens | Hostile question | Reviewer | Authored any corpus artifact? | Findings`
- Issues Found table with Verifier + Verdict + Status
- Promise Coverage matrix
- `**Gate verdict**: BLOCKED | NEEDS_FIXES | CLEAN`

Commit report after the corpus it analyses. Corpus edit after report → `ANALYSIS_STALE.P1`.

## 10. Verdict

| Verdict | Condition | Next |
|---------|-----------|------|
| BLOCKED | ≥1 CRITICAL open | Fix / waive / refute; re-run |
| NEEDS_FIXES | Open non-CRITICAL | Owner decides; stories may start |
| CLEAN | All resolved / waived / refuted | `/story-specify` |

Validate:

```bash
bash .speck/scripts/validation/validate-template.sh --strict [EPIC_DIR]/epic-analysis-report.md
bash .speck/scripts/validation/check-epic-prereqs.sh specs/projects/[PROJECT_ID] --epic [EPIC_ID]
```

## Gate codes

| Code | When |
|------|------|
| `UNANALYZED_CORPUS.P1` | Gate applies; no report |
| `ANALYSIS_STALE.P1` | Corpus commit after report |
| `ANALYSIS_CRITICAL_OPEN.P1` | CRITICAL open |
| `PROMISE_UNCOVERED.P1` | MM/JOB missing or unresolved in matrix |
| `ANALYSIS_DECORRELATION_UNVERIFIED.P2` | Too few lenses, or Verifier == Lens on CRITICAL/HIGH |
| `ANALYSIS_COVERAGE_UNCOMPUTED.P2` | Graph unread |
| `ANALYSIS_GRANDFATHERED.P2` | Pre-v10.3 marker present |

Decorrelation check is structural (roster width + distinct verifier names), not proof a second mind existed. For high stakes: dispatch real subagents; verify Skill invocations before accepting.

## NEVER / ALWAYS

- NEVER judge severity where the mapping rule assigns CRITICAL
- NEVER self-verify a finding
- NEVER delete `refuted` rows
- NEVER hand-grep MM/JOB instead of the graph
- NEVER write CLEAN with uncovered MM/JOB
- NEVER claim decorrelation the Reviewer column contradicts
- ALWAYS write frontmatter + full `analyzed_sha`
- ALWAYS commit report after corpus; re-run after corpus edits
