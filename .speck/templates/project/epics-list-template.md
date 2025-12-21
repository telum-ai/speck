# Epic Breakdown: [Project Name]

**Project**: [Project Name]  
**Date**: [Date]  
**Total Epics**: [Count]  
**Estimated Total Stories**: [Range]

---

## Epic Dependency Map

```
[Visual representation of epic dependencies]

E001 ──────┐
           ├──→ E003 ──→ E005
E002 ──────┘              │
                          │
E004 ────────────────────┘
```

## Epic Prioritization

### MVP Epics (Must Have)
[Epics that must be completed for initial release]

### Enhancement Epics (Should Have)
[Epics that significantly improve the product but aren't critical]

### Future Epics (Nice to Have)
[Epics for post-MVP consideration]

---

## Epic Definitions

### E001: [Epic Name]

**Value Statement**: This epic enables [users] to [capability] resulting in [benefit]

**Scope Summary**: 
[2-3 sentences describing what this epic includes]

**Success Criteria**:
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] [Measurable outcome 3]

**User Stories Summary**:
- Authentication and account creation
- Profile management
- Preference settings
[High-level story groups, not detailed list]

**Dependencies**:
- **Depends On**: None (foundational)
- **Enables**: E003, E004

**Estimated Stories**: [8-12]
**Priority**: P0 - MVP Critical
**Target Phase**: Phase 1

---

### E002: [Epic Name]

**Value Statement**: This epic enables [users] to [capability] resulting in [benefit]

**Scope Summary**: 
[2-3 sentences describing what this epic includes]

**Success Criteria**:
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] [Measurable outcome 3]

**User Stories Summary**:
- [Story group 1]
- [Story group 2]
- [Story group 3]

**Dependencies**:
- **Depends On**: None (can run parallel to E001)
- **Enables**: E003

**Estimated Stories**: [6-10]
**Priority**: P0 - MVP Critical  
**Target Phase**: Phase 1

---

### E003: [Epic Name]

**Value Statement**: This epic enables [users] to [capability] resulting in [benefit]

**Scope Summary**: 
[2-3 sentences describing what this epic includes]

**Success Criteria**:
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] [Measurable outcome 3]

**User Stories Summary**:
- [Story group 1]
- [Story group 2]
- [Story group 3]

**Dependencies**:
- **Depends On**: E001, E002 (needs auth and data)
- **Enables**: E005

**Estimated Stories**: [10-15]
**Priority**: P0 - MVP Critical
**Target Phase**: Phase 2

---

### E004: [Epic Name]

**Value Statement**: This epic enables [users] to [capability] resulting in [benefit]

**Scope Summary**: 
[2-3 sentences describing what this epic includes]

**Success Criteria**:
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] [Measurable outcome 3]

**User Stories Summary**:
- [Story group 1]
- [Story group 2]
- [Story group 3]

**Dependencies**:
- **Depends On**: E001 (needs user context)
- **Enables**: E005

**Estimated Stories**: [5-8]
**Priority**: P1 - Important but not critical
**Target Phase**: Phase 2 (parallel with E003)

---

### E005: [Epic Name]

**Value Statement**: This epic enables [users] to [capability] resulting in [benefit]

**Scope Summary**: 
[2-3 sentences describing what this epic includes]

**Success Criteria**:
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] [Measurable outcome 3]

**User Stories Summary**:
- [Story group 1]
- [Story group 2]
- [Story group 3]

**Dependencies**:
- **Depends On**: E003, E004 (integration epic)
- **Enables**: Future enhancements

**Estimated Stories**: [8-12]
**Priority**: P1 - Post-MVP Enhancement
**Target Phase**: Phase 3

---

## Epic Execution Strategy

### Phase 1: Foundation (Weeks 1-4)
**Goal**: Establish core infrastructure and user management

**Epics**:
- E001: [Epic name] (Sequential)
- E002: [Epic name] (Parallel with E001)

**Success Gate**: Users can register, login, and access basic features

### Phase 2: Core Features (Weeks 5-8)
**Goal**: Deliver primary user value

**Epics**:
- E003: [Epic name] (Depends on Phase 1)
- E004: [Epic name] (Parallel with E003)

**Success Gate**: Users can perform all core workflows

### Phase 3: Integration & Polish (Weeks 9-12)
**Goal**: Create seamless, polished experience

**Epics**:
- E005: [Epic name] (Depends on Phase 2)

**Success Gate**: All features integrated, performance optimized

---

## Risk Mitigation by Epic

| Epic | Primary Risk | Mitigation Strategy |
|------|--------------|-------------------|
| E001 | [Risk] | [How to handle] |
| E002 | [Risk] | [How to handle] |
| E003 | [Risk] | [How to handle] |
| E004 | [Risk] | [How to handle] |
| E005 | [Risk] | [How to handle] |

---

## Success Metrics by Epic

| Epic | Key Metric | Target | Measurement |
|------|-----------|--------|-------------|
| E001 | User registration rate | X% | Analytics |
| E002 | [Metric] | [Target] | [Method] |
| E003 | [Metric] | [Target] | [Method] |
| E004 | [Metric] | [Target] | [Method] |
| E005 | [Metric] | [Target] | [Method] |

---

## Notes

- Epic boundaries may be adjusted based on implementation discoveries
- Story counts are estimates and will be refined during epic planning
- Dependencies shown are technical; business priorities may override
- Each epic will have its own detailed specification and technical design
