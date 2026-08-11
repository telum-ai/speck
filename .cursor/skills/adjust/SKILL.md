---
name: adjust
description: Re-engineers validated work after deliberate change. Use after validation to rebuild and re-prove a redesign or pivot.
---

# adjust

Canonical adjustment engine for intentional changes to validated or shipped work. Defects with no promise change route to `/harden`.

Cheap keys: changed promise ownership and cross-story/cross-epic reach determine `level` before any branch loads.

## Classify blast radius first

Treat an explicit `--level story|epic|project` as a candidate, then verify it against the changed promises:

| Level | Fully contained change |
|-------|------------------------|
| story | One story; no shared seam, sibling story, epic structure, or product promise changes |
| epic | Multiple stories or epic IA/experience-chain/structure; no strategic or product-contract change |
| project | Direction, paid promise, differentiator, project architecture, or cross-epic contract changes |

Escalate until the level contains every affected promise. Never preserve a narrower requested level by leaving downstream truth stale. Record the classification and affected artifacts in the adjustment report.

## Load exactly one branch

Before mutating any artifact, run:

```bash
python3 .speck/scripts/context/speck_context.py adjust --select level=<story|epic|project>
```

This emits exactly one template and one of `references/story.md`, `references/epic.md`, or `references/project.md`; sibling branches are forbidden.

## Common contract

1. Downgrade the affected unit to `NO-SHIP` or its lowest still-proven state before implementation.
2. Re-spec only the deliberate delta; do not silently overwrite validated truth.
3. Conserve every affected promise: remap it, add a new PRM row, or retire it through a DEC.
4. Append a decision entry describing the change and alternatives; a replaced decision uses `Supersedes: DEC-####`.
5. Re-enter the first affected canonical planning slot. Re-plan, regenerate tasks, run story analysis when required, and re-implement every affected story.
6. Run decorrelated `/speck-audit` and the level-specific validation on the changed behavior. A document-only adjustment cannot restore readiness.
7. Write the dated adjustment report, run its template validation and truth stamp as separate direct commands after the last mutation, then regenerate `/project-state`.
8. Restore readiness only from fresh evidence.
