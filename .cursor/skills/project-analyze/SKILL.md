---
name: project-analyze
description: Compatibility alias for /analyze --level project. Invoke only when the user names /project-analyze.
disable-model-invocation: true
paths:
  - "specs/projects/**"
---

# project-analyze compatibility shim

Read and fully execute `.cursor/skills/analyze/SKILL.md` with `--level project` and the user's arguments. Do not implement or restate analysis logic here.
