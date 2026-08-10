Implemented S006 completely.

- Added `build_reminder(action, now)` with validation, UTC normalization, normal/fallback scheduling, determinism, and no input mutation: [reminders.py](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-backend-B/src/reminders.py)
- Added seven `unittest` cases covering invalid inputs and all scheduling boundaries: [test_reminders.py](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-backend-B/tests/test_reminders.py)
- Reconciled the story lifecycle to `Specified` and marked all implementation tasks complete: [spec.md](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-backend-B/specs/projects/001-pulseboard/epics/E002-reminders/stories/S006-build-reminder/spec.md), [tasks.md](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-backend-B/specs/projects/001-pulseboard/epics/E002-reminders/stories/S006-build-reminder/tasks.md)

Evidence: prerequisite and graph checks passed; `python3 -m unittest discover -s tests -v` passed 7/7; Python compilation and `git diff --check` passed.

Readiness: implementation complete. The next required phase is `/audit`, then `/story-validate`.