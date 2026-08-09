# project-validate — spine

Prereq: every epic ≥ UX-RC (or ambition); `/recheck` <7d.
Output: project-validation-report.md, project-validation-summary.md, project-punch-list.md.
Verdict: readiness + GO/NO-GO — never PASS/FAIL alone.
MAX = MIN(epic states, coverage-matrix cap, gate-liveness cap, recheck drift cap).

## Play level
| Level | Scope |
|-------|-------|
| Sprint | sprint-log success → /project-promote; stop |
| Build | PRD/epics/product-contract/readiness; skip constitution+design-system coverage |
| Platform | Full |

## Axes
CORRECT=epic rollup+PRD+tests+liveness · ON-CONTRACT=product+evidence · FELT=persona JTBD+legibility · TASTE=flagship surfaces

## Pre-STOP
1. Every epic-validation-report ≥ UX-RC (or ambition) else STOP.
2. recheck <7d else STOP.
3. evidence-contract + product-contract else STOP.
4. JTBD LARP per persona on launch build else STOP.
5. SHIP-RC+: validate-readme --strict + profile-drift-check; PROFILE_DRIFT.P1 → STOP.

## NEVER / ALWAYS
- NEVER SHIP-RC with BLOCKED product JTBD; NEVER skip recheck; NEVER bypass gate-liveness at COMMERCIAL/SHIP-RC
- NEVER ignore LEGIBILITY.P1; ALWAYS MIN(epic states); ALWAYS cross-epic arrows; ALWAYS SHA-stamp
