# MCP Setup for Speck 🥓

Speck works best with these MCP servers configured. All are optional but recommended.

## Quick Setup

1. (Optional) Add team-shared MCP additions (no secrets): create/edit `.speck/mcp/project.example.json` (or `.cursor/mcp.project.json.example`)
2. Generate your local configs (produces both `.cursor/mcp.json` and `.mcp.json`):
   ```bash
   bash .speck/scripts/bash/merge-mcp-config.sh
   ```
3. Add your API keys / tokens in your generated local configs (both are local and git-ignored)
4. Restart your host (Cursor or Claude Code)

## Recommended Servers

| Server | Purpose | Get API Key |
|--------|---------|-------------|
| **Perplexity** | Deep research, web search | https://perplexity.ai/account/api |
| **GitHub** | PRs, issues, repos, code search | https://github.com/settings/tokens |
| **Context7** | Up-to-date library docs | No key needed |

### Perplexity Tools
- `perplexity_search` - Quick web search
- `perplexity_ask` - Conversational queries
- `perplexity_research` - Deep analysis
- `perplexity_reason` - Complex reasoning

### GitHub Tools
- Repository operations, PRs, issues, code search, branches, commits

**Org repos (template publishing, issue intake):**
- If you want the GitHub MCP server to **create repos in an organization** (e.g. `telum-ai`) or open issues/PRs there, your token must be authorized for that org.
- For orgs with SSO, ensure the token is **SSO-enabled** for the org.
- For fine-grained tokens, grant **Repository administration** (create repos) and/or **Issues** permissions for the target org/repo.

### Context7 Tools
- `resolve-library-id` - Find library docs
- `get-library-docs` - Fetch current API docs

## Without MCP

Speck falls back gracefully:
- Research → `web_search` tool, then manual prompts
- GitHub → Manual operations
- Docs → May have outdated API info (training data)

## Service-Specific MCP Servers

When using external services, install their MCP servers for AI-assisted development:

| Service | MCP Server | Type |
|---------|------------|------|
| **Stripe** | `https://mcp.stripe.com` | ✅ Official |
| **Supabase** | `https://mcp.supabase.com/mcp` | ✅ Official |
| **Sentry** | `https://mcp.sentry.dev/mcp` | ✅ Official |
| **PostHog** | `@anthropic-ai/posthog-mcp-server` | ✅ Official |
| **RevenueCat** | `https://mcp.revenuecat.ai/mcp` | ✅ Official |
| **Resend** | `docker run mcp/resend` | ✅ Docker |
| **Firebase** | `firebase-mcp-server` | 🔧 Community |
| **Cloudflare** | `https://*.mcp.cloudflare.com/mcp` | ✅ Official |

See `.claude/skills/external-services/*/SKILL.md` for detailed setup instructions.

## More Info

- [MCP Specification](https://modelcontextprotocol.io)
- [Perplexity MCP](https://docs.perplexity.ai/guides/model-context-protocol)
- [GitHub MCP](https://github.com/modelcontextprotocol/servers)
- [Context7](https://github.com/upstash/context7)

## Template Sync Notes

- Speck-managed baseline (canonical): `.speck/mcp/servers.example.json`
- Project-managed overlay (committed): `.speck/mcp/project.example.json` (falls back to `.cursor/mcp.project.json.example`)
- Local merged configs (git-ignored): `.cursor/mcp.json` (Cursor) and `.mcp.json` (Claude Code)
