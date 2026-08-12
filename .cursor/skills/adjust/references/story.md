# Story adjustment branch

Update the affected FRs and ACs without rebuilding the story specification from scratch. Re-enter at `/story-plan` when the technical approach changed, then run `/story-tasks`, `/analyze --level story` when required, and `/story-implement`; do not patch plan, tasks, and code as an untracked side sequence.

Reconcile `traceability-matrix.md`. Retire removed promises with a DEC and add PRM rows for new elements, actions, states, and seams.

Run `/speck-audit`, then `/story-validate` focused on the delta. Capture new runtime and visual evidence when the story has UI.

Write `specs/projects/<PROJECT_ID>/epics/E###/stories/S###/story-adjust-report-<YYYYMMDD>.md` from `.speck/templates/story/story-adjust-template.md`.

After the last mutation, run separately:

```bash
bash .speck/scripts/validation/validate-template.sh --strict [STORY_ADJUST_REPORT]
bash .speck/scripts/stamp-truth.sh [STORY_ADJUST_REPORT]
```
