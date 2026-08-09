# speck-skeptical-review / execution-steps

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
