# parallel-execution / verify-skills

## The Parallel-Conductor Pattern

```
                 [main] (planning corpus pushed)
                   │
         ┌─────────┴─────────┐
         ▼                   ▼
   [worktree-e001]     [worktree-e002]
   (seam-contract)     (seam-contract)
         │                   │
         └─────────┬─────────┘
                   ▼
         [merge choreography] (Verify-Skills Gate)
                   │
                 [main] (post-merge /project-state)
```

---
