# Gate codes

| Code | When |
|------|------|
| `UNANALYZED_CORPUS.P1` | Gate applies; no report |
| `ANALYSIS_STALE.P1` | PRD/epics/product-contract commit after report |
| `ANALYSIS_CRITICAL_OPEN.P1` | CRITICAL open |
| `PROMISE_UNCOVERED.P1` | MM/JOB missing or unresolved |
| `ANALYSIS_DECORRELATION_UNVERIFIED.P2` | Too few lenses, or Verifier == Lens on CRITICAL/HIGH |
| `ANALYSIS_COVERAGE_UNCOMPUTED.P2` | Graph unread |
| `ANALYSIS_GRANDFATHERED.P2` | Pre-v10.3 marker — notice only |

Decorrelation is structural. High stakes: real subagents + verify Skill invocations.
