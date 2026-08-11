Created the canonical [evidence contract](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/evidence-contract-B/specs/projects/001-pulseboard/evidence-contract.md).

Readiness: **NO-SHIP** — no implementation or runtime evidence exists yet.

It makes all three Pulseboard promises falsifiable and defines failure-path probes for confirmation bypass, cross-workspace access/write attempts, duplicate delivery, provider failures, ambiguous outcomes, and worker crashes.

Verified locally:

- Evidence-contract strict validator: pass, 0 errors/warnings
- Typed-citation admissibility parity: pass, 6 claim rows / 10 citation types
- Standard probe library: 8 declared classes, no undeclared or mismatched probes
- `git diff --check`: pass