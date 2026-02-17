---
name: websocket-implementation
description: Implement WebSockets for real-time communication. Applies when building chat, notifications, live updates, or any feature requiring bidirectional server-client communication.
---

# Implementing WebSockets

Follow these patterns for real-time communication with WebSockets. Covers connection management, reconnection, heartbeats, and scaling considerations.

## When This Rule Applies

Apply when implementing real-time features: chat, notifications, live updates, collaborative editing.

---

## Client Connection Management

### React Hook with Reconnection

```typescript
import { useEffect, useRef, useCallback, useState } from 'react';

interface UseWebSocketOptions {
  url: string;
  onMessage: (data: any) => void;
  onOpen?: () => void;
  onClose?: () => void;
  reconnectInterval?: number;
  maxReconnectAttempts?: number;
}

export function useWebSocket({
  url,
  onMessage,
  onOpen,
  onClose,
  reconnectInterval = 3000,
  maxReconnectAttempts = 5,
}: UseWebSocketOptions) {
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectAttemptsRef = useRef(0);
  const [isConnected, setIsConnected] = useState(false);

  const connect = useCallback(() => {
    const ws = new WebSocket(url);
    
    ws.onopen = () => {
      setIsConnected(true);
      reconnectAttemptsRef.current = 0;
      onOpen?.();
    };

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      onMessage(data);
    };

    ws.onclose = () => {
      setIsConnected(false);
      onClose?.();
      
      // Reconnect with exponential backoff
      if (reconnectAttemptsRef.current < maxReconnectAttempts) {
        const delay = reconnectInterval * Math.pow(2, reconnectAttemptsRef.current);
        setTimeout(() => {
          reconnectAttemptsRef.current++;
          connect();
        }, delay);
      }
    };

    ws.onerror = () => ws.close();
    wsRef.current = ws;
  }, [url, onMessage, onOpen, onClose, reconnectInterval, maxReconnectAttempts]);

  const send = useCallback((data: any) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(data));
    }
  }, []);

  const disconnect = useCallback(() => {
    reconnectAttemptsRef.current = maxReconnectAttempts; // Prevent reconnect
    wsRef.current?.close();
  }, [maxReconnectAttempts]);

  useEffect(() => {
    connect();
    return () => disconnect();
  }, [connect, disconnect]);

  return { send, isConnected, disconnect };
}
```

---

## Server Implementation (Node.js)

### Basic WebSocket Server

```typescript
import { WebSocketServer, WebSocket } from 'ws';
import { createServer } from 'http';

const server = createServer();
const wss = new WebSocketServer({ server });

// Connection management
const clients = new Map<string, WebSocket>();

wss.on('connection', (ws, req) => {
  const userId = authenticateFromRequest(req); // Extract from cookie/token
  clients.set(userId, ws);

  ws.on('message', (data) => {
    const message = JSON.parse(data.toString());
    handleMessage(userId, message);
  });

  ws.on('close', () => {
    clients.delete(userId);
  });

  // Heartbeat
  ws.isAlive = true;
  ws.on('pong', () => { ws.isAlive = true; });
});

// Heartbeat interval
setInterval(() => {
  wss.clients.forEach((ws) => {
    if (ws.isAlive === false) return ws.terminate();
    ws.isAlive = false;
    ws.ping();
  });
}, 30000);

// Send to specific user
function sendToUser(userId: string, data: any) {
  const ws = clients.get(userId);
  if (ws?.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(data));
  }
}

// Broadcast to all
function broadcast(data: any) {
  const message = JSON.stringify(data);
  wss.clients.forEach((ws) => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(message);
    }
  });
}
```

---

## Message Protocol

### Message Types

```typescript
// Client → Server
type ClientMessage = 
  | { type: 'subscribe'; channel: string }
  | { type: 'unsubscribe'; channel: string }
  | { type: 'message'; channel: string; content: string }
  | { type: 'ping' };

// Server → Client
type ServerMessage =
  | { type: 'subscribed'; channel: string }
  | { type: 'message'; channel: string; content: string; sender: string }
  | { type: 'presence'; channel: string; users: string[] }
  | { type: 'pong' }
  | { type: 'error'; message: string };
```

### Message Handler

```typescript
function handleMessage(userId: string, message: ClientMessage) {
  switch (message.type) {
    case 'subscribe':
      subscribeToChannel(userId, message.channel);
      break;
    case 'unsubscribe':
      unsubscribeFromChannel(userId, message.channel);
      break;
    case 'message':
      broadcastToChannel(message.channel, {
        type: 'message',
        channel: message.channel,
        content: message.content,
        sender: userId,
      });
      break;
    case 'ping':
      sendToUser(userId, { type: 'pong' });
      break;
  }
}
```

---

## Channel/Room Management

### Channel Subscriptions

```typescript
const channels = new Map<string, Set<string>>(); // channel → userIds

function subscribeToChannel(userId: string, channel: string) {
  if (!channels.has(channel)) {
    channels.set(channel, new Set());
  }
  channels.get(channel)!.add(userId);
  
  // Notify about subscription
  sendToUser(userId, { type: 'subscribed', channel });
  
  // Broadcast presence update
  broadcastToChannel(channel, {
    type: 'presence',
    channel,
    users: Array.from(channels.get(channel)!),
  });
}

function broadcastToChannel(channel: string, data: any) {
  const subscribers = channels.get(channel);
  if (!subscribers) return;
  
  subscribers.forEach(userId => sendToUser(userId, data));
}
```

---

## Scaling with Redis Pub/Sub

### Multi-Server Architecture

```typescript
import Redis from 'ioredis';

const pub = new Redis();
const sub = new Redis();

// Subscribe to Redis channel
sub.subscribe('ws-messages');

sub.on('message', (channel, message) => {
  const data = JSON.parse(message);
  
  // Broadcast to local clients only
  if (data.channel) {
    const subscribers = channels.get(data.channel);
    subscribers?.forEach(userId => {
      if (clients.has(userId)) {
        sendToUser(userId, data);
      }
    });
  }
});

// Publish message (goes to all servers)
function publishMessage(channel: string, data: any) {
  pub.publish('ws-messages', JSON.stringify({ channel, ...data }));
}
```

---

## Authentication

### Token-Based Auth

```typescript
// Client: Pass token in query string or subprotocol
const ws = new WebSocket(`wss://api.example.com/ws?token=${token}`);

// Server: Validate on connection
wss.on('connection', async (ws, req) => {
  const url = new URL(req.url!, `http://${req.headers.host}`);
  const token = url.searchParams.get('token');
  
  try {
    const user = await validateToken(token);
    ws.userId = user.id;
  } catch {
    ws.close(4001, 'Unauthorized');
    return;
  }
  
  // ... rest of connection handling
});
```

---

## Common Gotchas

### Connection Limits
Browsers limit connections per domain (~6). Use a single WebSocket and multiplex channels.

### Memory Leaks
Always clean up subscriptions on disconnect:

```typescript
ws.on('close', () => {
  clients.delete(userId);
  // Remove from all channels
  channels.forEach((subscribers, channel) => {
    subscribers.delete(userId);
  });
});
```

### Reconnection Storms
Use exponential backoff with jitter to prevent all clients reconnecting simultaneously.

### Stale Connections
Implement heartbeats. Connections can die silently (especially on mobile).

### Message Ordering
WebSocket guarantees order per connection, but across pub/sub you may need sequence numbers.

---

## Quick Reference

| Task | Pattern |
|------|---------|
| Reconnection | Exponential backoff with max attempts |
| Heartbeat | Ping/pong every 30s, terminate if no response |
| Authentication | Token in query string or first message |
| Channel broadcast | Map of channel → subscriber IDs |
| Multi-server | Redis pub/sub for message distribution |
| Cleanup | Remove from all channels on disconnect |

## References

- [MDN WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)
- [ws npm package](https://github.com/websockets/ws)
- [Socket.IO](https://socket.io/) (Higher-level abstraction)

