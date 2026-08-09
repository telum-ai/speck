# speck-reprove / felt-reearn

## Execution

### Phase 0 — Triage: inventory + suspect-green classification

Inventory truth artifacts, validation reports, LARP evidence, and traceability matrices. For each existing readiness claim, classify the principle it is suspect under:

| Suspect signal | Principle | What to look for |
|----------------|-----------|------------------|
| Screenshots/recordings present but no per-screen adversarial adjudication; no DOES-IT-WORK vs IS-IT-GOOD split; FELT-GOOD asserted from correctness evidence | **P1** | `validation-report.md` / `persona-larp` with captures but no IS-IT-GOOD verdict or Common-Sense Defect Sweep |
| AI action-claim, price/paywall, or authz/RLS test with no exhibited mechanism (no fired endpoint/row/real-principal-forbidden-op; price with no value-defensibility artifact) | **P2** | claims in specs/reports and negative tests that assert a guard without attempting the forbidden op as a least-privileged principal |
| Readiness cap justified by "unreachable"/"named infra blocker"/"tooling limitation" with no logged, reproduced real attempt | **P3** | `INTEGRATION-GREEN` caps and skipped LARPs citing a blocker without the recipe run + specific error |
| Self-audited (implementer == auditor); no independent/N-skeptic audit | **P4** | `audit-report.md` authored by the implementer, or missing |

Run `.speck/scripts/staleness-check.sh <PROJECT_DIR>` to enumerate `V8_STALE` artifacts. Detect consumer archetypes from `product-contract.md` / `personas/`.

### Phase 1 — Apply the cap

For each artifact/claim:
- Where a v7 claim is ≥ `UX-RC`, set the **effective** state to `INTEGRATION-GREEN` in `project-state.md` while **preserving** the historical claim in the artifact, appended with `[pre-v8-proof]`.
- For consumer archetypes, render **FELT-GOOD → `uncovered`** in the readiness map (the AI must re-run the naive-hostile IS-IT-GOOD LARP to re-cover it — a human sign-off is an optional stronger override, never a prerequisite).
- Do NOT rewrite the numeric history to a lower value; add the `[pre-v8-proof]` marker + a one-line "capped pending v8 re-prove" note.

### Phase 1.5 — Reconcile the traceability matrices (#87)

Phase 1 caps the validation **reports**. But the traceability **matrices** in the same epic dirs still assert `discharged` at the readiness the cap removed — the two artifacts now contradict each other, and the matrix is the one people cite when asked "is it covered?". Reconcile them:

```bash
bash .speck/scripts/validation/reconcile-matrix-grain.sh specs/projects/<PROJECT_ID>
```

For every `discharged` row whose discharging story's report is pre-v8-stamped or capped, this writes the row's `Grain (proven-at)` to the **effective** (capped) state — `integration-green [pre-v8-proof]` — the same sentinel the reports carry, so matrix and report converge. It reads the effective state (the cap), never the preserved numeric; it **never** auto-promotes to product grain; it inserts the `Grain` column if the matrix is still 6/7-col; Status is untouched (conservation byte-identical); and it is idempotent. `MATRIX_GRAIN_CAP` (MIN grain over all discharged rows) then drops each epic to its honest ceiling at `/epic-validate`.

Record the reconcile counts (`regraded=… columns_added=… matrices_changed=…` from the tail line) in the report's Status block.

> Note: the `[pre-v8-proof]` sentinel lives in BOTH the report (a story-level fact) and the matrix Grain cell (a row-level fact). Genuinely different facts sharing a token — NOT a one-fact-two-homes drift violation.

### Phase 2 — Build the re-prove worklist

Map every suspect claim to its concrete re-prove action, prioritized P0→P3:

- **P1 (evaluate):** re-run `/larp` with the DOES-IT-WORK vs IS-IT-GOOD split + per-screen pixel-grounded critique + Common-Sense Defect Sweep. Cover consumer FELT-GOOD with the AI's own naive-hostile pass.
- **P2 (mechanism):** exhibit the mechanism for each claim — fired endpoint / written row / real forbidden-op attempted as a least-privileged principal / value-defensibility artifact vs the free substitute.
- **P3 (reach):** for each cap citing a blocker, run the actual recipe and either reach the control or log the reproduced failure (recipe + specific error).
- **P4 (adversary):** ensure a genuinely independent `/audit` (separate auditor) exists for anything climbing back to ≥ `UX-RC`.

### Phase 3 — Write `project-v8-reprove-report.md`

Read the template at `.speck/templates/project/project-v8-reprove-report-template.md` and follow it exactly. It captures: the suspect-green triage table, the cap applied (per artifact), the prioritized worklist mapped to P1-P4, and the climb-back criteria. SHA-stamp it (the stamp will read `speck v8.x`, clearing V8_STALE for the report itself).

### Phase 4 — Finalize

1. Regenerate `project-state.md` via `/project-state`: effective (capped) states, FELT-GOOD `uncovered` for consumer archetypes, blocking issues = the P0/P1 worklist, Next action = "Work through project-v8-reprove-report.md".
2. Remove the `.speck/.v8-reprove-needed` marker **only after** the report exists and the worklist is tracked in `project-state.md`.
3. Re-run `/recheck` to confirm no remaining `V8_STALE` beyond the tracked worklist.

## Idempotency

Safe to re-run. Artifacts already stamped `speck v8.x` and claims already re-proven are skipped; only remaining `V8_STALE` / `[pre-v8-proof]` items are processed. Removing the marker is the terminal step.
