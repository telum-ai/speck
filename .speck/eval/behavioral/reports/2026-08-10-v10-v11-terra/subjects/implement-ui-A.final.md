Implemented S007 completely. Tasks are `completed` with 7/7 checked.

- Pure immutable state transitions and CommonJS exports: [app.js](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-ui-A/web/app.js)
- Accessible review UI with truthful `aria-pressed`, disabled approval, live status, focus and reduced-motion styles: [index.html](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-ui-A/web/index.html)
- Focused coverage: [app.test.cjs](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-ui-A/web/app.test.cjs)
- Canonical story artifacts updated, including [tasks.md](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-ui-A/specs/projects/001-pulseboard/epics/E001-capture-review/stories/S007-review-state/tasks.md) and [ui-spec.md](/Users/kjetil/Code/speck/.speck/eval/behavioral/.runs/2026-08-10-v10-v11-terra/workspaces/implement-ui-A/specs/projects/001-pulseboard/epics/E001-capture-review/stories/S007-review-state/ui-spec.md).

Evidence: `node --test web/app.test.cjs` passed 4/4; JS syntax checks, CommonJS smoke test, prerequisite check, and `git diff --check` passed.

Readiness: `NO-SHIP`—implementation complete; next required phases are `/audit` then `/story-validate`. UI self-review: ACCEPTABLE.