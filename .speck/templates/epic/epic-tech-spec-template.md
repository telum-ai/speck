# Epic Technical Specification: [Epic Name]

**Epic ID**: E###  
**Project**: [Project Name]  
**Created**: [Date]  
**Status**: Draft  
**Input**: `epic.md` (+ optional: `epic-architecture.md`, scans, research reports)

---

## Research Informing This Specification

### Web Search Findings
- **[Topic]**: [Finding] (Source: [URL], Date: [YYYY-MM-DD])

### Deep Research Reports (if any)
- **[Report]**: [Key takeaways and what changed because of them]

### Decisions Trace
- **Decision**: [What]
  - **Why**: [Rationale]
  - **Alternatives**: [What was rejected and why]

---

## Technical Approach

Describe the end-to-end implementation approach for this epic:
- Key components/services/modules involved
- How data flows through the system
- Where responsibilities live (boundaries)
- Key trade-offs and risks

---

## Technology Stack

- **Frontend**: [Frameworks/libraries]  
- **Backend**: [Frameworks/libraries]  
- **Database**: [Type + migration approach]  
- **Infra/Deployment**: [Hosting, CI/CD assumptions]  
- **Observability**: [Logging/metrics/tracing]  

---

## Data Model

### Entities
- **[Entity]**: [Purpose, key fields, constraints]

### Relationships
- [Entity A] → [Entity B]: [Relationship]

### Migration Strategy
- [If schema changes exist: how migrations are created and rolled out safely]

---

## API / Contracts

### Endpoints / Interfaces
- **[Operation]** `[path or interface]`: [Purpose]
  - Request: [shape]
  - Response: [shape]
  - Errors: [expected error cases]

### Contract Source of Truth
- Reference `contracts/` files created at story level (preferred), or define epic-level contract conventions here.

---

## Security

- **AuthN**: [Mechanism; how sessions/tokens are handled]
- **AuthZ**: [RBAC/ABAC rules; where enforced]
- **PII**: [What data is sensitive and how it is protected]
- **Threats**: [Top risks and mitigations]

---

## Performance & Scalability

- **Targets**: [p95 latency, throughput, etc.]
- **Bottlenecks**: [Expected hotspots]
- **Mitigations**: [Caching, indexing, batching, async, etc.]
- **Validation**: [Performance tests / load tests plan]

---

## Testing Strategy

- **Unit**: [Key units to test]
- **Contract**: [Contracts to validate]
- **Integration**: [Cross-service flows]
- **E2E (optional)**: [User journey coverage]
- **Quality Gates**: [What must pass before /epic-breakdown and implementation]

---

## Stories & Breakdown Guidance

This section guides `/epic-breakdown`:
- Key story boundaries (what should be its own story vs shared foundation)
- Dependencies between stories
- Parallelizable work (different files/modules)

**Story List (High Level)**:
1. [Story name] — [Goal]
2. [Story name] — [Goal]

---

## Open Questions / Risks

- [Open question]
- [Risk + mitigation plan]


