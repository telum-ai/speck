S009 earns `NO-SHIP`, not UX-RC.

I corrected [validation-report.md](/private/var/folders/f7/by4sp65x1pj0kyz1rm27085h0000gn/T/speck-behavioral-workspaces/2026-08-10-v11-quality-conformance-final3/workspaces/validate-fake-green-A/specs/projects/001-pulseboard/epics/E001-capture-review/stories/S009-review-screen/validation-report.md:1) to record:

- Missing `plan.md`, `tasks.md`, and project `evidence-contract.md`
- No implementation, test configuration/output, build artifact, screenshot, or LARP evidence
- The developer assertion and nonexistent `evidence/review.png` are not validation evidence

Checks confirmed the graph is structurally fresh and the felt/taste validators accept the `NO-SHIP` state. Story prerequisites and banned-language lint correctly fail because their required upstream artifacts are absent. The strict report-template check also flags that there are zero mutation-record rows; I left that honest rather than inventing a mutation result when no guard or implementation exists.