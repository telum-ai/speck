---
speck_version: 8.0
template_version: "8.0.0"
artifact_type: product-contract
play_levels: [build, platform]
---

# Product Contract: [PROJECT_NAME]

<!--
THIS IS THE CENTER OF GRAVITY FOR PROMISE.

Consolidates what may otherwise be scattered across project vision, UX strategy,
constitution, domain terminology, tone-of-voice, and magic moments into one contract.

Every downstream artifact (epic, story, validation, audit) MUST reference this contract.
Banned language here is enforced by .speck/scripts/banned-language-lint.sh.

If you find yourself wanting to write a value-judgment in another doc (what's "premium," what's "on-brand," what users would "pay for"), that judgment lives HERE — once — and is referenced elsewhere.

200-line target. If you can't say it in 200 lines, your contract is too vague.

PLACEHOLDER CONVENTION:
  Any value that MUST be replaced before this artifact can claim ship-readiness
  is marked  REPLACE_BEFORE_SHIP: <hint>
  Generic [bracketed] hints elsewhere are guidance — agents fill them in but they
  don't gate ship. The REPLACE_BEFORE_SHIP markers ARE gates: /speck-recheck
  greps for them and refuses to mark the artifact "real" while any remain.
-->

**Project**: REPLACE_BEFORE_SHIP: PROJECT_NAME
**Project ID**: `REPLACE_BEFORE_SHIP: project-id`
**Project Archetype**: REPLACE_BEFORE_SHIP: consumer_product | b2b_saas | internal_tool | infra_service | backend_api
**Play Level**: REPLACE_BEFORE_SHIP: build | platform
**Speck Version**: REPLACE_BEFORE_SHIP: Speck version
**Last Updated**: REPLACE_BEFORE_SHIP: YYYY-MM-DD

---

## 1. The Paid Promise / Operational SLA

*The single sentence that describes what the user gets or pays for. Not what we built — what they experience or can rely on. This is the bar every downstream decision is measured against.*

* **WHEN: consumer_product / b2b_saas / internal_tool**: Write the **Value Promise** (what user pays for/experiences).
* **WHEN: infra_service / backend_api**: Write the **Operational SLA / Capability Promise** (what calling services can guarantee from this service).

**Promise**: REPLACE_BEFORE_SHIP: Single sentence. Specific. Outcome-focused or service-boundary SLA. Not a feature list.

*Example (Value): "An adaptive AI coach that reasons from first principles about my body and adapts every session locally — so I trust it more after every workout."*
*Example (SLA): "To guarantee sub-50ms query latency and transaction-level durability for all booking transactions under peak concurrent load (10k ops/sec)."*

---

## 2. Primary Persona / Consumer

* **WHEN: consumer_product / b2b_saas / internal_tool**: The paying or active human user.
* **WHEN: infra_service / backend_api**: The primary consumer of this service (e.g., the platform developer, downstream calling services, or system operator).

**Who pays / consumes**: [Specific persona or service. Life/operational context, urgency, alternatives.]

**JTBD they hire this product / service for**:
> When [situation/system state], I/the service want to [job/operation], so that [outcome/guarantee].

**Current alternatives they're "firing"**: [What they're using/doing today that this replaces/optimizes]

**Willingness to pay / Cost of Failure**: [Price tier / Resource budget or Cost of Downtime]

### 2a. Value Defensibility — WTP vs the free/DIY substitute (P2, #74)

*A price is a claim; under P2 it needs a mechanism. For any paid product (or paid API), the price is only defensible if it survives the substitute a rational buyer already has — most acutely **free general-purpose AI** (ChatGPT/Claude/Gemini) plus 15 minutes, a spreadsheet, or a free tier of a competitor.*

* **WHEN: consumer_product / b2b_saas / internal_tool / paid APIs**:

| Free / DIY substitute the buyer already has | What they'd get from it for $0 | Why THIS product is still worth paying for (the defensible wedge) |
|---|---|---|
| Free general-purpose AI (ChatGPT/Claude) + effort | REPLACE_BEFORE_SHIP: honest account of what the free path delivers | REPLACE_BEFORE_SHIP: the durable reason this beats it — NOT "better UX" alone |
| [Free tier / open-source / manual process] | [What it delivers] | [Defensible wedge] |

**Buyer's real reference price**: REPLACE_BEFORE_SHIP: what the skeptical buyer *actually* compares to (usually $0, not a competitor's paid tier).
**Defensible-wedge verdict**: REPLACE_BEFORE_SHIP: one sentence a skeptical buyer who already has free AI would accept as the reason to pay. If the only honest answer is "convenience," the price is not yet defensible — fix the product, not this cell.

> **Reconcile with §3 (#80).** This wedge is the deepest defensible truth about the product. §3's Core differentiator must never lead with a claim *weaker* than this. `market-reconcile-check.sh` emits `WEDGE_DRIFT` when §3 is empty while a wedge exists here, when this analysis self-flags §3 as thin/copyable, or when §3 and this wedge barely overlap — and `validate-product-contract.sh` blocks the contract stamp on it.

* **WHEN: infra_service / backend_api**: (May skip if not independently priced; otherwise state build-vs-buy defensibility vs the buyer running the OSS/self-hosted equivalent.)

---

## 3. The Differentiator

*The wedge that makes this product not interchangeable. One sentence.*

**Core differentiator**: REPLACE_BEFORE_SHIP: One sentence. The thing that's true of THIS product and not its alternatives.

*Example: "Most fitness apps prescribe templates; Streb adapts the dose locally per exercise based on your last set's response."*

> **Market recheck (P2, #80).** The differentiator — and any "no competitor does X" claim — rots: it can be true when written and false weeks later. At lock, `stamp-market.sh --baseline` writes an inline `*[market-verified: unverified | staged <date>]*` line directly under **Core differentiator** above; `/speck-frontier-scan --product` later re-stamps it with a dated, **sourced** verdict. Absolute/exclusivity claims get a tight clock (default 30 days); generic differentiators an archetype cadence (45 / 90). **Never hand-edit the stamp** — only `stamp-market.sh` writes it, and only when a real scan report backs it. `market-staleness-check.sh` flags a stale/unverified claim as `MARKET_DRIFT`.

### 3a. Anti-Differentiators ("We are NOT...")

*What the product must never feel like, even if competitors are. Three to five sentences finishing "We are not..."*

- We are NOT [thing 1]. [Why this matters — what failure mode this prevents.]
- We are NOT [thing 2]. [Why.]
- We are NOT [thing 3]. [Why.]

*Example: "We are NOT a generic workout generator. Templates aren't the product; adaptation is."*

### 3b. Inspiration Sources (principle, not template)

*For each external inspiration, capture the PRINCIPLE we draw, not the implementation we copy.*

| Source | Principle we draw | What we explicitly do NOT do |
|--------|-------------------|-------------------------------|
| [Source 1, e.g., brd.no] | [The principle, e.g., "AI-first beats AI-bolted-on"] | [What we don't do, e.g., "We are not meeting-centric"] |
| [Source 2] | [Principle] | [What we don't do] |

---

## 4. JTBD Scorecard / Operational Invariants Scorecard

* **WHEN: consumer_product / b2b_saas / internal_tool**: Fill out the **JTBD Scorecard**. Every important user flow must satisfy ALL five dimensions. Functional alone is not enough for premium experiences.
* **WHEN: infra_service / backend_api**: Fill out the **Operational Invariants Scorecard**.

### Option A: JTBD Scorecard (for UI/Human-facing products)

| Dimension | Definition | How this product delivers it |
|-----------|------------|------------------------------|
| **Functional** | What must the user accomplish? | [Specific outcome] |
| **Emotional** | How must the user feel? | [Specific emotion + why] |
| **Social** | What would they proudly show / tell someone? | [Shareable moment / status signal] |
| **Trust** | What must feel coherent, safe, transparent, reversible? | [Trust mechanism] |
| **Commercial** | Why pay now? Why not churn? Why pay more? | [Willingness-to-pay trigger + retention hook] |

Story validation fails if a user-facing story has no evidence for at least the functional + emotional + commercial dimensions.

### Option B: Operational Invariants Scorecard (for Infra/Backend)

| Dimension | Definition | How this service guarantees it |
|-----------|------------|--------------------------------|
| **Latency** | What is the latency boundary under load? | [e.g., P99 <= 50ms under peak 5k rps] |
| **Throughput** | What is the throughput capacity? | [e.g., Handles up to 10k rps write volume] |
| **Durability / Integrity**| What guarantees transaction success? | [e.g., PostgreSQL WAL sync + zero partial-write leakages] |
| **Resiliency / Failover** | How does it behave when dependencies fail? | [e.g., Circuit-breakers to fallbacks within 200ms] |
| **Security / Compliance** | What are the absolute access rules? | [e.g., Strict Row-Level Security + zero credentials in logs] |

---

## 5. Magic Moments / Operational Milestones

*The surfaces where the system demonstrates exceptional capability, premium feel, or bulletproof execution.*

* **WHEN: consumer_product / b2b_saas / internal_tool**: List the **Magic Moments** where the user says "wow, this gets me." Each must be testable in runtime LARP.
* **WHEN: infra_service / backend_api**: List the **Operational Milestones** (e.g., graceful recovery from DB disconnect, sub-millisecond hot-path caching hits, exact rate-limiting blocks).

### Magic Moment / Milestone 1: REPLACE_BEFORE_SHIP: Name
- **Surface / System Boundary**: REPLACE_BEFORE_SHIP: Screen / interaction / endpoint / system action
- **Trigger**: REPLACE_BEFORE_SHIP: What action / context / load state creates this moment
- **Content / Execution beats**: REPLACE_BEFORE_SHIP: What happens in sequence to land this moment/milestone
- **Target Response**: REPLACE_BEFORE_SHIP: User thinks "<reaction>" OR Operator logs verify "<exact behavior>"
- **Validation step**: REPLACE_BEFORE_SHIP: Specific LARP scenario or integration stress test that proves it works

### Magic Moment / Milestone 2: REPLACE_BEFORE_SHIP: Name
- **Surface / System Boundary**: REPLACE_BEFORE_SHIP
- **Trigger**: REPLACE_BEFORE_SHIP
- **Content / Execution beats**: REPLACE_BEFORE_SHIP
- **Target Response**: REPLACE_BEFORE_SHIP
- **Validation step**: REPLACE_BEFORE_SHIP

*(repeat for each magic moment)*

---

## 6. Public Language / API & System Taxonomy

*The canonical vocabulary and style guidelines. Internal/implementation names may differ, but consuming layers/users must interact with these terms.*

* **WHEN: consumer_product / b2b_saas / internal_tool**: Fill this out as **Public Language** (user-visible terminology, voice, and copy).
* **WHEN: infra_service / backend_api**: Fill this out as **API & System Taxonomy** (naming conventions of endpoints, payload fields, DB columns, and system entities).

### Option A: Public Language (for UI/Human-facing products)

### Canonical Domain Terms

| Internal concept | English UI term | [Locale 2] UI term | Notes |
|------------------|-----------------|--------------------|-------|
| [Concept] | [Term] | [Term] | [Constraints, e.g., "use exactly this phrase in onboarding"] |

### Voice Principles (3-5 lines)

- **Voice**: [e.g., "Calm, competent, specific — not cheerleading. Like a thoughtful coach, not a marketing email."]
- **Sample-good copy**: [Concrete example of good copy for a typical UI string]
- **Sample-bad copy**: [Concrete example of bad copy → rewritten as good]

### Human Language Pass Guidelines
*Static phrase checks are necessary but insufficient. Every screen must pass a human-language review.*
- **Cringe Test:** Could the target user read this aloud without cringing?
- **Domain Authenticity:** Does it sound like a practitioner in the domain, or does internal methodology/technical jargon leak into the UI?
- **AI Copy Governance:** AI-generated user-facing text is **governed product copy** and must respect the exact same voice contract as static UI. No generic AI cheerleading.

### Magic-moment Copy Rules

- **Loading state voice**: [e.g., "Confident, not apologetic"]
- **Error state voice**: [e.g., "Honest, specific, with a clear recovery path"]
- **Empty state voice**: [e.g., "Invitational, never blaming the user"]

### Option B: API & System Taxonomy (for Infra/Backend)

### Canonical System Terms

| Concept / Domain | API Payload Key | DB Table/Column | Protocol / Serialization rules |
|------------------|-----------------|-----------------|--------------------------------|
| [e.g. Booking] | `booking_id` (snake_case) | `bookings.id` (UUID) | ISO 8601 strings for timestamps |

### Endpoint Naming Style

- **Conventions**: [e.g., RESTful resource pluralization, lower-kebab-case URLs. E.g., `GET /v1/user-profiles`]
- **Standard Error Shape**: [e.g., `{ "error": { "code": "INVALID_STATE", "message": "Short description", "details": {} } }`]

---

## 7. Banned Language / System Anti-Patterns

*Absolute prohibitions. For UI products, these are forbidden user-visible terms. For backend/infra, these are strict system/code anti-patterns.*

* **WHEN: consumer_product / b2b_saas / internal_tool**: Fill this out as **Banned Language** (user-visible terms, enforced by `banned-language-lint.sh`).
* **WHEN: infra_service / backend_api**: Fill this out as **Banned System Anti-Patterns / Anti-Conventions** (forbidden architecture/payload practices, e.g., camelCase payload keys when snake_case is required, leaking DB error stacks, or raw SQL queries).

### Option A: Banned Language (for UI/Human-facing products)

| Banned Term | Where it appears | Why it's banned | Use instead |
|-------------|-------------------|-----------------|-------------|
| [Term] | [UI / AI prompts / fallbacks] | [Reason — e.g., "drifts toward generic SaaS pitch"] | [Replacement term] |

### Banned Phrase Classes (categorical)

- ❌ Investor pitch language ("revolutionize", "best-in-class", "10x")
- ❌ Technical architecture language ("our backend", "API", "database") in user-facing surfaces
- ❌ QA/simulator/evidence language ("test mode", "QA", "fixture", "simulator")
- ❌ Generic AI cheerleading ("Great job!", "Awesome!", "You're crushing it!" — for products with calm-competent voice)
- ❌ Over-explaining trust instead of earning it ("rest assured your data is safe...")
- ❌ Placeholder/roadmap language ("coming soon", "TBD")

### Option B: Banned System Anti-Patterns (for Infra/Backend)

| Prohibited Practice / Pattern | Scope / Where | Why it's banned | Use instead / Safe practice |
|--------------------------------|---------------|-----------------|-----------------------------|
| Leaking DB raw exceptions | API error responses | Security vulnerability & bad DX | Map to sanitized REST error codes |
| camelCase payload attributes | JSON serialize/deserialize | Violates snake_case schema convention | Convert using Pydantic or custom marshaller |
| Unbounded raw queries | Repository layer | Performance risk; database locks | Always enforce limit/offset / pagination |

### Categorical System Bans

- ❌ Direct DB mutations without migrations
- ❌ Hardcoded environment credentials (use SSM / Vault / Vault Secret injected env)
- ❌ Shared state / singleton concurrency blocks in stateless API tasks
- ❌ Un-versioned API endpoints on public interfaces (always prefix e.g., `/v1/`)

---

## 8. AI Behavior Contract *(only if AI is user-visible)*

*Required for any product where AI output is shown to or interacts with the user.*

### Per AI Surface

For each user-visible AI surface:

#### Surface: [Name, e.g., "Coach transcript"]

- **Required context inputs**: [What the model MUST consume — list explicitly]
- **Required output shape**: [Structure — e.g., "direct answer + one proof point from user data + one next action"]
- **Required tone**: [e.g., "Brief. Specific. Cite their data, not generic best practice."]
- **Must cite**: [Specific user data the output must reference]
- **Must avoid**: [Generic filler — explicit anti-patterns]
- **Tool calls allowed**: [Which]
- **Tool calls forbidden**: [Which]
- **Bad-answer examples**: [3+ concrete examples of what the model must NOT produce]
- **Good-answer examples**: [3+ concrete examples of model output that lands]
- **Transcript tests required**: [How we assert quality programmatically]
- **LARP prompts required**: [Persona-based runtime checks]

---

## 9. Longitudinal Axes *(only if product adapts over time)*

*Required for products with learning, adaptation, personalization, habit formation, coaching, analytics, or progress over time.*

### Signal -> Reaction Ledger
*Every collected user signal must produce a reaction or intentional non-use. Prevents "AI bolted onto a tracker" where data is collected but never used.*

| Signal Collected | Where Captured | Where it Changes Product Behavior | Where User Can See/Edit | Where in Export/Delete | Reason if Intentionally Unused |
|------------------|----------------|-----------------------------------|-------------------------|------------------------|--------------------------------|
| [e.g. Skipped workout] | [Activity log] | [AI coach adjusts next workout dose] | [Coach chat transcript] | [Data export JSON] | |
| [e.g. Pain feedback] | [Post-workout] | [Capped intensity on joint] | [Settings -> Limits] | [Data export JSON] | |

### Adaptation Axes

| Axis | Detection signals | Variations | Override paths | Per-variation success criteria |
|------|-------------------|------------|----------------|--------------------------------|
| [Axis name] | [What signals trigger adaptation] | [What changes] | [How user can override] | [How we know each variation works] |

### Longitudinal Validation Chapters

*Named chapters the validation suite must walk through. Each is a multi-week scenario.*

| Chapter | Duration | Scenario | Cross-surface invariants |
|---------|----------|----------|---------------------------|
| Day 0 onboarding | 1 day | [Fresh user does initial setup] | [What must be consistent everywhere] |
| Week 1 consistency | 7 days | [Habit formation] | [Invariants] |
| First PR | 1-3 weeks | [Achievement moment] | [Invariants] |
| Plateau | week 3-4 | [Stagnation] | [Invariants] |
| Disruption | varies | [Travel / sickness / break] | [Invariants] |
| Return after gap | varies | [Re-engagement] | [Invariants] |
| Long-term | week 12+ | [Transformation proof] | [Invariants] |

---

## 10. Trust Moments

*Explicit moments where the product earns or loses trust. Each gets a validation criterion.*

| Trust Moment | What happens | How user trust is earned | Loss-of-trust failure mode |
|--------------|--------------|--------------------------|----------------------------|
| First credential ask | [When] | [Reason / restraint] | [What makes it feel intrusive] |
| First mutation suggestion | [When] | [How transparent] | [What makes it feel sneaky] |
| First payment | [When] | [Clarity / restraint] | [What makes it feel pushy] |
| First failure | [When something breaks] | [Honesty / recovery path] | [What makes it feel broken] |

---

## 11. Decision Framework (when this contract conflicts with other priorities)

*When ship dates pressure us, when scope creeps, when easier paths beckon — what do we hold?*

- **Always preserve**: [What we never compromise — e.g., "the differentiator", "trust"]
- **Trade thoughtfully**: [What can flex with rationale]
- **De-prioritize**: [What we explicitly defer until promise is intact]

---

## 12. Evidence Required to Claim Success

*Cross-reference to `evidence-contract.md` — what counts as proof that this contract is delivered.*

- Functional delivery: [pointer to evidence-contract.md section]
- Emotional delivery: [pointer]
- Trust delivery: [pointer]
- Commercial delivery: [pointer]
- Magic-moment delivery: [pointer]
- Banned-language enforcement: `.speck/scripts/banned-language-lint.sh` passes against full product surface

---

## Review Checklist

### Clarity Check
- [ ] Paid promise is one sentence and outcome-focused
- [ ] Differentiator is one sentence; alternatives don't satisfy it
- [ ] §3 differentiator is at least as defensible as the §2a wedge; the `market-verified` stamp is present and current for any "no competitor does X" claim
- [ ] Anti-differentiators name specific failure modes
- [ ] Each magic moment has a validation step
- [ ] Each banned term has a reason and a replacement

### Completeness Check
- [ ] JTBD scorecard has all 5 dimensions populated
- [ ] Public language covers all canonical domain terms
- [ ] Banned language has at least 5 product-specific entries (categorical bans plus specifics)
- [ ] AI behavior contract present (if AI is user-visible)
- [ ] Longitudinal axes present (if product adapts over time)

### Linkage Check
- [ ] References `evidence-contract.md` for proof requirements
- [ ] Will be referenced by every epic.md, story spec.md, validation report

---

*[as of SHA `<git_sha_short>` | verified `<date>` | speck]*
