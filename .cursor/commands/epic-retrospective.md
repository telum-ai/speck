---
description: Synthesize story retrospectives, validate patterns across epic, apply learnings to project and process.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Aggregate story retrospectives, validate patterns, apply immediate learnings to current project, and propose process improvements for Speck methodology.

## Subagent Parallelization

This command benefits from parallel data loading and validation:

**Data Loading Phase** - Load all story retros in parallel:
```
├── [Parallel] Load all story-retro.md files in epic
├── [Parallel] Load epic.md, epic-architecture.md
├── [Parallel] Load epic-tech-spec.md, epic-breakdown.md
└── [Continue] with all data loaded
```

**Validation Phase** - Spawn parallel speck-auditor:
```
├── [Parallel] speck-auditor: "Validate pattern frequency across stories (2+ = validated)"
├── [Parallel] speck-auditor: "Identify systemic issues from story gotchas"
├── [Parallel] speck-auditor: "Calculate effort variance across stories"
├── [Parallel] speck-auditor: "Find methodology gaps from story retros"
└── [Wait] → Synthesize into epic-retro.md
```

**Speedup**: 3-4x compared to sequential validation.

## Critical Understanding

**Epic retrospective consumes ONLY synthesized data (NOT raw)**:
- ✅ Reads `story-retro.md` files (structured summaries from story retros)
- ✅ Reads epic-level artifacts (epic.md, epic-architecture.md, etc.)
- ❌ Does NOT read .learning.log files (already processed by story retros)
- ❌ Does NOT mine git commits (already extracted in story retros)

**Produces structured output**:
- Creates `epic-retro.md` using template
- Project retrospective will read this summary (NOT story retros)

**Can update TWO directions**:
- **Non-Meta**: Future epics in current project, project-level docs
- **Meta**: Story/Epic commands, templates, Cursor rules (validated patterns only)

## Prerequisites

- Completed epic with all stories validated
- All stories have `story-retro.md` files (run `/story-retrospective` for each)
- Epic directory with artifacts (epic.md, epic-tech-spec.md, epic-breakdown.md)

## Retrospective Process (Synthesis → Validation → Application)

### Step 1: Load All Story Retrospectives

1. Determine epic:
   - If in epic directory, use current epic
   - Otherwise ask: "Which epic to retrospective?"

2. Find all story retros:
```bash
find [EPIC_DIR]/stories/*/story-retro.md
```

3. Load epic artifacts:
   - epic.md (goals and scope)
   - epic-breakdown.md (planned stories)
   - epic-architecture.md (architectural decisions)
   - epic-tech-spec.md (technical approach)

### Step 2: Validate Patterns Across Stories

**Pattern Frequency Analysis**:
```
For each pattern mentioned in story retros:
- Count appearances: How many stories discovered this?
- If >= 2 stories: VALIDATED (confirm it's real)
- If 1 story only: STORY-SPECIFIC (don't promote)
```

**Validated Pattern Assessment**:
- Reusability: High (project-wide) / Medium (epic-specific) / Low (context-specific)
- Where to apply: Future epics? Project architecture? Create library?

### Step 3: Validate Gotchas Across Stories

**Gotcha Frequency Analysis**:
```
For each gotcha mentioned in story retros:
- Count appearances: How many stories hit this?
- If >= 2 stories: SYSTEMIC (needs prevention)
- If 1 story only: ONE-OFF (document but don't over-engineer)
```

**Systemic Gotcha Assessment**:
- Root cause: Why does this keep happening?
- Prevention: Can a Cursor rule prevent it?
- Documentation: Epic notes? Project docs? New rule?

### Step 4: Aggregate Metrics

From all story retros:
- Total effort variance
- Average velocity per story
- Specification accuracy trends
- Performance achievement rate

### Step 5: Apply Immediate Learnings (Non-Meta)

**Update Future Epics in Project**:

Find unstarted/in-progress epics:
```bash
find [PROJECT_DIR]/epics/*/epic.md | xargs grep "Status.*Not Started\|In Progress"
```

For each validated pattern (frequency >= 2):
- Check if pattern applies to future epic
- Propose specific update to epic spec
- Example: "Epic 005 uses async APIs - apply retry pattern from Epic 007"

For each systemic gotcha:
- Check if gotcha might hit future epic  
- Propose warning in epic spec
- Example: "Epic 008 tests native - add 45min for iOS cert setup"

**Update Project-Level Docs**:
- architecture.md: Add validated patterns
- patterns-library.md: Document reusable patterns (create if not exists)

### Step 6: Apply Process Improvements (Meta)

**Analyze Process Issues from Story Retros**:

Look for escalated process issues:
- Planning issues (appeared in 3+ stories)
- Template gaps (appeared in 3+ stories)
- Command missing features (appeared in 3+ stories)

**Propose Speck Updates**:
```
If issue frequency >= 3 stories:
  # SYSTEMIC - Fix the process
  
  If affects story planning:
    Propose: Update /story-plan command or template
    Show: Specific diff
    Apply: If approved
    
  If affects epic planning:
    Propose: Update /epic-* command or template
    Show: Specific diff
    Apply: If approved
```

**Example Meta Update**:
```
Issue: "Setup time underestimated" in Stories 1, 2, 4, 5

Pattern: /story-tasks template missing dedicated setup phase

Proposal: Add Phase 0 to tasks-template.md:
```markdown
### Phase 0: Setup & Prerequisites
- [ ] T001 Development environment setup
- [ ] T002 Credentials and certificates
[...]
```

Apply? [Y/n]: y
✅ Updated .speck/templates/story/tasks-template.md
```

### Step 7: Update Cursor Rules (Validated Only)

For each RULE: tag that appeared in 2+ story retros:
- Load rule file if exists
- Propose specific update
- Show diff
- Get approval
- Apply change
- Document in epic-retro.md

### Step 8: Update Project-Level Documentation (Truth Update)

**CRITICAL**: After validating learnings, update project-level truth to reflect epic completion.

**Determine What Changed Across Epic**:

1. **Architecture Changes**:
   - New patterns introduced? → Update `architecture.md`
   - New dependencies added? → Update `architecture.md`
   - Example: "Epic 007 added Capacitor native bridge architecture"

2. **Feature Changes**:
   - New capabilities delivered? → Update `PRD.md`
   - Requirements modified? → Update `PRD.md`
   - Example: "Epic 005 added Claude AI activity suggestions"

3. **Constraint Changes**:
   - New constraints discovered? → Update `context.md`
   - Budget/timeline updates? → Update `context.md`
   - Example: "Epic 007 revealed iOS cert requires 45min setup"

4. **Design System Changes**:
   - New UI patterns established? → Update `design-system.md`
   - New components created? → Update `design-system.md`
   - Example: "Epic 004 added suggestion card pattern"

5. **UX Changes**:
   - UX principles validated/changed? → Update `ux-strategy.md`
   - New user flows established? → Update `ux-strategy.md`

**Make Updates**:

```bash
# For each document that needs updating:

# 1. Read validation reports from all stories
find [EPIC_DIR]/stories/*/validation-report.md

# 2. Identify patterns that became "current truth"
# - What was proposed → What was actually built
# - What worked → What became standard

# 3. Update project docs
# Add new sections showing current state
# Mark old sections as "(Updated after Epic XXX)"
# Update "Last Updated" timestamp

# Example:
echo "
## Claude AI Integration (Added after Epic 005)

**Architecture**:
- Claude Sonnet 3.5 via Anthropic API
- Web search enabled for Oslo-specific queries
- Streaming responses for progressive UI
- Cost monitoring: $0.003/request average

**Performance**:
- Response time: <3s p95
- Success rate: 99.2%
- Fallback: Generic suggestions if API fails

See: [EPIC_DIR]/ for full details
" >> architecture.md

# 4. Update timestamps
# Update "Last Updated" timestamps (edit manually or use a small script appropriate for your OS)

# 5. Commit with clear message
git add architecture.md PRD.md context.md
git commit -m "docs: update project truth after Epic [ID]

Updated to reflect:
- [Architectural changes from Epic XXX]
- [Features delivered from Epic XXX]
- [Constraints discovered from Epic XXX]

Project-level docs now reflect production state after epic completion.
See epic-retro.md for retrospective analysis.

ARCH: Updated project truth after epic - Single source of truth pattern"
```

**Why This Matters**:
- Project-level docs = **single source of truth** for current system state
- New team members read project docs to understand "what exists NOW"
- Epic/story specs remain as historical **proposals** (what was planned)
- This step keeps truth current with reality

### Step 9: Generate epic-retro.md Using Template

Load `.speck/templates/epic/epic-retro-template.md` and fill:
- All validated patterns
- All systemic gotchas
- Performance aggregates
- Architecture decision review
- Story synthesis
- Immediate actions applied
- Process improvements made
- Escalations for project retro

### Step 10: Output Summary

```
✅ Epic [ID] Retrospective Complete!

Story Retros Analyzed: [X]

Learnings Validated:
- Patterns: [Y total] → [Z validated across 2+ stories]
- Gotchas: [A total] → [B systemic across 2+ stories]
- Process issues: [C total] → [D validated]

Immediate Actions Applied (Non-Meta):
- ✅ Updated [X] future epic specs
- ✅ Updated project architecture with [Y] patterns
- ✅ Created patterns-library.md with [Z] entries

Process Improvements Applied (Meta):
- ✅ Updated [X] commands
- ✅ Updated [Y] templates
- ✅ Created/updated [Z] Cursor rules

Project Truth Updated:
- ✅ Updated architecture.md with [X] patterns
- ✅ Updated PRD.md with [Y] features
- ✅ Updated context.md with [Z] constraints
- ✅ Committed truth updates with traceability

Escalated to Project Retro:
- Cross-epic patterns: [X]
- Methodology insights: [Y]
- Strategic observations: [Z]

Created:
- epic-retro.md (for project retrospective consumption)
- patterns-library.md (reusable knowledge)

Preparation for Next Epic:
- Velocity multiplier: [X]x
- Setup patterns to reuse: [Count]
- Gotchas to avoid: [Count]

Ready for: Next epic / Project retrospective
```

### Step 11: Offer Speck Methodology Feedback (Optional)

After completing the retrospective, ask:

> "Would you like to share any **methodology-specific** learnings with the Speck repository?
> 
> This will create a GitHub issue in telum-ai/speck with suggested improvements.
> Only methodology insights will be shared - NO project-specific details."

**If user says YES**:

1. **Extract methodology-only insights** from epic-retro.md:
   - Process improvements (commands, templates, flow)
   - Validated patterns that could benefit other projects
   - Systemic gotchas with prevention strategies
   - Template gaps or improvements

2. **Filter out project-specific content**:
   - ❌ Project name, domain, business logic
   - ❌ Specific feature implementations
   - ❌ Performance metrics or user data
   - ✅ Generic patterns (e.g., "PostgreSQL window functions for time overlaps")
   - ✅ Process observations (e.g., "story-plan should ask about dependencies earlier")

3. **Show the user what will be shared** and get confirmation

4. **Create GitHub issue** using gh CLI:
```bash
gh issue create \
  --repo telum-ai/speck \
  --title "[Feedback] Methodology insights from epic retrospective" \
  --body "[Filtered methodology content]" \
  --label "feedback,methodology"
```

**If user says NO**: Skip this step.

## Integration Points

**Consumes**:
- Story retrospectives (story-retro.md files ONLY)
- Epic artifacts (for context)

**Feeds Into**:
- Project retrospective reads epic-retro.md (NOT story retros)
- Project retro aggregates across all epics

**Feeds Forward** (Non-Meta):
- Updates future epic specs in project
- Updates project architecture and patterns
- Improves next epic planning

**Feeds Into Process** (Meta):
- Updates story/epic commands based on validated issues
- Updates templates based on repeated gaps
- Creates/updates Cursor rules for validated patterns

**Feeds Into Speck** (Optional):
- User-approved methodology feedback via GitHub issues

---

**Position in Flow**: After all epic stories complete and validated  
**Duration**: 20-40 minutes  
**Purpose**: Validate learnings, apply to project, improve process  
**Output**: `epic-retro.md` for project retrospective consumption

