# Speck Patterns Library

**Status**: Active registry — the single lazy index for integration/domain patterns.
**Lazy-loaded (v8 mechanism)**: Every skill listed here carries `disable-model-invocation: true` in its frontmatter, so it is **NOT** on the agent's always-on skill surface. It is `Read` on demand only when the work actually touches that domain. (v7 described this as a convention; v8 enforces it with a real mechanism — the always-on surface shrinks so common sense fits back in context.)

---

## What This Is

A registry of **integration & domain patterns** — packaged know-how for connecting to specific external services or implementing specific technical patterns. Each entry corresponds to a `.cursor/skills/<name>/SKILL.md` (the canonical tree; `.claude/` and `.codex/` symlink to it, so a single copy serves every host).

These are **patterns, not always-loaded skills**. The orchestration agent does not pre-load them. They are pulled in only when:

1. A story's `spec.md` or `plan.md` explicitly names one of these services
2. The user asks for an integration ("how do I do Stripe webhooks?")
3. `/audit` or `/larp` needs domain-specific validation patterns

## Loading Pattern

```
1. Agent detects need (e.g., spec says "Integrate Stripe Checkout")
2. Agent consults this README to find the right pattern
3. Agent reads .cursor/skills/<pattern>/SKILL.md
4. Agent applies pattern to current story/plan
5. Pattern is unloaded after use (not retained in long context)
```

## Catalog

### Authentication & Identity

| Pattern | When to Load | File |
|---------|--------------|------|
| `clerk-authentication` | Implementing Clerk-based auth in React/Next.js | `.cursor/skills/clerk-authentication/SKILL.md` |
| `oauth-implementation` | Building OAuth 2.0 / OIDC, social login, SSO | `.cursor/skills/oauth-implementation/SKILL.md` |

### Payments & Billing

| Pattern | When to Load | File |
|---------|--------------|------|
| `stripe-integration` | Implementing Stripe checkout, subscriptions, webhooks | `.cursor/skills/stripe-integration/SKILL.md` |
| `revenuecat-integration` | iOS/Android subscriptions, entitlements | `.cursor/skills/revenuecat-integration/SKILL.md` |
| `saas-billing-patterns` | SaaS billing logic, proration, dunning, trials | `.cursor/skills/saas-billing-patterns/SKILL.md` |

### Backend Services

| Pattern | When to Load | File |
|---------|--------------|------|
| `supabase-integration` | Supabase database/auth/storage/realtime | `.cursor/skills/supabase-integration/SKILL.md` |
| `firebase-integration` | Firebase Firestore/Auth/FCM | `.cursor/skills/firebase-integration/SKILL.md` |
| `resend-integration` | Transactional email via Resend + React Email | `.cursor/skills/resend-integration/SKILL.md` |

### Observability & Analytics

| Pattern | When to Load | File |
|---------|--------------|------|
| `sentry-integration` | Sentry error tracking and performance | `.cursor/skills/sentry-integration/SKILL.md` |
| `posthog-integration` | PostHog product analytics, flags, A/B | `.cursor/skills/posthog-integration/SKILL.md` |

### Frontend Patterns

| Pattern | When to Load | File |
|---------|--------------|------|
| `tanstack-query` | TanStack Query for server state | `.cursor/skills/tanstack-query/SKILL.md` |
| `progressive-web-apps` | PWA manifest, service workers, offline | `.cursor/skills/progressive-web-apps/SKILL.md` |
| `websocket-implementation` | Real-time bidirectional via WebSocket | `.cursor/skills/websocket-implementation/SKILL.md` |

### Architecture Patterns

| Pattern | When to Load | File |
|---------|--------------|------|
| `multi-tenancy-patterns` | B2B SaaS tenant isolation, RLS | `.cursor/skills/multi-tenancy-patterns/SKILL.md` |
| `offline-first-architecture` | Apps that work offline | `.cursor/skills/offline-first-architecture/SKILL.md` |
| `serverless-architecture` | AWS Lambda, Vercel Functions, CF Workers | `.cursor/skills/serverless-architecture/SKILL.md` |

### Compliance

| Pattern | When to Load | File |
|---------|--------------|------|
| `gdpr-compliance` | EU data processing, consent, right-to-erasure | `.cursor/skills/gdpr-compliance/SKILL.md` |

### Infrastructure & DevOps

| Pattern | When to Load | File |
|---------|--------------|------|
| `docker-containerization` | Dockerfiles, compose, multi-stage builds | `.cursor/skills/docker-containerization/SKILL.md` |
| `github-actions-cicd` | CI/CD pipelines via GitHub Actions | `.cursor/skills/github-actions-cicd/SKILL.md` |

### Model & Task Fit (meta)

| Pattern | When to Load | File |
|---------|--------------|------|
| `model-selection` | Assessing whether the current model fits the task at hand | `.cursor/skills/model-selection/SKILL.md` |

> **Retired in v8**: `ai-api-integration` (a 5-line content-free stub) was deleted. For OpenAI / Anthropic API work, follow the provider's current SDK docs (prefer Context7) plus the relevant backend pattern above — there is no Speck-specific stub to load.

---

## Adding a New Pattern

To add a new pattern to the library:

1. Create `.cursor/skills/<name>/SKILL.md` following the SKILL.md template, with `disable-model-invocation: true` in the frontmatter (patterns are lazy by default).
2. Add a row to the relevant section table above.
3. `.claude/skills/` and `.codex/skills/` are symlinks to `.cursor/skills/`, so no mirroring step is needed.
4. Test the pattern by referencing it in a story plan.

## Why Lazy-Load?

Context economy. Pre-v7 Speck listed all of these in the agent's "available_skills" header every turn, regardless of whether the project used any of them. v8 makes them opt-in knowledge — enforced by `disable-model-invocation: true` — loaded only when the work actually touches that domain. This is the same anti-bloat move as the `.speck/README.md` methodology reference: keep the always-on surface small so the agent's common sense isn't crowded out.

The agent itself decides when to load a pattern based on:
- `spec.md` "Related Services" / "Integrations" section
- Recipe metadata (`_active_recipe` in `project.md`)
- Story `plan.md` "External Dependencies" section
- Explicit user request

---

## Patterns vs Learned Patterns

| Library | Purpose | Source |
|---------|---------|--------|
| `.speck/patterns/library/` (this) | Pre-packaged integration/domain knowledge | Speck team, community |
| `.speck/patterns/learned/` | Project-validated patterns | Retrospectives within YOUR project |

The learned library is project-specific. The integration library is universal.
