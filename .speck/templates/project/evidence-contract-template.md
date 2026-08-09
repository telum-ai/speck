---
speck_version: 11.0
template_version: "11.0.0"
artifact_type: evidence-contract
play_levels: [build, platform]
---

# Evidence Contract: [PROJECT_NAME]

<!-- PROVE center of gravity. Fill REPLACE_BEFORE_SHIP tokens before ship claims. -->

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

*Platform proof examples (iOS/Web/CLI): `.speck/reference/evidence-valid-proof-examples.md` (JIT). Fill product-specific rows below.*

### Platform: REPLACE_BEFORE_SHIP: platform-1
- REPLACE_BEFORE_SHIP: valid-proof-1
- REPLACE_BEFORE_SHIP: valid-proof-2

### 2a. The claim-type axis — which INSTRUMENT is admissible for which KIND of claim

*Everything above is indexed by **platform**. Platform answers "which build"; it never answers "which instrument can observe this claim." That gap is the whole mechanism behind a recurring defect class: a green, honestly-authored, mutation-verified suite gets cited for a claim it is **structurally incapable of observing**, and nothing written down was violated. #87 gave evidence a **grain** field (at what altitude it was collected); this gives it **admissibility** (which substrate may back which claim at all).*

**How to route a claim.** Read the claim's verb → find its row → cite a substrate from **Admissible**. Citing anything in that row's **Does NOT count** column is anti-proof (§3) no matter how green it is, and caps the claim at surrogate proof (§13). A claim whose verb matches no row below is routed by the same test: *what would have to be true for this instrument to be able to see this claim being false?*

| Claim type (the verb) | Admissible | Does NOT count |
|---|---|---|
| **"What can this principal SEE?"** — visibility, authorization, tenancy, RLS | A **live read executed as the real principal, in both directions**: one principal who must see the row, one who must not, against the real security layer | A green suite, however mutation-verified · a read performed by a **bypass-capable** (`service_role`/superuser) or **mocked** client · a 404 from an endpoint (refusals are 404-shaped by design, so an endpoint is not a membership oracle) |
| **"Does the deployment ACCEPT this?"** — request/payload/schema conformance | The request issued **against the deployed target (or the real engine)** and observed at that boundary — the response the deployment actually returns | A mocked client (a mock encodes what we *believe* the deployment accepts, so it can only ever confirm our own belief) · a hand-written vendor fixture with no provenance — a vendor payload fixture is admissible only when **cited to the vendor's own field reference (URL + retrieval date on the fixture)** |
| **"Did the walk actually WRITE it?"** — persistence | A **pre-walk baseline query** plus a post-walk read-back **out of the datastore** | A screenshot of a success state · a post-walk read **with no baseline** (rows persist across seeds and fires, so stale rows read as a green pass) |
| **"Does it FIT / is it reachable / is it announced?"** — geometry, platform announcement | Measured on a **running screen from a baked build**: a **platform AX dump** (the OS tree assistive tech actually walks) **plus container-vs-content geometry at ≥3 widths, with the numbers in the artifact**, from a harness that refuses to print a number unless its subject is present | A **rule-engine pass** (an a11y engine evaluates the node it is handed and has no model of containment or overflow) · a **props-level** a11y assertion (props are not the platform tree; and jsdom performs no layout, so every `getBoundingClientRect` there is zeros and every geometric claim is an arithmetic model of the CSS rather than the CSS's behaviour) · an un-measured screenshot |
| **"Does a prompt change BEHAVIOUR?"** — generative surfaces | **Control-vs-treatment on the composed prompt with the shipped model, n reported** | A source-text assertion that the rule string is present in the prompt |

**Scars:** see `.speck/reference/evidence-valid-proof-examples.md` (principal / geometry / boundary).

**Rules:** measure magnitudes; green suites OK for correctness claims only.

### 2b. Typed citations — the closed vocabulary and the admissibility table

*§2a is the rule stated for a human reader. This is the same rule stated so a machine can apply it, and the two halves must not drift: `validate-evidence-citations.sh --check-contract <this file>` diffs the table below against the Speck-owned one compiled into the validator and reports `CITATION_TABLE_DRIFT.P2` when they disagree.*

**Syntax.** A typed citation is `<citation-type>:<path>[@<sha>]` — e.g. `live-probe:supabase/tests/webhook_claim_proof.sql@89468af1`. The prefix must be one of the tokens below, spelled exactly; a leading token that is not in the vocabulary is not a type (a bare `https://…` or a Windows drive letter is read as an untyped path, never as a bogus type). A citation with no recognized prefix is **legacy-untyped**: `CITATION_UNTYPED.P3` — a nudge, never a block, because every artifact authored before this section is untyped by construction and a P1 here would brick every project on upgrade day. Stamp what can be derived with `validate-evidence-citations.sh --stamp-types --write <path>`.

**The closed citation-type vocabulary.** Speck-owned. A project does not add tokens — an unknown token reads as untyped, so inventing one degrades to a nudge rather than manufacturing a false admissibility verdict.

| Token | The instrument | Where it already appears in this contract |
|---|---|---|
| `test` | A unit/integration suite run in the project's own harness. Mocks and props-level assertions live here. | §8 IMPL-GREEN; validation-report Gate Criteria (`test-output.txt`) |
| `mutation-guard` | A guard whose removal was **watched** to redden it — `mutate-guard.sh`, verdict `GUARD_MUTATION_PROVEN`. | validation-report §Mutation Record |
| `live-probe` | A request/read/write issued **against the deployed target or the real engine**, as a named principal, and observed at that boundary. | §2 "Real Supabase/Stripe/RevenueCat events"; §7; §8 Real-Integration Smoke Check |
| `db-catalog` | Introspection of the live datastore's catalog, or a **baselined** read-back out of the datastore. | §8 Live-Schema Parity Check (`validate-schema-drift.sh`), Real Write-Path Smoke Check |
| `ax-dump` | The **platform** accessibility tree from a baked build — the OS tree assistive tech walks, not props. | §2 "AXe screenshots and accessibility trees"; §6; §9 `ax-trees/` |
| `geometry` | Measured **container-vs-content** numbers from a running screen, at ≥3 widths, numbers in the artifact. | §2a row 4 |
| `capture` | A screenshot, recording, or LARP transcript. Evidence of *what was on screen*, adjudicated or not. | §6; §9 `screenshots/`, `larp-recordings/`, `transcripts/` |
| `device-walk` | A human attestation on a real device or the baked artifact. | §8 Verifiability Tiering; `larp-recordings/<sha>-human-attestation.md` |
| `model-eval` | Control-vs-treatment on the **composed** prompt with the **shipped** model, n reported. | §2a row 5 |
| `static` | A source-text, lint, type-check or grep assertion over the tree. Reads the source; never runs it. | §8 lint/type gates; `banned-language-lint.sh output` |

**The admissibility table.** Claim type → which citation types may discharge it. **Admissible is a whitelist**: a type absent from a row's Admissible cell is inadmissible for that claim and raises `PROBE_SUBSTRATE_MISMATCH.P1`. The third column names the ones that were earned by a shipped defect, so nobody re-litigates them.

| Claim type | Admissible citation types | Inadmissible here — and the scar that earned it |
|---|---|---|
| `correctness` | `test` `mutation-guard` `live-probe` `db-catalog` `static` `ax-dump` `geometry` `capture` `device-walk` `model-eval` | *(nothing — a green suite is the right and sufficient instrument for a correctness claim; this row can never fire)* |
| `visibility` | `live-probe` `db-catalog` `device-walk` | `test` · `mutation-guard` — an anon-key server client carries no JWT, so `auth.uid() = <col>` returned **zero rows for every user, always**, silently. Two mutation-verified suites could not see it; a live read as each principal settled it in one query. Also `static`, `capture` |
| `acceptance` | `live-probe` `db-catalog` `device-walk` | `test` — a **mocked client** encodes what we *believe* the deployment accepts, so it can only ever confirm our own belief. Only the real boundary can contradict it. Also `mutation-guard`, `static`, `capture` |
| `persistence` | `live-probe` `db-catalog` | `capture` — a screenshot of a success state is not a written row; and a post-walk read with **no pre-walk baseline** cannot tell a fresh write from a stale seed. Also `test`, `mutation-guard`, `static` |
| `fit` | `ax-dump` `geometry` `device-walk` | `test` — a **props-level a11y assertion** reads props, not the platform tree, and jsdom performs no layout. A rule engine is structurally blind to containment: axe was **0/0/0/0 and a11y 9/9, identical before and after** a grid amputated a column on every phone. Also `static`, `capture`, `mutation-guard` |
| `behaviour` | `model-eval` `device-walk` | `static` — asserting the rule string is **present in the source** of a prompt is not evidence the composed prompt changed what the shipped model does. Also `test`, `capture` |

*Unrouted claim types: report and continue (honest gap, not false P1).*

**Citation site:** table with both a `Claim*` column and an `Evidence`/`Citation`/`Discharge artifact`/`Proof`/`Substrate` column. Definition tables (§2a/§2b) use Admissible/Inadmissible headers so they stay inert.

| Claim type | Discharge artifact | Notes |
|---|---|---|
| `correctness` | `test:path/to/suite.test.ts@REPLACE_SHA` | example citation site — replace in product contracts |

## 3. Invalid Proof Sources (anti-proof)

Never accept: dev-server screenshots as launch proof; un-adjudicated captures; tests-pass-as-SHIP; mocks as live-service proof; skipped suites as green. Full anti-proof catalog: `.speck/reference/evidence-invalid-proof-examples.md`.

## 4. Required Runtime LARP / Integration Stress Tests

List JTBD walkthroughs + stress cases for THIS product. Prompt adversary per P1–P4. Examples: `.speck/reference/evidence-larp-stress-examples.md`.

| Test | Persona / principal | Pass condition | Evidence home |
|------|---------------------|----------------|---------------|
| REPLACE_BEFORE_SHIP: test-1 | | | |

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

| Gate ID | Command / Script | Stage | Domain | Scope | Subject | Canary | Waiver |
|---------|------------------|-------|--------|-------|---------|--------|--------|
| REPLACE_BEFORE_SHIP:unit-frontend | `npm run test` | pre-push | frontend-tests | `frontend/src/**` | `tests_collected>0` | — | — |
| REPLACE_BEFORE_SHIP:banned-language | `.speck/scripts/banned-language-lint.sh` | pre-commit | copy | `src/**,app/**,components/**` | `files>0` | — | — |
| REPLACE_BEFORE_SHIP:integration | `pytest tests/integration` | ci:push | backend | `backend/**` | `tests_collected>0` | — | — |
| speck:evidence-citations | `.speck/scripts/validation/validators/validate-evidence-citations.sh specs/` | manual | evidence | `specs/**` | `citations>0` | — | — |
| speck:probe-library | `.speck/scripts/validation/validators/validate-evidence-citations.sh --check-probe-library` | manual | evidence | `specs/projects/**` | `probe_classes>0` | — | — |

**Speck-owned standing rows.** The two `speck:` rows are **not project-authored and not project-deletable** — `seed-gate-registry.sh` re-emits them on every seed, after the recipe's own gates, so re-seeding a contract can never drop them. They are declared `manual` **honestly**: `seed-gate-registry.sh` runs both the moment it seeds or amends this contract, and `/audit`, `/epic-validate` and `/project-validate` run them on demand; nothing on the commit path invokes them yet, and declaring a stage they do not fire at is the exact divergence `validate-gate-liveness.sh` exists to catch. Both are **nudges** — they exit 0 without `--strict`, so a project that has not adopted typed citations or §11a is enumerated, never blocked.

**Stage** ∈ `pre-commit | pre-push | commit-msg | ci:push | ci:pull_request | manual`.
- `manual` = the contract honestly declares this gate off the automatic path (no divergence to detect).
- **Waiver** = `waived DEC-####` — the gate *should* be wired but a logged decision accepts it dark for now (the DEC must resolve in `project-decisions-log.md`, or `GATE_WAIVER_UNBACKED`).
- The sin the validator hunts is the silent third case: §6a says `pre-push` / `ci:` while the wiring says `manual` / nowhere — with **neither** a `manual` declaration **nor** a waiver. Either arm the gate or amend the contract; the sin is the divergence, not being off the fast path.

**Canary** (Speck v8.6, #88 Phase 2 — the *liveness* half). Wiring proves a gate is reachable; the canary proves it is **load-bearing**. `gate-liveness-probe.sh` (opt-in, `--require-liveness`) injects a deliberate defect in the gate's domain inside a throwaway git worktree, runs the gate, and asserts it goes **red for the right reason**. The Canary cell is a single **library key** (seeded from the recipe's `canary:` tag), NOT project-authored mutation code — it resolves to `.speck/scripts/validation/canaries/<key>.canary`, a Speck-owned+reviewed definition. Values:
- a library key (`banned-language` | `lint-error` | `unit-tripwire` | `a11y-role` | `integration-invariant` | `entitlement-gate`, …) — the gate is probed.
  - `entitlement-gate` (Domain `entitlement`) is the money-path row: flip the entitlement gate **open** and **every** revenue path's suite must go red. A suite that stays green with entitlement deleted **is** the defect — measured in the field at 170 passed / 0 failed after flipping one handler's `requireEntitlement` to `false`, because the handler tests injected their own pass-through guard. Entitlement **only** — never point it at a safety gate whose correct value is `false` (pin the always-requires and the never-may-require paths in one file so nobody "fixes" a crisis surface into a paywall).
- `exempt:<reason>` — deliberately un-probeable (destructive / infra-bound, e.g. an e2e or deploy gate); first-class, distinct from blank.
- `—` — un-probed-honest (default; never a finding).

Outcomes: **`GATE_LIVE`** (watched it fail on every injected surface), **`GATE_DISARMED.P1`** (baseline green, defect in the gate's required scope, gate *still* green — the one positive block; hard-blocks only at COMMERCIAL-RC/SHIP-RC), **`GATE_LIVENESS_UNVERIFIED.P2`** (couldn't apply/attribute the canary — unknown key, no green baseline, unsafe-to-probe, infra-bound; degrade-to-honest, caps the ship claim, never blocks dev). Fail-closed on **safety** (a destructive command is never executed) and on **claims**; degrade-to-honest on **applicability**. Runs at `/epic-validate`, `/project-validate`, on-demand at `/audit` — never on push or in the always-on `/recheck` shell.

**Scope + Subject** (Speck v10, #98 — the *vacuity* half). Wiring proves the gate runs; the canary proves it bites; neither answers **did it look at anything**. A gate can be correctly wired, correctly implemented, pass its canary, and inspect an empty corpus — output ✅, exit 0. Zero violations is only meaningful if something was there to violate them.
- **Scope** — the glob the gate is contracted to cover, **asserted at runtime, never inherited from a tool default**. `validate-gate-liveness.sh` resolves it against `git ls-files`; a scope matching zero tracked files is **`GATE_SCOPE_UNRESOLVABLE.P2`** on its own, before the gate is ever run. (Measured in the field: root-anchored `src/**` in a repo whose product lives under `frontend/src/**` matched 0 of 1194 tracked files while the gate reported ✅ on every commit.)
- **Subject** — the nonzero count the gate must observe before it may report PASS, or a named assertion: `files>0`, `tests_collected>0`, `not_error_boundary`, `rows_evaluated==rows_declared`.

The mechanism that makes both real is the **gate output contract**: every canonical gate prints, on *every* exit path,
```
SPECK_GATE_SCOPE=src/**,app/**   SPECK_GATE_SUBJECT=17   SPECK_GATE_PREDICATES=59
```
and `gate-liveness-probe.sh` reads **that** — out of the baseline run it already performs — instead of re-deriving scope from its own list. The third verdict follows: **`GATE_VACUOUS.P1`** when the gate exits 0 with `SUBJECT=0` while its scope resolves to tracked files it should have read, with a scope that resolves to *no* tracked file at all (it can never reach a subject), or with `PREDICATES=0` (it read files and compared them against nothing — this family's vacuity is usually a dead predicate set, not an empty corpus). Bounded by **`GATE_EMPTY_LEGITIMATE`** — `SUBJECT=0` on a *diff-scoped* run whose scope does resolve — a NOTE, never a finding: a staged commit touching no product file is honest. A gate publishing no telemetry is **`GATE_SCOPE_UNREPORTED.P3`**, so the residual guessing is countable rather than invisible.

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

Axes: CORRECT · ON-CONTRACT · FELT-GOOD · TASTE (non-collapsible). Full per-state criteria: `.speck/reference/evidence-readiness-gate-criteria.md`.

| State | Required evidence (summary) |
|-------|-------------------------------|
| NO-SHIP | Hard blocker open |
| IMPL-GREEN | Unit/integration + types/lint green |
| INTEGRATION-GREEN | Real round-trip per §7 service + live schema matches migrations |
| UX-RC / API-RC | Target-runtime LARP / walkthrough; FELT/TASTE as required |
| COMMERCIAL-RC | Billing/entitlements/support/legal + value-defensibility |
| SHIP-RC | Launch-build LARP (not dev server) |
| SHIP | Post-deploy smoke + healthcheck |

Never claim SHIP-RC from dev-server evidence. Cap with logged attempt when P3 applies.

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

### Four-Axis Ownership
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

## 11a. Standard Probe Library

*§11 above stays exactly as it is. Its P4 framing is correct and this section does not touch it: **do not grow §11 to close a gap.** §11a is a **different kind of object** — §11 is the adversary's imagination (open, un-enumerable, discharged by a logged attempt); §11a is a **closed, Speck-owned registry of eight recurring defect classes** that are discharge-**required**. Adding a row to §11 makes a longer list nobody discharges; adding a row here is a Speck change, not a project change.*

**Why.** Eight recurring substrate-mismatch classes. Closed Speck-owned registry — do not grow §11.

**Discharge:** typed citation per §2b for the row claim type, OR Exception. Exactly one.

**Exception values:** `—` (must discharge) · `n/a:<reason>` · `waived DEC-####`. Neither discharge nor exception → `PROBE_UNDECLARED.P1`. Do not delete rows.

| Probe ID | Class | Claim type | Admissible substrate | Required negative controls | Discharge artifact | Exception |
|----------|-------|------------|----------------------|----------------------------|--------------------|-----------|
| PROBE:provenance | P1 | `behaviour` | render site + generator stamp + the prompt's own exemplars, judged control-vs-treatment on the composed prompt with the shipped model | rendered-with-degraded-provenance · exemplar re-read (deleting the exemplar must not leave the test green) | — | — |
| PROBE:honest-label | P2 | `persistence` | the write's observed outcome read back out of the datastore against a pre-walk baseline | total-failure render · partial-failure render · the three renders differ | — | — |
| PROBE:second-actor | P3 | `visibility` | A writes, teardown, B signs in on the same install, offline — once per enumerated persistence layer | signOut vs deleteAccount compared field-for-field · launch-with-data-and-no-owner-record | — | — |
| PROBE:money-path | P4 | `acceptance` | the real engine as the applying principal, one run per revenue path | entitlement gate flipped and every revenue path goes red · vendor fixture cited to the vendor's field reference · per-user serialized claim write · one declared fail-posture · bounded worst case per tap | — | — |
| PROBE:named-clock | P5 | `correctness` | an AST/lint rule over write handlers, cache fills and fixtures, plus the date-sensitive suites run under two timezones | a non-UTC TZ run · allowlist entries that name the audience | — | — |
| PROBE:geometry-ax | P6 | `fit` | a baked build: platform AX dump plus container-vs-content geometry at 3 or more widths, numbers in the artifact | adjacent-target overlap · expected-cell presence · page overflow | — | — |
| PROBE:substrate | P7 | `correctness` | §2b parity of this contract against Speck's compiled admissibility table | the parity run reports CITATION_TABLE_PARITY over a non-empty row set | — | — |
| PROBE:migration-dirt | P8 | `acceptance` | the migration applied forward on a throwaway seeded to the target's real dirty shape | pre-state REJECTED · boundary cases still refuse · one migration head after the merge | — | — |

*The table ships **undischarged on purpose**. A template whose own boilerplate satisfies its validator is the exact vacuity this repo has shipped twice: the green would mean "nobody edited the template," not "the class was proved." So an unedited contract raises eight `PROBE_UNDECLARED.P1` — which is the honest starting state, and why the gate runs as a nudge (exit 0) rather than a block.*

### Scar rationale (JIT)

Read `.speck/reference/evidence-probe-scars.md` when inventing probes or discharging §11a.

### How this section is validated

`validate-evidence-citations.sh --check-probe-library <this file>` reads the table above and reports, in the established vocabulary:

- **`PROBE_DISCHARGED`** — a typed, admissible citation. **`PROBE_EXCEPTION_DECLARED`** — a backed `n/a:`/`waived`.
- **`PROBE_UNDECLARED.P1`** — a class with neither a discharge artifact nor a declared exception, **including a class deleted from the table**. The silent third case §6a already hunts.
- **`PROBE_SUBSTRATE_MISMATCH.P1`** — the discharge citation's type is not in §2b's Admissible set for this row's claim type. A pure lookup: claim type → citation type → admissible?
- **`PROBE_SUBSTRATE_UNKNOWN.P3`** — a discharge artifact whose type is **unknown** (untyped, or a prefix outside the closed vocabulary). **Unknown never convicts**, and that is a deliberate decision, not an oversight: admissibility is a property of the *pair*, so an unknown type means the pair is incomplete, and a validator that resolved incomplete to *inadmissible* would turn every un-stamped project red on upgrade day while claiming to have proved something it never computed. `CITATION_UNTYPED` is P3 for the same reason. Stamp with `--stamp-types --write`, then the real verdict becomes computable.
- **`PROBE_NA_UNBACKED.P2`** — `n/a` with no reason, or `waived` with no resolving DEC.
- **`PROBE_LIBRARY_DRIFT.P2`** — a Speck-owned cell (Class / Claim type / Admissible substrate / Required negative controls) was edited, or an unrecognised Probe ID appears. Without this, weakening a row's claim type to `correctness` would silently dissolve every mismatch it could ever raise — the same reason §2b is parity-checked.
- **`PROBE_LIBRARY_ABSENT.P3`** — no §11a at all. Scaffold it with `validate-evidence-citations.sh --scaffold-probe-library --write <this file>`.

Blocking posture matches `GATE_DISARMED.P1`: hard-blocks only at **COMMERCIAL-RC / SHIP-RC**; below that it enumerates and warns. The gate exits 0 without `--strict`, so wiring it can never turn a repo red on the day it lands.

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

- Platforms + valid/invalid proof filled
- §2a/§2b present and parity-clean
- §11a rows discharged or excepted
- Readiness criteria match claimed state
- No REPLACE_BEFORE_SHIP left for ship claims
