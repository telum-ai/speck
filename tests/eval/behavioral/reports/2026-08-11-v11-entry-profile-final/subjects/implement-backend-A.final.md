Implemented S006 completely.

- Added `build_reminder` with validation, UTC `Z` timestamps, deterministic IDs, 24-hour scheduling, and the five-minute fallback in [reminders.py](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-11-v11-entry-profile-final/workspaces/implement-backend-A/src/reminders.py).
- Added seven contract tests in [test_reminders.py](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-11-v11-entry-profile-final/workspaces/implement-backend-A/tests/test_reminders.py).
- Marked all S006 tasks complete in [tasks.md](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-11-v11-entry-profile-final/workspaces/implement-backend-A/specs/projects/001-pulseboard/epics/E002-reminders/stories/S006-build-reminder/tasks.md).

Evidence: `python3 -m unittest discover -s tests -v` passed 7/7; `compileall` and `git diff --check` passed.

Readiness: implementation phase complete; no readiness state claimed. The next prescribed phase is independent audit.