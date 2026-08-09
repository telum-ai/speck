## MCP Servers (configure in `.cursor/mcp.json` — all optional)

| Server | Purpose |
|--------|---------|
| **Perplexity** | Just-in-time research; embedded in commands as needed |
| **GitHub** | PRs, issues, repos |
| **Context7** | Up-to-date library documentation (always prefer over training data for library specifics) |

See `.cursor/MCP-SETUP.md` for setup.


## Host Capability Matrix

Speck is designed to run seamlessly across all major AI coding environments. Core behavioral expectations, artifact rules, and evidence requirements are identical, while each environment offers different optional accelerators.

| Capability | Claude Code | Cursor | Codex |
|------------|-------------|--------|-------|
| **Core Process Commands** | ✅ Supported (via `.claude/skills/`) | ✅ Supported (via `.cursor/skills/`) | ✅ Supported (via `.codex/skills/`) |
| **Local MCP Config** | `.mcp.json` (root) | `.cursor/mcp.json` | Host-specific config |
| **Automatic Template Linting** | ✅ `PostToolUse` edit hooks | ✅ `afterFileEdit` hooks | Manual or CI-driven checks |
| **Structured Workflows** | ✅ `/loop` maintenance, `/goal` | Manual or scheduled CI | Manual or scheduled CI |
| **Custom Agent Roles** | ✅ `speck-*` subagents checked in | Optional `.cursor/rules/` | Optional skills guidelines |
| **Isolated Implementations** | ✅ `isolation: worktree` (story) + epic-level worktree doctrine | Epic worktree per Concurrent Multi-Epic rules; story impl on branch | Epic worktree per Concurrent Multi-Epic rules; story impl on branch |

### Portability Guarantees & Fallbacks
1. **Shared Validation Engine**: All validation hooks (`validate-template.sh`) route to a unified, host-agnostic bash core inside `.speck/scripts/validation/`.
2. **Subagents Fallback**: Spawning parallel subagents (e.g. `speck-auditor`, `speck-scanner`) is a Claude-specific optimization. When executing on Cursor or Codex, checklists run sequentially in the main conversation.
3. **Local Validation Backstop**: Run validators with `--strict` via pre-commit hooks or manually when your host lacks edit/stop gates.
4. **Agent Skill Tool Fallback**: Some AI host environments restrict or do not support the execution of the `Skill` tool inside highly restricted custom agent roles (such as `@speck-coder` or `@speck-auditor`). If your host environment fails to provide the `Skill` tool to custom roles, any workflow lane requiring skill invocation (e.g., running story/epic specification or validation) MUST be run using a general-purpose, all-tools agent instead. Never fall back to hand-writing or simulating report files; real skill execution recorded in the transcript is required.


## Claude-First Autonomous Workflows (optional accelerators)

Claude Code adds optional accelerators; none change the discipline. Five `speck-*` subagents in `.claude/agents/` (`@speck-scribe`, `@speck-planner`, `@speck-coder`, `@speck-auditor`, `@speck-validator`) can run as an agent team — e.g. one implements while a **separate** one audits (P4 role separation). `/loop <duration>` runs `.claude/loop.md` for scheduled test/drift/scaffold sweeps. `Stop` hooks use command-type lifecycle gates (`.claude/hooks/stop-gate.sh`); story `tasks.md` checks apply only inside story dirs. Speck-managed hook blocks reconcile from `settings.json.example` on `speck upgrade`; drift surfaces as `SETTINGS_DRIFT.P0` at `/recheck`.

### Model tiering doctrine (enforced)

Every `speck-*` agent is assigned a **tier** (its `.cursor/agents/*.md` source `tier:` field), never a model snapshot. Three tiers by role — and each harness gets its **own** model, because Claude Code, Cursor, and Codex have different model vocabularies (Cursor, e.g., has no Sonnet/Haiku):

| Tier | Agents | Claude Code | Cursor | Codex |
|---|---|---|---|---|
| **Frontier** | `speck-architect`, `speck-planner`, `speck-auditor` | `opus` | `claude-opus-4-8-thinking-high` | `gpt-5.6-sol` |
| **Mid** | `speck-coder`, `speck-scribe`, `speck-researcher`, `speck-validator` | `sonnet` | `composer-2.5` | `gpt-5.6-terra` |
| **Mechanical** | `speck-scanner`, `speck-explorer` | `haiku` | `composer-2.5` | `gpt-5.6-luna` |

Frontier = decomposition, design/trade-offs, and the adversarial audit — the few moments that need frontier judgment. Mid = implementation/drafting/research against an explicit plan. Mechanical = pattern extraction and file/grep discovery.

**Never cheap the planner (or the auditor).** Once a frontier planner collapses ambiguity into an explicit spec, cheaper models just follow it — so the worker fleet, not the planner, dominates cost. But a *weaker* planner produces a worse spec, and **a bad spec taxes the entire downstream fleet**: in Cursor's agent-swarm experiment ([cursor.com/blog/agent-swarm-model-economics](https://cursor.com/blog/agent-swarm-model-economics)) the same 100% result cost 8× less with a frontier planner + cheap workers, yet a *slightly* weaker planner made the whole fleet consume more tokens overall. Spend up on the decisions (`speck-planner`, `speck-architect`), keep the audit frontier and **decorrelated from the coder** (`speck-auditor` ≠ the model that implemented), spend down on the labor.

**Generated per-harness, from one source — so it works in concert and separately.** The source of truth is `.cursor/agents/speck-*.md` (the `tier:` field + the role body). `packages/cli/lib/generate-agents.js` derives every `model` value and stamps the three runtime files: `.claude/agents/*.md` (bare alias), `.cursor/agents/*.md` (Cursor slug), `.codex/agents/*.toml` (GPT slug + `developer_instructions`). This replaces the old symlink layout, which forced one markdown-YAML file — and one model value — onto three grammars and left `.codex` non-functional (Codex reads TOML, not markdown). **Edit the source `tier`/body and run `npm run gen-agents`; never hand-edit a generated file.** Reasoning depth (effort/thinking) is a separate dial — the Cursor/Codex maps carry a default effort; override at invocation.

**Enforcement.** `packages/cli/lib/agent-model-tiers.test.js` (in `npm test`) fails if any `speck-*` agent's source tier drifts from its role, an agent is added without a tier, or a generated harness file is out of sync with source (hand-edited, or source changed without `npm run gen-agents`). The doctrine is a gate, not a suggestion.
