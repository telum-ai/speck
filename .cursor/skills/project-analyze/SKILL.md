---
name: project-analyze
description: Decorrelated project planning analysis. Use after plan before epic-specify.
---

# project-analyze

Prereq: `project.md`, `PRD.md`, `epics.md`. STOP if missing — run `/project-plan` first.
Output: `[PROJECT_DIR]/project-analysis-report.md`.
NOT `/project-validate` (post-implementation).

1. MUST Read `.speck/templates/project/project-analysis-report-template.md`.
2. Read `.speck/project.json` → `play_level` (missing = Platform). Count epics → **tier**.
3. MUST Read `references/spine.md`.
4. Branch tier:
   - Sprint / Build 1–3: optional/recommended. If skipping: STOP with reason. If running: MUST Read `references/tiers/build-4.md`.
   - Build 4+: MUST Read `references/tiers/build-4.md`.
   - Platform: MUST Read `references/tiers/platform.md`.
5. If L3 in required set: MUST Read `references/promise-inventory.md` before L3.
6. For each required lens id: dispatch one reviewer; that agent MUST Read **only** `references/lenses/L#.md` (+ artifact list). Conductor does NOT preload other lenses.
7. After findings: MUST Read `references/verify-and-report.md`. Write + commit report.
8. Read `references/gate-codes.md` only when enforcing/explaining P-codes or running gate scripts.

STOP if any Read node says STOP.
