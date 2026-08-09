# epic-validate / backend-skip

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

## 7. Witness graph (v8.8)
