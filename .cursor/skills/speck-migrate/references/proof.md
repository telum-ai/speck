# Legacy-proof repair

Re-prove claims created before evaluation-shaped gates. This stage is additive: preserve historical claims, apply an honest effective cap, and create the work needed to climb again.

## 1. Inventory and classify

Require a project plus git history. Inventory validation reports, LARP evidence, traceability matrices, readiness claims, and `staleness-check.sh` findings. Classify each suspect claim:

- P1: screenshots or conformance without DOES-IT-WORK and IS-IT-GOOD adjudication; FELT-GOOD inferred from correctness.
- P2: action, authorization, billing, price, or value claim with no fired mechanism or forbidden-op attempt.
- P3: readiness capped by an unreachable control without a logged reproduced attempt.
- P4: implementer and auditor are the same party, or independent audit is absent.

## 2. Apply the effective cap

- Any historical claim at `UX-RC` or above is effectively capped at `INTEGRATION-GREEN` until current evaluation re-earns it.
- Consumer `FELT-GOOD` becomes `uncovered` until naive-hostile IS-IT-GOOD LARP re-evaluates it.
- Preserve the historical numeric claim in its report and append `[pre-v8-proof]` plus a one-line capped-pending-reproof note. Never silently rewrite history downward.
- Reflect the effective cap, open P0/P1 work, and next action in `project-state.md`.

## 3. Reconcile matrices

Run:

```bash
bash .speck/scripts/validation/reconcile-matrix-grain.sh specs/projects/<PROJECT_ID>
```

For discharged rows backed by capped reports, the effective grain becomes `integration-green [pre-v8-proof]`. Record `regraded`, `columns_added`, and `matrices_changed`. The reconciliation is idempotent and never promotes proof.

## 4. Build the worklist

Prioritize P0→P3 and name the exact action for every suspect claim:

- P1: current LARP with function/quality split, per-surface judgment, and common-sense defect sweep.
- P2: exhibit the real endpoint, row, least-privileged forbidden operation, or value-defensibility mechanism.
- P3: run the actual recipe and reach the control or log the specific reproduced failure.
- P4: obtain a separate `speck-audit` before any climb to `UX-RC` or higher.

## 5. Record and finish

Write `project-v8-reprove-report.md` from `.speck/templates/project/project-v8-reprove-report-template.md`. Include the inventory, per-artifact cap, matrix reconciliation counts, P1–P4 worklist, and climb criteria. Stamp it, regenerate project state, and rerun `speck-recheck`.

Delete `.speck/.v8-reprove-needed` only after the report exists and every remaining item is represented in project state. Always write the report, even when no legacy claim needs re-proving. A `[pre-v8-proof]` item or `V8_STALE` finding keeps this stage active until tracked and capped.
