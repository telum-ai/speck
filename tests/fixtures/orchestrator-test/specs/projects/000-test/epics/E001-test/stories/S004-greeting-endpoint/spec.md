---
depends_on: [S001, S002, S003]
---

# S004: Create /greet Endpoint

## User Story

As an API consumer, I want to call GET /greet with a name parameter so that I receive a personalized greeting.

## Requirements

### Functional Requirements

- FR-001: Endpoint SHALL be available at GET /greet
- FR-002: Endpoint SHALL accept `name` as a query parameter
- FR-003: Endpoint SHALL return JSON response with `message` field
- FR-004: Endpoint SHALL use the greeting service for message generation

### Non-Functional Requirements

- NFR-001: Response time SHALL be < 100ms
- NFR-002: Endpoint SHALL return appropriate HTTP status codes

## Acceptance Criteria

#### Scenario: Successful greeting
- **GIVEN** the API is running
- **WHEN** I GET `/greet?name=World`
- **THEN** the status code is 200 and the response contains `{"message": "Hello, World!"}`

```gherkin
Scenario: Successful greeting
  Given the API is running
  When I GET /greet?name=World
  Then the status code should be 200
  And the response body should be {"message": "Hello, World!"}

Scenario: Missing name parameter
  Given the API is running
  When I GET /greet without a name parameter
  Then the status code should be 200
  And the response body should be {"message": "Hello, stranger!"}
```

## Dependencies

- S001-project-setup: TypeScript configuration
- S002-express-config: Express server
- S003-greeting-service: Greeting logic
