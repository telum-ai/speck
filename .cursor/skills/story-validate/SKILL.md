---
name: story-validate
description: Validates story after audit. Use at story prove; claim readiness state.
paths:
  - "specs/projects/**/S*/**"
  - "specs/projects/**/stories/**"
  - "specs/projects/**/**/spec.md"
  - "specs/projects/**/**/plan.md"
  - "specs/projects/**/**/tasks.md"
---

# story-validate

Prereq: `spec.md`, `plan.md`, `tasks.md`, `audit-report.md`. Verdict = readiness state (never PASS/FAIL).
Output: `[STORY_DIR]/validation-report.md`.

1. MUST Read `.speck/templates/story/validation-report-template.md`.
2. MUST Read `references/spine.md`. Locate `STORY_DIR`; record `build_sha`.
3. Read `.speck/project.json` → `project_archetype`. Declare `--claim` / highest supported → **claimed_state**.
4. Branch archetype:
   - `infra_service` / `backend_api` / backend-only: MUST Read `references/backend-skip.md`. Do NOT Read larp / felt / taste / visual / reachability.
   - UI-facing: MUST Read `references/larp.md`.
5. MUST Read `references/execution.md`.
6. For claimed_state and every lower ladder state, MUST Read `references/states/<kebab>.md`.
   Ladder: `no-ship` < `impl-green` < `integration-green` < (`ux-rc`|`api-rc`) < `commercial-rc` < `ship-rc` < `ship`.
7. If claimed ≥ `integration-green`: MUST Read `references/integration-green.md`.
8. If UI and claimed ≥ `ux-rc`: MUST Read `references/axes/felt.md` and `references/axes/taste.md`.
9. If UI and visual platform not `api`/`cli`: MUST Read `references/visual.md`, then exactly one `visual-testing/references/<host>.md`.
10. If claimed ≥ `commercial-rc`: MUST Read `references/commercial.md`.
11. MUST Read `references/spec-coverage.md`, `references/code-audit.md`, `references/post-write.md`.
    If UI: also MUST Read `references/reachability.md`.
12. Write report; SHA-stamp; run validators in `post-write.md`.

STOP on any node STOP / P0 / missing required evidence.
