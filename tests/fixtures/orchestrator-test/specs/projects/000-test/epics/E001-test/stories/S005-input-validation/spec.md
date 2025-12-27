# S005: Add Request Validation

## User Story

As an API consumer, I want the API to validate my input so that I receive helpful error messages for invalid requests.

## Requirements

### Functional Requirements

- FR-001: API SHALL validate that name parameter is a string
- FR-002: API SHALL reject names longer than 100 characters
- FR-003: API SHALL sanitize input to prevent injection attacks

### Non-Functional Requirements

- NFR-001: Validation SHALL complete in < 10ms
- NFR-002: Error messages SHALL be user-friendly

## Acceptance Criteria

```gherkin
Scenario: Valid name
  Given the API is running
  When I GET /greet?name=Alice
  Then the status code should be 200

Scenario: Name too long
  Given the API is running
  When I GET /greet?name={101 character string}
  Then the status code should be 400
  And the response should contain an error message

Scenario: Special characters sanitized
  Given the API is running
  When I GET /greet?name=<script>alert('xss')</script>
  Then the response should not contain raw HTML tags
```

## Dependencies

- S004-greeting-endpoint: Endpoint to validate
