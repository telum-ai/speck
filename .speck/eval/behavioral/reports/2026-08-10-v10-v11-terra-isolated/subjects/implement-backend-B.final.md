Implemented S006 completely.

- Added validated, deterministic UTC reminder construction in [src/reminders.py](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-10-v10-v11-terra-isolated/workspaces/implement-backend-B/src/reminders.py).
- Added 7 focused unit tests in [tests/test_reminders.py](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-10-v10-v11-terra-isolated/workspaces/implement-backend-B/tests/test_reminders.py).
- Completed the story spec, plan, data model, callable contract, quickstart, and marked all 3 tasks complete in [tasks.md](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-10-v10-v11-terra-isolated/workspaces/implement-backend-B/specs/projects/001-pulseboard/epics/E002-reminders/stories/S006-build-reminder/tasks.md).

Evidence:

- `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v` → 7/7 passing.
- Story prerequisite check passed.
- Spec, plan, and task validators reported zero errors.
- Witness graph rebuilt and checked successfully.
- `git diff --check` passed.

Readiness remains `NO-SHIP`: implementation is complete, but `/audit` and `/story-validate` were intentionally not run because this request stops at implementation.