---
name: story-validate
description: Validates a story after audit and declares readiness. Use at the story prove gate before retrospective.
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
   state, archetype, axis, or host references. The receipt's
   `post_write_gates`, `post_write_gates_all`, and `gate_policy` fields are the
   exact executable closure contract; do not reconstruct or batch it.
4. Execute every receipted node in order; record `build_sha`, run real probes,
   and lower the claim to what is earned. Follow the receipted post-write node
   literally: after the latest stamp, run every gate individually even on a
   downgrade. Correctable red may edit, re-stamp, and rerun all; otherwise run
   the remaining gates, record `conformant_red` blockers, then make no edit.

STOP on any node STOP / P0 / missing required evidence.
