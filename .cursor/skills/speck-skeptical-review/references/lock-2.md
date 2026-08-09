# speck-skeptical-review / lock (2)

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
