---
speck_version: 8.0
template_version: "8.0.0"
artifact_type: evidence-contract
play_levels: [build, platform]
---

# Evidence Contract: [PROJECT_NAME]

<!--
THIS IS THE CENTER OF GRAVITY FOR PROVE.

The evidence-contract.md defines:
- What counts as proof for THIS product
- What does NOT count (anti-proof)
- Which readiness states require which evidence
- Where runtime evidence lives in the repo
- Who or what can mark a gate passed

Common failure modes this contract prevents: browser screenshots passed off as native-app proof,
"tests pass" treated as launch-ready, dev-server LARP treated as production-ready.

200-line target.

PLACEHOLDER CONVENTION:
  Tokens marked  REPLACE_BEFORE_SHIP: <hint>  MUST be filled before this artifact
  can claim ship-readiness. /speck-recheck greps for them. Other [bracketed]
  hints are guidance for the agent but don't gate ship.
-->

**Project**: REPLACE_BEFORE_SHIP: PROJECT_NAME
**Project ID**: `REPLACE_BEFORE_SHIP: project-id`
**Project Archetype**: REPLACE_BEFORE_SHIP: consumer_product | b2b_saas | internal_tool | infra_service | backend_api
**Play Level**: REPLACE_BEFORE_SHIP: build | platform
**Speck Version**: REPLACE_BEFORE_SHIP: Speck version
**Last Updated**: REPLACE_BEFORE_SHIP: YYYY-MM-DD

---

## 0. How this contract is read — the Four Principles

This contract is an instance of Speck v8's four principles, not a checklist to satisfy the letter of:

- **P1 — Evaluation over verification.** Every gate below asks "what is wrong here?" first. An un-adjudicated capture (a stored screenshot no one judged) is surrogate proof, never a pass. LARP is two non-collapsible jobs — DOES-IT-WORK and IS-IT-GOOD.
- **P2 — No claim without a mechanism.** Every proof points to the observed mechanism that makes it true (a fired endpoint, a written row, a real forbidden op attempted as a real principal, a logged real attempt, a price-vs-free-substitute artifact). No mechanism → automatic fail.
- **P3 — "Can't reach it" is a finding.** An unreachable control/flow/guard is a defect hypothesis, not a license to skip or cap. Caps require a logged, reproduced real attempt.
- **P4 — The adversary is structural.** The evaluator is separately incentivized (independent auditor / N-skeptic), judged by defects found. The probe suite (§11) prompts the adversary's imagination; it does not define "done."

Full rationale: `docs/v8/v8-north-star.md`.

---

## 1. Target Launch Platforms

*List every platform where the product will run in production. Each gets its own evidence rules below.*

| Platform | Build artifact | Distribution |
|----------|----------------|--------------|
| REPLACE_BEFORE_SHIP: platform-1 | REPLACE_BEFORE_SHIP: build-artifact-1 | REPLACE_BEFORE_SHIP: distribution-1 |

*Examples — delete rows that don't apply, add the ones that do:*
*- iOS native | Standalone simulator/TestFlight build with `com.<project>.app` bundle | App Store*
*- Android native | APK/AAB from Gradle release build | Play Store*
*- Web | Production bundle behind reverse proxy at <domain> | <hosting>*
*- Desktop | Code-signed installer for macOS/Windows/Linux | <distribution>*

---

## 2. Valid Proof Sources (per platform)

*What runtime evidence COUNTS as proof of UX-RC, SHIP-RC, or SHIP for THIS product.*

### Platform: [e.g., iOS]
- ✅ Standalone simulator build with production-like bundle ID
- ✅ TestFlight build for live account / payment proof
- ✅ AXe screenshots and accessibility trees from named sim
- ✅ Native logs showing no redbox or crash
- ✅ Real Sentry events from the build (production environment)
- ✅ Real Supabase/Stripe/RevenueCat events from the build's environment

### Platform: [e.g., Web]
- ✅ Production bundle served behind reverse-proxy lookalike (nginx / serve --single)
- ✅ Playwright recordings against the built bundle (NOT dev server)
- ✅ Lighthouse audit against the production-like build
- ✅ Real auth + real backend evidence (not mocked)

### Platform: [e.g., CLI/API]
- ✅ Shell transcripts from binary built with `cargo build --release` (or equivalent)
- ✅ Integration tests against the binary (NOT the source tree)
- ✅ Recorded API responses against deployed staging/prod

---

## 3. Invalid Proof Sources (anti-proof)

*What runtime evidence DOES NOT count for THIS product. Validation reports that rely on these MUST mark themselves as "surrogate proof" and cannot claim UX-RC or higher.*

### Platform: [e.g., iOS]
- ❌ Browser localhost — not the iOS runtime
- ❌ Expo Go — not the standalone build
- ❌ Safari — not native
- ❌ Dev client launcher screenshots
- ❌ Stale production bundle (>1 week old build)
- ❌ Static screenshots not captured from the target runtime
- ❌ Mock data screenshots when feature requires real data
- ❌ Pro-unlocked LARP for paid validation (must be real purchase flow)

### Platform: [e.g., Web]
- ❌ Dev server (`vite dev` / `next dev`) screenshots for SHIP-RC claims
- ❌ Storybook-only screenshots for full-flow validation
- ❌ Mocked auth screenshots for auth flow claims
- ❌ Localhost screenshots for production-like behavior validation

### Platform: [e.g., CLI]
- ❌ `cargo run` output for shipping claims (must be release binary)
- ❌ Tests-pass-locally for cross-platform binary claims

### Universal Test Hygiene & Form-UX Anti-Proof (All Platforms)
- ❌ Tautological assertions: using empty/unconditional `expect(true).toBe(true)` checks to inflate passing test counts.
- ❌ Silent skips: collect-time skips (e.g. `describe.skipIf` evaluated before runtime setup) that hide unrun tests. Skips must be runtime skip-with-reason logs. **A skipped standing/guarded regression suite is not a gate** — verify guarded suites report as RUN (not skipped) in the target CI. A conditionally-skipped suite is worse than a failing one: invisibly green (#76.2).
- ❌ API-bypassed forms: using direct API/programmatic client calls to audit or validate user stories that primarily focus on interactive forms/inputs. If a human touches the UI, the audit/LARP must drive it through the real UI.
- ❌ Static mocks for async close: using synchronous/immediate mocks that do not model async callback latency or late-firing close events. Mocks must accurately simulate teardown delays.
- ❌ **Un-adjudicated capture (P1)**: a screenshot/recording stored as evidence of *quality* with no substantive per-screen critique. Twenty un-judged screenshots are surrogate proof of felt quality, not proof (#78).
- ❌ **Claim without mechanism (P2)**: any product/AI-surface claim of an action or completed state (built, generated, scheduled, "done") with no observed mechanism behind it (endpoint hit, row written, state change). A first-person action claim on a no-tools LLM surface is an automatic FELT-GOOD fail + P0 (#75-G1).
- ❌ **Bypass-role / dead-guard tests (P2)**: a negative test asserting an authz/RLS/tenant-isolation guard while running as a bypass-capable role (e.g. `service_role`/superuser) or behind a silent collect-time skip — it stays green even if the guard clause is deleted. Guard tests MUST run as a real least-privileged principal and actually attempt the forbidden op (#77.2).

### Universal Evidence-Integrity Anti-Proof — Reward Hacking (All Platforms)
*A green check is proof ONLY if the agent under test could not have manufactured it. The implementer/validator MUST be isolated from the evaluator. Any green gate produced through the channels below is anti-proof and caps the claim at NO-SHIP until re-run under isolation. (Industry audits found EVERY major coding benchmark could be driven to near-100% without solving a single task — Berkeley RDI, 2026.)*
- ❌ Implementer-authored/-modified verification logic in the graded change: test-harness hooks (`conftest.py`, `pytest_*` hooks, `jest`/`vitest` global setup/teardown), grader scripts, or CI config touched in the same diff that is being graded. (SWE-bench Verified was driven to 100% via a `conftest.py` pytest hook that rewrote every result to PASSED.)
- ❌ Force-passing constructs: monkeypatched assertions, module-load/`init()` side-effects that mutate results, or env flags that short-circuit checks.
- ❌ Answer/fix retrieval instead of derivation: mining git history for the reference fix, fetching the patch/solution from the web or issue tracker, or copying a known-good diff. (Solution-artifact retrieval showed a 72% resolved rate vs. ~40% baseline — *The Verification Horizon*, arXiv 2606.26300, 2026.)
- ❌ Visible-test overfitting: hard-coding outputs to satisfy the named tests rather than implementing the behavior.
- ❌ Self-graded "done": the agent declaring its own success criteria met without a runtime / exit-code / artifact check it did not control. ("Gate progress with facts, not vibes" — Thread AI, 2026.)

---

## 4. Required Runtime LARP / Integration Stress Tests

* **WHEN: consumer_product / b2b_saas / internal_tool**: Persona-based LARP flows recorded as evidence at each readiness state.
* **WHEN: infra_service / backend_api**: Integration / Stress-test scenarios under concurrent simulated load.

> **P1 — the two-job LARP**: every UI LARP is two non-collapsible jobs — **DOES-IT-WORK** (functional: the flow completes, gates enforced) and **IS-IT-GOOD** (experiential: per-screen, pixel-grounded adversarial critique of how it looks and feels). IS-IT-GOOD has its own pass/fail and can block ship independently of functional green. A captured screen with no substantive critique is an incomplete LARP (surrogate proof), not a pass. See `/larp`.

### Option A: Human Persona-Based LARP (for UI/Human-facing products)

### Longitudinal Proof Mode (for adaptive products)
*Distinguishes "snapshot state coverage" from "same-user longitudinal proof" to verify continuity across weeks/months of use.*

- **Requirement:** For products with learning, adaptation, or progress over time, the validation suite **MUST** record same-user timeline continuity.
- **Evidence:** A `timeline.jsonl` containing state mutations and invariants across the longitudinal chapters (Day 0 -> Week 12+).
- **Rule:** Disconnected seeded states are valid for debugging, but **NOT** sufficient for claiming longitudinal product excellence.

### LARP Required for UX-RC

| Persona | Flow | Evidence required |
|---------|------|-------------------|
| [Anxious beginner] | Onboarding → first session → completion | Screenshots, AX tree, taste notes per screen, timings |
| [Returning user] | Cold-open → resume context → action | Screenshots showing no re-onboarding, timings |
| [Skeptical buyer] | Landing → trust check → first signal of value | Screenshots, taste notes, "would I pay?" judgment |
| [Naive first-timer (context-stripped)] | Onboarding → first screen → value-producing screen | Screenshots, First-Viewport Reaction rubric, taste notes, revulsion check (Required for consumer archetypes) |

### LARP Required for SHIP-RC

All UX-RC LARPs **plus**:

| Persona | Flow | Evidence required |
|---------|------|-------------------|
| [Each named persona] | Full primary JTBD walkthrough | Full recording (video or step-by-step), AX trees, timings, transcripts |
| [Privacy-conscious user] | Account / data review | Screenshots showing data residency, deletion paths |

LARP scripts live in: `specs/projects/<PROJECT_ID>/personas/<persona-id>.md`

### Option B: Integration / Stress-Test Scenarios (for Infra/Backend)

### Stress Tests Required for API-RC (equivalent to UX-RC)

| Consumer Profile | Simulated Flow | Metrics / Evidence Required |
|------------------|----------------|-----------------------------|
| [Peak Concurrent Caller] | 500 concurrent requests over 1 min | Latency histogram (P95/P99), total successful ops, zero DB lock timeouts |
| [Malformed Operator] | Send 100 random malformed payloads | Confirm stable error codes (e.g. 400), zero database exception leaks, zero 500 crashes |

### Stress Tests Required for OPERATIONAL-RC (equivalent to SHIP-RC)

| Scenario | Simulated Disruptions | Integrity / Failover Evidence Required |
|----------|-----------------------|----------------------------------------|
| [Database Disconnect] | Restart DB container during active writes | Connection pooled retry success, zero partial writes (rollback complete), graceful 503 response |
| [Unresponsive Auth Provider] | Mock auth provider response latency >= 5s | Request timeout trigger within 1s, fail-closed/cached response validity, client receives expected timeout error |

---

## 5. Quality Judgment & Scoring Protocol

*The explicit protocol for evaluating product quality beyond functional completeness. Proves that Promise -> Build -> Prove includes a Judge -> Fix -> Re-prove loop.*

### The Core Principle
> Green evidence means eligible for judgment, not judged excellent.

All user-facing stories and epics must undergo a skeptical quality judgment. Completing the functional requirements and collecting evidence is only the first step.

### The 0-10 Scoring Scale & Hard Caps
Every scorecard dimension (Functional, Emotional, Social, Trust, Commercial) must be graded on this scale:

| Score | Meaning | Criteria |
|-------|---------|----------|
| **0-4** | Missing / Broken | Core functionality is missing, buggy, or fails basic Gherkin scenarios. |
| **5-7** | Functional, Unproven | The feature works, but has active P0/P1/P2 findings, or has no qualitative polish. |
| **8** | Completeness Ceiling | **Hard Cap:** All evidence slots (screenshots, AX trees, logs) are filled, Gherkin scenarios pass, but no distinct skeptical note is provided, or active P2 findings exist. |
| **9** | High Quality | Score of 8 + a distinct, detailed skeptical note + zero active P0/P1 findings. |
| **10** | Perfect / Premium | Score of 9 + full evidence (screenshot + AX + transcript/timing/log where relevant) + zero active P0/P1/P2 findings + a distinct, non-reused per-dimension note. |

### Hard Anti-Theater Rules
1. **No Scoreboard Inflation:** You cannot claim a score of 9 or 10 on any dimension without providing a distinct, detailed skeptical note.
2. **Reused Note Invalidation:** If the exact same skeptical note is reused across multiple dimensions, any score of 9 or 10 on those dimensions is invalidated and capped at 8.
3. **Active Findings Cap:** Any active P0 or P1 findings cap the maximum score at 4. Any active P2 findings cap the maximum score at 8.
4. **Runtime Truth Supremacy:** If a current runtime screenshot or AX tree contradicts an older scorecard claim, the current runtime evidence wins immediately, and the scorecard must be downgraded.

---

## 6. Required Static Evidence

*Evidence captured from running the target build, not the source tree.*

For every validation report at UX-RC or higher:
- Build identifier (commit SHA + build number)
- App / bundle / package identifier
- Environment config output (sanitized)
- Screenshots at the recipe-defined breakpoints / devices
- Accessibility trees (XML or JSON) for at least primary flow
- Logs showing zero redbox / zero unhandled exceptions
- Network capture or backend logs for any backend-dependent flow

### 6a. CI-Enforced Gate Registry

*The machine-readable registry of the gates this contract relies on — so Speck can check they are actually **wired**, not just declared. A gate that never runs is indistinguishable from a passing one; both leave every validator green, and the dark one manufactures a clean-looking evidence trail. `validate-gate-liveness.sh` diffs each gate's declared stage against what the **committed** hook/CI config actually runs (`GATE_WIRING_DRIFT` when they disagree). Seeded from the recipe's `evidence_contract.ci_gates` by `seed-gate-registry.sh` — don't hand-author unless amending.*

| Gate ID | Command / Script | Stage | Domain | Canary | Waiver |
|---------|------------------|-------|--------|--------|--------|
| REPLACE_BEFORE_SHIP:unit-frontend | `npm run test` | pre-push | frontend-tests | — | — |
| REPLACE_BEFORE_SHIP:banned-language | `.speck/scripts/banned-language-lint.sh` | pre-commit | copy | — | — |
| REPLACE_BEFORE_SHIP:integration | `pytest tests/integration` | ci:push | backend | — | — |

**Stage** ∈ `pre-commit | pre-push | commit-msg | ci:push | ci:pull_request | manual`.
- `manual` = the contract honestly declares this gate off the automatic path (no divergence to detect).
- **Waiver** = `waived DEC-####` — the gate *should* be wired but a logged decision accepts it dark for now (the DEC must resolve in `project-decisions-log.md`, or `GATE_WAIVER_UNBACKED`).
- The sin the validator hunts is the silent third case: §6a says `pre-push` / `ci:` while the wiring says `manual` / nowhere — with **neither** a `manual` declaration **nor** a waiver. Either arm the gate or amend the contract; the sin is the divergence, not being off the fast path.

---

## 7. Required Live-Service Evidence

*For features that depend on live external services.*

| Service | What proves it works in prod | What does NOT count |
|---------|-------------------------------|---------------------|
| Authentication (e.g., Stytch / Clerk / Supabase Auth) | Real signup → login → logout → fresh-login from launch build | Mocked auth, dev-mode shortcuts |
| Billing (e.g., RevenueCat / Stripe) | Real sandbox purchase → restore → manage → entitlement state in DB | Pro-unlocked LARP, mock billing |
| Analytics (e.g., PostHog) | Events visible in dashboard from launch build | Console.log statements |
| Error tracking (e.g., Sentry) | Real captured event from launch build | Local error log |
| Storage (e.g., Supabase / S3) | Real upload + retrieval from launch build | Local file system |
| AI APIs (e.g., OpenAI / Anthropic) | Real API call with real cost in dashboard | Mocked responses |

---

## 8. Readiness State Gate Criteria

*The explicit checklist that must pass to claim each readiness state.*

### 🧭 The Four-Axis Readiness Model
Every readiness claim decomposes into three distinct, non-substitutable axes:
1. **CORRECT** — Does the code do what it claims? (proven by unit/integration tests, types, and `/audit`).
2. **ON-CONTRACT** — Does the behavior conform to the specifications and magic moments? (proven by standard LARP and traceability matrix).
3. **FELT-GOOD** *(legibility)* — Would a naive, first-time user actually find the experience good? **The AI evaluates this axis directly** via the context-stripped naive-hostile LARP (First-Viewport Reaction + taste-judgment rubric). A human taste review is an *optional stronger override* — never a prerequisite.
4. **TASTE** *(connoisseur craft)* — Is it *crafted / premium / does it sing*? Distinct from FELT-GOOD legibility: a screen can be clear yet cheap-feeling. **The AI evaluates this directly** via the connoisseur-hostile pass (Job C), **dual-anchored** against `product-contract.md` §6b Aesthetic Contract + `design-system.md` (product-relative) AND the `visual-quality` universal principles. Records `taste_axis` + `taste_anchor`; **surfaces aesthetic forks for the owner** (never resolves subjective taste unilaterally); a **severe BAD** (≥2 pixel-grounded craft violations on a flagship surface) or a named-declared-rule violation **caps the state**. `TASTE: uncovered` for consumer archetypes until the connoisseur pass runs.

**CRITICAL**: You must never use unqualified "verified" or "validated" claims without naming the axis. FELT-GOOD is a real, AI-evaluable axis — the agent is expected to understand and apply first-impression taste judgment, not defer it. A story or epic cannot claim FELT-GOOD coverage from correctness/conformance evidence alone; it must come from an actual naive-hostile taste pass. For consumer archetypes: `FELT: uncovered` until the naive-hostile pass runs → `FELT: ai-verified` once the AI records its taste verdict → `FELT: human-verified` when a human additionally signs off.

### IMPL-GREEN
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Lint passes
- [ ] Type check passes (if typed language)
- [ ] No `expect().toBe(<wrong-value>)` with "BUG:" / "TODO:" / "fix later" / "should be" comments
- [ ] Builds without warnings/errors
- [ ] **Evaluator isolation**: the graded change does NOT add or modify test-harness hooks, grader scripts, or CI config (diff-scan for new/edited `conftest.py` & `pytest`/`jest`/`vitest` setup-teardown, and changed CI workflows). If verification logic legitimately changes, it lands and is reviewed in a SEPARATE change. A zero-capability/no-op change must NOT be able to make this gate pass.
- [ ] **Clean trajectory**: the implementation transcript shows no shortcut-seeking — no reference-fix/answer retrieval (git-history mining, web fetch of the patch) and no test-oracle tampering. (A trajectory monitor + quality judge dropped the gamed-pass rate 28.57% → 0.56% — *The Verification Horizon*, 2026.)

### INTEGRATION-GREEN

* **WHEN: features depend on external services/APIs/LLMs (§7)**:
  - [ ] All IMPL-GREEN criteria pass
  - [ ] **Real-Integration Smoke Check**: At least one real round-trip call has successfully run and succeeded against each live external service named in §7 (e.g., real LLM completion returned, live API call responded 200). This catches 429 rate-limiting, authentication, payload-shape, or connectivity errors that mocks and compilers cannot see.
  - [ ] Real-integration logs or traces captured and saved in validation records.
* **WHEN: DB-backed project (persistent store + migrations)**:
  - [ ] **Live-Schema Parity Check**: Every database object (tables, columns, custom types, trigger functions) that your migration files claim to create exists and is verified in the target database. Run the schema↔migrations drift probe (`validate-schema-drift.sh`) to assert parity.
  - [ ] **Real Write-Path Smoke Check**: At least one real database write (e.g. insert, update, or delete) path is exercised and verified. Fail-closed reads (e.g., catching errors and returning empty/disabled) swallow missing tables on read paths; write paths expose them immediately.
  - [ ] **Migration integrity**: Verify no migrations were "force-marked" as applied without running their SQL. 
    > ⚠️ **CRITICAL WARNING**: Commands like `supabase migration repair --status applied <version>` (and database analogs) mark a migration as applied in the system ledger WITHOUT executing its SQL. This leaves the actual database schema in an un-migrated, drifting state while ledger checks false-pass. Never use migration ledger repairs as a shortcut for executing migrations in target environments.
* **WHEN: no external services in §7 and not DB-backed**:
  - [ ] (SKIP — Auto-passed. Proceed directly to UX-RC / API-RC)

### UX-RC / API-RC

* **WHEN: consumer_product / b2b_saas / internal_tool (UX-RC)**:
  - [ ] All IMPL-GREEN criteria
  - [ ] Persona LARP recorded against built artifact (not dev server) for every named UX-RC persona
  - [ ] Reachability check: user can complete primary JTBD without dev shortcuts
  - [ ] No scaffolding in UI (no UUID inputs, no debug headers, no x-user-id pickers)
  - [ ] Automation language invisible to users (no "QA", "test mode", "fixture", "preview data")
  - [ ] Banned language lint passes against all user-visible surfaces
  - [ ] Magic moments validated in LARP — each lands per its trigger / content beats / target response

  **UX-RC evidence partition — autonomous vs gated** *(prevents under-driving validation: defer the gated part, NEVER the autonomous part)*:
  - **Autonomous (REQUIRED — an agent with a build + a browser/headless tool can gather ALL of this; it is REQUIRED and NEVER deferrable)**:
    - [ ] Production build produced (not dev server) and cold-started from a **clean build** (cache cleared, e.g. `rm -rf .next` / `trash .next` or build tool cache equivalents)
    - [ ] Headless/browser persona LARP recorded against that build (screenshots + AX tree per step)
    - [ ] axe-core run with the **JSON stored** under `larp-recordings/` (claiming "axe 0/0" with no stored JSON is surrogate proof)
    - [ ] JTBD walkthrough completed end-to-end on the built artifact
  - **Human / creds-gated (legitimately deferrable — disclose in Deferrals, classify `human/creds-gated`)**:
    - Live third-party provider sends to a real account/device (SMS / WhatsApp / email to a real phone)
    - Formal human blind panels (e.g. ≥3 native-speaker copy review)
    - Live NFR / load tests on real production infrastructure
  - **RULE**: You may NOT declare "IMPL-GREEN with UX-RC deferred" while any **autonomous** item above is undone. If a build + browser/preview tool are available, the agent MUST complete the autonomous portion first; only the gated portion may be deferred. Deferring the browser cold-start LARP is strictly prohibited. If there is an infrastructure limitation, it must be reported as a hard blocker (`NO-SHIP`) rather than allowing a bypass, unless a named infrastructure blocker is explicitly identified and the attempt is logged (in which case the state is capped at `INTEGRATION-GREEN`).

  ### 💡 UI LARP Setup Recipe (Sandbox-Friendly)
  To execute browser LARPs successfully in sandboxed or restricted environments without real production databases/credentials:
  1. **Throwaway/Local DB**: Seed a local/SQLite or Docker-based database with minimal test fixtures.
  2. **Loopback/Review-Session Backdoor**: Implement a secure backdoor route or environment flag (e.g. `VITE_DEV_HTTP=true` or `process.env.PLAYWRIGHT_TEST=true`) that bypasses external OAuth/Clerk redirects and logs in a test user.
  3. **localStorage Token Re-injection**: Pre-populate `localStorage` or cookies with mock JWTs or session tokens before navigating, to simulate an authenticated state.
  4. **Loopback/Mock Server**: Run a lightweight local mock server (e.g., MSW or wiremock) to intercept and mock third-party API calls (e.g., Stripe, Resend) during the browser run.
* **WHEN: infra_service / backend_api (API-RC)**:
  - [ ] All IMPL-GREEN criteria
  - [ ] All API endpoint contracts verified with strict schema checks (Pydantic / OpenAPI schema tests)
  - [ ] DX Verification: developer-facing documentation / quickstart is accurate and working
  - [ ] Operational stress-test (under Option B) recorded with acceptable latency metrics

  **API-RC evidence partition — autonomous vs gated** *(backend analog of UX-RC partition)*:
  - **Autonomous (REQUIRED — never deferrable)**:
    - [ ] All endpoint schemas compiled/generated and verified with strict schema validators (Pydantic / OpenAPI schema tests)
    - [ ] Operational Scenario Walkthrough (Option B) executed locally/headless and transaction log captured
    - [ ] DX Verification: developer-facing docs/quickstart verified to compile and run with mock credentials
  - **Human / creds-gated (legitimately deferrable — disclose in Deferrals, classify `human/creds-gated`)**:
    - Real sandbox credentials/keys verification on production integration platforms
    - Security audit or compliance scans requiring external third-party tools/credentials
    - Production infrastructure latency metrics under load
  - **RULE**: You may NOT declare "IMPL-GREEN with API-RC deferred" while any **autonomous** item above is undone. Deferring the whole API-RC tier when part of it is autonomously gatherable under-drives validation and is a finding.

### COMMERCIAL-RC *(paid products only)*

* **WHEN: consumer_product / b2b_saas / internal_tool (or paid APIs)**:
  - [ ] **Value defensibility (P2, #74)**: `product-contract.md` §2a substitute table is filled with a defensible-wedge verdict a skeptical buyer *who already has free AI* would accept, AND a naive-hostile "skeptical buyer" LARP pass confirms the product earns its price over the $0 substitute (not "convenience" alone). A price with no defensibility artifact is an unbacked claim — cap at UX-RC.
  - [ ] All UX-RC / API-RC criteria
  - [ ] Real sandbox purchase + restore + manage + entitlement state in DB (or metered API billing verified)
  - [ ] Real fallback states (network down, payment fail, restore fail) tested
  - [ ] Support / Contact path accessible BEFORE purchase
  - [ ] Privacy + Terms accessible BEFORE purchase, with plain-language copy
  - [ ] Analytics events fire for purchase funnel
  - [ ] Webhook sync verified
* **WHEN: internal_tool / infra_service / free products**:
  - [ ] (SKIP - Auto-passed. Proceed directly to SHIP-RC / OPERATIONAL-RC)

### SHIP-RC / OPERATIONAL-RC

* **WHEN: consumer_product / b2b_saas / internal_tool (SHIP-RC)**:
  - [ ] All COMMERCIAL-RC criteria (or all UX-RC if free product)
  - [ ] Runtime LARP against the LAUNCH build (not dev, not preview)
  - [ ] **FELT-GOOD covered by the naive-hostile LARP**: The AI has run the naive-hostile + premise-challenge passes and recorded a first-impression taste verdict (`felt_axis: ai-verified`) with First-Viewport Reaction findings. A human taste review (`larp-recordings/<sha>-felt-attestation.md`) is an optional stronger signal, not a prerequisite. If FELT-GOOD is still `uncovered` (naive-hostile pass never ran), cap the state at the last clean state.
  - [ ] Device-walk manual attestation recorded (if story/epic contains device-walk criteria: keyboard avoidance, native hit-testing, biometrics, etc.)
  - [ ] Keystone Dependencies verified: all founder-provisioned secrets/infra keys are set and active. If a keystone is absent, CI/CD must output a clear skip-with-reason log (never silent) rather than failing the validation suite. Awaiting keystone keys caps maximum verified state at `UX-RC`, but allows lower suites to pass green.
  - [ ] Full JTBD walkthrough per persona passes
  - [ ] Cross-epic integration tested (the seams between epics)
  - [ ] Production environment config verified (no dev keys, no test secrets)
  - [ ] Environment separation verified (bundle IDs, schemes, Sentry environments)
  - [ ] Adversarial probe passes (malformed input, oversized payload, dep-down behavior)
  - [ ] GDPR cascade verification (if applicable): user deletion removes all related rows
* **WHEN: infra_service / backend_api (OPERATIONAL-RC)**:
  - [ ] All API-RC criteria
  - [ ] Integration / Failover / Resilience stress tests under disruption (Option B) pass
  - [ ] Production environment config verified (no dev keys, no test secrets)
  - [ ] Adversarial probe passes (malformed input, concurrent write race-conditions, injection attempts)
  - [ ] Downstream epic unblock check: calling epics/services can successfully compile / link / boot against this release

### SHIP

* **ALL ARCHETYPES**:
  - [ ] All SHIP-RC / OPERATIONAL-RC criteria
  - [ ] Deployment ran without errors
  - [ ] Post-deploy healthcheck / smoke-test returns ok
  - [ ] **Spec-to-Deployed Behavior Provenance Ledger**: Verification logs map the deployed artifact version/hash directly back to the triggering git commit SHA and the corresponding Speck specifications/PRM ledger line, guaranteeing complete, unbroken traceability of behavior from specifications to live production.
  - [ ] First real user/consumer signal observed (signup / payment / active service request)
  - [ ] Sentry / Log monitoring shows zero new errors in first 24h
  - [ ] Monitoring shows expected baseline metrics

### Verifiability Tiering & Artifact-Config Drift (All Platforms)

To guarantee that agent-verified success translates to actual runtime success on a customer's physical device, all acceptance criteria and evidence requirements must be explicitly tiered:

1. **`agent-LARP` (UX-RC Cap)**: Verifies the code, logic, rendering, and composition. **Runs against a production build whenever one is autonomously producible** — `next dev` / `vite` dev-server evidence does NOT count for UX-RC; dev-server composition is only a fallback when no build can be produced in the sandbox. Fully automatable by agents in build/preview environments.
2. **`device-walk` (SHIP-RC Requirement)**: Verifies the actual *shipped/baked native or client artifact*. Any behavior that depends on **Artifact-Config Drift**—where the local/development server environment differs from the baked production build by construction—MUST be categorized as `device-walk` only.

#### The Artifact-Config Drift Class (SHIP-RC Only):
- **Baked Environment Variables / Configs**: e.g., `VITE_API_URL` or secret host URL mappings baked into a native bundle (Capacitor, Cordova, React Native, Electron) or static client bundle at build-time.
- **Third-Party Callback & Redirect Allow-lists**: OAuth login redirects, Deep Linking protocols, or sign-in callback schemes that only function on the signed production bundle.
- **Signing & Signing Identities**: App Store provisioning profiles, native binary entitlements, push notification certificates, or keychain access groups.
- **Native Webview Wrappers / Hardware Seams**: Keyboard avoidance behaviors, native hit-testing overlays, native biometrics, or hardware interactions (camera, Bluetooth, file system).

*Rule:* If any of these criteria are present, the agent is structurally incapable of verifying them autonomously (as its sandbox runs on dev/preview targets with mock configs). These MUST be tagged `device-walk`. Attempting to autonomously claim `SHIP-RC` or higher without a valid `larp-recordings/<sha>-human-attestation.md` recorded by a human on a real build is classified as **P0 surrogate-proof drift**.

### PROFILE Gate Criteria (v7.7+)

*Public-face drift must not block release silently. See `project.md` PROFILE surfaces table.*

| State | PROFILE requirement |
|-------|---------------------|
| IMPL-GREEN | README footer matches `.speck/VERSION`; no orphan README placeholders |
| UX-RC | README one-liner token-overlap with product-contract Section 1 ≥ 60% |
| COMMERCIAL-RC | All declared PROFILE surfaces within drift threshold |
| SHIP-RC | Zero `PROFILE_DRIFT.P1` at `/recheck`; GitHub repo description aligned (manual attestation) |
| SHIP | SHIP-RC + `validate-readme.sh --strict` green in CI |

Per declared PROFILE surface (from `project.md`):

| Surface | Source of truth | Drift check | Refresh |
|---------|-----------------|-------------|---------|
| Root README | product-contract §1 | `profile-drift-check.sh` | `/project-readme` |
| package.json description | README one-liner | `regenerate-project-readme.sh --surface=package` | `/project-readme --surface=package` |
| GitHub repo description | README one-liner | manual `/recheck` | `gh repo edit --description` |
| Landing hero (if declared) | product-contract §1 + ui-spec | `--surface=landing` (check-only) | story validate gate |

---

## 9. Evidence Storage

*Where evidence artifacts live in the repo.*

```
specs/projects/<PROJECT_ID>/
├── personas/<persona-id>.md           # LARP script + detection signals
└── epics/E###-name/
    └── stories/S###-name/
        ├── screenshots/               # Captured per build per breakpoint per state
        │   └── <sha>-<screen>-<breakpoint>-<state>.png
        ├── larp-recordings/           # Video / step-by-step
        │   └── <sha>-<persona>-<flow>.{mp4,json,md}
        ├── ax-trees/                  # Accessibility snapshots
        │   └── <sha>-<screen>.{xml,json}
        ├── transcripts/               # AI transcripts, CLI transcripts
        │   └── <sha>-<scenario>.md
        └── logs/                      # Native logs, network captures
            └── <sha>-<flow>.log
```

Naming convention: `<short-sha>-<descriptor>.<ext>`. The SHA proves the evidence is from a specific build, not stale.

---

## 10. Who Can Mark a Gate Passed

*The default verification model: the AI agent runs the gates and records evidence. The human reviews the recorded evidence and may override.*

### 👥 Four-Axis Ownership
- **CORRECT**: AI agent claims pass based on tests, types, and `/audit` logs.
- **ON-CONTRACT**: AI agent claims pass based on standard LARP and traceability matrix.
- **FELT-GOOD**: **AI-evaluated.** The agent runs the naive-hostile LARP (First-Viewport Reaction + taste-judgment rubric), applies first-impression taste judgment, and records the verdict (`felt_axis: ai-verified`). A human may override at any time (final taste authority), and a recorded human taste review promotes the axis to `human-verified` — but human sign-off is an *optional stronger signal*, never a prerequisite for shipping.
- **TASTE**: **AI-evaluated, owner-sovereign on direction.** The agent runs the connoisseur-hostile pass (dual-anchored), records `taste_axis`/`taste_anchor`, and **surfaces aesthetic forks** — it never resolves subjective taste unilaterally, nor auto-fixes contestable taste (only named-rule violations + hard-objective defects). A **severe BAD** (≥2 pixel-grounded craft violations on a flagship surface) or a named-declared-rule violation **caps the state**; the *direction* of any fix is the owner's fork. A `universal-only` anchor (no §6b/design-system) cannot back a premium claim at SHIP-RC.

| Gate / Axis | Who claims pass | Who can override pass | Who must approve SHIP |
|-------------|-----------------|------------------------|-----------------------|
| IMPL-GREEN (CORRECT) | AI agent (automated) | Human (vetoes possible) | n/a |
| UX-RC (ON-CONTRACT) | AI agent (records LARP) | Human (taste judgment) | n/a |
| UX-RC (FELT-GOOD) | AI agent (naive-hostile LARP taste verdict) | Human (optional stronger override) | n/a |
| COMMERCIAL-RC | AI agent (records purchase flow) | Human (legal/support review) | n/a |
| SHIP-RC | AI agent (full record) | Human (final taste judgment) | Human (release decision) |
| SHIP | AI agent (post-deploy smoke) | Human | Human (release decision) |

### Irreversible-Action Control Tiers
*Evidence proves doneness; this tiers AUTONOMY by blast radius. An action's tier sets the minimum readiness state + approval it needs before an agent may EXECUTE it (not merely propose it).*
- **Tier 0 (reversible)**: Local edits, tests, branch commits, PR drafts — agent executes freely.
- **Tier 1 (recoverable)**: Merge to main, dependency bumps — after Verify-Skills Gate; human veto post-hoc.
- **Tier 2 (externally visible)**: Staging deploy, non-prod data seed — requires INTEGRATION-GREEN + recorded approval.
- **Tier 3 (irreversible/costly)**: Prod deploy, prod-DB drop/alter, real user comms (email/SMS), secret rotation/exposure, force-push to main, charging cards — agent MAY prepare but NEVER executes without a recorded human approval token; allowed only at SHIP-RC+.

---

## 11. Adversarial Probe Suite

*P4: this list **prompts the adversary's imagination — it is not the definition of "done."** A green row counts only if a genuine attempt to break it was made and logged. Do not grow this list to close a gap; install the gap as a principle (P1–P4) instead. The `/audit` skill runs these.*

| Probe | Expected behavior |
|-------|-------------------|
| Malformed JWT | 401 with stable error code, never 500 |
| Oversized payload (e.g., 1MB) | 413 or 400, never 500 |
| Missing required field | 400 with clear error, never crash |
| Injection attempt (SQL/NoSQL/template) | Sanitized, never executed |
| Concurrent same-resource update | Last-write-wins with audit trail OR rejection — never silent loss |
| DB connection drop mid-request | Graceful error, no partial writes |
| External AI/payment service down | Fail-open with user-visible degradation or fail-closed with retry, never silent hang |
| Rate limit exceeded | 429 with Retry-After header |
| Auth header missing | 401, never 500 |
| GDPR delete request | All related-table rows removed or anonymized; verified via integration test |
| Comprehension / Legibility probe | A first-time user can articulate exactly what the product is, why it matters, and identify the primary call-to-action within 5 seconds of the JTBD walkthrough cold-start. Catches "technically correct but functionally unintelligible" landing pages or dashboards. |
| Async close/teardown (Mocks check) | Mocks model late close events, queued timers, or retries after dependency is closed; verify no background work is rescheduled and tests assert "no late callbacks after close" |
| Test count honesty | Verify no tests use tautologies (e.g. `expect(true).toBe(true)`) to inflate counts, and no collect-time skips hide unrun suites silently |
| Keystone key landing | Verify that all human-provisioned external services have a clear skip-with-reason logic that auto-runs the moment the key lands |
| Evaluator-tampering scan | The graded diff adds/edits no test-harness hooks (`conftest.py`, global setup/teardown), grader, or CI config; if verification logic must change, it is reviewed in a separate change. A no-op/zero-capability change must NOT make any gate pass. |
| Reward-hack trajectory audit | Transcript shows no fix/answer retrieval (git-history mining, web fetch of the reference patch) and no visible-test overfitting; any shortcut-dependent pass is re-run under isolation before it counts. |
| Irreversible-action tier compliance check | Verification confirms no Tier 2 or Tier 3 actions were executed by the agent without corresponding recorded human approval tokens in the trajectory log. |

---

## 12. Stale-Proof Policy

*Evidence is fresh ONLY when tied to a recent commit.*

- Evidence is **fresh** when the build SHA matches HEAD or differs by less than 7 days of commits
- Evidence is **stale** when the build SHA is >2 weeks behind HEAD, or older than 14 days
- Stale evidence CANNOT support a readiness state claim — `/recheck` must re-run

---

## 13. Surrogate Proof Rule

*If a validation report uses any evidence from this contract's "Invalid Proof Sources" list, the report MUST:*

1. Mark the affected section as "Surrogate Proof"
2. Refuse to claim UX-RC or higher
3. Link to the canonical proof requirement
4. Enqueue a follow-up task to gather valid proof

- **Stale Build Cache as Surrogate:** Re-using an incremental build cache (e.g. Next.js, Webpack, Vite, or Android/iOS compiler caches) that serves stale compiled code instead of compiling the current commit HEAD is considered surrogate proof. It is strictly banned for UX-RC+ readiness claims.

---

## 14. LARP Runway & Efficiency Controls

*Efficiency controls to prevent excessive native rebuilds and optimize test loops.*

- **Build Fingerprint:** Every LARP recording must capture the app version, bundle ID, and backend API fingerprint.
- **Rebuild Requirements:** A full native rebuild is required only when native dependencies (npm/cocoapods/gradle), environment variables, or native configuration changes.
- **Freshness Window:** If the build fingerprint has not changed, the agent may reuse the existing build artifact for focused LARP runs.
- **Focused Reruns:** When polishing UI, the agent should isolate the simulator/device and rerun only the specific affected steps, rather than the full suite.
- **Clean Build Requirement for UX-RC+ claims:** While build fingerprint reuse is permitted for rapid iteration and UI polishing, any formal or final validation claiming a `UX-RC` or higher readiness state MUST be verified against a freshly compiled production build (where all incremental build caches were cleared prior to compile) to guarantee no stale compiled assets are served.

---

## Review Checklist

- [ ] Every target platform has explicit Valid + Invalid Proof Sources
- [ ] Every readiness state has explicit gate criteria
- [ ] Every external service used has Live-Service Evidence requirements
- [ ] Adversarial Probe Suite is populated (at least the standard 10)
- [ ] Evidence storage paths are defined
- [ ] Stale-proof and Surrogate-proof rules are in force
- [ ] Evidence-Integrity anti-proof (reward-hacking) rules are in force; evaluator is isolated from the implementer
- [ ] PROFILE Gate Criteria populated (v7.7+ projects)

---

*[as of SHA `<git_sha_short>` | verified `<date>` | speck]*
