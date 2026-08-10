# story-clarify / output

Questions Asked: [X] of 5
   Spec Updated: [Path]

   Coverage Summary:
   - Functional Scope: [Clear/Resolved/Deferred]
   - Technical Constraints: [Clear/Resolved/Deferred]
   - Data Requirements: [Clear/Resolved/Deferred]
   - Integration Points: [Clear/Resolved/Deferred]
   - UI/UX Details: [Clear/Resolved/Deferred]
   ```

   Then immediately run an **Optional Step Evaluation** based on the *updated* `spec.md` (clarifications often reveal new signals about complexity and UI):

   | Step | 🔴 Required when |  Recommended when | ⬜ Skip when |
   |------|-----------------|---------------------|------------|
   | `/speck-skeptical-review` | Unfamiliar technology; TBD sections remain; multiple competing implementation approaches | Minor unknowns after clarification | Path clear, follows established patterns |
   | `/speck-scan --level story` | Story extends or modifies existing code; brownfield context confirmed | Story touches existing functionality | Fully greenfield |
   | `/story-ui-spec` | Any mention of UI, screens, forms, components, layout, UX | Minor UI elements alongside backend work | Pure backend / API / CLI |

   Output:
   ```
   ## Optional Step Evaluation (post-clarification)

   | Step | Recommendation | Evidence from spec.md |
   |------|---------------|----------------------|
   | /speck-skeptical-review | ⬜ /  / 🔴 | "[observation]" |
   | /speck-scan --level story    | ⬜ /  / 🔴 | "[observation]" |
   | /story-ui-spec | ⬜ / 🔴       | "[observation]" |

   Next applicable slot from the marked canonical Story flow in root AGENTS.md:
   → [first incomplete Required/Recommended slot]

   Shall I proceed with [first recommended step]?
   ```

Behavior rules:
- If no meaningful ambiguities found (or all potential questions would be low-impact), respond: "No critical ambiguities detected worth formal clarification." and suggest proceeding.
- If spec file missing, instruct user to run `/story-specify` first (do not create a new spec here).
- Never exceed 5 total asked questions (clarification retries for a single question do not count as new questions).
- Avoid speculative tech stack questions unless the absence blocks functional clarity.
- Respect user early termination signals ("stop", "done", "proceed").
 - If no questions asked due to full coverage, output a compact coverage summary (all categories Clear) then suggest advancing.
 - If quota reached with unresolved high-impact categories remaining, explicitly flag them under Deferred with rationale.

Context for prioritization: $ARGUMENTS
