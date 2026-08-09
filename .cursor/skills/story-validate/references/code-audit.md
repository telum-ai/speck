# Code audit (required)

Change surface: `git diff --name-only`, entrypoints, 1–3 call-site traces.
Checklist: correctness/edge, maintainability, security/privacy, performance, operability, a11y, test quality.
High-severity (security, data loss, broken authz, missing critical tests) → fail even if tests green.
