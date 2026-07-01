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

### E000: Developer Infrastructure (RECOMMENDED FIRST)

**Value Statement**: This epic establishes the technical foundation that enables all future development to be reliable, maintainable, and deployable.

**Scope Summary**: 
Set up testing framework, CI/CD pipeline, linting/formatting, error tracking, and environment configuration. This is infrastructure that every production project needs - do it once, benefit forever.

**Success Criteria**:
- [ ] Tests can be written and run locally with a single command
- [ ] CI pipeline runs on every PR (lint, test, build)
- [ ] Error tracking captures production issues with context
- [ ] Deployment to staging/production is automated

**User Stories Summary**:
- Testing framework configuration (unit, integration patterns)
- CI/CD pipeline setup (lint, test, build, deploy stages)
- Linting and formatting configuration (auto-fix on save)
- Error tracking integration (Sentry or equivalent)
- Environment configuration (.env patterns, secrets management)
- Pre-commit hooks (optional but recommended)

**Dependencies**:
- **Depends On**: None (truly foundational - do first!)
- **Enables**: All other epics (E001+)

**Estimated Stories**: [3-6]
**Priority**: P0 - Foundation (before any feature work)
**Target Phase**: Phase 0 (before Phase 1)

**⚠️ Skip Criteria**: Only skip if ALL of these are true:
- [ ] Existing project with testing already configured
- [ ] CI/CD pipeline already running
- [ ] Error tracking already integrated
- [ ] This is a throwaway prototype (not production-bound)

---

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
- **Depends On**: E000 (infrastructure foundation)
- **Enables**: E003, E004

**Touch-points (creates/modifies)**:
- Migrations: [e.g., create table auto_reply_config]
- Models/Services: [e.g., models/availability.py, match_service.py]
- Files/Components: [e.g., src/components/AvailabilityCard.tsx]

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

**Touch-points (creates/modifies)**:
- Migrations: [e.g., create table crew_members]
- Models/Services: [e.g., models/crew.py, crew_service.py]
- Files/Components: [e.g., src/components/CrewCard.tsx]

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

### Phase 0: Developer Infrastructure (Week 1)
**Goal**: Establish technical foundation for reliable development

**Epics**:
- E000: Developer Infrastructure (Required before feature work)

**Success Gate**: CI pipeline runs, tests work, errors are tracked

**Skip Criteria**: Only skip if this is brownfield with existing infrastructure

---

### Phase 1: Foundation (Weeks 2-5)
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

## Epic Concurrency Waves & Rebase Cadence

<!--
REQUIRED for Platform / 4+ epic Build projects.
Assign every epic to exactly one wave. Only epics in the CURRENT wave may run in parallel.
Integrator epics (2+ upstream dependencies) belong in a later wave — never start them until upstreams merge to main.
-->

| Wave | Epics | May run in parallel? | Starts when | Daily rebase cadence |
|------|-------|----------------------|-------------|----------------------|
| 0 | E000 | No (foundation) | Project start | N/A — merge before Wave 1 |
| 1 | E001, E002, E006 | Yes | E000 merged to `main` | `git fetch && git rebase origin/main` on each `epic/eNNN` branch |
| 2 | E003, E005 | Yes | All Wave 1 epics merged | Same daily rebase |
| 3 | E004, E007 | No (integrators) | Wave 2 merged | Rebase before each story batch |

**Worktree setup** (per parallel epic):
```bash
# Push the planning corpus FIRST — worktrees branch from origin/main, not local HEAD.
git push origin main
git fetch origin
git worktree add ../<repo>-eNNN -b epic/eNNN origin/main
# ...after the epic merges:
git worktree remove --force ../<repo>-eNNN
```

**Rules**:
- **Push before spawn**: `git push origin main` the full planning corpus (specs, tech-spec, wireframes, DECs) before any worktree wave and after every merge — unpushed commits are invisible to worktrees, so the first wave builds blind to locked specs.
- Branch parallel epics from **current** `main`, not a stale pre-foundation base
- **Disk hygiene**: `git worktree remove --force` after each merge — many parallel worktrees (each ~1 GB+ after install/build) can exhaust host disk and freeze every session. Cap live worktrees to the current wave.
- DEC bands: `E002` → `DEC-0201+` (see AGENTS.md)
- `project-state.md` regeneration deferred to merge-to-`main` on epic branches
- Shared DB tables frozen during parallel waves — new tables/migrations only per epic; **real wall-clock** 14-digit UTC timestamps (`date -u +%Y%m%d%H%M%S`), never rounded placeholders (parallel epics collide on identical round numbers)

---

## Notes

- Epic boundaries may be adjusted based on implementation discoveries
- Story counts are estimates and will be refined during epic planning
- Dependencies shown are technical; business priorities may override
- Each epic will have its own detailed specification and technical design
