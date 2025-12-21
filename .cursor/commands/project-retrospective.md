---
description: Synthesize epic retrospectives, validate cross-epic patterns, evolve Speck methodology based on project-wide insights.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Aggregate epic retrospectives, validate project-wide patterns, and propose methodology evolution for Speck based on strategic project insights.

## Critical Understanding

**Project retrospective consumes ONLY epic summaries (NOT story data)**:
- ✅ Reads `epic-retro.md` files (structured summaries from epic retros)
- ✅ Reads project-level artifacts (project.md, PRD.md, architecture.md)
- ❌ Does NOT read story-retro.md files (already synthesized in epic retros)
- ❌ Does NOT read .learning.log or git commits (already processed)

**Produces strategic output**:
- Creates `project-retro.md` using template
- This is the top-level synthesis for methodology evolution

**Can update ANY level (Maximum Flexibility)**:
- **Non-Meta**: Can't update current project (it's done), but guides next project
- **Meta**: Can update commands/templates at ALL levels (story/epic/project)
- **Strategic**: Can propose Speck methodology evolution

## Prerequisites

- Project at major milestone (launch, v1 complete, major release)
- Multiple epics completed (ideally all or most)
- All epics have `epic-retro.md` files (run `/epic-retrospective` for each)

## Project Retrospective Process (Strategic Synthesis)

### Step 1: Load All Epic Retrospectives

1. Find project:
   - If in project directory, use current project
   - Otherwise ask: "Which project to retrospective?"

2. Load project artifacts:
   - project.md (vision and goals)
   - PRD.md (requirements and epic breakdown)
   - architecture.md (design decisions)
   - context.md (constraints discovered)
   - design-system.md (UI patterns established)
   - ux-strategy.md (UX principles validated)
   - epics.md (epic list)

**CRITICAL CHECK**: Verify project-level docs were updated after each epic!
- Each epic retro should have updated project truth
- If project docs are stale, update them before retrospective
- Project-level docs = single source of truth for "what exists NOW"

3. **Find all epic retrospectives**:
```bash
find [PROJECT_DIR]/epics/*/epic-retro.md
```

**CRITICAL**: Project retro ONLY reads epic-retro.md files (NOT story retros!)

4. Calculate project metrics from epic retros:
   - Total stories across all epics
   - Total effort across all epics
   - Velocity trend across epics
   - Goals achievement rate

### Step 2: Validate Patterns Across Epics

**Cross-Epic Pattern Analysis**:

For each pattern mentioned in epic retros:
```python
# Count how many epics discovered this pattern
pattern_frequency_across_epics = count_epics_with_pattern(pattern)

if pattern_frequency_across_epics >= 2:
    # PROJECT-WIDE PATTERN - Validated across epics
    mark_as_project_pattern(pattern)
    # Decision: Promote to Speck pattern library?
    if pattern.applies_to_other_projects():
        propose_add_to_speck_pattern_library(pattern)
    else:
        keep_in_project_architecture(pattern)
        
elif pattern_frequency_across_epics == 1:
    # EPIC-SPECIFIC - Already handled in epic retro
    mark_as_epic_specific(pattern)
```

**Output**: Project-wide patterns vs epic-specific patterns

### Step 3: Validate Gotchas Across Epics

**Cross-Epic Gotcha Analysis**:

For each gotcha mentioned in epic retros:
```python
gotcha_frequency_across_epics = count_epics_with_gotcha(gotcha)

if gotcha_frequency_across_epics >= 2:
    # PROJECT-WIDE ISSUE - Systemic problem
    mark_as_project_wide_issue(gotcha)
    # Decision: How to prevent in ALL future projects?
    if gotcha.is_speck_process_issue():
        propose_methodology_update(gotcha)
    elif gotcha.is_technology_specific():
        create_technology_gotcha_doc(gotcha)
        
elif gotcha_frequency_across_epics == 1:
    # EPIC-SPECIFIC - Already documented in epic retro
    mark_as_epic_specific(gotcha)
```

**Output**: Project-wide gotchas requiring process changes

**Cross-Epic Pattern Analysis**:
- Patterns that appeared in multiple epics: [Truly reusable]
- Patterns used once: [Epic-specific]
- Pattern evolution: [How patterns improved across epics]

**Gotcha Trends**:
- Recurring gotchas: [Systemic issues]
- Epic-specific gotchas: [One-time issues]
- Prevention effectiveness: [Did documented gotchas prevent repeats?]

### Step 3: Mine All Project Commits

Aggregate learning tags from entire project:
```bash
git log --all --grep="PATTERN:\|GOTCHA:\|PERF:\|ARCH:\|RULE:\|DEBT:"
```

**Pattern Library Statistics**:
- Total unique patterns: [Count]
- Most reused pattern: [Name, usage count]
- Pattern categories: [Group by type]

**Gotcha Database**:
- Total gotchas: [Count]
- Time saved by documentation: [Estimated hours]
- Most impactful gotcha: [By time saved]

**Performance Insights**:
- Optimization techniques used: [List with frequency]
- Average performance improvement: [%]
- Performance targets met: [% of targets]

### Step 4: Methodology Effectiveness Review

**Foundation Phase (ux, context, constitution)**:
- Value delivered: [High/Medium/Low]
- Time investment: [X hours]
- Impact on PRD quality: [Rating]
- Would we do again?: [Yes/No/Modified]

**Planning Phase (PRD, epics)**:
- PRD accuracy: [% shipped as specified]
- Epic breakdown accuracy: [Boundaries held or changed?]
- Epic estimation accuracy: [Variance %]

**Architecture Phase**:
- Technology choices: [Wins vs regrets]
- Architectural patterns: [Worked vs struggled]
- Scale predictions: [Accurate vs adjustments]

**Implementation Phase**:
- Story specification quality: [How often specs matched reality]
- Task breakdown accuracy: [How often tasks were complete]
- Validation effectiveness: [Issues caught vs missed]

**Truth Management Phase** (NEW):
- Project docs updated after epics: [Yes/No for each epic]
- Documentation drift: [None/Minor/Major]
- Truth vs reality alignment: [How well project docs reflect current state]
- Time spent on truth updates: [X hours total]
- Value of maintained truth: [High/Medium/Low - based on onboarding, clarity]

**Assessment**:
- Does project.md accurately describe current system? [Yes/Partially/No]
- Does architecture.md reflect actual architecture? [Yes/Partially/No]
- Does PRD.md list actual features? [Yes/Partially/No]
- Can new team member understand "what exists" from project docs? [Yes/No]

**If truth drift detected**: Update project docs before completing retrospective!

### Step 5: Speck Command Usage Analysis

**Commands Actually Used**:
```markdown
| Command | Times Used | Value Rating (1-5) | Issues Encountered |
|---------|------------|-------------------|-------------------|
| /project-specify | 1 | 5 | None |
| /project-plan | 1 | 4 | Ran before ux/context (fixed) |
| /epic-specify | 8 | 5 | Placeholder enhancement smooth |
| /story-implement | 26 | 5 | Excellent |
[... full analysis ...]
```

**Commands Skipped**:
- [Command]: [Why skipped, was it needed?]

**Flow Deviations**:
- [Where we went off-script]: [Why, should flow change?]

### Step 6: Cursor Rules Effectiveness

**Rules That Caught Issues**:
- @[rule].mdc: [What it prevented, value delivered]

**Rules That Were Ignored**:
- @[rule].mdc: [Why ignored, rule problem or user problem?]

**Rules Created During Project**:
- @[rule].mdc: [From Epic X retrospective, effectiveness]

**Rules Needing Updates**:
- @[rule].mdc: [What's missing based on project learnings]

### Step 7: Interactive Strategic Review

**Part 1: Vision Alignment** 🎯
- "Did the project achieve its vision?"
- "What worked as planned?"
- "What unexpected outcomes occurred?"

**Part 2: Process Effectiveness** 📊
- "Which Speck commands added most value?"
- "Which felt like overhead?"
- "Where did the flow feel natural vs forced?"

**Part 3: Knowledge Capture** 📚
- Review pattern library built during project
- "Are patterns well-documented for next project?"
- "What knowledge is still tacit (not documented)?"

**Part 4: Methodology Evolution** 🔄
- "What would you change about the Speck process?"
- "Which templates need improvement?"
- "What's missing from the methodology?"

### Step 8: Generate Project Retrospective Report

Create `[PROJECT_DIR]/project-retrospective.md`:

```markdown
# Project Retrospective: [Project Name]

**Project ID**: [ID]  
**Completed**: [Date]  
**Duration**: [X months]  
**Epics Completed**: [X of Y]  
**Stories Completed**: [X of Y]

---

## Executive Summary

[Strategic overview of project outcomes, key learnings, and methodology insights]

---

## Project Goals Achievement

[From project.md]

| Goal | Target | Actual | Status | Notes |
|------|--------|--------|--------|-------|
| [Goal 1] | [Target] | [Actual] | ✅/⚠️/❌ | [Context] |

---

## Cross-Epic Patterns

[Patterns that appeared in multiple epics]

### Pattern 1: [Name]
- **Used in**: Epic [X], Epic [Y], Epic [Z]
- **Effectiveness**: [High/Medium/Low]
- **Documentation**: [Where documented]
- **Action**: Promote to project architecture / Create shared library

---

## Gotcha Database

[All gotchas from all epics with prevention strategies]

### Category: [Setup/Runtime/Testing/Deployment]
1. **[Gotcha]**: [Description]
   - Appeared in: Epic [X], Epic [Y]
   - Total time impact: [Z hours]
   - Now prevented by: @[rule].mdc
   - Effectiveness: [Prevented Y instances]

---

## Velocity Evolution

[Tracking velocity across epics]

| Epic | Planned Stories | Actual | Velocity | Notes |
|------|----------------|--------|----------|-------|
| E001 | 8 | 8 | 1.0x | Baseline |
| E007 | 5 | 5 | 1.2x | Capacitor learning curve |
| E005 | 6 | 6 | 0.9x | Improved from E007 learnings |

**Overall Project Velocity**: [Average across epics]  
**Velocity Trend**: [Improving/Stable/Declining]  
**For Next Project**: Start with [X]x multiplier

---

## Speck Methodology Review

### Commands by Value

**High Value** (Keep, enhance):
- [Command]: [Why valuable, usage frequency]

**Medium Value** (Keep, consider refinement):
- [Command]: [Why used, what could improve]

**Low Value** (Consider removing or merging):
- [Command]: [Why not used, alternative approach]

### Flow Analysis

**Actual Flow Used**:
```
[Document the actual sequence of commands used]
```

**Documented Flow**:
```
[What README suggested]
```

**Deviations**:
- [Where we went off-script and why]

**Flow Improvements Needed**:
- [Specific change to README flow]

### Template Effectiveness

[For each template used]

| Template | Usage | Sections Used | Sections Skipped | Improvements Needed |
|----------|-------|--------------|------------------|-------------------|
| [Template name] | [X times] | [Sections] | [Sections] | [Specific changes] |

---

## Cursor Rules Evolution

### Rules Created During Project
- @[rule].mdc: [Created in Epic X, effectiveness rating]

### Rules Updated During Project
- @[rule].mdc: [Updated X times, final state vs initial]

### Rule Effectiveness Analysis
| Rule | Times Caught Issues | Times Ignored | Effectiveness | Action |
|------|-------------------|---------------|---------------|---------|
| @[rule].mdc | [X] | [Y] | [%] | Keep/Update/Remove |

---

## Knowledge Base Built

**Pattern Library**:
- Total patterns: [X]
- Reusable across projects: [Y]
- Project-specific: [Z]
- Documentation quality: [Rating]

**Anti-Pattern Documentation**:
- Total gotchas: [X]
- Prevention strategies: [Y]
- Estimated time saved: [Z hours]

**Architecture Decisions**:
- ADRs documented: [X]
- Decisions validated: [Y]
- Decisions that need revision: [Z]

---

## Strategic Learnings

### What We'd Do Again
1. [Thing 1]: [Why it worked, apply to next project]
2. [Thing 2]: [Evidence of success]

### What We'd Change
1. [Thing 1]: [What didn't work, better approach]
2. [Thing 2]: [Cost vs benefit analysis]

### What We Discovered
1. [Insight 1]: [Unexpected learning]
2. [Insight 2]: [New capability or understanding]

---

## Speck Process Improvements

### Immediate Changes
- [ ] Update command: [Which command, what change]
- [ ] Update template: [Which template, what change]
- [ ] Update README flow: [Specific flow change]
- [ ] Create new command: [Gap identified, purpose]

### For Consideration
- [ ] Merge commands: [Which ones, rationale]
- [ ] Split command: [Which one, why]
- [ ] New template needed: [Purpose]

---

## For Next Project

### Start With
- [Command/process that should be standard]
- [Pattern/approach that worked well]

### Skip or Defer
- [Command/process that didn't add value]
- [Activity that can wait]

### Watch Out For
- [Gotcha that might appear again]
- [Decision point that needs early attention]

### Estimation Guidance
- [Story type]: Use [X]x multiplier
- [Epic type]: Expect [Y] week duration
- [Project type]: Plan for [Z]% variance

---

## Action Items

### Methodology Updates
- [ ] Update .speck/README.md: [Specific change]
- [ ] Update command flow diagram: [Change]
- [ ] Create missing template: [Which one]

### Cursor Rules
- [ ] Create @[new-rule].mdc
- [ ] Update @[existing-rule].mdc
- [ ] Archive @[outdated-rule].mdc

### Documentation
- [ ] Document patterns in architecture.md
- [ ] Update best practices guide
- [ ] Share learnings with community

---

**Retrospective Complete**: [Date]  
**Facilitator**: [Name]  
**Next Project**: [Name if planned]  
**Carry Forward**: [Top 3 learnings to apply]
```

### Step 9: Execute Approved Actions

With user approval, update:
- README.md flow changes
- Template improvements
- Command refinements
- Cursor rule updates

### Step 10: Summary Output

```
✅ Project [Name] Retrospective Complete!

Project Outcomes:
- Goals achieved: [X of Y]
- Epics completed: [A of B]
- Stories delivered: [C of D]
- Duration: [Weeks]

Knowledge Captured:
- Patterns documented: [X]
- Gotchas with solutions: [Y]
- Performance optimizations: [Z]
- Cursor rules created/updated: [A]

Methodology Insights:
- Commands with high value: [List top 3]
- Flow improvements identified: [Count]
- Template enhancements needed: [Count]

For Next Project:
- Velocity multiplier: [X]
- Start with: [Top 3 practices]
- Watch out for: [Top 3 gotchas]

Report: [PROJECT_DIR]/project-retrospective.md

Next Steps:
1. Review and approve methodology updates
2. Share learnings with team/community
3. Apply insights to next project planning
```

## Integration with Speck Evolution

Project retrospectives feed back into:
- `.speck/README.md` - Flow improvements
- `.cursor/commands/` - Command refinements
- `.speck/templates/` - Template enhancements
- `.cursor/rules/` - Rule evolution

This creates a self-improving methodology where each project makes Speck better!

---

**Position in Flow**: After project launch or major milestone  
**Duration**: 2-4 hours  
**Value**: Strategic learnings, methodology evolution, institutional knowledge

