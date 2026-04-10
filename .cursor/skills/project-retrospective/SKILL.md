---
name: project-retrospective
description: Load after project-validate passes to synthesize all epic retrospectives, validate cross-project patterns, and evolve the Speck methodology. Run once at project completion. FIRST ACTION after loading: read template at .speck/templates/project/project-retro-template.md before any context loading or artifact generation.
disable-model-invocation: false
---
## Learnings register propagation

When synthesizing a project retrospective, update `specs/projects/[project-id]/learnings-register.md` alongside the retrospective. Promote stable cross-epic lessons there before proposing upstream methodology changes.



The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## ⚠️ Step 0: Read Template First

**Before any other action** — read this template now using the Read tool:
```
.speck/templates/project/project-retro-template.md
```
The template defines required sections and formatting for `project-retro.md`, including cross-epic pattern validation and methodology evolution proposals.

**Checkpoint**: After reading, note the top-level sections from the template. Then continue to Step 1.

Aggregate epic retrospectives, validate project-wide patterns, and propose methodology evolution for Speck based on strategic project insights.

## Subagent Parallelization

This command benefits from parallel data loading and analysis:

**Data Loading Phase** - Load multiple docs in parallel:
```
├── [Parallel] Load all epic-retro.md files
├── [Parallel] Load project.md, PRD.md, architecture.md
├── [Parallel] Load context.md, design-system.md, ux-strategy.md
└── [Continue] with all data loaded
```

**Pattern Analysis Phase** - Spawn parallel speck-auditor:
```
├── [Parallel] speck-auditor: "Analyze patterns appearing across epics"
├── [Parallel] speck-auditor: "Identify systemic issues from epic gotchas"
├── [Parallel] speck-auditor: "Find methodology gaps from epic retros"
├── [Parallel] speck-auditor: "Analyze effort trends across epics"
└── [Wait] → Synthesize into project-retro.md
```

**Speedup**: 3-4x compared to sequential analysis.

## Critical Understanding

**Project retrospective consumes epic summaries (NOT raw story-level data)**:
- ✅ Reads `epic-retro.md` files (structured summaries from epic retros)
- ✅ Reads project-level artifacts (project.md, PRD.md, architecture.md)
- ❌ Does NOT read story-retro.md files (already synthesized in epic retros)
- ⚠️ MAY optionally mine git commit learning tags if epic retros are missing signal

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

### Step 3: Mine All Project Commits (Optional)

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

Create `[PROJECT_DIR]/project-retro.md`:

**CRITICAL**: Load and follow the template exactly:
```
.speck/templates/project/project-retro-template.md
```

Fill it using:
- Project-level truth docs (project.md, PRD.md, architecture.md, context.md, ux-strategy.md, design-system.md)
- All `epic-retro.md` files (primary signal for patterns/gotchas)
- Optional: aggregated commit learning tags (PATTERN/GOTCHA/PERF/ARCH/RULE/DEBT), if used

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

Report: [PROJECT_DIR]/project-retro.md

Next Steps:
1. Review and approve methodology updates
2. Share learnings with team/community
3. Apply insights to next project planning
```

### Step 11: Offer Speck Methodology Feedback (Optional)

After completing the retrospective, ask:

> "Would you like to share **methodology-specific** learnings with the Speck repository?
> 
> This will create a GitHub issue in telum-ai/speck with suggested improvements.
> Only methodology insights will be shared - NO project-specific details."

**If user says YES**:

1. **Extract methodology-only insights** from project-retro.md:
   - Command value assessments (which were useful, which weren't)
   - Template improvements needed
   - Flow deviations that worked better
   - Cross-project patterns that could benefit others
   - Process improvements for the methodology

2. **Filter out project-specific content**:
   - ❌ Project name, domain, business logic
   - ❌ Specific feature implementations
   - ❌ Velocity/metrics tied to your project
   - ✅ Generic process observations
   - ✅ Template gap identifications
   - ✅ Command improvement suggestions

3. **Show the user what will be shared** and get confirmation

4. **Create GitHub issue** using gh CLI:
```bash
gh issue create \
  --repo telum-ai/speck \
  --title "[Feedback] Methodology insights from project retrospective" \
  --body "[Filtered methodology content]" \
  --label "feedback,methodology"
```

**If user says NO**: Skip this step.

## Integration with Speck Evolution

Project retrospectives feed back into:
- `.speck/README.md` - Flow improvements
- `.cursor/skills/` - Skill refinements
- `.speck/templates/` - Template enhancements
- `.cursor/rules/` - Rule evolution

This creates a self-improving methodology where each project makes Speck better!

**Feedback is always opt-in** - see `.speck/TEMPLATE-FEEDBACK.md` for details.

---

**Position in Flow**: After project launch or major milestone  
**Duration**: 2-4 hours  
**Value**: Strategic learnings, methodology evolution, institutional knowledge

