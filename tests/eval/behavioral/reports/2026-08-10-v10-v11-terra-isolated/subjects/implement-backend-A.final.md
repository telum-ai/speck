Implemented S006 completely.

- `build_reminder` now validates confirmed actions, handles UTC timestamps and scheduling boundaries, returns deterministic `Z` timestamps, and does not mutate input: [reminders.py](/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-10-v10-v11-terra-isolated/workspaces/implement-backend-A/src/reminders.py)
- Added five behavior tests: [test_reminders.py](/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-10-v10-v11-terra-isolated/workspaces/implement-backend-A/tests/test_reminders.py)
- Updated S006’s lifecycle label and marked all implementation tasks complete: [tasks.md](/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-10-v10-v11-terra-isolated/workspaces/implement-backend-A/specs/projects/001-pulseboard/epics/E002-reminders/stories/S006-build-reminder/tasks.md)

Evidence:

- Story prerequisite gate: passed.
- `python3 -m unittest discover -s tests -v`: 5 passed.
- `python3 -m compileall -q src tests`: passed.
- `git diff --check`: passed.

Readiness was not assessed in this phase; the required next route is `/audit`.