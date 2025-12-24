# GitHub Copilot Instructions

You are working in a **Speck** project. Read `AGENTS.md` for the complete methodology.

## Story Command Flow

Commands are in `.cursor/commands/story-*.md`. Execute in order:

### Discovery & Specification
| Command | Purpose | Output | Required |
|---------|---------|--------|----------|
| `story-specify` | Define requirements, user stories, acceptance criteria | `spec.md` | ✅ |
| `story-clarify` | Resolve ambiguities via Q&A | Updates `spec.md` | ✅ |
| `story-outline` | Map research needs | `outline.md` | When complex tech decisions |
| `story-scan` | Analyze existing code | `codebase-scan-*.md` | When brownfield |

### Planning
| Command | Purpose | Output | Required |
|---------|---------|--------|----------|
| `story-plan` | Technical design, data model, contracts | `plan.md`, `data-model.md` | ✅ |
| `story-ui-spec` | UI specification | `ui-spec.md` | When UI-heavy |

### Execution
| Command | Purpose | Output | Required |
|---------|---------|--------|----------|
| `story-tasks` | Break down into implementation checklist | `tasks.md` | ✅ |
| `story-analyze` | Quality check on artifacts | Analysis report | ⚠️ **REQUIRED** |
| `story-implement` | Write code following tasks.md | Code changes, PR | ✅ |

### Verification & Learning
| Command | Purpose | Output | Required |
|---------|---------|--------|----------|
| `story-validate` | Validate implementation against spec | `validation-report.md` | ✅ |
| `story-retrospective` | Mine commits, capture learnings | `story-retro.md` | ✅ |

## ⚠️ CRITICAL: Task Format

When creating `tasks.md`, use this **EXACT** format (validation will fail otherwise):

```markdown
- [ ] T001 Task description here
- [ ] T002 [P] Parallel task (mark with [P] if different files)
- [ ] T003 Another task
```

**Rules:**
1. Start with `- [ ] ` (dash, space, brackets, space)
2. Task ID: `T` + 3 digits (T001, T002...)
3. IDs must be sequential
4. Optional `[P]` after ID for parallel tasks

**INVALID (will fail):**
- `- T001 Description` ❌
- `[ ] T001 Description` ❌
- `- [] T001 Description` ❌

## Decision Gates for Optional Commands

| Command | Include When |
|---------|--------------|
| `story-outline` | Complex technical decisions, unfamiliar tech stack, need research |
| `story-scan` | Extending existing codebase (brownfield project) |
| `story-ui-spec` | UI-heavy story with multiple components/states/animations |

**Always include `story-analyze`** - it catches issues before implementation.

## Workflow Handoffs

| Workflow | Scope | Trigger |
|----------|-------|---------|
| `speck-orchestrator.yml` | specify → implement | Issue assigned |
| `speck-validate-pr.yml` | validate | PR ready for review |
| `speck-retrospective.yml` | retrospective | PR merged |

## When Assigned a Story Issue

1. Check the issue for current phase and start command
2. Navigate to story directory (create if needed)
3. Execute commands from start command through `story-implement`
4. **ALWAYS run `story-analyze` before `story-implement`**
5. Create PR when implementation complete

## When Performing Code Review

Apply `story-validate` methodology:

1. Load spec.md, plan.md, tasks.md
2. Verify all tasks marked complete
3. Check each requirement (FR-XXX) is implemented
4. Verify acceptance scenarios satisfied
5. Check tests exist (TDD)

## Dependency Handling

If issue is marked `speck:blocked`:
- Check which stories it depends on
- Wait for those to merge before starting
- You'll be notified when unblocked

## Rate Limiting

Max 2-3 concurrent Copilot sessions. Issues queue with `speck:queued` label.
