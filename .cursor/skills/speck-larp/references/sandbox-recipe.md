# speck-larp / reachability unlock

Use only after the real persona route is blocked by auth/data/external services.

1. Reproduce and log the actual recipe failure first; an asserted blocker does not license a cap.
2. Prefer a throwaway/local datastore seeded with minimal persona fixtures.
3. Use a test-only loopback session route or environment flag that cannot ship enabled. Record the guard.
4. Inject local session cookies/tokens only to unlock the UI route; do not bypass the product action being evaluated.
5. Mock third-party transport only when the evidence contract permits it for this readiness state; keep request/response shape real.
6. Re-run the same persona step. If still blocked, record the exact error and return the contract-defined cap or NO-SHIP.
