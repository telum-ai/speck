# Speck Patterns Library

**Status**: Active registry. v7 introduces this catalog. 
**Lazy-loaded**: These patterns are NOT in the agent's default context. They are loaded on-demand only when the agent is implementing in the corresponding domain.

---

## What This Is

A registry of **integration patterns** — packaged know-how for connecting to specific external services or implementing specific technical patterns. Each entry corresponds to a `.claude/skills/<name>/SKILL.md` (which Speck preserves for back-compat). 

In Speck v7, these are **patterns**, not always-loaded skills. The orchestration agent does not pre-load them. They are pulled in only when:

1. A story's `spec.md` or `plan.md` explicitly names one of these services
2. The user asks for an integration ("how do I do Stripe webhooks?")
3. `/audit` or `/larp` needs domain-specific validation patterns

## Loading Pattern

```
1. Agent detects need (e.g., spec says "Integrate Stripe Checkout")
2. Agent consults this README to find the right pattern
3. Agent reads .claude/skills/<pattern>/SKILL.md
4. Agent applies pattern to current story/plan
5. Pattern is unloaded after use (not retained in long context)
```

## Catalog

### Authentication & Identity

| Pattern | When to Load | File |
|---------|--------------|------|
| `clerk-authentication` | Implementing Clerk-based auth in React/Next.js | `.claude/skills/clerk-authentication/SKILL.md` |
| `oauth-implementation` | Building OAuth 2.0 / OIDC, social login, SSO | `.claude/skills/oauth-implementation/SKILL.md` |

### Payments & Billing

| Pattern | When to Load | File |
|---------|--------------|------|
| `stripe-integration` | Implementing Stripe checkout, subscriptions, webhooks | `.claude/skills/stripe-integration/SKILL.md` |
| `revenuecat-integration` | iOS/Android subscriptions, entitlements | `.claude/skills/revenuecat-integration/SKILL.md` |
| `saas-billing-patterns` | SaaS billing logic, proration, dunning, trials | `.claude/skills/saas-billing-patterns/SKILL.md` |

### Backend Services

| Pattern | When to Load | File |
|---------|--------------|------|
| `supabase-integration` | Supabase database/auth/storage/realtime | `.claude/skills/supabase-integration/SKILL.md` |
| `firebase-integration` | Firebase Firestore/Auth/FCM | `.claude/skills/firebase-integration/SKILL.md` |
| `resend-integration` | Transactional email via Resend + React Email | `.claude/skills/resend-integration/SKILL.md` |

### AI

| Pattern | When to Load | File |
|---------|--------------|------|
| `ai-api-integration` | OpenAI / Anthropic Claude API integration | `.claude/skills/ai-api-integration/SKILL.md` |

### Observability & Analytics

| Pattern | When to Load | File |
|---------|--------------|------|
| `sentry-integration` | Sentry error tracking and performance | `.claude/skills/sentry-integration/SKILL.md` |
| `posthog-integration` | PostHog product analytics, flags, A/B | `.claude/skills/posthog-integration/SKILL.md` |

### Frontend Patterns

| Pattern | When to Load | File |
|---------|--------------|------|
| `tanstack-query` | TanStack Query for server state | `.claude/skills/tanstack-query/SKILL.md` |
| `progressive-web-apps` | PWA manifest, service workers, offline | `.claude/skills/progressive-web-apps/SKILL.md` |
| `websocket-implementation` | Real-time bidirectional via WebSocket | `.claude/skills/websocket-implementation/SKILL.md` |

### Architecture Patterns

| Pattern | When to Load | File |
|---------|--------------|------|
| `multi-tenancy-patterns` | B2B SaaS tenant isolation, RLS | `.claude/skills/multi-tenancy-patterns/SKILL.md` |
| `offline-first-architecture` | Apps that work offline | `.claude/skills/offline-first-architecture/SKILL.md` |
| `serverless-architecture` | AWS Lambda, Vercel Functions, CF Workers | `.claude/skills/serverless-architecture/SKILL.md` |

### Compliance

| Pattern | When to Load | File |
|---------|--------------|------|
| `gdpr-compliance` | EU data processing, consent, right-to-erasure | `.claude/skills/gdpr-compliance/SKILL.md` |

### Infrastructure & DevOps

| Pattern | When to Load | File |
|---------|--------------|------|
| `docker-containerization` | Dockerfiles, compose, multi-stage builds | `.claude/skills/docker-containerization/SKILL.md` |
| `github-actions-cicd` | CI/CD pipelines via GitHub Actions | `.claude/skills/github-actions-cicd/SKILL.md` |

---

## Adding a New Pattern

To add a new pattern to the library:

1. Create `.claude/skills/<name>/SKILL.md` following the SKILL.md template
2. Add a row to the relevant section table above
3. Mirror to `.cursor/skills/<name>/SKILL.md` (or use the hardlink mechanism)
4. Test the pattern by referencing it in a story plan

## Why Lazy-Load?

Context economy. Pre-v7 Speck listed all of these in the agent's "available_skills" header every turn, regardless of whether the project used any of them. v7 treats them as opt-in knowledge, loaded only when the work actually touches that domain.

The agent itself decides when to load a pattern based on:
- `spec.md` "Related Services" / "Integrations" section
- Recipe metadata (`_active_recipe` in `project.md`)
- Story `plan.md` "External Dependencies" section
- Explicit user request

---

## Patterns vs Learned Patterns

| Library | Purpose | Source |
|---------|---------|--------|
| `.speck/patterns/library/` (this) | Pre-packaged integration knowledge | Speck team, community |
| `.speck/patterns/learned/` | Project-validated patterns | Retrospectives within YOUR project |

The learned library is project-specific. The integration library is universal.
