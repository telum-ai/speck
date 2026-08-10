Implemented S007 completely and marked all four story tasks complete.

Changed:
- [web/app.js](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-ui-B/web/app.js)
- [web/index.html](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-ui-B/web/index.html)
- [web/app.test.mjs](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-ui-B/web/app.test.mjs)
- [story tasks](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-ui-B/specs/projects/001-pulseboard/epics/E001-capture-review/stories/S007-review-state/tasks.md)
- Added the required [UI spec](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-ui-B/specs/projects/001-pulseboard/epics/E001-capture-review/stories/S007-review-state/ui-spec.md) and regenerated graph artifacts.

Evidence:
- `node --test web/app.test.mjs`: 6 passed, 0 failed.
- `node --check web/app.js`: passed.
- Story task validator: 4/4 complete, no errors.
- Story prerequisite gate: passed.
- Witness graph rebuilt and fresh.
- `git diff --check`: passed.

No readiness state is declared; the required next phase is `/audit`. The banned-language gate could not run because this workspace has no project `product-contract.md`.