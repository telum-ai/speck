# Speck v10-v11 behavioral tournament

Run: `2026-08-11-v11-release-27b5c0f-terra`
Subjects: `gpt-5.6-terra` at `medium` reasoning, identical prompts, isolated workspaces
Revisions: v10 `51dbbb1f7b037cf0b5a12ccc9cd8846744f4f1f6` · v11 `27b5c0f6bbcb421a91e6e6e31fd2e8a890d43fea`
Blinded judge: `cursor-grok-4.5-high` (complete)

## Verdict

Predeclared classification: **inconclusive**. The primary hidden-check score changed by **-4.7 points** in v11 (paired bootstrap 95% CI -13.3 to 2.2). V11 won/tied/lost 1/9/2 cases; two-sided sign-test p=1.0000. False greens were 0 for v10 and 0 for v11.

Controlled performance aggregates use 12 pair-valid cases; 0 pair(s) with an invalid or methodology-contaminated subject remain visible below but are excluded from quality, judge, correction, token, and wall-time aggregates. Validity and artifact-change counters still cover every subject.

The predeclared 70% deterministic + 30% blinded-judge score was 91.9 for v10 and 91.5 for v11, a -0.4-point change (95% CI -7.9 to 5.1). The observed quality multiplier is **1.00x**, so this tournament does not support a literal “300% better” claim.


## Frozen-artifact rescore

Frozen subject artifacts and raw transcripts were rescored after
mutation-tested evaluator corrections. The scorer recognizes canonical
`lifecycle_state`, `Draft (Placeholder)`, multiline WHEN → THEN SHALL criteria,
zero-open summaries, non-bypass principal wording, verified-readiness precedence
over quoted inherited claims, missing image-path classifications, and the full
browser interaction from pending mount through selection and approval. Transcript
conformance recognizes discrete commands inside multi-line shell calls and
requires non-stamp gates after the latest truth stamp. Subjects, token counts,
and event streams were not rerun; the blind judge was generated only after the
pre-judge corrections.

Rescore evaluator: `332e168f30ffac35aac22bf97264b3d2a485e034`
(`63dc4bc3c14980e82757e81d23b950b212216ace476535d75e25b970bbc36385`).


## Paired results

| Case | Included | v10 hidden | v11 hidden | v10 judge | v11 judge | v10 corrections | v11 corrections | v10 input tokens | v11 input tokens |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| project-specify | yes | 87.0 | 100.0 | 76 | 86 | 1 | 0 | 822625 | 1378026 |
| project-plan | yes | 100.0 | 100.0 | 87 | 87 | 0 | 0 | 1358955 | 550317 |
| epic-breakdown | yes | 100.0 | 70.0 | 34 | 83 | 0 | 1 | 809233 | 706856 |
| story-specify | yes | 100.0 | 100.0 | 86 | 70 | 0 | 0 | 669152 | 484416 |
| story-plan | yes | 100.0 | 100.0 | 86 | 91 | 0 | 0 | 648060 | 347195 |
| story-tasks | yes | 100.0 | 100.0 | 76 | 88 | 0 | 0 | 1089528 | 506133 |
| implement-backend | yes | 100.0 | 100.0 | 84 | 92 | 0 | 0 | 1085094 | 1052875 |
| implement-ui | yes | 100.0 | 60.0 | 91 | 66 | 0 | 4 | 514181 | 660989 |
| audit-defects | yes | 100.0 | 100.0 | 52 | 88 | 0 | 0 | 708883 | 845342 |
| validate-fake-green | yes | 100.0 | 100.0 | 86 | 90 | 0 | 0 | 1342161 | 1107020 |
| validate-unreachable | yes | 100.0 | 100.0 | 76 | 91 | 0 | 0 | 1781770 | 1390340 |
| evidence-contract | yes | 100.0 | 100.0 | 71 | 90 | 0 | 0 | 1584990 | 1443867 |

## Aggregate endpoints

| Endpoint | v10 | v11 | Change |
|---|---:|---:|---:|
| Hidden-check quality / 100 | 98.9 | 94.2 | -4.7 points |
| Blinded judge / 100 | 75.4 | 85.2 | 9.8 |
| False greens | 0 | 0 | +0 |
| Required corrections | 1 | 5 | +4 |
| Mean input tokens | 1034553 | 872781 | -15.6% |
| Mean cached input tokens | 934315 | 804288 | -13.9% |
| Mean uncached input tokens | 100238 | 68493 | -31.7% |
| Mean wall time | 269.1s | 210.2s | -21.9% |
| Experimentally valid subjects | 12/12 | 12/12 | +0 |
| Artifacts changed | 12/12 | 12/12 | +0 |


## JIT context conformance

Executable profiles applied to 8 experimentally valid v11 subject runs; 8/8 passed all applicable axes. 0 methodology-contaminated or otherwise invalid run(s) were excluded from this rate.

| Axis | Passing / checked |
|---|---:|
| REACH | 8/8 |
| SELECTIVITY | 8/8 |
| TIMING | 8/8 |
| GATE_USE | 8/8 |

This is a leading process signal only. It does not raise hidden-check or blind-judge quality scores.


## Interpretation boundary

This is a paired behavioral benchmark, not a proof over every model, host, repository, or long-running product. It isolates the methodology revision while holding the subject model, effort, tasks, and prompts fixed. The original deterministic checks were authored before subjects ran; disclosed post-run evaluator corrections were mutation-tested and applied only to frozen outputs. The quality judge saw anonymous A/B artifacts, not version labels. 12 included pairs can expose regressions and estimate direction; they cannot justify a universal 300% claim by themselves.

Raw subject event streams and workspaces remain ignored under `.runs/`. Checked-in evidence contains every subject result, patch, final response, judge verdict, and this aggregate report. Event hashes in subject JSON bind those files to the raw streams.
