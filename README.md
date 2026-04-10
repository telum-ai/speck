# Speck 🥓

**Spec-driven development methodology** for building digital products through project → epic → story levels.

## 🚀 Quick Start

### In Cursor IDE or Claude Code

Just type `/speck` followed by what you want to build:

```
/speck Build a social networking app
/speck Add user authentication
/speck Import my existing codebase at ~/projects/myapp
/speck Continue working on my project
```

Speck will automatically:
- Detect the appropriate level (project/epic/story)
- Guide you through the process
- Create the right specifications

**That's it!** No need to memorize commands—just describe what you want to accomplish.

## 📦 Installation & Setup

### First Time Setup

If you're starting a new project with Speck:

```bash
# Initialize Speck in your project
npx github:telum-ai/speck init
```

This sets up:
- Skill files (`.cursor/skills/` and `.claude/skills/`)
- Templates (`.speck/templates/`)
- Validation hooks (`.cursor/hooks/`)
- Update workflows (`.github/workflows/`)

Runtime source of truth:
- Canonical runtime source is `.cursor/skills/` + `.cursor/agents/`
- `.claude/skills/` + `.claude/agents/` are symlinked from `.cursor/` for Claude Code compatibility
- Sync manually with: `bash .speck/scripts/bash/sync-claude-runtime.sh` (manages symlinks)

Instruction source of truth:
- `AGENTS.md` is the single instruction source for both Cursor and Claude Code
- We intentionally avoid `CLAUDE.md` to reduce instruction drift risk

### Claude Code advanced setup (recommended)

To leverage Claude-native features beyond Cursor:
- Subagents via `.claude/agents/` (symlinked from `.cursor/agents/`)
- Agent teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- Claude settings baseline at `.claude/settings.json.example`
- Claude hooks/settings scopes (project/user/local) via `.claude/settings*.json`

Start from:
```bash
cp .claude/settings.json.example .claude/settings.json
```

### Recommended: MCP Setup

For the best experience, configure MCP servers for research and documentation:

1. See `.cursor/MCP-SETUP.md` for setup instructions
2. Recommended servers:
   - **Perplexity** - Research and web search
   - **GitHub** - PRs, issues, code search
   - **Context7** - Up-to-date library docs

> 💡 Speck works without MCP servers, but they're highly recommended for research capabilities.

## 🔄 Keeping Speck Updated

### Automatic Updates (Recommended)

Speck includes a workflow that **automatically checks for updates daily** and creates PRs:

- ✅ **Works out of the box** for public Speck repos
- ✅ **Smart merging** preserves your customizations
- 🔒 For private repos: Add `SPECK_GITHUB_TOKEN` secret

### Manual Updates

```bash
# Check for available updates
npx github:telum-ai/speck check

# Upgrade to latest version
npx github:telum-ai/speck upgrade

# Preview changes without applying
npx github:telum-ai/speck upgrade --dry-run

# Upgrade to specific version
npx github:telum-ai/speck upgrade v2.3.0
```

### What Gets Updated

Updates preserve your customizations:
- ✅ Your `AGENTS.md` content outside `SPECK:START..END` tags
- ✅ Your `.gitignore` entries
- ✅ Your custom hooks and MCP config
- ✅ Your `README.md` (if customized)
- ✅ Your `copilot-setup-steps.yml` (if customized)

## 📁 Project Structure

Your Speck project artifacts live under:
```
specs/projects/[project-id]/
├── project.md          # Project vision & goals
├── PRD.md              # Product requirements
├── learnings-register.md # Project-local learnings and validated gotchas
├── architecture.md     # System design
└── epics/              # Epic specifications
    └── stories/        # Story specifications
```

## 📚 Documentation

**Full documentation**: See `.speck/README.md` for:
- Complete skill reference
- Workflow examples
- Best practices
- Troubleshooting
- Advanced usage

**Quick reference**: Just use `/speck` and follow the prompts!

## 🛠️ Development

For contributing to Speck itself (CLI, sync system, versioning, releases), see **[DEVELOPMENT.md](DEVELOPMENT.md)**.

## 🤝 Contributing Methodology Insights

After running retrospective commands (`/story-retrospective`, `/epic-retrospective`, `/project-retrospective`), you can opt-in to share methodology insights with the Speck team. Only process improvements are shared—no project-specific data.

---

**Need help?** Just type `/speck` and describe what you want to build. Speck will guide you through the rest!
