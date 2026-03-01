---
name: project-promote
description: Promote or downgrade a project between Sprint, Build, and Platform play levels with conversational guidance
disable-model-invocation: false
---

---
description: Conversational transition between Sprint, Build, and Platform play levels — preserving existing work.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## What This Does

`/project-promote` transitions a project between play levels:
- **Sprint → Build**: Expand the lightweight PRD, create context.md + COMMERCIAL.md, offer first epic
- **Build → Platform**: Scaffold constitution + design-system, flag missing artifacts
- **Downgrade**: Supported — strip artifacts and reduce requirements

Play levels live in `.speck/project.json` as `play_level`.

## Step 1: Read Current State

Read `.speck/project.json` to determine current play level.
If file doesn't exist, assume `platform` (backward compatible).

Also check what artifacts exist:
- `PRD.md` — sprint PRD or full PRD?
- `sprint-log.md` — Sprint tracking log
- `context.md`, `COMMERCIAL.md` — Build artifacts
- `constitution.md`, `design-system.md` — Platform artifacts
- `specs/projects/` — Epic/story structure

## Step 2: Determine Target Level

Parse arguments for target level:
- "to build", "promote to build", "--to build" → Build
- "to platform", "promote to platform" → Platform
- "downgrade to sprint" → Sprint
- "downgrade to build" → Build

If not specified, infer from context:
- Sprint → assume promoting to Build
- Build → assume promoting to Platform
- Platform → ask (promote or downgrade?)

Confirm with user before proceeding:
```
Current play level: Sprint
Target play level: Build

This will:
- Expand your PRD.md with full sections
- Create context.md (constraints and requirements)
- Create COMMERCIAL.md (revenue and business model)
- Preserve your sprint-log.md as history
- Offer to create your first epic

Shall I proceed? [Y/n]
```

## Step 3: Execute Transition

### Sprint → Build

1. **Expand PRD.md**
   - Read existing sprint PRD
   - Ask 3-5 targeted questions to fill out the full PRD:
     - "Who exactly are your users? Any segments?"
     - "What's the full feature set beyond the MVP you shipped?"
     - "What are your 90-day goals?"
   - Expand using `.speck/templates/project/prd-template.md` as structure
   - Preserve sprint PRD content as a "Sprint History" appendix section

2. **Create context.md**
   - Run `/project-context` flow (or inline a condensed version)
   - Focus on: tech constraints, team size, timeline, budget

3. **Create COMMERCIAL.md**
   - Revenue model details
   - Pricing strategy
   - GTM approach
   - Key business metrics

4. **Update `.speck/project.json`**
   ```json
   {
     "play_level": "build",
     "promoted_from": "sprint",
     "promoted_at": "[ISO date]"
   }
   ```

5. **Preserve sprint-log.md** — rename to `sprint-log-history.md` so it's clear it's historical

6. **Offer first epic**:
   ```
   Build promotion complete!

   Your sprint insights suggest these as strong first epics:
   1. [Inferred from sprint PRD build plan]
   2. [Inferred from sprint PRD kill criteria learnings]
   3. Start fresh with /epic-specify

   Which would you like to tackle first? [1/2/3/skip]
   ```

---

### Build → Platform

1. **Gap analysis** — check what's missing:
   - `architecture.md` missing? Flag it.
   - `constitution.md` missing? Offer to create it.
   - `design-system.md` missing? Offer to create it.
   - `ux-strategy.md` missing? Offer to create it.

2. **Scaffold missing artifacts** (only those the user confirms):
   ```
   Platform promotion requires these artifacts. Which shall we create now?

   [ ] constitution.md — technical principles and governance
   [ ] architecture.md — system design (recommended before planning)
   [ ] design-system.md — UI components and tokens
   [ ] ux-strategy.md — UX principles and user journeys

   Select all that apply [1,2,3,4 or 'all' or 'skip']:
   ```

3. **Update `.speck/project.json`**:
   ```json
   {
     "play_level": "platform",
     "promoted_from": "build",
     "promoted_at": "[ISO date]"
   }
   ```

4. **Next steps**:
   ```
   Platform promotion staged!

   Recommended next steps (in order):
   1. /project-architecture — design the system before planning
   2. /project-plan — create comprehensive PRD and epic breakdown
   3. /project-roadmap — sequence your epics
   ```

---

### Downgrade (Platform/Build → Sprint or Build)

Downgrades reduce artifact requirements without deleting work.

1. Confirm: "Downgrading reduces audit requirements but keeps all existing files. Continue?"
2. Update `.speck/project.json` with new play level
3. Note: "Your existing artifacts are preserved — the audit will simply check fewer requirements."

---

## Output Format

```
✅ Promoted to [Target Level]!

From: [Previous Level]
To: [New Level]

Created:
- [list of new files]

Preserved:
- [list of renamed/kept files]

Updated:
- .speck/project.json

Next Steps:
- [context-appropriate recommendations]
```

## CLI Alternative

You can also use the CLI:
```bash
npx github:telum-ai/speck promote --to build
npx github:telum-ai/speck promote --to platform
npx github:telum-ai/speck promote --to sprint   # downgrade
```
