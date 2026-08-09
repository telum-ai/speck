# parallel-execution / wave-safety

## Purpose

When multiple epics or stories are executed in parallel (across separate sessions or worktrees), shared truth artifacts and code files are contention hotspots. This skill defines the **Parallel-Conductor Pattern** to prevent merge collisions, index corruption, and simulated (unvalidated) results.

---

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

## Core Doctrines

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

### 7. Clean-Merge Re-Run (`--no-ff`) + the Post-Merge Semantic Gate
- When merging a parallel branch back to `main`, **ALWAYS** use non-fast-forward merges to preserve history:
  ```bash
  git merge --no-ff epic/eNNN
  ```
- After merging, **ALWAYS** re-run the full validation suite (`npm test` and `/project-state`) to ensure no semantic drift or integration bugs were introduced by the merge.

#### A git-clean merge is not a clean merge

git resolves **text**. It has no model of the invariants two branches can each satisfy alone and jointly break, so **a merge that reported zero conflicts is exactly the case this gate exists for** — do not skip these because the merge was clean.

Plan-time wave/cluster assignment (Doctrine §2 above; issue #68 §1) stops two concurrent chunks from authoring a migration against the same head **before** they are spawned. That is a *prevention*, and it ships with no gate that catches a collision **after** a merge — its framing is that a git-clean merge is clean. Verified recurrence, six weeks after that prevention closed: **two migration heads arrived from a conflict-free merge, and an un-appliable migration reached a pre-push gate.** An un-appliable migration does not merely block itself — it wedges the head and every later migration behind it, including security fixes. A constraint nobody can apply protects nothing.

Run all four **on the merge commit, before push**, alongside the full suite:

1. **ONE migration head.** Two heads is the canonical clean-merge break — each branch appended to a head that was current when it forked.
   ```bash
   test "$(alembic heads | wc -l)" -eq 1
   # django: python manage.py makemigrations --check --dry-run   (one leaf per app)
   # prisma: npx prisma migrate status                           (no divergence fork)
   # knex / typeorm / goose: that framework's own no-divergence check
   ```
2. **The migration is APPLIABLE against the target's real DIRTY state** — not merely present and syntactically valid. Seed a throwaway with the **shape** of the dirt the constraint will meet (the duplicates / nulls / orphans the target environment actually has — *synthesized, never cloned from production*), apply forward, and assert three things: the **pre-state was REJECTED**, the post-state accepts, **and the boundary cases still refuse**. Without those controls a migration that merely *drops* the constraint passes just as green. Record it as `proved-against: <throwaway description>` on the merge.
3. **The lockfile RESOLVES.** A lockfile merged from two branches is textually clean and semantically broken. Install **frozen** — if the tool has to rewrite the lockfile, the merge is not finished.
   ```bash
   npm ci   # pnpm install --frozen-lockfile · yarn --immutable · uv sync --frozen · poetry check --lock
   ```
4. **The derived graph RECOMPILES AT THE MERGE COMMIT.** Two branches can each carry a valid derived graph whose union is not one. Rebuild it at the merge SHA — never trust either parent's.

Bounding rules:
- Any of the four failing means the merge is **incomplete**, not that a follow-up ticket is owed. Fix it *in* the merge commit, before push.
- **Deploy order is part of the deliverable.** When a migration and the code that reads it ship separately, the merge record states which goes first. A runbook written afterwards is not a gate.
- A migration may make an un-appliable constraint appliable. It may **not** silently resolve a *product* question (e.g. whether fabricated rows should be purged rather than deduplicated) — log that as an owner decision and leave the rows.
