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

## When Assigned a Story Issue

1. Check the issue for current phase and start command
2. Navigate to story directory (create if needed)
3. Execute commands from start command through `story-implement`
4. **ALWAYS run `story-analyze` before `story-implement`**
5. **ALWAYS follow templates exactly** - see `.speck/templates/story/`
6. Create PR when implementation complete

## When Performing Code Review

Apply `story-validate` methodology from `.cursor/commands/story-validate.md`.

## Dependency Handling

If issue is marked `speck:blocked`:
- Wait for dependencies to merge before starting
- You'll be notified when unblocked

## Workflow Handoffs

| Workflow | Scope | Trigger |
|----------|-------|---------|
| `speck-orchestrator.yml` | specify → implement | Issue assigned |
| `speck-validate-pr.yml` | validate | PR ready for review |
| `speck-retrospective.yml` | retrospective | PR merged |
