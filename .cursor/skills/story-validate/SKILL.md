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

1. Cheap-key read only: locate `STORY_DIR`; read `.speck/project.json`; take
   **claimed_state** from `--claim`, the requested target, or the existing
   report claim. Classify UI vs backend. For UI, identify exactly one visual
   host from the active recipe/project files.
2. Before the first mutation, run exactly one contract:
   - Backend: `python3 .speck/scripts/context/speck_context.py story-validate-backend --select claimed_state=<state>`
   - UI: `python3 .speck/scripts/context/speck_context.py story-validate-ui --select claimed_state=<state> --select visual_host=<host>`
3. Require exit 0 and `SPECK_CONTEXT_RECEIPT`. Do not directly load unselected
   state, archetype, axis, or host references.
4. Execute every receipted node in order. Locate and record `build_sha`; run the
   real checks/probes; write the report; lower the claim to the highest state
   actually earned; then close the report loop:
   - SHA-stamp the report, then run every post-write gate selected by the
     receipt;
   - use one direct shell tool call per gate, with the gate as the event's
     primary command, so that event exit code belongs to that gate; never group
     it with other commands or merely print collected statuses;
   - if any gate is red, correct or lower the report, re-stamp it, and run the
     complete gate set again;
   - stop only after every selected gate exits 0 after the most recent stamp,
     with no later report edit.

STOP on any node STOP / P0 / missing required evidence.
