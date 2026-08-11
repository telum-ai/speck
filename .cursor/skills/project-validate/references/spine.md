# project-validate — spine

# project-validate

Prereq: every epic meets the project's interface-specific ambition; fresh `speck-recheck` (<7 days).
Output: `[PROJECT_DIR]/project-validation-report.md`, `project-validation-summary.md`, `project-punch-list.md`.
Templates: `.speck/templates/project/project-validation-report-template.md`, `project-validation-summary-template.md`, `project-punch-list-template.md`, `.speck/templates/story/validation-report-template.md` (readiness taxonomy).
Verdict: readiness state + production GO/NO-GO — never PASS/FAIL alone.

## 0. Template

Read all project validation templates before writing.

## 2. Readiness states

Same taxonomy: `NO-SHIP` → `SHIP`.
Project MAX claimable = MIN(epic verified states, coverage-matrix cap, gate-liveness cap, recheck drift cap).

## 3. Pre-validate gates (STOP on fail)

1. Read `.speck/project.json` archetype. UI projects require every epic at `UX-RC` or the higher project ambition; nonvisual/API projects require `API-RC` or the higher ambition. Lower → STOP and route back to `speck-larp`, then `epic-validate`.
2. **`speck-recheck` within 7 days**. Missing/stale → STOP.
3. **`evidence-contract.md`** + **`product-contract.md`**. Missing → STOP.
4. **Prior project-level job evidence on the launch build** — UI requires the full JTBD per persona plus its visual evidence; nonvisual/API requires the evidence-contract's end-to-end operational scenario with principal, negative control, telemetry, and real seam read-backs. Missing/stale evidence → STOP and route back to `speck-larp`.
5. **SHIP-RC+ PROFILE gates**:
```bash
bash .speck/scripts/validation/validators/validate-readme.sh --strict
bash .speck/scripts/profile-drift-check.sh --claim "$claimed_state"
```
Any `PROFILE_DRIFT.P1` → STOP.

## NEVER / ALWAYS

- NEVER claim SHIP-RC with all epics green but BLOCKED product JTBD
- NEVER skip fresh `speck-recheck`
- NEVER bypass gate-liveness at COMMERCIAL-RC/SHIP-RC
- NEVER substitute epic composition for product-level smoke
- NEVER ignore LEGIBILITY.P1 for commercial ship
- ALWAYS MIN(epic states) for project ceiling
- ALWAYS test cross-epic dependency arrows
- ALWAYS SHA-stamp reports
