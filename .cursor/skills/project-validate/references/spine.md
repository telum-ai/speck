# project-validate — spine

# project-validate

Prereq: every epic ≥ `UX-RC` (or project ambition); fresh `/recheck` (<7 days).
Output: `[PROJECT_DIR]/project-validation-report.md`, `project-validation-summary.md`, `project-punch-list.md`.
Templates: `.speck/templates/project/project-validation-report-template.md`, `project-validation-summary-template.md`, `project-punch-list-template.md`, `.speck/templates/story/validation-report-template.md` (readiness taxonomy).
Verdict: readiness state + production GO/NO-GO — never PASS/FAIL alone.

## 0. Template

Read all project validation templates before writing.

## 2. Readiness states

Same taxonomy: `NO-SHIP` → `SHIP`.
Project MAX claimable = MIN(epic verified states, coverage-matrix cap, gate-liveness cap, recheck drift cap).

## 3. Pre-validate gates (STOP on fail)

1. Every epic `epic-validation-report.md` verified ≥ `UX-RC` (or higher per ambition). Lower → STOP: run `/larp` + `/epic-validate`.
2. **`/recheck` within 7 days**. Missing/stale → STOP.
3. **`evidence-contract.md`** + **`product-contract.md`**. Missing → STOP.
4. **Full JTBD walkthrough per persona** in evidence-contract — latest `larp-recordings/<sha>-<persona>-findings.md` on launch build. Missing persona → STOP.
5. **SHIP-RC+ PROFILE gates**:
```bash
bash .speck/scripts/validation/validators/validate-readme.sh --strict
bash .speck/scripts/profile-drift-check.sh
```
Any `PROFILE_DRIFT.P1` → STOP.

## 4. Four axes (project rollup)

| Axis | Project validate |
|------|------------------|
| CORRECT | Epic rollup, PRD coverage, tests, gate-liveness |
| ON-CONTRACT | product-contract + evidence-contract |
| FELT-GOOD | Persona JTBD LARPs + legibility check |
| TASTE | Connoisseur coverage across flagship surfaces |

LARP: **DOES-IT-WORK** = cross-epic JTBD smoke per persona; **IS-IT-GOOD** = FELT + TASTE + legibility.

## 8. Coverage matrix (breadth)

Always-on (cheap):
```bash
.speck/scripts/validation/generate-coverage-matrix.sh --level project specs/projects/<PROJECT_ID>
bash .speck/scripts/validation/validators/validate-coverage-matrix.sh specs/projects/<PROJECT_ID>
```

`--exhaustive` (opt-in, expensive): fan-out `/speck-larp <persona> --tier=torture` per cell (persona × route × {happy,error,empty,loading} × viewport × theme + input-variety on §8 AI surfaces). Deterministic `banned-language-lint.sh` across N samples; full-page axe + Lighthouse; evidence-contract §11 resilience cells. Record Job A/B/C verdict + real `larp-recordings/…` path per cell.

Breadth verdict caps (never raises) claimable state. `validate-coverage-matrix.sh --strict` before SHIP-RC when §8 declares matrix required.

## 10. Write outputs

1. `project-validation-report.md`
2. `project-validation-summary.md`
3. `project-punch-list.md`

Post-write axis validators (consumer UX-RC+ claims):
```bash
bash .speck/scripts/validation/validators/validate-felt-axis.sh --strict project-validation-report.md
bash .speck/scripts/validation/validators/validate-taste-axis.sh --strict project-validation-report.md
```

## NEVER / ALWAYS

- NEVER claim SHIP-RC with all epics green but BLOCKED product JTBD
- NEVER skip fresh `/recheck`
- NEVER bypass gate-liveness at COMMERCIAL-RC/SHIP-RC
- NEVER substitute epic composition for product-level smoke
- NEVER ignore LEGIBILITY.P1 for commercial ship
- ALWAYS MIN(epic states) for project ceiling
- ALWAYS test cross-epic dependency arrows
- ALWAYS SHA-stamp reports


# project-validate

Prereq: every epic ≥ `UX-RC` (or project ambition); fresh `/recheck` (<7 days).
Output: `[PROJECT_DIR]/project-validation-report.md`, `project-validation-summary.md`, `project-punch-list.md`.
Templates: `.speck/templates/project/project-validation-report-template.md`, `project-validation-summary-template.md`, `project-punch-list-template.md`, `.speck/templates/story/validation-report-template.md` (readiness taxonomy).
Verdict: readiness state + production GO/NO-GO — never PASS/FAIL alone.

## 0. Template

Read all project validation templates before writing.

## 3. Pre-validate gates (STOP on fail)

1. Every epic `epic-validation-report.md` verified ≥ `UX-RC` (or higher per ambition). Lower → STOP: run `/larp` + `/epic-validate`.
2. **`/recheck` within 7 days**. Missing/stale → STOP.
3. **`evidence-contract.md`** + **`product-contract.md`**. Missing → STOP.
4. **Full JTBD walkthrough per persona** in evidence-contract — latest `larp-recordings/<sha>-<persona>-findings.md` on launch build. Missing persona → STOP.
5. **SHIP-RC+ PROFILE gates**:
```bash
bash .speck/scripts/validation/validators/validate-readme.sh --strict
bash .speck/scripts/profile-drift-check.sh
```
Any `PROFILE_DRIFT.P1` → STOP.
