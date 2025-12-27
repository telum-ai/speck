# Architecture: Greeting API

## System Overview

A simple REST API with a single endpoint.

```
┌─────────────┐     ┌─────────────────┐
│   Client    │────▶│  Express API    │
└─────────────┘     └─────────────────┘
                           │
                    ┌──────▼──────┐
                    │  Greeting   │
                    │  Service    │
                    └─────────────┘
```

## Technology Stack

| Layer | Technology |
|-------|------------|
| Runtime | Node.js 20 |
| Framework | Express.js |
| Language | TypeScript |
| Testing | Vitest |

## API Design

### GET /greet

**Query Parameters:**
- `name` (string, required): Name to greet

**Response:**
```json
{
  "message": "Hello, {name}!"
}
```

## Directory Structure

```
src/
├── index.ts          # Entry point
├── routes/
│   └── greet.ts      # Greeting endpoint
└── services/
    └── greeting.ts   # Greeting logic
```
