Created [evidence-contract.md](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-11-v11-release-27b5c0f-terra/workspaces/evidence-contract-A/specs/projects/001-pulseboard/evidence-contract.md).

Readiness: **NO-SHIP**. The contract makes all three promises falsifiable and defines explicit probes for missing confirmations, workspace isolation, and delivery timeout/rejection/duplicates/partial results/late callbacks. Unselected platform, persistence, and delivery-provider choices are recorded as proof blockers, not invented.

Evidence:

- `stamp-truth.sh` stamped SHA `31614a3`.
- Strict evidence-contract template validation passed.
- Citation admissibility parity passed: 6 claim rows, 10 citation types, 0 drift.
- Standard probe-library check passed: 8 declared exceptions, 0 P1/P2/P3 findings.
- `git diff --check` passed.