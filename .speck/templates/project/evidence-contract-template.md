---
speck_version: 7.0
template_version: "7.11.0"
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
- ❌ Silent skips: using collect-time skips (like `describe.skipIf` evaluated before runtime setups) that silently hide unrun tests. Skips must be runtime skip-with-reason logs.
- ❌ API-bypassed forms: using direct API/programmatic client calls to audit or validate user stories that primarily focus on interactive forms/inputs. If a human touches the UI, the audit/LARP must drive it through the real UI.
- ❌ Static mocks for async close: using synchronous/immediate mocks that do not model async callback latency or late-firing close events. Mocks must accurately simulate teardown delays.

---

## 4. Required Runtime LARP / Integration Stress Tests

* **WHEN: consumer_product / b2b_saas / internal_tool**: Persona-based LARP flows recorded as evidence at each readiness state.
* **WHEN: infra_service / backend_api**: Integration / Stress-test scenarios under concurrent simulated load.

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

### IMPL-GREEN
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Lint passes
- [ ] Type check passes (if typed language)
- [ ] No `expect().toBe(<wrong-value>)` with "BUG:" / "TODO:" / "fix later" / "should be" comments
- [ ] Builds without warnings/errors

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
  - **Autonomous (REQUIRED — an agent with a build + a browser/headless tool can gather ALL of this; it is NEVER deferrable)**:
    - [ ] Production build produced (not dev server) and cold-started from a **clean build** (cache cleared, e.g. `rm -rf .next` / `trash .next` or build tool cache equivalents)
    - [ ] Headless/browser persona LARP recorded against that build (screenshots + AX tree per step)
    - [ ] axe-core run with the **JSON stored** under `larp-recordings/` (claiming "axe 0/0" with no stored JSON is surrogate proof)
    - [ ] JTBD walkthrough completed end-to-end on the built artifact
  - **Human / creds-gated (legitimately deferrable — disclose in Deferrals, classify `human/creds-gated`)**:
    - Live third-party provider sends to a real account/device (SMS / WhatsApp / email to a real phone)
    - Formal human blind panels (e.g. ≥3 native-speaker copy review)
    - Live NFR / load tests on real production infrastructure
  - **RULE**: You may NOT declare "IMPL-GREEN with UX-RC deferred" while any **autonomous** item above is undone. If a build + browser/preview tool are available, the agent MUST complete the autonomous portion first; only the gated portion may be deferred. Deferring the whole UX-RC tier when part of it is autonomously gatherable under-drives validation and is a finding.
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

| Gate | Who claims pass | Who can override pass | Who must approve SHIP |
|------|-----------------|------------------------|-----------------------|
| IMPL-GREEN | AI agent (automated) | Human (vetoes possible) | n/a |
| UX-RC | AI agent (records LARP) | Human (taste judgment) | n/a |
| COMMERCIAL-RC | AI agent (records purchase flow) | Human (legal/support review) | n/a |
| SHIP-RC | AI agent (full record) | Human (final taste judgment) | Human (release decision) |
| SHIP | AI agent (post-deploy smoke) | Human | Human (release decision) |

---

## 11. Adversarial Probe Suite

*Standard adversarial checks for SHIP-RC. The `/audit` skill runs these automatically.*

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
| Async close/teardown (Mocks check) | Mocks model late close events, queued timers, or retries after dependency is closed; verify no background work is rescheduled and tests assert "no late callbacks after close" |
| Test count honesty | Verify no tests use tautologies (e.g. `expect(true).toBe(true)`) to inflate counts, and no collect-time skips hide unrun suites silently |
| Keystone key landing | Verify that all human-provisioned external services have a clear skip-with-reason logic that auto-runs the moment the key lands |

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
- [ ] PROFILE Gate Criteria populated (v7.7+ projects)

---

*[as of SHA `<git_sha_short>` | verified `<date>` | speck]*
