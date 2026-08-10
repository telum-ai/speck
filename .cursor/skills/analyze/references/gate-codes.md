# Analysis gate codes

| Code | When |
|------|------|
| `UNANALYZED_CORPUS.P1` | Gate applies; no report |
| `ANALYSIS_STALE.P1` | Analyzed corpus changed after report |
| `ANALYSIS_CRITICAL_OPEN.P1` | CRITICAL remains open |
| `PROMISE_UNCOVERED.P1` | In-scope MM/JOB missing or unresolved |
| `ANALYSIS_DECORRELATION_UNVERIFIED.P2` | Too few lenses, or verifier equals lens on CRITICAL/HIGH |
| `ANALYSIS_COVERAGE_UNCOMPUTED.P2` | Witness graph unreadable |
| `ANALYSIS_GRANDFATHERED.P2` | Pre-v10.3 marker present |

Decorrelation is structural: roster width plus distinct verifier names. For high-stakes work, use real independent reviewers and verify skill invocation receipts.
