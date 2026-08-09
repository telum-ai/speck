# project-validate — procedure

Prereq: every epic ≥ `UX-RC` (or project ambition); fresh `/recheck` (<7 days).
Output: `[PROJECT_DIR]/project-validation-report.md`, `project-validation-summary.md`, `project-punch-list.md`.
Templates: `.speck/templates/project/project-validation-report-template.md`, `project-validation-summary-template.md`, `project-punch-list-template.md`, `.speck/templates/story/validation-report-template.md` (readiness taxonomy).
Verdict: readiness state + production GO/NO-GO — never PASS/FAIL alone.

## 0. Template

Read all project validation templates before writing.

## 1. Play level

Read `.speck/project.json` → `play_level` (missing = Platform).

| Level | Scope |
|-------|-------|
| Sprint | Success metric in `sprint-log.md`; if hit → `/project-promote`. Stop here. |
| Build | PRD, epic completion, product-contract, readiness gates. Skip constitution + design-system coverage. |
| Platform | Full flow below. |

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

## 6. JTBD smoke test (required centerpiece)

1. Primary JTBD from `project.md`.
2. Cold-start as new user — no dev headers, UUID fields, terminal/API shortcuts.
3. Record steps, dead ends, confusion.
4. Cross-epic flows: test every dependency arrow in `epics.md` (data/auth/navigation).
5. Multi-platform: core JTBD completable on each supported platform; secondary-only deferrals OK.
6. **Legibility** (5-second test): user articulates what product is, why it matters, primary CTA. Fail → `LEGIBILITY.P1`, cap below `SHIP-RC`.

| JTBD result | Project status |
|-------------|----------------|
| COMPLETE + legibility PASS | GO (if all other gates pass) |
| PARTIAL or LEGIBILITY.P1 | CONDITIONAL — cap below SHIP-RC |
| BLOCKED | NO-GO |

Report section: core journey table, cross-epic flows, platform coherence, dead ends, scaffolding remaining.

## 7. Gate liveness — hard at COMMERCIAL-RC / SHIP-RC (#88)

Wiring (proves reachability):
```bash
bash .speck/scripts/validation/validators/validate-gate-liveness.sh --strict specs/projects/<PROJECT_ID>/evidence-contract.md
```
`GATE_WIRING_DRIFT.P1` / `CI_TRUNK_EXCLUDED.P1` / `SCRIPT_UNREFERENCED.P1` / missing §6a registry → hard-block COMMERCIAL-RC/SHIP-RC. Below: enumerate-and-warn. Fix: arm gate, or `waived DEC-####` on §6a row. Seed: `seed-gate-registry.sh <recipe> --contract …`.

Canary (proves load-bearing):
```bash
bash .speck/scripts/validation/validators/gate-liveness-probe.sh --strict --require-liveness specs/projects/<PROJECT_ID>/evidence-contract.md
```
`GATE_DISARMED.P1` → hard-block COMMERCIAL-RC/SHIP-RC. `GATE_LIVENESS_UNVERIFIED.P2` → cap claimable state. Mutation in throwaway worktree only; destructive gates → `exempt:<reason>` in §6a.

## 8. Coverage matrix (breadth)

Always-on (cheap):
```bash
.speck/scripts/validation/generate-coverage-matrix.sh --level project specs/projects/<PROJECT_ID>
bash .speck/scripts/validation/validators/validate-coverage-matrix.sh specs/projects/<PROJECT_ID>
```

`--exhaustive` (opt-in, expensive): fan-out `/speck-larp <persona> --tier=torture` per cell (persona × route × {happy,error,empty,loading} × viewport × theme + input-variety on §8 AI surfaces). Deterministic `banned-language-lint.sh` across N samples; full-page axe + Lighthouse; evidence-contract §11 resilience cells. Record Job A/B/C verdict + real `larp-recordings/…` path per cell.

Breadth verdict caps (never raises) claimable state. `validate-coverage-matrix.sh --strict` before SHIP-RC when §8 declares matrix required.

## 9. Rollup validation

- Project vision vs `project.md`; PRD requirements; epic integration; quality gates.
- Aggregate Cursor rules compliance from epic reports.
- Full test suite; integration scenarios; perf benchmarks; security/accessibility scans.
- Success metrics from `project.md` — target vs actual.

Parallel subagents when host supports; else sequential.

## 10. Write outputs

1. `project-validation-report.md`
2. `project-validation-summary.md`
3. `project-punch-list.md`

Post-write axis validators (consumer UX-RC+ claims):
```bash
bash .speck/scripts/validation/validators/validate-felt-axis.sh --strict project-validation-report.md
bash .speck/scripts/validation/validators/validate-taste-axis.sh --strict project-validation-report.md
```

## 11. Commercial gates

Paid products at COMMERCIAL-RC+: billing round-trip, entitlements, legal/compliance per evidence-contract.
SHIP-RC: launch build, all gates, PROFILE clean.
SHIP: post-deploy proof.

## NEVER / ALWAYS

- NEVER claim SHIP-RC with all epics green but BLOCKED product JTBD
- NEVER skip fresh `/recheck`
- NEVER bypass gate-liveness at COMMERCIAL-RC/SHIP-RC
- NEVER substitute epic composition for product-level smoke
- NEVER ignore LEGIBILITY.P1 for commercial ship
- ALWAYS MIN(epic states) for project ceiling
- ALWAYS test cross-epic dependency arrows
- ALWAYS SHA-stamp reports
