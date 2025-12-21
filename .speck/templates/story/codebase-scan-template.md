# Codebase Scan Report

**Scan Date**: [YYYY-MM-DD]  
**Feature**: [feature-name]  
**Scope**: [Full / Domain: {domain}]

## Executive Summary

- **Project Type**: [Single / Web / Mobile / Monorepo]
- **Primary Languages**: [languages and versions]
- **Key Findings**: [3-5 bullet points]

---

## Project Structure Overview

### Directory Organization

```
[ROOT]/
├── [primary source directory]/
│   ├── [subdirectory 1]/        # [Purpose description]
│   ├── [subdirectory 2]/        # [Purpose description]
│   └── [subdirectory 3]/        # [Purpose description]
├── tests/
│   ├── [test type 1]/           # [Test category description]
│   └── [test type 2]/           # [Test category description]
└── [config/docs/other]/
```

**Observations**:
- [How modules are organized]
- [Separation of concerns approach]
- [Test organization strategy]
- [Configuration management]

### Module Boundaries

- **[Module/Layer 1]**: [Files/directories, purpose, dependencies]
- **[Module/Layer 2]**: [Files/directories, purpose, dependencies]
- **[Module/Layer 3]**: [Files/directories, purpose, dependencies]

---

## Technology Stack Inventory

### Backend Stack (if applicable)

- **Language & Version**: [e.g., Python 3.13]
- **Web Framework**: [e.g., FastAPI 0.104, Django 4.2]
- **Database**: [e.g., PostgreSQL 15, MongoDB 7]
- **ORM/Database Toolkit**: [e.g., SQLAlchemy 2.0, Prisma 5]
- **Authentication**: [e.g., JWT, OAuth 2.0, Stytch SDK]
- **Background Jobs**: [e.g., Celery, RQ, APScheduler or N/A]
- **Caching**: [e.g., Redis, Memcached or N/A]
- **Testing**: [e.g., pytest, unittest, Jest]
- **Linting & Formatting**: [e.g., black, flake8, mypy]

### Frontend Stack (if applicable)

- **Language & Version**: [e.g., TypeScript 5.2, JavaScript ES2022]
- **Framework**: [e.g., React 18.2, Vue 3, Svelte]
- **Meta-framework**: [e.g., Next.js 14, Nuxt 3, SvelteKit or N/A]
- **State Management**: [e.g., React Query, Zustand, Redux or N/A]
- **UI Library**: [e.g., Tailwind CSS, Material-UI, Chakra UI]
- **Routing**: [e.g., Next.js routing, React Router, Vue Router]
- **Build Tool**: [e.g., Vite, webpack, Turbopack]
- **Testing**: [e.g., Vitest, Jest, Playwright]

### Infrastructure & Tooling

- **Containerization**: [e.g., Docker, Podman or N/A]
- **Orchestration**: [e.g., docker-compose, Kubernetes or N/A]
- **CI/CD**: [e.g., GitHub Actions, GitLab CI, CircleCI]
- **Package Management**: [e.g., pip, npm, pnpm, yarn, Poetry]
- **Version Control**: [e.g., Git with GitHub/GitLab]
- **Pre-commit Hooks**: [e.g., pre-commit framework, husky]

---

## Identified Patterns

### Authentication & Authorization (if relevant)

**Pattern Type**: [JWT tokens / Session-based / OAuth 2.0 / SSO]

**Implementation Location**:
- Middleware: `[path/to/middleware]`
- Auth service: `[path/to/service]`
- Models: `[path/to/user/model]`

**Key Pattern Example**:
```[language]
[CODE EXAMPLE - Max 20 lines showing auth pattern]
```

**Observations**:
- [How tokens are managed]
- [Protected route/endpoint pattern]
- [User session handling approach]

---

### API Design & Endpoint Patterns (if relevant)

**API Style**: [REST / GraphQL / gRPC / Mixed]

**Versioning**: [e.g., /api/v1/, /v2/api/, query param, header-based]

**Request/Response Pattern**:
```[language]
[CODE EXAMPLE - Max 20 lines showing typical endpoint structure]
```

**Observations**:
- Request validation approach: [Pydantic / Zod / JSON Schema / Framework built-in]
- Response format: [Consistent schema, error handling]
- Pagination pattern: [offset/limit, cursor-based, page-based or N/A]
- Filtering/sorting: [Query params, request body, standardized approach or N/A]

---

### Data Models & Entities (if relevant)

**ORM/Data Layer**: [SQLAlchemy / Prisma / Mongoose / ActiveRecord]

**Model Location**: `[path/to/models/]`

**Relationship Patterns**:
```[language]
[CODE EXAMPLE - Max 20 lines showing model definition with relationships]
```

**Observations**:
- Field naming convention: [snake_case / camelCase]
- Relationship definitions: [Explicit foreign keys, lazy loading, etc.]
- Validation patterns: [ORM validators / Pydantic / Custom validators]
- Migration approach: [Alembic / Prisma Migrate / Django migrations]

---

### Error Handling Patterns

**Exception Strategy**: [Custom exceptions / Framework exceptions / Standard library]

**Error Response Format**:
```[language]
[CODE EXAMPLE - Max 15 lines showing error handling]
```

**Observations**:
- Centralized error handling: [Middleware / Decorator / Manual]
- Logging approach: [Structured logging, log levels, destinations]
- User-facing messages: [Exposed / Sanitized / Error codes]

---

### Testing Patterns

**Test Organization**:
- Unit tests: `[path/to/unit/tests/]`
- Integration tests: `[path/to/integration/tests/]`
- Contract tests: `[path/to/contract/tests/]` (if applicable)
- E2E tests: `[path/to/e2e/tests/]` (if applicable)

**Test Structure Example**:
```[language]
[CODE EXAMPLE - Max 20 lines showing typical test structure]
```

**Observations**:
- Fixture patterns: [pytest fixtures / Jest beforeEach / Factory pattern]
- Mocking strategy: [unittest.mock / Jest mocks / No mocks (integration style)]
- Assertion style: [assert / expect / should]
- Test database: [SQLite / Postgres testcontainer / Real DB]

---

### Logging & Observability (if present)

**Logging Framework**: [e.g., Python logging, Winston, Pino]

**Log Destinations**: [stdout / files / external service]

**Observability Example**:
```[language]
[CODE EXAMPLE - Max 15 lines showing logging pattern]
```

**Observations**:
- Structured logging: [Yes / No]
- Log levels used: [DEBUG, INFO, WARNING, ERROR]
- Contextual information: [Request IDs, user IDs, etc.]
- Monitoring tools: [Sentry, DataDog, CloudWatch or None detected]

---

## Conventions to Follow

### Naming Conventions

- **Files**: [snake_case / kebab-case / PascalCase]
  - Example: `[actual-file-name.ext]` from codebase
- **Functions/Methods**: [camelCase / snake_case]
  - Example: `[actual_function_name()]` from codebase
- **Classes**: [PascalCase / snake_case]
  - Example: `[ActualClassName]` from codebase
- **Constants**: [SCREAMING_SNAKE_CASE / UPPER_CASE]
  - Example: `[ACTUAL_CONSTANT_NAME]` from codebase
- **API Endpoints**: [/resource/action / /api/v1/resource]
  - Example: `[/api/v1/actual-endpoint]` from codebase

### Import Organization

**Backend** (if applicable):
```[language]
[ACTUAL EXAMPLE from codebase showing import ordering]
# Standard library
# Third-party
# Local imports
```

**Frontend** (if applicable):
```[language]
[ACTUAL EXAMPLE from codebase showing import ordering]
```

**Observations**:
- Import sorting: [Alphabetical / By type / Manual]
- Absolute vs relative imports: [Preference and when each is used]

### Code Style & Documentation

- **Docstrings/JSDoc**: [Google style / NumPy / JSDoc / Minimal / None]
- **Type Hints**: [Fully typed / Partial / None]
- **Comments**: [Explain why, not what / Minimal / Documentation-heavy]
- **Line Length**: [80 / 88 / 100 / 120 characters]
- **Formatting**: [Auto-formatted via [tool] / Manual / Mixed]

### Configuration Management

- **Environment Variables**: [.env file / OS env / Config service]
- **Config Location**: `[path/to/config]`
- **Secrets Handling**: [env vars / Secret manager / Vault / Config files]
- **Multi-environment**: [dev/staging/prod configs / Single unified config]

---

## Reference Implementations

### [Similar Feature Name 1]

**Relevance**: [Why this feature is similar to the planned feature]

**File Locations**:
- Backend: `[path/to/backend/files]`
- Frontend: `[path/to/frontend/files]`
- Tests: `[path/to/test/files]`

**Patterns Used**:
- [Pattern 1 observed in this feature]
- [Pattern 2 observed in this feature]
- [Pattern 3 observed in this feature]

**Key Code Reference** ([filename]):
```[language]
[CODE EXAMPLE - Max 20 lines showing relevant implementation]
```

**Lessons Learned**:
- ✅ What works well in this implementation
- ⚠️ What could be improved
- 📝 Notes for new feature implementation

---

### [Similar Feature Name 2]

**Relevance**: [Why this feature is similar to the planned feature]

**File Locations**:
- [List relevant file paths]

**Patterns Used**:
- [Patterns observed]

**Key Code Reference** ([filename]):
```[language]
[CODE EXAMPLE]
```

**Lessons Learned**:
- [Observations]

---

## Potential Conflicts & Risks

### Naming Collisions

[If any detected:]
- ⚠️ **Entity/Model**: Proposed "[name]" conflicts with existing `[path/to/existing/file]`
  - **Recommendation**: [Suggested alternative name]

- ⚠️ **API Route**: Proposed "[endpoint]" conflicts with existing route in `[path/to/file]`
  - **Recommendation**: [Suggested alternative endpoint or versioning approach]

- ⚠️ **File/Directory**: Proposed structure may overlap with `[existing/path]`
  - **Recommendation**: [Suggested alternative structure]

[If none detected:]
- ✅ No naming collisions detected with existing codebase.

### Architectural Concerns

[If any detected:]
- ⚠️ **Complexity Risk**: Adding this feature may violate [principle] from constitution
  - **Details**: [Explanation]
  - **Recommendation**: [How to mitigate]

- ⚠️ **Integration Challenge**: Feature requires integration with [system] which currently [issue]
  - **Details**: [Explanation]
  - **Recommendation**: [Suggested approach]

[If none detected:]
- ✅ No major architectural conflicts identified.

### Technical Debt Areas

[If any identified:]
- ⚠️ **Legacy Code**: `[path/to/legacy/code]` does not follow current patterns
  - **Recommendation**: Do NOT replicate these patterns. Follow patterns from [reference feature] instead.

- ⚠️ **Missing Tests**: [Component/Feature] lacks proper test coverage
  - **Recommendation**: New feature should include comprehensive tests (unlike this area).

[If none detected:]
- ✅ Codebase quality is consistent; no significant technical debt identified.

---

## Constitutional Compliance Analysis

*Cross-referenced with project constitution (if exists)*

### Aligned Practices

[List practices in codebase that follow project principles (from constitution.md if it exists):]
- ✅ **[Principle Name]**: [How existing code demonstrates this principle]
  - **Example**: `[path/to/file]` shows [specific pattern]

- ✅ **[Principle Name]**: [How existing code demonstrates this principle]
  - **Example**: [Specific observation]

### Constitutional Deviations (Technical Debt)

[List practices that violate constitution - to AVOID replicating:]
- ⚠️ **[Principle Violated]**: [Where and how]
  - **Location**: `[path/to/problematic/code]`
  - **Issue**: [Specific violation]
  - **Recommendation**: Do NOT replicate this pattern. Use [alternative] instead.

[If none found:]
- ✅ No constitutional violations detected in analyzed code.

### Recommendations for Constitutional Compliance

1. **[Recommendation 1]**: [Specific guidance for new feature]
2. **[Recommendation 2]**: [Specific guidance for new feature]
3. **[Recommendation 3]**: [Specific guidance for new feature]

---

## Recommendations for Planning

### Immediate Actions

1. **Follow [Pattern Name]**: Use the pattern from `[reference-file]` for [aspect of feature]
2. **Avoid [Anti-pattern]**: Do not replicate approach in `[problematic-file]`
3. **Check [Constraint]**: Ensure new feature respects [existing constraint/limitation]

### Technology Choices

Based on existing stack:
- **Recommended**: [Technology/library] (already in use, consistent with codebase)
- **Compatible**: [Technology/library] (not used yet, but compatible with stack)
- **Avoid**: [Technology/library] (conflicts with existing choices or principles)

### File Organization

Based on existing structure:
- **Backend files**: Place in `[suggested/path/]` following pattern of [reference feature]
- **Frontend files**: Place in `[suggested/path/]` following pattern of [reference feature]
- **Tests**: Organize as `[suggested/test/structure/]` matching existing convention

### Integration Points

- **Database**: [Guidance on models, migrations, relationships]
- **API**: [Guidance on endpoint design, versioning, schemas]
- **Authentication**: [Guidance on auth integration if applicable]
- **Frontend**: [Guidance on component structure, state management if applicable]

---

## Next Steps

1. **Review** this scan report thoroughly before running `/plan`
2. **Reference** the identified patterns during planning phase
3. **Run `/research`** if external best practices needed to supplement internal patterns
4. **Run `/plan`** - planning will automatically incorporate this scan
5. **Bookmark** reference implementations for consultation during implementation

---

*Generated by `/scan` on [YYYY-MM-DD]*
