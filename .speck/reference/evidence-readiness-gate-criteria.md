# Readiness gate criteria detail (JIT)

## 8. Readiness State Gate Criteria

*The explicit checklist that must pass to claim each readiness state.*

### The Four-Axis Readiness Model
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

