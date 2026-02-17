# Project Retrospective Summary

**Project**: [PROJECT_ID] - [PROJECT_NAME]  
**Completed/Milestone**: [DATE]  
**Retro Date**: [RETRO_DATE]  
**Duration**: [X months/weeks]  
**Epics Completed**: [X of Y]

---

## Executive Summary

[Strategic overview of project outcomes, methodology effectiveness, and key insights for future projects]

---

## Project Goals Achievement

| Goal | Target | Actual | Status | Evidence |
|------|--------|--------|--------|----------|
| [Goal from project.md] | [Target] | [Actual] | ✅/⚠️/❌ | [How measured] |

---

## Cross-Epic Patterns (Validated Project-Wide)

> **Source**: Patterns appearing in 2+ epic retrospectives

### Pattern 1: [Pattern Name] ✅ PROJECT-WIDE
- **Found in Epics**: [E001, E003, E007]
- **Description**: [What the pattern does]
- **Effectiveness**: [Consistent success across epics]
- **Reusability**: [High - applies to other projects]
- **Action**: Promote to Speck pattern library / Create shared component

### Pattern 2: [Pattern Name] ⚠️ EPIC-SPECIFIC
- **Found in Epics**: [E007 only]
- **Description**: [What it does]
- **Action**: Keep in Epic 007 docs, don't promote project-wide

[List all cross-epic patterns with validation]

---

## Cross-Epic Gotchas (Project-Wide Issues)

> **Source**: Gotchas appearing in multiple epic retrospectives

### Gotcha 1: [Gotcha Title] 🔴 PROJECT-WIDE
- **Appeared in Epics**: [E001, E005, E007]
- **Total Time Impact**: [X hours across epics]
- **Root Cause**: [Why it affected multiple epics]
- **Prevention**: [Strategy]
- **Action**: Update project setup docs / Create Cursor rule / Update process

### Gotcha 2: [Gotcha Title] ✅ EPIC-SPECIFIC
- **Appeared in Epics**: [E007 only]
- **Action**: Already documented in Epic 007, don't escalate

[List all gotchas with cross-epic analysis]

---

## Velocity Evolution Across Epics

| Epic | Planned Stories | Actual | Planned Effort | Actual Effort | Velocity |
|------|----------------|--------|----------------|---------------|----------|
| E001 | [X] | [Y] | [A]h | [B]h | [V1] |
| E007 | [X] | [Y] | [A]h | [B]h | [V2] |
| E005 | [X] | [Y] | [A]h | [B]h | [V3] |

**Velocity Trend**: [Improving/Stable/Declining]  
**Average Project Velocity**: [X stories per week, Y hours per story]  
**Learning Curve**: [Did velocity improve as project progressed?]  
**For Next Project**: Start estimates with [X]x multiplier

---

## Speck Methodology Effectiveness

> **Source**: Command usage and flow analysis across all epics

### Commands by Actual Value

| Command | Usage Count | Avg Value (1-5) | Issues Encountered | Keep/Modify/Remove |
|---------|-------------|-----------------|-------------------|-------------------|
| /project-specify | 1 | 5 | None | ✅ Keep |
| /epic-architecture | 3 | 4 | [Issue] | ⚠️ Modify |
| /story-implement | 26 | 5 | None | ✅ Keep |

### Flow Deviations

**Documented Flow (README)**:
```
specify → clarify → [ux] → context → [constitution] → architecture → [design-system] → plan → [roadmap]
```

**Actual Flow Used**:
```
[Document the actual sequence used and why you deviated (if you did).]
[If the deviation is validated across projects: propose a Speck update.]
```

**Insights**:
- [Where flow worked vs struggled]
- [Commands that should be reordered]
- [Commands that should be optional vs required]

### Template Effectiveness

| Template | Usage | Sections Always Used | Sections Always Skipped | Action |
|----------|-------|---------------------|------------------------|--------|
| story-template.md | 26x | [Sections] | [Sections] | Update/Keep |
| epic-template.md | 8x | [Sections] | [Sections] | Update/Keep |

---

## Cursor Rules Evolution

> **Source**: Rules created/updated during project from epic retros

### Rules Created During Project
- @[rule].mdc: Created in Epic [X] retro, used in Epic [Y], effectiveness: [Rating]

### Rules Updated During Project
- @[rule].mdc: Updated [X] times, final state effective: [Yes/No]

### Rule Effectiveness Analysis
| Rule | Issues Prevented | Times Triggered | Effectiveness | Action |
|------|-----------------|-----------------|---------------|---------|
| @migrations-safety.mdc | [X] | [Y] | [Z%] | ✅ Keep |
| @testing.mdc | [X] | [Y] | [Z%] | ⚠️ Update |

---

## Speck Process Improvements (Meta - Applied)

> **Methodology updates based on validated patterns across multiple epics**

### Command Updates Applied
- ✅ /story-plan: [Specific improvement validated across E001, E007]
- ✅ /epic-breakdown: [Improvement validated across all epics]

### Template Updates Applied
- ✅ tasks-template.md: [Added section based on repeated gaps]
- ✅ epic-template.md: [Clarified section based on confusion]

### Flow Updates Applied
- ✅ README.md: [Reordered commands based on actual usage]

### Deferred Improvements (Need More Validation)
- [ ] Consider merging: [Commands X and Y - appeared redundant]
- [ ] Consider splitting: [Command Z - too many concerns]

---

## Cross-Epic Learnings

> **Insights that span multiple epics**

### Epic Integration Patterns
- How Epic [X] and Epic [Y] integrated: [Smooth/Rocky]
- Dependencies that worked: [List]
- Dependencies that struggled: [List with lessons]

### Architecture Decisions Validated
- [Decision]: Appeared in E001, E007 - Consistently successful
- [Decision]: Tried in E005, struggled - Alternative proposed

---

## Knowledge Base Built

**Pattern Library Created**:
- Total unique patterns: [X]
- Project-wide patterns: [Y]
- Epic-specific patterns: [Z]
- Documented in: [patterns-library.md location]

**Gotcha Database**:
- Total gotchas: [X]
- Project-wide: [Y]
- Epic-specific: [Z]
- Time saved by prevention: [Est. hours]

**Cursor Rules Evolution**:
- Rules created: [X]
- Rules updated: [Y]
- Rules deprecated: [Z]
- Current rule count: [Total]

---

## Strategic Learnings

### What Worked (Repeat in Next Project)
1. [Thing 1]: [Evidence across epics]
2. [Thing 2]: [Impact on velocity/quality]

### What Didn't Work (Change in Next Project)
1. [Thing 1]: [What happened, better approach]
2. [Thing 2]: [Cost vs benefit analysis]

### Unexpected Discoveries
1. [Discovery 1]: [What we learned that wasn't planned]
2. [Discovery 2]: [New capability or understanding]

---

## For Next Project

### Recommended Starting Flow
```
[Optimal command sequence based on this project's learnings]
```

### Estimation Guidance
- Story complexity [Type]: [X]x multiplier
- Epic duration [Type]: [Y] weeks baseline
- Project buffer: [Z%] variance expected

### Patterns to Reuse
1. [Pattern]: [When and how to apply]
2. [Pattern]: [Code/docs location in this project]

### Gotchas to Preempt
1. [Gotcha]: [Prevention strategy]
2. [Gotcha]: [What to check upfront]

### Technology Insights
- [Technology/Library]: [Worked well / Struggled - alternative]

---

## Methodology Evolution Proposals

> **Speck process improvements requiring consideration**

### Flow Changes
- [ ] Reorder: [Commands X and Y - data shows better order]

---

## Speck Template Feedback (Upstream)

If you use Speck as a GitHub **template repo**, avoid directly editing template-managed methodology files in product repos.
Instead, capture validated improvements here so they can be upstreamed to the template and then synced back down.

<!-- SPECK_FEEDBACK:START -->
### Proposed change: [Short title]
- **Target**: [Template-managed path, e.g. `.cursor/skills/story-plan/SKILL.md`]
- **Type**: Command / Template / Script / Docs / Workflow
- **Evidence**: [List epics/stories + links to retro sections]
- **Why**: [What this fixes / improves]
- **Suggested patch** (preferred): include a unified diff or apply-patch snippet
<!-- SPECK_FEEDBACK:END -->
- [ ] Merge: [Commands A and B - redundant in practice]
- [ ] Split: [Command C - too complex]

### New Commands Needed
- [ ] /[new-command]: [Gap identified across project]

### Templates to Revise
- [ ] [template].md: [Specific sections to add/remove/clarify]

### README Updates
- [ ] Flow diagram: [Changes based on actual usage]
- [ ] Examples: [Add brownfield/greenfield distinctions]

---

**Status**: ✅ Project retrospective complete  
**Created**: project-retro.md (strategic insights)  
**Methodology Updates Applied**: [Count]  
**Methodology Proposals**: [Count]  
**Ready for**: Next project with evolved Speck process

