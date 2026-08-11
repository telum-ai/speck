# Speck v10-v11 behavioral tournament

Run: `2026-08-10-v10-v11-terra-isolated`
Subjects: `gpt-5.6-terra` at `medium` reasoning, identical prompts, isolated workspaces
Revisions: v10 `51dbbb1f7b037cf0b5a12ccc9cd8846744f4f1f6` · v11 `8ff081f1436024e5315fd68a3c2af505bd09ab83`
Blinded judge: `cursor-grok-4.5-high` (complete)

## Verdict

Predeclared classification: **inconclusive**. The primary hidden-check score changed by **-2.7 points** in v11 (paired bootstrap 95% CI -7.1 to 1.2). V11 won/tied/lost 1/8/3 cases; two-sided sign-test p=0.6250. False greens were 0 for v10 and 0 for v11.

The predeclared 70% deterministic + 30% blinded-judge score was 88.8 for v10 and 85.5 for v11, a -3.3-point change (95% CI -7.2 to 0.6). The observed quality multiplier is **0.96x**, so this tournament does not support a literal “300% better” claim.


## Scorer isolation correction

Frozen subject artifacts were rescored after document discovery was scoped to
`specs/**` and the canonical `lifecycle_state` field was recognized. Subjects,
token counts, transcripts, and blinded judge verdicts were not rerun. The
scorer self-test now seeds both methodology-fixture contamination and a real
project mutant so this correction can no longer green itself.


## Paired results

| Case | v10 hidden | v11 hidden | v10 judge | v11 judge | v10 corrections | v11 corrections | v10 input tokens | v11 input tokens |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| project-specify | 85.0 | 85.0 | 87 | 80 | 1 | 1 | 1242015 | 1094946 |
| project-plan | 100.0 | 100.0 | 88 | 84 | 0 | 0 | 814545 | 750827 |
| epic-breakdown | 90.0 | 90.0 | 85 | 42 | 1 | 1 | 1176888 | 328844 |
| story-specify | 65.0 | 65.0 | 82 | 73 | 2 | 2 | 626211 | 636077 |
| story-plan | 100.0 | 100.0 | 88 | 86 | 0 | 0 | 1272437 | 846837 |
| story-tasks | 100.0 | 100.0 | 80 | 85 | 0 | 0 | 798871 | 863960 |
| implement-backend | 100.0 | 100.0 | 74 | 90 | 0 | 0 | 2372783 | 795713 |
| implement-ui | 100.0 | 87.5 | 83 | 72 | 0 | 1 | 2066647 | 750085 |
| audit-defects | 100.0 | 100.0 | 91 | 91 | 0 | 0 | 1370059 | 625482 |
| validate-fake-green | 70.0 | 80.0 | 86 | 90 | 2 | 1 | 1128544 | 446024 |
| validate-unreachable | 100.0 | 85.0 | 78 | 89 | 0 | 1 | 2250278 | 778466 |
| evidence-contract | 80.0 | 65.0 | 88 | 72 | 1 | 2 | 1832604 | 1953356 |

## Aggregate endpoints

| Endpoint | v10 | v11 | Change |
|---|---:|---:|---:|
| Hidden-check quality / 100 | 90.8 | 88.1 | -2.7 points |
| Blinded judge / 100 | 84.2 | 79.5 | -4.7 |
| False greens | 0 | 0 | +0 |
| Required corrections | 7 | 9 | +2 |
| Mean input tokens | 1412657 | 822551 | -41.8% |
| Mean cached input tokens | 1311381 | 755285 | -42.4% |
| Mean uncached input tokens | 101276 | 67266 | -33.6% |
| Mean wall time | 306.4s | 237.4s | -22.5% |
| Valid subject runs | 12/12 | 12/12 | +0 |



## Interpretation boundary

This is a paired behavioral benchmark, not a proof over every model, host, repository, or long-running product. It isolates the methodology revision while holding the subject model, effort, tasks, prompts, and scorer fixed. Deterministic checks were authored before subjects ran and mutation-tested. The quality judge saw anonymous A/B artifacts, not version labels. Twelve pairs can expose regressions and estimate direction; they cannot justify a universal 300% claim by themselves.

Raw subject event streams and workspaces remain ignored under `.runs/`. Checked-in evidence contains every subject result, patch, final response, judge verdict, and this aggregate report. Event hashes in subject JSON bind those files to the raw streams.
