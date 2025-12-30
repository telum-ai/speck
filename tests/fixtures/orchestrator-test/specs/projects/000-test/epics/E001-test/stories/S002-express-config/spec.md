---
depends_on: []
---

# S002: Configure Express Server

## User Story

As a developer, I want to configure an Express.js server so that I can handle HTTP requests.

## Requirements

### Functional Requirements

- FR-001: Server SHALL listen on configurable port (default: 3000)
- FR-002: Server SHALL respond to health check at GET /health
- FR-003: Server SHALL use JSON middleware for request/response parsing

### Non-Functional Requirements

- NFR-001: Server startup time SHALL be < 2 seconds
- NFR-002: Health check response time SHALL be < 50ms

## Technical Notes

Use Express.js 4.x with TypeScript configuration from S001.

## Out of Scope

- HTTPS configuration
- Rate limiting
- Authentication
