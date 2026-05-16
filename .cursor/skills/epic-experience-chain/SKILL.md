---
name: epic-experience-chain
description: Required for UI epics in Speck v7. Defines the SEAMS between screens — entry state, single job per screen, emotional progression, handoff, no-repetition rule, first-viewport "why now", magic-moment placement, backtracking, cross-epic adjacency. Prevents the "seven different apps stitched together" failure mode (Fauna's Sept 2025 audit). Produces experience-chain.md, required before /epic-plan. Load when epic has any user-facing UI, when user says "the app feels disjointed", or when designing a multi-screen flow. FIRST ACTION is read the template at .speck/templates/epic/experience-chain-template.md.
disable-model-invocation: false
---

The user input can be provided directly by the agent or as a command argument — you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

---

## ⚠️ Step 0: Read Template First

Before any other action, read:
```
.speck/templates/epic/experience-chain-template.md
```

---

## Purpose

Three v6 retrospectives independently surfaced this failure:
- **Brightstance**: "Specifying screens in isolation is not enough. We need to specify SEAMS — what state precedes a screen, what emotional momentum a screen inherits, what it MUST hand off to the next screen."
- **Streb**: "Each magic moment was a story passing, but they didn't compose. The shared context between sessions was lost between stories."
- **Fauna**: "Once one screen falls into AI cliché, the next does too. There's no mechanism to enforce voice contagion."

`experience-chain.md` is the seam-level artifact. It's required for any epic with user-facing UI.

## When to Run

| Trigger | What to do |
|---------|------------|
| `/epic-specify` complete, epic has UI | Required before `/epic-plan` |
| User says "the app feels disjointed" | Audit/rebuild the chain |
| User says "feels like different apps" | Audit/rebuild the chain |
| New epic touches existing screens | Update relevant chain rows |

## Prerequisites

- `epic.md` exists (epic scope)
- `product-contract.md` exists (magic moments, banned language, voice)
- The epic has user-facing UI (skip for backend / API / CLI / infra epics)

If `product-contract.md` is missing: STOP. Tell user "Run `/project-product-contract` first."

## Execution Steps

### 1. Detect UI scope

Read `epic.md`. Determine the screens / steps / interactions involved. If unclear, ask user.

If the epic has no user-facing UI (backend, API, CLI, infra): EXIT. Tell user "experience-chain.md is not required for non-UI epics. Skip it."

### 2. Load context (parallel)

```
├── [Parallel] speck-explorer: Read epic.md
├── [Parallel] speck-explorer: Read product-contract.md (magic moments, voice, banned language)
├── [Parallel] speck-explorer: Read existing experience-chain.md files in other epics (for adjacency context)
├── [Parallel] speck-explorer: Read design-system.md if exists (primitives, patterns)
└── [Parallel] speck-explorer: Read ux-strategy.md if exists (voice principles)
```

### 3. Enumerate the screens

List every screen / step / surface / state in the epic. Each gets a row.

For each screen, ask the user (or infer from epic.md + product-contract.md):
- **Entry state**: What did the user bring with them? (data, emotional state, prior context)
- **Single job**: What's the ONE thing this screen must accomplish?
- **Emotional state on arrival**: What are they feeling when they land here?
- **Emotional state on handoff**: What must they feel as they leave?
- **Handoff to**: Where do they go next?
- **No-repetition rule**: What MUST NOT repeat from the previous screen?

### 4. Variants per screen

For each screen, define:
- First-time variant (what's pre-filled, hidden, shown that's specific to first-time?)
- Returning variant (what's hidden / pre-filled / skipped / surfaced?)
- Interrupted/resumed variant (what's preserved? what re-onboarding is needed?)

### 5. Magic-moment placement

For each magic moment in `product-contract.md`, decide which screen in THIS chain delivers it. Add to the placement table.

### 6. Continuity threads

What information must persist visibly across the chain? (e.g., chosen goal, progress indicator, selected plan)

### 7. Backtracking + adjacency

- Define Back / Cancel / Close behavior per screen.
- Define adjacency: this epic ↔ other epics (entries, exits, shared state).

### 8. First-viewport "why now?"

For each screen, name the single thing in the first 3 seconds that earns the user's attention. Test mercilessly: if you can't name it, the screen lacks a reason to exist.

### 9. Validation anchors

Map the chain to a runnable LARP script. The chain BECOMES the JTBD walkthrough for `/epic-validate`.

### 10. Write the file and stamp

Write to `specs/projects/<PROJECT_ID>/epics/E###-<name>/experience-chain.md`.

Apply SHA stamp:
```
.speck/scripts/stamp-truth.sh <epic-dir>/experience-chain.md
```

### 11. Report to user

```
✅ experience-chain.md created

Path: <epic-dir>/experience-chain.md
Screens chained: <count>
Variants per screen: <count> × 3 (first-time, returning, interrupted)
Magic moments placed: <count>
Continuity threads: <count>
Cross-epic adjacencies: <count>

Next steps:
1. /epic-plan can now proceed
2. The story-level work will reference this chain
3. /epic-validate's JTBD walkthrough will use this as the test script
```

## Behavior Rules

- NEVER allow a screen row without all required columns filled
- NEVER allow "feels good" or "feels nice" as emotional states — require specific feelings
- NEVER skip the no-repetition rule for any transition
- ALWAYS cross-reference magic moments back to product-contract.md
- ALWAYS apply SHA stamp on write

## Integration Points

- Required input: `epic.md`, `product-contract.md`
- Required output: `experience-chain.md` (with SHA stamp)
- Downstream consumers: `/epic-plan`, `/epic-validate`, all story `/story-specify` skills in this epic
- Updates: `project-state.md` (next action becomes /epic-plan)

## Context: $ARGUMENTS
