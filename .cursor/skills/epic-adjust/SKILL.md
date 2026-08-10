---
name: epic-adjust
description: Compatibility alias for /adjust --level epic. Invoke only when the user names /epic-adjust.
disable-model-invocation: true
paths:
  - "specs/projects/**/E*/**"
  - "specs/projects/**/epics/**"
  - "specs/projects/**/**/epic.md"
---

# epic-adjust compatibility shim

Read and fully execute `.cursor/skills/adjust/SKILL.md` with `--level epic` and the user's arguments. The canonical blast-radius check may escalate the level.
