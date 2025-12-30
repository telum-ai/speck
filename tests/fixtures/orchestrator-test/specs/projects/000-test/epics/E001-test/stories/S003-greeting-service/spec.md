---
depends_on: []
---

# S003: Implement Greeting Service

## User Story

As a developer, I want a greeting service that generates personalized messages so that the API can return customized greetings.

## Requirements

### Functional Requirements

- FR-001: Service SHALL accept a name parameter
- FR-002: Service SHALL return greeting in format "Hello, {name}!"
- FR-003: Service SHALL handle empty names by returning "Hello, stranger!"

### Non-Functional Requirements

- NFR-001: Service response time SHALL be < 5ms
- NFR-002: Service SHALL be stateless

## Acceptance Criteria

#### Scenario: Greet with valid name
- **GIVEN** the greeting service is initialized
- **WHEN** I call greet with name "Alice"
- **THEN** the response is "Hello, Alice!"

```gherkin
Scenario: Greet with valid name
  Given the greeting service is initialized
  When I call greet with name "Alice"
  Then the response should be "Hello, Alice!"

Scenario: Greet with empty name
  Given the greeting service is initialized
  When I call greet with an empty name
  Then the response should be "Hello, stranger!"

Scenario: Greet with whitespace-only name
  Given the greeting service is initialized
  When I call greet with name "   "
  Then the response should be "Hello, stranger!"
```

## Technical Approach

Create a pure function `greet(name: string): string` with no side effects.

## Testing Strategy

- Unit tests for all scenarios
- Edge cases: null, undefined, special characters
