# speck-skeptical-review / more

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

## Purpose

Skeptical-review is the **anti-premature-commitment primitive**. It catches the failure mode in 4 of 6 v6 retrospectives: the AI agent reached for the first plausible option (familiar pattern, training-data-default, "what the recipe suggests") rather than enumerating alternatives and picking with rationale.

The primitive is unconditional: at any decision lock, EITHER you've enumerated N≥3 alternatives with explicit tradeoffs OR you cannot lock.

## Context: $ARGUMENTS
