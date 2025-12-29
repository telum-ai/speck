---
description: Create or update the story specification from a natural language story description within an epic context.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

The text the user typed after `/story-specify` in the triggering message **is** the story description. Assume you always have it available in this conversation even if `$ARGUMENTS` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

## Context-Aware Story Creation

Since commands can't rely on directory context, establish hierarchy:

### Step 1: Context Discovery

Parse arguments for context:
- "project:XXX epic:YYY [story description]"
- "in epic YYY of project XXX"
- "for [epic name] in [project name]"

If context missing, ask progressively:
1. "Which project is this story for?"
2. "Which epic does this story belong to?"
3. "What's the story description?"

List available options:
```bash
# List projects
find specs/projects -name "project.md" -exec dirname {} \; | xargs -I {} basename {}

# List epics for selected project
ls specs/projects/[PROJECT_ID]/epics/
```

### Step 2: Detect Draft Spec (From Epic Breakdown)

Check if a draft spec exists from `/epic-breakdown`:

```bash
# Check for draft spec in story directory
if [ -f "specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/stories/[STORY_ID]/spec-draft.md" ]; then
  echo "Draft spec found - will upgrade to full spec"
fi
```

**If `spec-draft.md` exists**:
1. Load the draft as a starting point
2. Display to user: "Found draft spec from epic breakdown. I'll use this as a starting point."
3. Validate and enhance through interactive Q&A (Steps 4-8)
4. Save the finalized version as `spec.md` (replacing/alongside the draft)
5. Keep `spec-draft.md` for reference, or delete after successful upgrade

**If no draft exists**: Continue with normal interactive specification flow.

### Step 3: Pre-Validation Checklist (Prevent Duplication)

Before creating the story, check:

**Duplication Check (Docs/Specs Only)**:
- [ ] Check if similar story already exists in this epic
  - Search epic-breakdown.md for similar story names/descriptions
  - Review existing story specs in `stories/` directory
  - If similar exists: Suggest updating existing vs creating new
  
- [ ] Check if this belongs at story level
  - Is it small enough for a story? (5-minute explainability)
  - Or should it be an epic? (if >10 stories or major feature)
  
- [ ] Review epic scope alignment
  - Load epic.md to understand epic goals
  - Validate story aligns with epic scope
  - If misaligned: Suggest different epic or epic scope expansion

**Clarify if Ambiguous**:
- [ ] If request is ambiguous: Ask 1-2 clarifying questions before scaffolding
- [ ] Verify user intent before creating spec

**Note**: Only check specs/docs for duplication, not implementation code.

### Step 4: Load Context Documents

Load project-level documents for consistency:
```
LOAD (if exists):
- specs/projects/[PROJECT_ID]/domain-model.md → Domain terminology and rules
- specs/projects/[PROJECT_ID]/ux-strategy.md → UX principles and voice
- specs/projects/[PROJECT_ID]/design-system.md → UI components and tokens
```

**Domain Model Usage**:
- Use glossary terms from domain-model.md in story descriptions
- Respect domain invariants in acceptance criteria
- Reference domain entities for data requirements

### Step 5: Story Validation

Validate story fits epic scope:
- Load epic spec: `specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/epic.md`
- Validate story aligns with epic goals
- If duplication found: "Similar story exists: [name]. Should we update that instead?"

If mismatch: "This story seems outside the epic scope. Would you like to:
1. Create it in a different epic?
2. Expand the current epic scope?
3. Create a new epic for this?"

### Step 6: Interactive Story Development

If minimal description (or upgrading from draft), gather/validate details:

**If upgrading from `spec-draft.md`**:
- Show draft content to user
- Ask: "Does this draft capture your intent? What would you change?"
- Focus on gaps and refinements rather than starting from scratch

**If starting fresh**, gather details:

**Story Essentials:**
1. "As a [who], I want to [what], so that [why]"
2. "What triggers this story?"
3. "What indicates completion?"

**Acceptance Criteria:**
4. "What are the must-have requirements?"
5. "Any specific constraints?"
6. "How will we test this?"

**Technical Considerations:**
7. "Frontend, backend, or both?"
8. "Any API changes needed?"
9. "Database impacts?"

### Step 7: Create Story Structure

Create directly in the **current hierarchical structure** (if not already created by epic-breakdown):
```bash
# Generate story ID and create directory (skip if already exists from epic-breakdown)
mkdir -p specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/stories/[STORY_ID]-[story-name]
```

Note: Speck stories live in the hierarchical structure under:
`specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/stories/[STORY_ID]-[story-name]/`

### Step 8: Story Specification

**CRITICAL**: Load and follow the template exactly:
```
.speck/templates/story/story-template.md
```

The template is self-documenting - follow all sections and guidelines within it.

**Output**: Save as `spec.md` (this is the canonical spec, distinct from any `spec-draft.md`).

### Step 9: Apply 10-Minute Understandability Rule

Before finalizing, validate story scope:

**5-Minute Test**: Can you explain this story to a new teammate in <5 minutes?
- What it does
- Why it's needed  
- How success is measured

**If NO** → Story is too complex, split it!

**Check for "AND"**: Does the story description need "AND"?
- Example: "Add login form AND registration flow"
- Action: Split into separate stories

**Complexity Indicators**:
- Needs >3 acceptance scenarios → Might be multiple stories
- Touches >3 different components → Might be too broad
- Requires extensive context to explain → Simplify or split

If story seems too complex, suggest splitting and ask user approval.

### Step 10: Update Epic Tracking

Add story to epic's story list with status "specified"

### Step 11: Guide Next Steps

```
✅ Story Specification Created!

Next Steps:
- Recommended: /story-clarify (resolve any ambiguities)
- If already clear: /story-plan (create technical design)
- If UI-heavy: /story-ui-spec (design interfaces first)
- If complex tech: /story-outline, then follow the just-in-time research pattern
  (`.speck/patterns/just-in-time-research-pattern.md`) for the outline’s open questions/queries,
  then proceed to /story-plan
- If extracting patterns: /story-scan (analyze existing code)

Note: /story-plan is the gateway to implementation - it generates the technical
blueprint that /story-tasks will break down into executable steps.
```

Note: If your team uses a branch-based workflow, create a branch for this story (e.g. `[STORY_ID]-[story-name]`) before implementation.
