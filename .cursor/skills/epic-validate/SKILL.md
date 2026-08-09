---
name: epic-validate
description: Validates epic after stories + audit. Use at epic prove gate.
---

# epic-validate

Prereq: all stories ≥ `IMPL-GREEN`; `/audit --epic <id>` → epic `audit-report.md`.
Output: `[EPIC_DIR]/epic-validation-report.md`, `[EPIC_DIR]/epic-punch-list.md`.
Templates: `.speck/templates/epic/epic-validation-report-template.md`, `.speck/templates/epic/epic-punch-list-template.md`, `.speck/templates/story/validation-report-template.md` (readiness taxonomy).
Verdict: readiness state — never PASS/FAIL.

## 0. Template

Read epic + story validation templates before writing.

## 1. Readiness states

Same taxonomy as story-validate: `NO-SHIP` → `SHIP`.
Epic MAX claimable = `MIN(story verified states, MATRIX_GRAIN_CAP, GRAPH_CAP)`.

## 2. Pre-validate gates (STOP on fail)

1. Every story `validation-report.md` with verified state ≥ `IMPL-GREEN`. Any `NO-SHIP` → STOP.
2. **`/audit --epic <id>` → `audit-report.md`**. Missing or P0 → STOP.
3. **`evidence-contract.md`**. Missing → STOP.
4. **Archetype** — `.speck/project.json` → `project_archetype`.
   - `infra_service` / `backend_api` / no UI → skip LARP + Premise-Challenge.
   - UI-facing epic → full-flow `/larp` per persona (JTBD end-to-end, not per-story segments). Missing → STOP.
   - High-impact surfaces → `/speck-premise-challenge` documented. Missing/failed → cap `IMPL-GREEN`/`INTEGRATION-GREEN`.

## 3. Four axes

| Axis | Epic validate |
|------|---------------|
| CORRECT | Story rollup, audit, matrix, graph, mutation |
| ON-CONTRACT | evidence-contract gates |
| FELT-GOOD | Naive-hostile LARP on cold-start JTBD walkthrough (consumer UX-RC+) |
| TASTE | Connoisseur-hostile (`/speck-larp` Job C) for consumer UX-RC+ |

LARP: **DOES-IT-WORK** = JTBD cold-start walkthrough on built artifact; **IS-IT-GOOD** = FELT + TASTE + comprehension rubric.
Graph proves traceable/complete/fresh — never faithful/good/excellent.

## 4. Algorithm

1. Read every story `validation-report.md` — extract verified states + evidence paths.
2. MAX claimable = MIN(story states, **MATRIX_GRAIN_CAP**, **GRAPH_CAP**).
3. **Device-walk**: epic/story criteria marked `device-walk` without `larp-recordings/<sha>-human-attestation.md` → cap epic at `UX-RC`; refuse `SHIP-RC+`.
4. Read epic `audit-report.md` — P0 lowers max.
5. **JTBD cold-start LARP** (UI epics — mandatory centerpiece, non-deferrable):
   - Clean boot, no dev shortcuts, real nav/auth on **built artifact** (browser/operator LARP).
   - Store axe-core JSON; code-level composition reading is NOT UX-RC evidence.
   - First-Time Comprehension rubric on walkthrough.
   - Fail/dead-end/404 on primary path → cap `IMPL-GREEN` regardless of story passes.
   - Infra blocker cap at `INTEGRATION-GREEN` only with logged reproduced LARP failure (P3). Try sandbox recipe first (local DB, review-session backdoor, token injection, MSW/wiremock).
6. **FELT-GOOD**: consumer UX-RC+ → naive-hostile across epic JTBD; not run → `felt_axis: uncovered`, cap below UX-RC.
7. **Deferrals** — required section with `Cap Status` per row; same cap rules as story-validate; browser cold-start LARP never `autonomous-not-done`.
8. **INTEGRATION-GREEN**: real round-trip per §7 service across stories; live schema drift when DB + `DATABASE_URL`; no URL → honest ⚠️ deferral.
9. Non-UI epics: Option B System Operational Scenario Walkthrough → declare `API-RC` when evidence-contract §8 criteria pass.

## 5. Promise conservation (gates readiness)

```bash
bash .speck/scripts/validation/validators/validate-traceability-matrix.sh --require-evidence [EPIC_DIR]
```

- Every `PRM-NNN`: `discharged` | `descoped` (DEC) | `pilot-gated`. Open/undischarged → cap at last clean state.
- Read `MATRIX_GRAIN_CAP=<enum>` + GRAIN FLOOR line. Un-graded matrix caps `INTEGRATION-GREEN`.
- `--require-evidence`: per-row grain teeth BLOCK (grain ≤ story effective state; ≥ ux-rc row needs walk evidence).
- **Evaporation audit**: grep shipped model/code for dead seams (enum never set, prop-gated button uncalled, orphan route). Each → DEC or P1 fix in Promise Conservation section.

## 6. Gate liveness (#88)

```bash
bash .speck/scripts/validation/validators/validate-gate-liveness.sh --strict
bash .speck/scripts/validation/validators/gate-liveness-probe.sh --require-liveness specs/projects/<PROJECT_ID>/evidence-contract.md
```

- `GATE_DISARMED.P1` → P1 (gate manufactures false evidence).
- `GATE_LIVENESS_UNVERIFIED.P2` → fold into MAX claimable.
- Hard-block at COMMERCIAL-RC/SHIP-RC owned by project-validate; epic runs probe at UX-RC+ transition.

## 7. Witness graph (v8.8)

```bash
python3 .speck/scripts/graph/speck_graph.py build specs/projects/<PROJECT_ID>
python3 .speck/scripts/graph/speck_graph.py check specs/projects/<PROJECT_ID>
```

| Code | Meaning |
|------|---------|
| `DANGLING_REF.P1` | Discharge points at missing story/AC |
| `DUP_ID.P1` | Two story dirs share S-number |
| `PHANTOM_PROMISE.P1` | MM/JOB promised, no story delivers |
| `GRAPH_CAP` | Un-migrated/stale graph caps `INTEGRATION-GREEN` |
| `UNJUDGED_SURFACE.P2` | MM-N with no verdict caps ux-rc+ |

`ORPHAN_CODE` → NOT-evaluated until tests-as-join — never a pass.

## 8. Cross-epic + composition

- Test seams to dependent epics (data/auth/navigation).
- JTBD walkthrough section in report: core job, entry point, journey steps, composition assessment, cross-epic integration.
- JTBD `BLOCKED`/`PARTIAL` → epic fails regardless of story greens.

## 9. Visual (UI epics)

Reference: `.cursor/skills/visual-testing/SKILL.md` + `.cursor/skills/visual-testing/references/<host>.md`.
Aggregate story `larp-recordings/` + visual sections; wireframe adherence; user-journey touchpoints; cross-story consistency; design-system adoption %.
Multimodal: `Read` screenshots for coherence — cite paths.

## 10. Mutation (epic-cited guards)

Same rules as story-validate. **Merged-tree rule**: mutation SHA = merge commit; conductor re-runs in merged tree. Worktree-branch SHA = finding.

Receipt verify:
```bash
.speck/scripts/validation/mutate-guard.sh --verify-receipt [EPIC_DIR]/epic-validation-report.md
```

## 11. Legacy rollup checks

Epic vision vs `epic.md`; architecture vs `epic-tech-spec.md`; story completion from `epic-breakdown.md`; aggregate tests; Cursor rules compliance across stories; performance/security/docs.

Parallel subagents when host supports; else sequential.

## 12. Write outputs

1. `epic-validation-report.md` — match template; evaluative drift section if state changed.
2. `epic-punch-list.md` — match template.
3. Update `epic.md` status + link report.

Post-write:
```bash
bash .speck/scripts/validation/validators/validate-felt-axis.sh --strict epic-validation-report.md
bash .speck/scripts/validation/validators/validate-taste-axis.sh --strict epic-validation-report.md
```

Readiness ≥ UX-RC: `.speck/scripts/regenerate-project-readme.sh --epic-validated <E###>`.
Trigger `/project-state`. Bypass/blocked LARP → `/speck-feedback`.

Audit subagent stall: degrade gracefully, complete scope sequentially, disclose fallback in audit + epic reports.

## NEVER / ALWAYS

- NEVER claim epic UX-RC from story greens alone (composition fallacy)
- NEVER defer browser cold-start LARP for UI epics
- NEVER discharge PRM from JTBD sample alone (long tail must exist)
- NEVER hand-wave phantom/dead seams
- NEVER substitute PASS/FAIL for readiness state
- ALWAYS run `/audit --epic` first
- ALWAYS apply MIN(story, MATRIX_GRAIN_CAP, GRAPH_CAP)
- ALWAYS SHA-stamp report
