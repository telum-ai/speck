---
description: Create or update the project specification from a natural language project description.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

The text the user typed after `/project-specify` in the triggering message **is** the project description. Assume you always have it available in this conversation even if `$ARGUMENTS` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

## Interactive Project Specification Process

### Step 0: Detect Mode (Greenfield vs Brownfield)

Check for brownfield indicators in the active project directory:
- Look for `project-import.md` (non-code aspects extraction)
- Look for `project-landscape-overview.md` (code aspects extraction)

**If EITHER exists → BROWNFIELD MODE**
**If NEITHER exists → GREENFIELD MODE**

---

### Step 0.5: Recipe Detection (Greenfield Only)

**For greenfield projects**, check if the user's description matches a known recipe:

1. **Scan recipe keywords**: Read `.speck/recipes/*/recipe.yaml` files and match `keywords:` against user input
2. **If match found**, offer the recipe:
   ```
   🍳 I found a matching recipe: "[recipe display_name]"
   
   This recipe provides:
   - Stack: [frontend + backend + database from recipe]
   - Pre-configured patterns for [key patterns]
   - Suggested epics: [list epic names from suggested_epics]
   
   Options:
   1. Use this recipe (pre-fills architecture, context, and epic suggestions)
   2. Start from scratch (full custom specification)
   3. See other recipes
   
   Your choice [1]:
   ```

3. **If user selects recipe**:
   - Store recipe selection: `_active_recipe: [recipe-name]` in project.md metadata
   - Pre-fill relevant sections from recipe's `stack:`, `ideal_for:`, `patterns:`
   - Recipe will also inform `/project-architecture`, `/project-context`, and `/project-plan`

4. **If no match or user declines**: Continue with standard greenfield flow

**Recipe Reference**: See `.speck/recipes/README.md` for available recipes and their use cases.

---

### GREENFIELD MODE: Create from Scratch

### Step 1: Parse and Validate Input

Analyze the provided project description:
- Extract key concepts from `$ARGUMENTS`
- If empty or too vague, ask: "What would you like to build?"
- If minimal, identify what's missing for the template

### Step 2: Interactive Gap Filling

The project template needs specific information. If any of these are missing from the input, ask targeted questions:

**If project type unclear:**
- "Is this a web app, mobile app, API, or something else?"

**If user groups undefined:**
- "Who will use this product?"

**If core problem unstated:**
- "What main problem does this solve?"

**If scale ambiguous:**
- "Is this a small enhancement, a new feature set, or a full platform?"

### Step 2.5: Domain Expertise Check

Determine if this project requires specialized domain knowledge:

**Ask if domain is specialized:**
- "Does this product operate in a specialized domain that requires subject matter expertise?"
- Examples: Healthcare, Finance, Fitness/Exercise Science, Legal, Agriculture, Education

**If YES (specialized domain):**
- Note in project.md: `**Domain Expertise Required**: Yes - [domain name]`
- Capture any initial domain knowledge the user provides
- Flag for `/project-domain` command after clarification

**If NO (generic/technical domain):**
- Note in project.md: `**Domain Expertise Required**: No`
- Skip `/project-domain` in the recommended flow

**Why this matters**: Projects with specialized domains need a domain model to capture terminology, rules, and principles that inform all downstream decisions.

### Step 3: Create Project Structure

Once we have enough information:

1. Run `bash .speck/scripts/bash/create-new-project.sh --json "$ARGUMENTS"` to create project structure
2. Load `.speck/templates/project/project-template.md`
3. Fill the template systematically:
   - Parse description for each template section
   - Use provided information where available
   - Mark gaps with [NEEDS CLARIFICATION: specific question]
   - Don't leave generic placeholders

### Step 4: Review and Guide

Show what was created:
- "I've created the project specification in [path]"
- "Key areas marked for clarification: [list]"
- "The project appears to be [scale] complexity"

Guide to next steps:
- Recommended: `/project-clarify` (resolve ambiguities & identify research needs)
- If domain expertise required: `/project-domain` (capture subject matter knowledge)
- Then: `/project-ux` or `/project-context`

**Note**: `/project-clarify` is strongly recommended to ensure specification completeness before planning. For specialized domains (healthcare, fitness, finance, etc.), `/project-domain` captures critical subject matter expertise.

---

### BROWNFIELD MODE: Pre-fill from Import/Scan Data

### Step 1: Load Extraction Artifacts

Load brownfield artifacts that exist:
- `project-import.md` → Non-code aspects (vision, stakeholders, constraints)
- `project-landscape-overview.md` → Code aspects (tech stack, features, architecture)

### Step 2: Pre-fill Project Template

1. Load `.speck/templates/project/project-template.md`
2. Pre-fill sections from extracted data:

**From project-import.md (if exists):**
- Project Vision → Use discovered vision/purpose
- Target Users → Use stakeholder findings
- Success Metrics → Use existing metrics if found
- Goals → Infer from documented objectives

**From project-landscape-overview.md (if exists):**
- Current State → Use scan's "Current State" section
- Core Features → Use scan's "Potential Epic Areas"
- Tech Stack (in context) → Use scan's "Tech Stack" findings
- Architecture Overview → Reference scan findings

**Markers for pre-filled content:**
- Mark with `[FROM IMPORT]` for data from project-import.md
- Mark with `[INFERRED FROM CODE]` for data from project-landscape-overview.md
- Mark with `[NEEDS VALIDATION]` for uncertain inferences

### Step 3: Interactive Completion

Ask targeted questions to fill gaps that **cannot be discovered from code**:
- Strategic vision and long-term goals
- User personas and pain points
- Success metrics and business objectives
- Competitive positioning
- Constraints not evident in code (budget, team, timeline)

**Skip questions about:**
- Existing features (already in scan)
- Tech stack (already in scan)
- Current architecture (already in scan)

### Step 4: Generate Final project.md

Combine:
- Pre-filled sections from import/scan
- User-provided strategic information
- Validated inferences

Generate `project.md` with all markers preserved for transparency.

### Step 5: Review and Guide

Show what was created:
- "I've created the project specification in [path]"
- "Pre-filled from import/scan data: [list sections]"
- "Areas needing validation: [list NEEDS VALIDATION markers]"
- "Strategic areas completed through Q&A: [list]"

Guide to next steps:
- Recommended: `/project-clarify` (focus on non-discoverable aspects)
- If domain expertise required: `/project-domain` (capture/document domain knowledge)
- Then: `/project-context` (pre-fills tech from scan, asks for team constraints)

**Note**: Even in brownfield mode, `/project-clarify` helps focus on strategy and future direction, not just documenting what exists. For specialized domains, `/project-domain` captures the subject matter expertise that may be implicit in the existing codebase.

---

## Key Differences Summary

| Aspect | Greenfield | Brownfield |
|-----|----|-----|
| Starting Point | User description | Import/scan artifacts |
| Questions | All aspects | Strategic/non-discoverable only |
| project.md | From scratch | Pre-filled, then completed |
| Markers | [NEEDS CLARIFICATION] | [FROM IMPORT], [INFERRED FROM CODE], [NEEDS VALIDATION] |
| Focus | Define what to build | Document + enhance what exists |

The template itself contains all the detailed guidance for what goes in each section.
