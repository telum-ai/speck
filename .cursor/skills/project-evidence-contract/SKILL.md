---
name: project-evidence-contract
description: Defines product proof and readiness gates. Use at Build/Platform after product-contract and before project-plan.
paths:
  - "specs/projects/**"
---

# project-evidence-contract

Cheap keys: `.speck/project.json` → `play_level`, `project_archetype` (UI vs backend).

1. Classify `build|platform` and `ui|backend` before loading branch context. Sprint stops here; promote before authoring this contract.
2. Before the first mutation, run the matching profile:
   `python3 .speck/scripts/context/speck_context.py project-evidence-<ui|backend>-<build|platform>`.
3. Require exit 0 and `SPECK_CONTEXT_RECEIPT`; do not separately load sibling tier/archetype branches.
4. Execute loaded context. Write only `evidence-contract.md`; stamp, then validate as the spine requires. State and graph refresh happen later.
