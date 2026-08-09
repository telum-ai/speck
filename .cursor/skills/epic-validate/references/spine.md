# epic-validate — spine

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

## 5. Promise conservation (gates readiness)

```bash
bash .speck/scripts/validation/validators/validate-traceability-matrix.sh --require-evidence [EPIC_DIR]
```

- Every `PRM-NNN`: `discharged` | `descoped` (DEC) | `pilot-gated`. Open/undischarged → cap at last clean state.
- Read `MATRIX_GRAIN_CAP=<enum>` + GRAIN FLOOR line. Un-graded matrix caps `INTEGRATION-GREEN`.
- `--require-evidence`: per-row grain teeth BLOCK (grain ≤ story effective state; ≥ ux-rc row needs walk evidence).
- **Evaporation audit**: grep shipped model/code for dead seams (enum never set, prop-gated button uncalled, orphan route). Each → DEC or P1 fix in Promise Conservation section.

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


# epic-validate

Prereq: all stories ≥ `IMPL-GREEN`; `/audit --epic <id>` → epic `audit-report.md`.
Output: `[EPIC_DIR]/epic-validation-report.md`, `[EPIC_DIR]/epic-punch-list.md`.
Templates: `.speck/templates/epic/epic-validation-report-template.md`, `.speck/templates/epic/epic-punch-list-template.md`, `.speck/templates/story/validation-report-template.md` (readiness taxonomy).
Verdict: readiness state — never PASS/FAIL.

## 0. Template

Read epic + story validation templates before writing.
