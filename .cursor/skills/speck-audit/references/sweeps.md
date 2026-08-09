# speck-audit / sweeps

## 6. Adversarial probe suite

Per `evidence-contract.md` §11. Run applicable probes; log genuine break attempts.
Dispatch parallel subagents when available. Skipped probe or false-green → run `/speck-feedback`.

## 7. Failure modes + DB cascade

- External deps: verify failure handling per spec `failure_modes_handled`.
- DB writes: verify cascade/anonymize per spec `related_tables`.

## 8. Exhaustive reader/writer sweep (security/privacy epics)

Never trust documented single injection point. Enumerate **every** reader/writer of sensitive model across whole codebase before trusting gate design.
Fan-out all references — seam-local gate over incomplete inventory ships privacy hole.

## 9. Quality patterns

N+1 queries, unpaged lists, type coverage, env-var validation, observability reach.

## 10. Test isolation + async + authz (mandatory at story audit)

**10a. Test pollution (#77.1)** — run suite default order AND random order (`vitest --sequence.shuffle`, `pytest -p randomly`). Results differ → **P0**.
Grep: `mockClear()` in `beforeEach` where `mockReset()` required.

**10b. Async teardown** — mocks must model async close/late callbacks; no post-close rescheduled work; regression tests simulate late callback on closed dep. Over-simplified mock → **P1**.

**10c. Boundary-crossing try-catch** — multi-boundary catch must classify which boundary failed; no catch-all attributing config/network to validation. Lazy attribution → **P1**.

**10d. Negative-test authenticity (#77.2)** — authz/RLS/tenant tests: real least-privileged principal, actually attempt forbidden op; no bypass role (`service_role`, superuser, RLS-bypass connection); no silent collect-time skip. Surrogate/dead-guard → **P1**. Optional: remove guard clause — no red = untested.

**10e. Pass-count honesty** — tautologies (`expect(true).toBe(true)`) → **P2**. Collect-time skips hiding suites → flag; standing/guarded suites must report RUN in CI, not skipped (#76.2).

## NEVER / ALWAYS

- NEVER skip adversarial probe suite
- NEVER claim CLEAN without random-order test rerun (story audit)
- NEVER accept guard test as bypass role or silent skip
- NEVER treat skipped standing/guarded suite as covered
- NEVER take implementer's word — verify mechanism
- NEVER end orchestrated turn at audit report when CLEAN
- ALWAYS SHA-stamp report
- ALWAYS write report even if CLEAN
- BLOCK validate on P0
