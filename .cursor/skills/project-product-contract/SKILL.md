---
name: project-product-contract
description: Create or update product-contract.md — the PROMISE center of gravity for Build and Platform projects. Merges what v6 scattered across project.md, ux-strategy.md, constitution.md, domain-model.md. Required before /project-plan at Build+ levels. Load when user wants to "make this contract executable", lock in the differentiator, define banned language, document the magic moments, or before any epic planning. FIRST ACTION is read the template at .speck/templates/project/product-contract-template.md.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

> 🚦 **METHODOLOGY INTENT SPLIT**:
> - Use `/project-product-contract` to author the initial contract or refresh it during greenfield planning.
> - If the project's contract has already been validated/shipped and you need to make a **deliberate directional or strategic intent change**, run `/project-adjust` instead of silently re-authoring to ensure downstream cascade dependencies are traced and re-validated.

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Template First

Before any other action, read:
```
.speck/templates/project/product-contract-template.md
```

The template defines the canonical structure for product-contract.md.

---

## Purpose

`product-contract.md` is the **single executable PROMISE document** in Speck v7. Everything downstream — epic specs, story specs, audit reports, validation reports — references it.

Six v6 projects (Streb, Pust, Brightstance, Fau, Ukesmeny, Splang) independently failed when they didn't have this:
- Generic concepts leaked into specialized products (Streb: "deload" in adaptive coach)
- Marketing copy bled into mandatory product steps (Brightstance, Fauna)
- Inspirational sources became templates instead of principles (Fauna: brd.no clone)
- Magic moments existed as specs but never compiled into validation (Streb, Fauna)
- AI output was generic because no AI behavior contract enforced specificity

This skill produces the contract that prevents all of those.

## When to Run

| Trigger | What to do |
|---------|------------|
| After `/project-clarify`, before `/project-plan` | Required at Build+ levels — create from scratch |
| User says "lock in the differentiator" | Refine the differentiator + anti-differentiator sections |
| User says "what are we banning?" | Refine banned language section |
| User says "what are the magic moments?" | Refine magic moments section |
| Drift detected by `/recheck` | Revisit relevant sections; re-stamp |
| Migrating from v6 | Construct from existing project.md + ux-strategy.md + constitution.md + domain-model.md |

## Prerequisites

- `project.md` must exist (vision)
- `project-clarify` should have run (resolves ambiguities)
- Helpful but optional: existing `ux-strategy.md`, `domain-model.md`, `constitution.md` content to merge in

## Execution Steps

### 1. Detect project, play level, and archetype

Find `specs/projects/<PROJECT_ID>/`. Read `.speck/project.json` → `play_level` and `project_archetype`. (If `project_archetype` is missing, default to `consumer_product` or infer from stack/context).

If play level is `sprint`: tell the user "Sprint-level products don't require product-contract.md. Refine `PRD.md` instead. If this is growing into a real product, run `/project-promote` first."

**Archetype Adaptation**:
Adapt your writing of the template sections based on the detected `project_archetype` (see `product-contract-template.md` for explicit WHEN/SKIP criteria):
- **For `infra_service` / `backend_api` (Non-UI / Systems work)**:
  - Replace Section 1 with the "Operational SLA / Capability Promise".
  - Replace Section 2 with the "Primary Consumer / Client Service" operational JTBD.
  - Replace Section 4 with the "Operational Invariants Scorecard" (Latency, Throughput, Durability, Resiliency, Security).
  - Replace Section 5 with "Operational Milestones".
  - Replace Section 6 with "API & System Taxonomy" (endpoint names, JSON schemas, protocol rules).
  - Replace Section 7 with "Banned System Anti-Patterns" (forbidden code behaviors/payload structures).
  - Skip Section 8 (AI Contract) and Section 9 (Longitudinal Axes) unless specifically AI/adaptation related.
  - Skip Section 10 (Trust Moments).
- **For `consumer_product` / `b2b_saas` / `internal_tool` (UI/Human-facing products)**:
  - Write standard human-centered value promise, primary persona, JTBD scorecard, magic moments, public/banned copy guidelines, and trust moments.

### 2. Read prerequisites (subagent parallelization)

Dispatch in parallel:
```
├── [Parallel] speck-explorer: Read project.md (vision, persona, scope)
├── [Parallel] speck-explorer: Read ux-strategy.md if exists (voice/tone)
├── [Parallel] speck-explorer: Read constitution.md if exists (principles)
├── [Parallel] speck-explorer: Read domain-model.md if exists (terminology)
├── [Parallel] speck-explorer: Read context.md if exists (constraints affecting promise)
└── [Parallel] speck-explorer: Read recipe.yaml if active (recipe defaults)
```

### 3. Skeptical-review primitive (mandatory before locking)

Before drafting, surface the **3 alternative framings** of the paid promise and pick one with rationale:

```markdown
## Skeptical Review — Paid Promise

**Framing A**: [One-sentence promise — option A]
- Strengths: [What this framing emphasizes]
- Weaknesses: [What it under-sells / over-promises]

**Framing B**: [One-sentence promise — option B]
- Strengths:
- Weaknesses:

**Framing C**: [One-sentence promise — option C]
- Strengths:
- Weaknesses:

**Locked choice**: [A/B/C]
**Rationale**: [Why this framing — tied to the persona's JTBD]
```

Log the locked choice to `project-decisions-log.md`.

Repeat skeptical-review for:
- The differentiator (3+ options)
- The primary magic moment (3+ candidates)

### 4. Draft the contract

Fill the template section-by-section. Use information from step 2 plus user Q&A.

#### Key dialogue prompts:

**Paid promise**: "If a user describes this product in one outcome-focused sentence, what would make them excited enough to pay? Avoid feature lists."

**Differentiator**: "If a competitor copied every feature, what would still be true of THIS product that wouldn't be true of theirs?"

**Anti-differentiators**: "What category does this product naturally drift toward that it must never become? Finish 'We are NOT...'"

**Inspiration sources**: "Name 1-3 sources you take inspiration from. For each, what PRINCIPLE do we draw — not what implementation do we copy?"

**JTBD scorecard**: "For this product's primary flow, fill all five dimensions: functional, emotional, social, trust, commercial. None of these can be left vague."

**Magic moments**: "Name 3-7 surfaces where a user would say 'wow, this gets me.' For each, define trigger, content beats, target emotional response, and how we validate it in LARP."

**Public language**: "Build the canonical domain term table (in every supported locale). Voice principles in 3-5 lines. Sample-good and sample-bad copy."

**Banned language**: "What words would a competitor say that we'd never say? What words has the agent or designer reached for that don't fit? Each banned term gets a reason and a replacement."

**AI behavior contract** (if applicable): "For every user-visible AI surface, define inputs the model must consume, required output shape, required tone, must-cite items, must-avoid items, bad-answer examples, good-answer examples."

**Longitudinal axes** (if applicable): "Does the product adapt over time? List each adaptive axis with signals, variations, overrides, success criteria. Define named validation chapters."

### 5. Validate the contract

Run the review checklist in the template:
- Clarity: paid promise = one sentence? differentiator = one sentence? anti-differentiators name specific failure modes?
- Completeness: JTBD all 5 dimensions? banned language has 5+ entries? AI contract present if AI is user-visible? longitudinal axes present if product adapts?
- Linkage: references `evidence-contract.md`? will be referenced by every epic and story?

If anything fails: surface it, ask for input, iterate.

### 6. Write the file and stamp

Write to `specs/projects/<PROJECT_ID>/product-contract.md`.

Apply SHA stamp:
```
.speck/scripts/stamp-truth.sh specs/projects/<PROJECT_ID>/product-contract.md
```

Write the provisional market stamp under §3 (issue #80) so the differentiator is scheduled for its first market re-validation instead of reading as never-checked. Only `stamp-market.sh` writes this stamp — never by hand:
```bash
.speck/scripts/stamp-market.sh specs/projects/<PROJECT_ID>/product-contract.md --baseline
```
A real dated + sourced verdict lands later via `/speck-frontier-scan --product`.

### 6b. Validate the contract

Run the product contract validator to ensure structural completeness, self-consistency (no self-violation of the contract's own banned language), and **§2a↔§3 reconciliation** — the validator blocks (`--strict`) when the §3 differentiator is weaker than the project's own §2a defensible wedge (`WEDGE_DRIFT.P1`), the exact "canonical headline is weaker than our own analysis" failure. When it fires, promote the §2a wedge into §3 before locking:
```bash
bash .speck/scripts/validation/validators/validate-product-contract.sh --strict specs/projects/<PROJECT_ID>/product-contract.md
```

### 6c. Run Premise-Challenge (Anti-Spec) Pass

Run a premise-challenge pass on onboarding/first-run and other high-impact surfaces defined in the contract to ensure the underlying design decisions are fundamentally sound and feel good (using the `/speck-premise-challenge` skill).

### 7. Trigger downstream regeneration

Run `/project-state` to regenerate `project-state.md` with the new contract reflected.

**Then automatically invoke `/project-readme`** (run `.speck/scripts/regenerate-project-readme.sh`) to refresh the root README elevator pitch from the paid promise. Do not wait for the user to ask.

### 8. Report to user

```
✅ product-contract.md created

Path: specs/projects/<PROJECT_ID>/product-contract.md
Sections completed: 12/12
Banned language entries: <count>
Magic moments defined: <count>
AI surfaces governed: <count>
Longitudinal axes: <count>

Next steps:
1. Review the contract — this is the bar every downstream decision is measured against
2. Run /project-evidence-contract to define what counts as proof
3. Then proceed with /project-plan
```

## Behavior Rules

- NEVER write a vague paid promise — refuse if user can't make it one specific sentence
- NEVER skip the skeptical-review primitive for the differentiator
- NEVER auto-fill banned language; ask the user for product-specific bans
- ALWAYS apply SHA stamp on write
- ALWAYS log decisions to `project-decisions-log.md`
- ALWAYS trigger `/project-state` regeneration on write
- ALWAYS trigger `/project-readme` after `/project-state` on write

## Integration Points

- Required input: `project.md`, optionally `ux-strategy.md`, `constitution.md`, `domain-model.md`, `context.md`, recipe
- Required output: `product-contract.md` (200-line target, with SHA stamp footer)
- Downstream consumers: `/project-evidence-contract`, `/project-plan`, every `/epic-*` and `/story-*` skill
- Updates: `project-decisions-log.md` (lock decisions), `project-state.md` (regenerate)

## Context: $ARGUMENTS
