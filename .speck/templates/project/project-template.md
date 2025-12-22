# Project Specification: [PROJECT NAME]

**Project ID**: [PROJECT_NUM]  
**Created**: [DATE]  
**Status**: Planning  
**Scale**: [To be determined: Level 0-4]

---

## 📊 Information Sources

**Traceability**: This project specification was created from the following sources:

- **Greenfield**: User input + interactive Q&A
- **Brownfield** (if applicable):
  - `project-import.md` → Non-code aspects (vision, stakeholders, constraints)
  - `project-landscape-overview.md` → Code aspects (tech stack, features, architecture)
  - Markers used: `[FROM IMPORT]`, `[INFERRED FROM CODE]`, `[NEEDS VALIDATION]`

**Information Flow**:
```
project-import + project-landscape-overview + user input
  ↓
project.md (this document)
  ↓
project-clarify → context → architecture → design-system → plan
```

---

## Execution Flow (/project-specify scope)
```
1. Parse project description from Input
   → Extract key concepts: domain, users, goals, constraints
2. Identify project type and potential scale
   → Web app, mobile app, API, library, platform, hybrid
   → Estimate complexity: simple (0-1), moderate (2), complex (3-4)
3. For each unclear aspect:
   → [NEEDS CLARIFICATION: specific question about scope/goals/constraints]
4. Fill all template sections with concrete details
   → No placeholders, no generic text
5. Ensure internal consistency
   → Goals align with vision, scope supports goals, metrics measure goals
6. Review against project-level checklist
   → All sections complete, no conflicts, ready for planning
7. Return: SUCCESS (ready for /project-clarify or /project-plan)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT the project achieves and WHY it matters
- ✅ Define clear boundaries (what's in v1 vs future)
- ✅ Identify key user groups and their primary needs
- ❌ Avoid implementation details (no tech stack, architecture, or timelines yet)
- ❌ Don't list individual features - use capability areas instead

---

## 🎯 Project Overview

**One-paragraph project summary that explains:**
- What problem this project solves
- Who benefits from the solution  
- The core value proposition
- Why this matters now

## 🎨 Project Type & Scale

**Type**: [Select primary type]
- Web Application (browser-based, responsive)
- Mobile Application (iOS/Android native or cross-platform)
- API/Backend Service (headless, integration-focused)
- Library/Framework (developer tool)
- Platform (multi-sided marketplace or ecosystem)
- Hybrid (combination - specify)

**Estimated Scale**: [Will be refined during planning]
- Level 0: Single atomic change or fix
- Level 1: Small feature or enhancement (1-10 stories, 1 epic)
- Level 2: Moderate feature set (5-15 stories, 1-2 epics)
- Level 3: Major product area (12-40 stories, 2-5 epics)
- Level 4: Full platform or product (40+ stories, 5+ epics)

**Primary Domain**: [Core business/technical area]
- Social/Community
- E-commerce/Marketplace  
- Analytics/Data
- Content/Media
- Developer Tools
- Enterprise/B2B
- Other: [Specify]

## 🚀 Vision & Goals

### Vision Statement
[One powerful sentence that describes the future state this project enables]
- Format: "A world where [target users] can [key capability] so that [ultimate benefit]"
- Example: "A world where remote teams collaborate as naturally as in-person teams"

### Primary Goals
[3-5 specific, measurable goals that directly support the vision]
1. **[Goal Category]**: [Specific measurable outcome]
   - Success looks like: [Concrete description]
   - Key metric: [How we measure this]

2. **[Goal Category]**: [Specific measurable outcome]
   - Success looks like: [Concrete description]
   - Key metric: [How we measure this]

3. **[Goal Category]**: [Specific measurable outcome]
   - Success looks like: [Concrete description]
   - Key metric: [How we measure this]

## 👥 Target Users

### Primary User Segments
[2-3 well-defined user groups with distinct needs]

**[User Type 1 Name]**
- Who they are: [Demographics, role, context]
- Current pain points: [What frustrates them today]
- Primary job: [Core functional job they're hiring this product for]
- Success criteria: [What would delight them / key outcomes they value]

**[User Type 2 Name]**
- Who they are: [Demographics, role, context]
- Current pain points: [What frustrates them today]
- Primary job: [Core functional job they're hiring this product for]
- Success criteria: [What would delight them / key outcomes they value]

### User Problems We're Solving
[Top 3-5 problems in priority order]
1. **[Problem Name]**: [Description of the problem and its impact]
   - Current workarounds: [How users cope today]
   - Cost of inaction: [What happens if we don't solve this]

2. **[Problem Name]**: [Description of the problem and its impact]
   - Current workarounds: [How users cope today]
   - Cost of inaction: [What happens if we don't solve this]

---

## 🎯 Jobs-to-Be-Done (JTBD)

*Apply JTBD theory (Ulwick/Christensen) to focus on what users are trying to accomplish, not just features.*

### Core Functional Job

**Primary Job Statement**:
[Action verb] + [object of action] + [contextual clarifier]

*Example: "Manage project deadlines across distributed teams"*

**Job Context**:
- **When**: [Situation or trigger that creates the need]
- **With**: [People, tools, or resources involved]
- **Goal**: [What success looks like]

### Related Jobs

*Adjacent jobs that arise before, during, or after the core job:*

1. **[Related Job]**: [Job statement]
   - Relationship: [Before/During/After core job]

2. **[Related Job]**: [Job statement]
   - Relationship: [Before/During/After core job]

### Emotional & Social Jobs

**Emotional Jobs** (How users want to feel):
- Feel [confident/in control/relieved/etc.] that [outcome]
- Avoid feeling [stressed/anxious/overwhelmed/etc.] about [situation]

**Social Jobs** (How users want to be perceived):
- Appear [organized/professional/competent/etc.] to [audience]
- Avoid appearing [unprepared/disorganized/etc.] to [audience]

### Key Desired Outcomes (Ranked)

*Users measure job success by these outcomes. Rank by importance to users:*

| Priority | Outcome Statement | Current Pain Level |
|----------|-------------------|-------------------|
| 1 | [Direction] the [measure] of [object] [context] | High/Med/Low |
| 2 | [Direction] the [measure] of [object] [context] | High/Med/Low |
| 3 | [Direction] the [measure] of [object] [context] | High/Med/Low |
| 4 | [Direction] the [measure] of [object] [context] | High/Med/Low |
| 5 | [Direction] the [measure] of [object] [context] | High/Med/Low |

*Directions: Minimize, Maximize, Increase, Reduce, Optimize*

*Examples:*
- *Minimize the time it takes to identify at-risk project tasks*
- *Minimize the likelihood of missing deadlines due to hidden dependencies*
- *Increase the accuracy of time estimates for similar future tasks*

### Competitive Job Executors

*How do users currently "hire" solutions to get this job done?*

| Current Solution | Strengths | Weaknesses (Opportunities) |
|------------------|-----------|---------------------------|
| [Competitor/Workaround 1] | [What it does well] | [Where it falls short] |
| [Competitor/Workaround 2] | [What it does well] | [Where it falls short] |
| [Manual process] | [What it does well] | [Where it falls short] |

### JTBD-Driven Prioritization

*Use this framework to prioritize features:*

**Prioritization Formula**: Importance + (Importance - Satisfaction) = Opportunity Score

Focus on outcomes with:
- HIGH importance to users
- LOW satisfaction with current solutions
- = HIGH opportunity score

---

## 📊 Success Metrics

### Key Performance Indicators (KPIs)
[3-5 measurable outcomes that indicate project success]

**Business Metrics**
- [Metric]: [Target] by [Timeframe]
  - Baseline: [Current state if applicable]
  - Method: [How we'll measure]

**User Metrics**
- [Metric]: [Target] by [Timeframe]
  - Baseline: [Current state if applicable]
  - Method: [How we'll measure]

**Technical Metrics**
- [Metric]: [Target] by [Timeframe]
  - Baseline: [Current state if applicable]
  - Method: [How we'll measure]

### Project Definition of Done
- [ ] All primary user problems have solutions implemented
- [ ] Success metrics tracking is in place and showing positive trends
- [ ] User acceptance testing confirms value delivery
- [ ] Technical quality gates passed (performance, security, accessibility)
- [ ] Documentation enables self-service usage
- [ ] Handoff to operations/support is complete

## 💰 Business Model & Monetization

### Value Proposition
**What value we create**: [Describe the core value delivered to customers]

**Who pays**: [Customer segments that pay - may differ from all users]
- [Customer Segment 1]: [Why they pay]
- [Customer Segment 2]: [Why they pay]

**Value exchange**: [What customers get vs what they give]

### Revenue Model
**Primary Revenue Stream**: [Select primary model]
- Subscription (recurring revenue)
- Transaction fees (per-use)
- License fees (perpetual or term)
- Advertising/Sponsored content
- Marketplace commission
- Freemium (free tier + paid upgrade)
- Enterprise/Custom pricing
- Usage-based (consumption pricing)
- Other: [Specify]

**Secondary Revenue Streams**: [Additional revenue if applicable]
- [Stream]: [Description]

**Rationale**: [Why this model fits the market, users, and value delivery]

### Pricing Strategy

**Pricing Model**: [Select approach]
- Freemium (free base + paid premium)
- Tiered (good/better/best packages)
- Usage-based (pay for consumption)
- Per-seat (per user pricing)
- Enterprise (custom negotiated)
- One-time purchase
- Hybrid (combination)

**Indicative Price Points** (if known):
- [Tier/Plan Name]: [Price] - [What's included]
- [Tier/Plan Name]: [Price] - [What's included]

**Value Metric**: [What drives pricing]
- Example: Number of seats, API calls, storage used, transactions processed
- Rationale: [Why this metric aligns with value delivered]

**Competitive Positioning**: [Premium/Mid-market/Budget relative to alternatives]

### Unit Economics (if applicable)

**Customer Acquisition Cost (CAC)**: 
- Estimated: [$ or range]
- Breakdown: [Marketing + Sales + Onboarding costs per customer]
- Assumptions: [Key assumptions in CAC calculation]

**Lifetime Value (LTV)**:
- Estimated: [$ or range]
- Calculation: [Average revenue per customer × retention period]
- Assumptions: [Churn rate, expansion revenue, retention assumptions]

**Key Ratios**:
- **LTV:CAC Ratio**: [Target: typically 3:1 or better]
- **Payback Period**: [Months to recover CAC - typically <12 months]
- **Gross Margin**: [Revenue - direct costs, typically 70%+ for SaaS]

**Break-even Analysis**: [When project becomes cash-flow positive]

### Revenue Milestones & Business Goals

**Phase 1 - Foundation**: [Business goal]
- Revenue target: [$ or validation milestone]
- Customer target: [Number of paying customers]
- Key metric: [Primary business metric to achieve]

**Phase 2 - Growth**: [Business goal]
- Revenue target: [$ or scale milestone]
- Customer target: [Number of paying customers]
- Key metric: [Primary business metric to achieve]

**Phase 3 - Scale**: [Business goal]
- Revenue target: [$ or optimization milestone]
- Customer target: [Number of paying customers]
- Key metric: [Primary business metric to achieve]

### Business Model Validation Plan

**Research Needed**:
- Business model research: YES/NO
- If YES: Use the **just-in-time research pattern** (`.speck/patterns/just-in-time-research-pattern.md`)
  to gather the information needed for these topics, and embed findings into the relevant
  artifact (usually `PRD.md`, and sometimes `ux-strategy.md` / `context.md` / `architecture.md`):
  - business-model-validation (revenue models, unit economics)
  - pricing-strategy (competitive analysis, willingness to pay)
  - go-to-market-strategy (customer acquisition channels, launch approach)
  - market-validation (TAM/SAM analysis, competitive landscape)

**Critical Assumptions to Test**:
1. [Assumption]: [How we'll validate - experiment/survey/pilot]
2. [Assumption]: [How we'll validate]
3. [Assumption]: [How we'll validate]

**Pricing Validation**:
- Research needed: YES/NO
- Method: [How we'll test pricing - surveys/pilots/competitor analysis]
- Timeline: [When pricing will be validated]
- Pivot plan: [What we'll do if initial pricing doesn't work]

**Go-to-Market Strategy** (High-level):
- Research needed: YES/NO
- **Customer Acquisition**: [Primary channels]
- **Sales Motion**: [Self-serve/Sales-assisted/Enterprise sales]
- **Launch Strategy**: [Beta/Soft launch/Big bang]

**Note**: Detailed business model research findings will be embedded in PRD.md after `/project-plan` runs.

### Business Model Risks

**Revenue Risks**:
1. [Risk]: [Impact] - [Mitigation]
2. [Risk]: [Impact] - [Mitigation]

**Market Risks**:
1. [Risk]: [Impact] - [Mitigation]
2. [Risk]: [Impact] - [Mitigation]

**Competitive Risks**:
1. [Risk]: [Impact] - [Mitigation]

---

**Note**: For internal tools, open-source projects, or non-commercial products, this section may focus on cost justification, internal value metrics, or community sustainability instead of revenue.

## 🏗️ High-Level Scope

### Core Capabilities (v1)
[Major capability areas that must be in the first release]

**[Capability Area 1]**
- What: [High-level description]
- Why critical: [Why this can't wait for v2]
- User value: [Direct benefit to users]

**[Capability Area 2]**
- What: [High-level description]
- Why critical: [Why this can't wait for v2]
- User value: [Direct benefit to users]

**[Capability Area 3]**
- What: [High-level description]
- Why critical: [Why this can't wait for v2]
- User value: [Direct benefit to users]

### Future Capabilities (v2+)
[Important but not critical for initial success]

**[Capability Area]**
- What: [High-level description]
- Why deferred: [Reason for not including in v1]
- Prerequisites: [What needs to be in place first]

### Explicit Out of Scope
[Things that might be expected but won't be included]
- [Capability]: [Brief reason why excluded]
- [Capability]: [Brief reason why excluded]

## 🔧 Constraints & Requirements

### Business Constraints
- **Budget**: [If known]
- **Timeline**: [Critical dates or deadlines]
- **Resources**: [Team size, skill constraints]
- **Legal/Compliance**: [Regulations, policies]

### Technical Constraints  
- **Platform**: [Must run on specific platforms]
- **Integration**: [Must work with existing systems]
- **Performance**: [Response time, throughput requirements]
- **Scale**: [Number of users, data volume]
- **Security**: [Special security requirements]

### User Experience Constraints
- **Accessibility**: [WCAG level, specific needs]
- **Localization**: [Languages, regions]
- **Device Support**: [Browsers, devices, versions]
- **Offline**: [Offline capability requirements]

## 🎭 Project Context

### Business Context
[Why is this project important to the business now?]
- Market opportunity or threat
- Strategic initiative alignment
- Revenue/cost implications
- Competitive positioning

### Technical Context
[Current technical landscape affecting the project]
- Existing systems to integrate or replace
- Technical debt to address
- Architectural constraints or opportunities
- Technology trends to leverage

### Organizational Context
[How this project fits within the organization]
- Stakeholder alignment
- Dependencies on other teams/projects
- Change management needs
- Success criteria from leadership

## ⚠️ Risks & Mitigation

### Critical Risks
[Top 3-5 risks that could derail the project]

1. **[Risk Name]**: [Probability: High/Medium/Low]
   - Description: [What might go wrong]
   - Impact: [What happens if it does]
   - Mitigation: [How we'll prevent or handle it]
   - Owner: [Who monitors this risk]

2. **[Risk Name]**: [Probability: High/Medium/Low]
   - Description: [What might go wrong]
   - Impact: [What happens if it does]
   - Mitigation: [How we'll prevent or handle it]
   - Owner: [Who monitors this risk]

### Key Assumptions
[Things we're assuming to be true]
1. [Assumption]: [What we're assuming]
   - Validation: [How we'll verify this]
   - Backup plan: [What if it's wrong]

2. [Assumption]: [What we're assuming]
   - Validation: [How we'll verify this]
   - Backup plan: [What if it's wrong]

## 🗺️ Implementation Approach

### Delivery Strategy
- **Approach**: [Big bang, phased, continuous]
- **MVP Definition**: [Minimum viable scope]
- **Rollout Plan**: [How we'll deliver to users]
- **Feedback Loops**: [How we'll gather and act on feedback]

### High-Level Phases
[Rough phases - will be detailed in planning]

**Phase 1: Foundation** ([Estimated epic count])
- Focus: [Primary outcomes]
- Success criteria: [What marks completion]

**Phase 2: Core Value** ([Estimated epic count])
- Focus: [Primary outcomes]
- Success criteria: [What marks completion]

**Phase 3: Scale & Polish** ([Estimated epic count])
- Focus: [Primary outcomes]
- Success criteria: [What marks completion]

## 🤝 Stakeholders

### Key Stakeholders
| Role | Name/Team | Interest | Influence |
|------|-----------|----------|-----------|
| Sponsor | [Name] | [What they care about] | High/Medium/Low |
| User Representative | [Name] | [What they care about] | High/Medium/Low |
| Technical Lead | [Name] | [What they care about] | High/Medium/Low |

### Communication Plan
- **Updates**: [Frequency and format]
- **Reviews**: [Key review points]
- **Escalation**: [How issues get raised]

## ✅ Project Specification Checklist

### Clarity Check
- [ ] Vision statement is inspiring and clear
- [ ] Goals are specific and measurable
- [ ] User problems are well-defined
- [ ] Scope boundaries are explicit
- [ ] All [NEEDS CLARIFICATION] items resolved

### Completeness Check  
- [ ] All template sections filled with project-specific content
- [ ] Success metrics have targets and methods
- [ ] Risks have mitigation strategies
- [ ] Assumptions are documented with validation plans
- [ ] No placeholder text remains

### Readiness Check
- [ ] Ready for stakeholder review
- [ ] Ready for epic identification (/project-plan)
- [ ] Ready for technical assessment
- [ ] Team can understand project intent from this document alone

---

**Next Steps**: 
1. Run `/project-clarify` if any aspects need refinement
2. Run `/project-plan` to generate PRD and identify epics
3. Share with stakeholders for alignment
