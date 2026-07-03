---
name: speck-audit
description: Adversarial skeptical audit inserted between /story-implement (or /epic-implement) and /story-validate (or /epic-validate). The auditor does NOT trust the implementer's report. For each acceptance criterion it asks "what's the negative case? has it been observed? what evidence proves it works?" Runs adversarial probes (malformed input, oversized payload, dep failure, concurrency, N+1, env vars, observability reach) per evidence-contract.md. Required for every epic close in Speck v7 — replaces the v6 /story-analyze step. Load when implementation just finished, when user says "audit this", "are we sure?", "what's missing", or before any validate gate.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

---

## Purpose

`/audit` is the skeptical pass that catches what the implementer missed. From Splang's retro:

> Every "ship" doc I wrote was honest about what I'd done — but silent about what I hadn't checked. The methodology failure isn't that the specs were bad. It's that Speck's notion of "done" was satisfiable by tests passing, screenshots looking good, and commit messages reading nicely — none of which are reality checks.

The auditor:
- Does NOT trust the implementer's self-report
- For each acceptance criterion, asks: negative case? evidence? regression guard?
- Auto-runs the adversarial probe suite per `evidence-contract.md`
- Flags banned-phrases in implementation summaries
- Produces a findings report that blocks validate-claim-of-PASS until resolved

This step is **mandatory** between implement and validate. Replaces the v6 `/story-analyze` skill.

**P4 — the auditor is the structural adversary**: a separate role judged by *defects found*, not by declaring green. Every probe here prompts the search; none of them defines "done." **P2** — every claim under audit must resolve to a mechanism: a fired endpoint, a written row, a real forbidden op attempted as a real principal — not the implementer's word, not a green-looking suite.

## When to Run

| Trigger | What to do |
|---------|------------|
| `/story-implement` just completed | Run `/audit` for that story |
| All stories in an epic are validated | Run `/audit` for the epic (cross-story coverage check) |
| User says "audit" / "are we sure" / "what's missing" | Run for current context |
| Before `/recheck` proceeds to LARP cold-start | Run audit to surface known issues first |
| Banned-phrase detected in implementer's summary | Auto-trigger |

## Prerequisites

For a story audit: `spec.md`, `plan.md`, `tasks.md` exist; implementation done; `evidence-contract.md` exists.
For an epic audit: all stories in epic have completed `/audit` + `/story-validate`.

## Execution Steps

### 1. Locate target

If `--story <id>`: audit that story.
If `--epic <id>`: audit that epic.
Default: audit the active story.

### 1b. Multi-Lens/N-Skeptic Audit for High-Risk Stories (Default for P0/P1/Privacy)

For any story/epic classified as high-risk (P0/P1 severity, or those handling sensitive user data, privacy, or security-critical authentication/billing flows), a single auditor is highly prone to confirmation bias. Therefore, **N-independent diverse-lens auditors (majority-refute)** is the default:
1. **Deploy 3+ distinct auditor subagents** (or run 3+ separate sequential passes with distinct persona lenses):
   - **Security/Privacy Lens**: Focuses on access control, data leakages, sanitization, token exposure, and compliance.
   - **Performance/Scalability Lens**: Focuses on N+1 queries, memory leaks, unpaged lists, and database indexing.
   - **UX/Accessibility Lens**: Focuses on form validation, keyboard trap, screen readers, and rendering gotchas.
2. **Consensus & Majority-Refute**:
   - If *any* auditor lens raises a P0 finding, the audit is blocked.
   - If there is a disagreement on a P1 finding, a majority-refute rule applies (if 2 out of 3 lenses agree it is a violation, it is treated as a P1 finding).
3. **Log the Lenses**: The final `audit-report.md` MUST explicitly list the lenses deployed under a `## 👥 Multi-Lens Audit Team` section.

### 2. Load context (parallel)

```
├── [Parallel] speck-explorer: Read spec.md, plan.md, tasks.md
├── [Parallel] speck-explorer: Read evidence-contract.md
├── [Parallel] speck-explorer: Read product-contract.md
├── [Parallel] speck-explorer: List changed files
└── [Parallel] speck-explorer: Read implementer's commit messages
```

### 3. Spec-to-implementation traceability check

For each acceptance criterion / FR in spec.md:
- Find supporting code
- Find supporting test
- Verify test asserts BEHAVIOR, not current (buggy) state
- Flag `expect().toBe(<wrong>)` + "BUG/TODO/should be/fix later" comments
- Flag `test.skip` without reason

### 4. Adversarial probe suite (parallel subagents)

Per evidence-contract.md. Standard 10 probes (see claude skill for full list). Each subagent runs probe + verifies response.

### 5. Failure-mode-handling check

For each external dep, verify implementation handles its failure mode per spec's `failure_modes_handled` section.

### 6. Cascade-on-write check (DB)

For each DB write path, list related tables per spec's `related_tables` section, verify cascade/anonymize behavior.

### 6b. Exhaustive reader/writer sweep (security/privacy epics, #76.4)

For any epic whose gate protects a sensitive/regulated resource (privacy, leakage, tenant isolation): **never trust a documented "single injection point" or a seam-local comment.** Enumerate EVERY reader and writer of the sensitive model across the WHOLE codebase (not just the documented seam) before trusting the gate design. A documented seam reflects one author's local view; real leak surfaces recur across reader families *outside* the primary module (e.g. a greeting/memory service reading the resource with only a GDPR guard). Run this as a fan-out over all references — a seam-local gate over an incomplete reader inventory ships a privacy hole. (`/epic-plan` should do this pre-impl; `/audit` re-sweeps post-impl — the re-sweep is what actually catches residual risk.)

### 7. Quality patterns scan

N+1 queries, unpaged lists, type coverage, env-var validation, observability reach.

### 8. Banned-phrase detection in implementer summary

Search commit messages + handoff notes for banned phrases. If found, require enumeration.

### 9. Test pollution check (story-level AND epic-level, #77.1)

Run the test suite twice — default order AND random order (e.g. Vitest `--sequence.shuffle`, pytest `-p randomly`). Results differ → **P0 test-isolation finding**. **This is mandatory at the STORY audit, not only the epic audit** — a single leaky harness silently poisons every downstream story that shares it, and order-dependence stays invisible (every story green in default order) until it compounds at epic close.

Common root cause to grep for: a `beforeEach` using `mockClear()` (clears call history but NOT a persistent `mockResolvedValue` / `mockResolvedValueOnce` queue) instead of `mockReset()` — one test's mock override leaks into a sibling under shuffle and flips a branch assertion. Optional stronger signal: the mutation sanity check in step 9d.

### 9b. Async teardown / late callback mock validation

For any story involving async resources (WebSockets, timers, subscriptions, auto-retrying dependencies, closeable connections):

1. **Verify mock behavior**: Check if unit/integration test mocks synchronously and immediately mark resources closed/disposed, or if they accurately model real async callback latency (e.g. firing close callbacks asynchronously).
2. **Scan for teardown bugs**: Look at implementation teardowns / cleanup hooks (`useEffect` cleanups, `.close()`, `.destroy()`, `clearInterval`) to verify no background work, retries, or queued timers are scheduled *after* the close call.
3. **Verify late callback regression tests**: If a fix for a late-firing callback or background re-scheduling exists, assert that the regression test explicitly *simulates* the late callback firing on a closed dependency (rather than just checking synchronous closed state).
4. Any mock found to be over-simplifying async close behavior or failing to model late events/retries → **P1 finding** ("incomplete async mock — hides post-teardown execution bugs").

### 9c. Boundary-crossing try-catch error attribution check

For any user-facing or logged error raised in a block (like a `try-catch`) that spans **two or more trust boundaries** (e.g., calling a third-party SDK like Stytch/Clerk, AND making an internal API/backend sync call, or database operations + external webhooks):

1. **Verify specific error handling**: Assert that the `catch` block does not use a lazy, catch-all error message that incorrectly attributes failure to the wrong boundary (e.g., assuming any failure is "wrong code" or "invalid OTP" when in fact the backend post-verify sync failed due to config or host down).
2. **Examine boundary separation**: Check that each distinct boundary has explicit, separate error classification (or typed/property checks on the caught error object) to accurately identify and log *which* specific connection or provider failed.
3. **Assert helpful feedback**: The user-facing error message or detailed debug logs must clearly distinguish network-level/config failures (such as a backend host returning a 502/HTML gateway page) from application-level validation failures (such as an expired token).
4. Any block spanning multiple boundaries with lazy, unified `catch-all` error messages or logs → **P1 finding** ("lazy error attribution — hides multi-boundary config/network failures").

### 9d. Negative-test authenticity — backend Non-Surrogate Rule (P2, #77.2)

The backend sibling of the UI Non-Surrogate Rule (step 10). For any test asserting an authz / RLS / tenant-isolation / permission guard:

1. **Real principal**: the test MUST run as a real, least-privileged authenticated principal (mint a real token/JWT carrying the relevant claim) and **actually attempt the forbidden operation** — never as a bypass-capable role (`service_role` / superuser / a connection that structurally bypasses row-level-security `WITH CHECK`), or the forbidden op "succeeds" and proves nothing.
2. **Not silently skipped**: the guard test must not sit behind a collect-time `skipIf` that removes it from the run.
3. Flag as **P1 "surrogate-proof / dead-guard test"** any negative test asserting a guard while running as a principal that structurally cannot reach it, or gated behind a silent skip — it stays green even if you delete the guard clause it claims to defend.
4. **Optional mutation sanity check**: remove the guard clause; if no test goes red, the guard is untested.

### 10. Reachability + scaffolding check (UI stories)

Navigation path, no dev shortcuts, real auth flow.

**Hard Non-Surrogate Rule**: The audit of a UI surface MUST NOT substitute API/programmatic calls for real UI interaction. If a human enters input and clicks a button, the audit (and subsequent LARPs) must exercise the real input fields and click the real UI elements. Mocking or bypassing UI forms via API client calls is strictly prohibited for UI story validation and is classified as **P0 surrogate-proof drift** if attempted.

### 10b. Rendering gotchas grep (UI stories)

If `design-system/primitives.md` exists and has a `## Rendering Gotchas` section:

1. Parse the gotchas table — extract **Grep signature** and **Canonical safe form** from each row (skip placeholder/template rows).
2. For each grep signature, run against changed UI files in the story scope (`rg` or equivalent on `.tsx`, `.jsx`, `.vue`, `.svelte`, `.css`).
3. For each match, verify the line also contains the canonical safe form (utility class, component name, or documented exception comment).
4. Raw anti-pattern without safe form → **P1 finding** ("correct code, wrong pixels — survives TDD").

Example: `bg-clip-text` without `.gradient-text-safe` (or project equivalent) on a headline.

Skip this step if no `## Rendering Gotchas` section exists (project has not registered any yet).

### 10c. Form Validation Matrix Check (UI stories)

If `ui-spec.md` exists and contains a **Form Validation Matrix**:

1. Validate that all field-level validation rules declared in the matrix are covered by interactive validation tests or real browser LARPs.
2. Confirm that invalid inputs are tested by driving the real form and asserting that the *exact* inline validation messages are rendered on their respective fields.
3. Assert that generic page-level errors (e.g. "Something went wrong") that do not mark/highlight the invalid fields are flagged as **P1 form-UX violations** ("handled but not guided").
4. Check that Submit Pending states disable all inputs and the submit CTA, and that double-submit protection is implemented (e.g., CTA disabled immediately on click).

### 10d. Pass-Count Honesty & Test Hygiene Check

To prevent test-suite inflation and "false green" theater:

1. **Grep for Tautologies**: Scan the tests in the story scope for meaningless sentinels like unconditional `expect(true).toBe(true)` environment checks used to inflate test counts. Flag these as **P2 informational-only passes**.
2. **Scan for Silent Skips**: Check for collect-time skip conditions (such as `describe.skipIf` evaluated before runtime setups) that silently skip suites without displaying execution-time skip-with-reason logs in test outputs. **A skipped standing/guarded regression suite is not a gate (#76.2)**: a leakage-probe or isolation suite `skipif`'d because CI lacks its throwaway DB reads as green with zero probes executed — worse than a failing suite (invisibly green). Verify standing/guarded suites report as RUN, not skipped, in the target CI.
3. Recommend using runtime skips (`it.skip(reason)`) or context-based skips (`beforeEach((ctx) => ctx.skip(reason))`) over static collect-time skips, so skips are clearly visible in the CI log.

### 10e. Decision-Lock Application Check

Verify that recent locked decisions (`DEC-XXXX`) from `project-decisions-log.md` are applied consistently across all referenced artifacts:

1. Scan `project-decisions-log.md` for decisions locked in the active scope or within the last 14 days.
2. If a decision specifies application or reconciliation across multiple files (e.g., "reconcile term in primitives.md, spec.md, and context.md"), verify that ALL listed files have been touched and aligned.
3. Unreconciled drift across documents listed in a locked decision → **P1 finding** ("decision-lock application drift").

### 11. Banned-language scan

Run `.speck/scripts/banned-language-lint.sh` against changed files.

Also run the product contract validator to ensure the contract itself does not self-violate any of its own banned terms:
```
bash .speck/scripts/validation/validators/validate-product-contract.sh --strict specs/projects/<PROJECT_ID>/product-contract.md
```

### 12. Compose audit report

Write to `<story-or-epic-dir>/audit-report.md` (template per claude skill).

### 13. Apply stamp + decision gate

```
.speck/scripts/stamp-truth.sh <story-or-epic-dir>/audit-report.md
```

Decision:
- P0 → BLOCKED. Validate must refuse PASS.
- P1-P3 only → NEEDS_FIXES. Surface; user choice.
- Clean → CLEAN. Validate can proceed.

### 14. Report (standard format per claude skill)

### 🚦 Continuous Feedback Capture Trigger
If any adversarial probe is skipped or false-green theater is detected, you **MUST** run `/speck-feedback` (or read `.cursor/skills/speck-feedback/SKILL.md`) to document the probe gap. Do not let workarounds go undocumented.

**Continuation (do NOT treat the report as a stop):**
- **Orchestrated / background / delegated run**: when the decision gate is CLEAN (or NEEDS_FIXES with no P0), **immediately proceed to `/story-validate` (or `/epic-validate`)** — the audit is a mid-lifecycle step, not a turn boundary. Stopping after the audit silently leaves the unit unvalidated.
- **Stop only** on a P0 finding (validate must refuse PASS) or when the user must choose how to handle P1–P3 findings in an interactive run.

## Behavior Rules

- NEVER skip the adversarial probe suite
- NEVER claim CLEAN without the random-order test rerun — at the STORY audit, not only the epic audit (#77.1)
- NEVER accept a guard/authz/RLS test that runs as a bypass-capable role or is silently skipped (P2, #77.2)
- NEVER treat a skipped standing/guarded suite as covered — verify it reported as RUN (#76.2)
- NEVER take the implementer's word — verify with evidence (a mechanism, not a self-report)
- NEVER end an orchestrated turn at the audit report when CLEAN — chain to validate
- ALWAYS apply SHA stamp
- ALWAYS write report even if CLEAN
- BLOCK validate on P0 findings

## Integration Points

- Reads: `spec.md`, `plan.md`, `tasks.md`, `evidence-contract.md`, `product-contract.md`, `design-system/primitives.md` (Rendering Gotchas), code
- Writes: `<dir>/audit-report.md`
- Invokes: `banned-language-lint.sh`, `stamp-truth.sh`
- Required before: `/story-validate`, `/epic-validate`

## Context: $ARGUMENTS
