---
name: offline-first-architecture
description: Build offline-first applications that work without network connectivity. Use when implementing local storage, sync queues, conflict resolution, or background sync.
---

# Building Offline-First Applications

Provides patterns for applications that work without network connectivity. Covers local-first data, sync strategies, conflict resolution, and background sync.

## When to Use

Apply when building mobile apps, PWAs, or any application requiring reliable offline functionality.

---

## Core Principles

1. **Local First**: Read/write to local storage, sync in background
2. **Optimistic UI**: Show changes immediately, reconcile later
3. **Conflict Resolution**: Define how to handle concurrent edits
4. **Sync Queue**: Track pending changes, retry on reconnect

---

## Local Storage Options

| Storage | Size Limit | Use Case |
|---------|-----------|----------|
| **IndexedDB** | ~50% of disk | Structured data, queries |
| **localStorage** | ~5-10MB | Small key-value |
| **SQLite (native)** | Unlimited | Mobile apps, large datasets |
| **OPFS** | Large | File storage in browser |

### IndexedDB with Dexie

```typescript
import Dexie, { Table } from 'dexie';

interface Todo {
  id: string;
  title: string;
  completed: boolean;
  updatedAt: number;
  syncStatus: 'synced' | 'pending' | 'conflict';
}

class AppDatabase extends Dexie {
  todos!: Table<Todo>;

  constructor() {
    super('AppDB');
    this.version(1).stores({
      todos: 'id, syncStatus, updatedAt',
    });
  }
}

const db = new AppDatabase();

// Offline-first write
async function updateTodo(id: string, updates: Partial<Todo>) {
  await db.todos.update(id, {
    ...updates,
    updatedAt: Date.now(),
    syncStatus: 'pending',
  });
  
  // Queue for sync
  await syncQueue.add({ type: 'update', entity: 'todo', id, updates });
}
```

---

## Sync Queue Pattern

### Queue Implementation

```typescript
interface SyncOperation {
  id: string;
  type: 'create' | 'update' | 'delete';
  entity: string;
  entityId: string;
  data: any;
  createdAt: number;
  retryCount: number;
}

class SyncQueue {
  private db: Dexie;

  async add(operation: Omit<SyncOperation, 'id' | 'createdAt' | 'retryCount'>) {
    await this.db.table('syncQueue').add({
      ...operation,
      id: crypto.randomUUID(),
      createdAt: Date.now(),
      retryCount: 0,
    });
  }

  async process() {
    const operations = await this.db.table('syncQueue')
      .orderBy('createdAt')
      .toArray();

    for (const op of operations) {
      try {
        await this.executeOperation(op);
        await this.db.table('syncQueue').delete(op.id);
      } catch (error) {
        if (op.retryCount >= 3) {
          await this.handleFailure(op, error);
        } else {
          await this.db.table('syncQueue').update(op.id, {
            retryCount: op.retryCount + 1,
          });
        }
      }
    }
  }

  private async executeOperation(op: SyncOperation) {
    const response = await fetch(`/api/${op.entity}/${op.entityId}`, {
      method: op.type === 'create' ? 'POST' : op.type === 'delete' ? 'DELETE' : 'PUT',
      body: JSON.stringify(op.data),
    });
    
    if (!response.ok) throw new Error(`Sync failed: ${response.status}`);
  }
}
```

### Process on Reconnect

```typescript
// Listen for online status
window.addEventListener('online', () => {
  syncQueue.process();
});

// Also process periodically
setInterval(() => {
  if (navigator.onLine) {
    syncQueue.process();
  }
}, 30000);
```

---

## Conflict Resolution

### Last-Write-Wins (Simple)

```typescript
async function resolveConflict(local: Todo, server: Todo): Promise<Todo> {
  // Compare timestamps
  return local.updatedAt > server.updatedAt ? local : server;
}
```

### Field-Level Merge

```typescript
async function mergeConflict(local: Todo, server: Todo, base: Todo): Promise<Todo> {
  const merged = { ...server };
  
  // For each field, check if local changed it from base
  for (const key of Object.keys(local)) {
    const localChanged = local[key] !== base[key];
    const serverChanged = server[key] !== base[key];
    
    if (localChanged && !serverChanged) {
      // Local changed, server didn't → use local
      merged[key] = local[key];
    } else if (localChanged && serverChanged) {
      // Both changed → conflict, need resolution
      merged[key] = await resolveFieldConflict(key, local[key], server[key]);
    }
    // If only server changed or neither changed, keep server value
  }
  
  return merged;
}
```

### User-Prompted Resolution

```typescript
async function handleConflict(local: Todo, server: Todo): Promise<Todo> {
  // Store conflict for user review
  await db.conflicts.add({
    entity: 'todo',
    entityId: local.id,
    localVersion: local,
    serverVersion: server,
  });
  
  // Mark as conflict in UI
  await db.todos.update(local.id, { syncStatus: 'conflict' });
  
  // Show conflict resolution UI
  showConflictDialog(local.id);
  
  return server; // Use server as current until resolved
}
```

---

## Background Sync API

```typescript
// Register for background sync
async function requestSync() {
  if ('serviceWorker' in navigator && 'sync' in window.SyncManager) {
    const registration = await navigator.serviceWorker.ready;
    await registration.sync.register('sync-data');
  }
}

// Service worker: handle sync event
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-data') {
    event.waitUntil(syncData());
  }
});

async function syncData() {
  const queue = await getQueuedOperations();
  
  for (const op of queue) {
    await executeOperation(op);
    await removeFromQueue(op.id);
  }
}
```

---

## Optimistic UI Pattern

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';

function useTodoMutation() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: updateTodo,
    
    onMutate: async (newTodo) => {
      // Cancel in-flight queries
      await queryClient.cancelQueries({ queryKey: ['todos'] });
      
      // Snapshot previous
      const previous = queryClient.getQueryData(['todos']);
      
      // Optimistically update UI
      queryClient.setQueryData(['todos'], (old) =>
        old.map(t => t.id === newTodo.id ? newTodo : t)
      );
      
      // Store in local DB with pending status
      await db.todos.put({ ...newTodo, syncStatus: 'pending' });
      
      return { previous };
    },
    
    onError: (err, newTodo, context) => {
      // Rollback on error
      queryClient.setQueryData(['todos'], context.previous);
      await db.todos.update(newTodo.id, { syncStatus: 'error' });
    },
    
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['todos'] });
    },
  });
}
```

---

## Data Versioning

### Vector Clocks (Distributed)

```typescript
interface VectorClock {
  [nodeId: string]: number;
}

function incrementClock(clock: VectorClock, nodeId: string): VectorClock {
  return { ...clock, [nodeId]: (clock[nodeId] || 0) + 1 };
}

function compareClocks(a: VectorClock, b: VectorClock): 'before' | 'after' | 'concurrent' {
  let aBeforeB = false;
  let bBeforeA = false;
  
  const allKeys = new Set([...Object.keys(a), ...Object.keys(b)]);
  
  for (const key of allKeys) {
    const aVal = a[key] || 0;
    const bVal = b[key] || 0;
    
    if (aVal < bVal) aBeforeB = true;
    if (bVal < aVal) bBeforeA = true;
  }
  
  if (aBeforeB && !bBeforeA) return 'before';
  if (bBeforeA && !aBeforeB) return 'after';
  return 'concurrent';
}
```

---

## Common Gotchas

### IndexedDB Transaction Limits
Transactions auto-commit after microtask. Keep transactions short.

### Storage Quota
Check available storage, handle quota exceeded:

```typescript
const estimate = await navigator.storage.estimate();
const usedPercent = (estimate.usage / estimate.quota) * 100;
```

### Offline Detection is Unreliable
`navigator.onLine` can be wrong. Always handle network errors gracefully.

### Clock Skew
Don't rely on client timestamps for ordering. Use server-assigned sequence numbers when possible.

### Large Sync Payloads
Sync incrementally (since last sync timestamp) rather than full dataset.

---

## Quick Reference

| Task | Pattern |
|------|---------|
| Local storage | IndexedDB with Dexie |
| Sync queue | Store operations, process on reconnect |
| Conflict resolution | Last-write-wins or field-level merge |
| Optimistic UI | Update immediately, rollback on error |
| Background sync | Service Worker Sync API |
| Version tracking | `updatedAt` or vector clocks |

## References

- [Local-First Software](https://www.inkandswitch.com/local-first/)
- [Dexie.js](https://dexie.org/)
- [Background Sync](https://developer.mozilla.org/en-US/docs/Web/API/Background_Synchronization_API)

