---
name: analyze
description: Runs decorrelated planning analysis. Use after project-plan, epic-breakdown, or story-tasks before downstream work.
---

# analyze

Canonical planning-analysis engine. `$ARGUMENTS` may contain `--level project|epic|story`.

## Select level and tier

1. Honor explicit `--level`; else infer story, epic, or project from the target path.
2. Project requires `project.md`, `PRD.md`, `epics.md`; epic requires `epic.md`, `epic-tech-spec.md`, `epic-breakdown.md`; story requires `spec.md`, `plan.md`, `tasks.md`. STOP on a missing prerequisite.
3. Read `.speck/project.json` (`play_level`; missing = Platform). Count epics from `epics.md` and `epics/` directories.
4. Story: Sprint skips; Build uses one focused reviewer; Platform uses three. Project/epic: Sprint and Build 1-3 are optional-recommended, Build 4+ uses three lenses, and Platform uses seven.

## Load the selected core

Before analysis, run exactly one receipted core load:

```bash
# project or epic
python3 .speck/scripts/context/speck_context.py analyze-core \
  --select level=<project|epic> --select tier=<build|platform>

# story
python3 .speck/scripts/context/speck_context.py analyze-story-core \
  --select tier=<build|platform>
```

The selected core loads only its scope and tier. Project MUST NOT load `references/traceability.md`; epic MUST load it. Story MUST NOT load project/epic lenses. Report templates and `references/reports/*` are forbidden until findings return.

## Dispatch lenses

Use the tier's required lens ids. For each id, dispatch one reviewer that did not author the corpus. That reviewer runs exactly one level-specific loader and receives the artifact list:

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

It emits the selected template plus exactly one level report contract. Follow it to verify findings, write the report, run gates, commit after the analyzed corpus, and declare `BLOCKED | NEEDS_FIXES | CLEAN`. Read `references/gate-codes.md` only when enforcing or explaining analysis codes.

Direct `/project-analyze` and `/epic-analyze` names are user-only compatibility shims into this engine. STOP on any loaded-node STOP.
