---
description: Transform loose ideas, inspirations, and problems into structured project concepts ready for specification.
---

User input:

$ARGUMENTS

The text the user typed after `/project-brainstorm` in the triggering message. This may be:
- Stream of consciousness thoughts
- Problem statements
- Inspirations from other products
- "I wish I had..." statements
- Vague concepts
- Multiple unrelated ideas
- Or nothing (start interactive session)

## Purpose

This command helps users who have ideas but haven't crystallized them into a specific project yet. It bridges the gap between "I have this vague idea" and "I'm ready to specify a project."

**Position in Flow**: BEFORE `/project-specify` (optional ideation phase)

**Output**: One or more project concepts ready for `/project-specify`

## Brainstorm Process

### Step 1: Idea Gathering

If user provided ideas in $ARGUMENTS:
- Parse and acknowledge each distinct idea/problem/inspiration
- Ask: "Is there anything else you'd like to add before we explore these?"

If no arguments provided, start interactive session:
```
💡 Let's brainstorm! Tell me about:
- Problems you want to solve
- Things that frustrate you
- Products you wish existed
- Features you want to build
- Industries or domains you're interested in
- Technologies you want to explore

Just brain dump - no structure needed. I'll help organize.
```

Continue gathering until user signals they're done or you have enough material.

### Step 2: Theme Clustering

Analyze the ideas and identify themes:

**Problem Themes**:
- What problems keep appearing?
- Who has these problems?
- How severe are they?

**Solution Themes**:
- What capabilities would address these?
- What technologies could help?
- What existing solutions are inadequate?

**User Themes**:
- Who are the potential users?
- What are their contexts?
- What motivates them?

**Domain Themes**:
- What industries or fields?
- What expertise is relevant?
- What regulations apply?

Present clustering:
```
📊 I see these themes in your ideas:

**Problems**:
1. [Theme 1] - Examples: [ideas that fit]
2. [Theme 2] - Examples: [ideas that fit]

**Potential Users**:
- [User type 1]: [their context]
- [User type 2]: [their context]

**Domain/Industry**:
- [Domain] with [specific focus]

Does this capture the essence? Anything to add or correct?
```

### Step 3: Concept Generation

For each viable theme combination, generate a project concept:

**Concept Template**:
```
📋 Project Concept: [Name]

**One-Liner**: [Single sentence describing the product]

**Problem Statement**: 
[Who] experiences [what problem] when [context], which causes [impact].

**Proposed Solution**:
A [product type] that [core capability], enabling users to [key benefit].

**Target Users**:
- Primary: [User type with context]
- Secondary: [Other user types]

**Key Features** (high-level):
1. [Feature 1]
2. [Feature 2]
3. [Feature 3]

**Differentiation**:
Why this is better than [existing solutions]: [reason]

**Complexity Estimate**:
- Scale: Level [0-4] (atomic → platform)
- Timeframe: [Rough estimate]
- Technical: [Key technical challenges]

**Confidence**: [High/Medium/Low] - [Why]
```

Generate 1-3 concepts depending on idea diversity.

### Step 4: Concept Exploration

For each concept, offer to explore further:
```
Would you like me to:
1. 🔍 Deep dive on "[Concept Name]" - explore feasibility, competition, risks
2. 🔀 Combine concepts - merge [A] and [B] into something new
3. ➕ Generate more variations - different angles on the same problem
4. ✅ Proceed with "[Concept Name]" to /project-specify
5. 💭 Keep brainstorming - add more ideas to the mix
```

### Step 5: Concept Refinement (if requested)

**Deep Dive includes**:
- Quick web search for existing solutions
- Identify potential competitors
- Technical feasibility assessment
- Risk identification
- Market opportunity (if applicable)

**Combination includes**:
- Merge complementary features
- Identify synergies
- Assess increased complexity
- Generate new unified concept

### Step 6: Output & Handoff

When user selects a concept to proceed with:

1. **Generate project description** suitable for `/project-specify`:
```
📝 Ready for Specification!

Here's your project description for /project-specify:

---
[Refined one-paragraph description that captures:
- What it is
- Who it's for
- Core problem solved
- Key differentiator]
---

Run this to continue:
/project-specify [paste description above]

Or I can run it now with this description. Proceed?
```

2. **Save brainstorm session** (optional):
```
Would you like me to save this brainstorm session?
→ Saves to specs/projects/brainstorm-[timestamp].md
→ Useful for revisiting rejected concepts later
```

## Brainstorm Artifacts

If saving, create:
```markdown
# Brainstorm Session: [Date]

## Raw Ideas
[User's original input]

## Themes Identified
### Problems
- [List]

### Users
- [List]

### Domains
- [List]

## Concepts Generated

### Concept 1: [Name]
[Full concept template]

### Concept 2: [Name]
[Full concept template]

## Selected Concept
[Name] - Proceeding to /project-specify

## Rejected Concepts (for future reference)
- [Concept]: [Why not selected]
```

## Integration with /speck

The `/speck` router should detect brainstorm intent:
- "I have an idea but it's not clear yet"
- "Help me figure out what to build"
- "I want to brainstorm"
- "Let's explore some ideas"
- Vague descriptions that lack specificity

Route to `/project-brainstorm` instead of `/project-specify`.

## Examples

### Example 1: Vague Idea
```
User: /project-brainstorm I want to build something with AI that helps people

Agent: 💡 That's a great starting point! Let's explore...
       - What kind of help? (productivity, health, learning, creativity?)
       - Which people? (students, professionals, elderly, general public?)
       - What frustrates you about current AI tools?
       
[Continues interactive exploration]
```

### Example 2: Multiple Ideas
```
User: /project-brainstorm I hate how hard it is to find good restaurants,
      and also I want to track my reading habits, and maybe something 
      with local events

Agent: 📊 I see three distinct areas in your ideas:
       1. **Discovery Problem**: Finding quality restaurants
       2. **Personal Tracking**: Reading habit management  
       3. **Local Awareness**: Event discovery
       
       These could be separate projects OR combined into a 
       "local lifestyle" platform. Let me generate concepts...
       
[Generates concepts for each and combined]
```

### Example 3: Problem Statement
```
User: /project-brainstorm It's so frustrating when I want to hang out with 
      friends but coordinating schedules is a nightmare

Agent: 🎯 Clear problem! Let me explore the space:
       
       **Problem**: Schedule coordination for social activities
       **Who**: Friend groups trying to meet up
       **Pain Points**: 
       - Back-and-forth messaging
       - Finding times that work for everyone
       - Picking activities/locations
       
       Let me generate concepts that address this...
       
[Generates 2-3 concepts: simple scheduler, social planning app, 
availability matching platform]
```

## Tips for Good Brainstorming

**Do**:
- Ask clarifying questions to understand intent
- Explore tangential ideas - they often lead somewhere
- Challenge assumptions about what the user "really" needs
- Suggest combinations and variations
- Be encouraging about half-formed ideas

**Don't**:
- Rush to specification too quickly
- Dismiss ideas as "too simple" or "already done"
- Force structure before exploration is complete
- Ignore the emotional/personal motivation behind ideas
- Forget to save interesting rejected concepts

## Research Integration

Use web search to:
- Find existing solutions (competitors)
- Validate that problem exists
- Identify market gaps
- Find technology options

Document findings in concept generation:
```
**Quick Research Findings**:
- Existing solutions: [List with limitations]
- Market gap: [What's missing]
- Technology: [What enables this now]
```

## Success Criteria

A successful brainstorm session:
- ✅ User feels heard and understood
- ✅ At least one concrete project concept generated
- ✅ Concept is specific enough for `/project-specify`
- ✅ User is excited about the direction
- ✅ Rejected concepts are preserved for future reference

