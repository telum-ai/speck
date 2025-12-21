# Story Retrospective Summary

**Story**: [STORY_ID] - [STORY_NAME]  
**Epic**: [EPIC_ID] - [EPIC_NAME]  
**Completed**: [COMPLETION_DATE]  
**Retro Date**: [RETRO_DATE]

---

## Execution Metrics

- **Estimated Effort**: [X hours from tasks.md]
- **Actual Effort**: [Y hours calculated from git commits]
- **Variance**: [+/-Z%] [(Faster/Slower/On-target)]
- **Specification Accuracy**: [Matched/Had-Gaps/Major-Deviation]
- **Files Changed**: [X files]
- **High-Iteration Files**: [Y files with >5 edits - indicates planning gaps]

---

## Patterns Discovered

> **Source**: PATTERN: tags from git commits + code analysis

### Pattern 1: [Pattern Name]
- **Description**: [What the pattern does]
- **Code Location**: [File:lines or service/component]
- **When to Use**: [Scenarios where this pattern applies]
- **Reusability**: [High/Medium/Low]
- **Escalate to Epic**: [Yes - validate across other stories / No - story-specific]

[Repeat for each pattern - aim for 1-3 significant patterns]

---

## Gotchas Encountered

> **Source**: GOTCHA: tags from git commits + .learning.log high-iteration indicators

### Gotcha 1: [Gotcha Title]
- **What Happened**: [Clear description of the surprise/pitfall]
- **Time Impact**: [X hours lost]
- **Solution**: [How it was fixed]
- **Prevention**: [How to avoid next time - specific action]
- **Escalate to Epic**: [Yes - might appear in other stories / No - one-off]

[Repeat for each gotcha - aim for 1-3 significant gotchas]

---

## Performance Insights

> **Source**: PERF: tags from git commits + validation report performance section

### Optimization 1: [What Was Optimized]
- **Before**: [Metric with measurement]
- **After**: [Metric with measurement]  
- **Technique**: [How achieved - specific approach]
- **Reusable**: [Yes - add to performance patterns / No - context-specific]

[Repeat for each optimization - 0-2 typically]

---

## Architecture Decisions

> **Source**: ARCH: tags from git commits + plan.md decisions

### Decision 1: [Decision Title]
- **Choice Made**: [What was chosen]
- **Rationale**: [Why this choice]
- **Alternatives Considered**: [What else was evaluated]
- **Result**: [Worked-Well/Struggled/Too-Early-To-Tell]
- **For Epic Retro**: [Validate this decision across other stories in epic]

[Repeat for significant architectural choices - 0-2 typically]

---

## Change Pattern Analysis

> **Source**: .learning.log file iteration analysis

**Planning Accuracy Indicators**:
- [File/section] had [X] iterations: [Indicates: good refinement / planning gap / requirements changed]
- [File/section] was one-shot: [Indicates: good planning]

**Insight**: [What change patterns reveal about specification quality]

---

## Immediate Actions (Non-Meta - Applied to Current Epic)

> **These updates were made during this retrospective**

### Updated Future Story Specs in This Epic
- ✅ Story [ID]: Updated spec.md to [specific change based on learning]
  - Why: [Learning from this story]
  - Impact: [Time/quality improvement expected]

### Updated Epic-Level Artifacts
- ✅ epic.md: Added [pattern/gotcha to notes]
- ✅ epic-architecture.md: Documented [architecture decision]

---

## Escalations to Epic Retrospective

> **These require validation across multiple stories**

### Potential Patterns (Validate in Epic Retro)
- [ ] Pattern: [Name] - Check if Story [X], [Y] also used this
- [ ] Gotcha: [Name] - Verify if this appeared in other stories

### Planning Issues (Check if Systemic)
- Issue: [/story-plan didn't catch X]
  - This story only? Or did others hit this?
  - If others hit it: Update /story-plan command

### Template Gaps (Validate Across Stories)
- Template: [tasks-template.md]
  - Missing: [Specific section]
  - Check: Did other stories need this too?

---

## Escalations to Project Retrospective

> **Strategic/methodology insights beyond this epic**

### Cross-Epic Patterns
- Pattern: [Name] might apply to other epics in project
- Check in project retro: Does this pattern appear in Epic [X]?

### Methodology Insights
- Process insight: [Speck flow observation]
- Scope: Could affect story/epic/project level commands
- Validate in project retro across all epics

---

## Cursor Rule Updates

> **Source**: RULE: tags from git commits

### Immediate Updates (Applied Now)
- ✅ @[rule].mdc: [Specific update made with approval]

### Deferred to Epic Retro (Validate First)
- [ ] @[rule].mdc: [Update needed - validate pattern across stories first]

### New Rules Needed (Flag for Epic/Project Retro)
- [ ] @[new-rule].mdc: [Purpose - validate need across epic/project]

---

## Technical Debt Log

> **Source**: DEBT: tags from git commits

| Debt Item | Why Created | Impact | Repayment Plan | Flagged For |
|-----------|-------------|--------|----------------|-------------|
| [Item] | [Reason] | H/M/L | [When] | Epic/Project retro |

---

## Quick Wins for Next Story

**Immediate Improvements**:
1. [Actionable improvement that applies right now]
2. [Specific thing to do differently]

**Watch Out For**:
- [Gotcha that might appear again]
- [Estimation adjustment for similar stories]

---

**Status**: ✅ Story retrospective complete  
**Immediate Updates Applied**: [Count]  
**Escalations Flagged**: [Count for epic retro]  
**Ready for**: Next story / Epic retrospective

