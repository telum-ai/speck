---
name: project-brainstorm
description: Vague idea → structured problem. Use at very start when intent is fuzzy.
---

# project-brainstorm

Input: `$ARGUMENTS` (raw ideas, problems, inspirations — or empty for interactive).
Output: project concept(s) ready for `/project-specify` (stdout); optional `specs/projects/brainstorm-[timestamp].md`.
Position: BEFORE `/project-specify` — optional ideation.

## 1. Gather ideas

With args: parse distinct ideas; ask "Anything else before we explore?"

Without args: prompt for problems, frustrations, wished-for products, domains, technologies. Continue until enough material or user done.

## 2. Cluster themes

Identify: problem themes, solution themes, user themes, domain/regulatory themes. Present clusters; confirm or correct.

## 3. Generate concepts

Per viable theme (1–3 concepts):

```
Name · One-liner
Problem: [who + pain + impact]
Solution: [product type + core capability + benefit]
Users: primary + secondary
Key features: 3–5 bullets
Differentiation vs existing solutions
Complexity: Level 0–4 · timeframe · technical challenges
Confidence: High/Medium/Low + reason
```

Optional web search: competitors, market gap, enabling tech → append "Quick research" bullets.

## 4. Explore options

Offer: deep dive · combine concepts · more variations · proceed to `/project-specify` · continue brainstorming.

Deep dive: competitors, feasibility, risks, market (if applicable).

## 5. Handoff

When user selects concept, emit one-paragraph description for `/project-specify`:

```
/project-specify [description]
```

Ask: run now or save session?

Optional save → `specs/projects/brainstorm-[timestamp].md`:
- Raw ideas, themes, all concepts, selected, rejected + reasons

## 6. Router signals

Route here (not `/project-specify`) when: vague idea, "help me figure out what to build", brainstorm intent, insufficient specificity.

## NEVER / ALWAYS

- NEVER jump to `/project-specify` before user picks a concept
- NEVER dismiss ideas without exploration
- NEVER omit rejected concepts from saved session (if saving)
- ALWAYS produce at least one concrete concept
- ALWAYS make handoff description specific enough to specify
