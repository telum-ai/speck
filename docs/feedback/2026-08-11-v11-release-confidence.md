# v11 release confidence

**Date**: 2026-08-11
**PR**: #127
**Methodology candidate**: `27b5c0f6bbcb421a91e6e6e31fd2e8a890d43fea`

## Conclusion

The branch is ready to be treated as a v11 release candidate. Confidence is high that it materially improves context efficiency, routing observability, and fail-closed methodology adherence. Confidence is moderate, not high, that it improves average delivered quality across models and real projects.

No 300% claim is supported. The controlled tournament observed a 1.00x composite quality ratio.

## Evidence assembled

The release argument now has four independent layers:

1. Static conservation and mutation tests protect load-bearing obligations, trusted evaluators, canonical routing, and retired-doctrine absences.
2. Post-hoc transcript validation checks whether the correct context was reached, selected, loaded before mutation, and actually used by an exit-bound gate.
3. Real-project canaries exercise entry precedence against Streb, Odd, and Speilet snapshots. Live graph P1s and migration markers outranked stale project-state prose and ordinary Next actions.
4. A paired behavioral tournament compares frozen v10 and v11 revisions across 12 project, epic, story, implementation, audit, and validation tasks.

The final tournament contains 24/24 valid subject runs. Applicable v11 transcripts passed all four JIT axes in 8/8 runs. V11 reduced mean input tokens by 15.6%, uncached input tokens by 31.7%, and wall time by 21.9%.

Outcome quality is mixed but legible. The hidden scorer changed by -4.7 points; the decorrelated blinded judge changed by +9.8; the predeclared 70/30 composite changed by -0.4 with a confidence interval crossing zero. Both versions recorded zero designated false greens. V11 required five corrections versus one for v10.

## Why this is enough for a release candidate

V11's primary intervention is architectural: move procedural detail out of always-loaded context while preserving the canonical flow and essential gates. The experiment directly confirms the intended mechanism. Agents loaded the required branches at the required times, closure gates were traceable to their own exits, and context cost fell materially.

The quality evidence does not show a broad collapse. The independent judge materially preferred v11, especially for adversarial audit and epic decomposition judgment, while the deterministic losses identify two concrete risks: completeness in epic breakdown and failure to wire a UI helper into the browser entry path. The latter was initially hidden by the scorer; the evaluator now requires the page to load its script, exercises every item through select and deselect before and after remount, proves full-batch and partial approvals, and mutation-tests disconnected, truncated, stale, and counter-facade implementations.

Adding more general prose to `story-implement` from this single miss would duplicate its existing requirements to implement every affected surface and run a runtime smoke test. That would be benchmark overfitting and reverse the subtraction goal. The correct response is the evaluator correction plus broader replication.

## Confidence limits and next proof

To move from release-candidate confidence to a strong universal quality claim:

- Repeat the same frozen comparison with a second subject model or host family.
- Run a multi-story longitudinal trial in a real project and score spec-to-runtime closure, not only isolated artifacts.
- Add end-to-end entry-path probes to future implementation cases before subjects run.
- Keep a blinded external judge, but use a second judge family or adjudicate material disagreements.
- Require every post-run scorer correction to have a turning-red mutant and its own committed revision/hash, as this run now does.

The release should be described plainly: v11 is substantially leaner, cheaper, and more inspectable; it preserves overall quality in this test and shows promising judgment gains, but a general quality increase still needs replication.

## Receipts

- Final report: `tests/eval/behavioral/reports/2026-08-11-v11-release-27b5c0f-terra/report.md`
- Release decision: `tests/eval/behavioral/reports/2026-08-11-v11-release-27b5c0f-terra/decision.md`
- Rescore evaluator: `332e168f30ffac35aac22bf97264b3d2a485e034` / `63dc4bc3c14980e82757e81d23b950b212216ace476535d75e25b970bbc36385`
- Decorrelated evaluator audit: `cursor-grok-4.5-high` PASS on the exact rescore revision; no reproducible P0/P1 false-green or evidence-integrity defect
- Focused story-closure audit target: `27b5c0f6bbcb421a91e6e6e31fd2e8a890d43fea`
