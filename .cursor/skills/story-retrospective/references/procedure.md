# story-retrospective — procedure

Input: `$ARGUMENTS`.
Output: `[STORY_DIR]/story-retro.md`.
Template: `.speck/templates/story/story-retro-template.md`.
Prereq: `/story-validate` complete (`validation-report.md` exists).

Story retro is the ONLY level that mines raw git data. Epic retro consumes `story-retro.md` summaries.

## 0. Template

Read `.speck/templates/story/story-retro-template.md` before writing.

## 1. Mine raw data

**Git tags**:
```bash
git log [story-branch] --grep='PATTERN:\|GOTCHA:\|PERF:\|ARCH:\|RULE:\|DEBT:'
# or by date range if branch unknown
```

Categorize: PATTERN, GOTCHA, PERF, ARCH, RULE, DEBT.

**validation-report.md**: spec accuracy, performance vs targets, constitution violations, Learnings section, visual/a11y/token findings if present.

**Effort variance**: estimated (tasks.md/spec) vs actual (first→last commit timestamps).

## 2. Write story-retro.md

Fill template from mined data. Mark escalations for epic retro.

## 3. Apply learnings — epic (non-meta)

For each pattern/gotcha relevant to unstarted stories in same epic:

```bash
find [EPIC_DIR]/stories/*/spec.md  # future / not started
```

Propose spec updates; show diff; ask approval; document in Immediate Actions.

Append to `epic.md` / `epic-architecture.md` when epic-wide.

## 4. Escalation rules

| Handle now | Escalate to epic retro |
|------------|------------------------|
| Specific future story in epic | Pattern might repeat — needs ≥2 validation |
| Clear epic doc update | Process/template issue |
| Low-risk immediate fix | Cross-epic or methodology insight |

## 5. Next

Ready for next story. Epic retrospective when all stories complete.

## NEVER / ALWAYS

- NEVER skip validation-report read
- NEVER apply epic-wide changes without approval
- NEVER escalate 1-story patterns as validated
- ALWAYS produce structured story-retro.md for epic consumption
- ALWAYS mine git tags when commits exist
