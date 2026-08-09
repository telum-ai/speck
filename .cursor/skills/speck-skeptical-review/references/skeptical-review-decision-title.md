# speck-skeptical-review / skeptical-review-decision-title

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
