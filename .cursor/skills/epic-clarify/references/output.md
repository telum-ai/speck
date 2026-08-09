# epic-clarify / output

Sections Updated: [List]
   ```

   Then immediately run an **Optional Step Evaluation** based on the *updated* `epic.md` (clarifications may have revealed new signals):

   Evaluate using these criteria (same as epic-specify, now with more context):

   | Step | 🔴 Required when |  Recommended when | ⬜ Skip when |
   |------|-----------------|---------------------|------------|
   | `/epic-constitution` | Regulated domain; defines API boundary; multi-team coordination | Domain-specific rules not in project constitution | Simple feature, no compliance concerns |
   | `/epic-architecture` | Touches 2+ services; new infra; explicit perf targets; complex new integrations | Modifies existing API contracts; new architectural patterns | Simple CRUD; single-service; clear path |
   | `/epic-journey` + `/epic-wireframes` | Any mention of UI, screens, forms, user flows, front-end | Mixes backend and light UI | Backend-only / API-only / CLI / infra |
   | `/epic-outline` | Unfamiliar tech; TBD sections; competing technical approaches | Minor unknowns | Clear path, established patterns |

   Output:
   ```
   ## Optional Step Evaluation (post-clarification)

   | Step | Recommendation | Evidence |
   |------|---------------|----------|
   | /epic-constitution         | ⬜ /  / 🔴 | "[observation]" |
   | /epic-architecture         | ⬜ /  / 🔴 | "[observation]" |
   | /epic-journey + /wireframes| ⬜ / 🔴       | "[observation]" |
   | /epic-outline              | ⬜ /        | "[observation]" |

   Recommended path to /epic-plan:
   → [only Required/Recommended steps in flow order] → /epic-plan

   Shall I proceed with [first recommended step]?
   ```

Error conditions:
- No epic.md → Instruct to run /epic-specify
- Already has tech spec → Note that clarifications may affect design
