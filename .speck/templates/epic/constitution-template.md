# Epic Constitution: [Epic Name]

**Epic**: [EPIC_ID]  
**Project**: [PROJECT_ID]  
**Inherits From**: [Project Name] Constitution v[X.Y]  
**Version**: 1.0  
**Last Updated**: [DATE]  
**Status**: [Draft/Active/Deprecated]

---

## 📋 Inheritance Declaration

This epic constitution extends and specializes the project constitution. All project-level principles apply unless explicitly refined here for epic-specific needs.

**Project Principles** (inherited):
1. [Project principle 1 - copy from project constitution]
2. [Project principle 2]
3. [Project principle 3]
[List all project principles for reference]

---

## 🎯 Epic-Specific Principles

### Principle: [Domain-Specific Rule Name]

**Statement**: [Clear, actionable principle specific to this epic's domain]

**Rationale**: [Why this principle is necessary for this epic, how it extends project principles]

**Implementation Guidelines**:
- [Specific coding pattern or rule]
- [Architectural guideline]
- [Process requirement]

**Examples**:
- ✅ Good: [Concrete example of following the principle]
- ❌ Bad: [Counter-example showing violation]

**Validation**:
- Automated: [Tool or check that verifies compliance]
- Manual: [Review checklist item]

---

### Principle: [Performance/Scalability Standard]

**Statement**: [Epic-specific performance requirement that may exceed project baselines]

**Rationale**: [Why this epic needs special performance considerations]

**Metrics**:
| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| [Response time] | [< Xms] | [How measured] |
| [Throughput] | [> Y req/s] | [Tool/approach] |
| [Resource usage] | [< Z] | [Monitoring] |

**Implementation**:
- [Caching strategy]
- [Optimization requirement]
- [Architecture pattern]

**Monitoring**:
- [What to track]
- [Alert thresholds]
- [Review frequency]

---

### Principle: [Security/Privacy Boundary]

**Statement**: [Epic-specific security rule based on domain requirements]

**Rationale**: [Threat model or compliance requirement unique to this domain]

**Requirements**:
- [Authentication pattern]
- [Authorization rules]
- [Data handling constraints]
- [Audit requirements]

**Controls**:
- Preventive: [Security measures]
- Detective: [Monitoring/logging]
- Corrective: [Incident response]

**Compliance Mapping**:
- [Regulation/Standard]: [How this principle ensures compliance]

---

## 🔒 Epic Boundaries

### Interface Contracts

**APIs This Epic Provides**:
| API | Version | Stability | SLA | Documentation |
|-----|---------|-----------|-----|---------------|
| [API name] | v[X.Y] | [Stable/Beta/Experimental] | [Uptime/Response] | [Link] |

**Contract Commitments**:
- Versioning: [Strategy - semantic/date/custom]
- Breaking changes: [Notice period and process]
- Deprecation: [Timeline and migration support]

**APIs This Epic Consumes**:
| From Epic/Service | API | Version Required | Fallback Strategy |
|-------------------|-----|------------------|-------------------|
| [Source] | [API] | [Version constraint] | [What happens if unavailable] |

---

### Data Ownership

**This Epic Owns** (full CRUD responsibility):
| Entity | Privacy Level | Retention | Backup Requirements |
|--------|---------------|-----------|---------------------|
| [Entity name] | [Public/Internal/Confidential/Secret] | [Period] | [RTO/RPO] |

**This Epic Shares** (read and/or conditional write):
| Entity | Owner Epic | Access Type | Conditions |
|--------|------------|-------------|------------|
| [Entity] | [Epic] | [Read-only/Read-write] | [When/how accessed] |

**Forbidden Access**:
- ❌ Direct database access to [Other epic's tables]
- ❌ Bypassing [Service name] API
- ❌ Accessing [System] without [Protocol]

---

### Dependency Constraints

**Allowed Dependencies**:
- ✅ Project shared libraries: [List]
- ✅ Epic-specific approved: [List with versions]
- ✅ Standard frameworks: [As defined in project]

**Forbidden Dependencies**:
- ❌ [Library/framework]: [Reason - deprecated/insecure/incompatible]
- ❌ Direct UI framework use: [Must use design system]
- ❌ [Other epic] internals: [Must use public API]

**Dependency Update Policy**:
- Review frequency: [Monthly/quarterly]
- Approval required for: [New dependencies/major updates]
- Security updates: [Auto-update timeline]

---

## 🛠️ Technical Standards

### Code Organization

**Epic Structure**:
```
epics/[epic-name]/
├── api/          # Public interfaces
├── domain/       # Business logic
├── services/     # Internal services
├── models/       # Data models
└── tests/        # All test types
```

**Naming Conventions**:
- Domain entities: [Pattern with examples]
- Services: [Pattern with examples]
- API endpoints: [Pattern with examples]

### Testing Requirements

Beyond project standards:

| Test Type | Project Minimum | Epic Requirement | Rationale |
|-----------|----------------|------------------|-----------|
| Unit | 80% | 90% | [Critical domain logic] |
| Integration | 70% | 85% | [External dependencies] |
| Performance | Optional | Required | [SLA commitments] |
| Security | Basic | Advanced | [Threat model] |

**Epic-Specific Test Scenarios**:
- [Domain-specific test case]
- [Edge case unique to epic]
- [Performance scenario]

### Documentation Standards

**Required Documentation**:
- [ ] API reference (OpenAPI/GraphQL schema)
- [ ] Domain glossary
- [ ] Architecture decision records (ADRs)
- [ ] Runbook for operations
- [ ] Integration guide for consumers

**Documentation Review**:
- Frequency: [With each story/sprint/release]
- Reviewers: [Roles responsible]

---

## 📈 Metrics & Monitoring

### Epic Health Metrics

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Code coverage | >90% | [X]% | [↑→↓] |
| API reliability | >99.9% | [X]% | [↑→↓] |
| Performance SLA | 100% | [X]% | [↑→↓] |
| Security incidents | 0 | [X] | [↑→↓] |

### Compliance Tracking

- Constitution adherence: [Tool/process]
- Automated checks run: [When]
- Manual reviews: [Frequency]
- Violations in period: [Count]

---

## 🔄 Evolution & Governance

### Amendment Process

1. **Proposal**: Document need with rationale
2. **Impact Analysis**: Assess effect on stories and dependent epics
3. **Compatibility Check**: Ensure project constitution alignment
4. **Review**: Epic team and architect approval
5. **Communication**: Notify all stakeholders
6. **Version**: Increment with changelog

### Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | [Date] | [Name] | Initial constitution |
| [Future] | | | |

### Compliance Verification

**Automated Checks**:
- [ ] Dependency scanner
- [ ] API contract tests  
- [ ] Performance benchmarks
- [ ] Security scans

**Manual Reviews**:
- [ ] Architecture review checklist
- [ ] Code review constitution points
- [ ] Documentation completeness

### Escalation Path

1. **Epic-level issues**: Epic tech lead
2. **Cross-epic conflicts**: Project architect  
3. **Constitution violations**: Project governance board
4. **Unresolved disputes**: Project sponsor

---

## 📎 Appendices

### A. Domain Glossary

| Term | Definition | Context |
|------|------------|---------|
| [Domain term] | [Clear definition] | [When used] |

### B. Reference Implementations

**Following Constitution**:
```[language]
// Example showing proper implementation
[Code example]
```

**Anti-Pattern Examples**:
```[language]
// What NOT to do
[Code example]
// Why this violates: [Principle]
```

### C. Decision Records

| Decision | Date | Rationale | Link to ADR |
|----------|------|-----------|-------------|
| [Major decision] | [Date] | [Brief why] | [ADR-XXX] |

---

## ✅ Constitution Checklist

**For Story Implementation**:
- [ ] Follows all project principles
- [ ] Adheres to epic-specific principles
- [ ] Respects boundary constraints
- [ ] Meets performance standards
- [ ] Includes required documentation
- [ ] Has appropriate test coverage

**For Code Reviews**:
- [ ] Check against constitution principles
- [ ] Verify API contract compliance
- [ ] Validate data access patterns
- [ ] Confirm dependency constraints
- [ ] Ensure documentation updated

**For Epic Planning**:
- [ ] New features align with constitution
- [ ] Technical debt addressed
- [ ] Boundaries remain clear
- [ ] Metrics tracked

---

**Approval Signatures**:
- Epic Lead: _________________ Date: _______
- Project Architect: __________ Date: _______
- Product Owner: ______________ Date: _______
