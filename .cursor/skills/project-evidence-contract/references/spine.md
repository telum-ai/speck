# project-evidence-contract / spine

1. Read `.speck/templates/project/evidence-contract-template.md`. Locate project; require `project.md` and `product-contract.md` at Build/Platform.
2. Read in parallel: product contract (promise/MM/AI behavior), context, architecture, active recipe evidence defaults, target platforms, and production distribution shape.
3. For each target platform, run skeptical review over at least three materially different valid/invalid proof framings. Lock the one tied to the paid promise and runtime substrate; log the decision.
4. Name production-like proof per platform. Dev-server, mock-only, source inspection, and unadjudicated screenshots are invalid whenever they cannot observe the claim.
5. Enumerate each external service and interaction boundary. State what proves real acceptance, persistence, authorization, billing, failure posture, and observability.
6. Define persona LARP scope for UI products or integration/stress scenarios for backend products. Every magic moment and paid path gets a reachable proof mechanism.
7. Fill readiness criteria from NO-SHIP through SHIP. Every state names required artifacts and blockers; paid products require COMMERCIAL-RC.
8. Customize the standard adversarial probes without treating the probe list as done. Require negative controls and evidence storage paths.
9. Enforce boundaries: product-contract owns the promise; evidence-contract owns proof; AGENTS owns workspace process. Do not duplicate or contradict them.
10. Write `evidence-contract.md`; run applicable strict template/gate validators; apply `.speck/scripts/stamp-truth.sh`.
11. Regenerate `/project-state`. Report platform, valid/invalid proof, readiness, persona/scenario, and probe counts.

Never allow one source to be both valid and invalid. Never permit a readiness claim without its criteria or a claim without an observable mechanism.
