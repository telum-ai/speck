---
name: project-evidence-contract
description: Creates evidence-contract.md. Use after product-contract.
paths:
  - "specs/projects/**"
---

# project-evidence-contract

Cheap keys: `.speck/project.json` → `play_level`, `project_archetype` (UI vs backend).

1. MUST Read template, then MUST Read `references/spine.md`.
2. MUST Read exactly one of `references/tiers/sprint.md` | `tiers/build.md` | `tiers/platform.md` matching `play_level`.
3. MUST Read exactly one of `references/archetype/ui.md` | `archetype/backend.md` matching archetype (UI-facing vs backend/infra).
4. MUST Read `references/probes.md` (and `probes-2.md` if linked). Write `evidence-contract.md`; SHA-stamp.
