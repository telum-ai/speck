---
name: speck-skeptical-review
description: Skeptical-review primitive. Before any non-trivial proposal locks (paid promise, differentiator, technical stack, architectural pattern, magic moment, banned language, readiness state target, etc.), produce N≥3 alternatives with tradeoff scoring and rationale. Unconditional discipline — invoked from project-product-contract, project-evidence-contract, project-architecture, project-plan, epic-plan, epic-architecture, story-plan, and any decision-locking flow. Forces enumeration before commitment, preventing premature lock-in.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

---

## Purpose

Skeptical-review is the **anti-premature-commitment primitive**. It catches the failure mode in 4 of 6 v6 retrospectives: the AI agent reached for the first plausible option (familiar pattern, training-data-default, "what the recipe suggests") rather than enumerating alternatives and picking with rationale.

The primitive is unconditional: at any decision lock, EITHER you've enumerated N≥3 alternatives with explicit tradeoffs OR you cannot lock.

## When to Run

Triggered by other skills BEFORE they call `/speck-decision-log` to log a lock.

Common triggers:
- Locking the paid promise (one sentence) in `product-contract.md`
- Locking the differentiator
- Locking a magic moment's surface placement
- Locking a tech stack choice
- Locking an architectural pattern (microservices vs monolith, REST vs GraphQL, etc.)
- Locking an evidence-contract proof source
- Locking a price / pricing tier / paywall trigger (must clear the free/DIY-substitute defensibility test, #74)
- Locking a readiness-state target for a story/epic
- Resolving conflicting requirements between PROMISE and CONSTRAINT

## Execution Steps

### 1. Receive the framing question

The caller specifies: "We're about to lock X. What are the options?"

If the question is too vague (e.g., "what tech stack"), refine first:
- "What persona's primary job does this serve?"
- "What does the product-contract.md say is the differentiator?"
- "What does the evidence-contract.md say about ship gates?"

Crisp the question so that the alternatives are comparable.

### 2. Enumerate alternatives (≥3)

Generate at least 3 alternatives that are:
- Materially different (not "Option B is Option A with a different name")
- Internally plausible (each could actually be chosen)
- Within scope (not requiring a different play level / different project)

If you can only think of 2: brainstorm wilder options or split an alternative into more granular options.

### 3. Score each alternative on tradeoff dimensions

Pick 3-5 dimensions relevant to the decision. Common ones:
- **Fit to paid promise**: Does this serve the differentiator?
- **Trust**: Does this build or erode trust?
- **Speed**: How fast to implement?
- **Cost**: Initial + ongoing
- **Risk**: What can go wrong?
- **Reversibility**: How hard to undo?
- **Operational**: Who maintains this?
- **Substitute defensibility** (pricing/value locks, #74): Does this survive the buyer's $0 substitute (free general-purpose AI + effort, a free tier, a manual process)? A price whose only edge is "convenience" is not defensible — name the durable wedge or don't lock the price.

For each alternative, write a 1-2 sentence judgment per dimension. Be specific to THIS project, not generic.

### 4. Surface and pick

Present the matrix to the user (or, if running autonomously, pick with rationale).

Required output structure:

```markdown
## Skeptical Review — [Decision Title]

**Question**: [crisp framing]

### Alternative A: [name]
- Description: [1 sentence]
- [Dimension 1]: [judgment]
- [Dimension 2]: [judgment]
- [Dimension N]: [judgment]
- Strengths: [summary]
- Weaknesses: [summary]

### Alternative B: [name]
[same structure]

### Alternative C: [name]
[same structure]

**Locked choice**: A | B | C

**Rationale**: [2-4 sentences. Why this option, not the others. Tied to product-contract.md or evidence-contract.md specifics.]

**Consequences accepted**: [What this choice commits to. What we're giving up.]

**Revisit if**: [Trigger conditions for reopening.]
```

### 5. Hand to `/speck-decision-log`

Call `/speck-decision-log` with the structured output to append to `project-decisions-log.md`.

### 6. Return to caller

Return the locked decision to the calling skill so it can continue its workflow.

## Behavior Rules

- NEVER lock with fewer than 3 alternatives — refuse and brainstorm more
- NEVER mark all alternatives as equal — the agent must commit to ONE with rationale
- NEVER use generic dimensions; tie them to product-contract.md / evidence-contract.md / context.md
- NEVER lock a price without the free/DIY-substitute defensibility test (#74) — a price is a P2 claim and needs the substitute mechanism, not just a working paywall
- ALWAYS surface the matrix before locking (transparent reasoning > silent agent confidence)
- ALWAYS pass the locked decision to `/speck-decision-log`

## Anti-Patterns

Self-rationalizing thoughts to catch:
- "The obvious choice is A" → Force yourself to enumerate B and C anyway
- "B and C are silly" → Then write them down with WHY they're silly, that's the rationale
- "We've already decided" → Then run supersession through `/speck-decision-log`, don't skip
- "This is too small to deserve skeptical review" → Skip it for truly trivial decisions (variable name, file path). NOT skip for: tech stack, evidence source, gate criteria, magic moment placement.

## Integration Points

Invoked by:
- `/project-product-contract` (paid promise, differentiator, magic moments)
- `/project-evidence-contract` (proof sources, gate criteria)
- `/project-architecture` (architectural patterns)
- `/project-plan` (epic structure)
- `/epic-plan` (technical approach)
- `/epic-architecture` (cross-cutting patterns)
- `/story-plan` (significant technical choices)
- `/recheck` (when drift requires reopening decisions)

Calls into:
- `/speck-decision-log` (always, on lock)

## Context: $ARGUMENTS
