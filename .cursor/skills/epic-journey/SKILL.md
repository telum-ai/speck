---
name: epic-journey
description: Map the user journey for a specific epic, identifying touchpoints, emotions, and opportunities
disable-model-invocation: false
---

---
description: Map the user journey for a specific epic, identifying touchpoints, emotions, and opportunities.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Create a detailed user journey map for an epic to guide design and development decisions.

## Context Gathering

**Required Information:**
1. Project name/ID (ask if not provided)
2. Epic name/ID (ask if not provided)
3. Load: project UX strategy, epic specification

If missing: "Which project and epic should I map the user journey for?"

## Interactive Journey Mapping

### Step 1: Understand Journey Context

**Determine PROJECT_ID** from epic path (e.g., `specs/projects/001-myproject/epics/...`).

**Load required design context**:
- `specs/projects/[PROJECT_ID]/ux-strategy.md` → UX principles, voice/tone, emotional design goals
  - Extract: Design principles, user personas, emotional journey targets, accessibility standards
  - If missing: WARN "No UX strategy found. Run `/project-ux` for UX guidelines that inform journey mapping."

- `specs/projects/[PROJECT_ID]/design-system.md` → Design tokens, interaction patterns
  - Extract: Interaction patterns, feedback mechanisms, animation guidelines
  - If missing: Note that touchpoint design will need alignment later

**Load epic context**:
- Epic specification for scope
- User personas from project spec (referenced in ux-strategy.md)

### Step 2: Journey Discovery

The journey template (`.speck/templates/epic/journey-template.md`) needs specific inputs. Ask for what's missing:

**Core journey questions:**
- "What triggers users to start this journey?"
- "What tells them they've succeeded?"
- "Which persona is this journey for?"

**If stages unclear:**
- "Walk me through the main steps users take..."
- "What are the key decision points?"

**If emotions unknown:**
- "How do users typically feel at the start?"
- "Where might they get frustrated?"
- "What would delight them?"

### Step 3: Pain Point Identification

For each stage identified, explore:
- "What could go wrong here?"
- "What might confuse users?"
- "Where do they typically need help?"

### Step 4: Opportunity Discovery

Based on pain points:
- "How might we reduce this friction?"
- "Where can we exceed expectations?"
- "What would make this memorable?"

### Step 5: Create Journey Map

1. Load template: `.speck/templates/epic/journey-template.md`
2. Create file at: `specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/user-journey.md`
3. Fill systematically:
   - Use discovered stages and emotions
   - Document all pain points
   - Include opportunity areas
   - Add success metrics
   - Mark unclear areas with [NEEDS CLARIFICATION]

### Step 6: Review and Guide

Present what was created:
- "I've mapped the user journey at [path]"
- "Key pain points identified: [list]"
- "Opportunities for delight: [list]"

Guide to next steps based on journey:
- Many touchpoints → `/epic-wireframes`
- Complex interactions → `/epic-interaction` (if exists)
- Ready for stories → `/story-specify` for individual touchpoints
- "The journey map will guide all design decisions for this epic"

The template contains the complete structure and guidance for journey documentation.
