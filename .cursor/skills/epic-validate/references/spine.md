# epic-validate — spine

# epic-validate

Prereq: all stories ≥ `IMPL-GREEN`; separate epic audit, and for UI epics the required LARP/visual evidence, already exist for the build under claim.
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
2. **Epic `audit-report.md` from `speck-audit`**. Missing or P0 → STOP.
3. **`evidence-contract.md`**. Missing → STOP.
4. **Archetype** — `.speck/project.json` → `project_archetype`.
   - `infra_service` / `backend_api` / no UI → prior operational `speck-larp` evidence for the composed service job; use `API-RC` and skip only visual/FELT/TASTE evidence. Missing → STOP and route back to `speck-larp`.
   - UI-facing epic → prior full-flow LARP evidence per persona (JTBD end-to-end, not per-story segments). Missing → STOP and route back to `speck-larp`.
5. Any high-impact product, technical, data, integration, operational, pricing, or UI commitment cites its prior `speck-premise-challenge` verdict. Missing/failed → cap `IMPL-GREEN`/`INTEGRATION-GREEN`.
