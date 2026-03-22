---
name: speck
description: Universal entry point — load when the user starts with /speck [description] or isn't sure which command to use. Detects play level, current project state, and routes to the right workflow (project/epic/story). Always start here when intent or current phase is unclear.
disable-model-invocation: false
---


The user input to you can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

Analyze the user's request and route to the appropriate Speck workflow level based on scope and context.

## Pre-Routing Checks

Before routing to standard workflows, check for special cases:

### 1. Brainstorm Detection
If user's request is vague or ideation-focused, route to `/project-brainstorm`:
- "I have an idea but it's not clear yet"
- "Help me figure out what to build"
- "Let's brainstorm", "explore ideas", "I'm not sure what I want"
- Vague descriptions lacking specific features
- Stream-of-consciousness thoughts
- "I wish..." or "wouldn't it be cool if..." statements

```
User: /speck I have some ideas about helping people be more social but I'm not sure

AI: 💡 Sounds like you're in ideation mode! Let me help you brainstorm...
→ Routes to: /project-brainstorm
```

### 2. Recipe Detection
If user's request matches a known recipe, offer it:
- Check `.speck/recipes/*/recipe.yaml` for keyword matches
- Suggest matching recipe as starting point
- Allow user to accept, customize, or skip
- If a recipe is selected:
  - Load `.speck/recipes/<recipe>/recipe.yaml` and use it to pre-fill /project-* artifacts
  - Load relevant skills from `.claude/skills/` (e.g., Clerk/Stripe/Supabase) and apply their patterns/gotchas during planning and implementation

```
User: /speck Build a React app with Python backend

AI: 🍳 I found a matching recipe: "react-fastapi-postgres"
    
    This recipe includes:
    - React 18 + TypeScript + Vite frontend
    - FastAPI + SQLAlchemy backend  
    - PostgreSQL database
    - Pre-configured auth epic
    
    Options:
    1. Use this recipe (customized for your needs)
    2. Start from scratch (full specification flow)
    3. See other recipes
    
[If user picks 1, pre-fill project-specify with recipe defaults]
```

**Recipe Keywords**:
- Each recipe defines a `keywords:` list in `.speck/recipes/<recipe>/recipe.yaml`
- Match case-insensitively against the user’s request (exact + partial phrase matches)
- If multiple recipes match, present the top 3 with “why it matched” and let the user choose

**Recipe index**:
- See `.speck/recipes/README.md` for the full recipe list and intended use cases

## Play Level Detection

Play levels are **agent-detected from conversation context** — never declared with flags.

After pre-routing checks, infer the play level before routing:

### Sprint signals (route to lightweight sprint flow)
- Time-bounded: "this weekend", "48 hours", "in a day", "quick experiment"
- Tiny scope: "simple tool", "calculator", "one-page app", "landing page"
- Ship-first intent: "ship it", "just get it out", "hack together", "prototype"
- No revenue complexity: "free tool", "scratch my own itch", "fun side project"

→ Sprint: Use `sprint-prd-template.md`, create `sprint-log.md`, skip epics/stories.
→ Tell the user: "This sounds like a Sprint — a focused 1–2 week bet. I'll keep the planning lightweight."

### Build signals (route to standard build flow)
- Subscription or payment: "subscription", "paid plan", "stripe", "pricing"
- Dashboard or admin: "dashboard", "admin panel", "user management"
- Expansion from existing: "expand this", "add more features", "v2", "grow it"
- Multi-user: "teams", "organizations", "multi-tenant"

→ Build: Standard PRD + context.md + COMMERCIAL.md. Epic structure. No constitution/design-system required.
→ Tell the user: "This sounds like a Build — a structured product with epics and stories."

### Platform signals (use existing Level 3-4 routing)
- Architecture complexity: "microservices", "distributed", "enterprise", "platform"
- Scale: "millions of users", "global", "marketplace"
- Already at Level 3-4 per scale analysis

→ Platform: Full Speck flow unchanged.

### Promotion signals
- "getting traction", "this is working", "users are paying", "promote to build/platform"
- "it's bigger than I thought", "we need more structure"

→ Route to: `/project-promote` with current play level context.

---

## Clear Level Separation (No Overlaps)

Each level has distinct responsibilities:
- **Project**: Vision, goals, epic identification, roadmap
- **Epic**: Feature design, technical architecture, story mapping  
- **Story**: Implementation details, concrete dev tasks

The levels complement each other without overlap:
- Projects don't define HOW features work (that's epic level)
- Epics don't define WHAT the product is (that's project level)
- Stories don't define architecture (that's epic level)

## Execution Flow

1. **Auto-Detection Phase**:
   - Detect if we're in the middle of existing Speck work
   - Look for current project context
   - Identify if this is a continuation or new work

2. **Context Parsing**:
   - Parse arguments for explicit context: "project:XXX", "epic:YYY"
   - Look for natural language context: "in project", "for epic"
   - Check for continuation keywords: "continue", "resume", "next"
   - Extract the actual request after context markers

3. **Smart Context Resolution**:
   - If "continue" or empty args → Find most recent work
   - If ambiguous → List current work in progress
   - If new work → Proceed to scale analysis

4. **Context Validation** (if context provided):
   - Verify project exists: `specs/projects/[PROJECT_ID]/project.md`
   - Verify epic exists: `specs/projects/[PROJECT_ID]/epics/[EPIC_ID]/epic.md`
   - If invalid, list available options

5. **Scale Analysis** (if no context):
   - Run `bash .speck/scripts/bash/analyze-scale.sh --json "$ARGUMENTS"`
   - Parse JSON for suggested level and reasoning
   - Consider confidence level

6. **Interactive Guidance**:
   - Present analysis with clear reasoning
   - Show current state if relevant
   - Offer intelligent defaults
   - Guide to the most appropriate workflow

7. **Smart Routing**:
   - Route to command with proper context
   - Pass context as part of arguments
   - Ensure continuity of work
   - Suggest next steps after completion

## Context Resolution Examples

### Explicit Context
```
Input: "/speck project:001-my-app epic:E001-authentication Add password reset"
→ Routes to: /story-specify with context pre-filled
```

### Natural Language Context  
```
Input: "/speck Add OAuth to the authentication epic"
→ Asks: "Which project contains the authentication epic?"
→ Lists projects, then epics
→ Routes to: /story-specify with discovered context
```

### No Context (New Work)
```
Input: "/speck Build a task management system"
→ Runs scale analysis (Level 3-4 detected)
→ Recommends: /project-specify
→ Allows override if user prefers different level
```

### Continuation Context
```
Input: "/speck Continue planning the user profile epic"
→ Searches for "user profile" epic across projects
→ If found: Routes to appropriate epic command
→ If multiple: Asks which one
→ If none: Suggests creating new epic
```

### Empty Input (Most Intelligent)
```
Input: "/speck"

AI: Let me check your current work state...

[If work exists]:
Current work in progress:
- Project: 001-my-app (75% complete)
  - PRD: ✅ Complete
  - Architecture: ⚠️ Not created (Level 3 project)
  - Epic: Authentication (3/5 stories done)
    - Active story: Password reset flow
  - Epic: User Management (not started)

What would you like to do?
1. Continue with password reset flow (/story-implement)
2. Create system architecture (/project-architecture) [Recommended for Level 3]
3. Start the user management epic (/epic-specify)
4. View project roadmap (/project-roadmap)
5. Review epic progress (/epic-validate)
6. Begin something new

[If no work exists]:
No existing work found. What would you like to build?
```

## Interactive Context Discovery

When context is ambiguous:

```
User: /speck "Add search functionality"

AI: I need more context to route you correctly. 

Are you:
1. Starting a new project with search as a core feature?
2. Adding search to an existing project? 
3. Adding search within a specific epic?

[If option 2 or 3 chosen]

Available projects:
- 001-my-app: Social Planning Assistant
- 002-crm-platform: CRM for Small Business
- 003-ecommerce: Online Store Platform
- 002-task-tracker: Task Management System

Which project? [Enter number or name]:

[After project selection, if needed]

This could be:
a) A new epic for comprehensive search
b) A story within an existing epic

Available epics in 001-my-app:
- E001-authentication: User Auth & Onboarding
- E002-connections: Social Connections  
- E003-activities: Activity Planning

Where does search belong? 
a) New epic (comprehensive search system)
b) Add to existing epic [Enter number]
c) Let me check the project roadmap first

[If c]: Shows project-roadmap.md to understand epic relationships
```

## Natural Flow Between Levels

The Speck workflow naturally progresses:
1. **Project** → Vision, goals, epic identification, system architecture
2. **Epic** → Feature sets, technical design, story mapping
3. **Story** → Implementation details, concrete tasks

You can jump in at ANY level based on your needs:
- Have a big idea? → Start at project level
- Know the feature you want? → Start at epic level  
- Ready to implement? → Start at story level

Architecture is handled based on scale (and comes *before* planning whenever planning depends on design decisions):
- Level 0-1 → Usually skip `/project-architecture` (or keep it very lightweight) and work at epic/story level
- Level 2-4 → Run `/project-architecture` before `/project-plan` so the PRD incorporates the chosen design
- Complex epics → Run `/epic-architecture` before `/epic-plan` and before implementation
- Brownfield projects → `/project-architecture` primarily extracts the as-is architecture from code (and can propose a to-be) before `/project-plan`

## Smart Suggestions Based on Scale

The system provides intelligent recommendations:

**Small Addition to Existing Epic**
```
"Add email validation to signup"
→ Detected: Story-level (specific validation)
→ Context needed: Which epic has signup?
→ Route to: /story-specify in auth epic
```

**Cross-Cutting Feature**
```
"Add real-time notifications"  
→ Detected: Epic-level (affects multiple areas)
→ Suggest: New epic in current project
→ Route to: /epic-specify with project context
```

**Major Enhancement**
```
"Convert to microservices architecture"
→ Detected: Project-level transformation
→ Suggest: New project or major epic
→ Route to: /project-specify or /epic-specify
```

## Interactive Flow Example

```
User: /speck "Add user authentication system"

AI: 🔍 Analyzing request...

Scale Analysis:
- Detected: Epic-level scope (authentication system)
- Estimated: 8-12 stories across 1 epic
- Confidence: High

Recommendation: Start with epic-level specification

Options:
a) Continue with epic workflow (/epic-specify) [Recommended]
b) Start with project level (/project-specify)
c) Break down to single story (/story-specify)
d) Get more details about each option

Your choice [a]: 

[After epic-specify and epic-clarify]

AI: Authentication epic specified! This looks complex with OAuth, 2FA, and session management.

Next steps:
1. Design epic architecture (/epic-architecture) [Recommended] 
2. Jump to tech spec (/epic-plan)
3. Map user journey first (/epic-journey)

Your choice [1]:
```

## Jump-In Examples

**Starting Mid-Stream**
```
User: /speck "I need to implement the login form"

AI: This looks like a story within an authentication epic.

Do you have:
1. An existing project with auth epic? → /story-specify
2. Just the epic planned? → Let's find it
3. Nothing yet? → Should we create the auth epic first?
```

**Skipping Levels** 
```
User: /speck "Build task tracker MVP - I don't need full project planning"

AI: Understood! You want to skip detailed project planning.

Options:
a) Create single epic with all MVP features → /epic-specify
b) Jump straight to stories → /story-specify  
c) Minimal project wrapper → /project-specify (quick version)

This is perfectly fine for MVPs and prototypes!
```

## Scale Detection Examples

**Level 0 (Atomic)**
- "Fix typo in login button"
- "Change header color to blue"
- "Update copyright year"
→ Route to: `/story-specify`
→ Architecture: Not needed

**Level 1 (Small Feature)**
- "Add password reset form"
- "Create user profile page"  
- "Implement search bar"
→ Route to: `/story-specify` (within existing epic)
→ Architecture: Inherits from epic

**Level 2 (Feature Set)**
- "Build authentication system"
- "Add shopping cart functionality"
- "Implement notification system"
→ Route to: `/epic-specify`
→ Architecture: Optional `/epic-architecture` for complex epics

**Level 3-4 (Major/Platform)**
- "Create social media platform"
- "Build e-commerce site"
- "Develop project management tool"
→ Route to: `/project-specify`
→ Architecture: Run `/project-architecture` before `/project-plan` (planning depends on design decisions)

## Brownfield Architecture Handling

When importing existing code, architecture commands adapt:

**Project Import Flow**
```
/speck import ~/myproject
→ /project-import (analyzes code)
→ /project-scan (extracts patterns)
→ /project-specify (creates spec from code)
→ /project-context (captures constraints discovered + missing non-code context)
→ /project-architecture (reverse-engineers design)
```

**Architecture Extraction Features**
- Detects existing architectural patterns
- Maps component relationships from code
- Identifies technology stack automatically
- Documents implicit design decisions
- Suggests refactoring opportunities

**Example Brownfield Flow**
```
User: /speck Import my Rails app and document architecture

AI: Analyzing your codebase...
- Found: MVC architecture with Rails 7
- Database: PostgreSQL with 23 models
- APIs: REST endpoints in 5 controllers
- Frontend: Hotwire + Stimulus

I'll help you:
1. Create project structure from code
2. Extract and document current architecture
3. Identify improvement opportunities

[Routes to /project-import then /project-architecture]
```

## Key Transition Points

**Project → Epic Transition**
After `/project-plan` creates PRD and identifies epics:
- Use `/project-roadmap` to plan epic timeline
- Then `/epic-specify` for each epic in priority order
- (If you’re working with existing work where PRD exists but architecture.md is missing, run `/project-architecture` and then update PRD.md or re-run `/project-plan`.)
- No overlap: Project defines WHAT epics, Epic defines HOW

**Epic → Story Transition**  
After `/epic-clarify` resolves ambiguities:
- For complex epics: Run `/epic-architecture` 
- Use `/epic-plan` to create technical spec
- Use `/epic-breakdown` to map all stories
- Then `/story-specify` for each story in order
- No overlap: Epic defines architecture, Story defines implementation

## Override Handling

If user disagrees with recommendation:

```
User: "No, I want to start with a full project plan"

AI: Understood! Let me help you create a project specification instead.
[Routes to /project-specify]
```

## Error Conditions

- Empty input → Ask what they want to build
- Ambiguous scope → Present scale analysis and ask for clarification  
- Conflicting context → Explain current location and options

## Smart Suggestions

Based on context, provide helpful hints:

**Ideation Phase**:
- Vague idea → "Try /project-brainstorm to explore and crystallize your concept"
- After brainstorm → "Ready to formalize! Run /project-specify with your chosen concept"

**Recipe Matches**:
- Matching recipe found → "I found a recipe that matches! Use it for faster setup"
- After recipe selection → "Recipe applied! Customizing for your specific needs..."

**Project Level**:
- After specify/clarify → "Run /project-domain for specialized domains, /project-ux for UX-heavy products, or /project-context to define constraints"
- After domain → "Run /project-ux for UX strategy (uses domain terminology), or /project-context to define technical constraints"
- After UX → "Run /project-context to define technical constraints"
- After context → "Optional: /project-constitution → then /project-architecture"
- After architecture → "Optional: /project-design-system → then /project-plan"
- After plan → "Optional: /project-roadmap → then /project-analyze → /project-validate"
- Level 3-4 project → "Full flow: domain → ux → context → constitution → architecture → design-system → plan → roadmap"
- Brownfield import → "Flow: import → scan → specify/clarify → domain → ux → context → architecture → plan"

**Epic Level**:
- Complex epic after clarify → "Run /epic-architecture before tech spec"
- In an epic needing stories → "Run /epic-breakdown to map stories"
- Epic ready for work → "Start with first story via /story-specify"

**General**:
- Starting fresh → "I can help you decide the right level to begin"

## Output Format

After routing decision:

```
✅ Routing to [workflow level] workflow

Context:
- Scope: [detected scope]
- Scale: Level [0-4]
- Location: [current context]

Executing: /[command] "[original arguments]"
---
[Command execution continues...]
```

## Architecture-Aware Routing Example

**Level 4 Platform Project**
```
User: /speck Build a comprehensive e-learning platform

AI: 🔍 Analyzing request...

This is a Level 4 platform-scale project requiring:
- Multiple subsystems (content, users, payments, analytics)
- Complex integrations
- Scalability planning
- Security architecture

I'll guide you through the complete workflow:

1. Project specification (/project-specify)
2. Clarification (/project-clarify)
3. UX strategy (optional) (/project-ux)
4. Context & constraints (/project-context)
5. Constitution (optional) (/project-constitution)
6. System architecture (/project-architecture) ← Critical for Level 4
7. Design system (optional) (/project-design-system)
8. Planning & PRD (/project-plan)
9. Project validation (/project-validate)

Ready to start? [Y/n]:
```

**Complex Brownfield Import**
```
User: /speck Import and modernize my existing Django app

AI: Analyzing your existing codebase...

Found:
- Django 2.1 (outdated)
- Monolithic architecture
- 47 models, 23 views
- No clear separation of concerns

Architecture recommendations:
1. Document current architecture (as-is)
2. Design target architecture (to-be)
3. Create migration roadmap

Shall I:
a) Import and document current state [Recommended]
b) Skip to modernization planning
c) Just create basic structure

Your choice [a]:

[Routes to /project-import → /project-architecture]
```

This universal entry point helps users start their Speck journey at the right level without needing to understand the full hierarchy upfront, with intelligent architecture guidance when complexity demands it.
