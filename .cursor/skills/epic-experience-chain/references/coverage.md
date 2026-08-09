# epic-experience-chain / coverage

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
