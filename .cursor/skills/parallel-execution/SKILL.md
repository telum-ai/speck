---
name: parallel-execution
description: Concurrency and parallel epic/chunk execution recipe using Git worktrees, file-cluster chunking, seam contracts, and merge choreography. Required when executing multiple epics or stories in parallel.
disable-model-invocation: false
---

## Purpose

When multiple epics or stories are executed in parallel (across separate sessions or worktrees), shared truth artifacts and code files are contention hotspots. This skill defines the **Parallel-Conductor Pattern** to prevent merge collisions, index corruption, and simulated (unvalidated) results.

---

## 🧭 The Parallel-Conductor Pattern

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

## 🛠️ Core Doctrines

### 1. Worktree-Per-Chunk Isolation
- **One Epic/Chunk = One Worktree + One Branch** branched off the *current* `main`.
- Command to spawn:
  ```bash
  git worktree add ../<repo>-eNNN -b epic/eNNN origin/main
  ```
- **Daily Rebase**: Rebase off `main` daily to catch upstream changes early:
  ```bash
  git fetch && git rebase origin/main
  ```
- **Disk Hygiene**: Worktrees are a shared, exhaustible host resource. Remove the worktree immediately after merging:
  ```bash
  git worktree remove ../<repo>-eNNN
  ```

### 2. File-Cluster Chunking
- Group parallel work by independent **file clusters** (e.g., separate database tables, separate route sub-trees, or isolated UI components).
- If two parallel chunks must touch the same file, they **MUST** freeze the shared file or establish a **Seam Contract** before proceeding.

### 3. The Seam Contract Artifact
- Create a `seam-contract.md` file (using `.speck/templates/project/seam-contract-template.md`) to define the interface, shared types, and error behaviors at the boundary between parallel chunks.
- The contract must be registered in the project's planning corpus on `main` **before** worktrees are spawned.

### 4. Chunk Briefs with Scan Digest
- When spawning a subagent for a chunk, provide a **Chunk Brief** carrying a scan digest of the files, types, and APIs it owns.
- This prevents the subagent from scanning the entire repository and wasting token budget.

### 5. Merge Choreography
- **Push-Before-Spawn**: Push the full planning corpus (specs, tech-specs, seam contracts) to `origin/main` **before** spawning any worktree wave.
- **Conflicted-Merge Commit Guard**: Committing a manually resolved conflicted merge can cause lint-staged stashing to corrupt the index. **MUST** commit conflicted merges using:
  ```bash
  git commit --no-verify
  ```
  Then verify `git show --stat HEAD` lists all files and the commit has 2 parents.

### 6. The Verify-Skills Gate (Human-Launched Variant)
- A delegated subagent can emit template-shaped reports with a declared readiness state without ever invoking the actual Speck skills.
- The conductor **MUST** verify the subagent's transcript for real skill tool calls (e.g., `"name":"Skill"` for `speck-audit` and `story-validate`).
- **Reject any hand-rolled file writes or copy-pasted templates** that lack corresponding skill executions in the transcript.

### 7. Clean-Merge Re-Run Note (`--no-ff`)
- When merging a parallel branch back to `main`, **ALWAYS** use non-fast-forward merges to preserve history:
  ```bash
  git merge --no-ff epic/eNNN
  ```
- After merging, **ALWAYS** re-run the full validation suite (`npm test` and `/project-state`) to ensure no semantic drift or integration bugs were introduced by the merge.
