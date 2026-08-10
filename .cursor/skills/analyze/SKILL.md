---
name: analyze
description: Runs decorrelated analysis of project or epic planning. Use after project-plan or epic-breakdown before downstream work.
---

# analyze

Canonical planning-analysis engine. `$ARGUMENTS` may contain `--level project|epic`.

## Select level and tier

1. Honor explicit `--level`; else infer project vs epic from the target path. Story analysis is retired: route pre-implementation consistency to `/story-tasks` and post-implementation challenge to `/audit`.
2. Project requires `project.md`, `PRD.md`, `epics.md`; epic requires `epic.md`, `epic-tech-spec.md`, `epic-breakdown.md`. STOP on a missing prerequisite.
3. Read `.speck/project.json` (`play_level`; missing = Platform). Count epics from `epics.md` and `epics/` directories.
4. Sprint / Build 1-3 analysis is optional-recommended. If skipped, STOP with the reason. If run, use the Build lens tier. Build 4+ uses Build; Platform uses Platform.

## Load the selected core

Before analysis, run exactly one receipted load:

```bash
python3 .speck/scripts/context/speck_context.py analyze-core \
  --select level=<project|epic> --select tier=<build|platform>
```

The level edge loads only its corpus rules. Project MUST NOT load `references/traceability.md`; epic MUST load it. Build loads `references/tiers/build-4.md`; Platform loads `references/tiers/platform.md`. Both load `references/spine.md` and `references/promise-inventory.md`. Report templates and `references/reports/*` are forbidden until findings return.

## Dispatch lenses

Use the tier's required lens ids. For each id, dispatch one reviewer that did not author the corpus. That reviewer runs exactly one level-specific loader and receives the artifact list:

```bash
python3 .speck/scripts/context/speck_context.py analyze-<project|epic>-lens \
  --select lens=L#
```

The loader emits `references/lens-spine.md` plus exactly one of `references/lenses/project/L#.md` or `references/lenses/epic/L#.md`; sibling level and lens nodes are forbidden. The conductor does not preload lens nodes. Lenses do not share findings before verification.

## Finish

After findings return, run exactly one second-stage load before any report mutation:

```bash
python3 .speck/scripts/context/speck_context.py analyze-report \
  --select level=<project|epic>
```

It emits the selected template plus exactly one of `references/reports/project.md` or `references/reports/epic.md`. Follow it to verify findings, write the report, run gates, commit after the analyzed corpus, and declare `BLOCKED | NEEDS_FIXES | CLEAN`. Read `references/gate-codes.md` only when enforcing or explaining analysis codes.

Direct `/project-analyze` and `/epic-analyze` names are user-only compatibility shims into this engine. STOP on any loaded-node STOP.
