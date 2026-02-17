---
name: epic-wireframes
description: Create wireframes for all screens and states within an epic
disable-model-invocation: false
---

---
description: Create wireframes for all screens and states within an epic.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Design wireframes that visualize the user interface for an epic's functionality.

## Context Loading

**Required:**
1. Project identification (ask if not provided)
2. Epic identification (ask if not provided)  
3. Load: design system, user journey, epic spec

Ask: "Which project and epic should I create wireframes for?"

## Interactive Wireframing Process

### Step 1: Load Context

**Determine PROJECT_ID** from epic path (e.g., `specs/projects/001-myproject/epics/...`).

**Load required design context**:
- `specs/projects/[PROJECT_ID]/design-system.md` → Design tokens, components, patterns
  - Extract: Color tokens, typography scale, spacing system, component library, grid specifications
  - If missing: WARN "No design system found. Run `/project-design-system` for consistent wireframes."

- `specs/projects/[PROJECT_ID]/ux-strategy.md` → UX principles, voice/tone
  - Extract: Design principles, voice attributes, accessibility standards, content guidelines
  - If missing: WARN "No UX strategy found. Run `/project-ux` for UX guidelines."

**Load epic context**:
- User journey map (for touchpoints) - `[EPIC_DIR]/user-journey.md`
- Epic specification (for requirements) - `[EPIC_DIR]/epic.md`

### Step 2: Screen Discovery

The wireframe template needs specific screens. Based on the journey:

**Screen identification:**
- "I see [X] touchpoints in the journey. Do these each need separate screens?"
- "Are there any administrative or edge case screens needed?"
- "What about different states (empty, error, success)?"

**For each screen, if unclear:**
- "What's the main purpose of this screen?"
- "What must users accomplish here?"
- "Mobile, desktop, or both?"

### Step 3: Layout Decisions

For screens needing definition:
- "Standard layout with header/nav or custom?"
- "What's the most important element on this screen?"
- "Any specific component preferences from the design system?"

### Step 4: Create Wireframes

1. Load template: `.speck/templates/epic/wireframes-template.md`
2. Create file at: `specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/wireframes.md`
3. Fill systematically:
   - Create screen inventory table
   - Generate ASCII wireframes using template format
   - Document all interactions
   - Include responsive versions
   - Note content requirements

### Step 5: Review and Guide

Present what was created:
- "I've created wireframes at [path]"
- "Designed [X] screens with mobile/desktop versions"
- "All journey touchpoints covered"

Validate completeness:
- "Any additional screens needed?"
- "Should we add more states (error, empty)?"

Guide to next steps:
- Need detailed specs → `/story-ui-spec` for each screen
- Ready for development → `/story-specify` to break down
- Want prototypes → Consider external prototyping tools

The template contains complete wireframe structures and examples.

## Tools Integration

If requested:
- Can export wireframe descriptions for design tools
- Can generate basic HTML/CSS prototypes
- Can create component mapping documentation
