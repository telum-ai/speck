---
name: posthog-integration
description: Integrate PostHog for product analytics and feature flags. Use when implementing event tracking, A/B testing, session replay, or funnel analysis.
---

# Integrating PostHog

Provides patterns for product analytics with PostHog. Covers event taxonomy, feature flags, session replay, funnel analysis, and self-hosting considerations.

## 🔌 MCP Server (Recommended)

Install the official PostHog MCP server for AI-assisted analytics:

**Where to put this config (Speck template repos):**
- Add the snippet to `.cursor/mcp.project.json.example` (create if missing; committed, no secrets)
- Then run: `bash .speck/scripts/bash/merge-mcp-config.sh` to generate `.cursor/mcp.json` (local)

```json
{
  "mcpServers": {
    "posthog": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/posthog-mcp-server"],
      "env": {
        "POSTHOG_AUTH_HEADER": "YOUR_PERSONAL_API_KEY"
      }
    }
  }
}
```

Get your API key with the [MCP Server preset](https://app.posthog.com/settings/user-api-keys) on PostHog.

**Tools available**: List events/properties, query trends/funnels, manage feature flags, generate HogQL queries.

---

## When to Use

Apply when implementing product analytics, feature flags, A/B testing, or session replay with PostHog.

---

## Event Taxonomy

### Naming Convention: `category:object_action`

```typescript
// ✓ GOOD: Structured, discoverable
'signup_flow:email_input_focus'
'pricing:annual_plan_click'
'checkout:payment_form_submit'

// ✗ BAD: Inconsistent, hard to find
'userSignedUp'
'click_button'
'pricing page view'
```

### Standard Actions

Use these verbs consistently: `view`, `click`, `submit`, `create`, `update`, `delete`, `start`, `end`, `cancel`, `fail`

### Property Naming

```typescript
// Objects: object_adjective
'user_id', 'item_price', 'signup_source'

// Booleans: is_ or has_ prefix
'is_subscribed', 'has_seen_onboarding'

// Dates: _date or _timestamp suffix
'trial_end_date', 'last_login_timestamp'
```

### Typed Analytics Service

```typescript
import posthog from 'posthog-js';

class Analytics {
  static trackPricingView(plan: 'basic' | 'pro' | 'enterprise') {
    posthog.capture('pricing:page_view', { plan_viewed: plan });
  }
  
  static trackCheckoutStart(cartValue: number, itemCount: number) {
    posthog.capture('checkout:started', { 
      cart_value: cartValue,
      item_count: itemCount 
    });
  }
}
```

---

## Feature Flags

### React Hooks

```typescript
import { useFeatureFlagEnabled, useFeatureFlagVariantKey } from '@posthog/react';

// Boolean flag
function HomePage() {
  const isNewLayoutEnabled = useFeatureFlagEnabled('new-layout');
  return isNewLayoutEnabled ? <NewLayout /> : <OldLayout />;
}

// Multivariate flag
function CheckoutPage() {
  const variant = useFeatureFlagVariantKey('checkout-test');
  
  switch (variant) {
    case 'control': return <StandardCheckout />;
    case 'variant-a': return <CheckoutWithSteps />;
    case 'variant-b': return <CheckoutWithProgress />;
    default: return <StandardCheckout />;
  }
}
```

### JSON Payloads (Dynamic Config)

```typescript
import { useFeatureFlagPayload, useFeatureFlagEnabled } from '@posthog/react';

function Banner() {
  const isEnabled = useFeatureFlagEnabled('promo-banner');
  const payload = useFeatureFlagPayload<{ text: string; color: string }>('promo-banner');
  
  if (!isEnabled) return null;
  
  return <div style={{ background: payload?.color }}>{payload?.text}</div>;
}
```

### Bootstrapping (Prevent Flicker)

```typescript
import { PostHogProvider } from '@posthog/react';

// Pre-compute flags server-side or from cache
const bootstrappedFlags = { 'new-layout': true, 'dark-mode': false };

function App() {
  return (
    <PostHogProvider 
      client={posthog}
      options={{ bootstrap: { featureFlags: bootstrappedFlags } }}
    >
      <Root />
    </PostHogProvider>
  );
}
```

---

## Session Replay

### Reduce Quota with Sampling

```typescript
posthog.init('your-key', {
  session_recording: {
    sampleRate: 0.5,                    // Record 50% of sessions
    minimumDurationMilliseconds: 5000,  // Skip sessions < 5s
  },
});
```

### Trigger Recording for Specific Events

```typescript
posthog.init('your-key', {
  session_recording: {
    recordingStartTriggerEvents: [
      { 
        event: '$pageview',
        properties: { $current_url: { type: 'contains', value: '/pricing' } }
      }
    ]
  }
});

// Or programmatically
if (isHighValueUser) {
  posthog.startSessionRecording();
}
```

---

## Funnel Analysis

### Setup in PostHog Dashboard

1. Create Insight → Funnels
2. Add steps (each is an event with optional filters):
   - Step 1: `$pageview` where URL contains `/pricing`
   - Step 2: `checkout:started`
   - Step 3: `checkout:payment_submitted`
   - Step 4: `purchase:completed`

### Key Settings

| Setting | Use |
|---------|-----|
| First occurrence matching filters | Match first event that satisfies filters (usually what you want) |
| Breakdown by | Segment by device, source, plan type |
| Conversion window | Max time between steps (e.g., 7 days) |

### Correlation Analysis

Enable automatic detection of properties that correlate with conversion/drop-off. PostHog surfaces insights like:

- "Users who viewed help docs have 2x completion rate"
- "Mobile users drop off 3x more at payment step"

---

## Self-Hosting vs Cloud

### Use PostHog Cloud (Recommended)

- ✓ Managed infrastructure, auto-scaling
- ✓ Continuous optimization
- ✓ Faster support
- ✓ US and EU regions available

### Self-Host Only If

- Strict data residency requirements
- Regulatory compliance mandates
- Existing infrastructure you want to leverage

### Self-Host Requirements

- Minimum: 4 vCPU, 16GB RAM, 30GB storage
- Components: PostgreSQL, ClickHouse, Kafka, Redis
- Docker Compose (small) or Kubernetes (scale)

```bash
git clone https://github.com/PostHog/posthog.git
cd posthog/compose
./deploy.sh
```

---

## Common Gotchas

### Event Name Fragmentation
Define a standard taxonomy before launching. Inconsistent naming (`userSignedUp` vs `user_signed_up` vs `sign_up`) fragments your data.

### Feature Flag Loading Delay
Flags aren't available until fetched. Use bootstrapping for critical flags that affect initial render.

### Session Replay Quota
Default records everything. Use sampling + triggers + minimum duration to control costs.

### Ad Blockers
Configure a reverse proxy to improve capture reliability:

```typescript
posthog.init('key', {
  api_host: 'https://yourapp.com/ingest', // Proxy to PostHog
});
```

---

## Quick Reference

| Task | Pattern |
|------|---------|
| Event naming | `category:object_action` |
| Boolean flag | `useFeatureFlagEnabled('flag')` |
| Multivariate flag | `useFeatureFlagVariantKey('flag')` |
| Prevent flicker | Bootstrap flags at init |
| Reduce replay quota | `sampleRate: 0.1` + `minimumDurationMilliseconds` |
| Backend tracking | Node SDK for signup events |

## References

- [PostHog React SDK](https://posthog.com/docs/libraries/react)
- [Feature Flags](https://posthog.com/docs/feature-flags)
- [Session Replay](https://posthog.com/docs/session-replay)
- [Event Best Practices](https://posthog.com/docs/product-analytics/best-practices)

