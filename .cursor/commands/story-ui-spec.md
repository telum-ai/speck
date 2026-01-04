---
description: Create detailed UI specifications for story implementation, including exact styling, behavior, and code examples. REQUIRED for stories with UI components.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Generate precise UI specifications that developers can implement directly.

**When to use this command**:
- ⚠️ **REQUIRED** for stories that include UI components (forms, pages, interactive elements)
- **REQUIRED** for stories with multiple component states, variants, or animations
- **OPTIONAL** for simple, single-state UI elements that follow existing patterns

If `/story-plan` detected UI requirements, you MUST run this command before `/story-tasks`.

## Context Requirements

1. Locate the active story directory (STORY_DIR):
   - Preferred: user is already in the story directory (or a subfolder like `contracts/`)
   - Determine STORY_DIR by walking up from current directory until you find `spec.md`
   - If no `spec.md` found: instruct user to `cd` into the story directory or run `/speck` to route
   - Define:
     - SPEC_PATH = `{STORY_DIR}/spec.md`
     - UI_SPEC_PATH = `{STORY_DIR}/ui-spec.md`

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
- Epic wireframes (where it fits) - `{EPIC_DIR}/wireframes.md` if exists
- Epic user journey (user flow context) - `{EPIC_DIR}/user-journey.md` if exists

**Load recipe visual testing config** (tight feedback loop):
- Read `specs/projects/[PROJECT_ID]/project.md` frontmatter for `_active_recipe:`
- If present, load `.speck/recipes/[recipe-name]/recipe.yaml`
- Extract `visual_testing:` (platform/strategy/pattern_file/breakpoints/devices/window_sizes)
- Use this config to make the UI spec *testable* and *verifiable*:
  - Populate **Responsive Behavior** with the actual breakpoints/devices we will validate
  - Populate **Testing Checklist** coverage matrix (web browsers vs mobile devices vs desktop OS)
  - Add **stability requirements** for automation (e.g. `data-testid`/`testID`/Flutter keys for critical elements)
  - Reference `.cursor/rules/speck/patterns/{visual_testing.pattern_file}` so implementers know the expected visual test approach

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

Write output to UI_SPEC_PATH (`{STORY_DIR}/ui-spec.md`)

The template is self-documenting - follow all sections and guidelines within it.

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
- Required: `/story-tasks` (generate implementation tasks)
- ⚠️ REQUIRED: `/story-analyze` (quality check - DO NOT SKIP)
- Then: `/story-implement`
- Finally: `/story-validate`
- Want component story → Consider Storybook

The template contains comprehensive sections for all UI specification needs.
