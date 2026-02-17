---
name: project-context
description: Define constraints, standards, and requirements that guide architectural decisions - the unchangeable rules within which the system must be designed
disable-model-invocation: false
---

---
description: Define constraints, standards, and requirements that guide architectural decisions - the unchangeable rules within which the system must be designed.
---

The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Create or update the project context that provides the foundation for all development decisions.

## Context Identification & Mode Detection

First, determine the project:
- Parse arguments for project identifier
- If not provided, ask: "Which project should I create/update context for?"
- List available projects

Load existing project context if it exists:
- Check for `specs/projects/[PROJECT_ID]/context.md`
- If exists, we're updating; if not, creating new

**Detect mode**:
- Check for project-landscape-overview.md (from /project-scan)
- If exists: **BROWNFIELD mode** (extract from scan)
- If not: **GREENFIELD mode** (interactive creation)

**Check for Active Recipe** (greenfield only):
- Look for `_active_recipe:` in project.md metadata
- If found, load `.speck/recipes/[recipe-name]/recipe.yaml`
- Recipe provides pre-filled context from its `context:` section:
  * `technical:` → Technical requirements (Python version, Node version, etc.)
  * `development:` → Development practices (branching strategy, commits)
  * `quality:` → Quality standards (test coverage, type safety)
- Use recipe context as starting point, ask only for non-covered areas

## Just-In-Time Research

**Reference**: Follow the just-in-time research pattern (`.cursor/skills/just-in-time-research/SKILL.md`)

Before defining context, identify knowledge gaps and conduct research:

### Research Areas for Context

**1. Industry Standards**:
- Decision: What standards apply to [domain/industry]?
- Web Search: ISO standards, industry regulations, compliance requirements
- Deep Research (if needed): Domain-specific regulatory analysis

**2. Technology Constraints**:
- Decision: What are limits/capabilities of [tech stack]?
- Web Search: Framework documentation, version compatibility, performance benchmarks
- Deep Research (if needed): Technology evaluation, migration strategies

**3. Compliance Requirements**:
- Decision: What legal/regulatory requirements apply?
- Web Search: GDPR, HIPAA, SOC2, PCI-DSS requirements (as applicable)
- Deep Research (if needed): Legal compliance deep-dive

**4. Best Practices**:
- Decision: What organizational standards should we follow?
- Web Search: Development best practices, testing standards, security patterns
- Deep Research (rarely needed): Most are well-documented

### Execute Research

For each area with knowledge gaps:
1. **Quick web search** for standards and requirements
2. **Generate deep research prompt** if web search insufficient
3. **Document findings** in "Research Informing This Context" section of output

## Interactive Context Development

**MODE SELECTION**: Branch based on detected mode

---

## BROWNFIELD MODE (Extract from Scan)

**Prerequisites**: project-landscape-overview.md must exist (run /project-scan first)

### Step 1: Load Scan Findings

Load project-landscape-overview.md and extract:
- Tech stack (languages, frameworks, databases)
- Architecture pattern (monolith, microservices, etc.)
- Existing integrations
- Quality metrics (test coverage, code quality)
- Major components and boundaries

### Step 2: Pre-fill Context from Scan

Auto-populate context.md sections with scan findings:

**Technology Constraints** (from scan):
- Current tech stack: [Languages and frameworks from scan]
- Database: [Database type from scan]
- Integrations: [Third-party services from scan]
- Platform: [Deployment target from scan]

**Development Standards** (from scan):
- Testing: [Test framework and coverage from scan]
- Code quality: [Linters/formatters found in scan]
- Documentation: [Doc patterns from scan]

### Step 3: Ask Only for Missing Context

For items NOT discoverable from code:
- "Team size and expertise?" (can't infer from code)
- "Development timeline and budget?" (business context)
- "Why was this tech stack chosen?" (historical context)
- "Are there constraints we should maintain?" (e.g., "Must stay on Python 3.9")
- "Any planned tech migrations?" (e.g., "Moving to React 19")

### Step 4: Document Extracted Context

Create context.md with extraction notes:
```markdown
> **Extraction Note**: This context was extracted from codebase analysis.
> Technology constraints reflect CURRENT STATE, not necessarily future direction.
> Update if planning tech migrations or diverging from current patterns.
```

---

## GREENFIELD MODE (Interactive Creation)

**Purpose**: Define constraints interactively when no code exists

### Step 1: Technical Constraints & Standards

Ask progressively:

**Technology Requirements**
- "Any required technologies or integrations?" (e.g., must use React, must integrate with SAP)
- "Browser/device support requirements?"
- "Platform constraints?" (mobile, desktop, embedded)
- "Legacy system compatibility needs?"

**Development Constraints**
- "Team size and expertise?"
- "Development timeline?"
- "Budget constraints?"
- "Geographic/timezone distribution?"

### Step 2: Development Standards

**Code Quality**
- "Do you have a style guide or linter config?"
- "Testing requirements?" (Coverage targets)
- "Documentation standards?"

**Workflow**
- "Git branching strategy?" 
- "Code review process?"
- "CI/CD pipeline?"

### Step 3: Quality & Compliance Standards

**Accessibility Requirements**
- "Required WCAG compliance level?" (A/AA/AAA)
- "Specific accessibility requirements?"
- "Multi-language support needed?"

**Regulatory Compliance**
- "Data privacy regulations?" (GDPR/CCPA/HIPAA)
- "Industry standards?" (PCI-DSS, SOC2, ISO)
- "Audit requirements?"

### Step 4: Operational Requirements

**Performance**
- "Response time targets?"
- "Concurrent user expectations?"
- "Data volume projections?"

**Security**
- "Authentication method?" (SSO/OAuth/Custom)
- "Authorization model?" (RBAC/ABAC)
- "Compliance requirements?" (GDPR/HIPAA/SOC2)

**Availability Requirements**
- "Required uptime SLA?"
- "Maintenance window constraints?"
- "Disaster recovery requirements?"

### Step 5: Constraints & Dependencies

**Technical Constraints**
- "Must support specific browsers/devices?"
- "Integration requirements?"
- "Legacy system constraints?"

**Project Constraints**
- "Timeline/deadline?"
- "Team size and expertise?"
- "Budget considerations?"

### Step 6: Generate Context Document

Create `specs/projects/[PROJECT_ID]/context.md`:

Use the template from `.speck/templates/project/context-template.md` and fill with gathered information.

Populate the template’s **Research Informing This Context** section using findings from the research step above.

Key sections to populate:
- Technical Constraints (required tech, browser support, integrations)
- Development Standards (code quality, testing, workflow)
- Compliance Requirements (accessibility, privacy, security)
- **Apply research findings to constraints and requirements**
- Operational Requirements (performance, uptime, DR)
- Project Constraints (timeline, budget, team)
- Inheritance Rules (how these constraints apply to epics/stories)

### Step 7: Context Validation

Review with checklist:
- ✅ All constraints and requirements documented?
- ✅ Development standards clear?
- ✅ Compliance requirements explicit?
- ✅ Performance/security targets defined?
- ✅ Clear what can't be changed vs what's flexible?

### Step 8: Integration Guidance

Explain how this context will be used:

"This context will be automatically inherited by:
- All epics in this project
- All stories within those epics

Epics can override specific technical choices if needed.
Stories inherit the merged context from both levels.

You can retrieve context anytime with:
```bash
bash .speck/scripts/bash/get-context.sh --project [PROJECT_ID]
```

Next steps:
- For complex/regulated projects: /project-constitution (define principles)
- For simpler projects: /project-plan (create PRD using these constraints)
- Ensure all team members understand the constraints
- Update when requirements change

Note: Context provides essential constraint inputs for PRD creation in /project-plan"

## Update Workflow

If updating existing context:

1. Load current context
2. Show what exists
3. Ask what needs updating:
   - "Technology changes?"
   - "New requirements?"
   - "Lessons learned?"
4. Preserve unchanged sections
5. Update only what's needed
6. Document why changes were made

## Context Usage Examples

Show how context influences decisions:

**Example 1: Epic Planning**
```
Project Context: Must support IE11+, WCAG AA, <200ms response time
Epic: User Authentication
→ Epic must ensure IE11 compatibility
→ Stories must meet accessibility standards
```

**Example 2: Story Implementation**  
```
Project Context: PCI compliance required, 99.9% uptime SLA
Epic Context: Payment processing constraints
Story: Add refund capability
→ Story must maintain PCI compliance
→ Must not exceed 5 min downtime/month
→ Must pass security audit requirements
```

## Error Prevention

Validate context completeness:
- Warn if critical sections empty
- Flag conflicting requirements
- Ensure inheritance rules clear
- Check for ambiguous standards
