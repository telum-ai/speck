# Epic Retrospective Summary

**Epic**: [EPIC_ID] - [EPIC_NAME]  
**Project**: [PROJECT_ID] - [PROJECT_NAME]  
**Completed**: [COMPLETION_DATE]  
**Retro Date**: [RETRO_DATE]  
**Duration**: [X weeks]

---

## Executive Summary

[2-3 paragraph synthesis of epic outcomes, key patterns discovered, and strategic insights]

---

## Epic Execution Metrics

| Metric | Planned | Actual | Variance |
|--------|---------|--------|----------|
| Stories | [X] | [Y] | [+/-Z%] |
| Effort (hours) | [X] | [Y] | [+/-Z%] |
| Duration (weeks) | [X] | [Y] | [+/-Z%] |

**Epic Goals Achievement**:
- [Goal 1]: ✅ Met / ⚠️ Partial / ❌ Missed - [Evidence]
- [Goal 2]: ✅ Met / ⚠️ Partial / ❌ Missed - [Evidence]

**Velocity Analysis**:
- Average story effort: [X hours]
- Velocity trend: [Improving/Stable/Declining across stories]
- Next epic multiplier: [Use Xx for similar stories]

---

## Validated Patterns (Confirmed Across Stories)

> **Source**: Patterns flagged in multiple story-retro.md files

### Pattern 1: [Pattern Name] ✅ VALIDATED
- **Found in Stories**: [S001, S003, S005]
- **Description**: [What the pattern does]
- **Code Locations**: [Multiple file:line references]
- **When to Use**: [Clear scenarios]
- **Reusability**: [High - project-wide / Medium - epic-specific / Low - story-specific]
- **Action**: Add to [epic-architecture.md / project-architecture.md / create shared library]

### Pattern 2: [Pattern Name] ❌ STORY-SPECIFIC
- **Found in Stories**: [S002 only]
- **Description**: [What it does]
- **Action**: Document in Story 2 only, don't promote

[List all patterns with validation status]

---

## Validated Gotchas (Systemic Issues)

> **Source**: Gotchas appearing in 2+ story-retro.md files

### Gotcha 1: [Gotcha Title] ⚠️ SYSTEMIC
- **Appeared in Stories**: [S001, S004]
- **Description**: [What happens]
- **Time Impact**: [Total hours lost across stories]
- **Root Cause**: [Why it keeps happening]
- **Prevention Strategy**: [Specific steps]
- **Action**: Create/update Cursor rule @[rule].mdc

### Gotcha 2: [Gotcha Title] ✅ ONE-OFF
- **Appeared in Stories**: [S003 only]
- **Action**: Document in epic notes, not worth rule

[List all gotchas with frequency analysis]

---

## Performance Insights Aggregated

> **Source**: PERF: insights from all story retros

| Optimization | Stories Applied | Avg Improvement | Technique | Reusable |
|--------------|----------------|-----------------|-----------|----------|
| [Name] | [S001, S002] | [X% faster] | [How] | [Yes/No] |

**Performance Targets vs Actual**:
- Target: [Epic success criteria performance target]
- Achieved: [Actual performance]
- Status: ✅ Met / ⚠️ Close / ❌ Missed
- Actions: [If missed, what to do]

---

## Architecture Decisions Review

> **Source**: ARCH: decisions from story retros, validated across epic scope

### Decisions That Worked ✅
1. **[Decision]**: [What was chosen]
   - Used in: [S001, S003, S005]
   - Result: [Consistent success, no rework needed]
   - Evidence: [Performance/quality/velocity improvement]
   - Action: Document in epic-architecture.md as established pattern

### Decisions That Struggled ⚠️
1. **[Decision]**: [What was chosen]
   - Used in: [S002]
   - Issues: [What went wrong]
   - Lesson: [What we learned, better approach]
   - Action: Document as anti-pattern, propose alternative

### Decisions Still Validating 🔄
1. **[Decision]**: [What was chosen]
   - Used in: [S001, S002]
   - Early indicators: [Promising / Concerning]
   - Defer: Validate in next epic or project retro

---

## Story-by-Story Synthesis

> **Source**: All story-retro.md summaries

[For each completed story, brief synthesis from its retro]:

### Story [ID]: [Name]
- Effort variance: [+/-X%]
- Spec accuracy: [Rating]
- Key contribution: [What this story taught us]
- Escalated items: [Count]

---

## Immediate Actions (Non-Meta - Applied to Current Project)

> **These updates were made during this retrospective**

### Updated Future Epic Specs in This Project
- ✅ Epic [ID]: Updated spec to [specific change based on validated pattern]
  - Why: [Pattern confirmed across Stories X, Y, Z]
  - Impact: [Expected improvement]

### Updated Project-Level Artifacts
- ✅ architecture.md: Added validated pattern [Name]
- ✅ [PROJECT_DIR]/patterns-library.md: Documented [X] reusable patterns

---

## Escalations to Project Retrospective

> **Strategic insights requiring project-level validation**

### Cross-Epic Patterns (Validate in Project Retro)
- [ ] Pattern: [Name] from this epic might apply to Epic [X], [Y]
- [ ] Gotcha: [Name] might be project-wide (check other epics)

### Methodology Insights (Process Improvements)
- Epic-level issue: [/epic-plan command observation]
  - Check: Did other epics hit this?
  - Scope: Might affect epic-level commands across projects
  
- Story-level issue: [Repeated across 5 stories]
  - Check: Did other epics have same story-level issue?
  - Scope: Might affect /story-* commands

---

## Cursor Rule Updates

> **Source**: RULE: tags validated across multiple stories

### Rules Created/Updated (Applied Now)
- ✅ @[rule].mdc: [Specific update - pattern confirmed in 3+ stories]
- ✅ @[new-rule].mdc: [Created - gotcha appeared in 2+ stories]

### Rules Deferred to Project Retro
- [ ] @[rule].mdc: [Update suggested - validate across other epics first]

### Rule Effectiveness in This Epic
- @[rule].mdc: ✅ Prevented [X] issues (caught in [Y] stories)
- @[rule].mdc: ⚠️ Ignored [X] times (rule needs refinement or removal)

---

## Process Improvements (Meta - Applied to Speck)

> **Changes to methodology based on epic learnings**

### Story-Level Command Updates
- [ ] /story-plan: [Specific improvement based on repeated planning gaps]
- [ ] /story-tasks: [Template update based on task breakdown issues]

### Epic-Level Command Updates  
- [ ] /epic-architecture: [Improvement based on architecture challenges]
- [ ] /epic-breakdown: [Adjustment based on story sizing accuracy]

### Template Improvements
- [ ] story-template.md: [Section to add/remove based on usage]
- [ ] epic-template.md: [Clarification based on ambiguities]

**Note**: These are proposed improvements. Project retro will validate if they're one-epic issues or systemic.

---

## Speck Template Feedback (Upstream)

If you use Speck as a GitHub **template repo**, avoid directly editing template-managed methodology files in product repos.
Instead, capture validated improvements here so they can be upstreamed to the template and then synced back down.

<!-- SPECK_FEEDBACK:START -->
### Proposed change: [Short title]
- **Target**: [Template-managed path, e.g. `.speck/templates/story/tasks-template.md`]
- **Type**: Command / Template / Script / Docs / Workflow
- **Evidence**: [List stories + links to story-retro sections]
- **Why**: [What this fixes / improves]
- **Suggested patch** (preferred): include a unified diff or apply-patch snippet
<!-- SPECK_FEEDBACK:END -->

---

## Preparation for Next Epic

### Technical Prerequisites
- [Setup needed before next epic]
- [Architectural decisions to make upfront]

### Velocity Guidance
- Similar stories: Use [X]x multiplier on estimates
- Setup-heavy stories: Add [Y] hours baseline
- Native platform work: Budget [Z] hours for environment setup

### Patterns to Reuse
1. [Pattern]: [When and how to apply in next epic]
2. [Pattern]: [Specific usage guidance]

### Gotchas to Avoid
1. [Gotcha]: [Prevention strategy for next epic]
2. [Gotcha]: [What to check upfront]

### Knowledge Gaps for Next Epic
- [Gap]: [Research or spike needed before starting]

---

**Status**: ✅ Epic retrospective complete  
**Created**: epic-retro.md (for project retrospective consumption)  
**Immediate Updates Applied**: [Count]  
**Process Updates Proposed**: [Count]  
**Ready for**: Next epic with validated learnings

