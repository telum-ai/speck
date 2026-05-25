---
speck_version: 7.0
depends_on: []         # e.g., [S001, S003]
blocks: []             # e.g., [S005]
persona: [persona-id]  # primary persona this story serves
readiness_target: [IMPL-GREEN | UX-RC | COMMERCIAL-RC | SHIP-RC | SHIP]
---

# Story: [STORY NAME]

**Story ID**: `S###-story-name`
**Created**: [DATE]
**Status**: Specified
**Input**: [User description]

---

## 1. Experience (What the user lives)

*This section comes first because the user lives in the experience, not in the data model.*

### 1a. JTBD Context

**When** [situation/trigger], the [persona-id] wants to [job], **so that** they can [outcome statement: direction + measure + object].

Cross-reference: `product-contract.md` — primary persona + magic moments.

### 1b. Primary User Story

As a [persona-id], I want to [action] so that I can [outcome].

### 1c. Felt Quality (How the user feels)

| Surface | Entry emotional state | Target felt outcome | Banned feelings |
|---------|----------------------|--------------------|--------------------|
| [screen/step name] | [What they bring in] | [What they leave with] | [Feelings the experience must NOT produce] |

### 1d. Magic Moments Tied to This Story

*Which magic moments from `product-contract.md` does this story deliver? Each gets a verification step.*

- [ ] Magic Moment: [Name from product-contract.md]
  - Surface: [Where it lands]
  - Verification: [LARP step that proves it]

---

## 2. Acceptance LARP (How we prove the experience works)

*The acceptance criteria are LARP-shaped. Each scenario is captured against the running build, not against the spec.*

### 2a. Required Personas to LARP

| Persona | Flow | Build artifact | Evidence required |
|---------|------|----------------|-------------------|
| [persona-id] | [flow name] | [per evidence-contract.md] | screenshots, AX tree, taste notes |

### 2b. Acceptance Scenarios

#### Scenario: [Primary success path]
- **GIVEN** [initial state in the actual runtime — not abstract "data exists" but "the running build, with X user, in Y state"]
- **WHEN** [user action]
- **THEN** [expected outcome — visible in screenshot/AX tree/transcript]
- **AND** [additional outcomes]
- **EVIDENCE** [screenshot path or AX-tree path or transcript line]

#### Scenario: [Alternative path]
- **GIVEN** ...
- **WHEN** ...
- **THEN** ...
- **EVIDENCE** ...

#### Scenario: [Recovery from error]
- **GIVEN** ...
- **WHEN** ...
- **THEN** ...
- **EVIDENCE** ...

---

## 3. Evidence Required

*What artifacts must `/larp` and `/audit` produce for this story to advance through readiness states?*

| Evidence type | Required for state | Path / convention |
|---------------|--------------------|--------------------|
| Screenshot at primary screen | UX-RC | `screenshots/<sha>-primary.png` |
| AX tree of primary screen | UX-RC | `ax-trees/<sha>-primary.xml` |
| Persona LARP findings | UX-RC | `larp-recordings/<sha>-<persona>-findings.md` |
| Adversarial probe results | SHIP-RC | `audit-report.md` adversarial section |
| Banned-language scan output | UX-RC | `audit-report.md` banned-language section |

---

## 4. Adversarial Cases (What must NOT happen)

*Inverts the spec. For every "should do X", list "must never do not-X under Y conditions". Audit uses this directly.*

| Condition | Must NOT happen | Probe used to verify |
|-----------|-----------------|----------------------|
| Malformed input | Crash | Send malformed input, assert clear error |
| Network drop mid-flow | Partial write | Inject drop at write point, assert atomicity |
| Concurrent same-user update | Silent data loss | Run 2 writes concurrently, assert deterministic outcome |
| Banned term reaches user | UI shows banned word | `banned-language-lint.sh` against captured copy |

---

## 5. Failure-Modes Handled

*For each external dependency: how does this story behave when it fails?*

| Dependency | Failure mode | Behavior | Verified by |
|------------|--------------|----------|-------------|
| [e.g., Auth service] | Down | [User sees X, can do Y] | [test/LARP] |
| [e.g., AI API] | Timeout | [Fail-open / fail-closed per policy] | [test/LARP] |
| [e.g., DB] | Connection drop | [Atomic rollback + retry] | [test] |

---

## 6. Related Tables / Surfaces (Cascade)

*For every data write: what related tables / surfaces / caches must update? Critical for GDPR / consistency.*

| Write target | Related tables | Cascade behavior | Verified |
|--------------|----------------|-------------------|----------|
| [e.g., users] | sessions, audit_log, user_settings, profile_avatars | DELETE CASCADE for delete; UPDATE timestamp for write | [test path] |

---

## 7. Performance + Non-Functional Targets

*Reference `context.md` for project defaults. Override only with rationale.*

- Performance: [e.g., "First meaningful paint <1.2s; primary action latency <300ms p95"]
- Accessibility: WCAG 2.1 AA (per UX-RC gate)
- Security/privacy: [if not covered by project default]
- Observability: [errors logged, events emitted]

---

## 8. Data + API (Last, not first)

*Document data and APIs last — the user experience drives the design, not the schema. Keep it brief; implementation detail belongs in `plan.md`.*

### Key Entities (if data involved)
- **[Entity]**: [What it represents, key attributes — without implementation]

### API Surface (if any)
- **[Endpoint or interface name]**: [Purpose, request/response shape — without implementation]

---

## 9. Implementation Hint (Optional)

*Only include if the team needs a nudge in a specific direction. Otherwise leave blank — `plan.md` is the place for technical approach.*

[Brief note. Example: "Use existing `useSubscription` hook from src/hooks/. Don't reinvent."]

---

## Acceptance Checklist

### Content Quality
- [ ] Experience (Section 1) is the longest section in this spec
- [ ] Felt quality is named per surface (not vague)
- [ ] Magic moments tied to product-contract.md
- [ ] Banned language NOT present in any user-visible copy in this story

### Verifiability
- [ ] Every acceptance scenario specifies EVIDENCE (screenshot path, AX tree, transcript line)
- [ ] Every dependency has a failure-mode-handled row
- [ ] Related tables / surfaces enumerated
- [ ] Adversarial cases match the spec's positive claims

### Cross-Reference
- [ ] Primary persona matches `personas/<id>.md`
- [ ] Magic moments match `product-contract.md`
- [ ] Evidence requirements align with `evidence-contract.md` gate criteria for `readiness_target`

---

*[as of SHA `<git_sha_short>` | verified `<date>` | speck]*
