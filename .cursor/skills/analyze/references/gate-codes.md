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
| `FLOW_OPTIONAL_UNREVIEWED.P1` | A reached conditional slot has no Flow Fit row |
| `FLOW_OPTIONAL_MISSING.P1` | Its trigger applies but the required work is absent |
| `FLOW_REQUIRED_MISSING.P1` | The play level's mandatory foundation slot is not included |
| `FLOW_INCLUDED_PHANTOM.P1` | An included row points to no checked-in artifact |
| `ANALYSIS_SCOPE_DRIFT.P1` | Report play level or epic count disagrees with live project truth |

Decorrelation is structural: roster width plus distinct verifier names. For high-stakes work, use real independent reviewers and verify skill invocation receipts.
