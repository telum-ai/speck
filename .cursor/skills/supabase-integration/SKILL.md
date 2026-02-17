---
name: supabase-integration
description: Load when integrating Supabase for database, auth, storage, and real-time features. Applies when implementing Row-Level Security, Supabase Auth with Next.js/React, real-time subscriptions, or Edge Functions.
---

# Supabase Integration

## 🔌 MCP Server (Recommended)

Install the official Supabase MCP server for AI-assisted database management:

**Where to put this config (Speck template repos):**
- Add the snippet to `.cursor/mcp.project.json.example` (create if missing; committed, no secrets)
- Then run: `bash .speck/scripts/bash/merge-mcp-config.sh` to generate `.cursor/mcp.json` (local)

```json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=YOUR_PROJECT_REF&read_only=true"
    }
  }
}
```

OAuth authentication will prompt you to login. Alternatively, configure in your [Supabase Dashboard → Connect → MCP tab](https://supabase.com/dashboard).

**Tools available**: Query databases, manage tables, inspect schemas, generate types, run migrations.

**Security**: Use `read_only=true` for production. Scope to specific project with `project_ref`.

---

## When This Rule Applies
- Setting up Row-Level Security (RLS) policies
- Integrating Supabase Auth with Next.js SSR
- Implementing real-time subscriptions
- Writing Edge Functions
- Generating TypeScript types from schema

## Row-Level Security (CRITICAL)

**RLS is your authorization layer. If disabled, ALL data is exposed.**

### Enable RLS on Every Table

```sql
-- ALWAYS enable RLS on public tables
alter table public.posts enable row level security;

-- Without policies, NO data is accessible (secure by default)
```

### Basic Policy Patterns

```sql
-- Users can only read their own data
create policy "Users read own data"
  on profiles for select
  to authenticated
  using ((select auth.uid()) = user_id);

-- Users can create their own records
create policy "Users create own records"
  on profiles for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

-- Users can update their own records
create policy "Users update own records"
  on profiles for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
```

### Performance: Optimize RLS Policies

```sql
-- ❌ SLOW: Scans team_members for EVERY row
create policy "team_access" on teams for select
  using (
    (select auth.uid()) in (
      select user_id from team_members 
      where team_members.team_id = teams.id
    )
  );

-- ✅ FAST: Fetches user's teams ONCE, then filters
create policy "team_access" on teams for select
  using (
    id in (
      select team_id from team_members 
      where user_id = (select auth.uid())
    )
  );
```

### Security Definer Functions for Complex Auth

```sql
-- Create function in private schema (not exposed via API)
create function private.user_has_role(required_role text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  return exists (
    select 1 from user_roles
    where user_id = (select auth.uid())
    and role = required_role
  );
end;
$$;

-- Use in policy
create policy "admin_only" on sensitive_data for select
  using ((select private.user_has_role('admin')));
```

## Next.js App Router + Supabase Auth

### Client Setup (Use @supabase/ssr)

```typescript
// lib/supabase/client.ts - Browser
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}

// lib/supabase/server.ts - Server Components & Actions
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (cookiesToSet) => {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          )
        },
      },
    }
  )
}
```

### Middleware for Token Refresh

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (cookiesToSet) => {
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // This refreshes the token if needed
  await supabase.auth.getUser()
  
  return response
}
```

### Critical: Use getUser() not getSession()

```typescript
// ✅ CORRECT: Validates JWT signature
const { data: { user } } = await supabase.auth.getUser()

// ❌ WRONG: Only reads cookie, doesn't verify
const { data: { session } } = await supabase.auth.getSession()
```

## Real-time Subscriptions

### Basic Pattern with Cleanup

```typescript
useEffect(() => {
  const channel = supabase
    .channel('messages')
    .on(
      'postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'messages' },
      (payload) => setMessages(prev => [...prev, payload.new])
    )
    .subscribe()

  // ⚠️ CRITICAL: Always unsubscribe to prevent memory leaks
  return () => { channel.unsubscribe() }
}, [])
```

### Filter to Relevant Data Only

```typescript
// Subscribe only to user's data
const channel = supabase
  .channel('user-data')
  .on(
    'postgres_changes',
    {
      event: '*',
      schema: 'public',
      table: 'notifications',
      filter: `user_id=eq.${userId}`,  // Only this user's notifications
    },
    handleChange
  )
  .subscribe()
```

## Edge Functions

```typescript
// supabase/functions/my-function/index.ts
import { createClient } from '@supabase/supabase-js'

Deno.serve(async (req) => {
  // Get auth from request header
  const authHeader = req.headers.get('authorization')
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader! } } }
  )

  // Verify user
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) {
    return new Response('Unauthorized', { status: 401 })
  }

  // RLS applies to all queries with user's JWT
  const { data } = await supabase
    .from('user_data')
    .select()
    .eq('user_id', user.id)

  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

## Type Generation

```bash
# Generate types from remote schema
supabase gen types typescript --project-id your-project > database.types.ts

# Use with client
import { Database } from './database.types'
const supabase = createClient<Database>(url, key)

# Now fully type-safe!
const { data } = await supabase.from('posts').select()
// data is typed as Database['public']['Tables']['posts']['Row'][]
```

## Common Gotchas

### 1. RLS Disabled = Data Exposed
Always check RLS status in Supabase Dashboard → Table Editor

### 2. Service Role Key on Client
```typescript
// ❌ NEVER expose service role key to browser
const supabase = createClient(url, process.env.SUPABASE_SERVICE_ROLE_KEY)

// ✅ Only use anon key on client
const supabase = createClient(url, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY)
```

### 3. N+1 Query Pattern
```typescript
// ❌ BAD: N+1 queries
const posts = await supabase.from('posts').select()
for (const post of posts.data) {
  const author = await supabase.from('users').select().eq('id', post.user_id)
}

// ✅ GOOD: Single query with join
const { data } = await supabase
  .from('posts')
  .select('*, users(name)')  // Nested select = JOIN
```

### 4. Realtime Not Receiving Events
- Check RLS allows SELECT for the subscription
- Verify table has Realtime enabled in Dashboard
- Filter by user_id if needed

## References

- [Row-Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Next.js Integration](https://supabase.com/docs/guides/getting-started/tutorials/with-nextjs)
- [Realtime](https://supabase.com/docs/guides/realtime)
- [Edge Functions](https://supabase.com/docs/guides/functions)

