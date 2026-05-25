> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Automate workflows with hooks

> Run shell commands automatically when Claude Code edits files, finishes tasks, or needs input. Format code, send notifications, validate commands, and enforce project rules.

Hooks are user-defined shell commands that execute at specific points in Claude Code's lifecycle. They provide deterministic control over Claude Code's behavior, ensuring certain actions always happen rather than relying on the LLM to choose to run them. Use hooks to enforce project rules, automate repetitive tasks, and integrate Claude Code with your existing tools.

For decisions that require judgment rather than deterministic rules, you can also use [prompt-based hooks](#prompt-based-hooks) or [agent-based hooks](#agent-based-hooks) that use a Claude model to evaluate conditions.

For other ways to extend Claude Code, see [skills](/en/skills) for giving Claude additional instructions and executable commands, [subagents](/en/sub-agents) for running tasks in isolated contexts, and [plugins](/en/plugins) for packaging extensions to share across projects.

<Tip>
  This guide covers common use cases and how to get started. For full event schemas, JSON input/output formats, and advanced features like async hooks and MCP tool hooks, see the [Hooks reference](/en/hooks).
</Tip>

## Set up your first hook

To create a hook, add a `hooks` block to a [settings file](#configure-hook-location). This walkthrough creates a desktop notification hook, so you get alerted whenever Claude is waiting for your input instead of watching the terminal.

<Steps>
  <Step title="Add the hook to your settings">
    Open `~/.claude/settings.json` and add a `Notification` hook. The example below uses `osascript` for macOS; see [Get notified when Claude needs input](#get-notified-when-claude-needs-input) for Linux and Windows commands.

    ```json theme={null}
    {
      "hooks": {
        "Notification": [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'"
              }
            ]
          }
        ]
      }
    }
    ```

    If your settings file already has a `hooks` key, add `Notification` as a sibling of the existing event keys rather than replacing the whole object. Each event name is a key inside the single `hooks` object:

    ```json theme={null}
    {
      "hooks": {
        "PostToolUse": [
          {
            "matcher": "Edit|Write",
            "hooks": [{ "type": "command", "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write" }]
          }
        ],
        "Notification": [
          {
            "matcher": "",
            "hooks": [{ "type": "command", "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'" }]
          }
        ]
      }
    }
    ```

    You can also ask Claude to write the hook for you by describing what you want in the CLI.
  </Step>

  <Step title="Verify the configuration">
    Type `/hooks` to open the hooks browser. You'll see a list of all available hook events, with a count next to each event that has hooks configured. Select `Notification` to confirm your new hook appears in the list. Selecting the hook shows its details: the event, matcher, type, source file, and command.
  </Step>

  <Step title="Test the hook">
    Press `Esc` to return to the CLI. Ask Claude to do something that requires permission, then switch away from the terminal. You should receive a desktop notification.
  </Step>
</Steps>

<Tip>
  The `/hooks` menu is read-only. To add, modify, or remove hooks, edit your settings JSON directly or ask Claude to make the change.
</Tip>

## What you can automate

Hooks let you run code at key points in Claude Code's lifecycle: format files after edits, block commands before they execute, send notifications when Claude needs input, inject context at session start, and more. For the full list of hook events, see the [Hooks reference](/en/hooks#hook-lifecycle).

Each example includes a ready-to-use configuration block that you add to a [settings file](#configure-hook-location). The most common patterns:

* [Get notified when Claude needs input](#get-notified-when-claude-needs-input)
* [Auto-format code after edits](#auto-format-code-after-edits)
* [Block edits to protected files](#block-edits-to-protected-files)
* [Re-inject context after compaction](#re-inject-context-after-compaction)
* [Audit configuration changes](#audit-configuration-changes)
* [Reload environment when directory or files change](#reload-environment-when-directory-or-files-change)
* [Auto-approve specific permission prompts](#auto-approve-specific-permission-prompts)

### Get notified when Claude needs input

Get a desktop notification whenever Claude finishes working and needs your input, so you can switch to other tasks without checking the terminal.

This hook uses the `Notification` event, which fires when Claude is waiting for input or permission. Each tab below uses the platform's native notification command. Add this to `~/.claude/settings.json`:

<Tabs>
  <Tab title="macOS">
    ```json theme={null}
    {
      "hooks": {
        "Notification": [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'"
              }
            ]
          }
        ]
      }
    }
    ```

    <Accordion title="If no notification appears">
      `osascript` routes notifications through the built-in Script Editor app. If Script Editor doesn't have notification permission, the command fails silently, and macOS won't prompt you to grant it. Run this in Terminal once to make Script Editor appear in your notification settings:

      ```bash theme={null}
      osascript -e 'display notification "test"'
      ```

      Nothing will appear yet. Open **System Settings > Notifications**, find **Script Editor** in the list, and turn on **Allow Notifications**. Run the command again to confirm the test notification appears.
    </Accordion>
  </Tab>

  <Tab title="Linux">
    ```json theme={null}
    {
      "hooks": {
        "Notification": [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": "notify-send 'Claude Code' 'Claude Code needs your attention'"
              }
            ]
          }
        ]
      }
    }
    ```
  </Tab>

  <Tab title="Windows (PowerShell)">
    ```json theme={null}
    {
      "hooks": {
        "Notification": [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": "powershell.exe -Command \"[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('Claude Code needs your attention', 'Claude Code')\""
              }
            ]
          }
        ]
      }
    }
    ```
  </Tab>
</Tabs>

The empty `matcher` fires on all notification types. To fire only on specific events, set it to one of these values:

| Matcher                | Fires when                                             |
| :--------------------- | :----------------------------------------------------- |
| `permission_prompt`    | Claude needs you to approve a tool use                 |
| `idle_prompt`          | Claude is done and waiting for your next prompt        |
| `auth_success`         | Authentication completes                               |
| `elicitation_dialog`   | An MCP server opens an elicitation form                |
| `elicitation_complete` | An MCP elicitation form is submitted or dismissed      |
| `elicitation_response` | An MCP elicitation response is sent back to the server |

Type `/hooks` and select `Notification` to confirm the hook is registered. For the full event schema, see the [Notification reference](/en/hooks#notification).

### Auto-format code after edits

Automatically run [Prettier](https://prettier.io/) on every file Claude edits, so formatting stays consistent without manual intervention.

This hook uses the `PostToolUse` event with an `Edit|Write` matcher, so it runs only after file-editing tools. The command extracts the edited file path with [`jq`](https://jqlang.github.io/jq/) and passes it to Prettier. Add this to `.claude/settings.json` in your project root:

```json theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write"
          }
        ]
      }
    ]
  }
}
```

<Note>
  The Bash examples on this page use `jq` for JSON parsing. Install it with `brew install jq` (macOS), `apt-get install jq` (Debian/Ubuntu), or see [`jq` downloads](https://jqlang.github.io/jq/download/).
</Note>

### Block edits to protected files

Prevent Claude from modifying sensitive files like `.env`, `package-lock.json`, or anything in `.git/`. Claude receives feedback explaining why the edit was blocked, so it can adjust its approach.

This example uses a separate script file that the hook calls. The script checks the target file path against a list of protected patterns and exits with code 2 to block the edit.

<Steps>
  <Step title="Create the hook script">
    Save this to `.claude/hooks/protect-files.sh`:

    ```bash theme={null}
    #!/bin/bash
    # protect-files.sh

    INPUT=$(cat)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

    PROTECTED_PATTERNS=(".env" "package-lock.json" ".git/")

    for pattern in "${PROTECTED_PATTERNS[@]}"; do
      if [[ "$FILE_PATH" == *"$pattern"* ]]; then
        echo "Blocked: $FILE_PATH matches protected pattern '$pattern'" >&2
        exit 2
      fi
    done

    exit 0
    ```
  </Step>

  <Step title="Make the script executable (macOS/Linux)">
    Hook scripts must be executable for Claude Code to run them:

    ```bash theme={null}
    chmod +x .claude/hooks/protect-files.sh
    ```
  </Step>

  <Step title="Register the hook">
    Add a `PreToolUse` hook to `.claude/settings.json` that runs the script before any `Edit` or `Write` tool call:

    ```json theme={null}
    {
      "hooks": {
        "PreToolUse": [
          {
            "matcher": "Edit|Write",
            "hooks": [
              {
                "type": "command",
                "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh"
              }
            ]
          }
        ]
      }
    }
    ```
  </Step>
</Steps>

### Re-inject context after compaction

When Claude's context window fills up, compaction summarizes the conversation to free space. This can lose important details. Use a `SessionStart` hook with a `compact` matcher to re-inject critical context after every compaction.

Any text your command writes to stdout is added to Claude's context. This example reminds Claude of project conventions and recent work. Add this to `.claude/settings.json` in your project root:

```json theme={null}
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Reminder: use Bun, not npm. Run bun test before committing. Current sprint: auth refactor.'"
          }
        ]
      }
    ]
  }
}
```

You can replace the `echo` with any command that produces dynamic output, like `git log --oneline -5` to show recent commits. For injecting context on every session start, consider using [CLAUDE.md](/en/memory) instead. For environment variables, see [`CLAUDE_ENV_FILE`](/en/hooks#persist-environment-variables) in the reference.

### Audit configuration changes

Track when settings or skills files change during a session. The `ConfigChange` event fires when an external process or editor modifies a configuration file, so you can log changes for compliance or block unauthorized modifications.

This example appends each change to an audit log. Add this to `~/.claude/settings.json`:

```json theme={null}
{
  "hooks": {
    "ConfigChange": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "jq -c '{timestamp: now | todate, source: .source, file: .file_path}' >> ~/claude-config-audit.log"
          }
        ]
      }
    ]
  }
}
```

The matcher filters by configuration type: `user_settings`, `project_settings`, `local_settings`, `policy_settings`, or `skills`. To block a change from taking effect, exit with code 2 or return `{"decision": "block"}`. See the [ConfigChange reference](/en/hooks#configchange) for the full input schema.

### Reload environment when directory or files change

Some projects set different environment variables depending on which directory you are in. Tools like [direnv](https://direnv.net/) do this automatically in your shell, but Claude's Bash tool does not pick up those changes on its own.

Pairing a `SessionStart` hook with a `CwdChanged` hook fixes this. `SessionStart` loads the variables for the directory you launch in, and `CwdChanged` reloads them each time Claude changes directory. Both write to `CLAUDE_ENV_FILE`, which Claude Code runs as a script preamble before each Bash command. Add this to `~/.claude/settings.json`:

```json theme={null}
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "direnv export bash > \"$CLAUDE_ENV_FILE\""
          }
        ]
      }
    ],
    "CwdChanged": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "direnv export bash > \"$CLAUDE_ENV_FILE\""
          }
        ]
      }
    ]
  }
}
```

Run `direnv allow` once in each directory that has an `.envrc` so direnv is permitted to load it. If you use devbox or nix instead of direnv, the same pattern works with `devbox shellenv` or `devbox global shellenv` in place of `direnv export bash`.

To react to specific files instead of every directory change, use `FileChanged` with a `matcher` listing the filenames to watch, separated by `|`. To build the watch list, this value is split into literal filenames rather than evaluated as a regex. See [FileChanged](/en/hooks#filechanged) for how the same value also filters which hook groups run when a file changes. This example watches `.envrc` and `.env` in the working directory:

```json theme={null}
{
  "hooks": {
    "FileChanged": [
      {
        "matcher": ".envrc|.env",
        "hooks": [
          {
            "type": "command",
            "command": "direnv export bash > \"$CLAUDE_ENV_FILE\""
          }
        ]
      }
    ]
  }
}
```

See the [CwdChanged](/en/hooks#cwdchanged) and [FileChanged](/en/hooks#filechanged) reference entries for input schemas, `watchPaths` output, and `CLAUDE_ENV_FILE` details.

### Auto-approve specific permission prompts

Skip the approval dialog for tool calls you always allow. This example auto-approves `ExitPlanMode`, the tool Claude calls when it finishes presenting a plan and asks to proceed, so you aren't prompted every time a plan is ready.

Unlike the exit-code examples above, auto-approval requires your hook to write a JSON decision to stdout. A `PermissionRequest` hook fires when Claude Code is about to show a permission dialog, and returning `"behavior": "allow"` answers it on your behalf.

The matcher scopes the hook to `ExitPlanMode` only, so no other prompts are affected. Add this to `~/.claude/settings.json`:

```json theme={null}
{
  "hooks": {
    "PermissionRequest": [
      {
        "matcher": "ExitPlanMode",
        "hooks": [
          {
            "type": "command",
            "command": "echo '{\"hookSpecificOutput\": {\"hookEventName\": \"PermissionRequest\", \"decision\": {\"behavior\": \"allow\"}}}'"
          }
        ]
      }
    ]
  }
}
```

When the hook approves, Claude Code exits plan mode and restores whatever permission mode was active before you entered plan mode. The transcript shows "Allowed by PermissionRequest hook" where the dialog would have appeared. The hook path always keeps the current conversation: it cannot clear context and start a fresh implementation session the way the dialog can.

To set a specific permission mode instead, your hook's output can include an `updatedPermissions` array with a `setMode` entry. The `mode` value is any permission mode like `default`, `acceptEdits`, or `bypassPermissions`, and `destination: "session"` applies it for the current session only.

<Note>
  `bypassPermissions` only applies if the session was launched with bypass mode already available: `--dangerously-skip-permissions`, `--permission-mode bypassPermissions`, `--allow-dangerously-skip-permissions`, or `permissions.defaultMode: "bypassPermissions"` in settings, and not disabled by [`permissions.disableBypassPermissionsMode`](/en/permissions#managed-settings). It is never persisted as `defaultMode`.
</Note>

To switch the session to `acceptEdits`, your hook writes this JSON to stdout:

```json theme={null}
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow",
      "updatedPermissions": [
        { "type": "setMode", "mode": "acceptEdits", "destination": "session" }
      ]
    }
  }
}
```

Keep the matcher as narrow as possible. Matching on `.*` or leaving the matcher empty would auto-approve every permission prompt, including file writes and shell commands. See the [PermissionRequest reference](/en/hooks#permissionrequest-decision-control) for the full set of decision fields.

## How hooks work

Hook events fire at specific lifecycle points in Claude Code. When an event fires, all matching hooks run in parallel, and identical hook commands are automatically deduplicated. The table below shows each event and when it triggers:

| Event                 | When it fires                                                                                                                                          |
| :-------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SessionStart`        | When a session begins or resumes                                                                                                                       |
| `Setup`               | When you start Claude Code with `--init-only`, or with `--init` or `--maintenance` in `-p` mode. For one-time preparation in CI or scripts             |
| `UserPromptSubmit`    | When you submit a prompt, before Claude processes it                                                                                                   |
| `UserPromptExpansion` | When a user-typed command expands into a prompt, before it reaches Claude. Can block the expansion                                                     |
| `PreToolUse`          | Before a tool call executes. Can block it                                                                                                              |
| `PermissionRequest`   | When a permission dialog appears                                                                                                                       |
| `PermissionDenied`    | When a tool call is denied by the auto mode classifier. Return `{retry: true}` to tell the model it may retry the denied tool call                     |
| `PostToolUse`         | After a tool call succeeds                                                                                                                             |
| `PostToolUseFailure`  | After a tool call fails                                                                                                                                |
| `PostToolBatch`       | After a full batch of parallel tool calls resolves, before the next model call                                                                         |
| `Notification`        | When Claude Code sends a notification                                                                                                                  |
| `SubagentStart`       | When a subagent is spawned                                                                                                                             |
| `SubagentStop`        | When a subagent finishes                                                                                                                               |
| `TaskCreated`         | When a task is being created via `TaskCreate`                                                                                                          |
| `TaskCompleted`       | When a task is being marked as completed                                                                                                               |
| `Stop`                | When Claude finishes responding                                                                                                                        |
| `StopFailure`         | When the turn ends due to an API error. Output and exit code are ignored                                                                               |
| `TeammateIdle`        | When an [agent team](/en/agent-teams) teammate is about to go idle                                                                                     |
| `InstructionsLoaded`  | When a CLAUDE.md or `.claude/rules/*.md` file is loaded into context. Fires at session start and when files are lazily loaded during a session         |
| `ConfigChange`        | When a configuration file changes during a session                                                                                                     |
| `CwdChanged`          | When the working directory changes, for example when Claude executes a `cd` command. Useful for reactive environment management with tools like direnv |
| `FileChanged`         | When a watched file changes on disk. The `matcher` field specifies which filenames to watch                                                            |
| `WorktreeCreate`      | When a worktree is being created via `--worktree` or `isolation: "worktree"`. Replaces default git behavior                                            |
| `WorktreeRemove`      | When a worktree is being removed, either at session exit or when a subagent finishes                                                                   |
| `PreCompact`          | Before context compaction                                                                                                                              |
| `PostCompact`         | After context compaction completes                                                                                                                     |
| `Elicitation`         | When an MCP server requests user input during a tool call                                                                                              |
| `ElicitationResult`   | After a user responds to an MCP elicitation, before the response is sent back to the server                                                            |
| `SessionEnd`          | When a session terminates                                                                                                                              |

Each hook has a `type` that determines how it runs. Most hooks use `"type": "command"`, which runs a shell command. Four other types are available:

* `"type": "http"`: POST event data to a URL. See [HTTP hooks](#http-hooks).
* `"type": "mcp_tool"`: call a tool on an already-connected MCP server. See [MCP tool hooks](/en/hooks#mcp-tool-hook-fields).
* `"type": "prompt"`: single-turn LLM evaluation. See [Prompt-based hooks](#prompt-based-hooks).
* `"type": "agent"`: multi-turn verification with tool access. Agent hooks are experimental and may change. See [Agent-based hooks](#agent-based-hooks).

### Combine results from multiple hooks

When multiple hooks match the same event, every hook's command runs to completion before Claude Code merges the results. One hook returning `deny` does not stop sibling hooks from executing. Don't rely on one hook's `deny` to suppress side effects in another hook.

After all matching hooks finish, Claude Code combines their outputs. For `PreToolUse` permission decisions, the most restrictive answer wins: `deny` overrides `ask`, which overrides `allow`. Text from `additionalContext` is kept from every hook and passed to Claude together.

The example below registers two `PreToolUse` hooks on `Bash`. The first appends every command to a log file and exits 0. The second runs a script that exits 2 to deny when the command contains `rm -rf`:

```json theme={null}
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r .tool_input.command >> ~/.claude/bash.log"
          },
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-rm-rf.sh"
          }
        ]
      }
    ]
  }
}
```

When Claude tries to run `rm -rf /tmp/build`, both hooks execute in parallel. The logging hook writes the command to `~/.claude/bash.log` and exits 0, which reports no decision. The guardrail hook exits 2, which denies the tool call. The deny wins, so Claude Code blocks the command and shows Claude the guardrail's stderr. The log entry is still written because the logging hook already ran.

### Read input and return output

Hooks communicate with Claude Code through stdin, stdout, stderr, and exit codes. When an event fires, Claude Code passes event-specific data as JSON to your script's stdin. Your script reads that data, does its work, and tells Claude Code what to do next via the exit code.

#### Hook input

Every event includes common fields like `session_id` and `cwd`, but each event type adds different data. For example, when Claude runs a Bash command, a `PreToolUse` hook receives something like this on stdin:

```json theme={null}
{
  "session_id": "abc123",          // unique ID for this session
  "cwd": "/Users/sarah/myproject", // working directory when the event fired
  "hook_event_name": "PreToolUse", // which event triggered this hook
  "tool_name": "Bash",             // the tool Claude is about to use
  "tool_input": {                  // the arguments Claude passed to the tool
    "command": "npm test"          // for Bash, this is the shell command
  }
}
```

Your script can parse that JSON and act on any of those fields. `UserPromptSubmit` hooks get the `prompt` text instead, `SessionStart` hooks get the `source` (startup, resume, clear, compact), and so on. See [Common input fields](/en/hooks#common-input-fields) in the reference for shared fields, and each event's section for event-specific schemas.

#### Hook output

Your script tells Claude Code what to do next by writing to stdout or stderr and exiting with a specific code. For example, a `PreToolUse` hook that wants to block a command:

```bash theme={null}
#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

if echo "$COMMAND" | grep -q "drop table"; then
  echo "Blocked: dropping tables is not allowed" >&2  # stderr becomes Claude's feedback
  exit 2                                               # exit 2 = block the action
fi

exit 0  # exit 0 = no decision; the normal permission flow applies
```

The exit code determines what happens next:

* **Exit 0**: the hook reports no objection and the action proceeds normally. For a `PreToolUse` hook this doesn't approve the tool call: the normal [permission flow](/en/permissions) still applies. For `UserPromptSubmit`, `UserPromptExpansion`, and `SessionStart` hooks, anything you write to stdout is added to Claude's context.
* **Exit 2**: the action is blocked. Write a reason to stderr, and Claude receives it as feedback so it can adjust. Some events cannot be blocked: for `SessionStart`, `Setup`, `Notification`, and others, exit 2 shows stderr to the user and execution continues. See [exit code 2 behavior per event](/en/hooks#exit-code-2-behavior-per-event) for the full list.
* **Any other exit code**: the action proceeds. The transcript shows a `<hook name> hook error` notice followed by the first line of stderr; the full stderr goes to the [debug log](/en/hooks#debug-hooks).

#### Structured JSON output

Exit codes only let you block or stay silent. For more control, exit 0 and print a JSON object to stdout instead.

<Note>
  Use exit 2 to block with a stderr message, or exit 0 with JSON for structured control. Don't mix them: Claude Code ignores JSON when you exit 2.
</Note>

For example, a `PreToolUse` hook can deny a tool call and tell Claude why, or escalate it to the user for approval:

```json theme={null}
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Use rg instead of grep for better performance"
  }
}
```

With `"deny"`, Claude Code cancels the tool call and feeds `permissionDecisionReason` back to Claude. These `permissionDecision` values are specific to `PreToolUse`:

* `"allow"`: skip the interactive permission prompt. Deny and ask rules, including enterprise managed deny lists, still apply
* `"deny"`: cancel the tool call and send the reason to Claude
* `"ask"`: show the permission prompt to the user as normal

A fourth value, `"defer"`, is available in [non-interactive mode](/en/headless) with the `-p` flag. It exits the process with the tool call preserved so an Agent SDK wrapper can collect input and resume. See [Defer a tool call for later](/en/hooks#defer-a-tool-call-for-later) in the reference.

Returning `"allow"` skips the interactive prompt but does not override [permission rules](/en/permissions#manage-permissions). If a deny rule matches the tool call, the call is blocked even when your hook returns `"allow"`. If an ask rule matches, the user is still prompted. This means deny rules from any settings scope, including [managed settings](/en/settings#settings-files), always take precedence over hook approvals.

Other events use different decision patterns. For example, `PostToolUse` and `Stop` hooks use a top-level `decision: "block"` field, while `PermissionRequest` uses `hookSpecificOutput.decision.behavior`. See the [summary table](/en/hooks#decision-control) in the reference for a full breakdown by event.

For `UserPromptSubmit` hooks, use `additionalContext` instead to inject text into Claude's context. Prompt-based hooks (`type: "prompt"`) handle output differently: see [Prompt-based hooks](#prompt-based-hooks).

### Filter hooks with matchers

Without a matcher, a hook fires on every occurrence of its event. Matchers let you narrow that down. For example, if you want to run a formatter only after file edits (not after every tool call), add a matcher to your `PostToolUse` hook:

```json theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "prettier --write ..." }
        ]
      }
    ]
  }
}
```

The `"Edit|Write"` matcher fires only when Claude uses the `Edit` or `Write` tool, not when it uses `Bash`, `Read`, or any other tool. See [Matcher patterns](/en/hooks#matcher-patterns) for how plain names and regular expressions are evaluated.

<Note>
  Claude can also create or modify files by running shell commands through the `Bash` tool. If your hook must see every file change, such as for compliance scanning or audit logging, add a [`Stop`](/en/hooks#stop) hook that scans the working tree once per turn. For per-call coverage instead, also match `Bash` and have your script list modified and untracked files with `git status --porcelain`.
</Note>

Each event type matches on a specific field:

| Event                                                                                                                                         | What the matcher filters                                              | Example matcher values                                                                                                                                                |
| :-------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied`                                                    | tool name                                                             | `Bash`, `Edit\|Write`, `mcp__.*`                                                                                                                                      |
| `SessionStart`                                                                                                                                | how the session started                                               | `startup`, `resume`, `clear`, `compact`                                                                                                                               |
| `Setup`                                                                                                                                       | which CLI flag triggered setup                                        | `init`, `maintenance`                                                                                                                                                 |
| `SessionEnd`                                                                                                                                  | why the session ended                                                 | `clear`, `resume`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other`                                                                              |
| `Notification`                                                                                                                                | notification type                                                     | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`, `elicitation_complete`, `elicitation_response`                                              |
| `SubagentStart`                                                                                                                               | agent type                                                            | `general-purpose`, `Explore`, `Plan`, or custom agent names                                                                                                           |
| `PreCompact`, `PostCompact`                                                                                                                   | what triggered compaction                                             | `manual`, `auto`                                                                                                                                                      |
| `SubagentStop`                                                                                                                                | agent type                                                            | same values as `SubagentStart`                                                                                                                                        |
| `ConfigChange`                                                                                                                                | configuration source                                                  | `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills`                                                                                    |
| `StopFailure`                                                                                                                                 | error type                                                            | `rate_limit`, `authentication_failed`, `oauth_org_not_allowed`, `billing_error`, `invalid_request`, `model_not_found`, `server_error`, `max_output_tokens`, `unknown` |
| `InstructionsLoaded`                                                                                                                          | load reason                                                           | `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact`                                                                                          |
| `Elicitation`                                                                                                                                 | MCP server name                                                       | your configured MCP server names                                                                                                                                      |
| `ElicitationResult`                                                                                                                           | MCP server name                                                       | same values as `Elicitation`                                                                                                                                          |
| `FileChanged`                                                                                                                                 | literal filenames to watch (see [FileChanged](/en/hooks#filechanged)) | `.envrc\|.env`                                                                                                                                                        |
| `UserPromptExpansion`                                                                                                                         | command name                                                          | your skill or command names                                                                                                                                           |
| `UserPromptSubmit`, `PostToolBatch`, `Stop`, `TeammateIdle`, `TaskCreated`, `TaskCompleted`, `WorktreeCreate`, `WorktreeRemove`, `CwdChanged` | no matcher support                                                    | always fires on every occurrence                                                                                                                                      |

A few more examples showing matchers on different event types:

<Tabs>
  <Tab title="Log every Bash command">
    Match only `Bash` tool calls and log each command to a file. The `PostToolUse` event fires after the command completes, so `tool_input.command` contains what ran. The hook receives the event data as JSON on stdin, and `jq -r '.tool_input.command'` extracts just the command string, which `>>` appends to the log file:

    ```json theme={null}
    {
      "hooks": {
        "PostToolUse": [
          {
            "matcher": "Bash",
            "hooks": [
              {
                "type": "command",
                "command": "jq -r '.tool_input.command' >> ~/.claude/command-log.txt"
              }
            ]
          }
        ]
      }
    }
    ```
  </Tab>

  <Tab title="Match MCP tools">
    MCP tools use a different naming convention than built-in tools: `mcp__<server>__<tool>`, where `<server>` is the MCP server name and `<tool>` is the tool it provides. For example, `mcp__github__search_repositories` or `mcp__filesystem__read_file`. Use a regex matcher to target all tools from a specific server, or match across servers with a pattern like `mcp__.*__write.*`. See [Match MCP tools](/en/hooks#match-mcp-tools) in the reference for the full list of examples.

    The command below extracts the tool name from the hook's JSON input with `jq` and writes it to stderr. Writing to stderr keeps stdout clean for JSON output and sends the message to the [debug log](/en/hooks#debug-hooks):

    ```json theme={null}
    {
      "hooks": {
        "PreToolUse": [
          {
            "matcher": "mcp__github__.*",
            "hooks": [
              {
                "type": "command",
                "command": "echo \"GitHub tool called: $(jq -r '.tool_name')\" >&2"
              }
            ]
          }
        ]
      }
    }
    ```
  </Tab>

  <Tab title="Clean up on session end">
    The `SessionEnd` event supports matchers on the reason the session ended. This hook only fires on `clear` (when you run `/clear`), not on normal exits:

    ```json theme={null}
    {
      "hooks": {
        "SessionEnd": [
          {
            "matcher": "clear",
            "hooks": [
              {
                "type": "command",
                "command": "rm -f /tmp/claude-scratch-*.txt"
              }
            ]
          }
        ]
      }
    }
    ```
  </Tab>
</Tabs>

For full matcher syntax, see the [Hooks reference](/en/hooks#configuration).

#### Filter by tool name and arguments with the `if` field

<Note>
  The `if` field requires Claude Code v2.1.85 or later. Earlier versions ignore it and run the hook on every matched call.
</Note>

The `if` field uses [permission rule syntax](/en/permissions) to filter hooks by tool name and arguments together, so the hook process only spawns when the tool call matches, or when a Bash command is too complex to parse. This goes beyond `matcher`, which filters at the group level by tool name only.

For example, to run a hook only when Claude uses `git` commands rather than all Bash commands:

```json theme={null}
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(git *)",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/check-git-policy.sh"
          }
        ]
      }
    ]
  }
}
```

The hook process only spawns when a subcommand of the Bash command matches `git *`, or when the command is too complex to parse into subcommands. For compound commands like `npm test && git push`, Claude Code evaluates each subcommand and fires the hook because `git push` matches. The `if` field accepts the same patterns as permission rules: `"Bash(git *)"`, `"Edit(*.ts)"`, and so on. To match multiple tool names, use separate handlers each with its own `if` value, or match at the `matcher` level where pipe alternation is supported.

`if` only works on tool events: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, and `PermissionDenied`. Adding it to any other event prevents the hook from running.

### Configure hook location

Where you add a hook determines its scope:

| Location                                                   | Scope                              | Shareable                          |
| :--------------------------------------------------------- | :--------------------------------- | :--------------------------------- |
| `~/.claude/settings.json`                                  | All your projects                  | No, local to your machine          |
| `.claude/settings.json`                                    | Single project                     | Yes, can be committed to the repo  |
| `.claude/settings.local.json`                              | Single project                     | No, gitignored                     |
| Managed policy settings                                    | Organization-wide                  | Yes, admin-controlled              |
| [Plugin](/en/plugins) `hooks/hooks.json`                   | When plugin is enabled             | Yes, bundled with the plugin       |
| [Skill](/en/skills) or [agent](/en/sub-agents) frontmatter | While the skill or agent is active | Yes, defined in the component file |

Run [`/hooks`](/en/hooks#the-hooks-menu) in Claude Code to browse all configured hooks grouped by event. To disable hooks, set `"disableAllHooks": true` in your settings file. Hooks configured in managed settings still run unless `disableAllHooks` is also set there.

If you edit settings files directly while Claude Code is running, the file watcher normally picks up hook changes automatically.

## Prompt-based hooks

For decisions that require judgment rather than deterministic rules, use `type: "prompt"` hooks. Instead of running a shell command, Claude Code sends your prompt and the hook's input data to a Claude model (Haiku by default) to make the decision. You can specify a different model with the `model` field if you need more capability.

The model's only job is to return a yes/no decision as JSON:

* `"ok": true`: the action proceeds
* `"ok": false`: what happens depends on the event:
  * `Stop` and `SubagentStop`: the `reason` is fed back to Claude so it keeps working
  * `PreToolUse`: the tool call is denied and the `reason` is returned to Claude as the tool error, so it can adjust and continue
  * `PostToolUse`, `PostToolBatch`, `UserPromptSubmit`, and `UserPromptExpansion`: the turn ends and the `reason` appears in the chat as a warning line

This example uses a `Stop` hook to ask the model whether all requested tasks are complete. If the model returns `"ok": false`, Claude keeps working and uses the `reason` as its next instruction:

```json theme={null}
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if all tasks are complete. If not, respond with {\"ok\": false, \"reason\": \"what remains to be done\"}."
          }
        ]
      }
    ]
  }
}
```

For full configuration options, see [Prompt-based hooks](/en/hooks#prompt-based-hooks) in the reference.

## Agent-based hooks

<Warning>
  Agent hooks are experimental. Behavior and configuration may change in future releases. For production workflows, prefer [command hooks](/en/hooks#command-hook-fields).
</Warning>

When verification requires inspecting files or running commands, use `type: "agent"` hooks. Unlike prompt hooks which make a single LLM call, agent hooks spawn a subagent that can read files, search code, and use other tools to verify conditions before returning a decision.

Agent hooks use the same `"ok"` / `"reason"` response format as prompt hooks, but with a longer default timeout of 60 seconds and up to 50 tool-use turns.

This example verifies that tests pass before allowing Claude to stop:

```json theme={null}
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify that all unit tests pass. Run the test suite and check the results. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

Use prompt hooks when the hook input data alone is enough to make a decision. Use agent hooks when you need to verify something against the actual state of the codebase.

For full configuration options, see [Agent-based hooks](/en/hooks#agent-based-hooks) in the reference.

## HTTP hooks

Use `type: "http"` hooks to POST event data to an HTTP endpoint instead of running a shell command. The endpoint receives the same JSON that a command hook would receive on stdin, and returns results through the HTTP response body using the same JSON format.

HTTP hooks are useful when you want a web server, cloud function, or external service to handle hook logic: for example, a shared audit service that logs tool use events across a team.

This example posts every tool use to a local logging service:

```json theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "http",
            "url": "http://localhost:8080/hooks/tool-use",
            "headers": {
              "Authorization": "Bearer $MY_TOKEN"
            },
            "allowedEnvVars": ["MY_TOKEN"]
          }
        ]
      }
    ]
  }
}
```

The endpoint should return a JSON response body using the same [output format](/en/hooks#json-output) as command hooks. To block a tool call, return a 2xx response with the appropriate `hookSpecificOutput` fields. HTTP status codes alone cannot block actions.

Header values support environment variable interpolation using `$VAR_NAME` or `${VAR_NAME}` syntax. Only variables listed in the `allowedEnvVars` array are resolved; all other `$VAR` references remain empty.

For full configuration options and response handling, see [HTTP hooks](/en/hooks#http-hook-fields) in the reference.

## Limitations and troubleshooting

### Limitations

* Command hooks communicate through stdout, stderr, and exit codes only. They cannot trigger `/` commands or tool calls. Text returned via `additionalContext` is injected as a system reminder that Claude reads as plain text. HTTP hooks communicate through the response body instead.
* Hook timeouts vary by type. Override per hook with the `timeout` field in seconds.
  * `command`, `http`, `mcp_tool`: 10 minutes. `UserPromptSubmit` lowers these to 30 seconds.
  * `prompt`: 30 seconds.
  * `agent`: 60 seconds.
* `PostToolUse` hooks cannot undo actions since the tool has already executed.
* `PermissionRequest` hooks do not fire in [non-interactive mode](/en/headless) (`-p`). Use `PreToolUse` hooks for automated permission decisions.
* `Stop` hooks fire whenever Claude finishes responding, not only at task completion. They do not fire on user interrupts. API errors fire [StopFailure](/en/hooks#stopfailure) instead.
* When multiple PreToolUse hooks return [`updatedInput`](/en/hooks#pretooluse) to rewrite a tool's arguments, the last one to finish wins. Since hooks run in parallel, the order is non-deterministic. Avoid having more than one hook modify the same tool's input.

### Hooks and permission modes

PreToolUse hooks fire before any permission-mode check. A hook that returns `permissionDecision: "deny"` blocks the tool even in `bypassPermissions` mode or with `--dangerously-skip-permissions`. This lets you enforce policy that users cannot bypass by changing their permission mode.

The reverse is not true: a hook returning `"allow"` does not bypass deny rules from settings. Hooks can tighten restrictions but not loosen them past what permission rules allow.

### Hook not firing

The hook is configured but never executes.

* Run `/hooks` and confirm the hook appears under the correct event
* Check that the matcher pattern matches the tool name exactly (matchers are case-sensitive)
* Verify you're triggering the right event type (e.g., `PreToolUse` fires before tool execution, `PostToolUse` fires after)
* If using `PermissionRequest` hooks in non-interactive mode (`-p`), switch to `PreToolUse` instead

### Hook error in output

You see a message like "PreToolUse hook error: ..." in the transcript.

* Your script exited with a non-zero code unexpectedly. Test it manually by piping sample JSON:
  ```bash theme={null}
  echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./my-hook.sh
  echo $?  # Check the exit code
  ```
* If you see "command not found", use absolute paths or `${CLAUDE_PROJECT_DIR}` to reference scripts. To avoid shell quoting entirely, add `"args": []` to switch to [exec form](/en/hooks#exec-form-and-shell-form), which spawns the script directly without a shell
* If you see "jq: command not found", install `jq` or use Python/Node.js for JSON parsing
* If the script isn't running at all, make it executable: `chmod +x ./my-hook.sh`

### `/hooks` shows no hooks configured

You edited a settings file but the hooks don't appear in the menu.

* File edits are normally picked up automatically. If they haven't appeared after a few seconds, the file watcher may have missed the change: restart your session to force a reload.
* Verify your JSON is valid (trailing commas and comments are not allowed)
* Confirm the settings file is in the correct location: `.claude/settings.json` for project hooks, `~/.claude/settings.json` for global hooks

### Stop hook hits the block cap

Claude keeps working instead of stopping, then ends the turn with a warning that the Stop hook blocked too many consecutive times.

Claude Code overrides a Stop hook after it blocks 8 times in a row without progress. Your hook script needs to check whether it already triggered a continuation. Parse the `stop_hook_active` field from the JSON input and exit early if it's `true`:

```bash theme={null}
#!/bin/bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0  # Allow Claude to stop
fi
# ... rest of your hook logic
```

If your hook legitimately needs more than eight iterations to converge, raise the cap with [`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`](/en/env-vars).

### JSON validation failed

Claude Code shows a JSON parsing error even though your hook script outputs valid JSON.

When Claude Code runs a shell-form command hook (one without `args`), it spawns `sh -c` on macOS and Linux or Git Bash on Windows by default. This shell is non-interactive, but Git Bash and some configurations (such as `BASH_ENV` pointing at `~/.bashrc`) still source your profile. If that profile contains unconditional `echo` statements, the output gets prepended to your hook's JSON:

```text theme={null}
Shell ready on arm64
{"decision": "block", "reason": "Not allowed"}
```

Claude Code tries to parse this as JSON and fails. To fix this, wrap echo statements in your shell profile so they only run in interactive shells:

```bash theme={null}
# In ~/.zshrc or ~/.bashrc
if [[ $- == *i* ]]; then
  echo "Shell ready"
fi
```

The `$-` variable contains shell flags, and `i` means interactive. Hooks run in non-interactive shells, so the echo is skipped.

### Debug techniques

The transcript view, toggled with `Ctrl+O`, shows a one-line summary for each hook that fired: success is silent, blocking errors show stderr, and non-blocking errors show a `<hook name> hook error` notice followed by the first line of stderr.

For full execution details including which hooks matched, their exit codes, stdout, and stderr, read the debug log. Start Claude Code with `claude --debug-file /tmp/claude.log` to write to a known path, then `tail -f /tmp/claude.log` in another terminal. If you started without that flag, run `/debug` mid-session to enable logging and find the log path.

## Learn more

* [Hooks reference](/en/hooks): full event schemas, JSON output format, async hooks, and MCP tool hooks
* [Security considerations](/en/hooks#security-considerations): review before deploying hooks in shared or production environments
* [Bash command validator example](https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py): complete reference implementation

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Push events into a running session with channels

> Use channels to push messages, alerts, and webhooks into your Claude Code session from an MCP server. Forward CI results, chat messages, and monitoring events so Claude can react while you're away.

<Note>
  Channels are in [research preview](#research-preview) and require Claude Code v2.1.80 or later. They require Anthropic authentication through claude.ai or a Console API key, and are not available on Amazon Bedrock, Google Vertex AI, or Microsoft Foundry. Team and Enterprise organizations must [explicitly enable them](#enterprise-controls).
</Note>

A channel is an MCP server that pushes events into your running Claude Code session, so Claude can react to things that happen while you're not at the terminal. Channels can be two-way: Claude reads the event and replies back through the same channel, like a chat bridge. Events only arrive while the session is open, so for an always-on setup you run Claude in a background process or persistent terminal.

Unlike integrations that spawn a fresh cloud session or wait to be polled, the event arrives in the session you already have open: see [how channels compare](#how-channels-compare).

You install a channel as a plugin and configure it with your own credentials. Telegram, Discord, and iMessage are included in the research preview.

When Claude replies through a channel, you see the inbound message in your terminal but not the reply text. The terminal shows the tool call and a confirmation (like "sent"), and the actual reply appears on the other platform.

This page covers:

* [Supported channels](#supported-channels): Telegram, Discord, and iMessage setup
* [Install and run a channel](#quickstart) with fakechat, a localhost demo
* [Who can push messages](#security): sender allowlists and how you pair
* [Enable channels for your organization](#enterprise-controls) if you manage a Team, Enterprise, or Console org
* [How channels compare](#how-channels-compare) to web sessions, Slack, MCP, and Remote Control

To build your own channel, see the [Channels reference](/en/channels-reference).

## Supported channels

Each supported channel is a plugin that requires [Bun](https://bun.sh). For a hands-on demo of the plugin flow before connecting a real platform, try the [fakechat quickstart](#quickstart).

<Tabs>
  <Tab title="Telegram">
    View the full [Telegram plugin source](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/telegram).

    <Steps>
      <Step title="Create a Telegram bot">
        Open [BotFather](https://t.me/BotFather) in Telegram and send `/newbot`. Give it a display name and a unique username ending in `bot`. Copy the token BotFather returns.
      </Step>

      <Step title="Install the plugin">
        In Claude Code, run:

        ```
        /plugin install telegram@claude-plugins-official
        ```

        If Claude Code reports that the plugin is not found in any marketplace, your marketplace is either missing or outdated. Run `/plugin marketplace update claude-plugins-official` to refresh it, or `/plugin marketplace add anthropics/claude-plugins-official` if you haven't added it before. Then retry the install.

        After installing, run `/reload-plugins` to activate the plugin's configure command.
      </Step>

      <Step title="Configure your token">
        Run the configure command with the token from BotFather:

        ```
        /telegram:configure <token>
        ```

        This saves it to `~/.claude/channels/telegram/.env`. You can also set `TELEGRAM_BOT_TOKEN` in your shell environment before launching Claude Code.
      </Step>

      <Step title="Restart with channels enabled">
        Exit Claude Code and restart with the channel flag. This starts the Telegram plugin, which begins polling for messages from your bot:

        ```bash theme={null}
        claude --channels plugin:telegram@claude-plugins-official
        ```
      </Step>

      <Step title="Pair your account">
        Open Telegram and send any message to your bot. The bot replies with a pairing code.

        <Note>If your bot doesn't respond, make sure Claude Code is running with `--channels` from the previous step. The bot can only reply while the channel is active.</Note>

        Back in Claude Code, run:

        ```
        /telegram:access pair <code>
        ```

        Then lock down access so only your account can send messages:

        ```
        /telegram:access policy allowlist
        ```
      </Step>
    </Steps>
  </Tab>

  <Tab title="Discord">
    View the full [Discord plugin source](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/discord).

    <Steps>
      <Step title="Create a Discord bot">
        Go to the [Discord Developer Portal](https://discord.com/developers/applications), click **New Application**, and name it. In the **Bot** section, create a username, then click **Reset Token** and copy the token.
      </Step>

      <Step title="Enable Message Content Intent">
        In your bot's settings, scroll to **Privileged Gateway Intents** and enable **Message Content Intent**.
      </Step>

      <Step title="Invite the bot to your server">
        Go to **OAuth2 > URL Generator**. Select the `bot` scope and enable these permissions:

        * View Channels
        * Send Messages
        * Send Messages in Threads
        * Read Message History
        * Attach Files
        * Add Reactions

        Open the generated URL to add the bot to your server.
      </Step>

      <Step title="Install the plugin">
        In Claude Code, run:

        ```
        /plugin install discord@claude-plugins-official
        ```

        If Claude Code reports that the plugin is not found in any marketplace, your marketplace is either missing or outdated. Run `/plugin marketplace update claude-plugins-official` to refresh it, or `/plugin marketplace add anthropics/claude-plugins-official` if you haven't added it before. Then retry the install.

        After installing, run `/reload-plugins` to activate the plugin's configure command.
      </Step>

      <Step title="Configure your token">
        Run the configure command with the bot token you copied:

        ```
        /discord:configure <token>
        ```

        This saves it to `~/.claude/channels/discord/.env`. You can also set `DISCORD_BOT_TOKEN` in your shell environment before launching Claude Code.
      </Step>

      <Step title="Restart with channels enabled">
        Exit Claude Code and restart with the channel flag. This connects the Discord plugin so your bot can receive and respond to messages:

        ```bash theme={null}
        claude --channels plugin:discord@claude-plugins-official
        ```
      </Step>

      <Step title="Pair your account">
        DM your bot on Discord. The bot replies with a pairing code.

        <Note>If your bot doesn't respond, make sure Claude Code is running with `--channels` from the previous step. The bot can only reply while the channel is active.</Note>

        Back in Claude Code, run:

        ```
        /discord:access pair <code>
        ```

        Then lock down access so only your account can send messages:

        ```
        /discord:access policy allowlist
        ```
      </Step>
    </Steps>
  </Tab>

  <Tab title="iMessage">
    View the full [iMessage plugin source](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/imessage).

    The iMessage channel reads your Messages database directly and sends replies through AppleScript. It requires macOS and needs no bot token or external service.

    <Steps>
      <Step title="Grant Full Disk Access">
        The Messages database at `~/Library/Messages/chat.db` is protected by macOS. The first time the server reads it, macOS prompts for access: click **Allow**. The prompt names whichever app launched Bun, such as Terminal, iTerm, or your IDE.

        If the prompt doesn't appear or you clicked Don't Allow, grant access manually under **System Settings > Privacy & Security > Full Disk Access** and add your terminal. Without this, the server exits immediately with `authorization denied`.
      </Step>

      <Step title="Install the plugin">
        In Claude Code, run:

        ```
        /plugin install imessage@claude-plugins-official
        ```

        If Claude Code reports that the plugin is not found in any marketplace, your marketplace is either missing or outdated. Run `/plugin marketplace update claude-plugins-official` to refresh it, or `/plugin marketplace add anthropics/claude-plugins-official` if you haven't added it before. Then retry the install.
      </Step>

      <Step title="Restart with channels enabled">
        Exit Claude Code and restart with the channel flag:

        ```bash theme={null}
        claude --channels plugin:imessage@claude-plugins-official
        ```
      </Step>

      <Step title="Text yourself">
        Open Messages on any device signed into your Apple ID and send a message to yourself. It reaches Claude immediately: self-chat bypasses access control with no setup.

        <Note>The first reply Claude sends triggers a macOS Automation prompt asking if your terminal can control Messages. Click **OK**.</Note>
      </Step>

      <Step title="Allow other senders">
        By default, only your own messages pass through. To let another contact reach Claude, add their handle:

        ```
        /imessage:access allow +15551234567
        ```

        Handles are phone numbers in `+country` format or Apple ID emails like `user@example.com`.
      </Step>
    </Steps>
  </Tab>
</Tabs>

You can also [build your own channel](/en/channels-reference) for systems that don't have a plugin yet.

## Quickstart

Fakechat is an officially supported demo channel that runs a chat UI on localhost, with nothing to authenticate and no external service to configure.

Once you install and enable fakechat, you can type in the browser and the message arrives in your Claude Code session. Claude replies, and the reply shows up back in the browser. After you've tested the fakechat interface, try out [Telegram](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/telegram), [Discord](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/discord), or [iMessage](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/imessage).

To try the fakechat demo, you'll need:

* Claude Code [installed and authenticated](/en/quickstart#step-1-install-claude-code) with a claude.ai account or a Claude Console API key
* [Bun](https://bun.sh) installed. The pre-built channel plugins are Bun scripts. Check with `bun --version`; if that fails, [install Bun](https://bun.sh/docs/installation).
* **Team, Enterprise, or managed Console org**: your admin must [enable channels](#enterprise-controls) in managed settings

<Steps>
  <Step title="Install the fakechat channel plugin">
    Start a Claude Code session and run the install command:

    ```text theme={null}
    /plugin install fakechat@claude-plugins-official
    ```

    If Claude Code reports that the plugin is not found in any marketplace, your marketplace is either missing or outdated. Run `/plugin marketplace update claude-plugins-official` to refresh it, or `/plugin marketplace add anthropics/claude-plugins-official` if you haven't added it before. Then retry the install.
  </Step>

  <Step title="Restart with the channel enabled">
    Exit Claude Code, then restart with `--channels` and pass the fakechat plugin you installed:

    ```bash theme={null}
    claude --channels plugin:fakechat@claude-plugins-official
    ```

    The fakechat server starts automatically.

    <Tip>
      You can pass several plugins to `--channels`, space-separated.
    </Tip>
  </Step>

  <Step title="Push a message in">
    Open the fakechat UI at [http://localhost:8787](http://localhost:8787) and type a message:

    ```text theme={null}
    hey, what's in my working directory?
    ```

    The message arrives in your Claude Code session as a `<channel source="fakechat">` event. Claude reads it, does the work, and calls fakechat's `reply` tool. The answer shows up in the chat UI.
  </Step>
</Steps>

If Claude hits a permission prompt while you're away from the terminal, the session pauses until you respond. Channel servers that declare the [permission relay capability](/en/channels-reference#relay-permission-prompts) can forward these prompts to you so you can approve or deny remotely. For unattended use, [`--dangerously-skip-permissions`](/en/permission-modes#skip-all-checks-with-bypasspermissions-mode) bypasses prompts entirely, but only use it in environments you trust.

When you run channels in non-interactive mode with `-p`, tools that need terminal input, such as multiple-choice questions and plan mode approval, are disabled so the session never stalls waiting for input.

## Security

Every approved channel plugin maintains a sender allowlist: only IDs you've added can push messages, and everyone else is silently dropped.

Telegram and Discord bootstrap the list by pairing:

1. Find your bot in Telegram or Discord and send it any message
2. The bot replies with a pairing code
3. In your Claude Code session, approve the code when prompted
4. Your sender ID is added to the allowlist

iMessage works differently: texting yourself bypasses the gate automatically, and you add other contacts by handle with `/imessage:access allow`.

On top of that, you control which servers are enabled each session with `--channels`, and your organization controls availability with [`channelsEnabled`](#enterprise-controls) on claude.ai Team and Enterprise plans and on Console organizations that deploy managed settings.

Being in `.mcp.json` isn't enough to push messages: a server also has to be named in `--channels`.

The allowlist also gates [permission relay](/en/channels-reference#relay-permission-prompts) if the channel declares it. Anyone who can reply through the channel can approve or deny tool use in your session, so only allowlist senders you trust with that authority.

## Enterprise controls

Admins control availability through two [managed settings](/en/settings) that users cannot override. The default depends on how you authenticate:

* **claude.ai Team and Enterprise**: channels are blocked until an admin enables them.
* **Anthropic Console with API key authentication**: channels are permitted by default. You only need this setting if your organization deploys managed settings.

In all cases, no channel runs until a user opts it in for the session with `--channels`.

| Setting                 | Purpose                                                                                                                                                                                                                                                     | When not configured                                                                                                                                                                    |
| :---------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `channelsEnabled`       | Master switch. Must be `true` for any channel to deliver messages. Set via the [claude.ai Admin console](https://claude.ai/admin-settings/claude-code) toggle or directly in managed settings. Blocks all channels including the development flag when off. | claude.ai Team and Enterprise: channels blocked. Console: channels allowed unless your organization deploys managed settings, in which case channels are blocked until this key is set |
| `allowedChannelPlugins` | Which plugins can register once channels are enabled. Replaces the Anthropic-maintained list when set. Only applies when `channelsEnabled` is `true`.                                                                                                       | Anthropic default list applies                                                                                                                                                         |

Pro and Max users without an organization skip these checks entirely: channels are available and users opt in per session with `--channels`.

### Enable channels for your organization

Admins can enable channels from [**claude.ai → Admin settings → Claude Code → Channels**](https://claude.ai/admin-settings/claude-code), or by setting `channelsEnabled` to `true` in managed settings.

Once enabled, users in your organization can use `--channels` to opt channel servers into individual sessions. If the setting is disabled or unset, the MCP server still connects and its tools work, but channel messages won't arrive. A startup warning tells the user to have an admin enable the setting.

### Restrict which channel plugins can run

By default, any plugin on the Anthropic-maintained allowlist can register as a channel. Admins on Team and Enterprise plans can replace that allowlist with their own by setting `allowedChannelPlugins` in managed settings. Use this to restrict which official plugins are allowed, approve channels from your own internal marketplace, or both. Each entry names a plugin and the marketplace it comes from:

```json theme={null}
{
  "channelsEnabled": true,
  "allowedChannelPlugins": [
    { "marketplace": "claude-plugins-official", "plugin": "telegram" },
    { "marketplace": "claude-plugins-official", "plugin": "discord" },
    { "marketplace": "acme-corp-plugins", "plugin": "internal-alerts" }
  ]
}
```

When `allowedChannelPlugins` is set, it replaces the Anthropic allowlist entirely: only the listed plugins can register. Leave it unset to fall back to the default Anthropic allowlist. An empty array blocks all channel plugins from the allowlist, but `--dangerously-load-development-channels` can still bypass it for local testing. To block channels entirely including the development flag, leave `channelsEnabled` unset instead.

This setting requires `channelsEnabled: true`. If a user passes a plugin to `--channels` that isn't on your list, Claude Code starts normally but the channel doesn't register, and the startup notice explains that the plugin isn't on the organization's approved list.

## Research preview

Channels are a research preview feature. Availability is rolling out gradually, and the `--channels` flag syntax and protocol contract may change based on feedback.

During the preview, `--channels` only accepts plugins from an Anthropic-maintained allowlist, or from your organization's allowlist if an admin has set [`allowedChannelPlugins`](#restrict-which-channel-plugins-can-run). The channel plugins in [claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins) are the default approved set. If you pass something that isn't on the effective allowlist, Claude Code starts normally but the channel doesn't register, and the startup notice tells you why.

To test a channel you're building, use `--dangerously-load-development-channels`. See [Test during the research preview](/en/channels-reference#test-during-the-research-preview) for information about testing custom channels that you build.

Report issues or feedback on the [Claude Code GitHub repository](https://github.com/anthropics/claude-code/issues).

## How channels compare

Several Claude Code features connect to systems outside the terminal, each suited to a different kind of work:

| Feature                                              | What it does                                                          | Good for                                                  |
| ---------------------------------------------------- | --------------------------------------------------------------------- | --------------------------------------------------------- |
| [Claude Code on the web](/en/claude-code-on-the-web) | Runs tasks in a fresh cloud sandbox, cloned from GitHub               | Delegating self-contained async work you check on later   |
| [Claude in Slack](/en/slack)                         | Spawns a web session from an `@Claude` mention in a channel or thread | Starting tasks directly from team conversation context    |
| Standard [MCP server](/en/mcp)                       | Claude queries it during a task; nothing is pushed to the session     | Giving Claude on-demand access to read or query a system  |
| [Remote Control](/en/remote-control)                 | You drive your local session from claude.ai or the Claude mobile app  | Steering an in-progress session while away from your desk |

Channels fill the gap in that list by pushing events from non-Claude sources into your already-running local session.

* **Chat bridge**: ask Claude something from your phone via Telegram, Discord, or iMessage, and the answer comes back in the same chat while the work runs on your machine against your real files.
* **[Webhook receiver](/en/channels-reference#example-build-a-webhook-receiver)**: a webhook from CI, your error tracker, a deploy pipeline, or other external service arrives where Claude already has your files open and remembers what you were debugging.

## Next steps

Once you have a channel running, explore these related features:

* [Build your own channel](/en/channels-reference) for systems that don't have plugins yet
* [Remote Control](/en/remote-control) to drive a local session from your phone instead of forwarding events into it
* [Scheduled tasks](/en/scheduled-tasks) to poll on a timer instead of reacting to pushed events

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Run prompts on a schedule

> Use /loop and the cron scheduling tools to run prompts repeatedly, poll for status, or set one-time reminders within a Claude Code session.

<Note>
  Scheduled tasks require Claude Code v2.1.72 or later. Check your version with `claude --version`.
</Note>

Scheduled tasks let Claude re-run a prompt automatically on an interval. Use them to poll a deployment, babysit a PR, check back on a long-running build, or remind yourself to do something later in the session. To react to events as they happen instead of polling, see [Channels](/en/channels): your CI can push the failure into the session directly. To keep the session working turn after turn until a condition is met rather than on an interval, see [`/goal`](/en/goal).

Tasks are session-scoped: they live in the current conversation and stop when you start a new one. Resuming with `--resume` or `--continue` brings back any task that hasn't [expired](#seven-day-expiry): a recurring task created within the last 7 days, or a one-shot whose scheduled time hasn't passed yet. For scheduling that survives independently of any session, use [Routines](/en/routines) to create a routine on Anthropic-managed infrastructure, set up a [Desktop scheduled task](/en/desktop-scheduled-tasks), or use [GitHub Actions](/en/github-actions).

## Compare scheduling options

Claude Code offers three ways to schedule recurring or one-off work:

|                            | [Cloud](/en/routines)          | [Desktop](/en/desktop-scheduled-tasks) | [`/loop`](/en/scheduled-tasks)      |
| :------------------------- | :----------------------------- | :------------------------------------- | :---------------------------------- |
| Runs on                    | Anthropic cloud                | Your machine                           | Your machine                        |
| Requires machine on        | No                             | Yes                                    | Yes                                 |
| Requires open session      | No                             | No                                     | Yes                                 |
| Persistent across restarts | Yes                            | Yes                                    | Restored on `--resume` if unexpired |
| Access to local files      | No (fresh clone)               | Yes                                    | Yes                                 |
| MCP servers                | Connectors configured per task | [Config files](/en/mcp) and connectors | Inherits from session               |
| Permission prompts         | No (runs autonomously)         | Configurable per task                  | Inherits from session               |
| Customizable schedule      | Via `/schedule` in the CLI     | Yes                                    | Yes                                 |
| Minimum interval           | 1 hour                         | 1 minute                               | 1 minute                            |

<Tip>
  Use **cloud tasks** for work that should run reliably without your machine. Use **Desktop tasks** when you need access to local files and tools. Use **`/loop`** for quick polling during a session.
</Tip>

## Run a prompt repeatedly with /loop

The `/loop` [bundled skill](/en/commands) is the quickest way to run a prompt on repeat while the session stays open. Both the interval and the prompt are optional, and what you provide determines how the loop behaves.

| What you provide          | Example                     | What happens                                                                                                  |
| :------------------------ | :-------------------------- | :------------------------------------------------------------------------------------------------------------ |
| Interval and prompt       | `/loop 5m check the deploy` | Your prompt runs on a [fixed schedule](#run-on-a-fixed-interval)                                              |
| Prompt only               | `/loop check the deploy`    | Your prompt runs at an [interval Claude chooses](#let-claude-choose-the-interval) each iteration              |
| Interval only, or nothing | `/loop`                     | The [built-in maintenance prompt](#run-the-built-in-maintenance-prompt) runs, or your `loop.md` if one exists |

You can also pass another command as the prompt, for example `/loop 20m /review-pr 1234`, to re-run a packaged workflow each iteration.

### Run on a fixed interval

When you supply an interval, Claude converts it to a cron expression, schedules the job, and confirms the cadence and job ID.

```text theme={null}
/loop 5m check if the deployment finished and tell me what happened
```

The interval can lead the prompt as a bare token like `30m`, or trail it as a clause like `every 2 hours`. Supported units are `s` for seconds, `m` for minutes, `h` for hours, and `d` for days.

Seconds are rounded up to the nearest minute since cron has one-minute granularity. Intervals that don't map to a clean cron step, such as `7m` or `90m`, are rounded to the nearest interval that does and Claude tells you what it picked.

### Let Claude choose the interval

When you omit the interval, Claude chooses one dynamically instead of running on a fixed cron schedule. After each iteration it picks a delay between one minute and one hour based on what it observed: short waits while a build is finishing or a PR is active, longer waits when nothing is pending. The chosen delay and the reason for it are printed at the end of each iteration.

The example below checks CI and review comments, with Claude waiting longer between iterations once the PR goes quiet:

```text theme={null}
/loop check whether CI passed and address any review comments
```

When you ask for a dynamic `/loop` schedule, Claude may use the [Monitor tool](/en/tools-reference#monitor-tool) directly. Monitor runs a background script and streams each output line back, which avoids polling altogether and is often more token-efficient and responsive than re-running a prompt on an interval.

A dynamically scheduled loop appears in your [scheduled task list](#manage-scheduled-tasks) like any other task, so you can list or cancel it the same way. The [jitter rules](#jitter) don't apply to it, but the [seven-day expiry](#seven-day-expiry) does: the loop ends automatically seven days after you start it.

<Note>
  On Bedrock, Vertex AI, and Microsoft Foundry, a prompt with no interval runs on a fixed 10-minute schedule instead.
</Note>

### Run the built-in maintenance prompt

When you omit the prompt, Claude uses a built-in maintenance prompt instead of one you supply. On each iteration it works through the following, in order:

* continue any unfinished work from the conversation
* tend to the current branch's pull request: review comments, failed CI runs, merge conflicts
* run cleanup passes such as bug hunts or simplification when nothing else is pending

Claude does not start new initiatives outside that scope, and irreversible actions such as pushing or deleting only proceed when they continue something the transcript already authorized.

```text theme={null}
/loop
```

A bare `/loop` runs this prompt at a [dynamically chosen interval](#let-claude-choose-the-interval). Add an interval, for example `/loop 15m`, to run it on a fixed schedule instead. To replace the built-in prompt with your own default, see [Customize the default prompt with loop.md](#customize-the-default-prompt-with-loop-md).

<Note>
  On Bedrock, Vertex AI, and Microsoft Foundry, `/loop` with no prompt prints the usage message instead of running the maintenance prompt.
</Note>

### Customize the default prompt with loop.md

A `loop.md` file replaces the built-in maintenance prompt with your own instructions. It defines a single default prompt for bare `/loop`, not a list of separate scheduled tasks, and is ignored whenever you supply a prompt on the command line. To schedule additional prompts alongside it, use `/loop <prompt>` or [ask Claude directly](#manage-scheduled-tasks).

Claude looks for the file in two locations and uses the first one it finds.

| Path                | Scope                                                            |
| :------------------ | :--------------------------------------------------------------- |
| `.claude/loop.md`   | Project-level. Takes precedence when both files exist.           |
| `~/.claude/loop.md` | User-level. Applies in any project that does not define its own. |

The file is plain Markdown with no required structure. Write it as if you were typing the `/loop` prompt directly. The following example keeps a release branch healthy:

```markdown title=".claude/loop.md" theme={null}
Check the `release/next` PR. If CI is red, pull the failing job log,
diagnose, and push a minimal fix. If new review comments have arrived,
address each one and resolve the thread. If everything is green and
quiet, say so in one line.
```

Edits to `loop.md` take effect on the next iteration, so you can refine the instructions while a loop is running. When no `loop.md` exists in either location, the loop falls back to the built-in maintenance prompt. Keep the file concise: content beyond 25,000 bytes is truncated.

<Note>
  On Bedrock, Vertex AI, and Microsoft Foundry, `loop.md` isn't read and `/loop` with no prompt prints the usage message instead.
</Note>

### Stop a loop

To stop a `/loop` while it is waiting for the next iteration, press `Esc`. This clears the pending wakeup so the loop does not fire again. Tasks you scheduled by [asking Claude directly](#manage-scheduled-tasks) are not affected by `Esc` and stay in place until you delete them.

In [self-paced mode](#let-claude-choose-the-interval), Claude can also end the loop on its own by not scheduling the next wakeup once the task is provably complete. Loops on a fixed interval keep running until you stop them or [seven days elapse](#seven-day-expiry).

## Set a one-time reminder

For one-shot reminders, describe what you want in natural language instead of using `/loop`. Claude schedules a single-fire task that deletes itself after running.

```text theme={null}
remind me at 3pm to push the release branch
```

```text theme={null}
in 45 minutes, check whether the integration tests passed
```

Claude pins the fire time to a specific minute and hour using a cron expression and confirms when it will fire.

## Manage scheduled tasks

Ask Claude in natural language to list or cancel tasks, or reference the underlying tools directly.

```text theme={null}
what scheduled tasks do I have?
```

```text theme={null}
cancel the deploy check job
```

Under the hood, Claude uses these tools:

| Tool         | Purpose                                                                                                         |
| :----------- | :-------------------------------------------------------------------------------------------------------------- |
| `CronCreate` | Schedule a new task. Accepts a 5-field cron expression, the prompt to run, and whether it recurs or fires once. |
| `CronList`   | List all scheduled tasks with their IDs, schedules, and prompts.                                                |
| `CronDelete` | Cancel a task by ID.                                                                                            |

Each scheduled task has an 8-character ID you can pass to `CronDelete`. A session can hold up to 50 scheduled tasks at once.

## How scheduled tasks run

The scheduler checks every second for due tasks and enqueues them at low priority. A scheduled prompt fires between your turns, not while Claude is mid-response. If Claude is busy when a task comes due, the prompt waits until the current turn ends.

All times are interpreted in your local timezone. A cron expression like `0 9 * * *` means 9am wherever you're running Claude Code, not UTC.

### Jitter

To avoid every session hitting the API at the same wall-clock moment, the scheduler adds a deterministic offset to fire times:

* Recurring tasks fire up to 30 minutes after the scheduled time (or up to half the interval, for tasks that run more often than hourly). An hourly job scheduled for `:00` may fire anywhere up to `:30`.
* One-shot tasks scheduled for the top or bottom of the hour fire up to 90 seconds early.

The offset is derived from the task ID, so the same task always gets the same offset. If exact timing matters, pick a minute that is not `:00` or `:30`, for example `3 9 * * *` instead of `0 9 * * *`, and the one-shot jitter will not apply.

### Seven-day expiry

Recurring tasks automatically expire 7 days after creation. The task fires one final time, then deletes itself. This bounds how long a forgotten loop can run. If you need a recurring task to last longer, cancel and recreate it before it expires, or use [Routines](/en/routines) or [Desktop scheduled tasks](/en/desktop-scheduled-tasks) for durable scheduling.

## Cron expression reference

`CronCreate` accepts standard 5-field cron expressions: `minute hour day-of-month month day-of-week`. All fields support wildcards (`*`), single values (`5`), steps (`*/15`), ranges (`1-5`), and comma-separated lists (`1,15,30`).

| Example        | Meaning                      |
| :------------- | :--------------------------- |
| `*/5 * * * *`  | Every 5 minutes              |
| `0 * * * *`    | Every hour on the hour       |
| `7 * * * *`    | Every hour at 7 minutes past |
| `0 9 * * *`    | Every day at 9am local       |
| `0 9 * * 1-5`  | Weekdays at 9am local        |
| `30 14 15 3 *` | March 15 at 2:30pm local     |

Day-of-week uses `0` or `7` for Sunday through `6` for Saturday. Extended syntax like `L`, `W`, `?`, and name aliases such as `MON` or `JAN` is not supported.

When both day-of-month and day-of-week are constrained, a date matches if either field matches. This follows standard vixie-cron semantics.

## Disable scheduled tasks

Set `CLAUDE_CODE_DISABLE_CRON=1` in your environment to disable the scheduler entirely. The cron tools and `/loop` become unavailable, and any already-scheduled tasks stop firing. See [Environment variables](/en/env-vars) for the full list of disable flags.

## Limitations

Session-scoped scheduling has inherent constraints:

* Tasks only fire while Claude Code is running and idle. Closing the terminal or letting the session exit stops them firing.
* No catch-up for missed fires. If a task's scheduled time passes while Claude is busy on a long-running request, it fires once when Claude becomes idle, not once per missed interval.
* Starting a fresh conversation clears all session-scoped tasks. Resuming with `claude --resume` or `claude --continue` restores tasks that have not expired: recurring tasks within seven days of creation, and one-shot tasks whose scheduled time has not yet passed. Background Bash and monitor tasks are never restored on resume.

For cron-driven automation that needs to run unattended:

* [Routines](/en/routines): run on Anthropic-managed infrastructure on a schedule, via API call, or on GitHub events
* [GitHub Actions](/en/github-actions): use a `schedule` trigger in CI
* [Desktop scheduled tasks](/en/desktop-scheduled-tasks): run locally on your machine

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Keep Claude working toward a goal

> Set a completion condition with /goal and Claude keeps working across turns until the condition is met.

<Note>
  `/goal` requires Claude Code v2.1.139 or later.
</Note>

The `/goal` command sets a completion condition and Claude keeps working toward it without you prompting each step. After each turn, a small fast model checks whether the condition holds. If not, Claude starts another turn instead of returning control to you. The goal clears automatically once the condition is met.

Use a goal for substantial work with a verifiable end state:

* Migrating a module to a new API until every call site compiles and tests pass
* Implementing a design doc until all acceptance criteria hold
* Splitting a large file into focused modules until each is under a size budget
* Working through a labeled issue backlog until the queue is empty

This page covers how to:

* [Compare autonomous workflow approaches](#compare-to-other-autonomous-workflows): `/loop`, Stop hooks, and auto mode
* [Set a goal](#set-a-goal) and [write an effective condition](#write-an-effective-condition)
* [Check status](#check-status), [clear early](#clear-a-goal), and [run non-interactively](#run-non-interactively)
* See [how evaluation works](#how-evaluation-works) and [requirements](#requirements)

## Compare to other autonomous workflows

Three approaches keep the current session running between prompts. Pick based on what should start the next turn:

| Approach                                                            | Next turn starts when      | Stops when                                      |
| :------------------------------------------------------------------ | :------------------------- | :---------------------------------------------- |
| `/goal`                                                             | The previous turn finishes | A model confirms the condition is met           |
| [`/loop`](/en/scheduled-tasks#run-a-prompt-repeatedly-with-%2Floop) | A time interval elapses    | You stop it, or Claude decides the work is done |
| [Stop hook](/en/hooks-guide#prompt-based-hooks)                     | The previous turn finishes | Your own script or prompt decides               |

`/goal` and a Stop hook both fire after every turn. `/goal` is a session-scoped shortcut: you type a condition and it's active for the current session only. A Stop hook lives in your settings file, applies to every session in its scope, and can run a script for deterministic checks or a prompt for model-evaluated ones.

[Auto mode](/en/auto-mode-config) on its own approves tool calls within a single turn but doesn't start a new one. Claude stops when it judges the work done. `/goal` adds a separate evaluator that checks your condition after every turn, so completion is decided by a fresh model rather than the one doing the work. The two are complementary: auto mode removes per-tool prompts, and `/goal` removes per-turn prompts.

<Tip>
  The approaches above keep the current session running. You can also schedule work that runs independent of any open session, such as nightly tests or morning triage. See [scheduling options](/en/scheduled-tasks#compare-scheduling-options) for cloud routines and desktop scheduled tasks.
</Tip>

## Use `/goal`

One goal can be active per session. The same command sets, checks, and clears it depending on the argument.

### Set a goal

Run `/goal` followed by the condition you want satisfied. If a goal is already active, the new one replaces it.

```text theme={null}
/goal all tests in test/auth pass and the lint step is clean
```

Setting a goal starts a turn immediately, with the condition itself as the directive. You don't need to send a separate prompt. While the goal is active, a `◎ /goal active` indicator shows how long the goal has been running.

After each turn, the evaluator returns a short reason explaining why the condition is or isn't met. The most recent reason appears in the status view and in the transcript so you can see what Claude is working toward next.

<Note>
  A goal keeps running until the condition is met or you run `/goal clear`. Run `/goal` with no argument to see turns and tokens spent so far.
</Note>

### Write an effective condition

The [evaluator](#how-evaluation-works) judges your condition against what Claude has surfaced in the conversation. It doesn't run commands or read files independently, so write the condition as something Claude's own output can demonstrate. "All tests in `test/auth` pass" works because Claude runs the tests and the result lands in the transcript for the evaluator to read.

A condition that holds up across many turns usually has:

* **One measurable end state**: a test result, a build exit code, a file count, an empty queue
* **A stated check**: how Claude should prove it, such as "`npm test` exits 0" or "`git status` is clean"
* **Constraints that matter**: anything that must not change on the way there, such as "no other test file is modified"

The condition can be up to 4,000 characters.

To bound how long a goal runs, include a turn or time clause in the condition, such as `or stop after 20 turns`. Claude reports progress against that clause each turn and the evaluator judges it from the conversation.

### Check status

Run `/goal` with no arguments to see the current state.

```text theme={null}
/goal
```

If a goal is active, the status shows:

* The condition
* How long it has been running
* How many turns have been evaluated
* The current token spend
* The evaluator's most recent reason

If no goal is active but one was achieved earlier in the session, the status shows the achieved condition along with its duration, turn count, and token spend.

### Clear a goal

Run `/goal clear` to remove an active goal before its condition is met.

```text theme={null}
/goal clear
```

`stop`, `off`, `reset`, `none`, and `cancel` are accepted as aliases for `clear`. Running `/clear` to start a new conversation also removes any active goal.

### Resume with an active goal

A goal that was still active when a session ended is restored when you resume that session with `--resume` or `--continue`. The condition carries over, but the turn count, timer, and token-spend baseline all reset on resume. A goal that was already achieved or cleared is not restored.

### Run non-interactively

`/goal` works in [non-interactive mode](/en/headless), in the [desktop app](/en/desktop), and through [Remote Control](/en/remote-control). Setting a goal with `-p` runs the loop to completion in a single invocation:

```bash theme={null}
claude -p "/goal CHANGELOG.md has an entry for every PR merged this week"
```

Interrupt the process with Ctrl+C to stop a non-interactive goal before the condition is met.

## How evaluation works

`/goal` is a wrapper around a session-scoped [prompt-based Stop hook](/en/hooks#prompt-based-hooks). Each time Claude finishes a turn, the condition and the conversation so far are sent to your configured [small fast model](/en/model-config), which defaults to Haiku. The model returns a yes-or-no decision and a short reason. A "no" tells Claude to keep working and includes the reason as guidance for the next turn. A "yes" clears the goal and records an achieved entry in the transcript.

The evaluator runs on whichever provider your session is configured for. It does not call tools, so it can only judge what Claude has already surfaced in the conversation.

<Note>
  Evaluation tokens are billed on the small fast model configured for your provider and are typically negligible compared to main-turn spend.
</Note>

## Requirements

`/goal` runs only in workspaces where you have accepted the trust dialog, because the evaluator is part of the hooks system. `/goal` is also unavailable when [`disableAllHooks`](/en/hooks#disable-or-remove-hooks) is set at any settings level or when [`allowManagedHooksOnly`](/en/settings#hook-configuration) is set in managed settings. In each case, the command tells you why instead of silently doing nothing.

## See also

* [Run a prompt repeatedly with `/loop`](/en/scheduled-tasks#run-a-prompt-repeatedly-with-%2Floop): re-run on a time interval instead of until a condition holds
* [Prompt-based hooks](/en/hooks-guide#prompt-based-hooks): write your own Stop hook when you need custom evaluation logic
* [Auto mode](/en/auto-mode-config): approve tool calls automatically so each goal turn runs unattended
* [Scheduling comparison](/en/scheduled-tasks#compare-scheduling-options): run work on a schedule independent of any open session

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Run Claude Code programmatically

> Use the Agent SDK to run Claude Code programmatically from the CLI, Python, or TypeScript.

<Note>
  Starting June 15, 2026, Agent SDK and `claude -p` usage on subscription plans will draw from a new monthly Agent SDK credit, separate from your interactive usage limits. See [Use the Claude Agent SDK with your Claude plan](https://support.claude.com/en/articles/15036540-use-the-claude-agent-sdk-with-your-claude-plan) for details.
</Note>

The [Agent SDK](/en/agent-sdk/overview) gives you the same tools, agent loop, and context management that power Claude Code. It's available as a CLI for scripts and CI/CD, or as [Python](/en/agent-sdk/python) and [TypeScript](/en/agent-sdk/typescript) packages for full programmatic control.

To run Claude Code in non-interactive mode, pass `-p` with your prompt and any [CLI options](/en/cli-reference):

```bash theme={null}
claude -p "Find and fix the bug in auth.py" --allowedTools "Read,Edit,Bash"
```

This page covers using the Agent SDK via the CLI (`claude -p`). For the Python and TypeScript SDK packages with structured outputs, tool approval callbacks, and native message objects, see the [full Agent SDK documentation](/en/agent-sdk/overview).

## Basic usage

Add the `-p` (or `--print`) flag to any `claude` command to run it non-interactively. All [CLI options](/en/cli-reference) work with `-p`, including:

* `--continue` for [continuing conversations](#continue-conversations)
* `--allowedTools` for [auto-approving tools](#auto-approve-tools)
* `--output-format` for [structured output](#get-structured-output)

This example asks Claude a question about your codebase and prints the response:

```bash theme={null}
claude -p "What does the auth module do?"
```

### Start faster with bare mode

Add `--bare` to reduce startup time by skipping auto-discovery of hooks, skills, plugins, MCP servers, auto memory, and CLAUDE.md. Without it, `claude -p` loads the same [context](/en/how-claude-code-works#the-context-window) an interactive session would, including anything configured in the working directory or `~/.claude`.

Bare mode is useful for CI and scripts where you need the same result on every machine. A hook in a teammate's `~/.claude` or an MCP server in the project's `.mcp.json` won't run, because bare mode never reads them. Only flags you pass explicitly take effect.

This example runs a one-off summarize task in bare mode and pre-approves the Read tool so the call completes without a permission prompt:

```bash theme={null}
claude --bare -p "Summarize this file" --allowedTools "Read"
```

In bare mode Claude has access to the Bash, file read, and file edit tools. Pass any context you need with a flag:

| To load                 | Use                                                     |
| ----------------------- | ------------------------------------------------------- |
| System prompt additions | `--append-system-prompt`, `--append-system-prompt-file` |
| Settings                | `--settings <file-or-json>`                             |
| MCP servers             | `--mcp-config <file-or-json>`                           |
| Custom agents           | `--agents <json>`                                       |
| A plugin                | `--plugin-dir <path>`, `--plugin-url <url>`             |

Bare mode skips OAuth and keychain reads. Anthropic authentication must come from `ANTHROPIC_API_KEY` or an `apiKeyHelper` in the JSON passed to `--settings`. Bedrock, Vertex, and Foundry use their usual provider credentials.

<Note>
  `--bare` is the recommended mode for scripted and SDK calls, and will become the default for `-p` in a future release.
</Note>

## Examples

These examples highlight common CLI patterns. For CI and other scripted calls, add [`--bare`](#start-faster-with-bare-mode) so they don't pick up whatever happens to be configured locally.

### Pipe data through Claude

Non-interactive mode reads stdin, so you can pipe data in and redirect the response out like any other command-line tool.

This example pipes a build log into Claude and writes the explanation to a file:

```bash theme={null}
cat build-error.txt | claude -p 'concisely explain the root cause of this build error' > output.txt
```

With `--output-format json`, the response payload includes `total_cost_usd` and a per-model cost breakdown, so scripted callers can track spend per invocation without consulting the [usage dashboard](/en/costs).

<Note>
  As of Claude Code v2.1.128, piped stdin is capped at 10MB. If you exceed the cap, Claude Code exits with a clear error and a non-zero status. To work with larger inputs, write the content to a file and reference the file path in your prompt instead of piping it.
</Note>

### Add Claude to a build script

You can wrap a non-interactive call in a script to use Claude as a project-specific linter or reviewer.

This `package.json` script pipes the diff against `main` into Claude and asks it to report typos. Piping the diff means Claude doesn't need Bash permission to read it, and the escaped double quotes keep the script portable to Windows:

```json theme={null}
{
  "scripts": {
    "lint:claude": "git diff main | claude -p \"you are a typo linter. for each typo in this diff, report filename:line on one line and the issue on the next. return nothing else.\""
  }
}
```

### Get structured output

Use `--output-format` to control how responses are returned:

* `text` (default): plain text output
* `json`: structured JSON with result, session ID, and metadata
* `stream-json`: newline-delimited JSON for real-time streaming

This example returns a project summary as JSON with session metadata, with the text result in the `result` field:

```bash theme={null}
claude -p "Summarize this project" --output-format json
```

To get output conforming to a specific schema, use `--output-format json` with `--json-schema` and a [JSON Schema](https://json-schema.org/) definition. The response includes metadata about the request (session ID, usage, etc.) with the structured output in the `structured_output` field.

This example extracts function names and returns them as an array of strings:

```bash theme={null}
claude -p "Extract the main function names from auth.py" \
  --output-format json \
  --json-schema '{"type":"object","properties":{"functions":{"type":"array","items":{"type":"string"}}},"required":["functions"]}'
```

<Tip>
  Use a tool like [jq](https://jqlang.github.io/jq/) to parse the response and extract specific fields:

  ```bash theme={null}
  # Extract the text result
  claude -p "Summarize this project" --output-format json | jq -r '.result'

  # Extract structured output
  claude -p "Extract function names from auth.py" \
    --output-format json \
    --json-schema '{"type":"object","properties":{"functions":{"type":"array","items":{"type":"string"}}},"required":["functions"]}' \
    | jq '.structured_output'
  ```
</Tip>

### Stream responses

Use `--output-format stream-json` with `--verbose` and `--include-partial-messages` to receive tokens as they're generated. Each line is a JSON object representing an event:

```bash theme={null}
claude -p "Explain recursion" --output-format stream-json --verbose --include-partial-messages
```

The following example uses [jq](https://jqlang.github.io/jq/) to filter for text deltas and display just the streaming text. The `-r` flag outputs raw strings (no quotes) and `-j` joins without newlines so tokens stream continuously:

```bash theme={null}
claude -p "Write a poem" --output-format stream-json --verbose --include-partial-messages | \
  jq -rj 'select(.type == "stream_event" and .event.delta.type? == "text_delta") | .event.delta.text'
```

When an API request fails with a retryable error, Claude Code emits a `system/api_retry` event before retrying. You can use this to surface retry progress or implement custom backoff logic.

| Field            | Type            | Description                                                                                                                                                                              |
| ---------------- | --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `type`           | `"system"`      | message type                                                                                                                                                                             |
| `subtype`        | `"api_retry"`   | identifies this as a retry event                                                                                                                                                         |
| `attempt`        | integer         | current attempt number, starting at 1                                                                                                                                                    |
| `max_retries`    | integer         | total retries permitted                                                                                                                                                                  |
| `retry_delay_ms` | integer         | milliseconds until the next attempt                                                                                                                                                      |
| `error_status`   | integer or null | HTTP status code, or `null` for connection errors with no HTTP response                                                                                                                  |
| `error`          | string          | error category: `authentication_failed`, `oauth_org_not_allowed`, `billing_error`, `rate_limit`, `invalid_request`, `model_not_found`, `server_error`, `max_output_tokens`, or `unknown` |
| `uuid`           | string          | unique event identifier                                                                                                                                                                  |
| `session_id`     | string          | session the event belongs to                                                                                                                                                             |

The `system/init` event reports session metadata including the model, tools, MCP servers, and loaded plugins. It is the first event in the stream unless [`CLAUDE_CODE_SYNC_PLUGIN_INSTALL`](/en/env-vars) is set, in which case `plugin_install` events precede it. Use the plugin fields to fail CI when a plugin did not load:

| Field           | Type  | Description                                                                                                                                                                                                                                                                                  |
| --------------- | ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `plugins`       | array | plugins that loaded successfully, each with `name` and `path`                                                                                                                                                                                                                                |
| `plugin_errors` | array | plugin load-time errors, each with `plugin`, `type`, and `message`. Includes unsatisfied dependency versions and `--plugin-dir` load failures such as a missing path or invalid archive. Affected plugins are demoted and absent from `plugins`. The key is omitted when there are no errors |

When [`CLAUDE_CODE_SYNC_PLUGIN_INSTALL`](/en/env-vars) is set, Claude Code emits `system/plugin_install` events while marketplace plugins install before the first turn. Use these to surface install progress in your own UI.

| Field        | Type                                                     | Description                                                                                                    |
| ------------ | -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `type`       | `"system"`                                               | message type                                                                                                   |
| `subtype`    | `"plugin_install"`                                       | identifies this as a plugin install event                                                                      |
| `status`     | `"started"`, `"installed"`, `"failed"`, or `"completed"` | `started` and `completed` bracket the overall install; `installed` and `failed` report individual marketplaces |
| `name`       | string, optional                                         | marketplace name, present on `installed` and `failed`                                                          |
| `error`      | string, optional                                         | failure message, present on `failed`                                                                           |
| `uuid`       | string                                                   | unique event identifier                                                                                        |
| `session_id` | string                                                   | session the event belongs to                                                                                   |

For programmatic streaming with callbacks and message objects, see [Stream responses in real-time](/en/agent-sdk/streaming-output) in the Agent SDK documentation.

### Auto-approve tools

Use `--allowedTools` to let Claude use certain tools without prompting. This example runs a test suite and fixes failures, allowing Claude to execute Bash commands and read/edit files without asking for permission:

```bash theme={null}
claude -p "Run the test suite and fix any failures" \
  --allowedTools "Bash,Read,Edit"
```

To set a baseline for the whole session instead of listing individual tools, pass a [permission mode](/en/permission-modes). `dontAsk` denies anything not in your `permissions.allow` rules or the [read-only command set](/en/permissions#read-only-commands), which is useful for locked-down CI runs. `acceptEdits` lets Claude write files without prompting and also auto-approves common filesystem commands such as `mkdir`, `touch`, `mv`, and `cp`. Other shell commands and network requests still need an `--allowedTools` entry or a `permissions.allow` rule, otherwise the run aborts when one is attempted:

```bash theme={null}
claude -p "Apply the lint fixes" --permission-mode acceptEdits
```

### Create a commit

This example reviews staged changes and creates a commit with an appropriate message:

```bash theme={null}
claude -p "Look at my staged changes and create an appropriate commit" \
  --allowedTools "Bash(git diff *),Bash(git log *),Bash(git status *),Bash(git commit *)"
```

The `--allowedTools` flag uses [permission rule syntax](/en/settings#permission-rule-syntax). The trailing ` *` enables prefix matching, so `Bash(git diff *)` allows any command starting with `git diff`. The space before `*` is important: without it, `Bash(git diff*)` would also match `git diff-index`.

<Note>
  User-invoked [skills](/en/skills) like `/commit` and [built-in commands](/en/commands) are only available in interactive mode. In `-p` mode, describe the task you want to accomplish instead.
</Note>

### Customize the system prompt

Use `--append-system-prompt` to add instructions while keeping Claude Code's default behavior. This example pipes a PR diff to Claude and instructs it to review for security vulnerabilities:

```bash theme={null}
gh pr diff "$1" | claude -p \
  --append-system-prompt "You are a security engineer. Review for vulnerabilities." \
  --output-format json
```

See [system prompt flags](/en/cli-reference#system-prompt-flags) for more options including `--system-prompt` to fully replace the default prompt.

### Continue conversations

Use `--continue` to continue the most recent conversation, or `--resume` with a session ID to continue a specific conversation. This example runs a review, then sends follow-up prompts:

```bash theme={null}
# First request
claude -p "Review this codebase for performance issues"

# Continue the most recent conversation
claude -p "Now focus on the database queries" --continue
claude -p "Generate a summary of all issues found" --continue
```

If you're running multiple conversations, capture the session ID to resume a specific one:

```bash theme={null}
session_id=$(claude -p "Start a review" --output-format json | jq -r '.session_id')
claude -p "Continue that review" --resume "$session_id"
```

## Next steps

* [Agent SDK quickstart](/en/agent-sdk/quickstart): build your first agent with Python or TypeScript
* [CLI reference](/en/cli-reference): all CLI flags and options
* [GitHub Actions](/en/github-actions): use the Agent SDK in GitHub workflows
* [GitLab CI/CD](/en/gitlab-ci-cd): use the Agent SDK in GitLab pipelines

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Launch sessions from links

> Open a Claude Code terminal session from a URL. Embed `claude-cli://` links in runbooks, alerts, and dashboards so a click opens Claude Code in the right repo with the right prompt.

A deep link is a `claude-cli://` URL that opens Claude Code in a new terminal window. The URL can carry a working directory and a prompt to pre-fill.

This lets you share a one-click starting point for a task: anyone with Claude Code installed who clicks the link sees a session open with the prompt already typed. The prompt is populated but not sent until you press Enter.

Because a deep link is a URL, you can put one anywhere a link can go:

* An incident runbook step that opens the affected service's repo with a diagnostic prompt
* A monitoring alert or dashboard that links to an investigation prompt for a specific metric
* A README or wiki page that opens the project with an onboarding prompt
* A CI failure notification that pre-fills the failing job's name

This page covers how to [build a link](#build-a-link), [embed one in a runbook or trigger it from the shell](#examples), and [manage or disable handler registration](#registration-and-supported-platforms) on each platform.

<Note>
  Deep links require Claude Code v2.1.91 or later.
</Note>

## How it works

The `claude-cli://` prefix is a custom URL scheme that Claude Code registers with your operating system, similar to how `mailto:` links open your email client. The link can live on a web page, in a wiki, in a Slack message, or in any app that renders links. When you click one:

1. The browser or app hands the URL to your operating system.
2. The operating system recognizes the `claude-cli://` prefix and starts Claude Code on your machine.
3. A new terminal window opens with Claude Code running in the directory the link specified, and the link's prompt text already in the input box.
4. You read the prompt, edit it if you want, and press Enter to send it.

The link itself can be hosted anywhere, but the session always opens locally on the computer where you clicked. See [Registration and supported platforms](#registration-and-supported-platforms) for which terminal emulator opens on each operating system.

<Note>
  The platform that displays the link must allow custom URL schemes. GitHub-rendered Markdown allows `http` and `https` but strips schemes like `claude-cli://` in READMEs, issues, pull requests, and wikis. Only the link text shows, with no link behind it and the URL hidden. See [Troubleshooting](#the-link-renders-as-plain-text-instead-of-being-clickable) for a workaround.
</Note>

### What a launched session shows

A deep link never executes anything on its own. The link only chooses a directory and fills the prompt box. If you click a link from a page you do not trust, the prompt is still inert: nothing reaches the model until you read what was filled in and press Enter.

When the session opens, a banner above the input shows that an external link launched it and which directory it selected. For prompts over 1,000 characters, the banner tells you to scroll and review the full text before pressing Enter, since long prompts can push instructions off screen. Permission rules, `CLAUDE.md`, and trust prompts for the selected directory apply the same way as for any other session.

## Build a link

Every deep link starts with `claude-cli://open`, which is the only path the handler accepts, followed by optional query parameters. The minimal form opens Claude Code in your home directory with an empty prompt:

```text theme={null}
claude-cli://open
```

Add parameters to control where the session starts and what the prompt box contains:

| Parameter | Description                                                                                                                                                                                                                                 |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `q`       | Text to pre-fill in the prompt box. [URL-encode](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent) the value. Use `%0A` for line breaks in multi-line prompts. Maximum 5,000 characters. |
| `cwd`     | Absolute path to use as the working directory. Network and UNC paths are rejected.                                                                                                                                                          |
| `repo`    | A GitHub `owner/name` slug. Claude Code resolves it to a local clone it has seen before and starts there. If you have no matching clone, the session opens in your home directory instead.                                                  |

`cwd` and `repo` are [two ways to set the working directory](#choose-between-cwd-and-repo). If you pass both, `cwd` takes precedence and `repo` is ignored, even if the `cwd` path does not exist.

The following link points at a repository called `acme/payments` with a two-line diagnostic prompt. Replace `acme/payments` with your repository's `owner/name` slug when you build your own:

```text theme={null}
claude-cli://open?repo=acme/payments&q=Investigate%20the%20failed%20deploy%20of%20payments-api.%0ACheck%20recent%20commits%20to%20main%20and%20the%20last%20successful%20build.
```

Clicking it opens a new terminal window, starts Claude Code in your local clone of `acme/payments`, and fills the prompt box with the decoded text:

```text theme={null}
Investigate the failed deploy of payments-api.
Check recent commits to main and the last successful build.
```

You can edit the prompt before pressing Enter to send it. If you have no local clone of the repository, the session opens in your home directory instead. See [Choose between `cwd` and `repo`](#choose-between-cwd-and-repo) for how the local path is selected when you have multiple clones or worktrees.

### Choose between `cwd` and `repo`

Use `cwd` when everyone who clicks the link has the project at the same absolute path, such as a standardized devcontainer or VM image.

Use `repo` when the link is shared and each person clones to a different location. Claude Code resolves the slug to a local path as follows:

* Each time you run `claude` in a Git repository, that directory's filesystem path is recorded against the repository's GitHub `owner/name` slug.
* When a deep link arrives, `repo` opens whichever matching path you used most recently. Multiple clones and worktrees are tracked separately, so it picks the one you worked in last.
* The lookup only finds paths where you have already run Claude Code at least once.
* The link does not change which branch is checked out. The session opens in whatever state that directory is currently in.

The launched session shows which path it picked and when that clone last fetched from the remote, so you can tell if you are looking at stale code.

## Examples

The sections below show two common ways to use a deep link: as a Markdown link in a document and as a command in a script or shell alias.

### Embed a link in a runbook

A deep link in a runbook gives whoever is triaging a one-click way to start investigating in the right repository with a prepared prompt. The platform that renders the runbook must allow custom URL schemes. GitHub-rendered Markdown does not allow `claude-cli://`, so a deep link in a GitHub README, issue, or wiki shows only its label with no clickable link. See [the troubleshooting note](#the-link-renders-as-plain-text-instead-of-being-clickable) for a workaround.

The prompt is part of the URL and must be URL-encoded. To produce the encoded value, pass your prompt text through `encodeURIComponent` in a browser console or any URL encoder.

The example below adds an investigation entry point to an incident runbook for a service called `web-gateway`:

```markdown theme={null}
## High 5xx rate on web-gateway

1. Acknowledge the page in PagerDuty.
2. [Open Claude Code in the gateway repo](claude-cli://open?repo=acme/web-gateway&q=5xx%20rate%20is%20elevated%20on%20web-gateway.%20Check%20recent%20deploys%2C%20error%20logs%20from%20the%20last%2030%20minutes%2C%20and%20open%20incidents%20in%20Linear.)
3. Post initial findings in #incident.
```

To use this in your own runbook, replace `acme/web-gateway` with your service's repository slug. This allows engineers with Claude Code installed and a local clone of that repository to click step 2 and start investigating with the prompt ready to send.

### Open a link from the shell

You can also open a deep link from a shell script, alias, or automation rather than by clicking it. Call your operating system's URL-opening command with the link as the argument.

<Tabs>
  <Tab title="macOS">
    The built-in `open` command passes the URL to the registered `claude-cli://` handler:

    ```bash theme={null}
    open "claude-cli://open?repo=acme/payments&q=review%20open%20PRs"
    ```
  </Tab>

  <Tab title="Linux">
    Most desktop environments provide `xdg-open`, which passes the URL to the registered handler:

    ```bash theme={null}
    xdg-open "claude-cli://open?repo=acme/payments&q=review%20open%20PRs"
    ```
  </Tab>

  <Tab title="Windows">
    In PowerShell, `Start-Process` passes the URL to the registered handler:

    ```powershell theme={null}
    Start-Process "claude-cli://open?repo=acme/payments&q=review%20open%20PRs"
    ```

    In `cmd.exe`, `start` treats its first quoted argument as a window title, so pass an empty title before the URL:

    ```cmd theme={null}
    start "" "claude-cli://open?repo=acme/payments&q=review%20open%20PRs"
    ```
  </Tab>
</Tabs>

## Registration and supported platforms

Claude Code registers the `claude-cli://` handler with your operating system the first time you start an interactive session on macOS, Linux, and Windows. You do not run a separate install command. Registration writes to user-level locations only:

| Platform | Handler location                                                                                                   |
| -------- | ------------------------------------------------------------------------------------------------------------------ |
| macOS    | `~/Applications/Claude Code URL Handler.app`                                                                       |
| Linux    | `claude-code-url-handler.desktop` under `$XDG_DATA_HOME/applications`, defaulting to `~/.local/share/applications` |
| Windows  | `HKEY_CURRENT_USER\Software\Classes\claude-cli`                                                                    |

The handler launches Claude Code in a detected terminal emulator. On macOS, Claude Code remembers the terminal from your most recent interactive session and reuses it, supporting iTerm2, Ghostty, kitty, Alacritty, WezTerm, and Terminal.app. On Linux it honors the `$TERMINAL` environment variable, then `x-terminal-emulator`, then a list of common emulators. On Windows it prefers Windows Terminal, then PowerShell, then `cmd.exe`.

To prevent registration entirely, set [`disableDeepLinkRegistration`](/en/settings) to `"disable"` in `settings.json`. To enforce this across an organization so users cannot re-enable it, set it in [managed settings](/en/server-managed-settings) instead.

## Open a VS Code tab instead of a terminal

The VS Code extension registers its own handler at `vscode://anthropic.claude-code/open`, which opens a Claude Code editor tab rather than a terminal window. See [Launch a VS Code tab from other tools](/en/vs-code#launch-a-vs-code-tab-from-other-tools) for that URL's parameters.

## Troubleshooting

### Clicking the link does nothing

The handler likely is not registered yet. Start an interactive `claude` session once on that machine, exit, and try the link again. If you are on Linux without a desktop environment, `xdg-open` may have nothing to dispatch to.

### The link renders as plain text instead of being clickable

Some Markdown renderers only allow `http` and `https` links and strip other URL schemes. GitHub does this in READMEs, issues, pull requests, and wikis: `[label](claude-cli://...)` renders as just `label`, with no link and the URL removed. On these platforms, put the deep link in a code block so readers can see the URL and paste it into their browser's address bar.

### The session opens in my home directory instead of the repo

The `repo` parameter only resolves to clones Claude Code has already seen. Run `claude` inside the clone once so its path is recorded, or switch the link to use `cwd` with an absolute path.

### The link opens the wrong terminal

On macOS, start `claude` in your preferred terminal once and the next deep link will use it. On Linux, set the `$TERMINAL` environment variable to your preferred emulator's command name. On Windows, the order is fixed: install Windows Terminal if you want links to open there instead of a PowerShell or `cmd.exe` window.

## Learn more

These pages cover related ways to launch or extend Claude Code sessions:

* [Skills](/en/skills): store a long runbook prompt as a `/skill` in the repo so the deep link's `q` parameter only has to name it
* [Non-interactive mode](/en/headless): run Claude from a script and capture the output without opening a terminal
