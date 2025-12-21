---
description: Define the overall user experience strategy and design principles for the project.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Create a comprehensive UX strategy that will guide all design decisions throughout the project.

## Context Gathering & Mode Detection

First, determine which project we're working on:
- If project name/ID provided in arguments, use that
- Otherwise, ask: "Which project should I create the UX strategy for?"
- List available projects from `specs/projects/`

Load project context:
- Project specification (project.md)
- Check for [INFERRED FROM CODE] markers (indicates brownfield import)
- Check for project-landscape-overview.md (from /project-scan)
- Target users and goals
- Success metrics

**Detect mode**:
- **EXTRACT mode** (brownfield): If project.md has [INFERRED FROM CODE] markers OR project-landscape-overview.md exists
- **CREATE mode** (greenfield): If project.md has no brownfield markers

## Just-In-Time Research

**Reference**: Follow the just-in-time research pattern (`.speck/patterns/just-in-time-research-pattern.md`)

Before defining UX strategy, identify knowledge gaps and conduct research:

### Research Areas for UX

**1. User Behavior Patterns**:
- Decision: What are typical user behaviors for [user segment] in [domain]?
- Web Search: User research studies, behavioral patterns
- Deep Research (if needed): Detailed user persona development, journey mapping

**2. Accessibility Standards**:
- Decision: What accessibility requirements apply?
- Web Search: WCAG 2.1 AA/AAA requirements, ARIA patterns, color contrast ratios
- Deep Research (rarely needed): Domain-specific accessibility requirements

**3. UX Best Practices**:
- Decision: What UX patterns work best for [app type]?
- Web Search: "UX best practices for [social/productivity/e-commerce] apps 2024"
- Deep Research (if needed): Case studies, competitive UX analysis

**4. Design Psychology**:
- Decision: How do users make decisions in this context?
- Web Search: Cognitive load principles, decision fatigue, visual hierarchy
- Deep Research (if needed): Behavioral economics, persuasive design ethics

### Execute Research

For each area with knowledge gaps:
1. **Quick web search** for standards and best practices
2. **Generate deep research prompt** if web search insufficient
3. **Document findings** in "Research Informing This Strategy" section of output

## Interactive UX Strategy Development

**MODE SELECTION**: Branch based on detected mode

---

## EXTRACT MODE (Brownfield)

**Purpose**: Extract UX principles from existing codebase, not create new ones

### Step 1: Analyze Existing UI (if applicable)

**Check for UI in codebase**:
- Load project-landscape-overview.md for UI component inventory
- Check if frontend/ or UI code exists
- If NO UI: Skip to CREATE mode for new UI strategy

**If UI exists**, analyze existing patterns:
```bash
# Find UI components (don't execute - just conceptual)
frontend/components/
frontend/pages/
src/ui/
```

Extract from code:
- Component patterns (buttons, forms, cards)
- Color usage (primary, secondary, accent colors)
- Typography patterns (headings, body, emphasis)
- Spacing patterns (padding, margins, gaps)
- Interaction patterns (modals, toasts, animations)
- Accessibility patterns (ARIA, keyboard nav)

### Step 2: Infer UX Principles from Patterns

Based on extracted patterns, infer principles:

**Example inferences**:
- Consistent spacing scale → "Principle: Systematic spacing for visual rhythm"
- Subtle animations → "Principle: Calm, focused interactions"
- High contrast → "Principle: Accessibility-first design"
- Minimal text → "Principle: Show, don't tell"

Ask user to validate:
- "I've analyzed your existing UI. The code shows these patterns: [list]"
- "This suggests these UX principles: [inferred principles]"
- "Does this match your UX philosophy, or should I adjust?"

### Step 3: Fill Gaps Interactively

For aspects not evident in code:
- "What emotional response should users have?" (if not clear from UI)
- "Are there accessibility requirements beyond what's implemented?" 
- "Any brand guidelines I should document?"

### Step 4: Create UX Strategy (Descriptive)

Generate ux-strategy.md with:
- **Research Informing This Strategy** section (web search findings on UX patterns/accessibility)
- **Existing Patterns** section (what code shows)
- **Inferred Principles** section (what patterns suggest)
- **Gaps Identified** section (what's missing or inconsistent)
- **Recommendations** section (how to improve consistency)

Mark extraction source:
```markdown
> **Extraction Note**: This UX strategy was extracted from existing codebase analysis.
> Patterns are DESCRIPTIVE (what exists), not PRESCRIPTIVE (what should be).
> Use for consistency in new features. Update as UX evolves.
```

---

## CREATE MODE (Greenfield)

**Purpose**: Define new UX strategy from scratch

### Step 1: Understand Design Context

Load project information:
- Project specification
- Target users and goals
- Success metrics

Assess what's already defined vs. what needs discovery.

### Step 2: Gap Discovery

The UX strategy template (`.speck/templates/project/ux-strategy-template.md`) needs specific inputs. Ask only for what's missing:

**If emotional goals undefined:**
- "What should users feel when using this product?"

**If design personality unclear:**
- "If this product had a personality, would it be more formal or casual? Playful or serious?"

**If visual direction unknown:**
- "Do you have existing brand guidelines or visual preferences?"

**If accessibility not specified:**
- "What level of accessibility compliance do you need?"

### Step 3: Collaborative Principle Development

Work with the user to define 3-5 UX principles:
- Start with their values and goals
- Translate into actionable principles
- Ensure each has clear do's and don'ts

### Step 4: Create UX Strategy

1. Load the template: `.speck/templates/project/ux-strategy-template.md`
2. Create file at: `specs/projects/[PROJECT_ID]/ux-strategy.md`
3. **Add "Research Informing This Strategy" section** at the top after metadata:
   ```markdown
   ## Research Informing This Strategy
   
   ### Web Search Findings
   - **Accessibility**: WCAG 2.1 AA requires 4.5:1 contrast ratio for body text (Source: [URL], Date: [Date])
   - **User Behavior**: [User segment] prefers mobile-first (Source: [URL], Date: [Date])
   
   ### Deep Research (if conducted)
   - **User Personas**: [Key findings] (Report: project-ux-research-report-personas.md)
   
   ### Best Practices Applied
   - Cognitive load reduction, visual hierarchy, progressive disclosure
   ```
4. Fill systematically:
   - Use project context for user information
   - **Apply research findings to UX principles**
   - Apply discovered design preferences
   - Mark unclear sections with [NEEDS CLARIFICATION]
   - Ensure consistency with project goals

### Step 5: Review and Next Steps

Present what was created:
- "I've documented your UX strategy at [path]"
- "Key principles established: [list]"
- "Design personality: [summary]"

Guide to next steps:
- Need refinement → "Review and let me know what needs adjustment"
- Ready to continue → `/project-context` (define technical constraints)
- If UX validation needed → apply the just-in-time research pattern
  (`.speck/patterns/just-in-time-research-pattern.md`) and embed findings in ux-strategy.md

Note: UX strategy provides essential inputs for PRD creation in /project-plan

The template contains detailed guidance for each section.

## Error Handling

- No project specified → List available projects
- Project not found → Suggest creating one first
- Minimal input → Use discovery questions
- Conflicting requirements → Surface trade-offs for decision
