# 🍳 Speck Recipes

Recipes are pre-configured project templates for common full-stack setups. They provide starting points that accelerate the `/project-specify` → `/project-plan` flow by pre-filling architectural decisions, technology choices, and common epic structures.

**Related**: Each recipe has companion **Skills** in `.speck/skills/` that provide deep implementation patterns for the recommended services (Stripe, Supabase, Clerk, etc.).

## 🛒 Buy vs. Build Philosophy

**Don't reinvent the wheel!** Modern development is about composing proven services, not building everything from scratch. Each recipe includes recommended external services for common functionality:

| Category | Top Picks | Why Buy? |
|----------|-----------|----------|
| **Auth** | Clerk, Stytch, Auth0, Supabase Auth | Security is hard, compliance is harder |
| **Payments** | Stripe, Paddle, LemonSqueezy | PCI compliance + global payments |
| **Email** | Resend, Postmark, SendGrid | Deliverability requires reputation |
| **SMS/Messaging** | Twilio, Plivo, Unipile | Multi-channel + carrier relationships |
| **File Storage** | Cloudinary, Uploadcare, S3 | CDN + optimization included |
| **Search** | Meilisearch, Algolia, Typesense | Relevance tuning is complex |
| **Analytics** | PostHog, Mixpanel, Sentry | Error tracking + product analytics |
| **AI/ML** | OpenAI, Anthropic, Replicate | Model hosting + scaling |
| **Real-time** | Pusher, Ably, LiveKit | WebSocket infrastructure at scale |
| **Maps** | Mapbox, Google Maps | Data + rendering + routing |

See [External Services Reference](#external-services-reference) for detailed recommendations.

## How Recipes Work

1. **Detection**: The `/speck` router detects when a user's request matches a recipe
   - Matching is based on the recipe’s `keywords:` list in `.speck/recipes/<recipe>/recipe.yaml` (case-insensitive phrase matching)
2. **Suggestion**: User is offered the matching recipe as a starting point
3. **Customization**: Recipe templates are filled with user-specific details
4. **Generation**: Creates project.md, architecture.md, and suggested epics

## Available Recipes

| Recipe | Use Case | Stack | Complexity |
|--------|----------|-------|------------|
| [react-fastapi-postgres](#react-fastapi-postgres) | Full-stack web app | React + FastAPI + PostgreSQL | Level 2-3 |
| [nextjs-supabase](#nextjs-supabase) | JAMstack/Serverless app | Next.js + Supabase | Level 2 |
| [sveltekit-supabase](#sveltekit-supabase) | Performant full-stack app | SvelteKit + Supabase | Level 2 |
| [t3-stack](#t3-stack) | Type-safe full-stack | Next.js + tRPC + Prisma | Level 2-3 |
| [django-htmx](#django-htmx) | Python full-stack | Django + HTMX | Level 2 |
| [go-templ-htmx](#go-templ-htmx) | High-perf full-stack | Go + Templ + HTMX | Level 2-3 |
| [expo-fastapi](#expo-fastapi) | Mobile app with API | Expo + FastAPI + PostgreSQL | Level 2-3 |
| [flutter-firebase](#flutter-firebase) | Cross-platform mobile | Flutter + Firebase | Level 2-3 |
| [electron-react](#electron-react) | Desktop app | Electron + React | Level 2-3 |
| [tauri-react](#tauri-react) | Lightweight desktop | Tauri + React + Rust | Level 2-3 |
| [chrome-extension](#chrome-extension) | Browser extension | React + Chrome APIs | Level 2 |
| [cli-tool](#cli-tool) | Command-line utility | Python/Node.js | Level 1-2 |
| [api-service](#api-service) | Pure API backend | FastAPI + PostgreSQL | Level 2 |
| [static-site](#static-site) | Marketing/docs site | Eleventy/Astro | Level 1 |

---

## Recipe Details

### react-fastapi-postgres

**Best for**: Traditional SPA with Python backend, real-time features, complex business logic

**Stack**:
- **Frontend**: React 18+ with TypeScript, Vite, Tailwind CSS
- **Backend**: FastAPI with SQLAlchemy, Pydantic v2
- **Database**: PostgreSQL 15+
- **Auth**: Stytch, Auth0, or custom JWT
- **Deployment**: Railway, Render, or Docker

**Recommended External Services**:
| Need | Service | Why |
|------|---------|-----|
| Auth | [Clerk](https://clerk.com) or [Stytch](https://stytch.com) | Great DX, hosted auth/security surface, and generous free tiers |
| Payments | [Stripe](https://stripe.com) | Best API, 2.9% + $0.30 |
| Email | [Resend](https://resend.com) | Modern DX, 3k emails free |
| File Upload | [Uploadcare](https://uploadcare.com) | CDN included, transformations |
| Error Tracking | [Sentry](https://sentry.io) | Python + React SDKs |
| Analytics | [PostHog](https://posthog.com) | Open-source, self-hostable |

**Common Epics**:
1. Authentication & Authorization
2. User Management
3. Core Domain Features
4. Admin Dashboard (optional)
5. Real-time Features (optional)

**Pre-configured**:
- Project structure (monorepo or separate repos)
- API contract patterns (OpenAPI)
- Database migration patterns (Alembic)
- Testing strategy (pytest + Vitest)
- CI/CD workflow suggestions

---

### nextjs-supabase

**Best for**: Rapid development, serverless, real-time out-of-box, smaller teams

**Stack**:
- **Frontend**: Next.js 14+ with App Router, TypeScript, Tailwind CSS
- **Backend**: Supabase (PostgreSQL + Auth + Realtime + Storage)
- **Auth**: Supabase Auth (email, OAuth, magic links)
- **Deployment**: Vercel + Supabase Cloud

**Recommended External Services**:
| Need | Service | Why |
|------|---------|-----|
| Auth | [Supabase Auth](https://supabase.com/auth) | Built-in, free tier generous |
| Payments | [Stripe](https://stripe.com) + [stripe-supabase-sync](https://github.com/supabase/stripe-sync-engine) | Best integration |
| Email | [Resend](https://resend.com) | Pairs well with Vercel |
| Search | [Meilisearch](https://meilisearch.com) | $30/mo, easy setup |
| Analytics | [Vercel Analytics](https://vercel.com/analytics) | Zero-config with Next.js |
| Error Tracking | [Sentry](https://sentry.io) | Next.js plugin available |

**Common Epics**:
1. Authentication (Supabase Auth)
2. Core Data Models & RLS Policies
3. Main Features
4. File Storage (optional)
5. Edge Functions (optional)

**Pre-configured**:
- Row-Level Security patterns
- Type generation from schema
- Real-time subscription patterns
- Edge function patterns

---

### expo-fastapi

**Best for**: Cross-platform mobile apps with shared API backend

**Stack**:
- **Mobile**: Expo SDK 50+, React Native, TypeScript
- **Backend**: FastAPI with SQLAlchemy
- **Database**: PostgreSQL
- **Auth**: Stytch or custom JWT with secure storage
- **Deployment**: EAS Build + Railway

**Recommended External Services**:
| Need | Service | Why |
|------|---------|-----|
| Auth | [Clerk](https://clerk.com) or [Stytch](https://stytch.com) | Mobile SDKs, biometric support |
| Push Notifications | [Expo Push](https://docs.expo.dev/push-notifications/overview/) | Free, built into Expo |
| Payments | [RevenueCat](https://revenuecat.com) | IAP made easy |
| Analytics | [Mixpanel](https://mixpanel.com) or [PostHog](https://posthog.com) | Mobile event tracking |
| Error Tracking | [Sentry](https://sentry.io) | React Native SDK |
| File Upload | [Cloudinary](https://cloudinary.com) | Image optimization for mobile |
| Maps | [Mapbox](https://mapbox.com) | Better RN support than Google |

**Common Epics**:
1. Mobile App Shell & Navigation
2. Authentication & Session Management
3. API Integration Layer
4. Core Mobile Features
5. Push Notifications (optional)
6. Offline Support (optional)

**Pre-configured**:
- Expo configuration
- Navigation patterns (Expo Router)
- Secure token storage
- API client with refresh logic
- Platform-specific considerations

---

### cli-tool

**Best for**: Developer tools, automation scripts, productivity utilities

**Stack Options**:
- **Python**: Click/Typer, Rich for UI
- **Node.js**: Commander, Inquirer, Chalk

**Common Epics**:
1. Core CLI Framework
2. Primary Commands
3. Configuration Management
4. Output Formatting
5. Distribution & Installation

**Pre-configured**:
- Argument parsing patterns
- Configuration file handling
- Interactive prompts
- Progress indicators
- Error handling
- Package distribution (pip/npm)

---

### api-service

**Best for**: Microservices, backend-only systems, API-first products

**Stack**:
- **Backend**: FastAPI with SQLAlchemy
- **Database**: PostgreSQL
- **Docs**: OpenAPI/Swagger auto-generated
- **Deployment**: Docker + Railway/Render

**Recommended External Services**:
| Need | Service | Why |
|------|---------|-----|
| Auth | [Auth0](https://auth0.com) or [Stytch](https://stytch.com) | M2M + API keys |
| Database | [Neon](https://neon.tech) | Serverless Postgres, branching |
| Caching | [Upstash Redis](https://upstash.com) | Serverless, pay-per-request |
| Queue | [Upstash QStash](https://upstash.com/docs/qstash/overall/getstarted) | Serverless message queue |
| Monitoring | [Sentry](https://sentry.io) + [SigNoz](https://signoz.io) | Errors + traces |
| Email | [Postmark](https://postmarkapp.com) | Best deliverability |
| SMS | [Twilio](https://twilio.com) or [Plivo](https://plivo.com) | Reliable, global reach |

**Common Epics**:
1. API Foundation (auth, error handling, logging)
2. Core Domain Endpoints
3. Data Layer & Migrations
4. External Integrations
5. Monitoring & Observability

**Pre-configured**:
- OpenAPI specification
- Request/response validation
- Authentication middleware
- Rate limiting patterns
- Health checks
- Structured logging

---

### static-site

**Best for**: Marketing sites, documentation, blogs

**Stack Options**:
- **Astro**: Content-focused, island architecture
- **Next.js Static**: React-based, familiar DX

**Recommended External Services**:
| Need | Service | Why |
|------|---------|-----|
| CMS | [Sanity](https://sanity.io) or [Contentful](https://contentful.com) | Headless, great DX |
| Forms | [Formspree](https://formspree.io) or [Basin](https://usebasin.com) | No backend needed |
| Analytics | [Plausible](https://plausible.io) or [Fathom](https://usefathom.com) | Privacy-first, simple |
| Search | [Algolia DocSearch](https://docsearch.algolia.com) | Free for docs/OSS |
| Newsletter | [Buttondown](https://buttondown.email) or [ConvertKit](https://convertkit.com) | Simple integrations |
| Comments | [Giscus](https://giscus.app) | GitHub-based, free |

**Common Epics**:
1. Site Structure & Navigation
2. Content Pages
3. Blog/News Section (optional)
4. Contact/Lead Forms
5. Analytics & SEO

**Pre-configured**:
- SEO metadata patterns
- Image optimization
- Content management (MDX or CMS)
- Form handling
- Analytics integration

---

## Using a Recipe

### Via /speck (Recommended)

```
User: /speck I want to build a task management app with React and Python

Speck: 🍳 I found a matching recipe: "react-fastapi-postgres"

     This recipe includes:
     - React 18 + TypeScript + Vite frontend
     - FastAPI + SQLAlchemy backend
     - PostgreSQL database
     - Pre-configured auth epic
     - Common CRUD patterns

     Options:
     1. Use this recipe (customized for your task manager)
     2. Start from scratch (full /project-specify flow)
     3. See other recipes

User: 1

Speck: Great! Let me customize this recipe for your task manager...
     [Proceeds with recipe-based specification]
```

### Via /project-specify

You can also request a recipe explicitly:

```
/project-specify --recipe react-fastapi-postgres "Task management app"
```

---

## Creating Custom Recipes

To add a new recipe:

1. Create directory: `.speck/recipes/[recipe-name]/`
2. Create `recipe.yaml` with metadata
3. Create `project-template.md` (pre-filled project spec)
4. Create `architecture-template.md` (pre-filled architecture)
5. Create `epics-template.md` (suggested epics)
6. Update this README

### Recipe YAML Structure

```yaml
name: recipe-name
display_name: "Human Readable Name"
description: "One-line description of when to use this"
version: "1.0.0"

# Matching keywords for /speck detection
keywords:
  - keyword1
  - keyword2

# Stack specification
stack:
  frontend:
    framework: react
    version: "18+"
    extras: [typescript, vite, tailwind]
  backend:
    framework: fastapi
    version: "0.100+"
    extras: [sqlalchemy, pydantic-v2]
  database:
    type: postgresql
    version: "15+"
  auth:
    options: [stytch, auth0, custom-jwt]
  deployment:
    options: [railway, render, docker]

# Complexity assessment
complexity:
  level: 2-3
  team_size: "1-5"
  timeline: "2-6 months"

# Common epics
suggested_epics:
  - name: "Authentication"
    priority: 1
    stories_estimate: 5-8
  - name: "User Management"
    priority: 1
    stories_estimate: 4-6
  - name: "Core Features"
    priority: 1
    stories_estimate: 8-15
```

---

## Recipe vs From Scratch

**Use a Recipe when**:
- You're building a common type of application
- You want faster time-to-spec
- You're comfortable with the suggested stack
- You want proven patterns

**Start from Scratch when**:
- Your project is unique or experimental
- You need non-standard technology choices
- You want full control over every decision
- You're exploring options

---

## Keeping Recipes Updated

Recipes should be updated when:
- Major framework versions are released
- Better patterns emerge from retrospectives
- Community best practices evolve

**Update Process**:
1. Review changelogs for included technologies
2. Update version numbers in `recipe.yaml`
3. Update patterns in templates
4. Test with a sample project
5. Update this README

---

## External Services Reference

Comprehensive recommendations for common functionality. **Buy, don't build** these unless you have a very good reason!

### 🔐 Authentication & Identity

| Service | Best For | Pricing | Notes |
|---------|----------|---------|-------|
| [Clerk](https://clerk.com) | React/Next.js apps | $0.02/MAU after 10k free | Best DX, React-native |
| [Stytch](https://stytch.com) | Passwordless, B2B SaaS | Usage-based | 99.999% uptime SLA |
| [Auth0](https://auth0.com) | Enterprise, compliance | Premium | SOC2, HIPAA, GDPR |
| [Supabase Auth](https://supabase.com/auth) | Supabase projects | Included | Great for MVP |

### 💳 Payments & Billing

| Service | Best For | Pricing | Notes |
|---------|----------|---------|-------|
| [Stripe](https://stripe.com) | Everything | 2.9% + $0.30 | Best API, global |
| [Paddle](https://paddle.com) | SaaS (MoR) | 5% + $0.50 | Handles taxes, compliance |
| [LemonSqueezy](https://lemonsqueezy.com) | Digital products | 5% + $0.50 | MoR for creators |
| [RevenueCat](https://revenuecat.com) | Mobile IAP | Usage-based | In-app purchases simplified |

### 📧 Email

| Service | Best For | Pricing | Notes |
|---------|----------|---------|-------|
| [Resend](https://resend.com) | Modern teams | $0 for 3k, $20/50k | Beautiful DX |
| [Postmark](https://postmarkapp.com) | Transactional | $15/10k | Fastest delivery |
| [SendGrid](https://sendgrid.com) | High volume | $20/50k | Feature-rich |
| [Amazon SES](https://aws.amazon.com/ses/) | Cost optimization | $0.10/1k | Cheapest at scale |

### 💬 SMS & Messaging

| Service | Best For | Pricing | Notes |
|---------|----------|---------|-------|
| [Twilio](https://twilio.com) | Full-featured | Pay-per-use | SMS, voice, video |
| [Plivo](https://plivo.com) | Cost-effective | Pay-per-use | 40% cheaper than Twilio |
| [Unipile](https://unipile.com) | Unified messaging | Pay-per-account | **LinkedIn + WhatsApp + Email in one API!** |
| [MessageBird](https://messagebird.com) | Omnichannel | Pay-per-use | Great for support |

> 💡 **Pro tip**: For apps needing multi-channel outreach (CRM, sales, recruiting), [Unipile](https://unipile.com) provides a single API for LinkedIn, WhatsApp, Instagram, Gmail, Outlook, and calendars - huge time saver vs. integrating each separately!

### 📁 File Storage & Media

| Service | Best For | Pricing | Notes |
|---------|----------|---------|-------|
| [Cloudinary](https://cloudinary.com) | Image/video optimization | Free tier + usage | Auto-optimization, CDN |
| [Uploadcare](https://uploadcare.com) | File uploads | Free tier + usage | Upload widget, CDN |
| [AWS S3](https://aws.amazon.com/s3/) | Raw storage | $0.023/GB | Cheapest at scale |
| [Supabase Storage](https://supabase.com/storage) | Supabase projects | Included | S3-compatible |

### 🔍 Search

| Service | Best For | Pricing | Notes |
|---------|----------|---------|-------|
| [Meilisearch](https://meilisearch.com) | Most projects | $30/mo or self-host | Open-source, easy |
| [Algolia](https://algolia.com) | Enterprise, e-commerce | Premium | Most features |
| [Typesense](https://typesense.org) | Self-hosting | Free (OSS) | Simple, fast |

### 📊 Analytics & Monitoring

| Service | Best For | Pricing | Notes |
|---------|----------|---------|-------|
| [PostHog](https://posthog.com) | Product analytics | Free tier generous | Open-source, all-in-one |
| [Sentry](https://sentry.io) | Error tracking | Free tier + $26/mo | Essential for production |
| [LogRocket](https://logrocket.com) | Session replay | Free tier + premium | Debug user issues |
| [Plausible](https://plausible.io) | Privacy-first web | $9/mo | Simple, GDPR-friendly |

### 🤖 AI & ML

| Service | Best For | Pricing | Notes |
|---------|----------|---------|-------|
| [OpenAI](https://openai.com) | GPT, DALL-E | Pay-per-token | Most capable |
| [Anthropic](https://anthropic.com) | Claude | Pay-per-token | Best for long context |
| [Replicate](https://replicate.com) | Image generation | Pay-per-run | Easy model deployment |
| [Together AI](https://together.ai) | Open models | Pay-per-token | Llama, Mixtral cheaper |

### ⚡ Real-time & WebSockets

| Service | Best For | Pricing | Notes |
|---------|----------|---------|-------|
| [Pusher](https://pusher.com) | Simple pub/sub | Free tier + usage | Easy setup |
| [Ably](https://ably.com) | Enterprise real-time | Usage-based | E2E encryption |
| [LiveKit](https://livekit.io) | Video/voice | 1k mins free | Powers ChatGPT voice |
| [Supabase Realtime](https://supabase.com/realtime) | Supabase projects | Included | PostgreSQL changes |

### 🗺️ Maps & Location

| Service | Best For | Pricing | Notes |
|---------|----------|---------|-------|
| [Mapbox](https://mapbox.com) | Custom styling | Free tier + usage | Beautiful maps |
| [Google Maps](https://developers.google.com/maps) | Maximum coverage | $200/mo credit | Best data |
| [Radar](https://radar.com) | Geofencing | Free tier + usage | Location tracking |

### 🗄️ Database & Backend

| Service | Best For | Pricing | Notes |
|---------|----------|---------|-------|
| [Supabase](https://supabase.com) | Full-stack BaaS | Generous free tier | Postgres + Auth + Storage |
| [Neon](https://neon.tech) | Serverless Postgres | Free tier + usage | Branching, scale-to-zero |
| [PlanetScale](https://planetscale.com) | MySQL at scale | Free tier + usage | Branching, Vitess |
| [Upstash](https://upstash.com) | Serverless Redis/Kafka | Pay-per-request | Great for serverless |
| [Convex](https://convex.dev) | Real-time backend | Free tier + usage | TypeScript-native |

---

**Last Updated**: 2025-12  
**Recipe Format Version**: 1.1

