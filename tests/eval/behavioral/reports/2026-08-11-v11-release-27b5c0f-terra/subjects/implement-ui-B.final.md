Implemented S007 completely.

- Added immutable review-state transitions and CommonJS exports in [web/app.js](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-11-v11-release-27b5c0f-terra/workspaces/implement-ui-B/web/app.js).
- Added accessible browser review rendering: truthful `aria-pressed`, selection toggles, and disabled approval until selection.
- Added focused coverage in [web/app.test.js](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-11-v11-release-27b5c0f-terra/workspaces/implement-ui-B/web/app.test.js).
- Marked all S007 tasks complete in [tasks.md](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-11-v11-release-27b5c0f-terra/workspaces/implement-ui-B/specs/projects/001-pulseboard/epics/E001-capture-review/stories/S007-review-state/tasks.md).

Evidence: `node --test web/app.test.js` passed 4/4 tests; `git diff --check` passed. Story prerequisite and graph checks were clear.

Readiness: implementation complete; no readiness claim at this phase. Next required route is independent `/audit`.