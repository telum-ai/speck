---
name: parallel-execution
description: Guides safe parallel execution. Use before dispatch when worktrees, seam contracts, or merge choreography are needed.
---

# parallel-execution

Cheap keys: lifecycle moment — before spawn, while creating worktrees, or at merge.

1. Before spawning any parallel worker: MUST Read `references/wave-safety.md`. Do not spawn without it.
2. When creating git worktrees/branches: MUST Read `references/worktrees.md`. Skip if not creating worktrees.
3. Before accepting merge of parallel work: MUST Read `references/verify-skills.md`. Skip at spawn time.
