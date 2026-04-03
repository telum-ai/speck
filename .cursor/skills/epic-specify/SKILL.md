---
name: epic-specify
description: Load when starting work on an epic — either enhancing a placeholder created by project-plan, or creating a new epic from scratch. Use when user says 'let's work on [epic name]' or 'start the [feature] epic'. Produces epic.md — required before all other epic commands.
disable-model-invocation: false
---


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

The text the user typed after `/epic-specify` in the triggering message should contain the epic description. Parse any context hints from the arguments.

## Play Level Check

Read `.speck/project.json` (if it exists) for `play_level`.

- **Sprint**: Epics don't exist at Sprint level. Tell the user: "Sprint projects don't use epics — the Build Plan in your PRD.md is enough. If this project is growing beyond a sprint, run `/project-promote` to move to Build level, then come back here."
- **Build** or **Platform**: Proceed normally below.

## Context Detection (NEW)

First, check if we're already in an epic context:

### Check Current Directory
```bash
# Are we in an epic directory with existing epic.md?
if [[ -f "epic.md" ]]; then
    # ENHANCE MODE: Working with existing epic placeholder
    echo "Found existing epic.md - entering enhance mode"
    EPIC_MODE="enhance"
    EPIC_PATH=$(pwd)
else
    # CREATE MODE: Need to create new epic
    echo "No epic.md found - entering create mode"
    EPIC_MODE="create"
fi
```

## Mode 1: Enhance Existing Epic

If epic.md exists (created by /project-plan):

1. **Load existing content**:
   - Parse any pre-filled information
   - Extract epic name, ID, initial scope
   - Note which sections are placeholders
   - **Check `**Current State**`**: If it reads `Draft (Placeholder)` or `Draft`, this is a
     `/project-plan` placeholder — proceed with full enhance flow below.
     If it already reads `Specified`, warn the user that `/epic-specify` appears to have been
     run already and ask if they want to re-specify or refine.

2. **Identify gaps**:
   - Which sections need completion?
   - What details are missing?
   - Any conflicts with project vision?

3. **Interactive completion**:
   - Skip questions for already-filled sections
   - Focus on missing information
   - Validate against project PRD/epics.md

4. **Preserve context**:
   - Keep epic ID and directory structure
   - Maintain any dependencies noted
   - Respect pre-defined scope boundaries

5. **After completing the epic.md** (ENHANCE mode):
   - Update `**Current State**: Specified`
   - Mark lifecycle checkboxes: `- [x] **Draft**` (keep checked), `- [x] **Specified**`

## Mode 2: Create New Epic

If no epic.md exists, proceed with full creation:

### Interactive Context Discovery

Since commands can't rely on directory context, we need explicit identification:

### Step 1: Project Identification
Parse arguments for context clues:
- Look for "project:XXX" or "in project XXX"
- Look for "for [project name]"
- If not found, ask: "Which project should this epic belong to?"

List available projects:
```bash
find specs/projects -name "project.md" | sed 's|/project.md||' | sed 's|specs/projects/||'
```

### Step 2: Pre-Validation Checklist (Prevent Duplication)

Before creating the epic, check:

**Duplication Check (Docs/Specs Only)**:
- [ ] Check if similar epic already exists in this project
  - Review PRD.md and epics.md for similar feature sets
  - Check existing epic specs in `epics/` directory
  - If similar exists: Suggest updating/expanding existing vs creating new
  
- [ ] Check if this belongs at epic level
  - Is it large enough for an epic? (>3 stories, 10-minute explainability)
  - Or should it be a story within existing epic?
  - Or multiple epics if description needs "AND"?
  
- [ ] Review project scope alignment
  - Load PRD.md to understand project goals
  - Validate epic aligns with project vision
  - If misaligned: Question if this belongs in project

**Clarify if Ambiguous**:
- [ ] If request is ambiguous: Ask 1-2 clarifying questions before scaffolding
- [ ] Verify user intent and scope before creating spec

**Note**: Only check specs/docs for duplication, not implementation code.

### Step 3: Epic Scope Discovery

If minimal description provided:
- "What's the main objective of this epic?"
- "What user problems will it solve?"
- "How does it fit into the project vision?"

Load project context:
- `specs/projects/[PROJECT_ID]/project.md`
- `specs/projects/[PROJECT_ID]/PRD.md` 
- `specs/projects/[PROJECT_ID]/epics.md`
- `specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/epic-codebase-scan.md` (if exists - brownfield)

**Brownfield Detection**: If `epic-codebase-scan.md` exists, use it to pre-fill epic sections with discovered features and architecture.

### Step 4: Epic Details Gathering

**Core Questions:**
1. "Who are the primary users for this epic?"
2. "What are the key features/capabilities?"
3. "What defines success for this epic?"

**Technical Questions:**
4. "Any technical constraints or requirements?"
5. "Dependencies on other epics or systems?"
6. "Estimated complexity (Small/Medium/Large)?"

### Step 5: Epic Creation/Enhancement

**For CREATE mode:**
Generate epic ID (next available number):
```bash
# Find highest epic number in project (supports E###- and legacy ###- prefixes)
ls specs/projects/[PROJECT_ID]/epics/ \
  | grep -E '^(E[0-9]{3}|[0-9]{3})' \
  | sed -E 's/^E?([0-9]{3}).*/\1/' \
  | sort -n \
  | tail -1
```

Create epic directory:
- `specs/projects/[PROJECT_ID]/epics/[EPIC_ID]-[epic-name]/`

**For ENHANCE mode:**
- Use existing directory and epic ID
- Load current epic.md content
- Identify placeholder sections

**For both modes:**

3. Load epic template from `.speck/templates/epic/epic-template.md`

4. Fill/enhance epic specification with:
   - Epic context from PRD and project goals
   - Business value proposition
   - User stories within epic scope
   - Success criteria specific to epic
   - Dependencies on other epics
   - Technical constraints inherited from project
   - Risk factors specific to epic

5. Epic specification structure:
   - Overview and value proposition
   - User stories and acceptance criteria
   - Functional requirements (epic-scoped)
   - Technical considerations
   - Dependencies and integration points
   - Success metrics
   - Risk mitigation

6. Maintain epic boundaries:
   - Ensure no overlap with other epics
   - Clear handoff points defined
   - Standalone value delivery confirmed
   - Dependencies explicitly stated

7. Apply 10-Minute Understandability Rule:

   Before finalizing, validate epic scope:
   
   **10-Minute Test**: Can you explain this epic to a new teammate in <10 minutes?
   - What capability it delivers
   - Why it's valuable
   - How it fits in the project
   
   **If NO** → Epic is too broad, split it!
   
   **Check for "AND"**: Does the epic description need "AND"?
   - Example: "Authentication AND user management AND admin panel"
   - Action: Split into separate epics
   
   **Complexity Indicators**:
   - Needs >15 user stories → Probably multiple epics
   - Spans multiple user journeys → Consider splitting
   - Requires extensive context from multiple epics → Too coupled
   
   If epic seems too complex, suggest splitting and ask user approval.

8. Save epic.md in epic directory, ensuring:
   - `**Current State**: Specified` is set in the lifecycle section
   - The lifecycle checkboxes read:
     ```
     - [ ] **Draft** - Placeholder created by `/project-plan` (not yet specified)
     - [x] **Specified** - epic.md created by `/epic-specify`
     ```
     (For ENHANCE mode where a Draft existed: check both Draft and Specified)

9. Report completion based on mode:

   **For ENHANCE mode:**
   ```
   ✅ Epic Specification Enhanced!

   Epic: [Name]
   Path: [Path]

   Sections Completed: [List]
   Sections Preserved: [List]
   ```

   **For CREATE mode:**
   ```
   ✅ Epic Specification Created!

   Epic: [Name]
   Path: [Path]
   Estimated Stories: [X]
   Dependencies: [List]
   ```

10. **Optional Step Evaluation** (REQUIRED — run immediately after every epic-specify)

    Scan the content of the just-saved `epic.md` and evaluate each optional step. Output a recommendation table with the **specific text or observation from epic.md** that drove each decision — not generic advice.

    **Evaluation criteria**:

    | Step | 🔴 Required when | ⚠️ Recommended when | ⬜ Skip when |
    |------|-----------------|---------------------|------------|
    | `/epic-clarify` | Acceptance criteria missing or vague; scope boundary unclear; [NEEDS CLARIFICATION] markers remain | Some user stories lack explicit success criteria | All stories have clear, testable acceptance criteria and scope is explicit |
    | `/epic-constitution` | Regulated domain (healthcare, finance, legal, payment, GDPR, HIPAA, SOC2); epic defines an API boundary other epics depend on; multi-team coordination required | Epic introduces domain-specific rules not covered by project constitution | Simple product feature with no compliance or cross-team concerns |
    | `/epic-architecture` | Touches 2+ services/systems; introduces new infrastructure; explicit latency/throughput targets; complex third-party integration not yet used in project | Significantly modifies existing API contracts; introduces new architectural patterns | Simple CRUD following existing project patterns; single-service concern with clear path |
    | `/epic-journey` + `/epic-wireframes` | Any mention of: UI, screen, page, dashboard, form, modal, user flow, navigation, front-end, UX, design | Epic mixes backend and light UI concerns | Explicitly backend-only, API-only, CLI-only, or infra/devops |
    | `/epic-outline` | Unfamiliar technology not in architecture.md; TBD/unknown sections present; multiple competing technical approaches | Minor unknowns that could benefit from a research pass | Implementation path clear; follows established patterns |

    **Output format** (fill from actual epic content — no placeholders):

    ```
    ## Optional Step Evaluation

    | Step | Recommendation | Evidence from epic.md |
    |------|---------------|----------------------|
    | /epic-clarify              | ⬜ / ⚠️ / 🔴 | "[specific quote or observation]" |
    | /epic-constitution         | ⬜ / ⚠️ / 🔴 | "[specific quote or observation]" |
    | /epic-architecture         | ⬜ / ⚠️ / 🔴 | "[specific quote or observation]" |
    | /epic-journey + /wireframes| ⬜ / 🔴       | "[specific quote or observation]" |
    | /epic-outline              | ⬜ / ⚠️       | "[specific quote or observation]" |

    Recommended path to /epic-plan:
    → [only Required/Recommended steps in flow order] → /epic-plan

    Shall I proceed with [first recommended step]?
    ```

    **Flow order**: `/epic-clarify` → `/epic-constitution` → `/epic-architecture` → `/epic-journey` → `/epic-wireframes` → `/epic-outline` → `/epic-plan`

    **If `/epic-journey` or `/epic-wireframes` is 🔴 Required**, add this warning explicitly:
    > "This epic has user-facing UI — journey mapping and wireframes are required before planning. Skipping them means each story invents its own UI independently, producing a disconnected product."

## Example Workflows

**Workflow 1: After project-plan**
```bash
cd specs/projects/001-my-app/epics/E001-authentication
/epic-specify
# Detects existing epic.md, enhances it with full specification
```

**Workflow 2: Creating new epic**
```bash
/epic-specify "Add real-time notifications to my app"
# No epic.md found, creates new epic from scratch
```
