# CLAUDE.md

This repository is Speck 🥓.

Use these files as the primary operating instructions:

1. `AGENTS.md` — full methodology, workflows, guardrails, and runtime guidance
2. `.claude/commands/*.md` — slash-command instructions (Claude Code)
3. `.speck/README.md` — deep methodology reference

## Command entry point

Start with:

```text
/speck <what you want to build>
```

The router command (`.claude/commands/speck.md`) handles project/epic/story routing.

## Compatibility note

Speck keeps command docs in both locations:
- `.cursor/commands/` (Cursor)
- `.claude/commands/` (Claude Code)

They are intended to remain functionally equivalent.
