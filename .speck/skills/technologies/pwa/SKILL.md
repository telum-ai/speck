---
name: progressive-web-apps
description: Build Progressive Web Apps with offline support, push notifications, and installability. Use when implementing service workers, caching strategies, or PWA manifest configuration.
---

# Progressive Web Apps (PWA)

## When to use this skill
- Setting up service worker caching
- Configuring web app manifest
- Implementing push notifications
- Adding install prompts
- Optimizing for offline-first

## Caching Strategies

**Choose the right strategy for each resource type!**

| Strategy | Use Case | Behavior |
|----------|----------|----------|
| **Cache-First** | Static assets (JS, CSS, images) | Cache → Network fallback |
| **Network-First** | API calls, dynamic content | Network → Cache fallback |
| **Stale-While-Revalidate** | Profile pics, semi-dynamic | Cache immediately, update in background |
| **Cache-Only** | Immutable assets | Never fetch network |
| **Network-Only** | Auth, real-time data | Never cache |

### Using Workbox (Recommended)

```javascript
// sw.js with Workbox
import { registerRoute } from 'workbox-routing';
import { CacheFirst, NetworkFirst, StaleWhileRevalidate } from 'workbox-strategies';
import { CacheableResponsePlugin } from 'workbox-cacheable-response';

// Static assets: Cache-First
registerRoute(
  ({ request }) => ['style', 'script', 'image'].includes(request.destination),
  new CacheFirst({
    cacheName: 'assets-v1',
    plugins: [new CacheableResponsePlugin({ statuses: [0, 200] })]
  })
);

// API calls: Network-First with 3s timeout
registerRoute(
  ({ url }) => url.pathname.startsWith('/api/'),
  new NetworkFirst({
    cacheName: 'api-v1',
    networkTimeoutSeconds: 3
  })
);

// User content: Stale-While-Revalidate
registerRoute(
  ({ url }) => url.pathname.startsWith('/content/'),
  new StaleWhileRevalidate({ cacheName: 'content-v1' })
);
```

## Web App Manifest

```json
{
  "name": "My App",
  "short_name": "App",
  "description": "A progressive web app",
  "start_url": "/?source=pwa",
  "scope": "/",
  "display": "standalone",
  "theme_color": "#3367D6",
  "background_color": "#FFFFFF",
  "icons": [
    { "src": "/icons/192.png", "sizes": "192x192", "type": "image/png", "purpose": "any" },
    { "src": "/icons/512.png", "sizes": "512x512", "type": "image/png", "purpose": "any" },
    { "src": "/icons/512-maskable.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ],
  "shortcuts": [
    {
      "name": "New Task",
      "url": "/tasks/new?source=shortcut",
      "icons": [{ "src": "/icons/shortcut-new.png", "sizes": "192x192" }]
    }
  ]
}
```

### Maskable Icons (Critical for Android!)
- Keep important content in center 80% (safe zone)
- Provide separate maskable icons
- Test with [Maskable.app](https://maskable.app/)

## Push Notifications

### Request Permission + Subscribe

```javascript
async function subscribeToPush() {
  const registration = await navigator.serviceWorker.ready;
  
  const permission = await Notification.requestPermission();
  if (permission !== 'granted') return null;
  
  const subscription = await registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY)
  });
  
  // Send subscription to backend
  await fetch('/api/push/subscribe', {
    method: 'POST',
    body: JSON.stringify(subscription),
    headers: { 'Content-Type': 'application/json' }
  });
  
  return subscription;
}
```

### Handle Push in Service Worker

```javascript
// sw.js
self.addEventListener('push', (event) => {
  const data = event.data?.json() || {};
  
  event.waitUntil(
    self.registration.showNotification(data.title || 'Notification', {
      body: data.body,
      icon: '/icons/192.png',
      badge: '/icons/badge-72.png',
      tag: data.tag || 'default',  // Prevents duplicates
      data: { url: data.url }
    })
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  
  event.waitUntil(
    clients.openWindow(event.notification.data?.url || '/')
  );
});
```

## Install Prompt

```javascript
let deferredPrompt;

window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  deferredPrompt = e;
  showInstallButton();  // Show your custom UI
});

async function handleInstallClick() {
  if (!deferredPrompt) return;
  
  deferredPrompt.prompt();
  const { outcome } = await deferredPrompt.userChoice;
  
  console.log(`Install ${outcome}`);
  deferredPrompt = null;
}

// iOS fallback (no beforeinstallprompt!)
function showIOSInstallInstructions() {
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
  const isStandalone = window.navigator.standalone;
  
  if (isIOS && !isStandalone) {
    showIOSModal();  // "Tap Share → Add to Home Screen"
  }
}
```

## Common Gotchas

### 1. Service Worker Scope

```javascript
// ❌ WRONG: SW at /app/sw.js only controls /app/*
navigator.serviceWorker.register('/app/sw.js');

// ✅ CORRECT: SW at root controls everything
navigator.serviceWorker.register('/sw.js', { scope: '/' });
```

### 2. Cache Poisoning

```javascript
// ❌ WRONG: Caching error responses
cache.put(request, response);

// ✅ CORRECT: Only cache successful responses
if (response.ok) {
  cache.put(request, response.clone());
}
```

### 3. Service Worker Update Stuck

```javascript
// New SW installs but stays in "waiting" state

// Option 1: User-triggered reload
self.addEventListener('message', (e) => {
  if (e.data === 'SKIP_WAITING') self.skipWaiting();
});

// Option 2: Force on activate (use carefully!)
self.addEventListener('activate', (e) => {
  e.waitUntil(clients.claim());
});
```

### 4. iOS Limitations
- Push notifications require iOS 16.4+
- No `beforeinstallprompt` event
- Limited background sync
- Must add meta tags for iOS:

```html
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<link rel="apple-touch-icon" href="/icons/apple-180.png">
```

### 5. Storage Quota

```javascript
// Check before you fill!
async function checkStorage() {
  const { quota, usage } = await navigator.storage.estimate();
  const percentUsed = (usage / quota * 100).toFixed(2);
  
  if (percentUsed > 80) {
    await cleanupOldCaches();
  }
}

// Request persistent storage
await navigator.storage.persist();
```

## Offline Data with IndexedDB

```javascript
import { openDB } from 'idb';

const db = await openDB('myapp', 1, {
  upgrade(db) {
    db.createObjectStore('tasks', { keyPath: 'id', autoIncrement: true });
  }
});

// Save offline
await db.add('tasks', { title: 'New task', synced: false });

// Sync when online
self.addEventListener('sync', (e) => {
  if (e.tag === 'sync-tasks') {
    e.waitUntil(syncPendingTasks());
  }
});
```

## Performance Tips

1. **Navigation Preload** - Start fetching while SW boots

```javascript
self.addEventListener('activate', (e) => {
  e.waitUntil(self.registration.navigationPreload.enable());
});
```

2. **Precache Critical Assets** - Install event

```javascript
self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open('v1').then((cache) =>
      cache.addAll(['/app.js', '/styles.css', '/offline.html'])
    )
  );
});
```

3. **Lazy Load Heavy Features** - Dynamic import

```javascript
const feature = await import('./features/heavy-feature.js');
```

## References

- [web.dev/learn/pwa](https://web.dev/learn/pwa/)
- [Workbox](https://developer.chrome.com/docs/workbox/)
- [PWA Builder](https://www.pwabuilder.com/)
- [Lighthouse](https://developer.chrome.com/docs/lighthouse/)

