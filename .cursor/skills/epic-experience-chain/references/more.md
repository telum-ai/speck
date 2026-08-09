# epic-experience-chain / more

## Integration Points

- Required input: `epic.md`, `product-contract.md`
- Required output: `experience-chain.md` (with SHA stamp)
- Downstream consumers: `/epic-plan`, `/epic-validate`, all story `/story-specify` skills in this epic
- Updates: `project-state.md` (next action becomes /epic-plan)

## Prerequisites

- `epic.md` exists (epic scope)
- `product-contract.md` exists (magic moments, banned language, voice)
- The epic has user-facing UI (skip for backend / API / CLI / infra epics)

If `product-contract.md` is missing: STOP. Tell user "Run `/project-product-contract` first."

## Step 0: Read Template First

Before any other action, read:
```
.speck/templates/epic/experience-chain-template.md
```

---

## Context: $ARGUMENTS
