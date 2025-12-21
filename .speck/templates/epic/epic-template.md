# Epic Specification: [Epic Name]

**Epic ID**: [ENNN]  
**Project**: [Project Name]  
**Created**: [Date]  
**Status**: Planning  
**Estimated Stories**: [X-Y]

---

## 📊 Information Sources

**Traceability**: This epic specification was created from the following sources:

- **Required Inputs**:
  - `PRD.md` → Project requirements and epic context
  - `project.md` → Project vision and goals
- **Recommended Inputs**:
  - `epics.md` → Epic relationships and dependencies
- **Brownfield** (if applicable):
  - `epic-codebase-scan.md` → Existing feature discovery
  - Markers used: `[FROM SCAN]`, `[EXISTING FEATURE]`

**Information Flow**:
```
PRD.md + project.md + [epic-codebase-scan]
  ↓
epic.md (this document)
  ↓
epic-clarify → epic-architecture → epic-plan → epic-breakdown → stories
```

---

## Epic Lifecycle State Tracking

**Current State**: Specified

- [x] **Specified** - epic.md created
- [ ] **Clarified** - Ambiguities resolved (`/epic-clarify` complete)
- [ ] **Architected** - epic-architecture.md created (`/epic-architecture` complete)
- [ ] **Planned** - epic-tech-spec.md created (`/epic-plan` complete)
- [ ] **Stories Mapped** - epic-breakdown.md created (`/epic-breakdown` complete)
- [ ] **In Progress** - Stories being implemented
- [ ] **All Stories Complete** - All story validations PASS
- [ ] **Validated** - Epic integration verified (`/epic-validate` complete)
- [ ] **Retrospective** - epic-retro.md created (`/epic-retrospective` complete)
- [ ] **Archived** - Ready for archive

Update state checkboxes as epic progresses through workflow.

---

## Execution Flow (/epic-specify scope)
```
1. Parse epic description from Input
   → Extract epic focus area and boundaries
2. Load project context (PRD, project goals)
   → Understand how this epic contributes to project
3. Identify user stories within epic scope
   → Each story delivers incremental value
4. For unclear aspects:
   → [NEEDS CLARIFICATION: specific question about scope/approach]
5. Define clear success criteria
   → Measurable outcomes when epic is complete
6. Map dependencies and integration points
   → What this epic needs from others, provides to others
7. Review against epic checklist
   → Standalone value, clear boundaries, testable outcomes
8. Return: SUCCESS (ready for /epic-clarify or /epic-plan)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT this epic delivers and HOW it fits the project
- ✅ Define clear boundaries with other epics
- ✅ Include enough detail for story breakdown
- ❌ Avoid implementation details (no code, schemas, or architecture yet)
- ❌ Don't overlap with other epic scopes

---

## Overview

**Epic Summary**: [2-3 sentences explaining what this epic delivers]
- Core capability being built
- Primary users who benefit
- How it advances project goals

**Business Value Statement**: 
"This epic enables [target users] to [key capability] which results in [business value]"

**Contribution to Project Goals**:
- Project Goal 1: [How this epic contributes]
- Project Goal 2: [How this epic contributes]

## 👥 User Stories

### Story Group 1: [Capability Area]

**Story 1.1**: As a [user type], I want to [action] so that [benefit]
- **Acceptance Criteria**:
  #### Scenario: [Primary success path]
  - **GIVEN** [initial state or context]
  - **WHEN** [user action]
  - **THEN** [expected outcome]
  - **AND** [additional outcomes]
- **Priority**: High/Medium/Low
- **Complexity**: Small/Medium/Large

**Story 1.2**: As a [user type], I want to [action] so that [benefit]
- **Acceptance Criteria**:
  #### Scenario: [Success path]
  - **GIVEN** [initial state]
  - **WHEN** [user action]
  - **THEN** [expected outcome]
- **Priority**: High/Medium/Low
- **Complexity**: Small/Medium/Large

### Story Group 2: [Capability Area]

[Continue with more stories...]

### Technical Stories

**Tech Story**: Set up [infrastructure/tooling/integration]
- **Rationale**: [Why needed for this epic]
- **Acceptance**: [What marks it complete]

## 📋 Functional Requirements

### Core Requirements
[Requirements specific to this epic, referenced from PRD]

**FR-[EPIC]-001**: System SHALL [requirement with normative statement]
- Input: [What's provided]
- Process: [What SHALL happen]
- Output: [What SHALL be produced]
- Validation: [How to verify]

**FR-[EPIC]-002**: System SHALL [requirement with normative statement]
- Input: [What's provided]
- Process: [What SHALL happen]
- Output: [What SHALL be produced]
- Validation: [How to verify]

### Integration Requirements
[How this epic integrates with others]

**IR-001**: Integration with [Other Epic]
- Interface: [How they connect]
- Data flow: [What's exchanged]
- Dependencies: [What must exist first]

### Non-Functional Requirements
[Performance, security, etc. specific to this epic]

**NFR-001**: [Requirement type]
- Target: [Specific metric]
- Measurement: [How to measure]
- Impact: [Why important for this epic]

## Dependencies

### Depends On
| Epic | What We Need | When Needed | Status |
|------|--------------|-------------|--------|
| [Epic ID] | [Specific dependency] | [Phase] | [Status] |

### Provides To
| Epic | What We Provide | When Available | Interface |
|------|-----------------|----------------|-----------|
| [Epic ID] | [Specific capability] | [Phase] | [How accessed] |

### External Dependencies
- [System/Service]: [What's needed and why]
- [System/Service]: [What's needed and why]

## Success Criteria

### Definition of Done
- [ ] All user stories implemented and tested
- [ ] Integration with dependent epics verified
- [ ] Performance targets met
- [ ] Security requirements validated
- [ ] Documentation complete
- [ ] Stakeholder acceptance received

### Key Metrics
| Metric | Target | Method | When Measured |
|--------|--------|--------|---------------|
| [Metric name] | [Target value] | [How measured] | [Frequency] |

### Acceptance Scenarios
[End-to-end scenarios that prove epic success]

Use structured GIVEN/WHEN/THEN format:

#### Scenario: [Primary end-to-end flow]
- **GIVEN** [initial system state]
- **WHEN** [series of user actions through epic features]
- **THEN** [epic goal is achieved]
- **AND** [measurable success criteria met]

#### Scenario: [Integration with other epics]
- **GIVEN** [dependent epic features exist]
- **WHEN** [user flows across epic boundaries]
- **THEN** [seamless integration verified]

## ⚠️ Risks & Mitigation

### Technical Risks
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| [Risk description] | High/Med/Low | High/Med/Low | [Strategy] |

### Business Risks
| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| [Risk description] | High/Med/Low | High/Med/Low | [Strategy] |

## 🏗️ Technical Considerations

### Constraints
[Technical constraints inherited from project or specific to epic]
- [Constraint]: [Impact on epic design]
- [Constraint]: [Impact on epic design]

### Assumptions
[Technical assumptions we're making]
- [Assumption]: [What we're assuming]
- [Assumption]: [What we're assuming]

### Open Questions
[Technical decisions still needed]
- [Question]: [What needs to be decided]
- [Question]: [What needs to be decided]

## 📊 Epic Sizing

### Story Breakdown Estimate
| Story Group | Story Count | Complexity | Total Points |
|-------------|------------|------------|--------------|
| [Group 1] | [X] | [S/M/L] | [Points] |
| [Group 2] | [Y] | [S/M/L] | [Points] |
| Technical | [Z] | [S/M/L] | [Points] |

**Total Estimated Stories**: [X-Y] stories  
**Estimated Duration**: [N] sprints/weeks  
**Team Size Needed**: [N] developers

## ✅ Epic Specification Checklist

### Completeness Check
- [ ] All user stories have acceptance criteria
- [ ] Success metrics are measurable
- [ ] Dependencies are identified
- [ ] Risks have mitigation strategies
- [ ] No overlap with other epics

### Quality Check
- [ ] Stories deliver incremental value
- [ ] Epic has clear boundaries
- [ ] Integration points defined
- [ ] Technical constraints acknowledged
- [ ] Ready for technical planning

### Readiness Check
- [ ] Ready for story estimation
- [ ] Ready for technical design (/epic-plan)
- [ ] Ready for sprint planning
- [ ] Team can understand scope

---

**Next Steps**: 
1. Run `/epic-clarify` if any aspects need refinement
2. Run `/epic-plan` to create technical specification
3. Run `/epic-breakdown` to map out story dependencies
