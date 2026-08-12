---
name: analyze
description: Runs decorrelated planning analysis. Use after project-plan, epic-breakdown, or story-tasks before downstream work.
---

# analyze

Canonical planning-analysis engine. `$ARGUMENTS` may contain `--level project|epic|story`.

## Select level and depth

1. Honor explicit `--level`; else infer story, epic, or project from the target path.
2. Project requires `project.md`, `PRD.md`, `epics.md`; epic requires `epic.md`, `epic-tech-spec.md`, `epic-breakdown.md`; story requires `spec.md`, `plan.md`, `tasks.md`. STOP on a missing prerequisite.
3. Read `.speck/project.json` (`play_level`; missing = Platform). Count epics from `epics.md` and `epics/` directories.
4. Story: Sprint skips; Build runs S1; Platform runs S1-S3. Project: Build 1-3 runs focused L7 only when requested, Build 4+ runs L3/L6/L7, Platform runs L1-L7. Epic: Build runs focused L7 and Platform runs L1-L7.

## Load the core

Before analysis, run one receipted load. It supplies scope, flow-fit, promise, traceability, severity, and role-separation rules without loading any reviewer lens or report template:

```bash
python3 .speck/scripts/context/speck_context.py analyze-core \
  --select level=<project|epic|story>
```

Require exit 0 and `SPECK_CONTEXT_RECEIPT`. Report templates and `references/reports/*` are forbidden until findings return.

## Dispatch lenses

For every required lens id, dispatch one reviewer that did not author the corpus. That reviewer runs exactly one level-specific loader and receives the target artifact list:

```bash
# project or epic
python3 .speck/scripts/context/speck_context.py analyze-<project|epic>-lens \
  --select lens=L#

# story
python3 .speck/scripts/context/speck_context.py analyze-story-lens \
  --select lens=S#
```

The loader emits `references/lens-spine.md` plus exactly one of `references/lenses/project/L#.md` or `references/lenses/epic/L#.md`; sibling level and lens nodes are forbidden. The conductor does not preload lens nodes. Lenses do not share findings before verification.

## Finish

After findings return, run exactly one second-stage load before any report mutation:

```bash
python3 .speck/scripts/context/speck_context.py analyze-report \
  --select level=<project|epic|story>
```

It emits the selected template plus exactly one level report contract. Follow it to verify findings, write the report, run gates, commit after the analyzed corpus, and declare `BLOCKED | NEEDS_FIXES | CLEAN`. Read `references/gate-codes.md` only when enforcing or explaining analysis codes. STOP on any loaded-node STOP.
