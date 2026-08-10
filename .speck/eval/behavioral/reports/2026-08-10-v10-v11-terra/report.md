# Speck v10-v11 behavioral tournament

Run: `2026-08-10-v10-v11-terra`  
Subjects: `gpt-5.6-terra` at `medium` reasoning, identical prompts, isolated workspaces  
Revisions: v10 `51dbbb1f7b037cf0b5a12ccc9cd8846744f4f1f6` · v11 `8ff081f1436024e5315fd68a3c2af505bd09ab83`  
Blinded judge: `cursor-grok-4.5-high` (complete)

## Verdict

The primary hidden-check score changed by **1.7 points** in v11 (paired bootstrap 95% CI 0.0 to 5.0). V11 won/tied/lost 1/11/0 cases; two-sided sign-test p=1.0000. False greens were 0 for v10 and 0 for v11.

The predeclared 70% deterministic + 30% blinded-judge score was 86.6 for v10 and 86.4 for v11, a -0.1-point change (95% CI -2.0 to 2.2). The observed quality multiplier is **1.00x**, so this tournament does not support a literal “300% better” claim.

## Paired results

| Case | v10 hidden | v11 hidden | v10 judge | v11 judge | v10 corrections | v11 corrections | v10 input tokens | v11 input tokens |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| project-specify | 85.0 | 85.0 | 86 | 77 | 1 | 1 | 1048014 | 961691 |
| project-plan | 100.0 | 100.0 | 83 | 86 | 0 | 0 | 866189 | 709619 |
| epic-breakdown | 60.0 | 60.0 | 74 | 81 | 2 | 2 | 912874 | 734741 |
| story-specify | 55.0 | 55.0 | 86 | 71 | 3 | 3 | 653710 | 572179 |
| story-plan | 100.0 | 100.0 | 89 | 84 | 0 | 0 | 731879 | 548387 |
| story-tasks | 100.0 | 100.0 | 85 | 79 | 0 | 0 | 1129270 | 466403 |
| implement-backend | 100.0 | 100.0 | 89 | 86 | 0 | 0 | 1002027 | 475350 |
| implement-ui | 70.0 | 90.0 | 68 | 56 | 3 | 1 | 1860739 | 1026457 |
| audit-defects | 100.0 | 100.0 | 91 | 87 | 0 | 0 | 1306324 | 784058 |
| validate-fake-green | 100.0 | 100.0 | 88 | 85 | 0 | 0 | 1187363 | 745736 |
| validate-unreachable | 100.0 | 100.0 | 82 | 91 | 0 | 0 | 1923633 | 499514 |
| evidence-contract | 80.0 | 80.0 | 92 | 78 | 1 | 1 | 1269216 | 1568845 |

## Aggregate endpoints

| Endpoint | v10 | v11 | Change |
|---|---:|---:|---:|
| Hidden-check quality / 100 | 87.5 | 89.2 | 1.7 points |
| Blinded judge / 100 | 84.4 | 80.1 | -4.3 |
| False greens | 0 | 0 | +0 |
| Required corrections | 10 | 8 | -2 |
| Mean input tokens | 1157603 | 757748 | -34.5% |
| Mean wall time | 236.2s | 199.4s | -15.6% |
| Valid subject runs | 12/12 | 12/12 | +0 |

## Interpretation boundary

This is a paired behavioral benchmark, not a proof over every model, host, repository, or long-running product. It isolates the methodology revision while holding the subject model, effort, tasks, prompts, and scorer fixed. Deterministic checks were authored before subjects ran and mutation-tested. The quality judge saw anonymous A/B artifacts, not version labels. Twelve pairs can expose regressions and estimate direction; they cannot justify a universal 300% claim by themselves.

Raw subject event streams and workspaces remain ignored under `.runs/`. Checked-in evidence contains every subject result, patch, final response, judge verdict, and this aggregate report. Event hashes in subject JSON bind those files to the raw streams.
