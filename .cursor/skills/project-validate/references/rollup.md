# project-validate / rollup

## 1. Play level

Read `.speck/project.json` → `play_level` (missing = Platform).

| Level | Scope |
|-------|-------|
| Sprint | Success metric in `sprint-log.md`; if hit → `/project-promote`. Stop here. |
| Build | PRD, epic completion, product-contract, readiness gates. Skip constitution + design-system coverage. |
| Platform | Full flow below. |

## 5. Algorithm

1. Read every epic `epic-validation-report.md` — extract verified states.
2. MAX claimable = MIN(epic states).
3. Read epic/story audit reports — P0 lowers max.
4. Read the `speck-recheck` report — drift lowers max.
5. Adjudicate prior product-level `speck-larp` evidence for every job: UI personas use cross-epic cold start with no dev shortcuts; nonvisual/API jobs use a clean client and the evidence-contract's operational scenario.
6. Cross-platform coherence per evidence-contract.
7. No dead ends: every feature has back-nav; every action has feedback; no scaffolding in prod UI.
8. Banned-phrase self-check on report.
9. SHA-stamp; trigger `project-state`; re-stamp truth artifacts with fresh `verified` date.

## 4. Four axes

- CORRECT: epic rollup, PRD coverage, tests, and gate liveness.
- ON-CONTRACT: product and evidence contracts.
- FELT-GOOD: prior naive-hostile UI judgment for consumer UX-RC+; not applicable to a nonvisual API-RC claim.
- TASTE: prior connoisseur UI judgment for consumer UX-RC+; not applicable to a nonvisual API-RC claim.

The product job result is distinct: UI uses DOES-IT-WORK plus FELT/TASTE/legibility; nonvisual/API uses the end-to-end operational verdict. Neither is produced during validation.

## 9. Rollup validation

- Project vision vs `project.md`; PRD requirements; epic integration; quality gates.
- Aggregate Cursor rules compliance from epic reports.
- Full test suite; integration scenarios; perf benchmarks; security/accessibility scans.
- Success metrics from `project.md` — target vs actual.

Parallel subagents when host supports; else sequential.
