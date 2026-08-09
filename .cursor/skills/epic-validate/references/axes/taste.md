# epic-validate / taste

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
8. **INTEGRATION-GREEN**: real round-trip per §7 service across stories; live schema drift when DB + `DATABASE_URL`; no URL → honest  deferral.
9. Non-UI epics: Option B System Operational Scenario Walkthrough → declare `API-RC` when evidence-contract §8 criteria pass.

## 5. Promise conservation (gates readiness)

```bash
bash .speck/scripts/validation/validators/validate-traceability-matrix.sh --require-evidence [EPIC_DIR]
```
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
