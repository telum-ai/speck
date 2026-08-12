---
name: speck-self-eval
description: Scores seeded defects against Speck gates. Use only in the Speck source repo before changing methodology gates.
---

# Speck self-eval (A1-lite)

Runs seeded artifacts through the candidate-corpus gate anchors and deterministic defect evaluator. Use before changing named Speck gate capabilities. This is a contract smoke test, not runtime agent-behavior proof.

Framework-repository-only: if `tests/eval/score.sh` or its immutable baseline is absent, STOP. Do not fabricate or copy a scorecard into a product repository.

## Do

1. Run `bash tests/eval/score.sh --check` while iterating; it must exit nonzero on a harness error, wrong fixture verdict, or regression from `reports/baseline.json`.
2. Read stdout + `tests/eval/reports/latest.md`.
3. Run `bash tests/eval/score.test.sh`; require the corpus-deletion and wrong-verdict mutations to turn red.
4. After the candidate is final, run `bash tests/eval/score.sh` once to refresh `latest.md`. Never rewrite `baseline.json` as a side effect of scoring.

## Output

Fail-closed scorecard with per-fixture verdicts, harness-error count, and immutable-baseline regressions.
