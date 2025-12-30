# 🎯 Speck Skills

Agent Skills are **domain-specific expertise packages** that AI agents can discover and use automatically. Unlike commands (user-triggered) or rules (always-applied), skills are **agent-decided** - loaded on-demand when relevant to the current task.

## How Skills Work in Speck

```
Commands  → User triggers explicitly (/project-specify)
Rules     → Always applied or file-pattern based
Skills    → Agent decides based on task context (automatic)
```

When you're working on a task, the agent:
1. **Discovers** available skills from their names and descriptions
2. **Activates** relevant skills by loading their full instructions
3. **Applies** the domain expertise to the current task

## Enabling Skills in Cursor

1. Open **Cursor Settings** (Cmd+Shift+J / Ctrl+Shift+J)
2. Select **Beta** → Set update channel to **Nightly**
3. Restart Cursor after update
4. Go to **Settings → Rules → Import Settings**
5. Toggle **Agent Skills** on

---

## Available Skills

### External Services (`external-services-*`)

| Skill | MCP | Description | Key Patterns |
|-------|-----|-------------|--------------|
| [Stripe](external-services-stripe/SKILL.md) | ✅ Official | Payment integration | Webhooks, idempotency, subscriptions, 5s timeout |
| [Supabase](external-services-supabase/SKILL.md) | ✅ Official | Backend-as-a-service | RLS policies, `getUser()` vs `getSession()`, real-time |
| [Clerk](external-services-clerk/SKILL.md) | 🔧 Build | Authentication | Middleware, 4KB cookie limit, organizations |
| [AI APIs](external-services-ai-apis/SKILL.md) | — | OpenAI & Claude | Structured outputs, streaming, prompt caching |
| [Sentry](external-services-sentry/SKILL.md) | ✅ Official | Error tracking | Source maps, fingerprinting, replay sampling |
| [Resend](external-services-resend/SKILL.md) | ✅ Docker | Transactional email | React Email, webhooks, idempotency keys |
| [Firebase](external-services-firebase/SKILL.md) | 🔧 Community | Google BaaS | Firestore rules, custom claims, FCM |
| [PostHog](external-services-posthog/SKILL.md) | ✅ Official | Product analytics | Event taxonomy, feature flags, session replay |
| [RevenueCat](external-services-revenuecat/SKILL.md) | ✅ Official | In-app purchases | Entitlements, webhooks, sandbox testing |

### Technologies (`technologies-*`)

| Skill | Description | Key Patterns |
|-------|-------------|--------------|
| [PWA](technologies-pwa/SKILL.md) | Progressive Web Apps | Service workers, caching strategies, manifests |
| [React Query](technologies-react-query/SKILL.md) | Server state | Query keys, mutations, optimistic updates |
| [WebSockets](technologies-websockets/SKILL.md) | Real-time comms | Reconnection, heartbeats, scaling with Redis |
| [Docker](technologies-docker/SKILL.md) | Containerization | Multi-stage builds, Compose, layer caching |
| [GitHub Actions](technologies-github-actions/SKILL.md) | CI/CD | Caching, matrix builds, secrets |

### Domains (`domains-*`)

| Skill | Description | Key Patterns |
|-------|-------------|--------------|
| [SaaS Billing](domains-saas-billing/SKILL.md) | Subscription management | State machine, proration, dunning, trials |
| [Multi-tenancy](domains-multi-tenancy/SKILL.md) | B2B architecture | RLS, org switching, RBAC, invitations |
| [OAuth](domains-oauth-implementation/SKILL.md) | Authentication flows | PKCE, token refresh, provider gotchas |
| [GDPR Compliance](domains-gdpr-compliance/SKILL.md) | Privacy | Consent, data export, right to erasure |

### Architectures (`architectures-*`)

| Skill | Description | Key Patterns |
|-------|-------------|--------------|
| [Serverless](architectures-serverless/SKILL.md) | FaaS patterns | Cold starts, connection pooling, queues |
| [Offline-First](architectures-offline-first/SKILL.md) | Local-first apps | Sync queues, conflict resolution, IndexedDB |

---

## Directory Structure

```
.claude/skills/
├── README.md                               # This file
├── external-services-stripe/SKILL.md       # Third-party: Stripe
├── external-services-supabase/SKILL.md     # Third-party: Supabase
├── external-services-clerk/SKILL.md        # Third-party: Clerk
├── external-services-ai-apis/SKILL.md      # Third-party: OpenAI & Claude APIs
├── external-services-sentry/SKILL.md       # Third-party: Sentry
├── external-services-resend/SKILL.md       # Third-party: Resend
├── external-services-firebase/SKILL.md     # Third-party: Firebase
├── external-services-posthog/SKILL.md      # Third-party: PostHog
├── external-services-revenuecat/SKILL.md   # Third-party: RevenueCat
├── technologies-pwa/SKILL.md               # Framework: PWA
├── technologies-react-query/SKILL.md       # Framework: React Query
├── technologies-websockets/SKILL.md        # Framework: WebSockets
├── technologies-docker/SKILL.md            # Framework: Docker
├── technologies-github-actions/SKILL.md    # Framework: GitHub Actions
├── domains-saas-billing/SKILL.md           # Domain pattern: SaaS Billing
├── domains-multi-tenancy/SKILL.md          # Domain pattern: Multi-tenancy
├── domains-oauth-implementation/SKILL.md   # Domain pattern: OAuth
├── domains-gdpr-compliance/SKILL.md        # Domain pattern: GDPR Compliance
├── architectures-serverless/SKILL.md       # Architecture: Serverless
└── architectures-offline-first/SKILL.md    # Architecture: Offline-First
```

---

## Relationship to Recipes

**Recipes** define WHAT technologies to use (stack choices).
**Skills** provide HOW to use them effectively (patterns & gotchas).

When a user picks a recipe like `nextjs-supabase`, the agent automatically has access to the Supabase skill for integration patterns.

---

## Creating New Skills

### 1. Create the Directory

```bash
mkdir -p .claude/skills/external-services-my-service
```

### 2. Create SKILL.md

**CRITICAL**: Every skill file MUST have YAML frontmatter with `name` and `description`. This is how Cursor discovers and loads skills:

```markdown
---
name: my-service-integration
description: Integrate MyService for [functionality]. Use when implementing [specific features] or working with [MyService concepts].
---

# My Service Integration

Brief description of what this skill covers and when to use it.

## When to Use

Apply when implementing [specific features] or working with [concepts].

---

## Quick Start

[Minimal working example]

## Common Patterns

[Reusable code patterns]

## Common Gotchas

[Things that trip people up]

## Quick Reference

| Task | Pattern |
|------|---------|
| [Task 1] | [Pattern] |

## References

- [Link to docs]
```

### 3. Key Authoring Principles

1. **YAML frontmatter is REQUIRED** - Without `name` and `description`, the skill won't be discovered
2. **Description triggers loading** - Include specific keywords the agent will match on (e.g., "webhooks", "subscriptions", "RLS")
3. **Include MCP server if available** - Add a `🔌 MCP Server` section with install instructions when official/community MCP servers exist. In Speck template repos, prefer adding servers to `.cursor/mcp.project.json.example` and generating `.cursor/mcp.json` via `bash .speck/scripts/bash/merge-mcp-config.sh`.
4. **Be concise** - Every token competes for context space (aim for <500 lines)
5. **Assume intelligence** - Only add what Claude doesn't already know
6. **Focus on gotchas** - Document surprises, not obvious things
7. **Provide code** - Patterns are worth 1000 words
8. **Stay current** - Update when services change
9. **Third person** - "Provides patterns for..." not "I help you with..."

---

**Last Updated**: 2025-12
**Skills Count**: 20 skills across 4 categories
