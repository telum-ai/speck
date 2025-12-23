# Domain Model: [PROJECT NAME]

**Project ID**: [PROJECT_ID]  
**Domain**: [Primary domain/field]  
**Created**: [DATE]  
**Last Updated**: [DATE]  
**Version**: 1.0.0

---

## 📊 Information Sources

**Traceability**: This domain model was created from the following sources:

- **User Input**: Subject matter expertise provided during project setup
- **Research**: Domain-specific research conducted via JIT research pattern
- **SME References**: [List any subject matter experts consulted]
- **Literature**: [Key sources, papers, standards referenced]

**Information Flow**:
```
User domain expertise + JIT research
  ↓
domain-model.md (this document)
  ↓
Informs: project-plan → epic-specify → story-specify → story-plan → validation
```

---

## 🎯 Domain Overview

### What Domain Is This?

**Primary Domain**: [e.g., Exercise Science, Healthcare, Financial Services, E-commerce]

**Domain Description**:
[2-3 paragraphs explaining the domain, its scope, and why domain expertise matters for this product. What makes this domain unique? What specialized knowledge is required?]

**Domain Scope for This Project**:
- **In Scope**: [Aspects of the domain this product addresses]
- **Out of Scope**: [Aspects of the domain we're NOT addressing]
- **Adjacent Domains**: [Related domains that may interact]

### Why Domain Expertise Matters

[Explain the consequences of getting domain knowledge wrong. What could go wrong if the product doesn't respect domain principles? Safety implications? User trust issues?]

---

## 📖 Ubiquitous Language (Glossary)

*Canonical terminology for this project. All specs, code, and UI MUST use these terms consistently.*

### Core Terms

| Term | Definition | Usage Notes | Avoid (Synonyms) |
|------|------------|-------------|------------------|
| [Term 1] | [Precise definition] | [When/how to use] | [Don't use: X, Y, Z] |
| [Term 2] | [Precise definition] | [When/how to use] | [Don't use: X, Y, Z] |
| [Term 3] | [Precise definition] | [When/how to use] | [Don't use: X, Y, Z] |

### Measurement & Units

| Term | Definition | Standard Unit | Conversion Notes |
|------|------------|---------------|------------------|
| [Measurement 1] | [What it measures] | [Unit] | [How to convert] |
| [Measurement 2] | [What it measures] | [Unit] | [How to convert] |

### Acronyms & Abbreviations

| Acronym | Full Form | Definition |
|---------|-----------|------------|
| [ABC] | [Full form] | [What it means in context] |

---

## 🧠 Core Domain Concepts

*The fundamental entities and concepts in this domain. These inform data models and system design.*

### Primary Entities

#### [Entity 1 Name]

**Definition**: [What this entity represents in the domain]

**Attributes**:
- `[attribute_name]`: [Type] - [Description]
- `[attribute_name]`: [Type] - [Description]

**Relationships**:
- Has many: [Related entities]
- Belongs to: [Parent entities]
- Associated with: [Peer entities]

**Lifecycle/States**:
1. [State 1] → [State 2] → [State 3]

**Domain Rules**:
- [Rule that applies to this entity]
- [Another rule]

#### [Entity 2 Name]

[Same structure as above...]

### Entity Relationship Diagram

```
[ASCII diagram or description of how entities relate]

Example:
┌─────────┐     ┌─────────────┐     ┌──────────┐
│  User   │────▶│   Workout   │────▶│ Exercise │
└─────────┘     └─────────────┘     └──────────┘
                      │                   │
                      ▼                   ▼
               ┌───────────┐      ┌─────────────┐
               │    Set    │      │ MuscleGroup │
               └───────────┘      └─────────────┘
```

### Concept Hierarchies

*Taxonomies and classification systems in the domain*

```
[Hierarchy Name]
├── [Category 1]
│   ├── [Subcategory 1.1]
│   └── [Subcategory 1.2]
├── [Category 2]
│   ├── [Subcategory 2.1]
│   └── [Subcategory 2.2]
└── [Category 3]
```

---

## ⚖️ Domain Rules & Invariants

*Business rules that must ALWAYS hold true. Violations indicate bugs or design flaws.*

### Invariants (Must ALWAYS Be True)

| ID | Rule | Rationale | Enforcement |
|----|------|-----------|-------------|
| INV-001 | [Rule statement] | [Why this must be true] | [How to enforce: validation, constraint, etc.] |
| INV-002 | [Rule statement] | [Why this must be true] | [How to enforce] |
| INV-003 | [Rule statement] | [Why this must be true] | [How to enforce] |

### Business Rules (Conditional Logic)

| ID | Condition | Rule | Exception Handling |
|----|-----------|------|-------------------|
| BR-001 | When [condition] | Then [action/constraint] | [What to do if violated] |
| BR-002 | When [condition] | Then [action/constraint] | [What to do if violated] |

### Validation Rules

| Field/Entity | Validation | Error Message |
|--------------|------------|---------------|
| [field] | [Rule: range, format, etc.] | [User-friendly error] |
| [field] | [Rule] | [Error message] |

---

## 🔬 Domain Principles

*Scientific, industry, or established principles that guide product decisions.*

### Foundational Principles

#### Principle 1: [Name]

**Statement**: [One sentence summary]

**Explanation**: [Detailed explanation of the principle]

**Source**: [Research paper, industry standard, SME]

**Application to Product**:
- [How this principle affects feature X]
- [How this principle affects feature Y]

**Violations to Avoid**:
- ❌ [Anti-pattern that violates this principle]
- ❌ [Another anti-pattern]

#### Principle 2: [Name]

[Same structure...]

### Industry Standards

| Standard | Description | Compliance Level | Reference |
|----------|-------------|------------------|-----------|
| [Standard name] | [What it covers] | [Must/Should/May] | [Link/citation] |

### Best Practices

- **[Practice 1]**: [Description and rationale]
- **[Practice 2]**: [Description and rationale]
- **[Practice 3]**: [Description and rationale]

---

## 📚 Evidence Base

*Research, citations, and authoritative sources that inform domain decisions.*

### Key Research

| Topic | Finding | Source | Confidence |
|-------|---------|--------|------------|
| [Topic] | [Key finding relevant to product] | [Citation] | High/Medium/Low |
| [Topic] | [Key finding] | [Citation] | High/Medium/Low |

### Authoritative Sources

**Primary Sources** (directly referenced):
1. [Author]. "[Title]." [Publication], [Year]. [DOI/URL]
2. [Author]. "[Title]." [Publication], [Year]. [DOI/URL]

**Secondary Sources** (background knowledge):
- [Source description and relevance]

### Subject Matter Experts

| Name/Role | Expertise Area | How Consulted | Key Insights |
|-----------|----------------|---------------|--------------|
| [Name] | [Area] | [Interview/Review/etc.] | [What they contributed] |

---

## 🚫 Domain Constraints

*What is impossible, unsafe, or inadvisable in this domain.*

### Physical/Logical Constraints

| Constraint | Description | Why It Matters |
|------------|-------------|----------------|
| [Constraint] | [What cannot happen] | [Consequence of violating] |
| [Constraint] | [What cannot happen] | [Consequence of violating] |

### Safety Constraints

| Constraint | Risk Level | Mitigation Required |
|------------|------------|---------------------|
| [Safety constraint] | Critical/High/Medium | [How product must handle] |

### Regulatory Constraints

| Regulation | Requirement | Compliance Approach |
|------------|-------------|---------------------|
| [Regulation name] | [What it requires] | [How we comply] |

---

## 🔄 Domain Evolution

*How domain knowledge may change and how to handle updates.*

### Known Uncertainties

- [Area where domain knowledge is evolving]
- [Area where there's debate among experts]

### Update Triggers

This domain model should be reviewed when:
- [ ] New research contradicts current principles
- [ ] User feedback reveals domain misunderstanding
- [ ] Regulatory changes affect domain rules
- [ ] SME review identifies gaps

### Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | [DATE] | Initial domain model | [Name] |

---

## ✅ Domain Model Checklist

### Completeness Check
- [ ] All core domain terms defined in glossary
- [ ] Primary entities documented with attributes and relationships
- [ ] Key invariants identified and documented
- [ ] Foundational principles captured with sources
- [ ] Evidence base includes authoritative references
- [ ] Constraints clearly stated

### Consistency Check
- [ ] Terminology is consistent throughout
- [ ] No conflicting rules or principles
- [ ] Entity relationships are bidirectionally correct
- [ ] Validation rules align with invariants

### Usability Check
- [ ] Glossary terms are used in all project specs
- [ ] Rules are specific enough to validate against
- [ ] Principles provide clear guidance for decisions
- [ ] Evidence base is accessible/verifiable

---

**Next Steps**:
1. Reference this domain model in all epic and story specifications
2. Use glossary terms consistently in code (variable names, comments, UI text)
3. Validate data models against domain entities
4. Check implementations against invariants and rules
5. Update this document as domain understanding deepens
