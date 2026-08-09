# speck-reprove / caps

## The cap-and-worklist model (the core doctrine)

On engagement, the effective shippable state is **capped** — old claims do not carry over as ship-ready:

| v7 claim | v8 effective state (until re-proven) | Why |
|----------|--------------------------------------|-----|
| Any claim ≥ `UX-RC` | Capped at **`INTEGRATION-GREEN`** | UX-RC+ requires evaluation evidence (P1) that v7 green may only have verified |
| Consumer archetype **FELT-GOOD** | Reverts to **`uncovered`** | The axis most likely to be fake green (#78) — needs the naive-hostile IS-IT-GOOD pass |
| `IMPL-GREEN` / `INTEGRATION-GREEN` | Unchanged | Correctness/integration claims are the least suspect; re-verify opportunistically |

The historical claim is **preserved** in place and stamped `[pre-v8-proof]` (never overwritten to a lower number silently). It climbs back only when a real v8 evaluation lands.

## Behavior Rules

- **NEVER** carry a v7 `UX-RC`+ claim into v8 as ship-ready without a fresh v8 evaluation — cap at `INTEGRATION-GREEN` first.
- **NEVER** silently lower a historical numeric claim — preserve it and append `[pre-v8-proof]` with a capped note.
- **NEVER** re-cover consumer FELT-GOOD from correctness/conformance evidence — it requires the naive-hostile IS-IT-GOOD LARP (P1).
- **NEVER** leave the traceability matrices asserting a readiness the report cap removed — run `reconcile-matrix-grain.sh` (Phase 1.5) so matrix and report converge. Reconcile writes only the capped (`≤ integration-green [pre-v8-proof]`) grain; it never promotes a row to product grain.
- **NEVER** accept a `[pre-v8-proof]` cap justified by a "named blocker" without a logged, reproduced real attempt (P3).
- **ALWAYS** map each suspect claim to the specific principle (P1-P4) and a concrete re-prove action.
- **ALWAYS** SHA-stamp the report (v8) and remove the marker only after the worklist is tracked.
- **ALWAYS** write the report even if nothing is suspect — state "No pre-v8 claims required re-proving; project shipped clean v8 from upgrade."
