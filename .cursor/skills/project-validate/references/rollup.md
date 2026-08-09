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
4. Read `/recheck` report — drift lowers max.
5. **Product JTBD smoke test** per persona (cross-epic, cold-start, no dev shortcuts).
6. Cross-platform coherence per evidence-contract.
7. No dead ends: every feature has back-nav; every action has feedback; no scaffolding in prod UI.
8. Banned-phrase self-check on report.
9. SHA-stamp; trigger `/project-state`; re-stamp truth artifacts with fresh `verified` date.

## 9. Rollup validation

- Project vision vs `project.md`; PRD requirements; epic integration; quality gates.
- Aggregate Cursor rules compliance from epic reports.
- Full test suite; integration scenarios; perf benchmarks; security/accessibility scans.
- Success metrics from `project.md` — target vs actual.

Parallel subagents when host supports; else sequential.
