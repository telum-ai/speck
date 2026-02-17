---
name: clerk-authentication
description: Load when integrating Clerk for authentication in React and Next.js apps. Applies when implementing auth with Next.js App Router, managing sessions, handling webhooks, or building multi-tenant apps with Organizations.
---


## When This Rule Applies
- Setting up auth in Next.js App Router
- Protecting routes with middleware
- Handling user webhooks
- Building multi-tenant apps with Organizations
- Managing sessions and tokens

## Next.js App Router Setup

### 1. Environment Variables

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_...
CLERK_SECRET_KEY=sk_...
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
```

### 2. ClerkProvider in Layout

```tsx
// app/layout.tsx
import { ClerkProvider } from '@clerk/nextjs'

export default function RootLayout({ children }) {
  return (
    <ClerkProvider>
      <html>
        <body>{children}</body>
      </html>
    </ClerkProvider>
  )
}
```

### 3. Middleware (Single File!)

```typescript
// middleware.ts (at project root, only ONE file!)
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server'

const isProtectedRoute = createRouteMatcher([
  '/dashboard(.*)',
  '/api/protected(.*)',
])

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    await auth.protect()
  }
})

export const config = {
  matcher: ['/((?!.*\\..*|_next).*)', '/', '/(api|trpc)(.*)'],
}
```

## Critical: Defense in Depth

**Middleware alone is NOT sufficient for security** (CVE-2025-29927 allows bypass).

### Verify Auth at Every Data Access Point

```typescript
// Server Component
import { auth } from '@clerk/nextjs/server'
import { redirect } from 'next/navigation'

export default async function DashboardPage() {
  const { userId } = await auth()
  
  if (!userId) {
    redirect('/sign-in')
  }

  // Safe to fetch user-specific data
  const data = await fetchUserData(userId)
  return <Dashboard data={data} />
}
```

```typescript
// Route Handler
import { auth } from '@clerk/nextjs/server'
import { NextResponse } from 'next/server'

export async function POST(req: Request) {
  const { userId } = await auth()
  
  if (!userId) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // Safe to proceed
}
```

```typescript
// Server Action
'use server'
import { auth } from '@clerk/nextjs/server'

export async function updateProfile(formData: FormData) {
  const { userId } = await auth()
  
  if (!userId) {
    throw new Error('Unauthorized')
  }

  // Validate input THEN update
}
```

## Session Tokens

### Token Lifecycle
- **Lifetime**: 60 seconds (auto-refreshes at 50s)
- **Cookie limit**: 4KB total (~1.2KB for custom claims)

### Custom Claims (Dashboard → Sessions)

```typescript
// Access custom claims
const { sessionClaims } = await auth()
const role = sessionClaims?.metadata?.role
```

### Force Token Refresh

```typescript
// After updating user metadata via API
const { user } = useUser()
await user.reload()  // Refreshes token + user object
```

## Webhooks (User Sync)

### Signature Verification

```typescript
// app/api/webhooks/clerk/route.ts
import { Webhook } from 'svix'
import { headers } from 'next/headers'
import { WebhookEvent } from '@clerk/nextjs/server'

export async function POST(req: Request) {
  const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET!
  
  const headerPayload = headers()
  const svix_id = headerPayload.get('svix-id')
  const svix_timestamp = headerPayload.get('svix-timestamp')
  const svix_signature = headerPayload.get('svix-signature')

  const payload = await req.json()
  const body = JSON.stringify(payload)

  const wh = new Webhook(WEBHOOK_SECRET)
  let event: WebhookEvent

  try {
    event = wh.verify(body, {
      'svix-id': svix_id!,
      'svix-timestamp': svix_timestamp!,
      'svix-signature': svix_signature!,
    }) as WebhookEvent
  } catch (err) {
    return new Response('Webhook verification failed', { status: 400 })
  }

  // Handle event idempotently
  if (event.type === 'user.created') {
    const { id, email_addresses, first_name, last_name } = event.data
    const email = email_addresses[0]?.email_address
    
    // Upsert to handle retries
    await db.users.upsert({
      where: { clerkId: id },
      create: { clerkId: id, email, firstName: first_name, lastName: last_name },
      update: { email, firstName: first_name, lastName: last_name },
    })
  }

  return new Response('OK', { status: 200 })
}
```

## Organizations (Multi-Tenancy)

### Setup

```tsx
import { OrganizationSwitcher } from '@clerk/nextjs'

// Renders org switcher dropdown
<OrganizationSwitcher />
```

### Access Org in Server Components

```typescript
const { userId, orgId, orgRole } = await auth()

if (orgId) {
  // User is in an organization context
  const data = await fetchOrgData(orgId)
}
```

### Role-Based Access Control

```typescript
const { has } = await auth()

// Check permission
if (!has({ permission: 'org:posts:create' })) {
  throw new Error('Forbidden')
}
```

## Common Gotchas

### 1. Multiple middleware.ts Files
```typescript
// ❌ WRONG: Multiple middleware files
// middleware.ts
// dashboard/middleware.ts
// api/middleware.ts

// ✅ CORRECT: Single middleware.ts at root
```

### 2. Double Redirects
```typescript
// ❌ WRONG: Redirecting in both middleware AND component
// middleware.ts: auth.protect() → redirects
// page.tsx: if (!userId) redirect('/sign-in') → redirects again

// ✅ CORRECT: Centralize redirects in middleware
```

### 3. Prefetch Errors on Protected Routes
```tsx
// ❌ Prefetch fails with 401
<Link href="/dashboard">Dashboard</Link>

// ✅ Disable prefetch for protected routes from public pages
<Link href="/dashboard" prefetch={false}>Dashboard</Link>
```

### 4. Cookie Size Overflow
```typescript
// ❌ Too much metadata → cookie fails silently
sessionClaims: {
  metadata: { /* >1.2KB of data */ }
}

// ✅ Store large data in your database, fetch via API
```

### 5. Rate Limiting
- Backend API: 1,000 requests / 10 seconds
- Don't call `currentUser()` on every request
- Use session claims for frequent data

## Hooks Reference

```typescript
// Client-side hooks
import { useAuth, useUser, useOrganization } from '@clerk/nextjs'

// useAuth - Authentication state
const { isLoaded, userId, sessionId, getToken } = useAuth()

// useUser - Full user object
const { isLoaded, user } = useUser()
// user.update({ firstName: 'New' })
// user.reload()

// useOrganization - Current org context
const { organization, membership } = useOrganization()
```

## Prebuilt Components

```tsx
import {
  SignIn,           // Full sign-in flow
  SignUp,           // Full sign-up flow
  UserButton,       // User menu dropdown
  SignedIn,         // Renders children if signed in
  SignedOut,        // Renders children if signed out
  RedirectToSignIn, // Redirects to sign-in
} from '@clerk/nextjs'
```

## References

- [Next.js App Router](https://clerk.com/docs/quickstarts/nextjs)
- [Middleware](https://clerk.com/docs/references/nextjs/clerk-middleware)
- [Organizations](https://clerk.com/docs/organizations/overview)
- [Webhooks](https://clerk.com/docs/integrations/webhooks)

