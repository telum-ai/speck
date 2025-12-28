---
description: Capture story learnings by mining raw data (.learning.log, git commits, validation) and producing structured summary for epic retrospective.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Mine raw learning data from story implementation and consolidate into structured summary. Apply immediate learnings to current epic, flag patterns for epic retrospective validation.

## Subagent Parallelization

This command benefits from parallel data mining:

**Data Mining Phase** - Spawn parallel speck-explorer:
```
├── [Parallel] speck-explorer: Parse .learning.log for edit events
├── [Parallel] speck-explorer: Mine git commits for learning tags
├── [Parallel] speck-explorer: Read validation-report.md
├── [Parallel] speck-explorer: Find future story specs in epic
└── [Wait] → Synthesize into story-retro.md
```

**Speedup**: 2-3x compared to sequential mining.

## Critical Understanding

**Story retrospective is the ONLY level that consumes raw data**:
- ✅ Reads .learning.log files
- ✅ Mines git commit tags (PATTERN:, GOTCHA:, PERF:, ARCH:, RULE:, DEBT:)
- ✅ Reads validation-report.md

**Produces structured output**:
- Creates `story-retro.md` using template
- Epic retrospective will read this summary (NOT raw data)

## Prerequisites

- Story validated (validation-report.md exists)
- Story directory with artifacts (spec.md, plan.md, tasks.md)
- Git commits for the story (with learning tags ideally)

## Retrospective Process (Data Mining → Template → Application)

### Step 1: Mine Raw Data Sources

**A. Find and Parse .learning.log File**

Look for `.learning.log` in story directory:
```bash
find [STORY_DIR] -name ".learning.log" -type f
```

Parse log file for:
- Total edit events
- Files edited with frequency count
- High-iteration files (>5 edits) - planning accuracy indicators
- Change timestamps (work duration indicators)

Calculate:
- Actual effort from timestamps (first edit to last edit)
- Iteration density (edits per file)
- Files that stabilized quickly vs needed rework

**B. Mine Git Commits for Learning Tags**

Get commits for story:
```bash
# If story has branch:
git log [story-branch] --grep="PATTERN:\|GOTCHA:\|PERF:\|ARCH:\|RULE:\|DEBT:"

# Or by date range if known:
git log --since="[story-start-date]" --until="[story-end-date]"
```

Extract and categorize tags:
- **PATTERN:** tags → Reusable code patterns list
- **GOTCHA:** tags → Surprises and pitfalls list
- **PERF:** tags → Performance optimizations list
- **ARCH:** tags → Architecture decisions list
- **RULE:** tags → Cursor rule updates needed list
- **DEBT:** tags → Technical debt items list

**C. Read Validation Report**

Load `validation-report.md` and extract:
- Specification accuracy (requirements matched/deviated)
- Performance vs targets (met/missed with gaps)
- Constitution compliance (violations if any)
- Learnings for Retrospective section (if present)

**D. Calculate Effort Variance**

- Estimated effort: From tasks.md or spec.md estimate
- Actual effort: From .learning.log timestamps or git commit times
- Variance percentage and direction

### Step 2: Consolidate into Template

**CRITICAL**: Load and follow the template exactly:
```
.speck/templates/story/story-retro-template.md
```

The template is self-documenting - follow all sections and guidelines within it.
Use the mined data from Step 1 to fill each section.

### Step 3: Apply Immediate Learnings (Non-Meta - Current Epic Only)

**Intelligent Learning Application Logic**:

```python
# Pseudo-code for learning application

for pattern in discovered_patterns:
    if pattern.affects_future_stories_in_epic():
        # Check if there are future story specs in epic
        future_stories = find_future_story_specs(current_epic)
        for story in future_stories:
            if pattern.is_relevant_to(story):
                propose_update_to_story_spec(story, pattern)
                # Example: "Story 3 also does native setup - add 2h for cert"
                
    if pattern.should_document_in_epic():
        propose_append_to_epic_md(pattern)
        propose_append_to_epic_architecture(pattern)
        
for gotcha in discovered_gotchas:
    if gotcha.affects_other_stories():
        # Find other unstarted stories in epic
        future_stories = find_unstarted_stories(current_epic)
        for story in future_stories:
            if gotcha.is_relevant_to(story):
                propose_update_to_story_spec(story, gotcha)
                # Example: "Story 5 needs Firebase - warn about auth setup time"
```

**Example Applications**:

Scenario: Story 1 discovers "iOS cert setup takes 45min"
- Action: Find Story 3 spec (also iOS work)
- Update: Add setup task with 45min allocation
- Update: epic.md → Add note about iOS prerequisites
- Escalate: Flag for epic retro (might affect other epics)

Scenario: Story 2 finds "PostgreSQL window functions 10x faster"
- Action: Check Story 4 spec (also has overlaps)
- Suggest: Use window functions instead of Python
- Document: epic-architecture.md → Add pattern
- Escalate: Flag for epic retro (might be project-wide pattern)

**Interactive Approval**:
For each proposed update:
- Show: Current spec section
- Propose: Specific change based on learning
- Ask: "Apply this update? [Y/n]"
- Document: Track in "Immediate Actions" section

### Step 4: Flag Escalations for Epic Retrospective

**Determine What to Escalate** (vs handle now):

**Escalate to Epic Retro** if:
- Pattern appears in this story, MIGHT appear in others (need validation)
- Gotcha might be systemic across epic
- Planning issue might affect epic-level commands
- Architecture decision needs validation across epic scope

**Handle Now** if:
- Obviously affects specific future story in epic
- Clear epic-level documentation update
- Low-risk, high-value immediate update

**Escalate to Project Retro** if:
- Insight about cross-epic coordination
- Methodology/process observation
- Pattern that might apply to other epics

### Step 5: Generate story-retro.md from Template

Create `[STORY_DIR]/story-retro.md` using template:

1. Fill template with all mined data
2. Mark escalations clearly in template sections
3. Document immediate actions taken
4. Ensure consistent format for epic retro parsing

### Step 6: Output Summary

```
✅ Story Retrospective Complete!

Story: [Name]
Duration: [Actual vs estimated with variance]

Data Sources Mined:
- .learning.log: [X edit events across Y files]
- Git commits: [Z commits with learning tags]
- Validation report: [Spec accuracy, performance data]

Learnings Captured:
- Patterns: [X] ([Y] reusable, [Z] story-specific)
- Gotchas: [A] ([B] escalated, [C] documented)
- Performance insights: [D]
- Architecture decisions: [E]

Immediate Actions Applied:
- ✅ Updated [X] future story specs in epic
- ✅ Updated epic.md with [Y] patterns
- ✅ Updated epic-architecture.md with [Z] decisions

Escalated to Epic Retro:
- Patterns to validate: [X]
- Process issues: [Y]
- Rule updates: [Z]

Created:
- story-retro.md (structured summary for epic retro)

Ready for: Next story / Epic retrospective when all stories complete
```

## Integration Points

**Feeds Into**:
- Epic retrospective reads this `story-retro.md` (NOT raw data)
- Epic retro aggregates learnings across all story retros
- Epic retro validates flagged patterns

**Feeds Forward** (Non-Meta):
- Updates future story specs in same epic
- Updates epic-level documentation
- Improves velocity estimates for similar stories

**Feeds Upward** (Meta - via Epic Retro):
- Flags process issues for epic retro validation
- Suggests template improvements
- Proposes rule updates

---

**Position in Flow**: After /story-validate, before next story  
**Duration**: 10-15 minutes (automated mining + interactive application)  
**Purpose**: Mine raw data, produce structured summary, apply immediate learnings  
**Output**: `story-retro.md` for epic retrospective consumption

