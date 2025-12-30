# Story: <!-- STORY_TITLE -->

<!-- Brief technical description of what this PR implements -->

## Story Details

| Field | Value |
|-------|-------|
| **Epic** | <!-- EPIC_ID - EPIC_NAME --> |
| **Story** | <!-- STORY_ID --> |
| **Story Path** | <!-- `specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/stories/[STORY_ID]-[story-name]/` --> |
| **Fixes** | <!-- #ISSUE_NUMBER --> |

---

## Implementation Summary

<!-- 
Technical overview of what was built. Include:
- Key components/modules created
- Libraries/dependencies added
- Architectural decisions made
-->

### Key Changes

<!-- List the main implementation points -->
- **Change 1**: Description
- **Change 2**: Description

### Code Example

<!-- Show a representative code snippet if helpful -->
```typescript
// Example implementation pattern used
```

---

## Files Changed

<!-- Group files by purpose -->

| Category | Files |
|----------|-------|
| **Core Implementation** | `path/to/file.ts`, `path/to/other.ts` |
| **Configuration** | `config.json`, `.env.example` |
| **Tests** | `__tests__/file.spec.ts` |
| **Documentation** | `README.md`, `SETUP.md` |

---

## Commands Executed

<!-- Check off the commands that were completed -->

### Discovery & Planning
- [ ] `story-specify` → Created `spec.md`
- [ ] `story-clarify` → Resolved ambiguities
- [ ] `story-outline` → *(optional)* Research mapping
- [ ] `story-scan` → *(optional)* Codebase analysis
- [ ] `story-plan` → Created `plan.md`, `data-model.md`
- [ ] `story-ui-spec` → *(optional, UI-heavy)* Created `ui-spec.md`

### Execution
- [ ] `story-tasks` → Created `tasks.md`
- [ ] `story-analyze` → ⚠️ **REQUIRED** Quality check
- [ ] `story-implement` → Code complete

---

## Requirements Coverage

<!-- Map each FR to implementation status -->

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| FR-001: [Description] | ✅ | `file.ts:L45-60` |
| FR-002: [Description] | ✅ | `other.ts` |
| FR-003: [Description] | ⚠️ Partial | See Known Issues |

---

## Performance

<!-- If story has performance targets from spec.md -->

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Response time | <200ms | 145ms | ✅ |
| Test execution | <30s | 5.4s | ✅ |

---

## Manual Tasks Required

<!-- 
IMPORTANT: Tasks that require human action - external services, credentials, etc.
The reviewer or user must complete these before the feature works fully.
-->

> [!IMPORTANT]
> The following tasks require manual action:

- [ ] **Task 1**: Description (est. X min)
  - Step-by-step instructions
- [ ] **Task 2**: Description (est. X min)
  - Step-by-step instructions

<!-- If no manual tasks: -->
<!-- No manual tasks required - implementation is self-contained. -->

---

## Quickstart Verification

<!-- From quickstart.md - scenarios to verify the implementation works -->

### Scenario 1: [Name]
```bash
# Steps to verify
```
Expected: [outcome]

### Scenario 2: [Name]
```bash
# Steps to verify  
```
Expected: [outcome]

---

## Dependencies

<!-- What this story requires and what it enables -->

| Direction | Story | Status |
|-----------|-------|--------|
| **Requires** | S001-setup | ✅ Merged |
| **Requires** | S002-config | ✅ Merged |
| **Blocks** | S015-feature | Waiting on this PR |

---

## Security Considerations

<!-- For stories with security implications -->

- [ ] No secrets in code (use env vars)
- [ ] Credentials via secure channel only
- [ ] RLS/permissions properly configured
- [ ] No sensitive data logged

<!-- Or: No security implications for this story. -->

---

## Known Issues / Technical Debt

<!-- Any items deferred, workarounds used, or debt created -->

| Issue | Impact | Resolution |
|-------|--------|------------|
| Placeholder test script | CI passes but no real tests | S015 will implement |
| Manual config required | Feature not active until setup | Documented in SETUP.md |

<!-- Or: No known issues. -->

---

## Warnings

<!-- Any errors, blocked connections, or issues encountered during implementation -->

> [!WARNING]
> <!-- e.g., Firewall blocked connections, external service issues, etc. -->

---

## Validation Notes

<!-- For the reviewer - key areas to check -->

- [ ] All acceptance criteria from `spec.md` met
- [ ] Code follows existing codebase patterns
- [ ] Tests cover happy path and edge cases
- [ ] Documentation updated
- [ ] No regressions introduced

---

*Created following the [Speck methodology](AGENTS.md). Story is complete when `validation-report.md` shows PASS.*
