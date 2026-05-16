---
speck_version: 7.0
artifact_type: product-contract
play_levels: [build, platform]
---

# Product Contract: [PROJECT_NAME]

<!--
THIS IS THE CENTER OF GRAVITY FOR PROMISE.

In Speck v7, the product-contract.md replaces what v6 scattered across:
- project.md (vision)
- ux-strategy.md (voice/tone)
- constitution.md (principles)
- domain-model.md (terminology)
- tone-of-voice.md (banned phrases — was bespoke in v6)
- magic-moments.md (was bespoke in v6)

Every downstream artifact (epic, story, validation, audit) MUST reference this contract.
Banned language here is enforced by .speck/scripts/banned-language-lint.sh.

If you find yourself wanting to write a value-judgment in another doc (what's "premium," what's "on-brand," what users would "pay for"), that judgment lives HERE — once — and is referenced elsewhere.

200-line target. If you can't say it in 200 lines, your contract is too vague.

PLACEHOLDER CONVENTION (Speck v7.2+):
  Any value that MUST be replaced before this artifact can claim ship-readiness
  is marked  REPLACE_BEFORE_SHIP: <hint>
  Generic [bracketed] hints elsewhere are guidance — agents fill them in but they
  don't gate ship. The REPLACE_BEFORE_SHIP markers ARE gates: /speck-recheck
  greps for them and refuses to mark the artifact "real" while any remain.
-->

**Project**: REPLACE_BEFORE_SHIP: PROJECT_NAME
**Project ID**: `REPLACE_BEFORE_SHIP: project-id`
**Play Level**: REPLACE_BEFORE_SHIP: build | platform
**Speck Version**: 7.0.0
**Last Updated**: REPLACE_BEFORE_SHIP: YYYY-MM-DD

---

## 1. The Paid Promise

*The single sentence that describes what the user is paying for. Not what we built — what they experience. This is the bar every downstream decision is measured against.*

**Promise**: REPLACE_BEFORE_SHIP: Single sentence. Specific. Outcome-focused. Not a feature list.

*Example: "An adaptive AI coach that reasons from first principles about my body and adapts every session locally — so I trust it more after every workout."*

*Anti-example (too vague): "An AI fitness app."*
*Anti-example (feature list): "An app that generates workouts and tracks progress."*

---

## 2. Primary Persona

**Who pays**: [Specific persona. Demographics, life context, urgency, current alternative.]

**JTBD they hire this product for**:
> When [situation], I want to [job], so that I can [outcome].

**Current alternatives they're "firing"**: [What they're using today that this replaces]

**Willingness to pay**: [Price tier — explicit number if known, "premium" / "freemium" / "free" otherwise]

---

## 3. The Differentiator

*The wedge that makes this product not interchangeable. One sentence.*

**Core differentiator**: REPLACE_BEFORE_SHIP: One sentence. The thing that's true of THIS product and not its alternatives.

*Example: "Most fitness apps prescribe templates; Streb adapts the dose locally per exercise based on your last set's response."*

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

## 4. JTBD Scorecard

*Every important user flow must satisfy ALL five dimensions. Functional alone is not enough for paid products.*

| Dimension | Definition | How this product delivers it |
|-----------|------------|------------------------------|
| **Functional** | What must the user accomplish? | [Specific outcome] |
| **Emotional** | How must the user feel? | [Specific emotion + why] |
| **Social** | What would they proudly show / tell someone? | [Shareable moment / status signal] |
| **Trust** | What must feel coherent, safe, transparent, reversible? | [Trust mechanism] |
| **Commercial** | Why pay now? Why not churn? Why pay more? | [Willingness-to-pay trigger + retention hook] |

Story validation fails if a user-facing story has no evidence for at least the functional + emotional + commercial dimensions.

---

## 5. Magic Moments

*The surfaces where the user would say "wow, this gets me." The product earns its price here. List 3-7. Each must be testable in runtime LARP.*

### Magic Moment 1: REPLACE_BEFORE_SHIP: Name
- **Surface**: REPLACE_BEFORE_SHIP: Screen / interaction / output
- **Trigger**: REPLACE_BEFORE_SHIP: What action / context creates the moment
- **Content beats**: REPLACE_BEFORE_SHIP: What happens in sequence to land the moment
- **Target emotional response**: REPLACE_BEFORE_SHIP: User thinks "<quoted internal reaction>"
- **Validation step**: REPLACE_BEFORE_SHIP: Specific LARP scenario that proves the moment lands

### Magic Moment 2: REPLACE_BEFORE_SHIP: Name
- **Surface**: REPLACE_BEFORE_SHIP
- **Trigger**: REPLACE_BEFORE_SHIP
- **Content beats**: REPLACE_BEFORE_SHIP
- **Target emotional response**: REPLACE_BEFORE_SHIP
- **Validation step**: REPLACE_BEFORE_SHIP

*(repeat for each magic moment)*

---

## 6. Public Language

*The user-visible vocabulary. Internal/implementation names may differ; user-facing copy MUST use these terms.*

### Canonical Domain Terms

| Internal concept | English UI term | [Locale 2] UI term | Notes |
|------------------|-----------------|--------------------|-------|
| [Concept] | [Term] | [Term] | [Constraints, e.g., "use exactly this phrase in onboarding"] |

### Voice Principles (3-5 lines)

- **Voice**: [e.g., "Calm, competent, specific — not cheerleading. Like a thoughtful coach, not a marketing email."]
- **Sample-good copy**: [Concrete example of good copy for a typical UI string]
- **Sample-bad copy**: [Concrete example of bad copy → rewritten as good]

### Magic-moment Copy Rules

- **Loading state voice**: [e.g., "Confident, not apologetic"]
- **Error state voice**: [e.g., "Honest, specific, with a clear recovery path"]
- **Empty state voice**: [e.g., "Invitational, never blaming the user"]

---

## 7. Banned Language

*Words and phrases that MUST NEVER appear in user-visible copy. Enforced by `banned-language-lint.sh`. Each term gets a reason and a preferred replacement.*

| Banned Term | Where it appears | Why it's banned | Use instead |
|-------------|-------------------|-----------------|-------------|
| [Term] | [UI / AI prompts / fallbacks] | [Reason — e.g., "drifts toward generic SaaS pitch"] | [Replacement term] |
| [Term] | [Where] | [Why] | [Replacement] |

### Banned Phrase Classes (categorical)

- ❌ Investor pitch language ("revolutionize", "best-in-class", "10x")
- ❌ Technical architecture language ("our backend", "API", "database") in user-facing surfaces
- ❌ QA/simulator/evidence language ("test mode", "QA", "fixture", "simulator")
- ❌ Generic AI cheerleading ("Great job!", "Awesome!", "You're crushing it!" — for products with calm-competent voice)
- ❌ Over-explaining trust instead of earning it ("rest assured your data is safe...")
- ❌ Placeholder/roadmap language ("coming soon", "TBD")

Add product-specific bans here as they're discovered.

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

*[as of SHA `<git_sha_short>` | verified `<date>` | speck v7.0.0]*
