---
name: story-adjust
description: Compatibility alias for /adjust --level story. Invoke only when the user names /story-adjust.
disable-model-invocation: true
paths:
  - "specs/projects/**/S*/**"
  - "specs/projects/**/stories/**"
  - "specs/projects/**/**/spec.md"
---

# story-adjust compatibility shim

Read and fully execute `.cursor/skills/adjust/SKILL.md` with `--level story` and the user's arguments. The canonical blast-radius check may escalate the level.
