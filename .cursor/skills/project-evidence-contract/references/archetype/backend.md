# project-evidence-contract / backend

- Use integration/stress scenarios, not persona UI LARP.
- Target API-RC/OPERATIONAL-RC where applicable; do not claim UX/FELT/TASTE axes without a human-facing surface.
- Require real applying principals for auth/RLS/tenant behavior, live write/read-back for persistence, dirty-shape migration proof, load/failure scenarios, and bounded retry/idempotency behavior.
- Each scenario names command/request, principal, substrate, negative control, expected telemetry, and checked-in artifact.
- A local production-like service may prove pre-ship integration; SHIP criteria use the deployed distribution named by the contract.
