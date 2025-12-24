# Story: <!-- STORY_TITLE -->

## Summary
<!-- Brief description of what this PR implements -->

## Story Details
- **Epic**: <!-- EPIC_ID -->
- **Story**: <!-- STORY_ID -->
- **Spec**: <!-- Link to spec.md or summary of requirements -->

## Commands Executed
<!-- Check off the commands that were completed -->

### Discovery & Specification
- [ ] `story-specify` → Created `spec.md`
- [ ] `story-clarify` → Resolved ambiguities
- [ ] `story-outline` → *(optional)* Research needs mapping
- [ ] `story-scan` → *(optional, brownfield)* Existing code analysis

### Planning
- [ ] `story-plan` → Created `plan.md`, `data-model.md`, `contracts/`
- [ ] `story-ui-spec` → *(optional, UI-heavy)* Detailed UI specs

### Execution
- [ ] `story-tasks` → Created `tasks.md`
- [ ] `story-analyze` → ⚠️ **REQUIRED** Quality check passed
- [ ] `story-implement` → Code changes complete

## Implementation Checklist
<!-- From tasks.md - list key tasks completed -->
- [ ] Task 1: ...
- [ ] Task 2: ...

## Testing
<!-- Describe testing approach -->
- [ ] Tests written (TDD)
- [ ] Tests passing
- [ ] Coverage target met

## Requirements Traceability
<!-- Map FRs to implementation -->
| Requirement | Status | Notes |
|-------------|--------|-------|
| FR-001 | ✅ | Implemented in `file.ts` |
| FR-002 | ✅ | ... |

## Design Decisions
<!-- Document any significant decisions made during implementation -->

## Known Issues / Technical Debt
<!-- Any items deferred or debt created -->

## Validation Notes
<!-- For the reviewer - key areas to check -->
- [ ] All acceptance criteria from `spec.md` met
- [ ] Code follows existing patterns
- [ ] No regressions introduced

---
*This PR was created following the [Speck methodology](AGENTS.md).*
*Validation will be performed by `speck-validate-pr.yml` when marked ready for review.*
