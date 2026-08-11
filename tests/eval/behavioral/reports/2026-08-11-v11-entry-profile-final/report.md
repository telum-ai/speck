# Speck v10-v11 behavioral tournament

Run: `2026-08-11-v11-entry-profile-final`
Subjects: `gpt-5.6-terra` at `medium` reasoning, identical prompts, isolated workspaces
Revisions: v10 `51dbbb1f7b037cf0b5a12ccc9cd8846744f4f1f6` · v11 `92a0a97b0f46c4218b3e985e5b7ce244480085df`
Blinded judge: `cursor-grok-4.5-high` (complete)

## Verdict

Predeclared classification: **inconclusive**. The primary hidden-check score changed by **0.0 points** in v11 (paired bootstrap 95% CI -5.0 to 5.0). V11 won/tied/lost 1/10/1 cases; two-sided sign-test p=1.0000. False greens were 0 for v10 and 0 for v11.

Controlled performance aggregates use 12 pair-valid cases; 0 pair(s) with an invalid or methodology-contaminated subject remain visible below but are excluded from quality, judge, correction, token, and wall-time aggregates. Validity and artifact-change counters still cover every subject.

The predeclared 70% deterministic + 30% blinded-judge score was 89.6 for v10 and 92.7 for v11, a 3.1-point change (95% CI -1.7 to 7.6). The observed quality multiplier is **1.03x**, so this tournament does not support a literal “300% better” claim.



## Paired results

| Case | Included | v10 hidden | v11 hidden | v10 judge | v11 judge | v10 corrections | v11 corrections | v10 input tokens | v11 input tokens |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| project-specify | yes | 85.0 | 85.0 | 89 | 74 | 1 | 1 | 774006 | 985565 |
| project-plan | yes | 100.0 | 100.0 | 80 | 86 | 0 | 0 | 1047307 | 397534 |
| epic-breakdown | yes | 100.0 | 100.0 | 26 | 88 | 0 | 0 | 743181 | 400667 |
| story-specify | yes | 85.0 | 65.0 | 86 | 80 | 1 | 2 | 682664 | 687767 |
| story-plan | yes | 100.0 | 100.0 | 89 | 86 | 0 | 0 | 730940 | 601466 |
| story-tasks | yes | 100.0 | 100.0 | 86 | 82 | 0 | 0 | 988920 | 757052 |
| implement-backend | yes | 100.0 | 100.0 | 70 | 88 | 0 | 0 | 1836687 | 702412 |
| implement-ui | yes | 100.0 | 100.0 | 74 | 85 | 0 | 0 | 1914730 | 1045476 |
| audit-defects | yes | 100.0 | 100.0 | 78 | 91 | 0 | 0 | 1222432 | 662144 |
| validate-fake-green | yes | 80.0 | 100.0 | 91 | 84 | 1 | 0 | 1129427 | 1085621 |
| validate-unreachable | yes | 100.0 | 100.0 | 62 | 93 | 0 | 0 | 1823565 | 1090669 |
| evidence-contract | yes | 100.0 | 100.0 | 71 | 88 | 0 | 0 | 978536 | 739508 |

## Aggregate endpoints

| Endpoint | v10 | v11 | Change |
|---|---:|---:|---:|
| Hidden-check quality / 100 | 95.8 | 95.8 | 0.0 points |
| Blinded judge / 100 | 75.2 | 85.4 | 10.2 |
| False greens | 0 | 0 | +0 |
| Required corrections | 3 | 3 | +0 |
| Mean input tokens | 1156033 | 762990 | -34.0% |
| Mean cached input tokens | 1059328 | 702400 | -33.7% |
| Mean uncached input tokens | 96705 | 60590 | -37.3% |
| Mean wall time | 325.8s | 223.5s | -31.4% |
| Experimentally valid subjects | 12/12 | 12/12 | +0 |
| Artifacts changed | 12/12 | 12/12 | +0 |


## JIT context conformance

Executable profiles applied to 8 experimentally valid v11 subject runs; 2/8 passed all applicable axes. 0 methodology-contaminated or otherwise invalid run(s) were excluded from this rate.

| Axis | Passing / checked |
|---|---:|
| REACH | 8/8 |
| SELECTIVITY | 8/8 |
| TIMING | 8/8 |
| GATE_USE | 2/8 |

This is a leading process signal only. It does not raise hidden-check or blind-judge quality scores.


## Interpretation boundary

This is a paired behavioral benchmark, not a proof over every model, host, repository, or long-running product. It isolates the methodology revision while holding the subject model, effort, tasks, and prompts fixed. The original deterministic checks were authored before subjects ran; disclosed post-run evaluator corrections were mutation-tested and applied only to frozen outputs. The quality judge saw anonymous A/B artifacts, not version labels. 12 included pairs can expose regressions and estimate direction; they cannot justify a universal 300% claim by themselves.

Raw subject event streams and workspaces remain ignored under `.runs/`. Checked-in evidence contains every subject result, patch, final response, judge verdict, and this aggregate report. Event hashes in subject JSON bind those files to the raw streams.
