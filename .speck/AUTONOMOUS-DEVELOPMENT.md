# Speck Autonomous Development

How Speck integrates with **Cursor Background Agents** and **GitHub Copilot Coding Agent**.

## Core Principle

**All runtimes execute the same commands from `.cursor/commands/`.**

The methodology is defined in `AGENTS.md`. Copilot reads it and follows the command flow.

## Workflow Handoffs

The autonomous flow is split across three workflows:

| Workflow | Scope | Trigger |
|----------|-------|---------|
| `speck-orchestrator.yml` | Up to `story-implement` | Push to specs/, manual, issue labeled |
| `speck-validate-pr.yml` | `story-validate` | PR ready for review |
| `speck-retrospective.yml` | `story-retrospective` | PR merged |

```
ORCHESTRATOR                    VALIDATE-PR           RETROSPECTIVE
     │                               │                      │
     ▼                               ▼                      ▼
specify → clarify → plan →      validate              retrospective
tasks → [analyze] → implement        │                      │
     │                               │                      │
     └──────► PR CREATED ───────────►└───► PR MERGED ──────►┘
```

## Rate Limiting

**GitHub Copilot Agent limit: ~2-3 concurrent sessions**

The orchestrator:
1. Counts `speck:in-progress` issues
2. Only assigns if slots available
3. Uses `speck:queued` as waiting queue
4. Assigns oldest first (FIFO)

## Dependency Management

Dependencies declared in `tasks.md` front matter:

```yaml
---
depends_on: [story-001, story-003]
---
```

The orchestrator:
1. Parses dependencies
2. Marks blocked with `speck:blocked`
3. Auto-unblocks when deps merge

## Label States

| Label | Meaning |
|-------|---------|
| `speck:story` | Speck story issue |
| `speck:blocked` | Waiting for dependencies |
| `speck:queued` | Ready, waiting for rate limit slot |
| `speck:in-progress` | Copilot working (max 2-3) |

## Two Runtime Options

### Cursor Background Agent

1. Open story in Cursor
2. Click ☁️ Background Agent
3. Prompt: "Follow AGENTS.md, complete this story"
4. Creates PR when done

### GitHub Copilot Agent

1. Epic has `epic-breakdown.md`
2. Orchestrator creates issues
3. Copilot works (rate limited)
4. Creates PRs
5. Validation workflow validates
6. Retrospective workflow captures learnings

## Setup

1. Enable Copilot Coding Agent in org settings
2. Enable Copilot Code Review for repository
3. Configure `copilot-setup-steps.yml` (E000 epic)

## Files

| File | Purpose |
|------|---------|
| `AGENTS.md` | Speck methodology (single source of truth) |
| `.cursor/commands/story-*.md` | Story commands |
| `.github/copilot-instructions.md` | Points to AGENTS.md |
| `.github/workflows/speck-*.yml` | Automation |
