# epic-experience-chain / emotion

## Purpose

Three v6 retrospectives independently surfaced this failure:
- **Brightstance**: "Specifying screens in isolation is not enough. We need to specify SEAMS — what state precedes a screen, what emotional momentum a screen inherits, what it MUST hand off to the next screen."
- **Streb**: "Each magic moment was a story passing, but they didn't compose. The shared context between sessions was lost between stories."
- **Fauna**: "Once one screen falls into AI cliché, the next does too. There's no mechanism to enforce voice contagion."

`experience-chain.md` is the seam-level artifact. It's required for any epic with user-facing UI.

## Prerequisites

- `epic.md` exists (epic scope)
- `product-contract.md` exists (magic moments, banned language, voice)
- The epic has user-facing UI (skip for backend / API / CLI / infra epics)

If `product-contract.md` is missing: STOP. Tell user "Run `/project-product-contract` first."

## Behavior Rules

- NEVER allow a screen row without all required columns filled
- NEVER allow "feels good" or "feels nice" as emotional states — require specific feelings
- NEVER skip the no-repetition rule for any transition
- ALWAYS cross-reference magic moments back to product-contract.md
- ALWAYS apply SHA stamp on write
