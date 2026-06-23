# Pattern: Parallel Epic Execution (Conductor + Orchestration Ledger)

**Category**: process
**Discovered**: 2026-06 (Flyt E002 — concurrent multi-epic run across ~35 worktrees)
**Validated In**: Flyt `001-flyt-ai-first-studio-management-platform` (E002 feedback)
**Occurrences**: 1 (codified from a real multi-session parallel run that survived compaction, spend-limit pauses, and rate-limit resets)

## Problem

Running 2+ epics in parallel (separate sessions or git worktrees) to compress calendar time creates three failure modes that single-epic flow never hits:

1. **State loss across resets** — long parallel runs hit context compaction, spend limits, and rate limits. Without a durable coordination file, the conductor "wakes up" not knowing which story each epic is on or which gate is open, and re-does or skips work.
2. **Simulated rigor at the merge boundary** — a delegated/background epic or story sub-agent can emit template-shaped artifacts with a declared readiness state **without ever invoking the skills**. Accepting that on its self-reported `{readiness_state, pass}` merges unvalidated work that looks validated.
3. **Shared-resource collisions** — worktrees branch from `origin/main` (not local HEAD), pile up on disk (~1 GB+ each → host `ENOSPC` freezes *every* session on the machine), race on `project-state.md` regeneration, and collide on rounded migration timestamps.

## Solution

A single **conductor** session owns sequencing and merges. It keeps one durable **orchestration ledger** as its working memory and enforces the v7.14 guards at every boundary. Epic/story execution is delegated; the conductor never trusts a delegated verdict — it verifies the skills ran.

### The conductor loop

```
1. Read epics.md → Epic Concurrency Waves. Identify the current wave (only same-wave,
   non-integrator epics may run in parallel).
2. PUSH the planning corpus to origin/main (specs, tech-spec, wireframes, traceability-matrix,
   DECs). Worktrees branch from origin/main — unpushed commits are invisible to the wave.
3. For each epic in the wave: create worktree off origin/main, assign its DEC band, route to /epic.
   Each sub-agent prompt carries a precondition guard: "verify <spec path> exists on this branch, else abort."
4. Write/refresh the orchestration-ledger (per-epic cursor, open gate, wave cursor, guards checklist).
5. As each delegated unit returns, run the VERIFY-SKILLS GATE before accepting (see below).
6. On accept: merge to main.
   > ⚠️ **CONFLICTED-MERGE COMMIT GATES (lint-staged stashing corruption)**: For projects using husky + lint-staged, a conflicted merge commit — after manual resolution and `git add` — can trigger lint-staged `--keep-index` stashing, which frequently corrupts the git index. This results in the commit silently dropping auto-merged files (e.g., database migrations or shared modules) and writing a broken single-parent commit instead of a true merge commit. 
   > **Guard Requirement**: Use `git commit --no-verify` exclusively for conflicted merge commits (since post-merge CI checks will still validate quality), and always run `git show --stat HEAD` to verify that (a) all expected files are in the commit, and (b) the commit header lists two parent hashes (e.g., `Merge: a1b2c3d e4f5g6h`).
7. Clean up worktrees: Run `git worktree remove ../<repo>-eNNN` (omit `--force` by default so git safely blocks on uncommitted or dirty states, warning you of lost WIP; use `--force` only when completely certain).
8. Re-push `origin/main`, regenerate `project-state.md` ON MAIN ONLY, and update the ledger.
9. When the wave is fully merged, advance to the next wave (integrators last). Repeat.
On any reset (compaction / spend / rate limit): re-read the orchestration-ledger and resume at step 4.
```

> 🛠️ **INTERRUPTED SUB-AGENT RECOVERY (WIP Restoration)**: If a background or worktree sub-agent is killed, timed out, or interrupted mid-task, its in-memory agent state is lost but its worktree on disk is intact. Do NOT delete and restart. Recover the work directly by navigating to the worktree and running `git -C ../<repo>-eNNN add -A && git -C ../<repo>-eNNN commit -m "WIP: agent recovery"` to capture the state, then either resume the task directly in that worktree or merge the WIP branch.

### The orchestration ledger

The one file that survives resets. Template: `.speck/templates/project/orchestration-ledger-template.md`. Keep it on `main` (or the conductor's branch) as a coordination-only file — it is **not** a truth artifact and is **not** SHA-stamped. Overwrite to keep it current; re-read it on every resume. It tracks: base SHA pushed to `origin/main`, active wave, per-epic branch/worktree/DEC-band/story-cursor/open-gate/verify-status/disk-present, open blockers, and the guards checklist.

### Verify-Skills Gate (the anti-simulation backstop)

Before ACCEPTING/merging any delegated story or epic result, the conductor MUST:

1. **Reports exist + compliant**: required reports (`validation-report.md`, `audit-report.md`; epic: `epic-validation-report.md`, `traceability-matrix.md`) exist AND pass `bash .speck/scripts/validation/validate-template.sh --strict <path>`.
2. **Skills actually ran**: the unit's return contract `{ readiness_state, pass, p0p1, artifact_paths, skills_invoked, gate_checks }` lists ≥2 real skill invocations — stories: `speck-audit` + `story-validate`; epics: `epic-analyze` + `epic-validate`. The conductor MUST cross-check the sub-agent's JSON transcript or execution log by running a grep search for `"name":"Skill"` (the host's tool call signature) to confirm at least 2 real skill invocations actually ran. Empty / zero → **REJECT + re-run**.
   > 💡 **AGENT ROLE AND SKILL-TOOL CAUTION**: If a host environment restricts custom agent types (like `@speck-coder` or `@speck-auditor`) from executing the `Skill` tool, those agents will fail to run the validation/specification flows. In such cases, the lanes requiring skill execution **MUST** use a general-purpose, all-tools agent to ensure the real skill is run and recorded in the transcript. Reading the skill markdown file by hand is considered simulation and will be rejected at the Verify-Skills Gate.
3. **Mandatory Independent Auditor**: Ensure that the story's `audit-report.md` was authored by a separate, independent auditor agent/session rather than the implementer/validator. Self-audits suffer from confirmation bias (field runs showed separate audits caught 4 critical defects across 9 stories missed by self-audits, including a Next.js `use-server` compile-breaker, false/simulated readiness claims, and silent runtime database transaction crashes).
4. **Full pre-commit gate passed**: `gate_checks` lists passing status for eslint, typecheck, tests, build, and banned-language check (reject on any skipped or failed checks).
5. **`/audit` non-skippable**: a unit merged without a real `/audit` is rejected regardless of its self-reported state.

Self-reported fields are not tamper-evident (host-runtime limit) — the transcript check is the backstop. A unit that produced passing-looking artifacts with zero skill calls is **simulated, not validated**.

## Example

Ledger mid-run (wave 1 = E001 + E002, E002 just returned a story):

```
Active wave: 1
| E001 | epic/e001 @ ../repo-e001 | DEC-0101+ | S004 impl → S005 | none | — | yes |
| E002 | epic/e002 @ ../repo-e002 | DEC-0201+ | S012 audited → validate | awaiting verify-gate | pending | yes |
Open gates:
- [ ] E002/S012: confirm speck-audit + story-validate in transcript before accepting
```

Conductor inspects S012's return: `skills_invoked: ["story-implement"]` only → no audit, no validate → **REJECT**, re-run `/story` for S012 from the Audited state. After a clean re-run with `skills_invoked: ["speck-audit","story-validate"]` and template-compliant reports → accept, merge, re-push `origin/main`, `git worktree remove --force ../repo-e002`, regenerate `project-state.md` on main, advance E002 cursor.

## When to Use

- Platform projects or 4+ epic Builds where wave-parallel epics meaningfully compress calendar time.
- Any run expected to span multiple sessions / survive compaction, spend, or rate-limit resets.

## When NOT to Use

- Single-epic or strictly sequential work — the ledger and conductor overhead aren't justified; just use `/epic`.
- Epics with unmet upstream dependencies (integrators) — they wait for the upstream wave to merge; never parallelize across a dependency edge.
- When host disk can't hold the wave's worktrees — reduce wave width instead of risking `ENOSPC`.

## Related Patterns

- AGENTS.md → **Concurrent multi-epic execution** (doctrine table: worktree isolation, push-before-spawn, disk hygiene, DEC bands, project-state merge-only, migration version coordination, epic waves).
- AGENTS.md → **Delegated execution: verify skills ran before accepting results** (the return contract + verify-skills gate).
- `.speck/templates/project/epics-list-template.md` → Epic Concurrency Waves & Rebase Cadence.

## Source

- First discovered: Flyt E002 concurrent run (SPECK-FEEDBACK-from-E002, Part 1 §6 + Part 2).
- Codified in: Speck v7.14.0.
