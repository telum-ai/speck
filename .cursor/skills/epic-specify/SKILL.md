---
name: epic-specify
description: Load when starting work on an epic — either enhancing a placeholder created by project-plan, or creating a new epic from scratch. Use when user says 'let's work on [epic name]' or 'start the [feature] epic'. Produces epic.md — required before all other epic commands. FIRST ACTION after loading: read template at .speck/templates/epic/epic-template.md before any Q&A or artifact generation.
disable-model-invocation: false
---


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

The text the user typed after `/epic-specify` in the triggering message should contain the epic description. Parse any context hints from the arguments.

## ⚠️ Step 0: Read Template First

**Before any other action** — read this template now using the Read tool:
```
.speck/templates/epic/epic-template.md
```
The template defines required sections and formatting for `epic.md`. Reading it first shapes your Q&A — you'll know exactly what information to gather (JTBD, success criteria, dependencies, scope boundaries, etc.). Generating `epic.md` from memory without reading this template produces structurally incorrect output.

**Checkpoint**: After reading, note the top-level sections from the template. Then continue to Play Level Check.

## Play Level Check

Read `.speck/project.json` (if it exists) for `play_level`.

- **Sprint**: Epics don't exist at Sprint level. Tell the user: "Sprint projects don't use epics — the Build Plan in your PRD.md is enough. If this project is growing beyond a sprint, run `/project-promote` to move to Build level, then come back here."
- **Build** or **Platform**: Proceed normally below.

## Pre-Specify Check (v7 — Mandatory Gate)

Read `project-state.md` (or list `specs/projects/<PROJECT_ID>/epics/` directory and check validation reports).
If there is an existing epic in the project that has completed implementation (all stories implemented) but has NOT yet passed `/epic-validate` (i.e. does not have an `epic-validation-report.md` claiming a verified readiness state of `UX-RC` / `API-RC` or higher, or is still listed as unvalidated):
- **STOP**. You are NOT allowed to specify or start work on a new epic (unless creating the Infrastructure epic `E000`) while a prior active epic's validation is outstanding.
- **Exception**: If the user provides `--force` with an explicit, logged rationale.
- **Rationale**: To prevent the composition fallacy, we must validate that each completed epic is fully integrated and usable before shifting the team's context to a new one.

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

    **Brownfield vs greenfield UI signal**: Check whether `epic-codebase-scan.md` exists in the epic directory. If it exists and lists existing screens/surfaces the epic will modify (not net-new only), treat the epic as **brownfield UI**.

    **Ambition-aware UI path signal** (REQUIRED — load before evaluating UI path):
    1. Read `product-contract.md` Section 3 (Differentiator) and Section 5 (Magic Moments) — note surfaces named in **Surface / System Boundary** fields.
    2. Read `ux-strategy.md` (if present) — note target experience claims that diverge from what currently ships.
    3. Cross-check epic scope against those differentiating surfaces.
    4. If the product claims a **modality / experience differentiator** (new UX paradigm, premium redesign, first-principles redraw) AND this epic touches those differentiating surfaces → flag **Redesign Ambition**.
    5. **Redesign Ambition overrides brownfield default**: Rubric Mode is NOT auto-selected. `/epic-journey` + `/epic-wireframes` are 🔴 Required unless the founder explicitly confirms existing surfaces are modality-adequate (log as human decision gate — do not proceed silently).

    **Evaluation criteria**:

    | Step | 🔴 Required when | ⚠️ Recommended when | ⬜ Skip when |
    |------|-----------------|---------------------|------------|
    | `/epic-clarify` | Acceptance criteria missing or vague; scope boundary unclear; [NEEDS CLARIFICATION] markers remain | Some user stories lack explicit success criteria | All stories have clear, testable acceptance criteria and scope is explicit |
    | `/epic-constitution` | Regulated domain (healthcare, finance, legal, payment, GDPR, HIPAA, SOC2); epic defines an API boundary other epics depend on; multi-team coordination required | Epic introduces domain-specific rules not covered by project constitution | Simple product feature with no compliance or cross-team concerns |
    | `/epic-architecture` | Touches 2+ services/systems; introduces new infrastructure; explicit latency/throughput targets; complex third-party integration not yet used in project | Significantly modifies existing API contracts; introduces new architectural patterns | Simple CRUD following existing project patterns; single-service concern with clear path |
    | `/epic-journey` + `/epic-wireframes` | **Greenfield UI**: any mention of UI, screen, page, dashboard, form, modal, user flow, navigation, front-end, UX, design AND surfaces are net-new or undefined in codebase; **OR Redesign Ambition**: epic touches differentiating surfaces named in product-contract / ux-strategy | Epic mixes backend and light UI concerns (greenfield) | Explicitly backend-only, API-only, CLI-only, or infra/devops |
    | **Rubric Mode** (brownfield UI alternative) | **Brownfield UI** (code exists) AND epic modifies existing screens AND **NOT Redesign Ambition** — use instead of per-surface journey + wireframes | — | Greenfield UI, Redesign Ambition, OR backend-only epic |
    | **Redesign Ambition gate** | Epic modifies a surface named in product-contract differentiator or magic-moment boundaries | — | Surfaces are genuinely modality-adequate (founder confirmed) OR epic is backend-only |
    | `/epic-outline` | Unfamiliar technology not in architecture.md; TBD/unknown sections present; multiple competing technical approaches | Minor unknowns that could benefit from a research pass | Implementation path clear; follows established patterns |

    **Rubric Mode** (sanctioned brownfield UI path — only when surfaces are modality-adequate):

    When brownfield UI is detected **and Redesign Ambition is NOT triggered**, recommend **Rubric Mode** instead of `/epic-journey` + `/epic-wireframes`:

    1. Encode a one-page **Native Screen Rubric** (principles + screen anatomy) as an enforced standard in `ux-strategy.md` and/or `design-system/primitives.md`.
    2. Derive FRs from the rubric; apply surface-by-surface to existing screens listed in `epic-codebase-scan.md`.
    3. Wireframe **only net-new screens** in their story specs (`ui-spec.md` / story-level wireframes) — do not duplicate wireframes for surfaces that already ship.
    4. Still run `/epic-experience-chain` if the epic changes cross-screen seams (entry/handoff between existing surfaces).

    Rubric Mode prevents per-surface divergence better than N duplicate wireframe docs for screens that already exist.

    **Output format** (fill from actual epic content — no placeholders):

    ```
    ## Optional Step Evaluation

    | Step | Recommendation | Evidence from epic.md |
    |------|---------------|----------------------|
    | /epic-clarify              | ⬜ / ⚠️ / 🔴 | "[specific quote or observation]" |
    | /epic-constitution         | ⬜ / ⚠️ / 🔴 | "[specific quote or observation]" |
    | /epic-architecture         | ⬜ / ⚠️ / 🔴 | "[specific quote or observation]" |
    | /epic-journey + /wireframes| ⬜ / 🔴       | "[greenfield UI evidence — or Redesign Ambition surfaces from product-contract]" |
    | Rubric Mode (brownfield UI) | ⬜ / 🔴      | "[epic-codebase-scan surfaces + brownfield signal — only if NOT Redesign Ambition]" |
    | Redesign Ambition gate     | ⬜ / 🔴 / ✅ founder-confirmed | "[differentiator surfaces touched + product-contract quote]" |
    | /epic-outline              | ⬜ / ⚠️       | "[specific quote or observation]" |

    UI path: [Greenfield → journey + wireframes | Redesign Ambition → journey + wireframes | Brownfield (adequate surfaces) → Rubric Mode | Backend-only → skip UI artifacts]

    Recommended path to /epic-plan:
    → [only Required/Recommended steps in flow order] → /epic-plan
    ```

    **Continuation (do NOT treat this menu as a stop):**
    - **Orchestrated / background / delegated run** (invoked by `/epic` or a conductor): this table is informational — **immediately proceed to the first recommended step**. Do NOT end your turn at the menu; the epic lifecycle is incomplete. A genuine decision gate (a 🔴 Redesign Ambition founder confirmation, unresolved `[NEEDS CLARIFICATION]`) is the ONLY reason to stop here.
    - **Interactive single-step run** (a human invoked `/epic-specify` directly): end with "Shall I proceed with [first recommended step]?" and wait.

    **Flow order (greenfield UI)**: `/epic-clarify` → `/epic-constitution` → `/epic-architecture` → `/epic-journey` → `/epic-wireframes` → `/epic-outline` → `/epic-plan`

    **Flow order (brownfield UI — Rubric Mode)**: `/epic-clarify` → `/epic-constitution` → `/epic-architecture` → **encode Screen Rubric in ux-strategy.md / primitives.md** → `/epic-outline` → `/epic-plan` (wireframe net-new screens only in story specs)

    **If `/epic-journey` or `/epic-wireframes` is 🔴 Required (greenfield UI)**, add this warning explicitly:
    > "This epic has user-facing UI — journey mapping and wireframes are required before planning. Skipping them means each story invents its own UI independently, producing a disconnected product."

    **If Redesign Ambition is 🔴 Required**, add this warning explicitly:
    > "This epic touches differentiating surfaces named in product-contract.md but code already exists — that does NOT mean the surfaces are modality-adequate. Run /epic-journey + /epic-wireframes before planning. Rubric Mode is prohibited unless the founder explicitly confirms existing surfaces meet the target experience."

    **If Rubric Mode is 🔴 Required (brownfield UI, NOT Redesign Ambition)**, add this guidance explicitly:
    > "This epic modifies existing screens that are modality-adequate — use Rubric Mode: one shared Screen Rubric in ux-strategy/primitives.md, FRs derived from it, applied surface-by-surface. Wireframe only net-new screens in story specs. Do not generate duplicate wireframes for surfaces that already ship."

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
