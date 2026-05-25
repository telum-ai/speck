> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Connect Claude Code to tools via MCP

> Learn how to connect Claude Code to your tools with the Model Context Protocol.

Claude Code can connect to hundreds of external tools and data sources through the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction), an open source standard for AI-tool integrations. MCP servers give Claude Code access to your tools, databases, and APIs.

Connect a server when you find yourself copying data into chat from another tool, like an issue tracker or a monitoring dashboard. Once connected, Claude can read and act on that system directly instead of working from what you paste.

## What you can do with MCP

With MCP servers connected, you can ask Claude Code to:

* **Implement features from issue trackers**: "Add the feature described in JIRA issue ENG-4521 and create a PR on GitHub."
* **Analyze monitoring data**: "Check Sentry and Statsig to check the usage of the feature described in ENG-4521."
* **Query databases**: "Find emails of 10 random users who used feature ENG-4521, based on our PostgreSQL database."
* **Integrate designs**: "Update our standard email template based on the new Figma designs that were posted in Slack"
* **Automate workflows**: "Create Gmail drafts inviting these 10 users to a feedback session about the new feature."
* **React to external events**: An MCP server can also act as a [channel](/en/channels) that pushes messages into your session, so Claude reacts to Telegram messages, Discord chats, or webhook events while you're away.

## Find and build MCP servers

Browse reviewed connectors in the [Anthropic Directory](https://claude.ai/directory). Directory connectors use the same MCP infrastructure as Claude Code, so you can add any remote server listed there with `claude mcp add`.

<Warning>
  Verify you trust each server before connecting it. Servers that fetch external content can expose you to [prompt injection risk](/en/security#protect-against-prompt-injection).
</Warning>

To build your own server, see the [MCP server guide](https://modelcontextprotocol.io/docs/develop/build-server) for protocol fundamentals and the [Claude connector building docs](https://claude.com/docs/connectors/building) for authentication, testing, and Directory submission.

You can also have Claude scaffold a server for you with the official [`mcp-server-dev` plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/mcp-server-dev).

<Steps>
  <Step title="Install the plugin">
    In a Claude Code session, run:

    ```
    /plugin install mcp-server-dev@claude-plugins-official
    ```

    Then run `/reload-plugins` to activate it in the current session.
  </Step>

  <Step title="Run the build skill">
    ```
    /mcp-server-dev:build-mcp-server
    ```

    Claude asks about your use case and scaffolds a remote HTTP or local stdio server.
  </Step>
</Steps>

## Installing MCP servers

MCP servers can be configured in three different ways depending on your needs:

### Option 1: Add a remote HTTP server

HTTP servers are the recommended option for connecting to remote MCP servers. This is the most widely supported transport for cloud-based services.

```bash theme={null}
# Basic syntax
claude mcp add --transport http <name> <url>

# Real example: Connect to Notion
claude mcp add --transport http notion https://mcp.notion.com/mcp

# Example with Bearer token
claude mcp add --transport http secure-api https://api.example.com/mcp \
  --header "Authorization: Bearer your-token"
```

When configuring MCP servers via JSON in `.mcp.json`, `~/.claude.json`, or `claude mcp add-json`, the `type` field accepts `streamable-http` as an alias for `http`. The MCP specification uses the name `streamable-http` for this transport, so configurations copied from server documentation work without modification.

### Option 2: Add a remote SSE server

<Warning>
  The SSE (Server-Sent Events) transport is deprecated. Use HTTP servers instead, where available.
</Warning>

```bash theme={null}
# Basic syntax
claude mcp add --transport sse <name> <url>

# Real example: Connect to Asana
claude mcp add --transport sse asana https://mcp.asana.com/sse

# Example with authentication header
claude mcp add --transport sse private-api https://api.company.com/sse \
  --header "X-API-Key: your-key-here"
```

### Option 3: Add a local stdio server

Stdio servers run as local processes on your machine. They're ideal for tools that need direct system access or custom scripts.

Claude Code sets `CLAUDE_PROJECT_DIR` in the spawned server's environment to the project root, so your server can resolve project-relative paths without depending on the working directory. This is the same directory hooks receive in their `CLAUDE_PROJECT_DIR` variable. Read it from inside your server process, for example `process.env.CLAUDE_PROJECT_DIR` in Node or `os.environ["CLAUDE_PROJECT_DIR"]` in Python. Your server can also call the MCP `roots/list` request, which returns the directory Claude Code was launched from.

This variable is set in the server's environment, not in Claude Code's own environment, so referencing it via `${VAR}` expansion in a project- or user-scoped `.mcp.json` `command` or `args` requires a default such as `${CLAUDE_PROJECT_DIR:-.}`. Plugin-provided MCP configurations substitute `${CLAUDE_PROJECT_DIR}` directly and don't need the default.

```bash theme={null}
# Basic syntax
claude mcp add [options] <name> -- <command> [args...]

# Real example: Add Airtable server
claude mcp add --transport stdio --env AIRTABLE_API_KEY=YOUR_KEY airtable \
  -- npx -y airtable-mcp-server
```

<Note>
  **Important: Option ordering**

  All options (`--transport`, `--env`, `--scope`, `--header`) must come **before** the server name. The `--` (double dash) then separates the server name from the command and arguments that get passed to the MCP server.

  For example:

  * `claude mcp add --transport stdio myserver -- npx server` → runs `npx server`
  * `claude mcp add --transport stdio --env KEY=value myserver -- python server.py --port 8080` → runs `python server.py --port 8080` with `KEY=value` in environment

  This prevents conflicts between Claude's flags and the server's flags.
</Note>

### Managing your servers

Once configured, you can manage your MCP servers with these commands:

```bash theme={null}
# List all configured servers
claude mcp list

# Get details for a specific server
claude mcp get github

# Remove a server
claude mcp remove github

# (within Claude Code) Check server status
/mcp
```

The `/mcp` panel shows the tool count next to each connected server and flags servers that advertise the tools capability but expose no tools.

If your request needs tools from a server that is still connecting in the background, Claude waits for that server before continuing. With [tool search](#scale-with-mcp-tool-search) enabled, which is the default, the wait happens inside the `ToolSearch` call. In configurations without tool search, such as Vertex AI, a custom `ANTHROPIC_BASE_URL`, or `ENABLE_TOOL_SEARCH=false`, Claude uses the `WaitForMcpServers` tool instead.

The server name `workspace` is reserved for internal use. If your configuration defines a server with that name, Claude Code skips it at load time and shows a warning asking you to rename it.

### Dynamic tool updates

Claude Code supports MCP `list_changed` notifications, allowing MCP servers to dynamically update their available tools, prompts, and resources without requiring you to disconnect and reconnect. When an MCP server sends a `list_changed` notification, Claude Code automatically refreshes the available capabilities from that server.

### Automatic reconnection

If an HTTP or SSE server disconnects mid-session, Claude Code automatically reconnects with exponential backoff: up to five attempts, starting at a one-second delay and doubling each time. The server appears as pending in `/mcp` while reconnection is in progress. After five failed attempts the server is marked as failed and you can retry manually from `/mcp`. Stdio servers are local processes and are not reconnected automatically.

The same backoff applies when an HTTP or SSE server fails its initial connection at startup. As of v2.1.121, Claude Code retries the initial connection up to three times on transient errors such as a 5xx response, a connection refused, or a timeout, then marks the server as failed if it still cannot connect. Authentication and not-found errors are not retried because they require a configuration change to resolve.

### Push messages with channels

An MCP server can also push messages directly into your session so Claude can react to external events like CI results, monitoring alerts, or chat messages. To enable this, your server declares the `claude/channel` capability and you opt it in with the `--channels` flag at startup. See [Channels](/en/channels) to use an officially supported channel, or [Channels reference](/en/channels-reference) to build your own.

<Tip>
  Tips:

  * Use the `--scope` flag to specify where the configuration is stored:
    * `local` (default): Available only to you in the current project (was called `project` in older versions)
    * `project`: Shared with everyone in the project via `.mcp.json` file
    * `user`: Available to you across all projects (was called `global` in older versions)
  * Set environment variables with `--env` flags (for example, `--env KEY=value`)
  * Configure MCP server startup timeout using the MCP\_TIMEOUT environment variable (for example, `MCP_TIMEOUT=10000 claude` sets a 10-second timeout)
  * Set a per-server tool execution timeout by adding a `timeout` field in milliseconds to that server's `.mcp.json` entry, for example `"timeout": 600000` for ten minutes. This overrides the `MCP_TOOL_TIMEOUT` environment variable for that server only
  * Claude Code will display a warning when MCP tool output exceeds 10,000 tokens. To increase this limit, set the `MAX_MCP_OUTPUT_TOKENS` environment variable (for example, `MAX_MCP_OUTPUT_TOKENS=50000`)
  * Use `/mcp` to authenticate with remote servers that require OAuth 2.0 authentication
</Tip>

The per-server `timeout` is a hard wall-clock limit per tool call, and progress notifications from the server do not extend it. Values below 1000 are floored to one second. For HTTP and SSE servers, the per-request fetch first-byte budget has a 60-second minimum regardless of this value, so only the tool-call watchdog honors smaller values.

### Plugin-provided MCP servers

[Plugins](/en/plugins) can bundle MCP servers, automatically providing tools and integrations when the plugin is enabled. Plugin MCP servers work identically to user-configured servers.

**How plugin MCP servers work**:

* Plugins define MCP servers in `.mcp.json` at the plugin root or inline in `plugin.json`
* When a plugin is enabled, its MCP servers start automatically
* Plugin MCP tools appear alongside manually configured MCP tools
* Plugin servers are managed through plugin installation (not `/mcp` commands)

**Example plugin MCP configuration**:

In `.mcp.json` at plugin root:

```json theme={null}
{
  "mcpServers": {
    "database-tools": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
      "env": {
        "DB_URL": "${DB_URL}"
      }
    }
  }
}
```

Or inline in `plugin.json`:

```json theme={null}
{
  "name": "my-plugin",
  "mcpServers": {
    "plugin-api": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/api-server",
      "args": ["--port", "8080"]
    }
  }
}
```

**Plugin MCP features**:

* **Automatic lifecycle**: At session startup, servers for enabled plugins connect automatically. If you enable or disable a plugin during a session, run `/reload-plugins` to connect or disconnect its MCP servers
* **Environment variables**: use `${CLAUDE_PLUGIN_ROOT}` for bundled plugin files, `${CLAUDE_PLUGIN_DATA}` for [persistent state](/en/plugins-reference#persistent-data-directory) that survives plugin updates, and `${CLAUDE_PROJECT_DIR}` for the stable project root
* **User environment access**: Access to same environment variables as manually configured servers
* **Multiple transport types**: Support stdio, SSE, and HTTP transports (transport support may vary by server)

**Viewing plugin MCP servers**:

```bash theme={null}
# Within Claude Code, see all MCP servers including plugin ones
/mcp
```

Plugin servers appear in the list with indicators showing they come from plugins.

**Benefits of plugin MCP servers**:

* **Bundled distribution**: Tools and servers packaged together
* **Automatic setup**: No manual MCP configuration needed
* **Team consistency**: Everyone gets the same tools when plugin is installed

See the [plugin components reference](/en/plugins-reference#mcp-servers) for details on bundling MCP servers with plugins.

## MCP installation scopes

MCP servers can be configured at three scopes. The scope you choose controls which projects the server loads in and whether the configuration is shared with your team. Administrators can also deploy servers at the enterprise level via [managed configuration](#managed-mcp-configuration).

| Scope                     | Loads in             | Shared with team         | Stored in                   |
| ------------------------- | -------------------- | ------------------------ | --------------------------- |
| [Local](#local-scope)     | Current project only | No                       | `~/.claude.json`            |
| [Project](#project-scope) | Current project only | Yes, via version control | `.mcp.json` in project root |
| [User](#user-scope)       | All your projects    | No                       | `~/.claude.json`            |

### Local scope

Local scope is the default. A local-scoped server loads only in the project where you added it and stays private to you. Claude Code stores it in `~/.claude.json` under that project's path, so the same server won't appear in your other projects. Use local scope for personal development servers, experimental configurations, or servers with credentials you don't want in version control.

<Note>
  The term "local scope" for MCP servers differs from general local settings. MCP local-scoped servers are stored in `~/.claude.json` (your home directory), while general local settings use `.claude/settings.local.json` (in the project directory). See [Settings](/en/settings#settings-files) for details on settings file locations.
</Note>

```bash theme={null}
# Add a local-scoped server (default)
claude mcp add --transport http stripe https://mcp.stripe.com

# Explicitly specify local scope
claude mcp add --transport http stripe --scope local https://mcp.stripe.com
```

The command writes the server into the entry for your current project inside `~/.claude.json`. The example below shows the result when you run it from `/path/to/your/project`:

```json theme={null}
{
  "projects": {
    "/path/to/your/project": {
      "mcpServers": {
        "stripe": {
          "type": "http",
          "url": "https://mcp.stripe.com"
        }
      }
    }
  }
}
```

### Project scope

Project-scoped servers enable team collaboration by storing configurations in a `.mcp.json` file at your project's root directory. This file is designed to be checked into version control, ensuring all team members have access to the same MCP tools and services. When you add a project-scoped server, Claude Code automatically creates or updates this file with the appropriate configuration structure.

```bash theme={null}
# Add a project-scoped server
claude mcp add --transport http paypal --scope project https://mcp.paypal.com/mcp
```

The resulting `.mcp.json` file follows a standardized format:

```json theme={null}
{
  "mcpServers": {
    "shared-server": {
      "command": "/path/to/server",
      "args": [],
      "env": {}
    }
  }
}
```

For security reasons, Claude Code prompts for approval before using project-scoped servers from `.mcp.json` files. If you need to reset these approval choices, use the `claude mcp reset-project-choices` command.

### User scope

User-scoped servers are stored in `~/.claude.json` and provide cross-project accessibility, making them available across all projects on your machine while remaining private to your user account. This scope works well for personal utility servers, development tools, or services you frequently use across different projects.

```bash theme={null}
# Add a user server
claude mcp add --transport http hubspot --scope user https://mcp.hubspot.com/anthropic
```

### Scope hierarchy and precedence

When the same server is defined in more than one place, Claude Code connects to it once, using the definition from the highest-precedence source:

1. Local scope
2. Project scope
3. User scope
4. [Plugin-provided servers](/en/plugins)
5. [claude.ai connectors](#use-mcp-servers-from-claude-ai)

The three scopes match duplicates by name. Plugins and connectors match by endpoint, so one that points at the same URL or command as a server above is treated as a duplicate.

### Environment variable expansion in `.mcp.json`

Claude Code supports environment variable expansion in `.mcp.json` files, allowing teams to share configurations while maintaining flexibility for machine-specific paths and sensitive values like API keys.

**Supported syntax:**

* `${VAR}` - Expands to the value of environment variable `VAR`
* `${VAR:-default}` - Expands to `VAR` if set, otherwise uses `default`

**Expansion locations:**
Environment variables can be expanded in:

* `command` - The server executable path
* `args` - Command-line arguments
* `env` - Environment variables passed to the server
* `url` - For HTTP server types
* `headers` - For HTTP server authentication

**Example with variable expansion:**

```json theme={null}
{
  "mcpServers": {
    "api-server": {
      "type": "http",
      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
      "headers": {
        "Authorization": "Bearer ${API_KEY}"
      }
    }
  }
}
```

If a required environment variable is not set and has no default value, Claude Code will fail to parse the config.

## Practical examples

{/* ### Example: Automate browser testing with Playwright

```bash
claude mcp add --transport stdio playwright -- npx -y @playwright/mcp@latest
```

Then write and run browser tests:

```text
Test if the login flow works with test@example.com
```
```text
Take a screenshot of the checkout page on mobile
```
```text
Verify that the search feature returns results
``` */}

### Example: Monitor errors with Sentry

```bash theme={null}
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
```

Authenticate with your Sentry account:

```text theme={null}
/mcp
```

Then debug production issues:

```text theme={null}
What are the most common errors in the last 24 hours?
```

```text theme={null}
Show me the stack trace for error ID abc123
```

```text theme={null}
Which deployment introduced these new errors?
```

### Example: Connect to GitHub for code reviews

GitHub's remote MCP server authenticates with a GitHub personal access token passed as a header. To get one, open your [GitHub token settings](https://github.com/settings/personal-access-tokens), generate a new fine-grained token with access to the repositories you want Claude to work with, then add the server:

```bash theme={null}
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
  --header "Authorization: Bearer YOUR_GITHUB_PAT"
```

Then work with GitHub:

```text theme={null}
Review PR #456 and suggest improvements
```

```text theme={null}
Create a new issue for the bug we just found
```

```text theme={null}
Show me all open PRs assigned to me
```

### Example: Query your PostgreSQL database

```bash theme={null}
claude mcp add --transport stdio db -- npx -y @bytebase/dbhub \
  --dsn "postgresql://readonly:pass@prod.db.com:5432/analytics"
```

Then query your database naturally:

```text theme={null}
What's our total revenue this month?
```

```text theme={null}
Show me the schema for the orders table
```

```text theme={null}
Find customers who haven't made a purchase in 90 days
```

## Authenticate with remote MCP servers

Many cloud-based MCP servers require authentication. Claude Code supports OAuth 2.0 for secure connections.

Claude Code marks a remote server as needing authentication when the server responds with `401 Unauthorized` or `403 Forbidden`. Either status code flags the server in `/mcp` so you can complete the OAuth flow. A custom server that returns a `WWW-Authenticate` header pointing to its authorization server gets the same automatic discovery as any other remote server.

<Steps>
  <Step title="Add the server that requires authentication">
    For example:

    ```bash theme={null}
    claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
    ```
  </Step>

  <Step title="Use the /mcp command within Claude Code">
    In Claude code, use the command:

    ```text theme={null}
    /mcp
    ```

    Then follow the steps in your browser to login.
  </Step>
</Steps>

<Tip>
  Tips:

  * Authentication tokens are stored securely and refreshed automatically
  * Use "Clear authentication" in the `/mcp` menu to revoke access
  * If your browser doesn't open automatically, copy the provided URL and open it manually
  * If the browser redirect fails with a connection error after authenticating, paste the full callback URL from your browser's address bar into the URL prompt that appears in Claude Code
  * OAuth authentication works with HTTP servers
</Tip>

### Use a fixed OAuth callback port

Some MCP servers require a specific redirect URI registered in advance. By default, Claude Code picks a random available port for the OAuth callback. Use `--callback-port` to fix the port so it matches a pre-registered redirect URI of the form `http://localhost:PORT/callback`.

You can use `--callback-port` on its own (with dynamic client registration) or together with `--client-id` (with pre-configured credentials).

```bash theme={null}
# Fixed callback port with dynamic client registration
claude mcp add --transport http \
  --callback-port 8080 \
  my-server https://mcp.example.com/mcp
```

### Use pre-configured OAuth credentials

Some MCP servers don't support automatic OAuth setup via Dynamic Client Registration. If you see an error like "Incompatible auth server: does not support dynamic client registration," the server requires pre-configured credentials. Claude Code also supports servers that use a Client ID Metadata Document (CIMD) instead of Dynamic Client Registration, and discovers these automatically. If automatic discovery fails, register an OAuth app through the server's developer portal first, then provide the credentials when adding the server.

<Steps>
  <Step title="Register an OAuth app with the server">
    Create an app through the server's developer portal and note your client ID and client secret.

    Many servers also require a redirect URI. If so, choose a port and register a redirect URI in the format `http://localhost:PORT/callback`. Use that same port with `--callback-port` in the next step.
  </Step>

  <Step title="Add the server with your credentials">
    Choose one of the following methods. The port used for `--callback-port` can be any available port. It just needs to match the redirect URI you registered in the previous step.

    <Tabs>
      <Tab title="claude mcp add">
        Use `--client-id` to pass your app's client ID. The `--client-secret` flag prompts for the secret with masked input:

        ```bash theme={null}
        claude mcp add --transport http \
          --client-id your-client-id --client-secret --callback-port 8080 \
          my-server https://mcp.example.com/mcp
        ```
      </Tab>

      <Tab title="claude mcp add-json">
        Include the `oauth` object in the JSON config and pass `--client-secret` as a separate flag:

        ```bash theme={null}
        claude mcp add-json my-server \
          '{"type":"http","url":"https://mcp.example.com/mcp","oauth":{"clientId":"your-client-id","callbackPort":8080}}' \
          --client-secret
        ```
      </Tab>

      <Tab title="claude mcp add-json (callback port only)">
        Use `--callback-port` without a client ID to fix the port while using dynamic client registration:

        ```bash theme={null}
        claude mcp add-json my-server \
          '{"type":"http","url":"https://mcp.example.com/mcp","oauth":{"callbackPort":8080}}'
        ```
      </Tab>

      <Tab title="CI / env var">
        Set the secret via environment variable to skip the interactive prompt:

        ```bash theme={null}
        MCP_CLIENT_SECRET=your-secret claude mcp add --transport http \
          --client-id your-client-id --client-secret --callback-port 8080 \
          my-server https://mcp.example.com/mcp
        ```
      </Tab>
    </Tabs>
  </Step>

  <Step title="Authenticate in Claude Code">
    Run `/mcp` in Claude Code and follow the browser login flow.
  </Step>
</Steps>

<Tip>
  Tips:

  * The client secret is stored securely in your system keychain (macOS) or a credentials file, not in your config
  * If the server uses a public OAuth client with no secret, use only `--client-id` without `--client-secret`
  * `--callback-port` can be used with or without `--client-id`
  * These flags only apply to HTTP and SSE transports. They have no effect on stdio servers
  * Use `claude mcp get <name>` to verify that OAuth credentials are configured for a server
</Tip>

### Override OAuth metadata discovery

Point Claude Code at a specific OAuth authorization server metadata URL to bypass the default discovery chain. Set `authServerMetadataUrl` when the MCP server's standard endpoints error, or when you want to route discovery through an internal proxy. By default, Claude Code first checks RFC 9728 Protected Resource Metadata at `/.well-known/oauth-protected-resource`, then falls back to RFC 8414 authorization server metadata at `/.well-known/oauth-authorization-server`.

Set `authServerMetadataUrl` in the `oauth` object of your server's config in `.mcp.json`:

```json theme={null}
{
  "mcpServers": {
    "my-server": {
      "type": "http",
      "url": "https://mcp.example.com/mcp",
      "oauth": {
        "authServerMetadataUrl": "https://auth.example.com/.well-known/openid-configuration"
      }
    }
  }
}
```

The URL must use `https://`. `authServerMetadataUrl` requires Claude Code v2.1.64 or later. The metadata URL's `scopes_supported` overrides the scopes the upstream server advertises.

### Restrict OAuth scopes

Set `oauth.scopes` to pin the scopes Claude Code requests during the authorization flow. This is the supported way to restrict an MCP server to a security-team-approved subset when the upstream authorization server advertises more scopes than you want to grant. The value is a single space-separated string, matching the `scope` parameter format in RFC 6749 §3.3.

```json theme={null}
{
  "mcpServers": {
    "slack": {
      "type": "http",
      "url": "https://mcp.slack.com/mcp",
      "oauth": {
        "scopes": "channels:read chat:write search:read"
      }
    }
  }
}
```

`oauth.scopes` takes precedence over both `authServerMetadataUrl` and the scopes the server discovers at `/.well-known`. Leave it unset to let the MCP server determine the requested scope set.

If the authorization server advertises `offline_access` in `scopes_supported`, Claude Code appends it to the pinned scopes so the access token can be refreshed without a new browser sign-in.

If the server later returns a 403 `insufficient_scope` for a tool call, Claude Code re-authenticates with the same pinned scopes. Widen `oauth.scopes` when a tool you need requires a scope outside the pin.

### Use dynamic headers for custom authentication

If your MCP server uses an authentication scheme other than OAuth (such as Kerberos, short-lived tokens, or an internal SSO), use `headersHelper` to generate request headers at connection time. Claude Code runs the command and merges its output into the connection headers.

```json theme={null}
{
  "mcpServers": {
    "internal-api": {
      "type": "http",
      "url": "https://mcp.internal.example.com",
      "headersHelper": "/opt/bin/get-mcp-auth-headers.sh"
    }
  }
}
```

The command can also be inline:

```json theme={null}
{
  "mcpServers": {
    "internal-api": {
      "type": "http",
      "url": "https://mcp.internal.example.com",
      "headersHelper": "echo '{\"Authorization\": \"Bearer '\"$(get-token)\"'\"}'"
    }
  }
}
```

**Requirements:**

* The command must write a JSON object of string key-value pairs to stdout
* The command runs in a shell with a 10-second timeout
* Dynamic headers override any static `headers` with the same name

The helper runs fresh on each connection (at session start and on reconnect). There is no caching, so your script is responsible for any token reuse.

Claude Code sets these environment variables when executing the helper:

| Variable                      | Value                      |
| :---------------------------- | :------------------------- |
| `CLAUDE_CODE_MCP_SERVER_NAME` | the name of the MCP server |
| `CLAUDE_CODE_MCP_SERVER_URL`  | the URL of the MCP server  |

Use these to write a single helper script that serves multiple MCP servers.

<Note>
  `headersHelper` executes arbitrary shell commands. When defined at project or local scope, it only runs after you accept the workspace trust dialog.
</Note>

## Add MCP servers from JSON configuration

If you have a JSON configuration for an MCP server, you can add it directly:

<Steps>
  <Step title="Add an MCP server from JSON">
    ```bash theme={null}
    # Basic syntax
    claude mcp add-json <name> '<json>'

    # Example: Adding an HTTP server with JSON configuration
    claude mcp add-json weather-api '{"type":"http","url":"https://api.weather.com/mcp","headers":{"Authorization":"Bearer token"}}'

    # Example: Adding a stdio server with JSON configuration
    claude mcp add-json local-weather '{"type":"stdio","command":"/path/to/weather-cli","args":["--api-key","abc123"],"env":{"CACHE_DIR":"/tmp"}}'

    # Example: Adding an HTTP server with pre-configured OAuth credentials
    claude mcp add-json my-server '{"type":"http","url":"https://mcp.example.com/mcp","oauth":{"clientId":"your-client-id","callbackPort":8080}}' --client-secret
    ```
  </Step>

  <Step title="Verify the server was added">
    ```bash theme={null}
    claude mcp get weather-api
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Make sure the JSON is properly escaped in your shell
  * The JSON must conform to the MCP server configuration schema
  * You can use `--scope user` to add the server to your user configuration instead of the project-specific one
</Tip>

## Import MCP servers from Claude Desktop

If you've already configured MCP servers in Claude Desktop, you can import them:

<Steps>
  <Step title="Import servers from Claude Desktop">
    ```bash theme={null}
    # Basic syntax 
    claude mcp add-from-claude-desktop 
    ```
  </Step>

  <Step title="Select which servers to import">
    After running the command, you'll see an interactive dialog that allows you to select which servers you want to import.
  </Step>

  <Step title="Verify the servers were imported">
    ```bash theme={null}
    claude mcp list 
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * This feature only works on macOS and Windows Subsystem for Linux (WSL)
  * It reads the Claude Desktop configuration file from its standard location on those platforms
  * Use the `--scope user` flag to add servers to your user configuration
  * Imported servers will have the same names as in Claude Desktop
  * If servers with the same names already exist, they will get a numerical suffix (for example, `server_1`)
</Tip>

## Use MCP servers from Claude.ai

If you've logged into Claude Code with a [Claude.ai](https://claude.ai) account, MCP servers you've added in Claude.ai are automatically available in Claude Code:

<Steps>
  <Step title="Configure MCP servers in Claude.ai">
    Add servers at [claude.ai/customize/connectors](https://claude.ai/customize/connectors). On Team and Enterprise plans, only admins can add servers.
  </Step>

  <Step title="Authenticate the MCP server">
    Complete any required authentication steps in Claude.ai.
  </Step>

  <Step title="View and manage servers in Claude Code">
    In Claude Code, use the command:

    ```text theme={null}
    /mcp
    ```

    Claude.ai servers appear in the list with indicators showing they come from Claude.ai.
  </Step>
</Steps>

Claude.ai connectors are fetched only when your active [authentication method](/en/authentication#authentication-precedence) is your Claude.ai subscription. They are not loaded when `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `apiKeyHelper`, or a third-party provider such as Bedrock or Vertex is active, even if you previously ran `/login`. If `/mcp` does not list a connector you added, run `/status` to confirm which authentication method is active, unset that environment variable or remove the `apiKeyHelper` setting, then run `/login` to select your Claude.ai account.

A server you've added in Claude Code takes [precedence](#scope-hierarchy-and-precedence) over a claude.ai connector that points at the same URL. When this happens, `/mcp` lists the connector as hidden and shows how to remove the duplicate if you'd rather use the connector.

To disable claude.ai MCP servers in Claude Code, set the `ENABLE_CLAUDEAI_MCP_SERVERS` environment variable to `false`:

```bash theme={null}
ENABLE_CLAUDEAI_MCP_SERVERS=false claude
```

## Use Claude Code as an MCP server

You can use Claude Code itself as an MCP server that other applications can connect to:

```bash theme={null}
# Start Claude as a stdio MCP server
claude mcp serve
```

You can use this in Claude Desktop by adding this configuration to claude\_desktop\_config.json:

```json theme={null}
{
  "mcpServers": {
    "claude-code": {
      "type": "stdio",
      "command": "claude",
      "args": ["mcp", "serve"],
      "env": {}
    }
  }
}
```

<Warning>
  **Configuring the executable path**: The `command` field must reference the Claude Code executable. If the `claude` command is not in your system's PATH, you'll need to specify the full path to the executable.

  To find the full path:

  ```bash theme={null}
  which claude
  ```

  Then use the full path in your configuration:

  ```json theme={null}
  {
    "mcpServers": {
      "claude-code": {
        "type": "stdio",
        "command": "/full/path/to/claude",
        "args": ["mcp", "serve"],
        "env": {}
      }
    }
  }
  ```

  Without the correct executable path, you'll encounter errors like `spawn claude ENOENT`.
</Warning>

<Tip>
  Tips:

  * The server provides access to Claude's tools like View, Edit, LS, etc.
  * In Claude Desktop, try asking Claude to read files in a directory, make edits, and more.
  * Note that this MCP server is only exposing Claude Code's tools to your MCP client, so your own client is responsible for implementing user confirmation for individual tool calls.
</Tip>

## MCP output limits and warnings

When MCP tools produce large outputs, Claude Code helps manage the token usage to prevent overwhelming your conversation context:

* **Output warning threshold**: Claude Code displays a warning when any MCP tool output exceeds 10,000 tokens
* **Configurable limit**: you can adjust the maximum allowed MCP output tokens using the `MAX_MCP_OUTPUT_TOKENS` environment variable
* **Default limit**: the default maximum is 25,000 tokens
* **Scope**: the environment variable applies to tools that don't declare their own limit. Tools that set [`anthropic/maxResultSizeChars`](#raise-the-limit-for-a-specific-tool) use that value instead for text content, regardless of what `MAX_MCP_OUTPUT_TOKENS` is set to. Tools that return image data are still subject to `MAX_MCP_OUTPUT_TOKENS`

To increase the limit for tools that produce large outputs:

```bash theme={null}
export MAX_MCP_OUTPUT_TOKENS=50000
claude
```

This is particularly useful when working with MCP servers that:

* Query large datasets or databases
* Generate detailed reports or documentation
* Process extensive log files or debugging information

### Raise the limit for a specific tool

If you're building an MCP server, you can allow individual tools to return results larger than the default persist-to-disk threshold by setting `_meta["anthropic/maxResultSizeChars"]` in the tool's `tools/list` response entry. Claude Code raises that tool's threshold to the annotated value, up to a hard ceiling of 500,000 characters.

This is useful for tools that return inherently large but necessary outputs, such as database schemas or full file trees. Without the annotation, results that exceed the default threshold are persisted to disk and replaced with a file reference in the conversation.

```json theme={null}
{
  "name": "get_schema",
  "description": "Returns the full database schema",
  "_meta": {
    "anthropic/maxResultSizeChars": 200000
  }
}
```

The annotation applies independently of `MAX_MCP_OUTPUT_TOKENS` for text content, so users don't need to raise the environment variable for tools that declare it. Tools that return image data are still subject to the token limit.

<Warning>
  If you frequently encounter output warnings with specific MCP servers you don't control, consider increasing the `MAX_MCP_OUTPUT_TOKENS` limit. You can also ask the server author to add the `anthropic/maxResultSizeChars` annotation or to paginate their responses. The annotation has no effect on tools that return image content; for those, raising `MAX_MCP_OUTPUT_TOKENS` is the only option.
</Warning>

## Respond to MCP elicitation requests

MCP servers can request structured input from you mid-task using elicitation. When a server needs information it can't get on its own, Claude Code displays an interactive dialog and passes your response back to the server. No configuration is required on your side: elicitation dialogs appear automatically when a server requests them.

Servers can request input in two ways:

* **Form mode**: Claude Code shows a dialog with form fields defined by the server (for example, a username and password prompt). Fill in the fields and submit.
* **URL mode**: Claude Code opens a browser URL for authentication or approval. Complete the flow in the browser, then confirm in the CLI.

To auto-respond to elicitation requests without showing a dialog, use the [`Elicitation` hook](/en/hooks#elicitation).

If you're building an MCP server that uses elicitation, see the [MCP elicitation specification](https://modelcontextprotocol.io/docs/learn/client-concepts#elicitation) for protocol details and schema examples.

## Use MCP resources

MCP servers can expose resources that you can reference using @ mentions, similar to how you reference files.

### Reference MCP resources

<Steps>
  <Step title="List available resources">
    Type `@` in your prompt to see available resources from all connected MCP servers. Resources appear alongside files in the autocomplete menu.
  </Step>

  <Step title="Reference a specific resource">
    Use the format `@server:protocol://resource/path` to reference a resource:

    ```text theme={null}
    Can you analyze @github:issue://123 and suggest a fix?
    ```

    ```text theme={null}
    Please review the API documentation at @docs:file://api/authentication
    ```
  </Step>

  <Step title="Multiple resource references">
    You can reference multiple resources in a single prompt:

    ```text theme={null}
    Compare @postgres:schema://users with @docs:file://database/user-model
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * Resources are automatically fetched and included as attachments when referenced
  * Resource paths are fuzzy-searchable in the @ mention autocomplete
  * Claude Code automatically provides tools to list and read MCP resources when servers support them
  * Resources can contain any type of content that the MCP server provides (text, JSON, structured data, etc.)
</Tip>

## Scale with MCP Tool Search

Tool search keeps MCP context usage low by deferring tool definitions until Claude needs them. Only tool names load at session start, so adding more MCP servers has minimal impact on your context window.

### How it works

Tool search is enabled by default. MCP tools are deferred rather than loaded into context upfront, and Claude uses a search tool to discover relevant ones when a task needs them. Only the tools Claude actually uses enter context. From your perspective, MCP tools work exactly as before.

If you prefer threshold-based loading, set `ENABLE_TOOL_SEARCH=auto` to load schemas upfront when they fit within 10% of the context window and defer only the overflow. See [Configure tool search](#configure-tool-search) for all options.

### For MCP server authors

If you're building an MCP server, the server instructions field becomes more useful with Tool Search enabled. Server instructions help Claude understand when to search for your tools, similar to how [skills](/en/skills) work.

Add clear, descriptive server instructions that explain:

* What category of tasks your tools handle
* When Claude should search for your tools
* Key capabilities your server provides

Claude Code truncates tool descriptions and server instructions at 2KB each. Keep them concise to avoid truncation, and put critical details near the start.

### Configure tool search

Tool search is enabled by default: MCP tools are deferred and discovered on demand. Claude Code disables it by default on Vertex AI. It is also disabled when `ANTHROPIC_BASE_URL` points to a non-first-party host, since most proxies do not forward `tool_reference` blocks. Set `ENABLE_TOOL_SEARCH` explicitly to override either fallback.

Tool search requires a model that supports `tool_reference` blocks: Sonnet 4 and later, or Opus 4 and later. Haiku models do not support it. On Vertex AI, tool search is supported for Claude Sonnet 4.5 and later and Claude Opus 4.5 and later.

Control tool search behavior with the `ENABLE_TOOL_SEARCH` environment variable:

| Value    | Behavior                                                                                                                                                                                                                          |
| :------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| (unset)  | All MCP tools deferred and loaded on demand. Falls back to loading upfront on Vertex AI or when `ANTHROPIC_BASE_URL` is a non-first-party host                                                                                    |
| `true`   | All MCP tools deferred. Claude Code sends the beta header even on Vertex AI and through proxies. Requests fail on Vertex AI models earlier than Sonnet 4.5 or Opus 4.5, or on proxies that do not support `tool_reference` blocks |
| `auto`   | Threshold mode: tools load upfront if they fit within 10% of the context window, deferred otherwise                                                                                                                               |
| `auto:N` | Threshold mode with a custom percentage, where `N` is 0-100. For example, `auto:5` for 5%                                                                                                                                         |
| `false`  | All MCP tools loaded upfront, no deferral                                                                                                                                                                                         |

```bash theme={null}
# Use a custom 5% threshold
ENABLE_TOOL_SEARCH=auto:5 claude

# Disable tool search entirely
ENABLE_TOOL_SEARCH=false claude
```

Or set the value in your [settings.json `env` field](/en/settings#available-settings).

You can also disable the `ToolSearch` tool specifically:

```json theme={null}
{
  "permissions": {
    "deny": ["ToolSearch"]
  }
}
```

### Exempt a server from deferral

If a server's tools should always be visible to Claude without a search step, set `alwaysLoad` to `true` in that server's configuration. Every tool from that server then loads into context at session start regardless of the `ENABLE_TOOL_SEARCH` setting. Use this for a small number of tools that Claude needs on every turn, since each upfront tool consumes context that would otherwise be available for your conversation.

The following `.mcp.json` entry exempts one HTTP server while leaving other servers deferred:

```json theme={null}
{
  "mcpServers": {
    "core-tools": {
      "type": "http",
      "url": "https://mcp.example.com/mcp",
      "alwaysLoad": true
    }
  }
}
```

The `alwaysLoad` field is available on all server types and requires Claude Code v2.1.121 or later. An MCP server can also mark individual tools as always-loaded by including `"anthropic/alwaysLoad": true` in the tool's `_meta` object, which has the same effect for that tool only.

Setting `alwaysLoad: true` also blocks startup until the server connects, capped at the standard 5-second connect timeout. This applies even though MCP startup is otherwise [non-blocking by default](/en/env-vars), since the tools must be present when the first prompt is built. Other servers continue to connect in the background.

## Use MCP prompts as commands

MCP servers can expose prompts that become available as commands in Claude Code.

### Execute MCP prompts

<Steps>
  <Step title="Discover available prompts">
    Type `/` to see all available commands, including those from MCP servers. MCP prompts appear with the format `/mcp__servername__promptname`.
  </Step>

  <Step title="Execute a prompt without arguments">
    ```text theme={null}
    /mcp__github__list_prs
    ```
  </Step>

  <Step title="Execute a prompt with arguments">
    Many prompts accept arguments. Pass them space-separated after the command:

    ```text theme={null}
    /mcp__github__pr_review 456
    ```

    ```text theme={null}
    /mcp__jira__create_issue "Bug in login flow" high
    ```
  </Step>
</Steps>

<Tip>
  Tips:

  * MCP prompts are dynamically discovered from connected servers
  * Arguments are parsed based on the prompt's defined parameters
  * Prompt results are injected directly into the conversation
  * Server and prompt names are normalized (spaces become underscores)
</Tip>

## Managed MCP configuration

For organizations that need centralized control over which MCP servers users can connect to, see [Managed MCP configuration](/en/managed-mcp). It covers deploying a fixed server set with `managed-mcp.json`, restricting servers with `allowedMcpServers` and `deniedMcpServers`, and what users see when a server is blocked.

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Discover and install prebuilt plugins through marketplaces

> Find and install plugins from marketplaces to extend Claude Code with new skills, agents, and capabilities.

Plugins extend Claude Code with skills, agents, hooks, and MCP servers. Plugin marketplaces are catalogs that help you discover and install these extensions without building them yourself.

Looking to create and distribute your own marketplace? See [Create and distribute a plugin marketplace](/en/plugin-marketplaces).

## How marketplaces work

A marketplace is a catalog of plugins that someone else has created and shared. Using a marketplace is a two-step process:

<Steps>
  <Step title="Add the marketplace">
    This registers the catalog with Claude Code so you can browse what's available. No plugins are installed yet.
  </Step>

  <Step title="Install individual plugins">
    Browse the catalog and install the plugins you want.
  </Step>
</Steps>

Think of it like adding an app store: adding the store gives you access to browse its collection, but you still choose which apps to download individually.

## Official Anthropic marketplace

The official Anthropic marketplace (`claude-plugins-official`) is automatically available when you start Claude Code. Run `/plugin` and go to the **Discover** tab to browse what's available, or view the catalog at [claude.com/plugins](https://claude.com/plugins).

To install a plugin from the official marketplace, use `/plugin install <name>@claude-plugins-official`. For example, to install the GitHub integration:

```shell theme={null}
/plugin install github@claude-plugins-official
```

If Claude Code reports that the plugin is not found in any marketplace, your marketplace is either missing or outdated. Run `/plugin marketplace update claude-plugins-official` to refresh it, or `/plugin marketplace add anthropics/claude-plugins-official` if you haven't added it before. Then retry the install.

<Note>
  The official marketplace is curated by Anthropic, and inclusion is at Anthropic's discretion. The in-app submission forms add plugins to the [community marketplace](#community-marketplace), not the official one. To distribute plugins independently, [create your own marketplace](/en/plugin-marketplaces) and share it with users.
</Note>

The official marketplace includes several categories of plugins:

### Code intelligence

Code intelligence plugins enable Claude Code's built-in LSP tool, giving Claude the ability to jump to definitions, find references, and see type errors immediately after edits. These plugins configure [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) connections, the same technology that powers VS Code's code intelligence.

These plugins require the language server binary to be installed on your system. If you already have a language server installed, Claude may prompt you to install the corresponding plugin when you open a project.

| Language   | Plugin              | Binary required              |
| :--------- | :------------------ | :--------------------------- |
| C/C++      | `clangd-lsp`        | `clangd`                     |
| C#         | `csharp-lsp`        | `csharp-ls`                  |
| Go         | `gopls-lsp`         | `gopls`                      |
| Java       | `jdtls-lsp`         | `jdtls`                      |
| Kotlin     | `kotlin-lsp`        | `kotlin-language-server`     |
| Lua        | `lua-lsp`           | `lua-language-server`        |
| PHP        | `php-lsp`           | `intelephense`               |
| Python     | `pyright-lsp`       | `pyright-langserver`         |
| Rust       | `rust-analyzer-lsp` | `rust-analyzer`              |
| Swift      | `swift-lsp`         | `sourcekit-lsp`              |
| TypeScript | `typescript-lsp`    | `typescript-language-server` |

You can also [create your own LSP plugin](/en/plugins-reference#lsp-servers) for other languages.

<Note>
  If you see `Executable not found in $PATH` in the `/plugin` Errors tab after installing a plugin, install the required binary from the table above.
</Note>

#### What Claude gains from code intelligence plugins

Once a code intelligence plugin is installed and its language server binary is available, Claude gains two capabilities:

* **Automatic diagnostics**: after every file edit Claude makes, the language server analyzes the changes and reports errors and warnings back automatically. Claude sees type errors, missing imports, and syntax issues without needing to run a compiler or linter. If Claude introduces an error, it notices and fixes the issue in the same turn. This requires no configuration beyond installing the plugin. You can see diagnostics inline by pressing **Ctrl+O** when the "diagnostics found" indicator appears.
* **Code navigation**: Claude can use the language server to jump to definitions, find references, get type info on hover, list symbols, find implementations, and trace call hierarchies. These operations give Claude more precise navigation than grep-based search, though availability may vary by language and environment.

If you run into issues, see [Code intelligence troubleshooting](#code-intelligence-issues).

### External integrations

These plugins bundle pre-configured [MCP servers](/en/mcp) so you can connect Claude to external services without manual setup:

* **Source control**: `github`, `gitlab`
* **Project management**: `atlassian` (Jira/Confluence), `asana`, `linear`, `notion`
* **Design**: `figma`
* **Infrastructure**: `vercel`, `firebase`, `supabase`
* **Communication**: `slack`
* **Monitoring**: `sentry`

### Development workflows

Plugins that add skills and agents for common development tasks:

* **commit-commands**: Git commit workflows including commit, push, and PR creation
* **pr-review-toolkit**: Specialized agents for reviewing pull requests
* **agent-sdk-dev**: Tools for building with the Claude Agent SDK
* **plugin-dev**: Toolkit for creating your own plugins

### Output styles

Customize how Claude responds:

* **explanatory-output-style**: Educational insights about implementation choices
* **learning-output-style**: Interactive learning mode for skill building

## Community marketplace

The community marketplace at [`anthropics/claude-plugins-community`](https://github.com/anthropics/claude-plugins-community) hosts third-party plugins that have passed Anthropic's automated validation and safety screening. Each plugin is pinned to a specific commit SHA in the catalog. Unlike the official marketplace, you add it manually:

```shell theme={null}
/plugin marketplace add anthropics/claude-plugins-community
```

Then install plugins from it using the `claude-community` marketplace name:

```shell theme={null}
/plugin install <plugin-name>@claude-community
```

To submit your own plugin to the community marketplace, see [Submit your plugin to the community marketplace](/en/plugins#submit-your-plugin-to-the-community-marketplace) in the create-plugins guide.

## Try it: add the demo marketplace

Anthropic also maintains a [demo plugins marketplace](https://github.com/anthropics/claude-code/tree/main/plugins) (`claude-code-plugins`) with example plugins that show what's possible with the plugin system. Unlike the official marketplace, you need to add this one manually.

<Steps>
  <Step title="Add the marketplace">
    From within Claude Code, run the `plugin marketplace add` command for the `anthropics/claude-code` marketplace:

    ```shell theme={null}
    /plugin marketplace add anthropics/claude-code
    ```

    This downloads the marketplace catalog and makes its plugins available to you.
  </Step>

  <Step title="Browse available plugins">
    Run `/plugin` to open the plugin manager. This opens a tabbed interface with four tabs you can cycle through using **Tab** (or **Shift+Tab** to go backward):

    * **Discover**: browse available plugins from all your marketplaces
    * **Installed**: view and manage your installed plugins
    * **Marketplaces**: add, remove, or update your added marketplaces
    * **Errors**: view any plugin loading errors

    Go to the **Discover** tab to see plugins from the marketplace you just added.
  </Step>

  <Step title="Install a plugin">
    Select a plugin to view its details. The details pane shows what the plugin contains and what it costs:

    * {/* min-version: 2.1.143 */}A **Context cost** estimate so you can see how many tokens the plugin will add to your [context window](/en/features-overview#understand-context-costs) every turn (Claude Code v2.1.143 and later)
    * {/* min-version: 2.1.144 */}The plugin's **Last updated** date (v2.1.144 and later)
    * {/* min-version: 2.1.145 */}A **Will install** section listing the plugin's commands, agents, skills, hooks, and MCP and LSP servers, so you can review exactly what it adds before installing (v2.1.145 and later)

    Choose an installation scope:

    * **User scope**: install for yourself across all projects
    * **Project scope**: install for all collaborators on this repository
    * **Local scope**: install for yourself in this repository only

    For example, select **commit-commands** (a plugin that adds git workflow skills) and install it to your user scope.

    You can also install directly from the command line:

    ```shell theme={null}
    /plugin install commit-commands@anthropics-claude-code
    ```

    See [Configuration scopes](/en/settings#configuration-scopes) to learn more about scopes.
  </Step>

  <Step title="Use your new plugin">
    After installing, run `/reload-plugins` to activate the plugin. Plugin skills are namespaced by the plugin name, so **commit-commands** provides skills like `/commit-commands:commit`.

    Try it out by making a change to a file and running:

    ```shell theme={null}
    /commit-commands:commit
    ```

    This stages your changes, generates a commit message, and creates the commit.

    Each plugin works differently. Check the plugin's details in the **Discover** tab to see the commands and skills it provides, or visit its homepage for usage guidance.
  </Step>
</Steps>

The rest of this guide covers all the ways you can add marketplaces, install plugins, and manage your configuration.

## Add marketplaces

Use the `/plugin marketplace add` command to add marketplaces from different sources.

<Tip>
  **Shortcuts**: You can use `/plugin market` instead of `/plugin marketplace`, and `rm` instead of `remove`.
</Tip>

* **GitHub repositories**: `owner/repo` format (for example, `anthropics/claude-code`)
* **Git URLs**: any git repository URL (GitLab, Bitbucket, self-hosted)
* **Local paths**: directories or direct paths to `marketplace.json` files
* **Remote URLs**: direct URLs to hosted `marketplace.json` files

### Add from GitHub

Add a GitHub repository that contains a `.claude-plugin/marketplace.json` file using the `owner/repo` format—where `owner` is the GitHub username or organization and `repo` is the repository name.

For example, `anthropics/claude-code` refers to the `claude-code` repository owned by `anthropics`:

```shell theme={null}
/plugin marketplace add anthropics/claude-code
```

### Add from other Git hosts

Add any git repository by providing the full URL. This works with any Git host, including GitLab, Bitbucket, and self-hosted servers. Include the `.git` suffix so Claude Code clones the repository rather than treating the URL as a direct link to a hosted `marketplace.json` file.

Using HTTPS:

```shell theme={null}
/plugin marketplace add https://gitlab.com/company/plugins.git
```

Using SSH:

```shell theme={null}
/plugin marketplace add git@gitlab.com:company/plugins.git
```

To add a specific branch or tag, append `#` followed by the ref:

```shell theme={null}
/plugin marketplace add https://gitlab.com/company/plugins.git#v1.0.0
```

### Add from local paths

Add a local directory that contains a `.claude-plugin/marketplace.json` file:

```shell theme={null}
/plugin marketplace add ./my-marketplace
```

You can also add a direct path to a `marketplace.json` file:

```shell theme={null}
/plugin marketplace add ./path/to/marketplace.json
```

### Add from remote URLs

Add a remote `marketplace.json` file via URL:

```shell theme={null}
/plugin marketplace add https://example.com/marketplace.json
```

<Note>
  URL-based marketplaces have some limitations compared to Git-based marketplaces. If you encounter "path not found" errors when installing plugins, see [Troubleshooting](/en/plugin-marketplaces#plugins-with-relative-paths-fail-in-url-based-marketplaces).
</Note>

## Install plugins

Once you've added marketplaces, you can install plugins directly (installs to user scope by default):

```shell theme={null}
/plugin install plugin-name@marketplace-name
```

To choose a different [installation scope](/en/settings#configuration-scopes), use the interactive UI: run `/plugin`, go to the **Discover** tab, and press **Enter** on a plugin. You'll see options for:

* **User scope** (default): install for yourself across all projects
* **Project scope**: install for all collaborators on this repository (adds to `.claude/settings.json`)
* **Local scope**: install for yourself in this repository only (not shared with collaborators)

You may also see plugins with **managed** scope—these are installed by administrators via [managed settings](/en/settings#settings-files) and cannot be modified.

<Warning>
  Make sure you trust a plugin before installing it. Anthropic does not control what MCP servers, files, or other software are included in plugins and cannot verify that they work as intended. Check each plugin's homepage for more information.
</Warning>

## Manage installed plugins

Run `/plugin` and go to the **Installed** tab to view, enable, disable, or uninstall your plugins. The list is grouped by scope and sorted so you see problems first: plugins with load errors or unresolved dependencies appear at the top, followed by your favorites, with disabled plugins folded behind a collapsed header at the bottom.

From the list you can:

* press `f` to favorite or unfavorite the selected plugin
* type to filter by plugin name or description
* press Enter to open a plugin's detail view and enable, disable, or uninstall it

When you install a plugin that declares dependencies, the install output lists which dependencies were auto-installed alongside it.

You can also manage plugins with direct commands.

Disable a plugin without uninstalling:

```shell theme={null}
/plugin disable plugin-name@marketplace-name
```

Re-enable a disabled plugin:

```shell theme={null}
/plugin enable plugin-name@marketplace-name
```

Completely remove a plugin:

```shell theme={null}
/plugin uninstall plugin-name@marketplace-name
```

The `--scope` option lets you target a specific scope with CLI commands:

```shell theme={null}
claude plugin install formatter@your-org --scope project
claude plugin uninstall formatter@your-org --scope project
```

### Apply plugin changes without restarting

When you install, enable, or disable plugins during a session, run `/reload-plugins` to pick up all changes without restarting:

```shell theme={null}
/reload-plugins
```

Claude Code reloads all active plugins and shows counts for plugins, skills, agents, hooks, plugin MCP servers, and plugin LSP servers.

## Manage marketplaces

You can manage marketplaces through the interactive `/plugin` interface or with CLI commands.

### Use the interactive interface

Run `/plugin` and go to the **Marketplaces** tab to:

* View all your added marketplaces with their sources and status
* Add new marketplaces
* Update marketplace listings to fetch the latest plugins
* Remove marketplaces you no longer need

### Use CLI commands

You can also manage marketplaces with direct commands.

List all configured marketplaces:

```shell theme={null}
/plugin marketplace list
```

Refresh plugin listings from a marketplace:

```shell theme={null}
/plugin marketplace update marketplace-name
```

Remove a marketplace:

```shell theme={null}
/plugin marketplace remove marketplace-name
```

<Warning>
  Removing a marketplace will uninstall any plugins you installed from it.
</Warning>

### Configure auto-updates

Claude Code can automatically update marketplaces and their installed plugins at startup. When auto-update is enabled for a marketplace, Claude Code refreshes the marketplace data and updates installed plugins to their latest versions. If any plugins were updated, you'll see a notification prompting you to run `/reload-plugins`.

Toggle auto-update for individual marketplaces through the UI:

1. Run `/plugin` to open the plugin manager
2. Select **Marketplaces**
3. Choose a marketplace from the list
4. Select **Enable auto-update** or **Disable auto-update**

Official Anthropic marketplaces have auto-update enabled by default. Third-party and local development marketplaces have auto-update disabled by default.

Administrators can also set `"autoUpdate": true` on each [`extraKnownMarketplaces`](/en/settings#extraknownmarketplaces) entry in managed settings to enable auto-update for an organization marketplace without requiring each user to toggle it.

To disable all automatic updates entirely for both Claude Code and all plugins, set the `DISABLE_AUTOUPDATER` environment variable. See [Auto updates](/en/setup#auto-updates) for details.

To keep plugin auto-updates enabled while disabling Claude Code auto-updates, set `FORCE_AUTOUPDATE_PLUGINS=1` along with `DISABLE_AUTOUPDATER`:

```bash theme={null}
export DISABLE_AUTOUPDATER=1
export FORCE_AUTOUPDATE_PLUGINS=1
```

This is useful when you want to manage Claude Code updates manually but still receive automatic plugin updates.

## Configure team marketplaces

Team admins can set up automatic marketplace installation for projects by adding marketplace configuration to `.claude/settings.json`. When team members trust the repository folder, Claude Code prompts them to install these marketplaces and plugins.

Add `extraKnownMarketplaces` to your project's `.claude/settings.json`:

```json theme={null}
{
  "extraKnownMarketplaces": {
    "my-team-tools": {
      "source": {
        "source": "github",
        "repo": "your-org/claude-plugins"
      }
    }
  }
}
```

For full configuration options including `extraKnownMarketplaces` and `enabledPlugins`, see [Plugin settings](/en/settings#plugin-settings).

## Security

Plugins and marketplaces are highly trusted components that can execute arbitrary code on your machine with your user privileges. Only install plugins and add marketplaces from sources you trust. Organizations can restrict which marketplaces users are allowed to add using [managed marketplace restrictions](/en/plugin-marketplaces#managed-marketplace-restrictions).

## Troubleshooting

### /plugin command not recognized

If you see "unknown command" or the `/plugin` command doesn't appear:

1. **Check your version**: Run `claude --version` to see what's installed.
2. **Update Claude Code**:
   * **Homebrew**: `brew upgrade claude-code` (or `brew upgrade claude-code@latest` if you installed that cask)
   * **npm**: `npm install -g @anthropic-ai/claude-code@latest`
   * **Native installer**: Re-run the install command from [Setup](/en/setup)
3. **Restart Claude Code**: After updating, restart your terminal and run `claude` again.

### Common issues

* **Marketplace not loading**: Verify the URL is accessible and that `.claude-plugin/marketplace.json` exists at the path
* **Plugin installation failures**: Check that plugin source URLs are accessible and repositories are public (or you have access)
* **Files not found after installation**: Plugins are copied to a cache, so paths referencing files outside the plugin directory won't work
* **Plugin skills not appearing**: Clear the cache with `rm -rf ~/.claude/plugins/cache`, restart Claude Code, and reinstall the plugin.

For detailed troubleshooting with solutions, see [Troubleshooting](/en/plugin-marketplaces#troubleshooting) in the marketplace guide. For debugging tools, see [Debugging and development tools](/en/plugins-reference#debugging-and-development-tools).

### Code intelligence issues

* **Language server not starting**: verify the binary is installed and available in your `$PATH`. Check the `/plugin` Errors tab for details.
* **High memory usage**: language servers like `rust-analyzer` and `pyright` can consume significant memory on large projects. If you experience memory issues, disable the plugin with `/plugin disable <plugin-name>` and rely on Claude's built-in search tools instead.
* **False positive diagnostics in monorepos**: language servers may report unresolved import errors for internal packages if the workspace isn't configured correctly. These don't affect Claude's ability to edit code.

## Next steps

* **Build your own plugins**: See [Plugins](/en/plugins) to create skills, agents, and hooks
* **Create a marketplace**: See [Create a plugin marketplace](/en/plugin-marketplaces) to distribute plugins to your team or community
* **Technical reference**: See [Plugins reference](/en/plugins-reference) for complete specifications

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Create plugins

> Create custom plugins to extend Claude Code with skills, agents, hooks, and MCP servers.

Plugins let you extend Claude Code with custom functionality that can be shared across projects and teams. This guide covers creating your own plugins with skills, agents, hooks, and MCP servers.

Looking to install existing plugins? See [Discover and install plugins](/en/discover-plugins). For complete technical specifications, see [Plugins reference](/en/plugins-reference).

## When to use plugins vs standalone configuration

Claude Code supports two ways to add custom skills, agents, and hooks:

| Approach                                                    | Skill names          | Best for                                                                                        |
| :---------------------------------------------------------- | :------------------- | :---------------------------------------------------------------------------------------------- |
| **Standalone** (`.claude/` directory)                       | `/hello`             | Personal workflows, project-specific customizations, quick experiments                          |
| **Plugins** (directories with `.claude-plugin/plugin.json`) | `/plugin-name:hello` | Sharing with teammates, distributing to community, versioned releases, reusable across projects |

**Use standalone configuration when**:

* You're customizing Claude Code for a single project
* The configuration is personal and doesn't need to be shared
* You're experimenting with skills or hooks before packaging them
* You want short skill names like `/hello` or `/deploy`

**Use plugins when**:

* You want to share functionality with your team or community
* You need the same skills/agents across multiple projects
* You want version control and easy updates for your extensions
* You're distributing through a marketplace
* You're okay with namespaced skills like `/my-plugin:hello` (namespacing prevents conflicts between plugins)

<Tip>
  Start with standalone configuration in `.claude/` for quick iteration, then [convert to a plugin](#convert-existing-configurations-to-plugins) when you're ready to share.
</Tip>

## Quickstart

This quickstart walks you through creating a plugin with a custom skill. You'll create a manifest (the configuration file that defines your plugin), add a skill, and test it locally using the `--plugin-dir` flag.

### Prerequisites

* Claude Code [installed and authenticated](/en/quickstart#step-1-install-claude-code)

<Note>
  If you don't see the `/plugin` command, update Claude Code to the latest version. See [Troubleshooting](/en/troubleshooting) for upgrade instructions.
</Note>

### Create your first plugin

<Steps>
  <Step title="Create the plugin directory">
    Every plugin lives in its own directory containing a manifest and your skills, agents, or hooks. Create one now:

    ```bash theme={null}
    mkdir my-first-plugin
    ```
  </Step>

  <Step title="Create the plugin manifest">
    The manifest file at `.claude-plugin/plugin.json` defines your plugin's identity: its name, description, and version. Claude Code uses this metadata to display your plugin in the plugin manager.

    Create the `.claude-plugin` directory inside your plugin folder:

    ```bash theme={null}
    mkdir my-first-plugin/.claude-plugin
    ```

    Then create `my-first-plugin/.claude-plugin/plugin.json` with this content:

    ```json my-first-plugin/.claude-plugin/plugin.json theme={null}
    {
      "name": "my-first-plugin",
      "description": "A greeting plugin to learn the basics",
      "version": "1.0.0",
      "author": {
        "name": "Your Name"
      }
    }
    ```

    | Field         | Purpose                                                                                                                                                                                                                                                        |
    | :------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
    | `name`        | Unique identifier and skill namespace. Skills are prefixed with this (e.g., `/my-first-plugin:hello`).                                                                                                                                                         |
    | `description` | Shown in the plugin manager when browsing or installing plugins.                                                                                                                                                                                               |
    | `version`     | Optional. If set, users only receive updates when you bump this field. If omitted and your plugin is distributed via git, the commit SHA is used and every commit counts as a new version. See [version management](/en/plugins-reference#version-management). |
    | `author`      | Optional. Helpful for attribution.                                                                                                                                                                                                                             |

    For additional fields like `homepage`, `repository`, and `license`, see the [full manifest schema](/en/plugins-reference#plugin-manifest-schema).
  </Step>

  <Step title="Add a skill">
    Skills live in the `skills/` directory. Each skill is a folder containing a `SKILL.md` file. The folder name becomes the skill name, prefixed with the plugin's namespace (`hello/` in a plugin named `my-first-plugin` creates `/my-first-plugin:hello`).

    Create a skill directory in your plugin folder:

    ```bash theme={null}
    mkdir -p my-first-plugin/skills/hello
    ```

    Then create `my-first-plugin/skills/hello/SKILL.md` with this content:

    ```markdown my-first-plugin/skills/hello/SKILL.md theme={null}
    ---
    description: Greet the user with a friendly message
    disable-model-invocation: true
    ---

    Greet the user warmly and ask how you can help them today.
    ```
  </Step>

  <Step title="Test your plugin">
    Run Claude Code with the `--plugin-dir` flag to load your plugin:

    ```bash theme={null}
    claude --plugin-dir ./my-first-plugin
    ```

    Once Claude Code starts, try your new skill:

    ```shell theme={null}
    /my-first-plugin:hello
    ```

    You'll see Claude respond with a greeting. Run `/help` to see your skill listed under the plugin namespace.

    <Note>
      **Why namespacing?** Plugin skills are always namespaced (like `/my-first-plugin:hello`) to prevent conflicts when multiple plugins have skills with the same name.

      To change the namespace prefix, update the `name` field in `plugin.json`.
    </Note>
  </Step>

  <Step title="Add skill arguments">
    Make your skill dynamic by accepting user input. The `$ARGUMENTS` placeholder captures any text the user provides after the skill name.

    Update your `SKILL.md` file:

    ```markdown my-first-plugin/skills/hello/SKILL.md theme={null}
    ---
    description: Greet the user with a personalized message
    ---

    # Hello Skill

    Greet the user named "$ARGUMENTS" warmly and ask how you can help them today. Make the greeting personal and encouraging.
    ```

    Run `/reload-plugins` to pick up the changes, then try the skill with your name:

    ```shell theme={null}
    /my-first-plugin:hello Alex
    ```

    Claude will greet you by name. For more on passing arguments to skills, see [Skills](/en/skills#pass-arguments-to-skills).
  </Step>
</Steps>

You've successfully created and tested a plugin with these key components:

* **Plugin manifest** (`.claude-plugin/plugin.json`): describes your plugin's metadata
* **Skills directory** (`skills/`): contains your custom skills
* **Skill arguments** (`$ARGUMENTS`): captures user input for dynamic behavior

<Tip>
  The `--plugin-dir` flag is useful for development and testing. When you're ready to share your plugin with others, see [Create and distribute a plugin marketplace](/en/plugin-marketplaces).
</Tip>

## Plugin structure overview

You've created a plugin with a skill, but plugins can include much more: custom agents, hooks, MCP servers, LSP servers, and background monitors.

<Warning>
  **Common mistake**: Don't put `commands/`, `agents/`, `skills/`, or `hooks/` inside the `.claude-plugin/` directory. Only `plugin.json` goes inside `.claude-plugin/`. All other directories must be at the plugin root level.
</Warning>

| Directory         | Location    | Purpose                                                                        |
| :---------------- | :---------- | :----------------------------------------------------------------------------- |
| `.claude-plugin/` | Plugin root | Contains `plugin.json` manifest (optional if components use default locations) |
| `skills/`         | Plugin root | Skills as `<name>/SKILL.md` directories                                        |
| `commands/`       | Plugin root | Skills as flat Markdown files. Use `skills/` for new plugins                   |
| `agents/`         | Plugin root | Custom agent definitions                                                       |
| `hooks/`          | Plugin root | Event handlers in `hooks.json`                                                 |
| `.mcp.json`       | Plugin root | MCP server configurations                                                      |
| `.lsp.json`       | Plugin root | LSP server configurations for code intelligence                                |
| `monitors/`       | Plugin root | Background monitor configurations in `monitors.json`                           |
| `bin/`            | Plugin root | Executables added to the Bash tool's `PATH` while the plugin is enabled        |
| `settings.json`   | Plugin root | Default [settings](/en/settings) applied when the plugin is enabled            |

<Note>
  **Next steps**: Ready to add more features? Jump to [Develop more complex plugins](#develop-more-complex-plugins) to add agents, hooks, MCP servers, and LSP servers. For complete technical specifications of all plugin components, see [Plugins reference](/en/plugins-reference).
</Note>

## Develop more complex plugins

Once you're comfortable with basic plugins, you can create more sophisticated extensions.

### Add Skills to your plugin

Plugins can include [Agent Skills](/en/skills) to extend Claude's capabilities. Skills are model-invoked: Claude automatically uses them based on the task context.

Add a `skills/` directory at your plugin root with Skill folders containing `SKILL.md` files:

```text theme={null}
my-plugin/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── code-review/
        └── SKILL.md
```

Each `SKILL.md` contains YAML frontmatter and instructions. Include a `description` so Claude knows when to use the skill:

```yaml theme={null}
---
description: Reviews code for best practices and potential issues. Use when reviewing code, checking PRs, or analyzing code quality.
---

When reviewing code, check for:
1. Code organization and structure
2. Error handling
3. Security concerns
4. Test coverage
```

After installing the plugin, run `/reload-plugins` to load the Skills. For complete Skill authoring guidance including progressive disclosure and tool restrictions, see [Agent Skills](/en/skills).

### Add LSP servers to your plugin

<Tip>
  For common languages like TypeScript, Python, and Rust, install the pre-built LSP plugins from the official marketplace. Create custom LSP plugins only when you need support for languages not already covered.
</Tip>

LSP (Language Server Protocol) plugins give Claude real-time code intelligence. If you need to support a language that doesn't have an official LSP plugin, you can create your own by adding an `.lsp.json` file to your plugin:

```json .lsp.json theme={null}
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": {
      ".go": "go"
    }
  }
}
```

Users installing your plugin must have the language server binary installed on their machine.

For complete LSP configuration options, see [LSP servers](/en/plugins-reference#lsp-servers).

### Add background monitors to your plugin

Background monitors let your plugin watch logs, files, or external status in the background and notify Claude as events arrive. Claude Code starts each monitor automatically when the plugin is active, so you don't need to instruct Claude to start the watch.

Add a `monitors/monitors.json` file at the plugin root with an array of monitor entries:

```json monitors/monitors.json theme={null}
[
  {
    "name": "error-log",
    "command": "tail -F ./logs/error.log",
    "description": "Application error log"
  }
]
```

Each stdout line from `command` is delivered to Claude as a notification during the session. For the full schema, including the `when` trigger and variable substitution, see [Monitors](/en/plugins-reference#monitors).

### Ship default settings with your plugin

Plugins can include a `settings.json` file at the plugin root to apply default configuration when the plugin is enabled. Currently, only the `agent` and `subagentStatusLine` keys are supported.

Setting `agent` activates one of the plugin's [custom agents](/en/sub-agents) as the main thread, applying its system prompt, tool restrictions, and model. This lets a plugin change how Claude Code behaves by default when enabled.

```json settings.json theme={null}
{
  "agent": "security-reviewer"
}
```

This example activates the `security-reviewer` agent defined in the plugin's `agents/` directory. Settings from `settings.json` take priority over `settings` declared in `plugin.json`. Unknown keys are silently ignored.

### Organize complex plugins

For plugins with many components, organize your directory structure by functionality. For complete directory layouts and organization patterns, see [Plugin directory structure](/en/plugins-reference#plugin-directory-structure).

### Test your plugins locally

Use the `--plugin-dir` flag to test plugins during development. This loads your plugin directly without requiring installation.

```bash theme={null}
claude --plugin-dir ./my-plugin
```

The flag also accepts a `.zip` archive of the plugin directory, which requires Claude Code v2.1.128 or later.

```bash theme={null}
claude --plugin-dir ./my-plugin.zip
```

When a `--plugin-dir` plugin has the same name as an installed marketplace plugin, the local copy takes precedence for that session. This lets you test changes to a plugin you already have installed without uninstalling it first. The exception is plugins that managed settings force-enable or force-disable: `--plugin-dir` cannot override those.

As you make changes to your plugin, run `/reload-plugins` to pick up the updates without restarting. This reloads plugins, skills, agents, hooks, plugin MCP servers, and plugin LSP servers. Test your plugin components:

* Try your skills with `/plugin-name:skill-name`
* Check that agents appear in `/agents`
* Verify hooks work as expected

<Tip>
  You can load multiple plugins at once by specifying the flag multiple times:

  ```bash theme={null}
  claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two
  ```
</Tip>

To test a plugin that is already packaged as a `.zip` archive and hosted at a URL, such as a CI build artifact, use `--plugin-url` instead. Claude Code fetches the archive at startup and loads it for that session only. If the fetch fails or the archive is invalid, Claude Code reports a plugin load error and starts without it. The same [trust considerations](/en/discover-plugins#security) apply as for any plugin source: only point this flag at archives you control or trust.

To load multiple plugins, repeat the flag for each URL:

```bash theme={null}
claude --plugin-url https://example.com/my-plugin.zip --plugin-url https://example.com/other.zip
```

Or pass space-separated URLs as one quoted argument:

```bash theme={null}
claude --plugin-url "https://example.com/my-plugin.zip https://example.com/other.zip"
```

### Debug plugin issues

If your plugin isn't working as expected:

1. **Check the structure**: Ensure your directories are at the plugin root, not inside `.claude-plugin/`
2. **Test components individually**: Check each skill, agent, and hook separately
3. **Use validation and debugging tools**: See [Debugging and development tools](/en/plugins-reference#debugging-and-development-tools) for CLI commands and troubleshooting techniques

### Share your plugins

When your plugin is ready to share:

1. **Add documentation**: Include a `README.md` with installation and usage instructions
2. **Choose a versioning strategy**: Decide whether to set an explicit `version` or rely on the git commit SHA. See [version management](/en/plugins-reference#version-management)
3. **Create or use a marketplace**: Distribute through [plugin marketplaces](/en/plugin-marketplaces) for installation
4. **Test with others**: Have team members test the plugin before wider distribution

Once your plugin is in a marketplace, others can install it using the instructions in [Discover and install plugins](/en/discover-plugins). To keep a plugin internal to your team, host the marketplace in a [private repository](/en/plugin-marketplaces#private-repositories).

### Submit your plugin to the community marketplace

Anthropic maintains two public marketplaces for Claude Code plugins:

* **`claude-plugins-official`**: a curated set of plugins maintained by Anthropic. Available automatically in every Claude Code installation.
* **`claude-community`**: the public community marketplace where third-party submissions land after review. Users add it with `/plugin marketplace add anthropics/claude-plugins-community` and install from it as `@claude-community`.

To submit your plugin for community-marketplace review, use one of the in-app forms:

* **Claude.ai**: [claude.ai/settings/plugins/submit](https://claude.ai/settings/plugins/submit)
* **Console**: [platform.claude.com/plugins/submit](https://platform.claude.com/plugins/submit)

Run `claude plugin validate` locally before you submit. The review pipeline runs the same check on every submission, along with automated safety screening.

Approved plugins are pinned to a specific commit SHA in the [`anthropics/claude-plugins-community`](https://github.com/anthropics/claude-plugins-community) catalog, and CI bumps the pin automatically as you push new commits to your repository. The public catalog syncs nightly from the review pipeline, so there can be a delay between approval and your plugin appearing in `marketplace.json`. To check whether your plugin is installable yet, search for its name in the [community catalog](https://github.com/anthropics/claude-plugins-community/blob/main/.claude-plugin/marketplace.json).

The official marketplace, `claude-plugins-official`, is curated separately. Anthropic decides which plugins to include at its discretion. There is no application process, and the submission form does not add plugins to the official marketplace.

If Anthropic lists your plugin in the official marketplace, your CLI can prompt Claude Code users to install it. See [Recommend your plugin from your CLI](/en/plugin-hints).

<Note>
  For complete technical specifications, debugging techniques, and distribution strategies, see [Plugins reference](/en/plugins-reference).
</Note>

## Convert existing configurations to plugins

If you already have skills or hooks in your `.claude/` directory, you can convert them into a plugin for easier sharing and distribution.

### Migration steps

<Steps>
  <Step title="Create the plugin structure">
    Create a new plugin directory:

    ```bash theme={null}
    mkdir -p my-plugin/.claude-plugin
    ```

    Create the manifest file at `my-plugin/.claude-plugin/plugin.json`:

    ```json my-plugin/.claude-plugin/plugin.json theme={null}
    {
      "name": "my-plugin",
      "description": "Migrated from standalone configuration",
      "version": "1.0.0"
    }
    ```
  </Step>

  <Step title="Copy your existing files">
    Copy your existing configurations to the plugin directory:

    ```bash theme={null}
    # Copy commands
    cp -r .claude/commands my-plugin/

    # Copy agents (if any)
    cp -r .claude/agents my-plugin/

    # Copy skills (if any)
    cp -r .claude/skills my-plugin/
    ```
  </Step>

  <Step title="Migrate hooks">
    If you have hooks in your settings, create a hooks directory:

    ```bash theme={null}
    mkdir my-plugin/hooks
    ```

    Create `my-plugin/hooks/hooks.json` with your hooks configuration. Copy the `hooks` object from your `.claude/settings.json` or `settings.local.json`, since the format is the same. The command receives hook input as JSON on stdin, so use `jq` to extract the file path:

    ```json my-plugin/hooks/hooks.json theme={null}
    {
      "hooks": {
        "PostToolUse": [
          {
            "matcher": "Write|Edit",
            "hooks": [{ "type": "command", "command": "jq -r '.tool_input.file_path' | xargs npm run lint:fix" }]
          }
        ]
      }
    }
    ```
  </Step>

  <Step title="Test your migrated plugin">
    Load your plugin to verify everything works:

    ```bash theme={null}
    claude --plugin-dir ./my-plugin
    ```

    Test each component: run your commands, check agents appear in `/agents`, and verify hooks trigger correctly.
  </Step>
</Steps>

### What changes when migrating

| Standalone (`.claude/`)       | Plugin                           |
| :---------------------------- | :------------------------------- |
| Only available in one project | Can be shared via marketplaces   |
| Files in `.claude/commands/`  | Files in `plugin-name/commands/` |
| Hooks in `settings.json`      | Hooks in `hooks/hooks.json`      |
| Must manually copy to share   | Install with `/plugin install`   |

<Note>
  After migrating, you can remove the original files from `.claude/` to avoid duplicates. The plugin version will take precedence when loaded.
</Note>

## Next steps

Now that you understand Claude Code's plugin system, here are suggested paths for different goals:

### For plugin users

* [Discover and install plugins](/en/discover-plugins): browse marketplaces and install plugins
* [Configure team marketplaces](/en/discover-plugins#configure-team-marketplaces): set up repository-level plugins for your team

### For plugin developers

* [Create and distribute a marketplace](/en/plugin-marketplaces): package and share your plugins
* [Plugins reference](/en/plugins-reference): complete technical specifications
* Dive deeper into specific plugin components:
  * [Skills](/en/skills): skill development details
  * [Subagents](/en/sub-agents): agent configuration and capabilities
  * [Hooks](/en/hooks): event handling and automation
  * [MCP](/en/mcp): external tool integration

> ## Documentation Index
> Fetch the complete documentation index at: https://code.claude.com/docs/llms.txt
> Use this file to discover all available pages before exploring further.

# Extend Claude with skills

> Create, manage, and share skills to extend Claude's capabilities in Claude Code. Includes custom commands and bundled skills.

Skills extend what Claude can do. Create a `SKILL.md` file with instructions, and Claude adds it to its toolkit. Claude uses skills when relevant, or you can invoke one directly with `/skill-name`.

Create a skill when you keep pasting the same instructions, checklist, or multi-step procedure into chat, or when a section of CLAUDE.md has grown into a procedure rather than a fact. Unlike CLAUDE.md content, a skill's body loads only when it's used, so long reference material costs almost nothing until you need it.

<Note>
  For built-in commands like `/help` and `/compact`, and bundled skills like `/debug` and `/code-review`, see the [commands reference](/en/commands).

  **Custom commands have been merged into skills.** A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md` both create `/deploy` and work the same way. Your existing `.claude/commands/` files keep working. Skills add optional features: a directory for supporting files, frontmatter to [control whether you or Claude invokes them](#control-who-invokes-a-skill), and the ability for Claude to load them automatically when relevant.
</Note>

Claude Code skills follow the [Agent Skills](https://agentskills.io) open standard, which works across multiple AI tools. Claude Code extends the standard with additional features like [invocation control](#control-who-invokes-a-skill), [subagent execution](#run-skills-in-a-subagent), and [dynamic context injection](#inject-dynamic-context).

## Bundled skills

Claude Code includes a set of bundled skills that are available in every session, including `/code-review`, `/batch`, `/debug`, `/loop`, and `/claude-api`. Unlike most built-in commands, which execute fixed logic directly, bundled skills are prompt-based: they give Claude detailed instructions and let it orchestrate the work using its tools. You invoke them the same way as any other skill, by typing `/` followed by the skill name.

Bundled skills are listed alongside built-in commands in the [commands reference](/en/commands), marked **Skill** in the Purpose column.

### Run and verify your app

Three bundled skills work together to launch your app and confirm changes against the running app instead of just tests:

| Skill                  | Purpose                                                                                                           |
| :--------------------- | :---------------------------------------------------------------------------------------------------------------- |
| `/run`                 | Launch and drive your app to see a change working                                                                 |
| `/verify`              | Build and run your app to confirm a code change does what it should, without falling back to tests or type checks |
| `/run-skill-generator` | Teach `/run` and `/verify` how to build and launch your project                                                   |

{/* min-version: 2.1.145 */}All three skills require Claude Code v2.1.145 or later.

`/run` and `/verify` work without setup. They infer the launch from your project type (CLI, server, TUI, browser-driven) and from what's in your README, `package.json`, or `Makefile`. That inference gets unreliable for projects that need anything beyond a standard launch: a database, an env file, a graphical session, a multi-step build.

`/run-skill-generator` records the recipe instead. It gets your app running from a clean environment, captures what worked (the install commands, the env vars, the launch script), and commits it as a per-project skill at `.claude/skills/run-<name>/`. After that, `/run`, `/verify`, and any other agent in the repo follow the recorded recipe instead of rediscovering it. Run `/run-skill-generator` once per project, and again if the build or launch process changes.

## Getting started

### Create your first skill

This example creates a skill that summarizes the uncommitted changes in your git repository and flags anything risky. It pulls the live diff into the prompt before Claude reads it, so the response is grounded in your actual working tree rather than what Claude can guess from open files. Claude loads the skill automatically when you ask about your changes, or you can invoke it directly with `/summarize-changes`.

<Steps>
  <Step title="Create the skill directory">
    Create a directory for the skill in your personal skills folder. Personal skills are available across all your projects.

    ```bash theme={null}
    mkdir -p ~/.claude/skills/summarize-changes
    ```
  </Step>

  <Step title="Write SKILL.md">
    Every skill needs a `SKILL.md` file with two parts: YAML frontmatter between `---` markers that tells Claude when to use the skill, and markdown content with the instructions Claude follows when the skill runs. The directory name becomes the command you type, and the `description` helps Claude decide when to load the skill automatically.

    Save this to `~/.claude/skills/summarize-changes/SKILL.md`:

    ```yaml theme={null}
    ---
    description: Summarizes uncommitted changes and flags anything risky. Use when the user asks what changed, wants a commit message, or asks to review their diff.
    ---

    ## Current changes

    !`git diff HEAD`

    ## Instructions

    Summarize the changes above in two or three bullet points, then list any risks you notice such as missing error handling, hardcoded values, or tests that need updating. If the diff is empty, say there are no uncommitted changes.
    ```

    The `` !`git diff HEAD` `` line uses [dynamic context injection](#inject-dynamic-context): Claude Code runs the command and replaces the line with its output before Claude sees the skill content, so the instructions arrive with the current diff already inlined.
  </Step>

  <Step title="Test the skill">
    Open a git project, make a small edit to any file, and start Claude Code by running `claude`. You can test the skill two ways.

    **Let Claude invoke it automatically** by asking something that matches the description:

    ```text theme={null}
    What did I change?
    ```

    **Or invoke it directly** with the skill name:

    ```text theme={null}
    /summarize-changes
    ```

    Either way, Claude should respond with a short summary of your edit and a list of risks.
  </Step>
</Steps>

### Where skills live

Where you store a skill determines who can use it:

| Location   | Path                                                | Applies to                     |
| :--------- | :-------------------------------------------------- | :----------------------------- |
| Enterprise | See [managed settings](/en/settings#settings-files) | All users in your organization |
| Personal   | `~/.claude/skills/<skill-name>/SKILL.md`            | All your projects              |
| Project    | `.claude/skills/<skill-name>/SKILL.md`              | This project only              |
| Plugin     | `<plugin>/skills/<skill-name>/SKILL.md`             | Where plugin is enabled        |

When skills share the same name across levels, enterprise overrides personal, and personal overrides project. Plugin skills use a `plugin-name:skill-name` namespace, so they cannot conflict with other levels. If you have files in `.claude/commands/`, those work the same way, but if a skill and a command share the same name, the skill takes precedence.

#### Live change detection

Claude Code watches skill directories for file changes. Adding, editing, or removing a skill under `~/.claude/skills/`, the project `.claude/skills/`, or a `.claude/skills/` inside an `--add-dir` directory takes effect within the current session without restarting. Creating a top-level skills directory that did not exist when the session started requires restarting Claude Code so the new directory can be watched.

#### Automatic discovery from parent and nested directories

Project skills load from `.claude/skills/` in your starting directory and in every parent directory up to the repository root, so starting Claude in a subdirectory still picks up skills defined at the root. When you work with files in subdirectories below your starting directory, Claude Code also discovers skills from nested `.claude/skills/` directories on demand. For example, if you're editing a file in `packages/frontend/`, Claude Code also looks for skills in `packages/frontend/.claude/skills/`. This supports monorepo setups where packages have their own skills.

Each skill is a directory with `SKILL.md` as the entrypoint:

```text theme={null}
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for Claude to fill in
├── examples/
│   └── sample.md      # Example output showing expected format
└── scripts/
    └── validate.sh    # Script Claude can execute
```

The `SKILL.md` contains the main instructions and is required. Other files are optional and let you build more powerful skills: templates for Claude to fill in, example outputs showing the expected format, scripts Claude can execute, or detailed reference documentation. Reference these files from your `SKILL.md` so Claude knows what they contain and when to load them. See [Add supporting files](#add-supporting-files) for more details.

<Note>
  Files in `.claude/commands/` still work and support the same [frontmatter](#frontmatter-reference). Skills are recommended since they support additional features like supporting files.
</Note>

#### Skills from additional directories

The `--add-dir` flag [grants file access](/en/permissions#additional-directories-grant-file-access-not-configuration) rather than configuration discovery, but skills are an exception: `.claude/skills/` within an added directory is loaded automatically. See [Live change detection](#live-change-detection) for how edits are picked up during a session.

Other `.claude/` configuration such as subagents, commands, and output styles is not loaded from additional directories. See the [exceptions table](/en/permissions#additional-directories-grant-file-access-not-configuration) for the complete list of what is and isn't loaded, and the recommended ways to share configuration across projects.

<Note>
  CLAUDE.md files from `--add-dir` directories are not loaded by default. To load them, set `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`. See [Load from additional directories](/en/memory#load-from-additional-directories).
</Note>

## Configure skills

Skills are configured through YAML frontmatter at the top of `SKILL.md` and the markdown content that follows.

### Types of skill content

Skill files can contain any instructions, but thinking about how you want to invoke them helps guide what to include:

**Reference content** adds knowledge Claude applies to your current work. Conventions, patterns, style guides, domain knowledge. This content runs inline so Claude can use it alongside your conversation context.

```yaml theme={null}
---
name: api-conventions
description: API design patterns for this codebase
---

When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
- Include request validation
```

**Task content** gives Claude step-by-step instructions for a specific action, like deployments, commits, or code generation. These are often actions you want to invoke directly with `/skill-name` rather than letting Claude decide when to run them. Add `disable-model-invocation: true` to prevent Claude from triggering it automatically.

```yaml theme={null}
---
name: deploy
description: Deploy the application to production
context: fork
disable-model-invocation: true
---

Deploy the application:
1. Run the test suite
2. Build the application
3. Push to the deployment target
```

Your `SKILL.md` can contain anything, but thinking through how you want the skill invoked (by you, by Claude, or both) and where you want it to run (inline or in a subagent) helps guide what to include. For complex skills, you can also [add supporting files](#add-supporting-files) to keep the main skill focused.

Keep the body itself concise. Once a skill loads, its content [stays in context across turns](#skill-content-lifecycle), so every line is a recurring token cost. State what to do rather than narrating how or why, and apply the same conciseness test you would for [CLAUDE.md content](/en/best-practices#write-an-effective-claude-md).

### Frontmatter reference

Beyond the markdown content, you can configure skill behavior using YAML frontmatter fields between `---` markers at the top of your `SKILL.md` file:

```yaml theme={null}
---
name: my-skill
description: What this skill does
disable-model-invocation: true
allowed-tools: Read Grep
---

Your skill instructions here...
```

All fields are optional. Only `description` is recommended so Claude knows when to use the skill.

| Field                      | Required    | Description                                                                                                                                                                                                                                                                                                        |
| :------------------------- | :---------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`                     | No          | Display name for the skill. If omitted, uses the directory name. Lowercase letters, numbers, and hyphens only (max 64 characters).                                                                                                                                                                                 |
| `description`              | Recommended | What the skill does and when to use it. Claude uses this to decide when to apply the skill. If omitted, uses the first paragraph of markdown content. Put the key use case first: the combined `description` and `when_to_use` text is truncated at 1,536 characters in the skill listing to reduce context usage. |
| `when_to_use`              | No          | Additional context for when Claude should invoke the skill, such as trigger phrases or example requests. Appended to `description` in the skill listing and counts toward the 1,536-character cap.                                                                                                                 |
| `argument-hint`            | No          | Hint shown during autocomplete to indicate expected arguments. Example: `[issue-number]` or `[filename] [format]`.                                                                                                                                                                                                 |
| `arguments`                | No          | Named positional arguments for [`$name` substitution](#available-string-substitutions) in the skill content. Accepts a space-separated string or a YAML list. Names map to argument positions in order.                                                                                                            |
| `disable-model-invocation` | No          | Set to `true` to prevent Claude from automatically loading this skill. Use for workflows you want to trigger manually with `/name`. Also prevents the skill from being [preloaded into subagents](/en/sub-agents#preload-skills-into-subagents). Default: `false`.                                                 |
| `user-invocable`           | No          | Set to `false` to hide from the `/` menu. Use for background knowledge users shouldn't invoke directly. Default: `true`.                                                                                                                                                                                           |
| `allowed-tools`            | No          | Tools Claude can use without asking permission when this skill is active. Accepts a space-separated string or a YAML list.                                                                                                                                                                                         |
| `model`                    | No          | Model to use when this skill is active. The override applies for the rest of the current turn and is not saved to settings; the session model resumes on your next prompt. Accepts the same values as [`/model`](/en/model-config), or `inherit` to keep the active model.                                         |
| `effort`                   | No          | [Effort level](/en/model-config#adjust-effort-level) when this skill is active. Overrides the session effort level. Default: inherits from session. Options: `low`, `medium`, `high`, `xhigh`, `max`; available levels depend on the model.                                                                        |
| `context`                  | No          | Set to `fork` to run in a forked subagent context.                                                                                                                                                                                                                                                                 |
| `agent`                    | No          | Which subagent type to use when `context: fork` is set.                                                                                                                                                                                                                                                            |
| `hooks`                    | No          | Hooks scoped to this skill's lifecycle. See [Hooks in skills and agents](/en/hooks#hooks-in-skills-and-agents) for configuration format.                                                                                                                                                                           |
| `paths`                    | No          | Glob patterns that limit when this skill is activated. Accepts a comma-separated string or a YAML list. When set, Claude loads the skill automatically only when working with files matching the patterns. Uses the same format as [path-specific rules](/en/memory#path-specific-rules).                          |
| `shell`                    | No          | Shell to use for `` !`command` `` and ` ```! ` blocks in this skill. Accepts `bash` (default) or `powershell`. Setting `powershell` runs inline shell commands via PowerShell on Windows. Requires `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`.                                                                            |

#### Available string substitutions

Skills support string substitution for dynamic values in the skill content:

| Variable               | Description                                                                                                                                                                                                                                                                              |
| :--------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `$ARGUMENTS`           | All arguments passed when invoking the skill. If `$ARGUMENTS` is not present in the content, arguments are appended as `ARGUMENTS: <value>`.                                                                                                                                             |
| `$ARGUMENTS[N]`        | Access a specific argument by 0-based index, such as `$ARGUMENTS[0]` for the first argument.                                                                                                                                                                                             |
| `$N`                   | Shorthand for `$ARGUMENTS[N]`, such as `$0` for the first argument or `$1` for the second.                                                                                                                                                                                               |
| `$name`                | Named argument declared in the [`arguments`](#frontmatter-reference) frontmatter list. Names map to positions in order, so with `arguments: [issue, branch]` the placeholder `$issue` expands to the first argument and `$branch` to the second.                                         |
| `${CLAUDE_SESSION_ID}` | The current session ID. Useful for logging, creating session-specific files, or correlating skill output with sessions.                                                                                                                                                                  |
| `${CLAUDE_EFFORT}`     | The current effort level: `low`, `medium`, `high`, `xhigh`, or `max`. Use this to adapt skill instructions to the active effort setting.                                                                                                                                                 |
| `${CLAUDE_SKILL_DIR}`  | The directory containing the skill's `SKILL.md` file. For plugin skills, this is the skill's subdirectory within the plugin, not the plugin root. Use this in bash injection commands to reference scripts or files bundled with the skill, regardless of the current working directory. |

Indexed arguments use shell-style quoting, so wrap multi-word values in quotes to pass them as a single argument. For example, `/my-skill "hello world" second` makes `$0` expand to `hello world` and `$1` to `second`. The `$ARGUMENTS` placeholder always expands to the full argument string as typed.

**Example using substitutions:**

```yaml theme={null}
---
name: session-logger
description: Log activity for this session
---

Log the following to logs/${CLAUDE_SESSION_ID}.log:

$ARGUMENTS
```

### Add supporting files

Skills can include multiple files in their directory. This keeps `SKILL.md` focused on the essentials while letting Claude access detailed reference material only when needed. Large reference docs, API specifications, or example collections don't need to load into context every time the skill runs.

```text theme={null}
my-skill/
├── SKILL.md (required - overview and navigation)
├── reference.md (detailed API docs - loaded when needed)
├── examples.md (usage examples - loaded when needed)
└── scripts/
    └── helper.py (utility script - executed, not loaded)
```

Reference supporting files from `SKILL.md` so Claude knows what each file contains and when to load it:

```markdown theme={null}
## Additional resources

- For complete API details, see [reference.md](reference.md)
- For usage examples, see [examples.md](examples.md)
```

<Tip>Keep `SKILL.md` under 500 lines. Move detailed reference material to separate files.</Tip>

### Control who invokes a skill

By default, both you and Claude can invoke any skill. You can type `/skill-name` to invoke it directly, and Claude can load it automatically when relevant to your conversation. Two frontmatter fields let you restrict this:

* **`disable-model-invocation: true`**: Only you can invoke the skill. Use this for workflows with side effects or that you want to control timing, like `/commit`, `/deploy`, or `/send-slack-message`. You don't want Claude deciding to deploy because your code looks ready.

* **`user-invocable: false`**: Only Claude can invoke the skill. Use this for background knowledge that isn't actionable as a command. A `legacy-system-context` skill explains how an old system works. Claude should know this when relevant, but `/legacy-system-context` isn't a meaningful action for users to take.

This example creates a deploy skill that only you can trigger. The `disable-model-invocation: true` field prevents Claude from running it automatically:

```yaml theme={null}
---
name: deploy
description: Deploy the application to production
disable-model-invocation: true
---

Deploy $ARGUMENTS to production:

1. Run the test suite
2. Build the application
3. Push to the deployment target
4. Verify the deployment succeeded
```

Here's how the two fields affect invocation and context loading:

| Frontmatter                      | You can invoke | Claude can invoke | When loaded into context                                     |
| :------------------------------- | :------------- | :---------------- | :----------------------------------------------------------- |
| (default)                        | Yes            | Yes               | Description always in context, full skill loads when invoked |
| `disable-model-invocation: true` | Yes            | No                | Description not in context, full skill loads when you invoke |
| `user-invocable: false`          | No             | Yes               | Description always in context, full skill loads when invoked |

<Note>
  In a regular session, skill descriptions are loaded into context so Claude knows what's available, but full skill content only loads when invoked. [Subagents with preloaded skills](/en/sub-agents#preload-skills-into-subagents) work differently: the full skill content is injected at startup.
</Note>

### Skill content lifecycle

When you or Claude invoke a skill, the rendered `SKILL.md` content enters the conversation as a single message and stays there for the rest of the session. Claude Code does not re-read the skill file on later turns, so write guidance that should apply throughout a task as standing instructions rather than one-time steps.

[Auto-compaction](/en/how-claude-code-works#when-context-fills-up) carries invoked skills forward within a token budget. When the conversation is summarized to free context, Claude Code re-attaches the most recent invocation of each skill after the summary, keeping the first 5,000 tokens of each. Re-attached skills share a combined budget of 25,000 tokens. Claude Code fills this budget starting from the most recently invoked skill, so older skills can be dropped entirely after compaction if you have invoked many in one session.

If a skill seems to stop influencing behavior after the first response, the content is usually still present and the model is choosing other tools or approaches. Strengthen the skill's `description` and instructions so the model keeps preferring it, or use [hooks](/en/hooks) to enforce behavior deterministically. If the skill is large or you invoked several others after it, re-invoke it after compaction to restore the full content.

### Pre-approve tools for a skill

The `allowed-tools` field grants permission for the listed tools while the skill is active, so Claude can use them without prompting you for approval. It does not restrict which tools are available: every tool remains callable, and your [permission settings](/en/permissions) still govern tools that are not listed.

For skills checked into a project's `.claude/skills/` directory, `allowed-tools` takes effect after you accept the workspace trust dialog for that folder, the same as permission rules in `.claude/settings.json`. Review project skills before trusting a repository, since a skill can grant itself broad tool access.

This skill lets Claude run git commands without per-use approval whenever you invoke it:

```yaml theme={null}
---
name: commit
description: Stage and commit the current changes
disable-model-invocation: true
allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *)
---
```

To block a skill from using certain tools, add deny rules in your [permission settings](/en/permissions) instead.

### Pass arguments to skills

Both you and Claude can pass arguments when invoking a skill. Arguments are available via the `$ARGUMENTS` placeholder.

This skill fixes a GitHub issue by number. The `$ARGUMENTS` placeholder gets replaced with whatever follows the skill name:

```yaml theme={null}
---
name: fix-issue
description: Fix a GitHub issue
disable-model-invocation: true
---

Fix GitHub issue $ARGUMENTS following our coding standards.

1. Read the issue description
2. Understand the requirements
3. Implement the fix
4. Write tests
5. Create a commit
```

When you run `/fix-issue 123`, Claude receives "Fix GitHub issue 123 following our coding standards..."

If you invoke a skill with arguments but the skill doesn't include `$ARGUMENTS`, Claude Code appends `ARGUMENTS: <your input>` to the end of the skill content so Claude still sees what you typed.

To access individual arguments by position, use `$ARGUMENTS[N]` or the shorter `$N`:

```yaml theme={null}
---
name: migrate-component
description: Migrate a component from one framework to another
---

Migrate the $ARGUMENTS[0] component from $ARGUMENTS[1] to $ARGUMENTS[2].
Preserve all existing behavior and tests.
```

Running `/migrate-component SearchBar React Vue` replaces `$ARGUMENTS[0]` with `SearchBar`, `$ARGUMENTS[1]` with `React`, and `$ARGUMENTS[2]` with `Vue`. The same skill using the `$N` shorthand:

```yaml theme={null}
---
name: migrate-component
description: Migrate a component from one framework to another
---

Migrate the $0 component from $1 to $2.
Preserve all existing behavior and tests.
```

## Advanced patterns

### Inject dynamic context

The `` !`<command>` `` syntax runs shell commands before the skill content is sent to Claude. The command output replaces the placeholder, so Claude receives actual data, not the command itself.

This skill summarizes a pull request by fetching live PR data with the GitHub CLI. The `` !`gh pr diff` `` and other commands run first, and their output gets inserted into the prompt:

```yaml theme={null}
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`

## Your task
Summarize this pull request...
```

When this skill runs:

1. Each `` !`<command>` `` executes immediately (before Claude sees anything)
2. The output replaces the placeholder in the skill content
3. Claude receives the fully-rendered prompt with actual PR data

This is preprocessing, not something Claude executes. Claude only sees the final result.

Substitution runs once over the original file. Command output is inserted as plain text and is not re-scanned for further `` !`<command>` `` placeholders, so a command cannot emit a placeholder for a later pass to expand.

The inline form is only recognized when `!` appears at the start of a line or immediately after whitespace. If `!` follows another character, as in `` KEY=!`cmd` ``, the placeholder is left as literal text and the command does not run.

For multi-line commands, use a fenced code block opened with ` ```! ` instead of the inline form:

````markdown theme={null}
## Environment
```!
node --version
npm --version
git status --short
```
````

To disable this behavior for skills and custom commands from user, project, plugin, or [additional-directory](#skills-from-additional-directories) sources, set `"disableSkillShellExecution": true` in [settings](/en/settings). Each command is replaced with `[shell command execution disabled by policy]` instead of being run. Bundled and managed skills are not affected. This setting is most useful in [managed settings](/en/permissions#managed-settings), where users cannot override it.

<Tip>
  To request deeper reasoning when a skill runs, include `ultrathink` anywhere in the skill content. See [Use ultrathink for one-off deep reasoning](/en/model-config#use-ultrathink-for-one-off-deep-reasoning).
</Tip>

### Run skills in a subagent

Add `context: fork` to your frontmatter when you want a skill to run in isolation. The skill content becomes the prompt that drives the subagent. It won't have access to your conversation history.

<Warning>
  `context: fork` only makes sense for skills with explicit instructions. If your skill contains guidelines like "use these API conventions" without a task, the subagent receives the guidelines but no actionable prompt, and returns without meaningful output.
</Warning>

Skills and [subagents](/en/sub-agents) work together in two directions:

| Approach                     | System prompt            | Task                        | Also loads                                          |
| :--------------------------- | :----------------------- | :-------------------------- | :-------------------------------------------------- |
| Skill with `context: fork`   | From agent type          | SKILL.md content            | CLAUDE.md, except when the agent is Explore or Plan |
| Subagent with `skills` field | Subagent's markdown body | Claude's delegation message | Preloaded skills + CLAUDE.md                        |

With `context: fork`, you write the task in your skill and pick an agent type to execute it. The built-in Explore and Plan agents [skip CLAUDE.md and git status](/en/sub-agents#what-loads-at-startup) to keep their context small, so a forked skill using `agent: Explore` sees only the SKILL.md content and the agent's own system prompt. For the inverse, where you define a custom subagent that uses skills as reference material, see [Subagents](/en/sub-agents#preload-skills-into-subagents).

#### Example: Research skill using Explore agent

This skill runs research in a forked Explore agent. The skill content becomes the task, and the agent provides read-only tools optimized for codebase exploration:

```yaml theme={null}
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:

1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with specific file references
```

When this skill runs:

1. A new isolated context is created
2. The subagent receives the skill content as its prompt ("Research \$ARGUMENTS thoroughly...")
3. The `agent` field determines the execution environment (model, tools, and permissions)
4. Results are summarized and returned to your main conversation

The `agent` field specifies which subagent configuration to use. Options include built-in agents (`Explore`, `Plan`, `general-purpose`) or any custom subagent from `.claude/agents/`. If omitted, uses `general-purpose`.

### Restrict Claude's skill access

By default, Claude can invoke any skill that doesn't have `disable-model-invocation: true` set. Skills that define `allowed-tools` grant Claude access to those tools without per-use approval when the skill is active. Your [permission settings](/en/permissions) still govern baseline approval behavior for all other tools. A few built-in commands are also available through the Skill tool, including `/init`, `/review`, and `/security-review`. Other built-in commands such as `/compact` are not.

Three ways to control which skills Claude can invoke:

**Disable all skills** by denying the Skill tool in `/permissions`:

```text theme={null}
# Add to deny rules:
Skill
```

**Allow or deny specific skills** using [permission rules](/en/permissions):

```text theme={null}
# Allow only specific skills
Skill(commit)
Skill(review-pr *)

# Deny specific skills
Skill(deploy *)
```

Permission syntax: `Skill(name)` for exact match, `Skill(name *)` for prefix match with any arguments.

**Hide individual skills** by adding `disable-model-invocation: true` to their frontmatter. This removes the skill from Claude's context entirely.

<Note>
  The `user-invocable` field only controls menu visibility, not Skill tool access. Use `disable-model-invocation: true` to block programmatic invocation.
</Note>

### Override skill visibility from settings

The `skillOverrides` setting controls skill visibility from your [settings](/en/settings) instead of the skill's own frontmatter. Use it for skills whose SKILL.md you don't want to edit, such as ones checked into a shared project repo or provided by an MCP server. The `/skills` menu writes it for you: highlight a skill and press `Space` to cycle states, then `Enter` to save to `.claude/settings.local.json`.

Each key is a skill name and each value is one of four states:

| Value                   | Listed to Claude     | In `/` menu |
| :---------------------- | :------------------- | :---------- |
| `"on"`                  | Name and description | Yes         |
| `"name-only"`           | Name only            | Yes         |
| `"user-invocable-only"` | Hidden               | Yes         |
| `"off"`                 | Hidden               | Hidden      |

A skill that is absent from `skillOverrides` is treated as `"on"`. The example below collapses one skill to its name and turns another off entirely:

```json theme={null}
{
  "skillOverrides": {
    "legacy-context": "name-only",
    "deploy": "off"
  }
}
```

Plugin skills are not affected by `skillOverrides`. Manage those through `/plugin` instead.

## Share skills

Skills can be distributed at different scopes depending on your audience:

* **Project skills**: Commit `.claude/skills/` to version control
* **Plugins**: Create a `skills/` directory in your [plugin](/en/plugins)
* **Managed**: Deploy organization-wide through [managed settings](/en/settings#settings-files)

### Generate visual output

Skills can bundle and run scripts in any language, giving Claude capabilities beyond what's possible in a single prompt. One powerful pattern is generating visual output: interactive HTML files that open in your browser for exploring data, debugging, or creating reports.

This example creates a codebase explorer: an interactive tree view where you can expand and collapse directories, see file sizes at a glance, and identify file types by color.

Create the Skill directory:

```bash theme={null}
mkdir -p ~/.claude/skills/codebase-visualizer/scripts
```

Save this to `~/.claude/skills/codebase-visualizer/SKILL.md`. The description tells Claude when to activate this Skill, and the instructions tell Claude to run the bundled script. The script path uses [`${CLAUDE_SKILL_DIR}`](#available-string-substitutions) so it resolves correctly whether the skill is installed at the personal, project, or plugin level:

````yaml theme={null}
---
name: codebase-visualizer
description: Generate an interactive collapsible tree visualization of your codebase. Use when exploring a new repo, understanding project structure, or identifying large files.
allowed-tools: Bash(python3 *)
---

# Codebase Visualizer

Generate an interactive HTML tree view that shows your project's file structure with collapsible directories.

## Usage

Run the visualization script from your project root:

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/visualize.py .
```

This creates `codebase-map.html` in the current directory and opens it in your default browser.

## What the visualization shows

- **Collapsible directories**: Click folders to expand/collapse
- **File sizes**: Displayed next to each file
- **Colors**: Different colors for different file types
- **Directory totals**: Shows aggregate size of each folder
````

Save this to `~/.claude/skills/codebase-visualizer/scripts/visualize.py`. This script scans a directory tree and generates a self-contained HTML file with:

* A **summary sidebar** showing file count, directory count, total size, and number of file types
* A **bar chart** breaking down the codebase by file type (top 8 by size)
* A **collapsible tree** where you can expand and collapse directories, with color-coded file type indicators

The script requires Python 3 but uses only built-in libraries, so there are no packages to install:

```python expandable theme={null}
#!/usr/bin/env python3
"""Generate an interactive collapsible tree visualization of a codebase."""

import json
import sys
import webbrowser
from html import escape
from pathlib import Path
from collections import Counter

IGNORE = {'.git', 'node_modules', '__pycache__', '.venv', 'venv', 'dist', 'build'}

def scan(path: Path, stats: dict) -> dict:
    result = {"name": path.name, "children": [], "size": 0}
    try:
        for item in sorted(path.iterdir()):
            if item.name in IGNORE or item.name.startswith('.'):
                continue
            if item.is_file():
                size = item.stat().st_size
                ext = item.suffix.lower() or '(no ext)'
                result["children"].append({"name": item.name, "size": size, "ext": ext})
                result["size"] += size
                stats["files"] += 1
                stats["extensions"][ext] += 1
                stats["ext_sizes"][ext] += size
            elif item.is_dir():
                stats["dirs"] += 1
                child = scan(item, stats)
                if child["children"]:
                    result["children"].append(child)
                    result["size"] += child["size"]
    except PermissionError:
        pass
    return result

def generate_html(data: dict, stats: dict, output: Path) -> None:
    ext_sizes = stats["ext_sizes"]
    total_size = sum(ext_sizes.values()) or 1
    sorted_exts = sorted(ext_sizes.items(), key=lambda x: -x[1])[:8]
    colors = {
        '.js': '#f7df1e', '.ts': '#3178c6', '.py': '#3776ab', '.go': '#00add8',
        '.rs': '#dea584', '.rb': '#cc342d', '.css': '#264de4', '.html': '#e34c26',
        '.json': '#6b7280', '.md': '#083fa1', '.yaml': '#cb171e', '.yml': '#cb171e',
        '.mdx': '#083fa1', '.tsx': '#3178c6', '.jsx': '#61dafb', '.sh': '#4eaa25',
    }
    lang_bars = "".join(
        f'<div class="bar-row"><span class="bar-label">{ext}</span>'
        f'<div class="bar" style="width:{(size/total_size)*100}%;background:{colors.get(ext,"#6b7280")}"></div>'
        f'<span class="bar-pct">{(size/total_size)*100:.1f}%</span></div>'
        for ext, size in sorted_exts
    )
    def fmt(b):
        if b < 1024: return f"{b} B"
        if b < 1048576: return f"{b/1024:.1f} KB"
        return f"{b/1048576:.1f} MB"

    html = f'''<!DOCTYPE html>
<html><head>
  <meta charset="utf-8"><title>Codebase Explorer</title>
  <style>
    body {{ font: 14px/1.5 system-ui, sans-serif; margin: 0; background: #1a1a2e; color: #eee; }}
    .container {{ display: flex; height: 100vh; }}
    .sidebar {{ width: 280px; background: #252542; padding: 20px; border-right: 1px solid #3d3d5c; overflow-y: auto; flex-shrink: 0; }}
    .main {{ flex: 1; padding: 20px; overflow-y: auto; }}
    h1 {{ margin: 0 0 10px 0; font-size: 18px; }}
    h2 {{ margin: 20px 0 10px 0; font-size: 14px; color: #888; text-transform: uppercase; }}
    .stat {{ display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #3d3d5c; }}
    .stat-value {{ font-weight: bold; }}
    .bar-row {{ display: flex; align-items: center; margin: 6px 0; }}
    .bar-label {{ width: 55px; font-size: 12px; color: #aaa; }}
    .bar {{ height: 18px; border-radius: 3px; }}
    .bar-pct {{ margin-left: 8px; font-size: 12px; color: #666; }}
    .tree {{ list-style: none; padding-left: 20px; }}
    details {{ cursor: pointer; }}
    summary {{ padding: 4px 8px; border-radius: 4px; }}
    summary:hover {{ background: #2d2d44; }}
    .folder {{ color: #ffd700; }}
    .file {{ display: flex; align-items: center; padding: 4px 8px; border-radius: 4px; }}
    .file:hover {{ background: #2d2d44; }}
    .size {{ color: #888; margin-left: auto; font-size: 12px; }}
    .dot {{ width: 8px; height: 8px; border-radius: 50%; margin-right: 8px; }}
  </style>
</head><body>
  <div class="container">
    <div class="sidebar">
      <h1>📊 Summary</h1>
      <div class="stat"><span>Files</span><span class="stat-value">{stats["files"]:,}</span></div>
      <div class="stat"><span>Directories</span><span class="stat-value">{stats["dirs"]:,}</span></div>
      <div class="stat"><span>Total size</span><span class="stat-value">{fmt(data["size"])}</span></div>
      <div class="stat"><span>File types</span><span class="stat-value">{len(stats["extensions"])}</span></div>
      <h2>By file type</h2>
      {lang_bars}
    </div>
    <div class="main">
      <h1>📁 {escape(data["name"])}</h1>
      <ul class="tree" id="root"></ul>
    </div>
  </div>
  <script>
    const data = {json.dumps(data)};
    const colors = {json.dumps(colors)};
    function fmt(b) {{ if (b < 1024) return b + ' B'; if (b < 1048576) return (b/1024).toFixed(1) + ' KB'; return (b/1048576).toFixed(1) + ' MB'; }}
    function esc(s) {{ return s.replace(/[&<>"']/g, c => ({{"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}}[c])); }}
    function render(node, parent) {{
      if (node.children) {{
        const det = document.createElement('details');
        det.open = parent === document.getElementById('root');
        det.innerHTML = `<summary><span class="folder">📁 ${{esc(node.name)}}</span><span class="size">${{fmt(node.size)}}</span></summary>`;
        const ul = document.createElement('ul'); ul.className = 'tree';
        node.children.sort((a,b) => (b.children?1:0)-(a.children?1:0) || a.name.localeCompare(b.name));
        node.children.forEach(c => render(c, ul));
        det.appendChild(ul);
        const li = document.createElement('li'); li.appendChild(det); parent.appendChild(li);
      }} else {{
        const li = document.createElement('li'); li.className = 'file';
        li.innerHTML = `<span class="dot" style="background:${{colors[node.ext]||'#6b7280'}}"></span>${{esc(node.name)}}<span class="size">${{fmt(node.size)}}</span>`;
        parent.appendChild(li);
      }}
    }}
    data.children.forEach(c => render(c, document.getElementById('root')));
  </script>
</body></html>'''
    output.write_text(html)

if __name__ == '__main__':
    target = Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
    stats = {"files": 0, "dirs": 0, "extensions": Counter(), "ext_sizes": Counter()}
    data = scan(target, stats)
    out = Path('codebase-map.html')
    generate_html(data, stats, out)
    print(f'Generated {out.absolute()}')
    webbrowser.open(f'file://{out.absolute()}')
```

To test, open Claude Code in any project and ask "Visualize this codebase." Claude runs the script, generates `codebase-map.html`, and opens it in your browser.

This pattern works for any visual output: dependency graphs, test coverage reports, API documentation, or database schema visualizations. The bundled script does the work while Claude handles orchestration.

## Troubleshooting

### Skill not triggering

If Claude doesn't use your skill when expected:

1. Check the description includes keywords users would naturally say
2. Verify the skill appears in `What skills are available?`
3. Try rephrasing your request to match the description more closely
4. Invoke it directly with `/skill-name` if the skill is user-invocable

### Skill triggers too often

If Claude uses your skill when you don't want it:

1. Make the description more specific
2. Add `disable-model-invocation: true` if you only want manual invocation

### Skill descriptions are cut short

Skill descriptions are loaded into context so Claude knows what's available. All skill names are always included, but if you have many skills, descriptions are shortened to fit the character budget, which can strip the keywords Claude needs to match your request. The budget scales at 1% of the model's context window. When it overflows, descriptions for the skills you invoke least are dropped first, so the skills you actually use keep their full text. Run `/doctor` to see whether the budget is overflowing and which skills are affected.

To raise the budget, set the [`skillListingBudgetFraction`](/en/settings#available-settings) setting (e.g. `0.02` = 2%) or the `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable to a fixed character count. To free budget for other skills, set low-priority entries to `"name-only"` in [`skillOverrides`](#override-skill-visibility-from-settings) so they list without a description. You can also trim the `description` and `when_to_use` text at the source: put the key use case first, since each entry's combined text is capped at 1,536 characters regardless of budget. The cap is configurable with [`maxSkillDescriptionChars`](/en/settings#available-settings).

## Related resources

* **[Debug your configuration](/en/debug-your-config)**: diagnose why a skill isn't appearing or triggering
* **[Subagents](/en/sub-agents)**: delegate tasks to specialized agents
* **[Plugins](/en/plugins)**: package and distribute skills with other extensions
* **[Hooks](/en/hooks)**: automate workflows around tool events
* **[Memory](/en/memory)**: manage CLAUDE.md files for persistent context
* **[Commands](/en/commands)**: reference for built-in commands and bundled skills
* **[Permissions](/en/permissions)**: control tool and skill access

