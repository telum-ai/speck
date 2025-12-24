---
description: Create detailed UI specifications for story implementation, including exact styling, behavior, and code examples.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Generate precise UI specifications that developers can implement directly.

## Context Requirements

**Must identify:**
1. Project (for design system)
2. Epic (for wireframes/patterns)
3. Story (specific component/feature)

Ask progressively:
- "Which project is this story part of?"
- "Which epic does this story belong to?"
- "Which specific story are we creating UI specs for?"

Load context:
- Design system tokens
- Epic wireframes
- Story requirements

## Interactive UI Specification Process

### Step 1: Understand Component Context

**Determine PROJECT_ID** from story path (e.g., `specs/projects/001-myproject/epics/...`).

**Load required design context**:
- `specs/projects/[PROJECT_ID]/design-system.md` → Design tokens, components, patterns
  - Extract: Color tokens, typography scale, spacing system, component library
  - If missing: WARN "No design system found. Run `/project-design-system` for consistent UI."
  
- `specs/projects/[PROJECT_ID]/ux-strategy.md` → UX principles, voice/tone
  - Extract: Design principles, voice attributes, accessibility standards
  - If missing: WARN "No UX strategy found. Run `/project-ux` for UX guidelines."

**Load story context**:
- Story specification (what needs to be built)
- Epic wireframes (where it fits) - `epic/wireframes.md` if exists
- Epic user journey (user flow context) - `epic/user-journey.md` if exists

### Step 2: Component Discovery

The UI spec template needs specific details. Ask only what's missing:

**If component type unclear:**
- "What UI element does this story focus on?"
- "Is this modifying an existing component or creating new?"

**If variants unknown:**
- "Does this need multiple sizes or states?"
- "Any theme variations (light/dark)?"

**If behavior undefined:**
- "What happens when users interact with this?"
- "Any special animations or transitions?"

### Step 3: Gather Specifications

Work with the user to define:
- Visual properties (using design tokens)
- Interactive states and transitions
- Responsive behavior
- Accessibility requirements
- Implementation approach

### Step 4: Create UI Specification

**CRITICAL**: Load and follow the template exactly:
```
.speck/templates/story/ui-spec-template.md
```

Create file at: `specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/stories/[STORY_ID]/ui-spec.md`

Fill all sections comprehensively:
   - Apply design system tokens
   - Document all states
   - Include code examples
   - Add accessibility specs
   - Mark unclear areas with [NEEDS CLARIFICATION]

### Step 5: Review and Guide

Present what was created:
- "I've created the UI specification at [path]"
- "Documented [X] states and [Y] variants"
- "Included implementation examples"

Validate completeness:
- "Any additional states or edge cases?"
- "Need specific framework code examples?"
- "Want me to generate CSS utility classes?"

Guide to next steps:
- Ready to build → `/story-implement`
- Need tests → `/story-test`
- Want component story → Consider Storybook

The template contains comprehensive sections for all UI specification needs.
