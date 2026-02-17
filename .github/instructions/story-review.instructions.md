# Story Code Review Instructions

When reviewing code in a Speck story PR, follow the validation methodology from `.cursor/skills/story-validate/SKILL.md`.

## Validation Checklist

### 1. Task Completion
- Find tasks.md in the story directory
- Verify all tasks are marked `[x]` complete
- Flag incomplete tasks

### 2. Requirements Traceability
- Find spec.md in the story directory
- For each FR-XXX requirement, verify implementation exists
- Check acceptance scenarios are satisfied

### 3. Technical Plan Adherence
- Find plan.md in the story directory
- Verify implementation follows the technical approach
- Check for undocumented deviations

### 4. Code Quality
- Tests exist for all requirements (TDD)
- No arbitrary styling (use design system)
- Idempotent migrations (IF EXISTS patterns)
- Conventional Commits with learning tags

### 5. Simplicity Check
- Default to <100 lines per task
- No premature abstractions
- Evidence required for complexity

## Review Output

For each issue found, reference:
- The specific requirement (FR-XXX) or task (TXXX)
- The file and line with the issue
- The expected behavior from spec.md

