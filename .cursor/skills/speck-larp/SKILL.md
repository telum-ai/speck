---
name: speck-larp
description: Runtime persona LARP (DOES-IT-WORK + IS-IT-GOOD). Use at UI validate.
---

# speck-larp

Input: `$ARGUMENTS` (persona / tier).

1. MUST Read template in spine, then MUST Read `references/spine.md`.
2. If backend/non-UI: MUST Read `references/backend-skip.md` then STOP.
3. MUST Read `references/build-check.md`. If fail → STOP.
4. Read `references/sandbox-recipe.md` only if sandbox/restricted env.
5. MUST Read `references/jobs/does-it-work.md` and run Job A.
6. MUST Read `references/jobs/felt.md` and run Job B.
7. Read `references/jobs/taste.md` only if caller requires Job C / UX-RC+ taste.
8. MUST Read `references/recording.md`. Write + stamp evidence.
