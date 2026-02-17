---
name: firebase-integration
description: Load when integrating Firebase for mobile and web apps. Applies when implementing Firestore security rules, custom claims, FCM push notifications, or offline persistence in Flutter/React Native.
---


## When This Rule Applies

Apply when building mobile or web apps with Firebase Auth, Firestore, or Cloud Messaging.

---

## Firestore Security Rules

### Basic Structure with Helper Functions

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isAdmin() {
      return request.auth.token.admin == true;
    }
    
    // User documents - owner access only
    match /users/{userId} {
      allow read, write: if isOwner(userId);
    }
    
    // Posts - read if signed in, write if owner or admin
    match /posts/{postId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && 
                       request.resource.data.author == request.auth.uid;
      allow update, delete: if isOwner(resource.data.author) || isAdmin();
    }
  }
}
```

### Role-Based Access (Document-Level Roles)

```
// Document structure: { title: "...", roles: { "user123": "editor", "user456": "viewer" } }

match /documents/{docId} {
  function getRole() {
    return resource.data.roles[request.auth.uid];
  }
  
  function hasRole(allowedRoles) {
    return request.auth != null && getRole() in allowedRoles;
  }
  
  allow read: if hasRole(['owner', 'editor', 'viewer']);
  allow write: if hasRole(['owner', 'editor']);
  allow delete: if hasRole(['owner']);
}
```

### Data Validation

```
match /tasks/{taskId} {
  function isValidTask() {
    let data = request.resource.data;
    return data.title is string &&
           data.title.size() > 0 &&
           data.title.size() <= 200 &&
           data.status in ['pending', 'in_progress', 'completed'];
  }
  
  allow create: if isSignedIn() && isValidTask();
  allow update: if isOwner(resource.data.createdBy) && isValidTask();
}
```

---

## Firebase Auth with Custom Claims

### Setting Claims (Admin SDK - Server Only)

```javascript
// Node.js Admin SDK
const admin = require('firebase-admin');

async function setUserRole(uid, role) {
  await admin.auth().setCustomUserClaims(uid, { role });
}

// Usage
await setUserRole('user123', 'admin');
```

### Reading Claims (Client)

```dart
// Flutter
Future<String?> getUserRole() async {
  final user = FirebaseAuth.instance.currentUser;
  final idTokenResult = await user?.getIdTokenResult(true); // Force refresh
  return idTokenResult?.claims?['role'] as String?;
}
```

```javascript
// React Native
const idTokenResult = await auth().currentUser?.getIdTokenResult(true);
const role = idTokenResult?.claims?.role;
```

### Claims in Security Rules

```
// Security rules can access claims via request.auth.token
allow read: if request.auth.token.role == 'admin';
allow write: if request.auth.token.admin == true;
```

**CRITICAL**: Claims don't update instantly. Users must refresh their token or re-authenticate to see new claims.

---

## Cloud Messaging (FCM)

### Flutter Setup

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> initFCM() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();
  
  // Foreground messages
  FirebaseMessaging.onMessage.listen((message) {
    print('Foreground: ${message.notification?.title}');
  });
  
  // Background messages (must be top-level function)
  FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  
  // Notification taps
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    navigateToScreen(message.data);
  });
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Process silently
}
```

### React Native Setup

```javascript
import messaging from '@react-native-firebase/messaging';

async function initFCM() {
  await messaging().requestPermission();
  
  messaging().onMessage(async (message) => {
    console.log('Foreground:', message.notification);
  });
  
  messaging().setBackgroundMessageHandler(async (message) => {
    console.log('Background:', message.data);
  });
  
  messaging().onNotificationOpenedApp((message) => {
    navigateToScreen(message.data);
  });
}
```

### Sending from Server

```javascript
const admin = require('firebase-admin');

await admin.messaging().send({
  token: deviceToken,
  notification: { title: 'Hello', body: 'World' },
  data: { action: 'open_chat', chatId: '123' },
  android: { priority: 'high' },
  apns: { payload: { aps: { sound: 'default' } } },
});
```

### Priority Levels

| Priority | Behavior | Use Case |
|----------|----------|----------|
| High | Immediate delivery, wakes device | Chat, urgent alerts |
| Normal | Batched, opportunistic | News, summaries |

---

## Offline Persistence

### Firestore (Enabled by Default on Mobile)

```dart
// Flutter - Configure persistence
await FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);

// Check if data is from cache
final snapshot = await doc.get();
print('From cache: ${snapshot.metadata.isFromCache}');
```

### Realtime Database (Must Enable Manually)

```dart
// Flutter
await FirebaseDatabase.instance.setPersistenceEnabled(true);
await FirebaseDatabase.instance.setPersistenceCacheSizeBytes(50 * 1024 * 1024);

// Check connection state
database.ref('.info/connected').onValue.listen((event) {
  final connected = event.snapshot.value as bool;
  print(connected ? 'Online' : 'Offline');
});
```

---

## Performance Optimization

### Query Best Practices

```dart
// BAD: Fetch all documents
final all = await firestore.collection('products').get();

// GOOD: Paginate with limit
final page = await firestore
    .collection('products')
    .orderBy('createdAt', descending: true)
    .limit(20)
    .get();

// Continue pagination
final nextPage = await firestore
    .collection('products')
    .orderBy('createdAt', descending: true)
    .startAfterDocument(page.docs.last)
    .limit(20)
    .get();
```

### Denormalization Pattern

```javascript
// Store author info in post to avoid joins
const post = {
  title: 'My Post',
  authorId: 'user123',
  authorName: 'John',      // Denormalized
  authorAvatar: 'url...',  // Denormalized
};

// Update all posts when author changes
async function updateAuthor(authorId, updates) {
  const batch = firestore.batch();
  batch.update(firestore.doc(`authors/${authorId}`), updates);
  
  const posts = await firestore.collection('posts')
    .where('authorId', '==', authorId).get();
  
  posts.forEach(doc => {
    batch.update(doc.ref, {
      authorName: updates.name,
      authorAvatar: updates.avatar,
    });
  });
  
  await batch.commit();
}
```

---

## Common Gotchas

### Rules Don't Cascade to Subcollections
Each path needs explicit rules:

```
match /posts/{postId} {
  allow read: if true;
  
  // Subcollection needs its own rules!
  match /comments/{commentId} {
    allow read: if true;
  }
}
```

### Claims Not Updating
Force token refresh after setting claims:

```dart
await user.getIdTokenResult(true); // Force refresh
```

### FCM Background Handler Must Be Top-Level
```dart
// WRONG: Instance method
class MyClass {
  Future<void> _handler(RemoteMessage m) async {} // Won't work
}

// RIGHT: Top-level function
@pragma('vm:entry-point')
Future<void> _handler(RemoteMessage m) async {}
```

### Offline Writes Queue Forever
Pending writes survive app restarts. Consider clearing on logout:

```dart
await FirebaseFirestore.instance.clearPersistence();
```

---

## Quick Reference

| Task | Pattern |
|------|---------|
| Check auth in rules | `request.auth != null` |
| Check custom claim | `request.auth.token.role == 'admin'` |
| Validate data | `request.resource.data.field is string` |
| FCM high priority | `android: { priority: 'high' }` |
| Paginate queries | `orderBy().limit(20).startAfterDocument()` |
| Force token refresh | `getIdTokenResult(true)` |

## References

- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Custom Claims](https://firebase.google.com/docs/auth/admin/custom-claims)
- [FCM Docs](https://firebase.google.com/docs/cloud-messaging)

