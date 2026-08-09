# project-validate / gate-liveness

## 2. Readiness states

Same taxonomy: `NO-SHIP` → `SHIP`.
Project MAX claimable = MIN(epic verified states, coverage-matrix cap, gate-liveness cap, recheck drift cap).

## 4. Four axes (project rollup)

| Axis | Project validate |
|------|------------------|
| CORRECT | Epic rollup, PRD coverage, tests, gate-liveness |
| ON-CONTRACT | product-contract + evidence-contract |
| FELT-GOOD | Persona JTBD LARPs + legibility check |
| TASTE | Connoisseur coverage across flagship surfaces |

LARP: **DOES-IT-WORK** = cross-epic JTBD smoke per persona; **IS-IT-GOOD** = FELT + TASTE + legibility.

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

## NEVER / ALWAYS

- NEVER claim SHIP-RC with all epics green but BLOCKED product JTBD
- NEVER skip fresh `/recheck`
- NEVER bypass gate-liveness at COMMERCIAL-RC/SHIP-RC
- NEVER substitute epic composition for product-level smoke
- NEVER ignore LEGIBILITY.P1 for commercial ship
- ALWAYS MIN(epic states) for project ceiling
- ALWAYS test cross-epic dependency arrows
- ALWAYS SHA-stamp reports
