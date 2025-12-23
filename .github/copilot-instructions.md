# GitHub Copilot Instructions

You are working in a **Speck** project.

## Primary Reference

**Read `AGENTS.md` in the repository root.** It contains the complete Speck methodology.

## Story Command Flow

Commands are in `.cursor/commands/story-*.md`. Execute in order:

### Discovery & Specification
| Command | Purpose | Output |
|---------|---------|--------|
| `story-specify` | Define requirements, user stories, acceptance criteria | `spec.md` |
| `story-clarify` | Resolve ambiguities via Q&A | Updates `spec.md` |
| `story-outline` | Map research needs (optional) | `outline.md` |
| `story-scan` | Analyze existing code (brownfield) | `codebase-scan-*.md` |

### Planning
| Command | Purpose | Output |
|---------|---------|--------|
| `story-plan` | Technical design, data model, contracts | `plan.md`, `data-model.md`, `contracts/` |
| `story-ui-spec` | UI specification (optional) | `ui-spec.md` |

### Execution
| Command | Purpose | Output |
|---------|---------|--------|
| `story-tasks` | Break down into implementation checklist | `tasks.md` |
| `story-analyze` | Quality check on artifacts (optional) | Analysis report |
| `story-implement` | Write code following tasks.md | Code changes, PR |

### Verification & Learning
| Command | Purpose | Output |
|---------|---------|--------|
| `story-validate` | Validate implementation against spec | `validation-report.md` |
| `story-retrospective` | Mine commits, capture learnings | `story-retro.md` |

### Utility
| Command | Purpose | Output |
|---------|---------|--------|
| `story-extract` | Extract story from existing code | `spec.md` from code |

## Workflow Handoffs

| Workflow | Scope | Trigger |
|----------|-------|---------|
| `speck-orchestrator.yml` | specify → implement (creates PR) | Issue assigned |
| `speck-validate-pr.yml` | validate | PR ready for review |
| `speck-retrospective.yml` | retrospective | PR merged |

## When Assigned a Story Issue

1. Read `AGENTS.md`
2. Navigate to the story path
3. Determine current phase (check which files exist)
4. Execute commands up through `story-implement`
5. Create PR when implementation complete

## When Performing Code Review

Apply `story-validate` methodology from `.cursor/commands/story-validate.md`:

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
