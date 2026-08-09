---
name: epic-analyze
description: Decorrelated epic planning analysis. Use after epic-breakdown before stories.
---

# epic-analyze

Prereq: `epic.md`, `epic-tech-spec.md`, `epic-breakdown.md` in epic dir. STOP if missing.
Output: `[EPIC_DIR]/epic-analysis-report.md`.

1. MUST Read `.speck/templates/epic/epic-analysis-report-template.md`.
2. Read `.speck/project.json` → `play_level` (missing = Platform). Count epics: max of `### E###` in `epics.md` and `epics/` dirs → **tier**.
3. MUST Read `references/spine.md`.
4. Branch tier:
   - Sprint / Build 1–3: optional/recommended. If skipping: STOP with reason. If running: treat as Build 4+ lens set only if owner requests full; default Read `references/tiers/build-4.md`.
   - Build 4+: MUST Read `references/tiers/build-4.md`.
   - Platform: MUST Read `references/tiers/platform.md`.
5. MUST Read `references/traceability.md`. Run matrix validator.
6. If L3 in required set: MUST Read `references/promise-inventory.md` before dispatching L3.
7. For each required lens id: dispatch one reviewer; that agent MUST Read **only** `references/lenses/L#.md` (+ artifact list). Conductor does NOT preload other lenses.
8. After findings return: MUST Read `references/verify-and-report.md`. Write + commit report.
9. Read `references/gate-codes.md` only when enforcing/explaining P-codes or running gate scripts.

STOP if any Read node says STOP.
