# story-tasks / api-backend

1. Map data-model entities/rules and contract endpoints/schemas/errors to implementation plus contract tests.
2. Add migration tasks for clean apply, real dirty-shape forward apply, constraint/index verification, recovery posture, and migration-head reconciliation.
3. Add least-privileged auth/tenant probes using the real request path. A bypass role or mocked policy cannot discharge interaction behavior.
4. Add integration tasks at each external boundary, including timeout, retry/idempotency, duplicate delivery, partial failure, and observability.
5. Balance/quota/inventory consumption requires symmetric re-credit/release/refund tasks in this story.
6. Add evidence-producing stress/integration scenarios from `evidence-contract.md`; name the artifact each task should leave for audit/validate.
