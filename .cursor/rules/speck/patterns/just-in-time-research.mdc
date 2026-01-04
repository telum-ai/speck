---
name: just-in-time-research
description: Load when making decisions that require external knowledge - technology evaluation, standards/compliance checking, market data, or current best practices not in your training data.
---

# Just-In-Time Research

When you encounter a decision requiring external knowledge (standards, best practices, market data, technical evaluation), conduct research immediately rather than guessing.

## When This Rule Applies

Load this rule when:
- Evaluating technology choices or comparing options
- Checking standards/specifications (WCAG, RFC, ISO)
- Assessing compliance or regulatory requirements
- Needing current market data or statistics
- Looking up integration patterns for external services
- Any decision where your training data may be outdated

Do NOT research for:
- Well-established patterns you're confident about
- Decisions already documented in loaded artifacts
- Basic programming concepts

## Research Priority Order

Use research tools in this order:

1. **Check existing research first** - Look for `*-research-report-*.md` files in the project/epic directories
2. **Perplexity MCP** (if configured) - Use `perplexity_search` for quick facts, `perplexity_research` for deep analysis
3. **Built-in web_search** - Fallback when Perplexity unavailable
4. **Generate manual prompt** - If automated tools insufficient, create a prompt for the user

## Research Workflow

### Step 1: Check Existing Research

Before conducting new research, always check:
```
specs/projects/[project-id]/*-research-report-*.md
specs/projects/[project-id]/epics/[epic-id]/*-research-report-*.md
```

Also check if upstream artifacts (architecture.md, context.md, ux-strategy.md) already contain relevant "Research Informing" sections.

If relevant research exists:
1. Load and extract relevant findings
2. Reference as "Reused Research" in your research trail
3. Only conduct new research if gaps remain

### Step 2: Identify the Knowledge Gap

Ask yourself:
- What specific information is missing?
- Can this be decided from well-known best practices?
- Do I need current/external information to decide wisely?

### Step 3: Execute Research

**For quick facts** (standards, specs, simple lookups):
- Use `perplexity_search` or `web_search`

**For analysis** (trade-offs, comparisons, deep dives):
- Use `perplexity_research`

**For complex decisions** (multi-factor analysis):
- Use `perplexity_reason`

### Step 4: Synthesize and Document

Extract key findings with source URLs. Add to the artifact:

```markdown
## Research Informing This Section

- **[Topic]**: [Finding] (Source: [URL], [Date])
```

## When Automated Research Fails

If research tools don't provide sufficient information:

1. Create a research prompt file: `[command]-research-prompt-[topic].md`
2. Tell the user: "Deep research needed for [topic]. Please run this prompt in your preferred research tool."
3. Pause and wait for the user to provide findings
4. Continue after incorporating results

## Quality Guidelines

- Prefer official documentation over blog posts
- Use recent sources (2 years for standards, 6 months for market data)
- Cross-reference multiple sources for critical decisions
- Note when information may be outdated
- Document what research influenced what decision

## Commands That Use This Pattern

**Project Level**: `/project-ux`, `/project-context`, `/project-constitution`, `/project-architecture`, `/project-design-system`, `/project-plan`

**Epic Level**: `/epic-architecture`, `/epic-plan`

**Story Level**: `/story-plan`
