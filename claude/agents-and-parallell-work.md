> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Run agents in parallel

> Compare the ways Claude Code can take on multiple tasks at once: subagents, agent view, agent teams, and isolated worktree sessions.

[Subagents](/en/sub-agents), [agent view](/en/agent-view), [agent teams](/en/agent-teams), and [worktrees](/en/worktrees) each parallelize work in a different way. The right one depends on whether you want to stay in each conversation yourself, hand tasks off and check back later, or have Claude coordinate a group of workers for you.

| Approach                       | What it gives you                                                                                                                        | Use it when                                                                                                                 |
| :----------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------- |
| [Subagents](/en/sub-agents)    | Delegated workers inside one session that do a side task in their own context and return a summary                                       | A side task would flood your main conversation with search results, logs, or file contents you won't reference again        |
| [Agent view](/en/agent-view)   | One screen to dispatch and monitor sessions running in the background, opened with `claude agents`. Research preview                     | You have several independent tasks and want to hand them off, check status at a glance, and step in only when one needs you |
| [Agent teams](/en/agent-teams) | Multiple coordinated sessions with a shared task list and inter-agent messaging, managed by a lead. Experimental and disabled by default | You want Claude to split a project into pieces, assign them, and keep the workers in sync                                   |
| [Worktrees](/en/worktrees)     | Separate git checkouts so parallel sessions never touch each other's files                                                               | You're running several sessions yourself, or your subagents edit overlapping files                                          |
| [`/batch`](/en/commands)       | A planned split of one large change into 5 to 30 worktree-isolated subagents that each open a pull request                               | A repo-wide migration or mechanical refactor you can describe in one instruction                                            |

In every approach the workers are Claude sessions. To involve a different tool, expose it to Claude as an [MCP server](/en/mcp).

You can combine these approaches. Agent view automatically moves each dispatched session into its own worktree when it needs to edit files, and a session you're working in can spawn subagents that each get their own worktree.

<Note>
  Running several sessions or subagents at once multiplies token usage. See [Costs](/en/costs) for usage and rate-limit details.
</Note>

## Choose an approach

The right approach depends on who coordinates the work, whether the workers need to communicate, and whether they edit the same files:

* **Who coordinates the work?** If you want Claude to delegate and collect results inside one conversation, use [subagents](/en/sub-agents). If you're handing off independent tasks and checking back on them, use [agent view](/en/agent-view). If you want Claude to plan, assign, and supervise a group of workers, use [agent teams](/en/agent-teams), which are experimental and disabled by default.
* **Do the workers need to talk to each other?** Subagents report results back to the conversation that spawned them, and agent view sessions report only to you. Teammates in an agent team share a task list and message each other directly.
* **Do the tasks touch the same files?** Isolate the work with [worktrees](/en/worktrees). Subagents and sessions you run yourself can each use a separate worktree. Agent teams don't isolate teammates in worktrees, so [partition the work](/en/agent-teams#avoid-file-conflicts) so each teammate owns a different set of files.

## Check on running work

The command for checking on running work depends on which approach you used:

* For background sessions, `claude agents` opens [agent view](/en/agent-view): one screen showing every session, its state, and which ones need your input.
* For subagents in the current session, `/agents` opens a panel with a **Running** tab listing live subagents and a **Library** tab where you [create and edit custom subagents](/en/sub-agents#use-the-%2Fagents-command). Despite the similar name, this is separate from `claude agents`.
* For anything running in the background of the current session, `/tasks` lists each item and lets you check on, attach to, or stop it.

For a desktop view of all your sessions, see [parallel sessions in the desktop app](/en/desktop#work-in-parallel-with-sessions).

## Learn more

Each guide below covers setup and configuration for one approach:

* [Create custom subagents](/en/sub-agents): define reusable specialists and control which tools they can use.
* [Manage agents with agent view](/en/agent-view): dispatch sessions, watch their state, and attach when one needs you.
* [Orchestrate agent teams](/en/agent-teams): set up a lead and teammates, assign tasks, and review their work.
* [Run parallel sessions with worktrees](/en/worktrees): start Claude in an isolated checkout, control what gets copied in, and clean up afterward.

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Create custom subagents

> Create and use specialized AI subagents in Claude Code for task-specific workflows and improved context management.

Subagents are specialized AI assistants that handle specific types of tasks. Use one when a side task would flood your main conversation with search results, logs, or file contents you won't reference again: the subagent does that work in its own context and returns only the summary. Define a custom subagent when you keep spawning the same kind of worker with the same instructions.

Each subagent runs in its own context window with a custom system prompt, specific tool access, and independent permissions. When Claude encounters a task that matches a subagent's description, it delegates to that subagent, which works independently and returns results. To see the context savings in practice, the [context window visualization](/en/context-window) walks through a session where a subagent handles research in its own separate window.

<Note>
  Subagents work within a single session. To run many independent sessions in parallel and monitor them from one place, see [background agents](/en/agent-view). For sessions that communicate with each other, see [agent teams](/en/agent-teams).
</Note>

Subagents help you:

* **Preserve context** by keeping exploration and implementation out of your main conversation
* **Enforce constraints** by limiting which tools a subagent can use
* **Reuse configurations** across projects with user-level subagents
* **Specialize behavior** with focused system prompts for specific domains
* **Control costs** by routing tasks to faster, cheaper models like Haiku

Claude uses each subagent's description to decide when to delegate tasks. When you create a subagent, write a clear description so Claude knows when to use it.

Claude Code includes several built-in subagents like **Explore**, **Plan**, and **general-purpose**. You can also create custom subagents to handle specific tasks. This page covers:

* [Built-in subagents](#built-in-subagents)
* [How to create your own](#quickstart-create-your-first-subagent)
* [Full configuration options](#configure-subagents)
* [Patterns for working with subagents](#work-with-subagents)
* [Forked subagents](#fork-the-current-conversation)
* [Example subagents](#example-subagents)

## Built-in subagents

Claude Code includes built-in subagents that Claude automatically uses when appropriate. Each inherits the parent conversation's permissions with additional tool restrictions.

Explore and Plan skip your CLAUDE.md files and the parent session's git status to keep research fast and inexpensive. Every other built-in and [custom subagent](#configure-subagents) loads both. For the full breakdown of what reaches a subagent, see [what loads at startup](#what-loads-at-startup).

<Tabs>
  <Tab title="Explore">
    A fast, read-only agent optimized for searching and analyzing codebases.

    * **Model**: Haiku (fast, low-latency)
    * **Tools**: Read-only tools (denied access to Write and Edit tools)
    * **Purpose**: File discovery, code search, codebase exploration

    Claude delegates to Explore when it needs to search or understand a codebase without making changes. This keeps exploration results out of your main conversation context.

    When invoking Explore, Claude specifies a thoroughness level: **quick** for targeted lookups, **medium** for balanced exploration, or **very thorough** for comprehensive analysis.
  </Tab>

  <Tab title="Plan">
    A research agent used during [plan mode](/en/permission-modes#analyze-before-you-edit-with-plan-mode) to gather context before presenting a plan.

    * **Model**: Inherits from main conversation
    * **Tools**: Read-only tools (denied access to Write and Edit tools)
    * **Purpose**: Codebase research for planning

    When you're in plan mode and Claude needs to understand your codebase, it delegates research to the Plan subagent. This prevents infinite nesting (subagents cannot spawn other subagents) while still gathering necessary context.
  </Tab>

  <Tab title="General-purpose">
    A capable agent for complex, multi-step tasks that require both exploration and action.

    * **Model**: Inherits from main conversation
    * **Tools**: All tools
    * **Purpose**: Complex research, multi-step operations, code modifications

    Claude delegates to general-purpose when the task requires both exploration and modification, complex reasoning to interpret results, or multiple dependent steps.
  </Tab>

  <Tab title="Other">
    Claude Code includes additional helper agents for specific tasks. These are typically invoked automatically, so you don't need to use them directly.

    | Agent             | Model  | When Claude uses it                                      |
    | :---------------- | :----- | :------------------------------------------------------- |
    | statusline-setup  | Sonnet | When you run `/statusline` to configure your status line |
    | claude-code-guide | Haiku  | When you ask questions about Claude Code features        |
  </Tab>
</Tabs>

Beyond these built-in subagents, you can create your own with custom prompts, tool restrictions, permission modes, hooks, and skills. The following sections show how to get started and customize subagents.

## Quickstart: create your first subagent

Subagents are defined in Markdown files with YAML frontmatter. You can [create them manually](#write-subagent-files) or use the `/agents` command.

This walkthrough guides you through creating a user-level subagent with the `/agents` command. The subagent reviews code and suggests improvements for the codebase.

<Steps>
  <Step title="Open the subagents interface">
    In Claude Code, run:

    ```text theme={null}
    /agents
    ```
  </Step>

  <Step title="Choose a location">
    Switch to the **Library** tab, select **Create new agent**, then choose **Personal**. This saves the subagent to `~/.claude/agents/` so it's available in all your projects.
  </Step>

  <Step title="Generate with Claude">
    Select **Generate with Claude**. When prompted, describe the subagent:

    ```text theme={null}
    A code improvement agent that scans files and suggests improvements
    for readability, performance, and best practices. It should explain
    each issue, show the current code, and provide an improved version.
    ```

    Claude generates the identifier, description, and system prompt for you.
  </Step>

  <Step title="Select tools">
    For a read-only reviewer, deselect everything except **Read-only tools**. If you keep all tools selected, the subagent inherits all tools available to the main conversation.
  </Step>

  <Step title="Select model">
    Choose which model the subagent uses. For this example agent, select **Sonnet**, which balances capability and speed for analyzing code patterns.
  </Step>

  <Step title="Choose a color">
    Pick a background color for the subagent. This helps you identify which subagent is running in the UI.
  </Step>

  <Step title="Configure memory">
    Select **User scope** to give the subagent a [persistent memory directory](#enable-persistent-memory) at `~/.claude/agent-memory/`. The subagent uses this to accumulate insights across conversations, such as codebase patterns and recurring issues. Select **None** if you don't want the subagent to persist learnings.
  </Step>

  <Step title="Save and try it out">
    Review the configuration summary. Press `s` or `Enter` to save, or press `e` to save and edit the file in your editor. The subagent is available immediately. Try it:

    ```text theme={null}
    Use the code-improver agent to suggest improvements in this project
    ```

    Claude delegates to your new subagent, which scans the codebase and returns improvement suggestions.
  </Step>
</Steps>

You now have a subagent you can use in any project on your machine to analyze codebases and suggest improvements.

You can also create subagents manually as Markdown files, define them via CLI flags, or distribute them through plugins. The following sections cover all configuration options.

## Configure subagents

### Use the /agents command

The `/agents` command opens a tabbed interface for managing subagents. The **Running** tab shows live subagents and lets you open or stop them. The **Library** tab lets you:

* View all available subagents (built-in, user, project, and plugin)
* Create new subagents with guided setup or Claude generation
* Edit existing subagent configuration and tool access
* Delete custom subagents
* See which subagents are active when duplicates exist

This is the recommended way to create and manage subagents. For manual creation or automation, you can also add subagent files directly.

### Choose the subagent scope

Subagents are Markdown files with YAML frontmatter. Store them in different locations depending on scope. When multiple subagents share the same name, the higher-priority location wins.

| Location                     | Scope                   | Priority    | How to create                                 |
| :--------------------------- | :---------------------- | :---------- | :-------------------------------------------- |
| Managed settings             | Organization-wide       | 1 (highest) | Deployed via [managed settings](/en/settings) |
| `--agents` CLI flag          | Current session         | 2           | Pass JSON when launching Claude Code          |
| `.claude/agents/`            | Current project         | 3           | Interactive or manual                         |
| `~/.claude/agents/`          | All your projects       | 4           | Interactive or manual                         |
| Plugin's `agents/` directory | Where plugin is enabled | 5 (lowest)  | Installed with [plugins](/en/plugins)         |

**Project subagents** (`.claude/agents/`) are ideal for subagents specific to a codebase. Check them into version control so your team can use and improve them collaboratively.

Project subagents are discovered by walking up from the current working directory. Directories added with `--add-dir` [grant file access only](/en/permissions#additional-directories-grant-file-access-not-configuration) and are not scanned for subagents. To share subagents across projects, use `~/.claude/agents/` or a [plugin](/en/plugins).

**User subagents** (`~/.claude/agents/`) are personal subagents available in all your projects.

Claude Code scans `.claude/agents/` and `~/.claude/agents/` recursively, so you can organize definitions into subfolders such as `agents/review/` or `agents/research/`. The subdirectory path does not affect how a subagent is identified or invoked, because identity comes only from the `name` frontmatter field. Keep `name` values unique across the whole tree: if two files within one scope declare the same name, Claude Code keeps one and discards the other without warning.

Plugin `agents/` directories are also scanned recursively. Unlike project and user scopes, a subfolder inside a plugin's `agents/` directory becomes part of the [scoped identifier](#invoke-subagents-explicitly): a file at `agents/review/security.md` in plugin `my-plugin` registers as `my-plugin:review:security`.

**CLI-defined subagents** are passed as JSON when launching Claude Code. They exist only for that session and aren't saved to disk, making them useful for quick testing or automation scripts. You can define multiple subagents in a single `--agents` call:

<Tabs>
  <Tab title="macOS, Linux, WSL">
    ```bash theme={null}
    claude --agents '{
      "code-reviewer": {
        "description": "Expert code reviewer. Use proactively after code changes.",
        "prompt": "You are a senior code reviewer. Focus on code quality, security, and best practices.",
        "tools": ["Read", "Grep", "Glob", "Bash"],
        "model": "sonnet"
      },
      "debugger": {
        "description": "Debugging specialist for errors and test failures.",
        "prompt": "You are an expert debugger. Analyze errors, identify root causes, and provide fixes."
      }
    }'
    ```
  </Tab>

  <Tab title="Windows PowerShell">
    ```powershell theme={null}
    claude --agents @'
    {
      "code-reviewer": {
        "description": "Expert code reviewer. Use proactively after code changes.",
        "prompt": "You are a senior code reviewer. Focus on code quality, security, and best practices.",
        "tools": ["Read", "Grep", "Glob", "Bash"],
        "model": "sonnet"
      },
      "debugger": {
        "description": "Debugging specialist for errors and test failures.",
        "prompt": "You are an expert debugger. Analyze errors, identify root causes, and provide fixes."
      }
    }
    '@
    ```
  </Tab>
</Tabs>

The `--agents` flag accepts JSON with the same [frontmatter](#supported-frontmatter-fields) fields as file-based subagents: `description`, `prompt`, `tools`, `disallowedTools`, `model`, `permissionMode`, `mcpServers`, `hooks`, `maxTurns`, `skills`, `initialPrompt`, `memory`, `effort`, `background`, `isolation`, and `color`. Use `prompt` for the system prompt, equivalent to the markdown body in file-based subagents.

**Managed subagents** are deployed by organization administrators. Place markdown files in `.claude/agents/` inside the [managed settings directory](/en/settings#settings-files), using the same frontmatter format as project and user subagents. Managed definitions take precedence over project and user subagents with the same name.

**Plugin subagents** come from [plugins](/en/plugins) you've installed. They appear in `/agents` alongside your custom subagents. See the [plugin components reference](/en/plugins-reference#agents) for details on creating plugin subagents.

<Note>
  For security reasons, plugin subagents do not support the `hooks`, `mcpServers`, or `permissionMode` frontmatter fields. These fields are ignored when loading agents from a plugin. If you need them, copy the agent file into `.claude/agents/` or `~/.claude/agents/`. You can also add rules to [`permissions.allow`](/en/settings#permission-settings) in `settings.json` or `settings.local.json`, but these rules apply to the entire session, not just the plugin subagent.
</Note>

Subagent definitions from any of these scopes are also available to [agent teams](/en/agent-teams#use-subagent-definitions-for-teammates): when spawning a teammate, you can reference a subagent type and the teammate uses its `tools` and `model`, with the definition's body appended to the teammate's system prompt as additional instructions. See [agent teams](/en/agent-teams#use-subagent-definitions-for-teammates) for which frontmatter fields apply on that path.

### Write subagent files

Subagent files use YAML frontmatter for configuration, followed by the system prompt in Markdown:

<Note>
  Subagents are loaded at session start. If you add or edit a subagent file directly on disk, restart your session to load it. Subagents created through the `/agents` interface take effect immediately without a restart.
</Note>

```markdown theme={null}
---
name: code-reviewer
description: Reviews code for quality and best practices
tools: Read, Glob, Grep
model: sonnet
---

You are a code reviewer. When invoked, analyze the code and provide
specific, actionable feedback on quality, security, and best practices.
```

The frontmatter defines the subagent's metadata and configuration. The body becomes the system prompt that guides the subagent's behavior. Subagents receive only this system prompt (plus basic environment details like working directory), not the full Claude Code system prompt.

A subagent starts in the main conversation's current working directory. Within a subagent, `cd` commands do not persist between Bash or PowerShell tool calls and do not affect the main conversation's working directory. To give the subagent an isolated copy of the repository instead, set [`isolation: worktree`](#supported-frontmatter-fields).

#### Supported frontmatter fields

The following fields can be used in the YAML frontmatter. Only `name` and `description` are required.

| Field             | Required | Description                                                                                                                                                                                                                                                                                                                              |
| :---------------- | :------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`            | Yes      | Unique identifier using lowercase letters and hyphens. [Hooks](/en/hooks#subagentstart) receive this value as `agent_type`. The filename does not have to match                                                                                                                                                                          |
| `description`     | Yes      | When Claude should delegate to this subagent                                                                                                                                                                                                                                                                                             |
| `tools`           | No       | [Tools](#available-tools) the subagent can use. Inherits all tools if omitted. To preload Skills into context, use the `skills` field rather than listing `Skill` here                                                                                                                                                                   |
| `disallowedTools` | No       | Tools to deny, removed from inherited or specified list                                                                                                                                                                                                                                                                                  |
| `model`           | No       | [Model](#choose-a-model) to use: `sonnet`, `opus`, `haiku`, a full model ID (for example, `claude-opus-4-7`), or `inherit`. Defaults to `inherit`                                                                                                                                                                                        |
| `permissionMode`  | No       | [Permission mode](#permission-modes): `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, or `plan`. Ignored for [plugin subagents](#choose-the-subagent-scope)                                                                                                                                                            |
| `maxTurns`        | No       | Maximum number of agentic turns before the subagent stops                                                                                                                                                                                                                                                                                |
| `skills`          | No       | [Skills](/en/skills) to preload into the subagent's context at startup. The full skill content is injected, not just the description. Subagents can still invoke unlisted project, user, and plugin skills through the Skill tool                                                                                                        |
| `mcpServers`      | No       | [MCP servers](/en/mcp) available to this subagent. Each entry is either a server name referencing an already-configured server (e.g., `"slack"`) or an inline definition with the server name as key and a full [MCP server config](/en/mcp#installing-mcp-servers) as value. Ignored for [plugin subagents](#choose-the-subagent-scope) |
| `hooks`           | No       | [Lifecycle hooks](#define-hooks-for-subagents) scoped to this subagent. Ignored for [plugin subagents](#choose-the-subagent-scope)                                                                                                                                                                                                       |
| `memory`          | No       | [Persistent memory scope](#enable-persistent-memory): `user`, `project`, or `local`. Enables cross-session learning                                                                                                                                                                                                                      |
| `background`      | No       | Set to `true` to always run this subagent as a [background task](#run-subagents-in-foreground-or-background). Default: `false`                                                                                                                                                                                                           |
| `effort`          | No       | Effort level when this subagent is active. Overrides the session effort level. Default: inherits from session. Options: `low`, `medium`, `high`, `xhigh`, `max`; available levels depend on the model                                                                                                                                    |
| `isolation`       | No       | Set to `worktree` to run the subagent in a temporary [git worktree](/en/worktrees), giving it an isolated copy of the repository branched by default from your [default branch](/en/worktrees#choose-the-base-branch) rather than the parent session's `HEAD`. The worktree is automatically cleaned up if the subagent makes no changes |
| `color`           | No       | Display color for the subagent in the task list and transcript. Accepts `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, or `cyan`                                                                                                                                                                                          |
| `initialPrompt`   | No       | Auto-submitted as the first user turn when this agent runs as the main session agent (via `--agent` or the `agent` setting). [Commands](/en/commands) and [skills](/en/skills) are processed. Prepended to any user-provided prompt                                                                                                      |

### Choose a model

The `model` field controls which [AI model](/en/model-config) the subagent uses:

* **Model alias**: Use one of the available aliases: `sonnet`, `opus`, or `haiku`
* **Full model ID**: Use a full model ID such as `claude-opus-4-7` or `claude-sonnet-4-6`. Accepts the same values as the `--model` flag
* **inherit**: Use the same model as the main conversation
* **Omitted**: If not specified, defaults to `inherit` (uses the same model as the main conversation)

When Claude invokes a subagent, it can also pass a `model` parameter for that specific invocation. Claude Code resolves the subagent's model in this order:

1. The [`CLAUDE_CODE_SUBAGENT_MODEL`](/en/model-config#environment-variables) environment variable, if set
2. The per-invocation `model` parameter
3. The subagent definition's `model` frontmatter
4. The main conversation's model

### Control subagent capabilities

You can control what subagents can do through tool access, permission modes, and conditional rules.

#### Available tools

Subagents can use any of Claude Code's [internal tools](/en/tools-reference). By default, subagents inherit all tools from the main conversation, including MCP tools.

To restrict tools, use either the `tools` field (allowlist) or the `disallowedTools` field (denylist). This example uses `tools` to exclusively allow Read, Grep, Glob, and Bash. The subagent can't edit files, write files, or use any MCP tools:

```yaml theme={null}
---
name: safe-researcher
description: Research agent with restricted capabilities
tools: Read, Grep, Glob, Bash
---
```

This example uses `disallowedTools` to inherit every tool from the main conversation except Write and Edit. The subagent keeps Bash, MCP tools, and everything else:

```yaml theme={null}
---
name: no-writes
description: Inherits every tool except file writes
disallowedTools: Write, Edit
---
```

If both are set, `disallowedTools` is applied first, then `tools` is resolved against the remaining pool. A tool listed in both is removed.

#### Restrict which subagents can be spawned

When an agent runs as the main thread with `claude --agent`, it can spawn subagents using the Agent tool. To restrict which subagent types it can spawn, use `Agent(agent_type)` syntax in the `tools` field.

<Note>In version 2.1.63, the Task tool was renamed to Agent. Existing `Task(...)` references in settings and agent definitions still work as aliases.</Note>

```yaml theme={null}
---
name: coordinator
description: Coordinates work across specialized agents
tools: Agent(worker, researcher), Read, Bash
---
```

This is an allowlist: only the `worker` and `researcher` subagents can be spawned. If the agent tries to spawn any other type, the request fails and the agent sees only the allowed types in its prompt. To block specific agents while allowing all others, use [`permissions.deny`](#disable-specific-subagents) instead.

To allow spawning any subagent without restrictions, use `Agent` without parentheses:

```yaml theme={null}
tools: Agent, Read, Bash
```

If `Agent` is omitted from the `tools` list entirely, the agent cannot spawn any subagents. This restriction only applies to agents running as the main thread with `claude --agent`. Subagents cannot spawn other subagents, so `Agent(agent_type)` has no effect in subagent definitions.

#### Scope MCP servers to a subagent

Use the `mcpServers` field to give a subagent access to [MCP](/en/mcp) servers that aren't available in the main conversation. Inline servers defined here are connected when the subagent starts and disconnected when it finishes. String references share the parent session's connection.

<Note>
  The `mcpServers` field applies in both contexts where an agent file can run:

  * As a subagent, spawned through the Agent tool or an @-mention
  * As the main session, launched with [`--agent`](#invoke-subagents-explicitly) or the `agent` setting

  When the agent is the main session, inline server definitions connect at startup alongside servers from [`.mcp.json`](/en/mcp) and settings files.
</Note>

Each entry in the list is either an inline server definition or a string referencing an MCP server already configured in your session:

```yaml theme={null}
---
name: browser-tester
description: Tests features in a real browser using Playwright
mcpServers:
  # Inline definition: scoped to this subagent only
  - playwright:
      type: stdio
      command: npx
      args: ["-y", "@playwright/mcp@latest"]
  # Reference by name: reuses an already-configured server
  - github
---

Use the Playwright tools to navigate, screenshot, and interact with pages.
```

Inline definitions use the same schema as `.mcp.json` server entries (`stdio`, `http`, `sse`, `ws`), keyed by the server name.

To keep an MCP server out of the main conversation entirely and avoid its tool descriptions consuming context there, define it inline here rather than in `.mcp.json`. The subagent gets the tools; the parent conversation does not.

#### Permission modes

The `permissionMode` field controls how the subagent handles permission prompts. Subagents inherit the permission context from the main conversation and can override the mode, except when the parent mode takes precedence as described below.

| Mode                | Behavior                                                                                                                                    |
| :------------------ | :------------------------------------------------------------------------------------------------------------------------------------------ |
| `default`           | Standard permission checking with prompts                                                                                                   |
| `acceptEdits`       | Auto-accept file edits and common filesystem commands for paths in the working directory or `additionalDirectories`                         |
| `auto`              | [Auto mode](/en/permission-modes#eliminate-prompts-with-auto-mode): a background classifier reviews commands and protected-directory writes |
| `dontAsk`           | Auto-deny permission prompts (explicitly allowed tools still work)                                                                          |
| `bypassPermissions` | Skip permission prompts                                                                                                                     |
| `plan`              | Plan mode (read-only exploration)                                                                                                           |

<Warning>
  Use `bypassPermissions` with caution. It skips all permission prompts, allowing the subagent to execute operations without approval, including writes to `.git`, `.claude`, `.vscode`, `.idea`, and `.husky`. Root and home directory removals such as `rm -rf /` still prompt as a circuit breaker. See [permission modes](/en/permission-modes#skip-all-checks-with-bypasspermissions-mode) for details.
</Warning>

If the parent uses `bypassPermissions` or `acceptEdits`, this takes precedence and cannot be overridden. If the parent uses [auto mode](/en/permission-modes#eliminate-prompts-with-auto-mode), the subagent inherits auto mode and any `permissionMode` in its frontmatter is ignored: the classifier evaluates the subagent's tool calls with the same block and allow rules as the parent session.

#### Preload skills into subagents

Use the `skills` field to inject skill content into a subagent's context at startup. This gives the subagent domain knowledge without requiring it to discover and load skills during execution.

```yaml theme={null}
---
name: api-developer
description: Implement API endpoints following team conventions
skills:
  - api-conventions
  - error-handling-patterns
---

Implement API endpoints. Follow the conventions and patterns from the preloaded skills.
```

The full content of each listed skill is injected into the subagent's context at startup. This field controls which skills are preloaded, not which skills the subagent can access: without it, the subagent can still discover and invoke project, user, and plugin skills through the Skill tool during execution. To prevent a subagent from invoking skills entirely, omit `Skill` from the [`tools`](#available-tools) list or add it to `disallowedTools`.

You cannot preload skills that set [`disable-model-invocation: true`](/en/skills#control-who-invokes-a-skill), since preloading draws from the same set of skills Claude can invoke. If a listed skill is missing or disabled, Claude Code skips it and logs a warning to the debug log.

<Note>
  This is the inverse of [running a skill in a subagent](/en/skills#run-skills-in-a-subagent). With `skills` in a subagent, the subagent controls the system prompt and loads skill content. With `context: fork` in a skill, the skill content is injected into the agent you specify. Both use the same underlying system.
</Note>

#### Enable persistent memory

The `memory` field gives the subagent a persistent directory that survives across conversations. The subagent uses this directory to build up knowledge over time, such as codebase patterns, debugging insights, and architectural decisions.

```yaml theme={null}
---
name: code-reviewer
description: Reviews code for quality and best practices
memory: user
---

You are a code reviewer. As you review code, update your agent memory with
patterns, conventions, and recurring issues you discover.
```

Choose a scope based on how broadly the memory should apply:

| Scope     | Location                                      | Use when                                                                                    |
| :-------- | :-------------------------------------------- | :------------------------------------------------------------------------------------------ |
| `user`    | `~/.claude/agent-memory/<name-of-agent>/`     | the subagent should remember learnings across all projects                                  |
| `project` | `.claude/agent-memory/<name-of-agent>/`       | the subagent's knowledge is project-specific and shareable via version control              |
| `local`   | `.claude/agent-memory-local/<name-of-agent>/` | the subagent's knowledge is project-specific but should not be checked into version control |

When memory is enabled:

* The subagent's system prompt includes instructions for reading and writing to the memory directory.
* The subagent's system prompt also includes the first 200 lines or 25KB of `MEMORY.md` in the memory directory, whichever comes first, with instructions to curate `MEMORY.md` if it exceeds that limit.
* Read, Write, and Edit tools are automatically enabled so the subagent can manage its memory files.

##### Persistent memory tips

* `project` is the recommended default scope. It makes subagent knowledge shareable via version control. Use `user` when the subagent's knowledge is broadly applicable across projects, or `local` when the knowledge should not be checked into version control.
* Ask the subagent to consult its memory before starting work: "Review this PR, and check your memory for patterns you've seen before."
* Ask the subagent to update its memory after completing a task: "Now that you're done, save what you learned to your memory." Over time, this builds a knowledge base that makes the subagent more effective.
* Include memory instructions directly in the subagent's markdown file so it proactively maintains its own knowledge base:

  ```markdown theme={null}
  Update your agent memory as you discover codepaths, patterns, library
  locations, and key architectural decisions. This builds up institutional
  knowledge across conversations. Write concise notes about what you found
  and where.
  ```

#### Conditional rules with hooks

For more dynamic control over tool usage, use `PreToolUse` hooks to validate operations before they execute. This is useful when you need to allow some operations of a tool while blocking others.

This example creates a subagent that only allows read-only database queries. The `PreToolUse` hook runs the script specified in `command` before each Bash command executes:

```yaml theme={null}
---
name: db-reader
description: Execute read-only database queries
tools: Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
---
```

Claude Code [passes hook input as JSON](/en/hooks#pretooluse-input) via stdin to hook commands. The validation script reads this JSON, extracts the Bash command, and [exits with code 2](/en/hooks#exit-code-2-behavior-per-event) to block write operations:

```bash theme={null}
#!/bin/bash
# ./scripts/validate-readonly-query.sh

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block SQL write operations (case-insensitive)
if echo "$COMMAND" | grep -iE '\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE)\b' > /dev/null; then
  echo "Blocked: Only SELECT queries are allowed" >&2
  exit 2
fi

exit 0
```

See [Hook input](/en/hooks#pretooluse-input) for the complete input schema and [exit codes](/en/hooks#exit-code-output) for how exit codes affect behavior. On Windows, write hook scripts in PowerShell and add `shell: powershell` to the hook entry as shown in [running hooks in PowerShell](/en/hooks#windows-powershell-tool).

#### Disable specific subagents

You can prevent Claude from using specific subagents by adding them to the `deny` array in your [settings](/en/settings#permission-settings). Use the format `Agent(subagent-name)` where `subagent-name` matches the subagent's name field.

```json theme={null}
{
  "permissions": {
    "deny": ["Agent(Explore)", "Agent(my-custom-agent)"]
  }
}
```

This works for both built-in and custom subagents. You can also use the `--disallowedTools` CLI flag:

```bash theme={null}
claude --disallowedTools "Agent(Explore)"
```

See [Permissions documentation](/en/permissions#tool-specific-permission-rules) for more details on permission rules.

### Define hooks for subagents

Subagents can define [hooks](/en/hooks) that run during the subagent's lifecycle. There are two ways to configure hooks:

1. **In the subagent's frontmatter**: Define hooks that run only while that subagent is active
2. **In `settings.json`**: Define hooks that run in the main session when subagents start or stop

#### Hooks in subagent frontmatter

Define hooks directly in the subagent's markdown file. These hooks only run while that specific subagent is active and are cleaned up when it finishes.

<Note>
  Frontmatter hooks fire when the agent is spawned as a subagent through the Agent tool or an @-mention, and when the agent runs as the main session via [`--agent`](#invoke-subagents-explicitly) or the `agent` setting. In the main-session case they run alongside any hooks defined in [`settings.json`](/en/hooks).
</Note>

All [hook events](/en/hooks#hook-events) are supported. The most common events for subagents are:

| Event         | Matcher input | When it fires                                                       |
| :------------ | :------------ | :------------------------------------------------------------------ |
| `PreToolUse`  | Tool name     | Before the subagent uses a tool                                     |
| `PostToolUse` | Tool name     | After the subagent uses a tool                                      |
| `Stop`        | (none)        | When the subagent finishes (converted to `SubagentStop` at runtime) |

This example validates Bash commands with the `PreToolUse` hook and runs a linter after file edits with `PostToolUse`:

```yaml theme={null}
---
name: code-reviewer
description: Review code changes with automatic linting
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh $TOOL_INPUT"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
---
```

When the agent is invoked as a subagent, `Stop` hooks in frontmatter are automatically converted to `SubagentStop` events.

#### Project-level hooks for subagent events

Configure hooks in `settings.json` that respond to subagent lifecycle events in the main session.

| Event           | Matcher input   | When it fires                    |
| :-------------- | :-------------- | :------------------------------- |
| `SubagentStart` | Agent type name | When a subagent begins execution |
| `SubagentStop`  | Agent type name | When a subagent completes        |

Both events support matchers to target specific agent types by name. This example runs a setup script only when the `db-agent` subagent starts, and a cleanup script when any subagent stops:

```json theme={null}
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "db-agent",
        "hooks": [
          { "type": "command", "command": "./scripts/setup-db-connection.sh" }
        ]
      }
    ],
    "SubagentStop": [
      {
        "hooks": [
          { "type": "command", "command": "./scripts/cleanup-db-connection.sh" }
        ]
      }
    ]
  }
}
```

See [Hooks](/en/hooks) for the complete hook configuration format.

## Work with subagents

### Understand automatic delegation

Claude automatically delegates tasks based on the task description in your request, the `description` field in subagent configurations, and current context. To encourage proactive delegation, include phrases like "use proactively" in your subagent's description field.

### Invoke subagents explicitly

When automatic delegation isn't enough, you can request a subagent yourself. Three patterns escalate from a one-off suggestion to a session-wide default:

* **Natural language**: name the subagent in your prompt; Claude decides whether to delegate
* **@-mention**: guarantees the subagent runs for one task
* **Session-wide**: the whole session uses that subagent's system prompt, tool restrictions, and model via the `--agent` flag or the `agent` setting

For natural language, there's no special syntax. Name the subagent and Claude typically delegates:

```text theme={null}
Use the test-runner subagent to fix failing tests
Have the code-reviewer subagent look at my recent changes
```

**@-mention the subagent.** Type `@` and pick the subagent from the typeahead, the same way you @-mention files. This ensures that specific subagent runs rather than leaving the choice to Claude:

```text theme={null}
@"code-reviewer (agent)" look at the auth changes
```

Your full message still goes to Claude, which writes the subagent's task prompt based on what you asked. The @-mention controls which subagent Claude invokes, not what prompt it receives.

Subagents provided by an enabled [plugin](/en/plugins) appear in the typeahead under their scoped name, such as `my-plugin:code-reviewer` or `my-plugin:review:security` when the plugin [organizes agents into subfolders](#choose-the-subagent-scope). Named background subagents currently running in the session also appear in the typeahead, showing their status next to the name. You can also type the mention manually without using the picker: `@agent-<name>` for local subagents, or `@agent-` followed by the scoped name for plugin subagents, for example `@agent-my-plugin:code-reviewer`.

**Run the whole session as a subagent.** Pass [`--agent <name>`](/en/cli-reference) to start a session where the main thread itself takes on that subagent's system prompt, tool restrictions, and model:

```bash theme={null}
claude --agent code-reviewer
```

The subagent's system prompt replaces the default Claude Code system prompt entirely, the same way [`--system-prompt`](/en/cli-reference) does. `CLAUDE.md` files and project memory still load through the normal message flow. The agent name appears as `@<name>` in the startup header so you can confirm it's active.

This works with built-in and custom subagents, and the choice persists when you resume the session.

For a plugin-provided subagent, you can pass just the agent name and Claude Code will find it:

```bash theme={null}
claude --agent security-reviewer
```

If multiple plugins provide agents with the same name, pass the scoped name to disambiguate:

```bash theme={null}
claude --agent my-plugin:security-reviewer
```

If the plugin places the agent in a subfolder of its `agents/` directory, include the subfolder in the scoped name, for example `claude --agent my-plugin:review:security`.

To make it the default for every session in a project, set `agent` in `.claude/settings.json`:

```json theme={null}
{
  "agent": "code-reviewer"
}
```

The CLI flag overrides the setting if both are present.

### Run subagents in foreground or background

Subagents can run in the foreground (blocking) or background (concurrent):

* **Foreground subagents** block the main conversation until complete. Permission prompts are passed through to you as they come up.
* **Background subagents** run concurrently while you continue working. They run with the permissions already granted in the session and auto-deny any tool call that would otherwise prompt. If a background subagent needs to ask clarifying questions, that tool call fails but the subagent continues.

If a background subagent fails due to missing permissions, you can start a new foreground subagent with the same task to retry with interactive prompts.

Claude decides whether to run subagents in the foreground or background based on the task. You can also:

* Ask Claude to "run this in the background"
* Press **Ctrl+B** to background a running task

To disable all background task functionality, set the `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` environment variable to `1`. See [Environment variables](/en/env-vars).

When [fork mode](#fork-the-current-conversation) is enabled, every subagent spawn runs in the background regardless of the `background` field. Forks still surface permission prompts in your terminal as they occur; named subagents auto-deny anything that would prompt, as described above.

### Common patterns

#### Isolate high-volume operations

One of the most effective uses for subagents is isolating operations that produce large amounts of output. Running tests, fetching documentation, or processing log files can consume significant context. By delegating these to a subagent, the verbose output stays in the subagent's context while only the relevant summary returns to your main conversation.

```text theme={null}
Use a subagent to run the test suite and report only the failing tests with their error messages
```

#### Run parallel research

For independent investigations, spawn multiple subagents to work simultaneously:

```text theme={null}
Research the authentication, database, and API modules in parallel using separate subagents
```

Each subagent explores its area independently, then Claude synthesizes the findings. This works best when the research paths don't depend on each other.

<Warning>
  When subagents complete, their results return to your main conversation. Running many subagents that each return detailed results can consume significant context.
</Warning>

For tasks that need sustained parallelism or exceed your context window, [agent teams](/en/agent-teams) give each worker its own independent context.

#### Chain subagents

For multi-step workflows, ask Claude to use subagents in sequence. Each subagent completes its task and returns results to Claude, which then passes relevant context to the next subagent.

```text theme={null}
Use the code-reviewer subagent to find performance issues, then use the optimizer subagent to fix them
```

### Choose between subagents and main conversation

Use the **main conversation** when:

* The task needs frequent back-and-forth or iterative refinement
* Multiple phases share significant context (planning → implementation → testing)
* You're making a quick, targeted change
* Latency matters. Subagents start fresh and may need time to gather context

Use **subagents** when:

* The task produces verbose output you don't need in your main context
* You want to enforce specific tool restrictions or permissions
* The work is self-contained and can return a summary

Consider [Skills](/en/skills) instead when you want reusable prompts or workflows that run in the main conversation context rather than isolated subagent context.

For a quick question about something already in your conversation, use [`/btw`](/en/interactive-mode#side-questions-with-%2Fbtw) instead of a subagent. It sees your full context but has no tool access, and the answer is discarded rather than added to history.

<Note>
  Subagents cannot spawn other subagents. If your workflow requires nested delegation, use [Skills](/en/skills) or [chain subagents](#chain-subagents) from the main conversation.
</Note>

### Manage subagent context

#### What loads at startup

Each subagent starts with a fresh, isolated context window. It does not see your conversation history, the skills you've already invoked, or the files Claude has already read. Claude composes a delegation message that summarizes the task, and the subagent works from there. The exception is a [fork](#fork-the-current-conversation), which inherits the parent conversation instead of starting fresh.

A non-fork subagent's initial context contains:

* **System prompt**: the agent's own prompt plus environment details that Claude Code appends, not the full Claude Code system prompt. Custom subagents define theirs in the [markdown body](#write-subagent-files) or `prompt` field. Built-in agents have predefined prompts.
* **Task message**: the delegation prompt Claude writes when it hands off the work.
* **CLAUDE.md and memory**: every level of the [memory hierarchy](/en/memory#how-claude-md-files-load) the main conversation loads, including `~/.claude/CLAUDE.md`, project rules, `CLAUDE.local.md`, and managed policy files. The built-in Explore and Plan agents skip this.
* **Git status**: a snapshot taken at the start of the parent session. Absent when the working directory isn't a Git repository or when [`includeGitInstructions`](/en/settings#available-settings) is `false`. Explore and Plan skip it regardless.
* **Preloaded skills**: full content of any skill named in the agent's [`skills` field](#preload-skills-into-subagents). Built-in agents don't preload skills.

Explore and Plan are the only subagents that omit CLAUDE.md and git status. There is no frontmatter field or per-agent setting to change which agents skip them.

The main conversation reads Explore and Plan results with full CLAUDE.md context, so most rules don't need to reach the subagent itself. If a rule must, such as "ignore the `vendor/` directory," restate it in the prompt you give Claude when delegating.

#### Resume subagents

Each subagent invocation creates a new instance with fresh context. To continue an existing subagent's work instead of starting over, ask Claude to resume it.

Resumed subagents retain their full conversation history, including all previous tool calls, results, and reasoning. The subagent picks up exactly where it stopped rather than starting fresh.

When a subagent completes, Claude receives its agent ID. Claude uses the `SendMessage` tool with the agent's ID as the `to` field to resume it. The `SendMessage` tool is only available when [agent teams](/en/agent-teams) are enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

To resume a subagent, ask Claude to continue the previous work:

```text theme={null}
Use the code-reviewer subagent to review the authentication module
[Agent completes]

Continue that code review and now analyze the authorization logic
[Claude resumes the subagent with full context from previous conversation]
```

If a stopped subagent receives a `SendMessage`, it auto-resumes in the background without requiring a new `Agent` invocation.

You can also ask Claude for the agent ID if you want to reference it explicitly, or find IDs in the transcript files at `~/.claude/projects/{project}/{sessionId}/subagents/`. Each transcript is stored as `agent-{agentId}.jsonl`.

Subagent transcripts persist independently of the main conversation:

* **Main conversation compaction**: When the main conversation compacts, subagent transcripts are unaffected. They're stored in separate files.
* **Session persistence**: Subagent transcripts persist within their session. You can [resume a subagent](#resume-subagents) after restarting Claude Code by resuming the same session.
* **Automatic cleanup**: Transcripts are cleaned up based on the `cleanupPeriodDays` setting (default: 30 days).

#### Auto-compaction

Subagents support automatic compaction using the same logic as the main conversation. By default, auto-compaction triggers at approximately 95% capacity. To trigger compaction earlier, set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` to a lower percentage (for example, `50`). See [environment variables](/en/env-vars) for details.

Compaction events are logged in subagent transcript files:

```json theme={null}
{
  "type": "system",
  "subtype": "compact_boundary",
  "compactMetadata": {
    "trigger": "auto",
    "preTokens": 167189
  }
}
```

The `preTokens` value shows how many tokens were used before compaction occurred.

## Fork the current conversation

<Note>
  Forked subagents are experimental and require Claude Code v2.1.117 or later. Behavior and configuration may change in future releases. Enable them by setting the [`CLAUDE_CODE_FORK_SUBAGENT`](/en/env-vars) environment variable to `1`. The variable is honored in interactive mode and via the SDK or `claude -p`.
</Note>

A fork is a subagent that inherits the entire conversation so far instead of starting fresh. This drops the input isolation that subagents otherwise provide: a fork sees the same system prompt, tools, model, and message history as the main session, so you can hand it a side task without re-explaining the situation. The fork's own tool calls still stay out of your conversation and only its final result comes back, so your main context window stays clean. Use a fork when a named subagent would need too much background to be useful, or when you want to try several approaches in parallel from the same starting point.

Enabling fork mode changes Claude Code in three ways:

* Claude spawns a fork whenever it would otherwise use the [general-purpose](#built-in-subagents) subagent. Named subagents such as Explore still spawn as before.
* Every subagent spawn runs in the [background](#run-subagents-in-foreground-or-background), whether it is a fork or a named subagent. Set `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` to `1` to keep spawns synchronous.
* The `/fork` command spawns a fork instead of acting as an alias for [`/branch`](/en/commands).

You can start a fork yourself with `/fork` followed by a directive. Claude Code names the fork from the first words of the directive. The following example forks the conversation to draft test cases while you continue with the implementation in the main session:

```text theme={null}
/fork draft unit tests for the parser changes so far
```

The fork appears in a panel below your prompt and runs in the background while you keep working. When it finishes, its result arrives as a message in your main conversation. The next section covers the panel controls for watching and steering forks while they run.

### Observe and steer running forks

Running forks appear in a panel below the prompt input, with one row for the main session and one for each fork. Use these keys to interact with the panel:

| Key       | Action                                                             |
| :-------- | :----------------------------------------------------------------- |
| `↑` / `↓` | Move between rows                                                  |
| `Enter`   | Open the selected fork's transcript and send it follow-up messages |
| `x`       | Dismiss a finished fork or stop a running one                      |
| `Esc`     | Return focus to the prompt input                                   |

### How forks differ from named subagents

A fork inherits everything the main session has at the moment it spawns. A named subagent starts from its own definition.

|                         | Fork                             | Named subagent                                                                           |
| :---------------------- | :------------------------------- | :--------------------------------------------------------------------------------------- |
| Context                 | Full conversation history        | Fresh context with the prompt you pass                                                   |
| System prompt and tools | Same as main session             | From the subagent's [definition file](#write-subagent-files)                             |
| Model                   | Same as main session             | From the subagent's `model` field                                                        |
| Permissions             | Prompts surface in your terminal | [Auto-denied](#run-subagents-in-foreground-or-background) when running in the background |
| Prompt cache            | Shared with main session         | Separate cache                                                                           |

Because a fork's system prompt and tool definitions are identical to the parent, its first request reuses the parent's [prompt cache](/en/prompt-caching#subagents-and-the-cache). This makes forking cheaper than spawning a fresh subagent for tasks that need the same context.

When Claude spawns a fork through the Agent tool, it can pass `isolation: "worktree"` so the fork's file edits are written to a separate git worktree instead of your checkout.

### Limitations

Setting `CLAUDE_CODE_FORK_SUBAGENT=1` enables fork mode in interactive sessions, [non-interactive mode](/en/headless), and the Agent SDK. A fork cannot spawn further forks.

## Example subagents

These examples demonstrate effective patterns for building subagents. Use them as starting points, or generate a customized version with Claude.

<Tip>
  **Best practices:**

  * **Design focused subagents:** each subagent should excel at one specific task
  * **Write detailed descriptions:** Claude uses the description to decide when to delegate
  * **Limit tool access:** grant only necessary permissions for security and focus
  * **Check into version control:** share project subagents with your team
</Tip>

### Code reviewer

A read-only subagent that reviews code without modifying it. This example shows how to design a focused subagent with limited tool access (no Edit or Write) and a detailed prompt that specifies exactly what to look for and how to format output.

```markdown theme={null}
---
name: code-reviewer
description: Expert code review specialist. Proactively reviews code for quality, security, and maintainability. Use immediately after writing or modifying code.
tools: Read, Grep, Glob, Bash
model: inherit
---

You are a senior code reviewer ensuring high standards of code quality and security.

When invoked:
1. Run git diff to see recent changes
2. Focus on modified files
3. Begin review immediately

Review checklist:
- Code is clear and readable
- Functions and variables are well-named
- No duplicated code
- Proper error handling
- No exposed secrets or API keys
- Input validation implemented
- Good test coverage
- Performance considerations addressed

Provide feedback organized by priority:
- Critical issues (must fix)
- Warnings (should fix)
- Suggestions (consider improving)

Include specific examples of how to fix issues.
```

### Debugger

A subagent that can both analyze and fix issues. Unlike the code reviewer, this one includes Edit because fixing bugs requires modifying code. The prompt provides a clear workflow from diagnosis to verification.

```markdown theme={null}
---
name: debugger
description: Debugging specialist for errors, test failures, and unexpected behavior. Use proactively when encountering any issues.
tools: Read, Edit, Bash, Grep, Glob
---

You are an expert debugger specializing in root cause analysis.

When invoked:
1. Capture error message and stack trace
2. Identify reproduction steps
3. Isolate the failure location
4. Implement minimal fix
5. Verify solution works

Debugging process:
- Analyze error messages and logs
- Check recent code changes
- Form and test hypotheses
- Add strategic debug logging
- Inspect variable states

For each issue, provide:
- Root cause explanation
- Evidence supporting the diagnosis
- Specific code fix
- Testing approach
- Prevention recommendations

Focus on fixing the underlying issue, not the symptoms.
```

### Data scientist

A domain-specific subagent for data analysis work. This example shows how to create subagents for specialized workflows outside of typical coding tasks. It explicitly sets `model: sonnet` for more capable analysis.

```markdown theme={null}
---
name: data-scientist
description: Data analysis expert for SQL queries, BigQuery operations, and data insights. Use proactively for data analysis tasks and queries.
tools: Bash, Read, Write
model: sonnet
---

You are a data scientist specializing in SQL and BigQuery analysis.

When invoked:
1. Understand the data analysis requirement
2. Write efficient SQL queries
3. Use BigQuery command line tools (bq) when appropriate
4. Analyze and summarize results
5. Present findings clearly

Key practices:
- Write optimized SQL queries with proper filters
- Use appropriate aggregations and joins
- Include comments explaining complex logic
- Format results for readability
- Provide data-driven recommendations

For each analysis:
- Explain the query approach
- Document any assumptions
- Highlight key findings
- Suggest next steps based on data

Always ensure queries are efficient and cost-effective.
```

### Database query validator

A subagent that allows Bash access but validates commands to permit only read-only SQL queries. This example shows how to use `PreToolUse` hooks for conditional validation when you need finer control than the `tools` field provides.

```markdown theme={null}
---
name: db-reader
description: Execute read-only database queries. Use when analyzing data or generating reports.
tools: Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
---

You are a database analyst with read-only access. Execute SELECT queries to answer questions about the data.

When asked to analyze data:
1. Identify which tables contain the relevant data
2. Write efficient SELECT queries with appropriate filters
3. Present results clearly with context

You cannot modify data. If asked to INSERT, UPDATE, DELETE, or modify schema, explain that you only have read access.
```

Claude Code [passes hook input as JSON](/en/hooks#pretooluse-input) via stdin to hook commands. The validation script reads this JSON, extracts the command being executed, and checks it against a list of SQL write operations. If a write operation is detected, the script [exits with code 2](/en/hooks#exit-code-2-behavior-per-event) to block execution and returns an error message to Claude via stderr.

Create the validation script anywhere in your project. The path must match the `command` field in your hook configuration:

```bash theme={null}
#!/bin/bash
# Blocks SQL write operations, allows SELECT queries

# Read JSON input from stdin
INPUT=$(cat)

# Extract the command field from tool_input using jq
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Block write operations (case-insensitive)
if echo "$COMMAND" | grep -iE '\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE|REPLACE|MERGE)\b' > /dev/null; then
  echo "Blocked: Write operations not allowed. Use SELECT queries only." >&2
  exit 2
fi

exit 0
```

On macOS and Linux, make the script executable:

```bash theme={null}
chmod +x ./scripts/validate-readonly-query.sh
```

On Windows, write the validation script in PowerShell and add `shell: powershell` to the hook entry. See [running hooks in PowerShell](/en/hooks#windows-powershell-tool).

The hook receives JSON via stdin with the Bash command in `tool_input.command`. Exit code 2 blocks the operation and feeds the error message back to Claude. See [Hooks](/en/hooks#exit-code-output) for details on exit codes and [Hook input](/en/hooks#pretooluse-input) for the complete input schema.

## Next steps

Now that you understand subagents, explore these related features:

* [Distribute subagents with plugins](/en/plugins) to share subagents across teams or projects
* [Run Claude Code programmatically](/en/headless) with the Agent SDK for CI/CD and automation
* [Use MCP servers](/en/mcp) to give subagents access to external tools and data

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Manage multiple agents with agent view

> Dispatch and manage many Claude Code sessions from one screen. Agent view shows what every session is doing and which ones need your input.

Agent view, opened with `claude agents`, is one screen for all your background sessions: what's running, what needs your input, and what's done. Dispatch new sessions, watch their state at a glance instead of scrolling through transcripts, and step in only when one needs you. Each background session is a full Claude Code conversation that keeps running without a terminal attached, so you can open it, reply, and leave whenever you want.

<img src="https://mintcdn.com/claude-code/1B48Qz2Z9hac4SLG/images/agent-view-light.png?fit=max&auto=format&n=1B48Qz2Z9hac4SLG&q=85&s=7a186c96ed47d6700d084d77e786be65" className="dark:hidden" alt="Agent view in a terminal: the header shows Claude Code v2.1.140, the model, the working directory, and a summary count. Sessions are grouped under Needs input, Working, and Completed, with a dispatch input at the bottom and a footer of keyboard hints." width="1772" height="780" data-path="images/agent-view-light.png" />

<img src="https://mintcdn.com/claude-code/1B48Qz2Z9hac4SLG/images/agent-view-dark.png?fit=max&auto=format&n=1B48Qz2Z9hac4SLG&q=85&s=a5bed7434bae368faea3a8f023b52aa2" className="hidden dark:block" alt="Agent view in a terminal: the header shows Claude Code v2.1.140, the model, the working directory, and a summary count. Sessions are grouped under Needs input, Working, and Completed, with a dispatch input at the bottom and a footer of keyboard hints." width="1772" height="780" data-path="images/agent-view-dark.png" />

Use agent view when you have several independent tasks Claude can work on without you watching every step. Dispatch a bug fix, a pull request review, and a flaky-test investigation as three rows, keep working in another window, and check back when a row shows it needs you or has a result.

When you want to work more directly in any agent's session, attach to the row to enter the full conversation.

To compare agent view with subagents, agent teams, and worktrees, see [Run agents in parallel](/en/agents).

<Note>
  Agent view is in research preview and requires Claude Code v2.1.139 or later. Check your version with `claude --version`. The interface and keyboard shortcuts may change as the feature evolves.
</Note>

This page covers:

* [Quick start](#quick-start): give Claude a task to work on in the background, check on it, and step in when needed
* [Monitor sessions with agent view](#monitor-sessions-with-agent-view), including state icons, peeking and replying, attaching, organizing, and keyboard shortcuts
* [Dispatch new agents](#dispatch-new-agents) from agent view, from inside a session, or from your shell
* [Manage sessions from the shell](#manage-sessions-from-the-shell)
* [How background sessions are hosted](#how-background-sessions-are-hosted) by the supervisor process

## Quick start

This walkthrough covers the core agent view loop: dispatch a task, watch its row update as Claude works, peek to check on it and reply, and attach for the full conversation. The session you dispatch keeps running after you close agent view, so you can leave and come back to it.

<Steps>
  <Step title="Open agent view">
    From your shell, run:

    ```bash theme={null}
    claude agents
    ```

    Agent view opens with an input at the bottom and a table that fills in as sessions start. Press `Esc` at any time to return to your shell. Your sessions keep running while you're away and reappear the next time you open agent view.
  </Step>

  <Step title="Dispatch a session">
    Type a prompt describing a task and press `Enter`. A new background session starts on that task and appears as a row showing whether it's working, waiting on you, or done. The new session uses the model shown in the agent view header and the same [permission mode](#permission-mode-model-and-effort) you'd get running `claude` in that directory.

    Every prompt you enter here starts its own new session. Typing another prompt and pressing `Enter` launches a second session alongside the first rather than sending a follow-up to it. You can run several in parallel this way.

    Each session uses your subscription quota independently, so see [Limitations](#limitations) before dispatching many at once.
  </Step>

  <Step title="Peek and reply">
    Select a row with the arrow keys and press `Space` to open the peek panel. It shows the session's most recent output, or the question it's waiting on, rather than the full transcript. Type a reply and press `Enter` to send it without leaving agent view.
  </Step>

  <Step title="Attach and detach">
    Press `Enter` or `→` on a row to attach when you want the full conversation. The session takes over the terminal exactly as if you had run `claude`. Press `←` on an empty prompt to detach and return to the table.
  </Step>

  <Step title="Bring an existing session in">
    To move a session you already have open into agent view, run `/bg` inside it, or press `←` on an empty prompt to background it and open agent view in one step. The session keeps running and appears as a row alongside the ones you dispatched.
  </Step>
</Steps>

You can use `claude agents` as your primary entry point instead of `claude`: dispatch every task from agent view, attach when you want the full conversation, and press `←` to return to the table.

## Monitor sessions with agent view

Run `claude agents` to open agent view. It takes over the full terminal and lists every session grouped by state, with pinned sessions and the ones that need you at the top. Each row shows the session's name, current activity, and how long ago it last changed.

By default the list shows every background session you've started, across all your projects. A session working in one repository and another in a different worktree both appear here, regardless of which directory you opened agent view from. To narrow the list to one project, pass `--cwd` (requires Claude Code v2.1.141 or later):

```bash theme={null}
claude agents --cwd ~/projects/my-app
```

This shows only sessions started under that directory. A session that has [moved into a worktree](#how-file-edits-are-isolated) under `~/projects/my-app/.claude/worktrees/` still counts as belonging to `~/projects/my-app`.

Interactive sessions you have open in other terminals don't appear until you [background them](#from-inside-a-session). [Subagents](/en/sub-agents) and [teammates](/en/agent-teams) a session spawns aren't listed as separate rows.

```text theme={null}
Pinned
  ✽ clawd walk cycle          Write assets/sprites/clawd-walk.png           3m

Ready for review
  ∙ jump physics              github.com/example/game/pull/2048          ●  2h

Needs input
  ✻ power-up design           needs input: double jump or wall climb?       1m

Working
  ✽ collision detection       Edit src/physics/CollisionSystem.ts           2m
  ✢ playtest level 3          run 12 · all checkpoints cleared           in 4m

Completed
  ✻ title screen              result: menu, options, and credits done       9m
  ∙ sound effects             result: 14 SFX exported to assets/audio       4h
  … 6 more
```

### Read session state

Each row starts with an icon whose color and animation show the session's state:

| State       | Icon shows as | What it means                                                            |
| :---------- | :------------ | :----------------------------------------------------------------------- |
| Working     | Animated      | Claude is actively running tools or generating a response                |
| Needs input | Yellow        | Claude is waiting on a specific question or permission decision from you |
| Idle        | Dimmed        | The session has nothing to do and is ready for your next prompt          |
| Completed   | Green         | The task finished successfully                                           |
| Failed      | Red           | The task ended with an error                                             |
| Stopped     | Grey          | The session was stopped with `Ctrl+X` or `claude stop`                   |

Separately, the icon's shape shows whether the underlying process is running:

| Shape               | What it means                                                                                                     |
| :------------------ | :---------------------------------------------------------------------------------------------------------------- |
| `✻` or animated `✽` | The session process is alive and replies immediately                                                              |
| `∙`                 | The process has exited. You can still peek, reply, or attach, and Claude restarts from where it left off          |
| `✢`                 | A [`/loop`](/en/scheduled-tasks) session sleeping between iterations. The row shows its run count and a countdown |

The `●` that can appear at the right edge of a row is the [pull request status](#pull-request-status) indicator, not part of the state icon. A number before it is the count of pull requests the session has opened.

The terminal tab title shows the awaiting-input count while agent view is open: `2 awaiting input · claude agents` when sessions need input, or `claude agents` when none do.

Background sessions don't need any terminal open to keep working. A separate [supervisor process](#the-supervisor-process) runs them, so you can close agent view, close your shell, or start a new interactive session and your dispatched work keeps going.

Session state persists on disk through auto-updates and supervisor restarts. Sessions are also preserved when your machine sleeps. Their processes resume on wake and the supervisor reconnects to them instead of treating the time gap as idle. Shutting down still stops running sessions; see [Sessions show as failed after shutdown](#sessions-show-as-failed-after-shutdown) for how to recover them.

### Row summaries

The one-line summary in each row is generated by a [Haiku-class model](/en/model-config) so the row can tell you what the session is doing, what it needs, or what it produced without opening the transcript. While a session is actively working, the summary refreshes at most once every 15 seconds, plus once when each turn ends.

Each refresh is one short Haiku-class request through your normal provider, billed and handled under the same [data usage terms](/en/data-usage) as the session itself.

### Pull request status

When a session opens a pull request, a status dot appears at the right edge of the row, linked to the pull request in terminals that support hyperlinks. When the session has opened more than one pull request, the count appears before the dot and the color reflects whichever one most needs attention.

| Dot color | Pull request status                           |
| :-------- | :-------------------------------------------- |
| Yellow    | Waiting on checks or review, or checks failed |
| Green     | Checks passed and no review is blocking       |
| Purple    | Merged                                        |
| Grey      | Draft or closed                               |

For most tasks this row is where you pick up the result: review and merge the pull request when the dot turns green.

### Peek and reply

Press `Space` on a selected row to open the peek panel. It shows what the session needs from you, its most recent output, and any pull requests it opened. Most of the time this is enough, and you never need to open the full transcript.

Type a reply in the peek panel and press `Enter` to send it to that session. When the session is asking a multiple-choice question, the peek panel shows the options and you can press a number key to pick one. For other blocked sessions, press `Tab` to fill the input with a suggested reply you can edit before sending. Prefix a reply with `!` to send a Bash command instead.

Use `↑` and `↓` to peek at adjacent sessions without closing the panel, or `→` to attach.

### Attach to a session

Press `Enter` or `→` on a selected row to attach. Agent view is replaced by the full interactive session, exactly as if you had run `claude` in that directory. When you attach, Claude posts a short recap of what happened while you were away.

While attached, the session behaves like any other Claude Code session: every [command](/en/commands), keyboard shortcut, and feature works.

Press `←` on an empty prompt to detach and return to agent view. If a dialog has focus and isn't responding to `←`, press `Ctrl+Z` to detach immediately.

Detaching never stops a background session: `←`, `Ctrl+C`, `Ctrl+D`, `Ctrl+Z`, and `/exit` all leave it running. To end a session from inside it, run `/stop`.

After you've dispatched or backgrounded a session, pressing `←` on an empty prompt works from any Claude Code session, not only ones you attached to from agent view. It backgrounds the current session and opens agent view with that row selected, so you can switch sessions without leaving the terminal. The row is created even from a fresh session with no conversation history, so `→` returns to it. When that row is the only one, agent view shows an onboarding hint below it. You can turn this shortcut off in `/config` (the `leftArrowOpensAgents` setting).

### Organize the list

Agent view groups sessions so the ones that need input are at the top, with `Ready for review` and `Needs input` above `Working` and `Completed`. These group names don't map one-to-one to the [states](#read-session-state) above: a session moves to `Ready for review` when it has an open pull request, and `Completed` collects finished, failed, and stopped sessions together. Press `Ctrl+S` to group by directory instead. Your choice persists across runs.

Within a group:

* Press `Ctrl+T` to pin a session to the top and [keep its process running](#the-supervisor-process) while idle
* Press `Shift+↑` or `Shift+↓` to reorder sessions
* Press `Ctrl+R` to rename a session
* Press `Enter` on a group header to collapse it

To remove a session from the list, press `Ctrl+X` to stop it and `Ctrl+X` again within two seconds to delete it. Pressing `Ctrl+X` on a group header deletes every session in that group after confirmation.

Deleting removes the session from agent view. If Claude [created a worktree](#how-file-edits-are-isolated) for the session, deleting removes that worktree too, including any uncommitted changes in it, so push or commit work you want to keep first. A worktree you created yourself and started the session inside is left in place. The conversation transcript stays on your local machine and remains available through `claude --resume`.

Older completed sessions fold into a `… N more` row to keep the list short. Failures and sessions with an open pull request always stay visible.

### Filter sessions

Type in the dispatch input to filter instead of dispatching:

| Filter                  | Shows                                                                                                    |
| :---------------------- | :------------------------------------------------------------------------------------------------------- |
| `a:<name>`              | Sessions running the named agent                                                                         |
| `s:<state>`             | Sessions in the given state, such as `s:working`. Also accepts `s:blocked` for everything waiting on you |
| `#<number>` or a PR URL | The session working on that pull request                                                                 |

### Keyboard shortcuts

Press `?` in agent view to see every shortcut in context. The table below summarizes them.

| Shortcut              | Action                                                                              |
| :-------------------- | :---------------------------------------------------------------------------------- |
| `↑` / `↓`             | Move between rows                                                                   |
| `Enter`               | Attach to the selected session, or dispatch if there's text in the input            |
| `Space`               | Open or close the peek panel for the selected session                               |
| `Shift+Enter`         | Dispatch and attach immediately                                                     |
| `→`                   | Attach to the selected session                                                      |
| `Alt+1`..`Alt+9`      | Attach to session 1–9 in the focused session's directory                            |
| `Tab`                 | On an empty input, browse all subagents. Otherwise apply the highlighted suggestion |
| `Ctrl+S`              | Switch grouping between state and directory                                         |
| `Ctrl+T`              | Pin or unpin the selected session                                                   |
| `Ctrl+R`              | Rename the selected session                                                         |
| `Ctrl+G`              | Open the dispatch prompt in your `$VISUAL` or `$EDITOR`                             |
| `Ctrl+X`              | Stop the session; press again within two seconds to delete it                       |
| `Shift+↑` / `Shift+↓` | Reorder the selected session                                                        |
| `Esc`                 | Close the peek panel, clear the input, or exit                                      |
| `Ctrl+C`              | Clear the input; press twice to exit                                                |
| `?`                   | Show all shortcuts                                                                  |

## Dispatch new agents

You can dispatch new background sessions from agent view, send an existing interactive session to the background, or start one directly from the shell.

### From agent view

Type a prompt in the input at the bottom of agent view and press `Enter` to start a new background session. The session is named automatically from the prompt; rename it later with `Ctrl+R`.

Paste an image into the prompt to include a screenshot or diagram with the task.

Prefix or mention parts of the prompt to control how the session starts:

| Input                             | Effect                                                                                                                                                         |
| :-------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `<agent-name> <prompt>`           | If the first word matches a custom [subagent](/en/sub-agents) name, that subagent runs as the session's main agent with the configuration from its frontmatter |
| `@<agent-name>`                   | Mention a custom subagent anywhere in the prompt to run it as the main agent                                                                                   |
| `@<repo>`                         | Mention a repository under the directory you opened agent view from to run the session there                                                                   |
| `/<skill>`                        | Suggest [skills](/en/skills) to dispatch as the prompt                                                                                                         |
| `#<number>` or a pull request URL | If a session is already working on that PR, select it instead of dispatching                                                                                   |
| `Shift+Enter`                     | Dispatch and immediately attach to the new session                                                                                                             |

Packaging a recurring task as a [skill](/en/skills) lets you start the same workflow from agent view repeatedly without retyping the prompt.

When the same `@name` matches both a subagent and a sibling repository, the subagent takes precedence. The bare first-word match also applies, so a prompt that happens to begin with one of your subagent names dispatches that subagent rather than treating the word as plain text. Use the `@` form when you want to be explicit, or start the prompt with a different word to avoid the match.

#### Dispatch to a specific directory

A new session runs in the directory you opened agent view from. To target a different directory:

* Open `claude agents` in that directory.
* Open `claude agents` in a parent directory that holds several repositories and mention one with `@<repo>` in the prompt to run the session there.
* From the shell, `cd` into the directory and run `claude --bg "<prompt>"`.

When agent view is grouped by directory, the highlighted row's directory becomes the dispatch target, so you can scroll to a group and dispatch into it without retyping the path.

### From inside a session

Run `/background` or its alias `/bg` to move the current conversation into a background session. Pass a prompt such as `/bg run the test suite and fix any failures` to give one more instruction first.

Backgrounding from an interactive session starts a fresh process that resumes from the saved conversation, so running subagents, [monitors](/en/tools-reference#monitor-tool), and background commands do not transfer to it. Claude asks you to confirm before backgrounding when any are running. Once in the background, the session can start new subagents, monitors, and background commands, and those keep running across later detach and reattach.

Configuration flags from the original launch carry through to the backgrounded session, so its MCP servers, settings, and fallback model remain in effect:

* `--mcp-config` and `--strict-mcp-config`
* `--settings`
* `--add-dir`
* `--plugin-dir`
* `--fallback-model`
* `--allow-dangerously-skip-permissions`

Directories you added during the session with [`/add-dir`](/en/permissions#additional-directories-grant-file-access-not-configuration) also carry through.

Carrying `--allow-dangerously-skip-permissions` through keeps `bypassPermissions` reachable in the backgrounded session, but it does not grant anything new. The mode still requires the same one-time interactive acceptance described in [Permission mode, model, and effort](#permission-mode-model-and-effort) before any session can use it.

### From your shell

Pass `--bg` to start a session that goes straight to the background:

```bash theme={null}
claude --bg "investigate the flaky SettingsChangeDetector test"
```

To run a specific subagent as the session's main agent, combine `--bg` with `--agent`:

```bash theme={null}
claude --agent code-reviewer --bg "address review comments on PR 1234"
```

Pass `--name` to set the session's display name in agent view instead of the auto-generated one:

```bash theme={null}
claude --bg --name "flaky-test-fix" "investigate the flaky SettingsChangeDetector test"
```

After backgrounding, Claude prints the session's short ID and the commands for managing it. When you pass `--name`, the name appears after the short ID:

```text theme={null}
backgrounded · 7c5dcf5d · flaky-test-fix
  claude agents             list sessions
  claude attach 7c5dcf5d    open in this terminal
  claude logs 7c5dcf5d      show recent output
  claude stop 7c5dcf5d      stop this session
```

### How file edits are isolated

Every background session, whether started from agent view, `/bg`, or `claude --bg`, starts in your working directory. Before editing files, Claude moves the session into an isolated [git worktree](/en/worktrees) under `.claude/worktrees/`, so parallel sessions can read the same checkout but each writes to its own.

Claude skips the worktree when:

* The session is already inside a linked git worktree, whether Claude created it under `.claude/worktrees/` or you created it with `git worktree add` somewhere else
* The working directory isn't a git repository and no [`WorktreeCreate` hook](/en/hooks#worktreecreate) is configured
* The write is outside the working directory

To turn off worktree isolation for a repository where git worktrees are impractical, set [`worktree.bgIsolation`](/en/settings#worktree-settings) to `"none"`. Background sessions then edit your working copy directly without moving into a worktree first. Add the setting to the project's `.claude/settings.json`:

```json theme={null}
{
  "worktree": {
    "bgIsolation": "none"
  }
}
```

<Note>
  The `worktree.bgIsolation` setting requires Claude Code v2.1.143 or later.
</Note>

Outside a git repository, sessions write to the working directory directly and aren't isolated from each other, so avoid dispatching parallel sessions that edit the same files. If you use a different version control system, configure a [`WorktreeCreate` hook](/en/worktrees#non-git-version-control) and Claude isolates edits the same way it does for git.

Deleting a session in agent view (`Ctrl+X` twice) removes a worktree Claude created for it, including any uncommitted changes, so merge or push the changes you want to keep first. Deleting from the shell with [`claude rm`](#manage-sessions-from-the-shell) keeps a worktree that has uncommitted changes and prints its path so you can clean it up yourself. A worktree you created yourself and started the session inside is left in place either way.

To find a session's worktree path, peek the session or attach and check its working directory.

To make a subagent always run in its own worktree regardless of how it was started, set [`isolation: worktree`](/en/sub-agents#supported-frontmatter-fields) in its frontmatter.

### Set the model

The model name shown in the agent view header is the dispatch default. New sessions you start from the input use this model, which comes from the [`model` setting](/en/settings#available-settings) in your user settings. Set it by pressing `d` on a model in the [`/model` picker](/en/model-config), or edit the setting directly. To override it for the whole agent view session, pass `--model` when opening agent view. See [Permission mode, model, and effort](#permission-mode-model-and-effort).

Each background session can run on a different model. To override it for one session:

* From the shell, pass `--model` with `claude --bg`.
* Attach to a running session and run `/model` there. The change persists if the session is respawned.
* Dispatch a [subagent](/en/sub-agents) whose frontmatter sets a `model` field.

### Permission mode, model, and effort

A background session reads its [settings](/en/settings) from the directory it runs in, the same as if you had started `claude` there.

The [permission mode](/en/permissions) depends on how you started the session. Backgrounding an existing session with `/bg` or `←` keeps the current permission mode, so a session you switched to `acceptEdits` or `auto` stays in that mode after detaching. Dispatching from the agent view input or running `claude --bg` from your shell uses the `defaultMode` from that directory's settings, or the `permissionMode` from the dispatched [subagent's frontmatter](/en/sub-agents#supported-frontmatter-fields).

The permission mode you start a background session with persists when the supervisor later [stops and restarts](#the-supervisor-process) the session's process. A session you launched with `claude --bg --dangerously-skip-permissions` or `claude --bg --permission-mode bypassPermissions` stays in `bypassPermissions` after that restart instead of falling back to the directory's `defaultMode`.

To set defaults for every session you dispatch from agent view, pass any of `--permission-mode`, `--model`, or `--effort` when opening it:

```bash theme={null}
claude agents --permission-mode plan --model opus --effort high
```

`claude agents` also accepts `--dangerously-skip-permissions` as shorthand for `--permission-mode bypassPermissions`, and `--allow-dangerously-skip-permissions` to make `bypassPermissions` available in each dispatched session's `Shift+Tab` cycle without starting in that mode. Both match the [top-level CLI flags](/en/cli-reference).

<Note>
  Passing `--permission-mode`, `--model`, `--effort`, or `--dangerously-skip-permissions` to `claude agents` requires Claude Code v2.1.142 or later. {/* min-version: 2.1.143 */}`--allow-dangerously-skip-permissions` on `claude agents` requires v2.1.143 or later. Earlier versions reject these flags with an unknown-option error.
</Note>

The active defaults appear in the footer below the dispatch input.

Without these flags, the session uses the `defaultMode` from that directory's settings or the `permissionMode` from the dispatched [subagent's frontmatter](/en/sub-agents#supported-frontmatter-fields), and the model shown in the agent view header.

Using `bypassPermissions` or `auto` is refused until you have accepted that mode by running `claude` with it once interactively, since those modes let a session you aren't watching act without approval. The same applies whether you pass the mode to `claude agents` or to `claude --bg --permission-mode`.

### Settings, plugins, and MCP servers

Agent view accepts the same configuration flags as `claude` for loading settings, plugins, MCP servers, and additional directories. These flags require Claude Code v2.1.142 or later. Each flag applies to agent view itself and is passed through to every session you dispatch from it, so a plugin or MCP server you load this way is available in those sessions too.

| Flag                                                                                             | Effect                                                                         |
| :----------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------- |
| [`--settings <file-or-json>`](/en/settings)                                                      | Override settings for agent view and dispatched sessions                       |
| [`--add-dir <path>`](/en/permissions#additional-directories-grant-file-access-not-configuration) | Grant file access to an additional directory                                   |
| [`--plugin-dir <path>`](/en/plugins)                                                             | Load a plugin from a local directory                                           |
| [`--mcp-config <file-or-json>`](/en/mcp)                                                         | Load MCP servers from a config file or JSON string                             |
| `--strict-mcp-config`                                                                            | Use only the MCP servers from `--mcp-config`, ignoring other MCP configuration |

Repeat `--add-dir`, `--plugin-dir`, or `--mcp-config` once per value. The space-separated form, such as `--add-dir a b c`, is not supported with `claude agents`.

The following example opens agent view with a settings override and one extra directory:

```bash theme={null}
claude agents --settings ./ci-settings.json --add-dir ../shared-lib
```

## Manage sessions from the shell

Every background session has a short ID you can use from the shell. The ID is printed when you start a session with `claude --bg`, and each session's ID is its directory name under `~/.claude/jobs/`. These commands are useful for scripting or when you don't want to open agent view.

| Command                      | Purpose                                                                                                                                                                                                                                                                                                                                 |
| :--------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `claude agents`              | Open agent view                                                                                                                                                                                                                                                                                                                         |
| `claude agents --cwd <path>` | Open agent view scoped to sessions started under `<path>`                                                                                                                                                                                                                                                                               |
| `claude agents --json`       | Print live sessions as a JSON array and exit. Each entry has `pid`, `cwd`, `kind`, and `startedAt`, plus `sessionId`, `name`, and `status` when set. Combine with `--cwd <path>` to filter                                                                                                                                              |
| `claude attach <id>`         | Attach to a session in this terminal                                                                                                                                                                                                                                                                                                    |
| `claude logs <id>`           | Print the session's recent output                                                                                                                                                                                                                                                                                                       |
| `claude stop <id>`           | Stop a session. Also accepts `claude kill`                                                                                                                                                                                                                                                                                              |
| `claude respawn <id>`        | Restart a session, running or stopped, with its conversation intact, e.g. to pick up an updated Claude Code binary                                                                                                                                                                                                                      |
| `claude respawn --all`       | Restart every running session, e.g. to move all sessions onto an updated Claude Code binary at once                                                                                                                                                                                                                                     |
| `claude rm <id>`             | Remove a session from the list. Removes a worktree Claude created for the session if it has no uncommitted changes; otherwise prints the worktree path so you can clean it up. Leaves a worktree you created yourself in place. The conversation transcript stays on your local machine and remains available through `claude --resume` |
| `claude daemon status`       | Print the [supervisor's](#the-supervisor-process) state, version, socket directory, and worker count                                                                                                                                                                                                                                    |

## How background sessions are hosted

Every session listed in agent view is considered a background session, whether or not you're currently attached to it. By contrast, a session started by running `claude` directly is tied to that terminal and ends when it closes, unless you [send it to the background](#from-inside-a-session).

### The supervisor process

Background sessions are hosted by a per-user supervisor process, separate from your terminal and from agent view. The supervisor starts automatically the first time you background a session or open agent view, and you don't manage it directly.

The supervisor and its sessions authenticate with the same credentials as your interactive sessions and make no additional network connections beyond the model API.

Each background session is its own Claude Code process, managed by the supervisor rather than tied to your terminal. A session that's actively working, waiting for your input, or has a terminal attached keeps its process running. A running background shell command, subagent, workflow, or monitor counts as active work, so a long-running process such as a dev server keeps the session alive.

Once a session finishes and sits unattached for about an hour, the supervisor stops its process to free resources. A session you have [pinned](#organize-the-list) with `Ctrl+T` is exempt and keeps its process running while idle. The transcript and state stay on disk either way, and the next time you attach, peek, or reply to a stopped session, the supervisor starts a fresh process from where it left off. When every session has finished and no terminal is connected, the supervisor itself exits and starts again the next time you need it.

When the host runs low on memory, the supervisor stops idle non-pinned sessions first and stops idle pinned ones only if that freed nothing.

The supervisor watches the installed Claude Code binary on disk and restarts into the new version after the regular [auto-updater](/en/setup#auto-updates) replaces it. This is a local file watch, not a network check. Background sessions are detached processes, so they keep running through the restart and the new supervisor reconnects to them. An idle pinned session is also restarted in place onto the new version so it picks up the update without you reattaching.

### Where state is stored

Session state is stored under your Claude Code config directory. If you set [`CLAUDE_CONFIG_DIR`](/en/env-vars), the supervisor uses that directory instead of `~/.claude` and runs as a separate instance with its own sessions.

| Path                             | Contents                                                               |
| :------------------------------- | :--------------------------------------------------------------------- |
| `~/.claude/daemon.log`           | Supervisor log                                                         |
| `~/.claude/daemon/roster.json`   | List of running background sessions, used to reconnect after a restart |
| `~/.claude/jobs/<id>/state.json` | Per-session state shown in agent view                                  |

To inspect this state without reading the files directly, run `claude daemon status`. It reports whether the supervisor is reachable, its process ID and version, the socket directory, and how many background sessions are live. `/doctor` includes a summary of the same check. On Windows, `claude daemon status` surfaces the underlying file error when the daemon's pipe-key file is locked or unreadable instead of reporting a generic connection failure.

### Turn off agent view

To turn off background agents and agent view entirely, set the `disableAgentView` [setting](/en/settings) to `true` or set the `CLAUDE_CODE_DISABLE_AGENT_VIEW` environment variable. Administrators can enforce this through [managed settings](/en/permissions#managed-settings).

## Troubleshooting

### `claude agents` lists subagents instead of opening agent view

If `claude agents` prints a count followed by your configured subagents and then exits, agent view is unavailable in your environment. Earlier versions didn't open agent view in every environment, including when connected through Bedrock, Vertex AI, or Foundry. Run `claude update` to install the latest version.

If agent view still does not open after updating, check whether it has been [turned off](#turn-off-agent-view) by a setting or environment variable.

### Agent view opens with no sessions

Before you dispatch your first session, agent view shows a short onboarding hint with example prompts in place of the session list. Type a prompt in the input at the bottom and press `Enter` to dispatch your first session.

### Cannot open agents because background tasks are running

If pressing `←` to background the current session shows `Cannot open agents — N background task(s) running`, the session has in-flight work such as a subagent, a workflow, or a background shell command, and the shortcut won't silently abandon it. Run `/tasks` to see what's running, then `/bg` to confirm abandoning them. See [From inside a session](#from-inside-a-session) for what does and doesn't transfer when you background.

### Prompt rejected as too short

The dispatch input expects a task description, not a conversational opener. A prompt shorter than four characters is rejected with a `Too short` hint so a stray keystroke doesn't start a session. Describe what you want the session to do, such as `investigate the flaky checkout test`.

### Sessions show as failed after shutdown

Shutting down or restarting your machine stops running background sessions, so they show as failed when you next open agent view. Attach, peek, or reply to any of them and the session restarts from where it left off.

Sleep alone does not cause this. Sessions are preserved across sleep and the supervisor reconnects to them on wake.

### A session is slow to respond after attaching

Once a session has finished and sat unattached for about an hour, the supervisor stops its process to free resources. Attaching starts a fresh process from where it left off, which takes a moment. Sessions that are working, waiting on you, or [pinned](#organize-the-list) are not stopped this way, so pin a session with `Ctrl+T` to keep it responsive.

### `.claude/worktrees/` is filling up

Deleting a session in agent view removes the worktree Claude created for it. `claude rm` keeps a worktree that has uncommitted changes and prints its path. List leftover entries with `git worktree list` in the project directory and remove each with `git worktree remove <path>`. See [Clean up worktrees](/en/worktrees#clean-up-worktrees).

## Limitations

Agent view is in research preview with the following limitations:

* **Rate limits apply**: background sessions consume your subscription usage the same as interactive sessions, so running ten agents in parallel uses quota roughly ten times as fast as running one.
* **Sessions are local**: background sessions run on your machine. They are preserved across sleep but stop if the machine shuts down.
* **Claude-created worktrees are deleted with the session in agent view**: merge or push changes before deleting a session that edited files in its own worktree. `claude rm` keeps a worktree that has uncommitted changes; a worktree you created yourself is left in place.

## Related resources

For other ways to run Claude in parallel, see:

* [Run agents in parallel](/en/agents): compare agent view with subagents, agent teams, and worktrees
* [Agent teams](/en/agent-teams): coordinate multiple sessions that message each other
* [Claude Code on the web](/en/claude-code-on-the-web): run sessions in a managed cloud environment instead of locally

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Orchestrate teams of Claude Code sessions

> Coordinate multiple Claude Code instances working together as a team, with shared tasks, inter-agent messaging, and centralized management.

<Warning>
  Agent teams are experimental and disabled by default. Enable them by adding `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` to your [settings.json](/en/settings) or environment. Agent teams have [known limitations](#limitations) around session resumption, task coordination, and shutdown behavior.
</Warning>

Agent teams let you coordinate multiple Claude Code instances working together. One session acts as the team lead, coordinating work, assigning tasks, and synthesizing results. Teammates work independently, each in its own context window, and communicate directly with each other.

Unlike [subagents](/en/sub-agents), which run within a single session and can only report back to the main agent, you can also interact with individual teammates directly without going through the lead.

<Note>
  Agent teams require Claude Code v2.1.32 or later. Check your version with `claude --version`.
</Note>

This page covers:

* [When to use agent teams](#when-to-use-agent-teams), including best use cases and how they compare with subagents
* [Starting a team](#start-your-first-agent-team)
* [Controlling teammates](#control-your-agent-team), including display modes, task assignment, and delegation
* [Best practices for parallel work](#best-practices)

## When to use agent teams

Agent teams are most effective for tasks where parallel exploration adds real value. See [use case examples](#use-case-examples) for full scenarios. The strongest use cases are:

* **Research and review**: multiple teammates can investigate different aspects of a problem simultaneously, then share and challenge each other's findings
* **New modules or features**: teammates can each own a separate piece without stepping on each other
* **Debugging with competing hypotheses**: teammates test different theories in parallel and converge on the answer faster
* **Cross-layer coordination**: changes that span frontend, backend, and tests, each owned by a different teammate

Agent teams add coordination overhead and use significantly more tokens than a single session. They work best when teammates can operate independently. For sequential tasks, same-file edits, or work with many dependencies, a single session or [subagents](/en/sub-agents) are more effective.

### Compare with subagents

Both agent teams and [subagents](/en/sub-agents) let you parallelize work, but they operate differently. Choose based on whether your workers need to communicate with each other:

<Frame caption="Subagents only report results back to the main agent and never talk to each other. In agent teams, teammates share a task list, claim work, and communicate directly with each other.">
  <img src="https://mintcdn.com/claude-code/nsvRFSDNfpSU5nT7/images/subagents-vs-agent-teams-light.png?fit=max&auto=format&n=nsvRFSDNfpSU5nT7&q=85&s=2f8db9b4f3705dd3ab931fbe2d96e42a" className="dark:hidden" alt="Diagram comparing subagent and agent team architectures. Subagents are spawned by the main agent, do work, and report results back. Agent teams coordinate through a shared task list, with teammates communicating directly with each other." width="4245" height="1615" data-path="images/subagents-vs-agent-teams-light.png" />

  <img src="https://mintcdn.com/claude-code/nsvRFSDNfpSU5nT7/images/subagents-vs-agent-teams-dark.png?fit=max&auto=format&n=nsvRFSDNfpSU5nT7&q=85&s=d573a037540f2ada6a9ae7d8285b46fd" className="hidden dark:block" alt="Diagram comparing subagent and agent team architectures. Subagents are spawned by the main agent, do work, and report results back. Agent teams coordinate through a shared task list, with teammates communicating directly with each other." width="4245" height="1615" data-path="images/subagents-vs-agent-teams-dark.png" />
</Frame>

|                   | Subagents                                        | Agent teams                                         |
| :---------------- | :----------------------------------------------- | :-------------------------------------------------- |
| **Context**       | Own context window; results return to the caller | Own context window; fully independent               |
| **Communication** | Report results back to the main agent only       | Teammates message each other directly               |
| **Coordination**  | Main agent manages all work                      | Shared task list with self-coordination             |
| **Best for**      | Focused tasks where only the result matters      | Complex work requiring discussion and collaboration |
| **Token cost**    | Lower: results summarized back to main context   | Higher: each teammate is a separate Claude instance |

Use subagents when you need quick, focused workers that report back. Use agent teams when teammates need to share findings, challenge each other, and coordinate on their own.

## Enable agent teams

Agent teams are disabled by default. Enable them by setting the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable to `1`, either in your shell environment or through [settings.json](/en/settings):

```json settings.json theme={null}
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## Start your first agent team

After enabling agent teams, tell Claude to create an agent team and describe the task and the team structure you want in natural language. Claude creates the team, spawns teammates, and coordinates work based on your prompt.

This example works well because the three roles are independent and can explore the problem without waiting on each other:

```text theme={null}
I'm designing a CLI tool that helps developers track TODO comments across
their codebase. Create an agent team to explore this from different angles: one
teammate on UX, one on technical architecture, one playing devil's advocate.
```

From there, Claude creates a team with a [shared task list](/en/interactive-mode#task-list), spawns teammates for each perspective, has them explore the problem, synthesizes findings, and attempts to [clean up the team](#clean-up-the-team) when finished.

The lead's terminal lists all teammates and what they're working on. Use Shift+Down to cycle through teammates and message them directly. After the last teammate, Shift+Down wraps back to the lead.

If you want each teammate in its own split pane, see [Choose a display mode](#choose-a-display-mode).

## Control your agent team

Tell the lead what you want in natural language. It handles team coordination, task assignment, and delegation based on your instructions.

### Choose a display mode

Agent teams support two display modes:

* **In-process**: all teammates run inside your main terminal. Use Shift+Down to cycle through teammates and type to message them directly. Works in any terminal, no extra setup required.
* **Split panes**: each teammate gets its own pane. You can see everyone's output at once and click into a pane to interact directly. Requires tmux, or iTerm2.

<Note>
  `tmux` has known limitations on certain operating systems and traditionally works best on macOS. Using `tmux -CC` in iTerm2 is the suggested entrypoint into `tmux`.
</Note>

The default is `"auto"`, which uses split panes if you're already running inside a tmux session, and in-process otherwise. The `"tmux"` setting enables split-pane mode and auto-detects whether to use tmux or iTerm2 based on your terminal. To override, set [`teammateMode`](/en/settings#available-settings) in `~/.claude/settings.json`:

```json theme={null}
{
  "teammateMode": "in-process"
}
```

To force in-process mode for a single session, pass it as a flag:

```bash theme={null}
claude --teammate-mode in-process
```

Split-pane mode requires either [tmux](https://github.com/tmux/tmux/wiki) or iTerm2 with the [`it2` CLI](https://github.com/mkusaka/it2). To install manually:

* **tmux**: install through your system's package manager. See the [tmux wiki](https://github.com/tmux/tmux/wiki/Installing) for platform-specific instructions.
* **iTerm2**: install the [`it2` CLI](https://github.com/mkusaka/it2), then enable the Python API in **iTerm2 → Settings → General → Magic → Enable Python API**.

### Specify teammates and models

Claude decides the number of teammates to spawn based on your task, or you can specify exactly what you want:

```text theme={null}
Create a team with 4 teammates to refactor these modules in parallel.
Use Sonnet for each teammate.
```

Teammates don't inherit the lead's `/model` selection by default. To change the model used when the prompt doesn't specify one, set **Default teammate model** in `/config`. Pick **Default (leader's model)** to have teammates follow the lead's current model.

### Require plan approval for teammates

For complex or risky tasks, you can require teammates to plan before implementing. The teammate works in read-only plan mode until the lead approves their approach:

```text theme={null}
Spawn an architect teammate to refactor the authentication module.
Require plan approval before they make any changes.
```

When a teammate finishes planning, it sends a plan approval request to the lead. The lead reviews the plan and either approves it or rejects it with feedback. If rejected, the teammate stays in plan mode, revises based on the feedback, and resubmits. Once approved, the teammate exits plan mode and begins implementation.

The lead makes approval decisions autonomously. To influence the lead's judgment, give it criteria in your prompt, such as "only approve plans that include test coverage" or "reject plans that modify the database schema."

### Talk to teammates directly

Each teammate is a full, independent Claude Code session. You can message any teammate directly to give additional instructions, ask follow-up questions, or redirect their approach.

* **In-process mode**: use Shift+Down to cycle through teammates, then type to send them a message. Press Enter to view a teammate's session, then Escape to interrupt their current turn. Press Ctrl+T to toggle the task list.
* **Split-pane mode**: click into a teammate's pane to interact with their session directly. Each teammate has a full view of their own terminal.

### Assign and claim tasks

The shared task list coordinates work across the team. The lead creates tasks and teammates work through them. Tasks have three states: pending, in progress, and completed. Tasks can also depend on other tasks: a pending task with unresolved dependencies cannot be claimed until those dependencies are completed.

The lead can assign tasks explicitly, or teammates can self-claim:

* **Lead assigns**: tell the lead which task to give to which teammate
* **Self-claim**: after finishing a task, a teammate picks up the next unassigned, unblocked task on its own

Task claiming uses file locking to prevent race conditions when multiple teammates try to claim the same task simultaneously.

### Shut down teammates

To gracefully end a teammate's session:

```text theme={null}
Ask the researcher teammate to shut down
```

The lead sends a shutdown request. The teammate can approve, exiting gracefully, or reject with an explanation.

### Clean up the team

When you're done, ask the lead to clean up:

```text theme={null}
Clean up the team
```

This removes the shared team resources. When the lead runs cleanup, it checks for active teammates and fails if any are still running, so shut them down first.

<Warning>
  Always use the lead to clean up. Teammates should not run cleanup because their team context may not resolve correctly, potentially leaving resources in an inconsistent state.
</Warning>

### Enforce quality gates with hooks

Use [hooks](/en/hooks) to enforce rules when teammates finish work or tasks are created or completed:

* [`TeammateIdle`](/en/hooks#teammateidle): runs when a teammate is about to go idle. Exit with code 2 to send feedback and keep the teammate working.
* [`TaskCreated`](/en/hooks#taskcreated): runs when a task is being created. Exit with code 2 to prevent creation and send feedback.
* [`TaskCompleted`](/en/hooks#taskcompleted): runs when a task is being marked complete. Exit with code 2 to prevent completion and send feedback.

## How agent teams work

This section covers the architecture and mechanics behind agent teams. If you want to start using them, see [Control your agent team](#control-your-agent-team) above.

### How Claude starts agent teams

There are two ways agent teams get started:

* **You request a team**: give Claude a task that benefits from parallel work and explicitly ask for an agent team. Claude creates one based on your instructions.
* **Claude proposes a team**: if Claude determines your task would benefit from parallel work, it may suggest creating a team. You confirm before it proceeds.

In both cases, you stay in control. Claude won't create a team without your approval.

### Architecture

An agent team consists of:

| Component     | Role                                                                                       |
| :------------ | :----------------------------------------------------------------------------------------- |
| **Team lead** | The main Claude Code session that creates the team, spawns teammates, and coordinates work |
| **Teammates** | Separate Claude Code instances that each work on assigned tasks                            |
| **Task list** | Shared list of work items that teammates claim and complete                                |
| **Mailbox**   | Messaging system for communication between agents                                          |

See [Choose a display mode](#choose-a-display-mode) for display configuration options. Teammate messages arrive at the lead automatically.

The system manages task dependencies automatically. When a teammate completes a task that other tasks depend on, blocked tasks unblock without manual intervention.

Teams and tasks are stored locally:

* **Team config**: `~/.claude/teams/{team-name}/config.json`
* **Task list**: `~/.claude/tasks/{team-name}/`

Claude Code generates both of these automatically when you create a team and updates them as teammates join, go idle, or leave. The team config holds runtime state such as session IDs and tmux pane IDs, so don't edit it by hand or pre-author it: your changes are overwritten on the next state update.

To define reusable teammate roles, use [subagent definitions](#use-subagent-definitions-for-teammates) instead.

The team config contains a `members` array with each teammate's name, agent ID, and agent type. Teammates can read this file to discover other team members.

There is no project-level equivalent of the team config. A file like `.claude/teams/teams.json` in your project directory is not recognized as configuration; Claude treats it as an ordinary file.

### Use subagent definitions for teammates

When spawning a teammate, you can reference a [subagent](/en/sub-agents) type from any [subagent scope](/en/sub-agents#choose-the-subagent-scope): project, user, plugin, or CLI-defined. This lets you define a role once, such as a security-reviewer or test-runner, and reuse it both as a delegated subagent and as an agent team teammate.

To use a subagent definition, mention it by name when asking Claude to spawn the teammate:

```text theme={null}
Spawn a teammate using the security-reviewer agent type to audit the auth module.
```

The teammate honors that definition's `tools` allowlist and `model`, and the definition's body is appended to the teammate's system prompt as additional instructions rather than replacing it. Team coordination tools such as `SendMessage` and the task management tools are always available to a teammate even when `tools` restricts other tools.

<Note>
  The `skills` and `mcpServers` frontmatter fields in a subagent definition are not applied when that definition runs as a teammate. Teammates load skills and MCP servers from your project and user settings, the same as a regular session.
</Note>

### Permissions

Teammates start with the lead's permission settings. If the lead runs with `--dangerously-skip-permissions`, all teammates do too. After spawning, you can change individual teammate modes, but you can't set per-teammate modes at spawn time.

### Context and communication

Each teammate has its own context window. When spawned, a teammate loads the same project context as a regular session: CLAUDE.md, MCP servers, and skills. It also receives the spawn prompt from the lead. The lead's conversation history does not carry over.

**How teammates share information:**

* **Automatic message delivery**: when teammates send messages, they're delivered automatically to recipients. The lead doesn't need to poll for updates.
* **Idle notifications**: when a teammate finishes and stops, they automatically notify the lead.
* **Shared task list**: all agents can see task status and claim available work.
* **Teammate messaging**: send a message to one specific teammate by name. To reach everyone, send one message per recipient.

The lead assigns every teammate a name when it spawns them, and any teammate can message any other by that name. To get predictable names you can reference in later prompts, tell the lead what to call each teammate in your spawn instruction.

### Token usage

Agent teams use significantly more tokens than a single session. Each teammate has its own context window, and token usage scales with the number of active teammates. For research, review, and new feature work, the extra tokens are usually worthwhile. For routine tasks, a single session is more cost-effective. See [agent team token costs](/en/costs#agent-team-token-costs) for usage guidance.

## Use case examples

These examples show how agent teams handle tasks where parallel exploration adds value.

### Run a parallel code review

A single reviewer tends to gravitate toward one type of issue at a time. Splitting review criteria into independent domains means security, performance, and test coverage all get thorough attention simultaneously. The prompt assigns each teammate a distinct lens so they don't overlap:

```text theme={null}
Create an agent team to review PR #142. Spawn three reviewers:
- One focused on security implications
- One checking performance impact
- One validating test coverage
Have them each review and report findings.
```

Each reviewer works from the same PR but applies a different filter. The lead synthesizes findings across all three after they finish.

### Investigate with competing hypotheses

When the root cause is unclear, a single agent tends to find one plausible explanation and stop looking. The prompt fights this by making teammates explicitly adversarial: each one's job is not only to investigate its own theory but to challenge the others'.

```text theme={null}
Users report the app exits after one message instead of staying connected.
Spawn 5 agent teammates to investigate different hypotheses. Have them talk to
each other to try to disprove each other's theories, like a scientific
debate. Update the findings doc with whatever consensus emerges.
```

The debate structure is the key mechanism here. Sequential investigation suffers from anchoring: once one theory is explored, subsequent investigation is biased toward it.

With multiple independent investigators actively trying to disprove each other, the theory that survives is much more likely to be the actual root cause.

## Best practices

### Give teammates enough context

Teammates load project context automatically, including CLAUDE.md, MCP servers, and skills, but they don't inherit the lead's conversation history. See [Context and communication](#context-and-communication) for details. Include task-specific details in the spawn prompt:

```text theme={null}
Spawn a security reviewer teammate with the prompt: "Review the authentication module
at src/auth/ for security vulnerabilities. Focus on token handling, session
management, and input validation. The app uses JWT tokens stored in
httpOnly cookies. Report any issues with severity ratings."
```

### Choose an appropriate team size

There's no hard limit on the number of teammates, but practical constraints apply:

* **Token costs scale linearly**: each teammate has its own context window and consumes tokens independently. See [agent team token costs](/en/costs#agent-team-token-costs) for details.
* **Coordination overhead increases**: more teammates means more communication, task coordination, and potential for conflicts
* **Diminishing returns**: beyond a certain point, additional teammates don't speed up work proportionally

Start with 3-5 teammates for most workflows. This balances parallel work with manageable coordination. The examples in this guide use 3-5 teammates because that range works well across different task types.

Having 5-6 [tasks](/en/agent-teams#architecture) per teammate keeps everyone productive without excessive context switching. If you have 15 independent tasks, 3 teammates is a good starting point.

Scale up only when the work genuinely benefits from having teammates work simultaneously. Three focused teammates often outperform five scattered ones.

### Size tasks appropriately

* **Too small**: coordination overhead exceeds the benefit
* **Too large**: teammates work too long without check-ins, increasing risk of wasted effort
* **Just right**: self-contained units that produce a clear deliverable, such as a function, a test file, or a review

<Tip>
  The lead breaks work into tasks and assigns them to teammates automatically. If it isn't creating enough tasks, ask it to split the work into smaller pieces. Having 5-6 tasks per teammate keeps everyone productive and lets the lead reassign work if someone gets stuck.
</Tip>

### Wait for teammates to finish

Sometimes the lead starts implementing tasks itself instead of waiting for teammates. If you notice this:

```text theme={null}
Wait for your teammates to complete their tasks before proceeding
```

### Start with research and review

If you're new to agent teams, start with tasks that have clear boundaries and don't require writing code: reviewing a PR, researching a library, or investigating a bug. These tasks show the value of parallel exploration without the coordination challenges that come with parallel implementation.

### Avoid file conflicts

Two teammates editing the same file leads to overwrites. Break the work so each teammate owns a different set of files.

### Monitor and steer

Check in on teammates' progress, redirect approaches that aren't working, and synthesize findings as they come in. Letting a team run unattended for too long increases the risk of wasted effort.

## Troubleshooting

### Teammates not appearing

If teammates aren't appearing after you ask Claude to create a team:

* In in-process mode, teammates may already be running but not visible. Press Shift+Down to cycle through active teammates.
* Check that the task you gave Claude was complex enough to warrant a team. Claude decides whether to spawn teammates based on the task.
* If you explicitly requested split panes, ensure tmux is installed and available in your PATH:
  ```bash theme={null}
  which tmux
  ```
* For iTerm2, verify the `it2` CLI is installed and the Python API is enabled in iTerm2 preferences.

### Too many permission prompts

Teammate permission requests bubble up to the lead, which can create friction. Pre-approve common operations in your [permission settings](/en/permissions) before spawning teammates to reduce interruptions.

### Teammates stopping on errors

Teammates may stop after encountering errors instead of recovering. Check their output using Shift+Down in in-process mode or by clicking the pane in split mode, then either:

* Give them additional instructions directly
* Spawn a replacement teammate to continue the work

### Lead shuts down before work is done

The lead may decide the team is finished before all tasks are actually complete. If this happens, tell it to keep going. You can also tell the lead to wait for teammates to finish before proceeding if it starts doing work instead of delegating.

### Orphaned tmux sessions

If a tmux session persists after the team ends, it may not have been fully cleaned up. List sessions and kill the one created by the team:

```bash theme={null}
tmux ls
tmux kill-session -t <session-name>
```

## Limitations

Agent teams are experimental. Current limitations to be aware of:

* **No session resumption with in-process teammates**: `/resume` and `/rewind` do not restore in-process teammates. After resuming a session, the lead may attempt to message teammates that no longer exist. If this happens, tell the lead to spawn new teammates.
* **Task status can lag**: teammates sometimes fail to mark tasks as completed, which blocks dependent tasks. If a task appears stuck, check whether the work is actually done and update the task status manually or tell the lead to nudge the teammate.
* **Shutdown can be slow**: teammates finish their current request or tool call before shutting down, which can take time.
* **One team at a time**: a lead can only manage one team. Clean up the current team before creating a new one.
* **No nested teams**: teammates cannot spawn their own teams or teammates. Only the lead can manage the team.
* **Lead is fixed**: the session that creates the team is the lead for its lifetime. You can't promote a teammate to lead or transfer leadership.
* **Permissions set at spawn**: all teammates start with the lead's permission mode. You can change individual teammate modes after spawning, but you can't set per-teammate modes at spawn time.
* **Split panes require tmux or iTerm2**: the default in-process mode works in any terminal. Split-pane mode isn't supported in VS Code's integrated terminal, Windows Terminal, or Ghostty.

<Tip>
  **`CLAUDE.md` works normally**: teammates read `CLAUDE.md` files from their working directory. Use this to provide project-specific guidance to all teammates.
</Tip>

## Next steps

Explore related approaches for parallel work and delegation:

* **Lightweight delegation**: [subagents](/en/sub-agents) spawn helper agents for research or verification within your session, better for tasks that don't need inter-agent coordination
* **Manual parallel sessions**: [Git worktrees](/en/worktrees) let you run multiple Claude Code sessions yourself without automated team coordination
* **Compare approaches**: see the [subagent vs agent team](/en/features-overview#compare-similar-features) comparison for a side-by-side breakdown

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Run parallel sessions with worktrees

> Isolate parallel Claude Code sessions in separate git worktrees so changes don't collide. Covers the `--worktree` flag, subagent isolation, `.worktreeinclude`, cleanup, and non-git VCS hooks.

A [git worktree](https://git-scm.com/docs/git-worktree) is a separate working directory with its own files and branch, sharing the same repository history and remote as your main checkout. Running each Claude Code session in its own worktree means edits in one session never touch files in another, so you can have Claude building a feature in one terminal while fixing a bug in a second.

This page covers worktree isolation in the CLI. Everything below assumes a git repository. For other version control systems, see [Non-git version control](#non-git-version-control). The [desktop app](/en/desktop#work-in-parallel-with-sessions) creates a worktree for every new session automatically.

Worktrees are one of several ways to run Claude in parallel. They isolate file edits, while [subagents](/en/sub-agents) and [agent teams](/en/agent-teams) coordinate the work itself. See [Run agents in parallel](/en/agents) to compare the approaches, or skip ahead to [Isolate subagents with worktrees](#isolate-subagents-with-worktrees) to use worktrees and subagents together.

## Start Claude in a worktree

Pass `--worktree` or `-w` to create an isolated worktree and start Claude in it. By default, the worktree is created under `.claude/worktrees/<value>/` at your repository root, on a new branch named `worktree-<value>`:

```bash theme={null}
claude --worktree feature-auth
```

To put worktrees somewhere else, configure a [`WorktreeCreate` hook](#non-git-version-control). Run the command again with a different name in another terminal to start a second isolated session:

```bash theme={null}
claude --worktree bugfix-123
```

If you omit the name, Claude generates one such as `bright-running-fox`:

```bash theme={null}
claude --worktree
```

You can also ask Claude to "work in a worktree" during a session, and it will create one with the [`EnterWorktree`](/en/tools-reference) tool.

Before using `--worktree` in a directory for the first time, accept the workspace trust dialog by running `claude` once in that directory. If trust has not yet been accepted, `--worktree` exits with an error and prompts you to run `claude` in the directory first, including when combined with `-p`.

<Tip>
  Add `.claude/worktrees/` to your `.gitignore` so worktree contents don't appear as untracked files in your main checkout.
</Tip>

### Choose the base branch

Worktrees branch from your repository's default branch, `origin/HEAD`, so they start from a clean tree matching the remote. If no remote is configured or the fetch fails, the worktree falls back to your current local `HEAD`. To always branch from local `HEAD` instead, set `worktree.baseRef` to `"head"` in [settings](/en/settings#worktree-settings). Setting `baseRef` to `"head"` makes new worktrees carry your unpushed commits and feature-branch state, which is useful when isolating subagents that need to operate on in-progress work. The setting accepts only `"fresh"` or `"head"`, not arbitrary git refs:

```json theme={null}
{
  "worktree": {
    "baseRef": "head"
  }
}
```

To branch from a specific pull request, pass the PR number prefixed with `#`, or a full GitHub pull request URL. Claude Code fetches `pull/<number>/head` from `origin` and creates the worktree at `.claude/worktrees/pr-<number>`:

```bash theme={null}
claude --worktree "#1234"
```

For full control over how worktrees are created, configure a [`WorktreeCreate` hook](/en/hooks#worktreecreate), which replaces the default `git worktree` logic entirely.

## Copy gitignored files into worktrees

A worktree is a fresh checkout, so untracked files like `.env` or `.env.local` from your main repository are not present. To copy them automatically when Claude creates a worktree, add a `.worktreeinclude` file to your project root.

The file uses `.gitignore` syntax. Only files that match a pattern and are also gitignored are copied, so tracked files are never duplicated.

This `.worktreeinclude` copies two env files and a secrets config into each new worktree:

```text .worktreeinclude theme={null}
.env
.env.local
config/secrets.json
```

This applies to worktrees created with `--worktree`, [subagent worktrees](#isolate-subagents-with-worktrees), and parallel sessions in the [desktop app](/en/desktop#work-in-parallel-with-sessions).

## Isolate subagents with worktrees

Subagents can run in their own worktrees so parallel edits don't conflict. Ask Claude to "use worktrees for your agents", or set it permanently on a [custom subagent](/en/sub-agents#supported-frontmatter-fields) by adding `isolation: worktree` to the frontmatter. Each subagent gets a temporary worktree that is removed automatically when the subagent finishes without changes.

Subagent worktrees use the same [base branch](#choose-the-base-branch) as `--worktree`, so they branch from your repository's default branch unless `worktree.baseRef` is set to `"head"`.

## Clean up worktrees

When you exit a worktree session, cleanup depends on whether you made changes:

* **No uncommitted changes, no untracked files, and no new commits**: the worktree and its branch are removed automatically. If the session has a [name](/en/sessions#name-your-sessions), Claude prompts instead so you can keep the worktree for later
* **Uncommitted changes, untracked files, or new commits exist**: Claude prompts you to keep or remove the worktree. Keeping preserves the directory and branch so you can return later. Removing deletes the worktree directory and its branch, discarding any uncommitted changes, untracked files, and commits
* **Non-interactive runs**: worktrees created with `--worktree` alongside `-p` are not cleaned up automatically since there is no exit prompt. Remove them with `git worktree remove`

Subagent worktrees orphaned by a crash or interrupted run are removed at startup once they are older than your [`cleanupPeriodDays`](/en/settings#available-settings) setting, provided they have no uncommitted changes, no untracked files, and no unpushed commits. Worktrees you create with `--worktree` are never removed by this sweep.

## Manage worktrees manually

For full control over worktree location and branch configuration, create worktrees with Git directly. This is useful when you need to check out a specific existing branch or place the worktree outside the repository.

Create a worktree on a new branch:

```bash theme={null}
git worktree add ../project-feature-a -b feature-a
```

Create a worktree from an existing branch:

```bash theme={null}
git worktree add ../project-bugfix bugfix-123
```

Start Claude in the worktree:

```bash theme={null}
cd ../project-feature-a && claude
```

List your worktrees:

```bash theme={null}
git worktree list
```

Remove one when you're done with it:

```bash theme={null}
git worktree remove ../project-feature-a
```

See the [Git worktree documentation](https://git-scm.com/docs/git-worktree) for the full command reference. Remember to initialize your development environment in each new worktree: install dependencies, set up virtual environments, or run whatever your project's setup requires.

## Non-git version control

Worktree isolation uses git by default. For SVN, Perforce, Mercurial, or other systems, configure [`WorktreeCreate` and `WorktreeRemove` hooks](/en/hooks#worktreecreate) to provide custom creation and cleanup logic. Because the hook replaces the default git behavior, [`.worktreeinclude`](#copy-gitignored-files-into-worktrees) is not processed when you use `--worktree`. Copy any local configuration files inside your hook script instead.

This `WorktreeCreate` hook reads the worktree name from stdin, checks out a fresh SVN working copy, and prints the directory path so Claude Code can use it as the session's working directory:

```json theme={null}
{
  "hooks": {
    "WorktreeCreate": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'NAME=$(jq -r .name); DIR=\"$HOME/.claude/worktrees/$NAME\"; svn checkout https://svn.example.com/repo/trunk \"$DIR\" >&2 && echo \"$DIR\"'"
          }
        ]
      }
    ]
  }
}
```

Pair it with a `WorktreeRemove` hook to clean up when the session ends. See the [hooks reference](/en/hooks#worktreecreate) for the input schema and a removal example.

## See also

Worktrees handle file isolation. The related pages below cover delegating work into those isolated checkouts and switching between the sessions you create:

* [Subagents](/en/sub-agents): delegate work to isolated agents within a session
* [Agent teams](/en/agent-teams): coordinate multiple Claude sessions automatically
* [Manage sessions](/en/sessions): name, resume, and switch between conversations
* [Desktop parallel sessions](/en/desktop#work-in-parallel-with-sessions): worktree-backed sessions in the desktop app

