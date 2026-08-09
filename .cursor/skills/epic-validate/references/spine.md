# epic-validate — spine

Prereq: all stories ≥ `IMPL-GREEN`; `/audit --epic <id>` → epic `audit-report.md`.
Output: `epic-validation-report.md`, `epic-punch-list.md`.
Templates: `.speck/templates/epic/epic-validation-report-template.md`, `epic-punch-list-template.md`, story validation-report-template (taxonomy).
Verdict: readiness state — never PASS/FAIL.
MAX claimable = `MIN(story verified states, MATRIX_GRAIN_CAP, GRAPH_CAP)`.

## Axes
| Axis | Epic |
|------|------|
| CORRECT | Story rollup, audit, matrix, graph, mutation |
| ON-CONTRACT | evidence-contract |
| FELT-GOOD | Naive-hostile JTBD walkthrough (consumer UX-RC+) |
| TASTE | Connoisseur Job C |

Graph proves traceable/complete/fresh — never faithful/good/excellent.

## Pre-STOP
1. Every story validation-report ≥ IMPL-GREEN; any NO-SHIP → STOP.
2. audit-report missing/P0 → STOP.
3. evidence-contract missing → STOP.

## NEVER / ALWAYS
- NEVER claim UX-RC from story greens alone
- NEVER defer browser cold-start LARP for UI epics
- NEVER discharge PRM from JTBD sample alone
- NEVER PASS/FAIL instead of readiness
- ALWAYS `/audit --epic` first; ALWAYS MIN(story, MATRIX_GRAIN_CAP, GRAPH_CAP); ALWAYS SHA-stamp
