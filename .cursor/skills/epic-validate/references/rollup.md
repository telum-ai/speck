# epic-validate / rollup

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
