---
name: project-design-system
description: Create a comprehensive design system for the project, including components, tokens, and patterns
disable-model-invocation: false
---

---
description: Create a comprehensive design system for the project, including components, tokens, and patterns.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Develop a detailed design system that will ensure consistency across the entire project.

## Context Requirements & Mode Detection

1. **Project Identification**
   - If project name/ID in arguments → use it
   - Otherwise ask: "Which project should I create the design system for?"
   - Load: project.md, ux-strategy.md, architecture.md

2. **Prerequisites Check**
   - **Required**: ux-strategy.md (run `/project-ux` if missing)
   - **Required**: architecture.md (run `/project-architecture` if missing)
   - Understand design principles and personality from UX
   - Understand tech stack and component structure from architecture

3. **Mode Detection**
   - Check for project-landscape-overview.md (from /project-scan)
   - Check if codebase has UI components
   - If YES: **BROWNFIELD mode** (extract existing design system)
   - If NO: **GREENFIELD mode** (create new design system)

**Position in Flow**: 
- Runs AFTER architecture, BEFORE planning
- Architecture informs tech-specific design choices (Tailwind vs CSS-in-JS)
- Design system informs UI requirements in planning

**Research Approach**: Uses just-in-time research pattern (`.cursor/skills/just-in-time-research/SKILL.md`) for design patterns, tokens, and accessibility standards

## Just-In-Time Research

Before creating/extracting design system, conduct research for:
- **Design Tokens**: Web search for token naming conventions, best practices
- **Component Patterns**: Web search for component library structures
- **Accessibility Standards**: Web search for WCAG 2.1 AA requirements, ARIA patterns
- **Design System Examples**: Web search for industry-standard design systems
- **Deep Research** (if needed): Custom design language development

Document findings in "Research Informing This Design System" section of output.

## Interactive Design System Creation

**MODE SELECTION**: Branch based on detected mode

---

## BROWNFIELD MODE (Extract from Existing UI)

**Prerequisites**: Codebase has UI components (detected from scan or manual inspection)

### Step 1: Analyze Existing UI Code

**Scan for design tokens in code**:
```bash
# Find CSS/styling files (conceptual)
grep -r "color:" frontend/
grep -r "fontSize:" frontend/
grep -r "spacing:" frontend/
grep -r "borderRadius:" frontend/

# Find component files
ls frontend/components/
ls src/ui/
```

**Extract existing patterns**:
- Colors used in code (primary, secondary, accent, neutrals)
- Font sizes and families
- Spacing values (margin, padding)
- Border radius values
- Shadow definitions
- Component patterns

### Step 2: Consolidate into Token System

**From extracted values, create systematic tokens**:

**Colors** (extract from actual usage):
- Primary: [#XXXXXX - used for CTAs, primary actions]
- Secondary: [#XXXXXX - used for secondary actions]
- Neutrals: [#XXXXXX, #XXXXXX, etc. - grays used in UI]
- Semantic: [Success, Warning, Error colors found in code]

**Typography** (extract from actual usage):
- Font families: [Fonts actually used]
- Sizes: [All fontSize values found, consolidated into scale]
- Weights: [Font weights used]

**Spacing** (extract from actual usage):
- Base unit: [Infer from most common values - 4px or 8px]
- Scale: [All spacing values found, mapped to scale]

**Components** (extract from actual files):
- List all existing components with file paths
- Document props/variants found in code
- Note inconsistencies (same component with different patterns)

### Step 3: Identify Gaps & Inconsistencies

**Document findings**:
- Inconsistent color usage: [Examples of same semantic meaning, different colors]
- Arbitrary spacing values: [Values not on systematic scale]
- Missing components: [UI patterns built ad-hoc vs reusable components]
- Accessibility gaps: [Missing ARIA, color contrast issues]

### Step 4: Generate Design System (Descriptive + Prescriptive)

Create design-system.md with:
- **Existing Tokens** section (what code currently uses)
- **Recommended Tokens** section (consolidated into systematic scale)
- **Migration Guide** section (how to move from arbitrary to systematic)
- **Component Inventory** section (what exists, what's missing)

Mark extraction source:
```markdown
> **Extraction Note**: This design system was extracted from existing codebase.
> "Existing" sections are DESCRIPTIVE (current state).
> "Recommended" sections are PRESCRIPTIVE (systematic improvements).
> Migrate gradually - new components use recommended tokens.
```

---

## GREENFIELD MODE (Create New Design System)

**Purpose**: Create design system from scratch based on UX strategy

### Step 1: Design Token Definition

Guide through foundational decisions:

**Color System**
- "What's your primary brand color?" (show picker options)
- "Do you need dark mode support?"
- Generate: Primary, secondary, neutral, semantic colors

**Typography Scale**
- "Preferred font family?" (or suggest based on personality)
- Generate: Type scale (xs through 6xl)
- Define: Line heights, letter spacing, font weights

**Spacing System**
- "Prefer a 4px or 8px base unit?"
- Generate: Spacing scale (0.5x through 12x)
- Define: Component padding standards

**Shape & Effects**
- "Corner radius preference?" (sharp/slightly/rounded/pill)
- "Shadow intensity?" (none/subtle/moderate/dramatic)
- Generate: Radius scale, shadow scale

### Step 2: Component Architecture

**Component Categories**
```
Primitives: Button, Input, Label, Link
Layout: Container, Grid, Stack, Divider  
Feedback: Alert, Toast, Spinner, Progress
Navigation: Nav, Tabs, Breadcrumb, Pagination
Overlay: Modal, Drawer, Tooltip, Popover
Data Display: Table, List, Card, Badge
```

For each category, ask:
- "Which components will you need?"
- "Any special variations required?"

### Step 3: Pattern Library

**Interaction Patterns**
- Form validation approach
- Loading states
- Empty states
- Error handling
- Success feedback

**Layout Patterns**
- Page templates
- Section layouts
- Responsive behavior
- Grid system

### Step 4: Accessibility Standards

Ensure inclusive design:
- Color contrast ratios
- Focus states
- Keyboard navigation
- Screen reader support
- Touch targets

### Step 5: Create Design System

1. Load template: `.speck/templates/project/design-system-template.md`
2. Create base file: `specs/projects/[PROJECT_ID]/design-system.md`
3. Fill systematically:
   - Generate color tokens from brand colors
   - Create typography scale
   - Define spacing system
   - List needed components
   - Document patterns
   - Add implementation notes

Additional files can be created:
- `design-system/components/` - Individual component specs
- `design-system/patterns/` - Detailed pattern guides
- `design-system/examples/` - Code samples

### Step 6: Review and Guide

Present what was created:
- "I've created the design system at [path]"
- "Defined [X] color tokens, [Y] components"
- "Documented key patterns and guidelines"

Integration guidance:
- Next in flow: `/project-architecture` (system design using design tokens)
- Or skip to: `/project-roadmap` (if architecture not needed)
- Later usage: `/epic-wireframes`, `/story-ui-spec` will reference these tokens
- Implementation: Build component library (consider Storybook)
- Export: Design tools like Figma/Sketch for design team

Note: Design system provides visual design inputs for architecture decisions

The template contains comprehensive sections for tokens, components, patterns, and implementation.

## Context Management

Since commands can't rely on directory context:
- Always ask for project specification
- Store design system reference in project plan
- Link to design system from all epic/story specs
- Maintain version history for changes

## Success Criteria

A complete design system includes:
✅ Complete token definitions
✅ Core component specifications  
✅ Interaction patterns
✅ Accessibility guidelines
✅ Implementation examples
✅ Clear documentation
