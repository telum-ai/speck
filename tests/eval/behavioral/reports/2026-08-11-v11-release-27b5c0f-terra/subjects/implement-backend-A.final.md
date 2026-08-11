Implemented S006 completely.

- Added `build_reminder` in [src/reminders.py](/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-11-v11-release-27b5c0f-terra/workspaces/implement-backend-A/src/reminders.py).
- Added boundary/validation/immutability tests in [tests/test_reminders.py](/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-11-v11-release-27b5c0f-terra/workspaces/implement-backend-A/tests/test_reminders.py).
- Updated all S006 tasks to completed in [tasks.md](/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-11-v11-release-27b5c0f-terra/workspaces/implement-backend-A/specs/projects/001-pulseboard/epics/E002-reminders/stories/S006-build-reminder/tasks.md).

Evidence: `python3 -m unittest discover -v` passed — 8 tests. `py_compile` and `git diff --check` also passed.

Readiness is not claimed at this implementation phase; the prescribed next step is independent audit.