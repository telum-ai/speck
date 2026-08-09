# A1-lite scorecard

Generated: 2026-08-09T16:45:17Z

| Fixture | Class | Expect | Result |
|---------|-------|--------|--------|
| bl-clean | banned-language | clean-pass | MISS |
| bl-leak | banned-language | catch | CATCH |
| fe-missing-path | fabricated-evidence | catch | CATCH |
| fe-real-path | fabricated-evidence | clean-pass | MISS |
| fg-clean-adjudicated | fake-green | clean-pass | MISS |
| fg-unjudged-screenshot | fake-green | catch | CATCH |
| pp-discharged | phantom-promise | clean-pass | MISS |
| pp-open-prm | phantom-promise | catch | CATCH |
| sa-same-agent | self-audit | catch | CATCH |
| sa-separate-auditor | self-audit | clean-pass | MISS |
| ue-logged-attempt | unreachable-excuse | clean-pass | MISS |
| ue-named-blocker | unreachable-excuse | catch | CATCH |

## Summary

- fixtures: 12
- correct: 12
- incorrect: 0
- rate_pct: 100.0

Measured-win rule: new always-on/gate needs defect-catch↑ and false-green not↑, or equal retirement, or spine ADR (`docs/decisions/`).
