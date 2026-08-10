---
name: epic-analyze
description: Compatibility alias for /analyze --level epic. Invoke only when the user names /epic-analyze.
disable-model-invocation: true
paths:
  - "specs/projects/**/E*/**"
  - "specs/projects/**/epics/**"
  - "specs/projects/**/**/epic.md"
---

# epic-analyze compatibility shim

Read and fully execute `.cursor/skills/analyze/SKILL.md` with `--level epic` and the user's arguments. Do not implement or restate analysis logic here.
