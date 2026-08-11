# epic-validate / matrix-graph

## 1. Readiness states

Same taxonomy as story-validate: `NO-SHIP` → `SHIP`.
Epic MAX claimable = `MIN(story verified states, MATRIX_GRAIN_CAP, GRAPH_CAP)`.

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
8. **INTEGRATION-GREEN**: real round-trip per §7 service across stories; live schema drift when DB + `DATABASE_URL`; no URL → honest  deferral.
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

## 7. Witness graph

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
