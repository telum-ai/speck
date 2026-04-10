# Epic Technical Specification: [Epic Name]

**Epic ID**: E###  
**Project**: [Project Name]  
**Created**: [Date]  
**Status**: Draft  
**Input**: `epic.md` (+ optional: `epic-architecture.md`, `user-journey.md`, `wireframes.md`, scans, research reports)

---

## UX Design Context

*Fill this section only if `user-journey.md` and/or `wireframes.md` exist for this epic.
If neither exists for a UI epic, note "No UX artifacts — consider running /epic-journey and /epic-wireframes."*

### Journey Stage → Story Mapping

| Journey Stage | User Goal | Pain Point Addressed | Stories |
|--------------|-----------|----------------------|---------|
| [Stage name from user-journey.md] | [What user is trying to do] | [Pain point this epic resolves] | S001, S002 |

### Screen Inventory (from wireframes.md)

| Screen | Journey Stage | Responsive? | Implementing Story |
|--------|--------------|-------------|-------------------|
| [Screen name] | [Stage] | Y/N | S00X |

### UX Quality Requirements

Derived from emotional targets and pain points in `user-journey.md`:

- **[Stage]**: [Emotional target] → Implementation requirement (e.g., "Reduce anxiety at checkout → inline validation, no page reload on error")
- **Accessibility**: [Standards from ux-strategy.md]
- **Performance perception**: [Any latency/feedback requirements driven by UX expectations]

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

## Review Gauntlet

### 1. User Value / Scope Review

- **Epic promise**: [What user-visible value this epic must deliver]
- **Minimum lovable scope**: [What belongs in this epic vs what should wait]
- **Scope expansions considered**: [Ideas surfaced during planning]
- **Decision**: [Accepted / Deferred / Rejected with rationale]

### 2. UX / Journey Review

- **Critical user flow**: [What journey this epic owns]
- **High-risk interaction states**: [Empty/loading/error/edge states that must be designed intentionally]
- **Decision**: [What UX assumptions are locked before story breakdown]

### 3. Engineering / Reliability Review

- **Architectural pressure points**: [Boundaries, dependencies, failure modes]
- **Operational risk**: [Data, jobs, migrations, auth, performance, rollback]
- **Decision**: [What technical constraints or bets drive the approach]

## Deferred Scope Register

| Idea | Why it came up | Why it is deferred from this epic | Revisit trigger |
|------|----------------|-----------------------------------|-----------------|
| [Feature / expansion] | [Reason] | [Why not now] | [Condition] |

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

## Review Readiness Dashboard

| Review Lane | Status | Evidence / Artifact | Blocking? |
|-------------|--------|---------------------|-----------|
| User Value / Scope | [CLEAR / NEEDS WORK / N/A] | [Section, decision, or artifact] | [Yes/No] |
| UX / Journey | [CLEAR / NEEDS WORK / N/A] | [Section, journey, or artifact] | [Yes/No] |
| Engineering / Reliability | [CLEAR / NEEDS WORK / N/A] | [Section, architecture note, or artifact] | [Yes/No] |

**Verdict**: [READY FOR STORY BREAKDOWN / HOLD]

**Why**: [One paragraph on whether the epic is ready to break into stories]

## Open Questions / Risks

- [Open question]
- [Risk + mitigation plan]


