# Speck v10-v11 behavioral tournament

Run: `2026-08-10-v10-v11-jit-quality-rework`
Subjects: `gpt-5.6-terra` at `medium` reasoning, identical prompts, isolated workspaces
Revisions: v10 `51dbbb1f7b037cf0b5a12ccc9cd8846744f4f1f6` · v11 `a3c3cacb97e4bbba0113a699082e5fc1ab7a65ac`
Blinded judge: `cursor-grok-4.5-high` (complete)

## Verdict

Predeclared classification: **invalid run**. The primary hidden-check score changed by **14.1 points** in v11 (paired bootstrap 95% CI 0.0 to 34.1). V11 won/tied/lost 3/8/0 cases; two-sided sign-test p=0.2500. False greens were 0 for v10 and 0 for v11.

Controlled performance aggregates use 11 pair-valid cases; 1 pair(s) with an invalid or methodology-contaminated subject remain visible below but are excluded from quality, judge, correction, token, and wall-time aggregates. Validity and artifact-change counters still cover every subject.

The predeclared 70% deterministic + 30% blinded-judge score was 77.4 for v10 and 91.9 for v11, a 14.5-point change (95% CI 2.3 to 32.3). The observed quality multiplier is **1.19x**, so this tournament does not support a literal “300% better” claim.


## Frozen-artifact rescore

Frozen subject artifacts and raw transcripts were rescored after
mutation-tested evaluator corrections. The scorer recognizes canonical
`lifecycle_state`, `Draft (Placeholder)`, multiline WHEN → THEN SHALL criteria,
zero-open summaries, non-bypass principal wording, verified-readiness precedence
over quoted inherited claims, and missing image-path classifications. Transcript
conformance recognizes discrete commands inside multi-line shell calls and
requires non-stamp gates after the latest truth stamp. Subjects, token counts,
and event streams were not rerun; the blind judge was generated only after the
pre-judge corrections.


## Paired results

| Case | Included | v10 hidden | v11 hidden | v10 judge | v11 judge | v10 corrections | v11 corrections | v10 input tokens | v11 input tokens |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| project-specify | yes | 85.0 | 85.0 | 88 | 73 | 1 | 1 | 1076619 | 1229003 |
| project-plan | yes | 100.0 | 100.0 | 86 | 80 | 0 | 0 | 939611 | 585976 |
| epic-breakdown | yes | 100.0 | 100.0 | 28 | 90 | 0 | 0 | 888565 | 495709 |
| story-specify | yes | 65.0 | 100.0 | 71 | 80 | 2 | 0 | 907958 | 774190 |
| story-plan | yes | 100.0 | 100.0 | 78 | 88 | 0 | 0 | 1016464 | 354213 |
| story-tasks | yes | 100.0 | 100.0 | 74 | 86 | 0 | 0 | 1031675 | 695513 |
| implement-backend | yes | 100.0 | 100.0 | 64 | 86 | 0 | 0 | 1384555 | 701010 |
| implement-ui | yes | 0.0 | 100.0 | 18 | 91 | 8 | 0 | 176757 | 931083 |
| audit-defects | no | 100.0 | 100.0 | 89 | 90 | 0 | 0 | 1208731 | 683315 |
| validate-fake-green | yes | 80.0 | 80.0 | 91 | 68 | 1 | 1 | 1141027 | 809460 |
| validate-unreachable | yes | 65.0 | 85.0 | 73 | 90 | 2 | 1 | 1275740 | 981083 |
| evidence-contract | yes | 100.0 | 100.0 | 79 | 88 | 0 | 0 | 2018275 | 719145 |

## Aggregate endpoints

| Endpoint | v10 | v11 | Change |
|---|---:|---:|---:|
| Hidden-check quality / 100 | 81.4 | 95.5 | 14.1 points |
| Blinded judge / 100 | 68.2 | 83.6 | 15.5 |
| False greens | 0 | 0 | +0 |
| Required corrections | 14 | 3 | -11 |
| Mean input tokens | 1077931 | 752399 | -30.2% |
| Mean cached input tokens | 989603 | 687872 | -30.5% |
| Mean uncached input tokens | 88329 | 64527 | -26.9% |
| Mean wall time | 264.5s | 218.4s | -17.4% |
| Experimentally valid subjects | 11/12 | 12/12 | +1 |
| Artifacts changed | 11/12 | 12/12 | +1 |


## JIT context conformance

Executable profiles applied to 8 experimentally valid v11 subject runs; 1/8 passed all applicable axes. 0 methodology-contaminated or otherwise invalid run(s) were excluded from this rate.

| Axis | Passing / checked |
|---|---:|
| REACH | 8/8 |
| SELECTIVITY | 8/8 |
| TIMING | 8/8 |
| GATE_USE | 1/8 |

This is a leading process signal only. It does not raise hidden-check or blind-judge quality scores.


## Interpretation boundary

This is a paired behavioral benchmark, not a proof over every model, host, repository, or long-running product. It isolates the methodology revision while holding the subject model, effort, tasks, and prompts fixed. The original deterministic checks were authored before subjects ran; disclosed post-run evaluator corrections were mutation-tested and applied only to frozen outputs. The quality judge saw anonymous A/B artifacts, not version labels. 11 included pairs can expose regressions and estimate direction; they cannot justify a universal 300% claim by themselves.

Raw subject event streams and workspaces remain ignored under `.runs/`. Checked-in evidence contains every subject result, patch, final response, judge verdict, and this aggregate report. Event hashes in subject JSON bind those files to the raw streams.
