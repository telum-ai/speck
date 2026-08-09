# Gate codes

| Code | When |
|------|------|
| `UNANALYZED_CORPUS.P1` | Gate applies; no report |
| `ANALYSIS_STALE.P1` | Corpus commit after report |
| `ANALYSIS_CRITICAL_OPEN.P1` | CRITICAL open |
| `PROMISE_UNCOVERED.P1` | MM/JOB missing or unresolved in matrix |
| `ANALYSIS_DECORRELATION_UNVERIFIED.P2` | Too few lenses, or Verifier == Lens on CRITICAL/HIGH |
| `ANALYSIS_COVERAGE_UNCOMPUTED.P2` | Graph unread |
| `ANALYSIS_GRANDFATHERED.P2` | Pre-v10.3 marker present |

Decorrelation check is structural (roster width + distinct verifier names). High stakes: real subagents + verify Skill invocations.
