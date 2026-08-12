---
name: speck-larp
description: Exercises real user or operator jobs. Use after audit before story, epic, or project validation.
---

# speck-larp

Cheap keys: `.speck/project.json` → `project_archetype`; claimed LARP jobs (A/B/C); whether auth/data blocks reachability.

1. If archetype is `infra_service` / `backend_api` / backend-only (no UI surface): MUST Read `references/backend-skip.md`, produce its operational evidence, then STOP without loading UI nodes.
2. Else MUST Read `references/spine.md` (P3 reach-everything, prereqs, behavior).
3. If a runtime gate blocks the persona (auth wall, empty DB, missing seed): MUST Read `references/sandbox-recipe.md` and apply a listed unlock before continuing.
4. MUST Read `references/jobs/does-it-work.md` (Job A — always for UI LARP).
5. If claiming FELT / IS-IT-GOOD / magic-moments: MUST Read `references/jobs/felt.md`. Else do not Read it.
6. If claiming TASTE / connoisseur judgment: MUST Read `references/jobs/taste.md`. Else do not Read it.
7. For UI, invoke `visual-testing` inside the LARP to produce host-specific visual and accessibility evidence.
8. MUST Read `references/recording.md`. Write evidence; SHA-stamp.
STOP on any STOP in a Read node.
