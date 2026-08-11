Implemented S007.

- Added immutable review state functions and browser controls in [app.js](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-10-v10-v11-terra-isolated/workspaces/implement-ui-B/web/app.js).
- Added UI behavior coverage in [app.test.js](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-10-v10-v11-terra-isolated/workspaces/implement-ui-B/web/app.test.js), plus the canonical [ui-spec.md](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-10-v10-v11-terra-isolated/workspaces/implement-ui-B/specs/projects/001-pulseboard/epics/E001-capture-review/stories/S007-review-state/ui-spec.md).
- Marked all S007 tasks complete with evidence in [tasks.md](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-10-v10-v11-terra-isolated/workspaces/implement-ui-B/specs/projects/001-pulseboard/epics/E001-capture-review/stories/S007-review-state/tasks.md).

Evidence: `node --check web/app.js` passed; `node --test web/app.test.js` passed 5/5; `git diff --check` passed; witness graph built and checked.

No readiness state is claimed at implementation phase; next route is `/audit`. The banned-language gate cannot issue a verdict because the required project `product-contract.md` is absent, and the prereq checker retains its inherited `current_state: Planned` mismatch.