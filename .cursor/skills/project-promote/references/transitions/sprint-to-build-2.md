# project-promote / sprint-to-build (cont. 2)


3. **Update `.speck/project.json`**:
   ```json
   {
     "play_level": "platform",
     "promoted_from": "build",
     "promoted_at": "[ISO date]"
   }
   ```

4. **Next steps**:
   ```
   Platform promotion staged!

   Recommended next steps (in order):
   1. /project-architecture — design the system before planning
   2. /project-plan — create comprehensive PRD and epic breakdown
   3. /project-roadmap — sequence your epics
   ```

---

### Downgrade (Platform/Build → Sprint or Build)

Downgrades reduce artifact requirements without deleting work.

1. Confirm: "Downgrading reduces audit requirements but keeps all existing files. Continue?"
2. Update `.speck/project.json` with new play level
3. Note: "Your existing artifacts are preserved — the audit will simply check fewer requirements."

---
