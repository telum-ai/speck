---
name: tanstack-query
description: Load when using TanStack Query (React Query) for server state management. Applies when implementing data fetching, caching, mutations, or optimistic updates in React applications.
---

# Using TanStack Query (React Query)

Follow these patterns for server state management with TanStack Query. Covers query keys, mutations, optimistic updates, infinite queries, and caching strategies.

## When This Rule Applies

Apply when managing server state in React applications - data fetching, caching, synchronization.

---

## Query Basics

### Query Key Convention

```typescript
// Structure: [entity, ...filters/identifiers]
const queryKey = ['todos'];                    // List all
const queryKey = ['todos', { status: 'done' }]; // Filtered list
const queryKey = ['todos', todoId];            // Single item
const queryKey = ['todos', todoId, 'comments']; // Nested resource
```

### Basic Query

```typescript
import { useQuery } from '@tanstack/react-query';

function TodoList() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['todos'],
    queryFn: () => fetch('/api/todos').then(res => res.json()),
  });

  if (isLoading) return <Spinner />;
  if (error) return <Error message={error.message} />;
  
  return <ul>{data.map(todo => <TodoItem key={todo.id} todo={todo} />)}</ul>;
}
```

---

## Mutations

### Basic Mutation with Cache Invalidation

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';

function AddTodo() {
  const queryClient = useQueryClient();
  
  const mutation = useMutation({
    mutationFn: (newTodo) => fetch('/api/todos', {
      method: 'POST',
      body: JSON.stringify(newTodo),
    }).then(res => res.json()),
    
    onSuccess: () => {
      // Invalidate and refetch
      queryClient.invalidateQueries({ queryKey: ['todos'] });
    },
  });

  return (
    <button 
      onClick={() => mutation.mutate({ title: 'New Todo' })}
      disabled={mutation.isPending}
    >
      Add Todo
    </button>
  );
}
```

### Optimistic Updates

```typescript
const mutation = useMutation({
  mutationFn: updateTodo,
  
  onMutate: async (newTodo) => {
    // Cancel outgoing refetches
    await queryClient.cancelQueries({ queryKey: ['todos', newTodo.id] });
    
    // Snapshot previous value
    const previousTodo = queryClient.getQueryData(['todos', newTodo.id]);
    
    // Optimistically update
    queryClient.setQueryData(['todos', newTodo.id], newTodo);
    
    // Return context for rollback
    return { previousTodo };
  },
  
  onError: (err, newTodo, context) => {
    // Rollback on error
    queryClient.setQueryData(['todos', newTodo.id], context.previousTodo);
  },
  
  onSettled: () => {
    // Refetch to ensure sync
    queryClient.invalidateQueries({ queryKey: ['todos'] });
  },
});
```

---

## Caching Strategies

### Stale Time vs. Cache Time

```typescript
useQuery({
  queryKey: ['user', userId],
  queryFn: fetchUser,
  staleTime: 5 * 60 * 1000,  // Fresh for 5 min (no background refetch)
  gcTime: 30 * 60 * 1000,    // Keep in cache for 30 min (formerly cacheTime)
});
```

| Setting | Description |
|---------|-------------|
| `staleTime: 0` | Always refetch on mount (default) |
| `staleTime: Infinity` | Never refetch automatically |
| `gcTime: 0` | Don't cache at all |
| `gcTime: Infinity` | Cache forever |

### Global Defaults

```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000,      // 1 min fresh
      gcTime: 5 * 60 * 1000,     // 5 min cache
      retry: 1,                   // Retry once
      refetchOnWindowFocus: false,
    },
  },
});
```

---

## Infinite Queries (Pagination)

```typescript
import { useInfiniteQuery } from '@tanstack/react-query';

function InfiniteTodoList() {
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteQuery({
    queryKey: ['todos'],
    queryFn: ({ pageParam = 0 }) => 
      fetch(`/api/todos?offset=${pageParam}&limit=20`).then(r => r.json()),
    getNextPageParam: (lastPage, pages) => 
      lastPage.hasMore ? pages.length * 20 : undefined,
  });

  return (
    <>
      {data.pages.map(page => 
        page.items.map(todo => <TodoItem key={todo.id} todo={todo} />)
      )}
      <button 
        onClick={() => fetchNextPage()} 
        disabled={!hasNextPage || isFetchingNextPage}
      >
        {isFetchingNextPage ? 'Loading...' : hasNextPage ? 'Load More' : 'No More'}
      </button>
    </>
  );
}
```

---

## Prefetching

### On Hover

```typescript
function TodoLink({ todoId }) {
  const queryClient = useQueryClient();
  
  const prefetch = () => {
    queryClient.prefetchQuery({
      queryKey: ['todos', todoId],
      queryFn: () => fetchTodo(todoId),
      staleTime: 60 * 1000, // Only prefetch if stale
    });
  };

  return (
    <Link to={`/todos/${todoId}`} onMouseEnter={prefetch}>
      View Todo
    </Link>
  );
}
```

### In Loader (React Router)

```typescript
// Route loader
export const loader = (queryClient) => async ({ params }) => {
  await queryClient.ensureQueryData({
    queryKey: ['todos', params.id],
    queryFn: () => fetchTodo(params.id),
  });
  return null;
};
```

---

## Dependent Queries

```typescript
// Fetch user first, then their projects
function UserProjects({ userId }) {
  const userQuery = useQuery({
    queryKey: ['users', userId],
    queryFn: () => fetchUser(userId),
  });

  const projectsQuery = useQuery({
    queryKey: ['projects', { userId }],
    queryFn: () => fetchProjects(userId),
    enabled: !!userQuery.data, // Only run when user is loaded
  });

  // ...
}
```

---

## Query Factory Pattern

```typescript
// queries/todos.ts
export const todoQueries = {
  all: () => ['todos'] as const,
  lists: () => [...todoQueries.all(), 'list'] as const,
  list: (filters: TodoFilters) => [...todoQueries.lists(), filters] as const,
  details: () => [...todoQueries.all(), 'detail'] as const,
  detail: (id: string) => [...todoQueries.details(), id] as const,
};

// Usage
useQuery({ queryKey: todoQueries.detail(todoId), queryFn: ... });
queryClient.invalidateQueries({ queryKey: todoQueries.lists() });
```

---

## Common Gotchas

### Object Reference in Query Key
Query keys are compared by reference. Use stable objects or serialize:

```typescript
// BAD: New object each render
useQuery({ queryKey: ['todos', { filter }], ... });

// GOOD: Stable reference
const queryKey = useMemo(() => ['todos', { filter }], [filter]);
useQuery({ queryKey, ... });
```

### Stale Closures in Mutations
Use `onMutate` context instead of closure variables:

```typescript
// BAD: Stale closure
const previousData = queryClient.getQueryData(['todos']);
mutation.mutate(newTodo);
// In onError: previousData is stale

// GOOD: Return from onMutate
onMutate: async (newTodo) => {
  const previousData = queryClient.getQueryData(['todos']);
  return { previousData };
},
```

### Missing Error Boundaries
Wrap query-heavy components in error boundaries for graceful failure.

---

## Quick Reference

| Task | Pattern |
|------|---------|
| Refetch on mount | `staleTime: 0` (default) |
| Cache indefinitely | `staleTime: Infinity` |
| Invalidate cache | `queryClient.invalidateQueries()` |
| Optimistic update | `onMutate` → update cache → return rollback |
| Dependent query | `enabled: !!dependencyData` |
| Pagination | `useInfiniteQuery` + `getNextPageParam` |

## References

- [TanStack Query Docs](https://tanstack.com/query/latest)
- [Query Key Factory](https://tkdodo.eu/blog/effective-react-query-keys)

