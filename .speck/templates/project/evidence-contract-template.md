---
speck_version: 7.0
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

Six v6 projects independently failed by treating browser screenshots as native-iOS proof,
treating "tests pass" as launch-ready, treating dev-server LARP as production-ready.
This contract makes those failures impossible.

200-line target.
-->

**Project**: [PROJECT_NAME]
**Project ID**: `[PROJECT_ID]`
**Play Level**: [build | platform]
**Speck Version**: 7.0.0
**Last Updated**: [YYYY-MM-DD]

---

## 1. Target Launch Platforms

*List every platform where the product will run in production. Each gets its own evidence rules below.*

| Platform | Build artifact | Distribution |
|----------|----------------|--------------|
| [e.g., iOS native] | Standalone simulator/TestFlight build with `com.<project>.app` bundle | App Store |
| [e.g., Android native] | APK/AAB from Gradle release build | Play Store |
| [e.g., Web] | Production bundle behind reverse proxy at <domain> | <hosting> |
| [e.g., Desktop] | Code-signed installer for macOS/Windows/Linux | <distribution> |

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

---

## 4. Required Runtime LARP

*The persona-based LARP flows that must be recorded as evidence at each readiness state.*

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

---

## 5. Required Static Evidence

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

## 6. Required Live-Service Evidence

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

## 7. Readiness State Gate Criteria

*The explicit checklist that must pass to claim each readiness state.*

### IMPL-GREEN
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Lint passes
- [ ] Type check passes (if typed language)
- [ ] No `expect().toBe(<wrong-value>)` with "BUG:" / "TODO:" / "fix later" / "should be" comments
- [ ] Builds without warnings/errors

### UX-RC
- [ ] All IMPL-GREEN criteria
- [ ] Persona LARP recorded against built artifact (not dev server) for every named UX-RC persona
- [ ] Reachability check: user can complete primary JTBD without dev shortcuts
- [ ] No scaffolding in UI (no UUID inputs, no debug headers, no x-user-id pickers)
- [ ] Automation language invisible to users (no "QA", "test mode", "fixture", "preview data")
- [ ] Banned language lint passes against all user-visible surfaces
- [ ] Magic moments validated in LARP — each lands per its trigger / content beats / target response

### COMMERCIAL-RC *(paid products only)*
- [ ] All UX-RC criteria
- [ ] Real sandbox purchase + restore + manage + entitlement state in DB
- [ ] Real fallback states (network down, payment fail, restore fail) tested
- [ ] Support path accessible BEFORE purchase
- [ ] Privacy + Terms accessible BEFORE purchase, with plain-language copy
- [ ] Analytics events fire for purchase funnel
- [ ] Webhook sync verified

### SHIP-RC
- [ ] All COMMERCIAL-RC criteria (or all UX-RC if free product)
- [ ] Runtime LARP against the LAUNCH build (not dev, not preview)
- [ ] Full JTBD walkthrough per persona passes
- [ ] Cross-epic integration tested (the seams between epics)
- [ ] Production environment config verified (no dev keys, no test secrets)
- [ ] Environment separation verified (bundle IDs, schemes, Sentry environments)
- [ ] Adversarial probe passes (malformed input, oversized payload, dep-down behavior)
- [ ] GDPR cascade verification (if applicable): user deletion removes all related rows

### SHIP
- [ ] All SHIP-RC criteria
- [ ] Deployment ran without errors
- [ ] Post-deploy healthcheck returns ok
- [ ] First real user signal observed (signup / payment / etc.)
- [ ] Sentry shows zero new errors in first 24h
- [ ] Monitoring shows expected baseline metrics

---

## 8. Evidence Storage

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

## 9. Who Can Mark a Gate Passed

*The Speck v7 default: the AI agent runs the gates and records evidence. The human reviews the recorded evidence and may override.*

| Gate | Who claims pass | Who can override pass | Who must approve SHIP |
|------|-----------------|------------------------|-----------------------|
| IMPL-GREEN | AI agent (automated) | Human (vetoes possible) | n/a |
| UX-RC | AI agent (records LARP) | Human (taste judgment) | n/a |
| COMMERCIAL-RC | AI agent (records purchase flow) | Human (legal/support review) | n/a |
| SHIP-RC | AI agent (full record) | Human (final taste judgment) | Human (release decision) |
| SHIP | AI agent (post-deploy smoke) | Human | Human (release decision) |

---

## 10. Adversarial Probe Suite

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

---

## 11. Stale-Proof Policy

*Evidence is fresh ONLY when tied to a recent commit.*

- Evidence is **fresh** when the build SHA matches HEAD or differs by less than 7 days of commits
- Evidence is **stale** when the build SHA is >2 weeks behind HEAD, or older than 14 days
- Stale evidence CANNOT support a readiness state claim — `/recheck` must re-run

---

## 12. Surrogate Proof Rule

*If a validation report uses any evidence from this contract's "Invalid Proof Sources" list, the report MUST:*

1. Mark the affected section as "Surrogate Proof"
2. Refuse to claim UX-RC or higher
3. Link to the canonical proof requirement
4. Enqueue a follow-up task to gather valid proof

---

## Review Checklist

- [ ] Every target platform has explicit Valid + Invalid Proof Sources
- [ ] Every readiness state has explicit gate criteria
- [ ] Every external service used has Live-Service Evidence requirements
- [ ] Adversarial Probe Suite is populated (at least the standard 10)
- [ ] Evidence storage paths are defined
- [ ] Stale-proof and Surrogate-proof rules are in force

---

*[as of SHA `<git_sha_short>` | verified `<date>` | speck v7.0.0]*
