# speck-audit — procedure

Mandatory between implement and validate. Replaces v6 `/story-analyze`.
Output: `<story-or-epic-dir>/audit-report.md`.
P4: auditor ≠ implementer; judged by defects found, not green. P2: every claim resolves to a mechanism.

## 0. When to run

| Trigger | Target |
|---------|--------|
| `/story-implement` completed | That story |
| All stories validated in epic | Epic (cross-story) |
| User: audit / are we sure | Current context |
| Before `/recheck` → LARP | Current scope |
| Banned phrase in implementer summary | Auto-trigger |

## 1. Locate target + prereqs

- `--story <id>` → story dir; `--epic <id>` → epic dir; default → active story.
- Story: `spec.md`, `plan.md`, `tasks.md`, implementation done, `evidence-contract.md`.
- Epic: every story has completed `/audit` + `/story-validate`.
- STOP if prereqs missing.

## 2. Role separation (P4)

1. Auditor ≠ implementer (separate subagent / session / model).
2. High-risk default (P0/P1 severity, privacy, security-critical auth/billing): **3+ independent lens auditors** — Security/Privacy · Performance/Scalability · UX/Accessibility.
3. Any lens P0 → BLOCKED. P1 disagreement → majority-refute (2 of 3).
4. Report lists deployed lenses under `## Multi-Lens Audit Team`.

## 3. Load context (parallel)

- `spec.md`, `plan.md`, `tasks.md`, `evidence-contract.md`, `product-contract.md`
- Changed files; implementer commit messages / handoff notes

## 4. Spec-to-implementation traceability

Per AC / FR in `spec.md`:
- Supporting code + test exist
- Test asserts behavior, not buggy current state
- Flag `expect().toBe(<wrong>)`, BUG/TODO/fix-later comments
- Flag `test.skip` without reason

## 5. Promise↔Source fidelity sweep (opt-in semantic)

Run before epic close, when `--check-fidelity` WARN, or on demand.
Scope: mandatory on differentiator (product-contract §3) + magic-moment (§5) rows; widen on request.

Structural pre-pass:

```bash
bash .speck/scripts/validation/validators/validate-traceability-matrix.sh --check-fidelity specs/projects/[PROJECT_ID]/epics/[EPIC_ID]
```

Per in-scope `discharged` row: adversarial subagent gets Source clause (verbatim), row `Promise`, discharged predicate.
Verdict: `faithful` | `drift` (P2) | `contradictory` (P1 — false discharge).
Log Source, Promise, predicate location. Never auto-resolve subjective faithfulness.

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

## 11. UI stories

**11a. Reachability** — real nav path, no dev shortcuts, real auth. **Non-Surrogate Rule**: no API/programmatic substitute for UI interaction → **P0 surrogate-proof drift**.

**11b. Rendering gotchas** — if `design-system/primitives.md` has `## Rendering Gotchas`: grep each signature on changed UI files; match without canonical safe form → **P1**.

**11c. Form Validation Matrix** — if `ui-spec.md` has matrix: interactive tests/LARP assert exact inline messages; generic page error without field highlight → **P1**; submit pending disables inputs + CTA; double-submit protection.

## 12. Decision-lock application

Scan `project-decisions-log.md` for decisions locked in scope or last 14 days. Multi-file reconciliation specified but not applied → **P1** drift.

## 13. Banned language + gate liveness

```bash
bash .speck/scripts/banned-language-lint.sh <changed-files>
bash .speck/scripts/validation/validators/validate-product-contract.sh --strict specs/projects/[PROJECT_ID]/product-contract.md
bash .speck/scripts/validation/validators/validate-gate-liveness.sh --strict specs/projects/[PROJECT_ID]/evidence-contract.md
```

Opt-in canary (on-demand, throwaway worktree):

```bash
bash .speck/scripts/validation/validators/gate-liveness-probe.sh --require-liveness specs/projects/[PROJECT_ID]/evidence-contract.md
```

`GATE_DISARMED.P1` → P0-adjacent (gate green on injected defect). `GATE_LIVENESS_UNVERIFIED.P2` → cap ship claim, never blocks.

Search implementer summary for banned phrases; require enumeration if found.

## 14. Compose report + stamp

Write `<dir>/audit-report.md`. Sections: findings by severity (P0/P1/P2/P3), probe results, banned-language, multi-lens roster if used.

```bash
bash .speck/scripts/stamp-truth.sh <dir>/audit-report.md
```

## 15. Verdict + continuation

| Verdict | Condition | Next |
|---------|-----------|------|
| BLOCKED | Any P0 | Validate refuses PASS |
| NEEDS_FIXES | P1–P3 only | Surface; owner choice |
| CLEAN | No open P0 | Chain to `/story-validate` or `/epic-validate` |

Orchestrated/delegated run: on CLEAN (or NEEDS_FIXES without P0) → **immediately proceed to validate** — audit is mid-lifecycle, not turn boundary.
Stop only on P0 or when user must choose P1–P3 handling.

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
