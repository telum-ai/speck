# story-implement / backend

1. Read data model, contracts, migrations, operational invariants, and evidence-contract integration/stress scenarios.
2. Implement the failure path with the success path: validation, authorization, idempotency, retries/timeouts, partial failure, rollback, and observability.
3. For balances/quotas/inventory, implement symmetric re-credit/release/refund in this story.
4. Migration work: prove clean apply, dirty-shape forward apply, rollback/recovery posture, and one migration head. Never mark unapplied SQL as applied.
5. Auth/tenant tests use the real least-privileged request path; no bypass role or mocked policy substitute.
6. External integrations exercise a real sandbox/local equivalent at the interaction boundary; mocks cover unit behavior only.
7. Run contract, integration, migration, and failure-injection tests plus the project full gate. Preserve runtime evidence paths for `/audit` and `/story-validate`.
