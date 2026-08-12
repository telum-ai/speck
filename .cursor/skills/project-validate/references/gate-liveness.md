# project-validate / gate-liveness

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
