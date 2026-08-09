---
name: speck-self-eval
description: A1-lite seeded defect scorecard. Use when measuring Speck gate fitness.
---

# Speck self-eval (A1-lite)

Runs seeded-defect fixtures against Speck gates. Use when measuring methodology fitness or before always-on expansions.

## Do

1. Run `bash .speck/eval/score.sh`
2. Read stdout + `.speck/eval/reports/latest.md`
3. For gate changes: require defect-catch↑ and false-green not↑, or equal budget retirement, or spine ADR

## Output

Scorecard with per-fixture catch/miss and summary rates.
