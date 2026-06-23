# Orchestration Ledger — [PROJECT_ID]

<!--
The conductor's persistent working memory for a concurrent multi-epic run. It is the ONE file
that survives context compaction, spend-limit pauses, and rate-limit resets — re-read it on every
resume to know exactly where the wave stands. Keep it terse and CURRENT (overwrite, don't append
prose). Update it after every state change. See .speck/patterns/learned/process/parallel-epic-execution.md.

Coordination-only file (not a truth artifact): keep it on `main` (or the conductor's branch).
Do NOT regenerate project-state.md from epic branches — that stays merge-only.
-->

**Run started**: [DATE]
**Conductor**: [session/agent id]
**Base SHA pushed to origin/main**: [SHA]  ← worktrees branch from here; re-push + record after every merge
**Active wave**: [N]  (per `epics.md` → Epic Concurrency Waves)

## Wave Plan

| Wave | Epics | Status (pending / running / merged) | Notes |
|------|-------|-------------------------------------|-------|
| 0 | E000 | merged | foundation |
| 1 | E001, E002 | running | |
| 2 | E003 | pending (integrator — waits for wave 1 merge) | |

## Per-Epic Cursor

| Epic | Branch / worktree | DEC band | Story cursor (current → next) | Open gate | Verify-skills status | Disk (worktree present?) |
|------|-------------------|----------|-------------------------------|-----------|----------------------|--------------------------|
| E001 | `epic/e001` @ `../repo-e001` | DEC-0101+ | S004 implementing → S005 | none | — | yes |
| E002 | `epic/e002` @ `../repo-e002` | DEC-0201+ | S012 audited → validate | awaiting verify-gate | pending (need speck-audit + story-validate in transcript) | yes |

## Open Gates / Blockers (must clear before advancing)

- [ ] [e.g. E002/S012: verify-skills gate — confirm speck-audit + story-validate actually ran before accepting]
- [ ] [e.g. push base corpus to origin/main before spawning wave 2]

## Guards Checklist (re-confirm each resume)

- [ ] Planning corpus pushed to `origin/main` before this wave was spawned (worktrees branch from `origin/main`, not local HEAD)
- [ ] Each merged epic's worktree removed (`git worktree remove ../repo-eNNN` - omit `--force` by default so git safely blocks on dirty trees and warns of lost WIP) — disk is shared cross-session state
- [ ] Interrupted/killed background agent WIP recovered directly from its worktree on disk (`git add -A && commit`) instead of restarting
- [ ] Conflicted merges committed with `--no-verify` (prevents lint-staged `--keep-index` index corruption / file drop), and verified with `git show --stat HEAD` to ensure 2 parent hashes and all files are intact
- [ ] Migration filenames use real wall-clock `date -u +%Y%m%d%H%M%S` (no rounded placeholders); per-epic offset bands as fallback
- [ ] No epic accepted on a self-reported `{readiness_state, pass}` — Verify-Skills Gate passed for each merged story (including verifying `gate_checks` for full pre-commit gate success)
- [ ] `project-state.md` regenerated on `main` only (never overwritten from `epic/*` branches)

---

*Coordination file — overwrite to keep current. Not SHA-stamped, not a truth artifact.*
