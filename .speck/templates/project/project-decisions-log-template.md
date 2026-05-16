---
speck_version: 7.0
artifact_type: decisions-log
append_only: true
---

# Project Decisions Log

<!--
APPEND-ONLY LOG. Never edit or delete past entries; supersede instead.

At every phase boundary (specify → clarify → plan → architecture → product-contract
→ evidence-contract → epic-plan → story-plan → implement, etc.) the agent MUST log
the decisions that locked at this boundary. This is unconditional discipline — not
dependent on play level or human hands-on intensity.

Format: one decision per H3 (###) section with frontmatter-style metadata.
-->

**Project**: [PROJECT_NAME]
**Project ID**: `[PROJECT_ID]`
**Speck Version**: 7.0.0

---

## How to Use This Log

1. At every phase boundary, the active skill enumerates the decisions being locked
2. For each decision: provide 3+ alternatives + tradeoff + chosen + rationale + SHA + date
3. Each decision gets a unique ID: `DEC-<NNNN>`
4. To revisit a decision: add a NEW entry that supersedes the old one (`Supersedes: DEC-XXXX`)
5. Never edit a locked entry — append the supersession

---

## Decision Index

| ID | Date | SHA | Title | Phase | Status |
|----|------|-----|-------|-------|--------|
| DEC-0001 | YYYY-MM-DD | abc1234 | [Title] | specify | LOCKED |
| DEC-0002 | YYYY-MM-DD | abc1234 | [Title] | product-contract | LOCKED |
| DEC-0003 | YYYY-MM-DD | def5678 | [Title] | evidence-contract | LOCKED |

---

## Decisions

### DEC-0001 — [Decision Title]

- **Phase**: [project-specify / product-contract / evidence-contract / project-plan / epic-plan / etc.]
- **Date**: YYYY-MM-DD
- **SHA at decision time**: `abc1234`
- **Status**: LOCKED | SUPERSEDED-BY-[ID] | OPEN
- **Owner**: [AI agent / human / both]

**Question**: [What was being decided?]

**Alternatives considered**:

1. **[Option A name]** — [1-sentence description]
   - Strengths: [why it's appealing]
   - Weaknesses: [where it falls short]
   - Score: [if quantifiable]

2. **[Option B name]** — [1-sentence description]
   - Strengths:
   - Weaknesses:
   - Score:

3. **[Option C name]** — [1-sentence description]
   - Strengths:
   - Weaknesses:
   - Score:

**Chosen**: [Option name]

**Rationale**: [2-4 sentences. Why this option, not the others. Specific to THIS project's promise / context / constraint.]

**Consequences accepted**: [What this choice commits us to. What we're giving up.]

**Revisit if**: [Trigger conditions that would warrant reopening — e.g., "scale exceeds X", "third-party Y becomes unviable", "the persona's primary JTBD shifts"]

**Evidence**: [Link to research, LARP findings, or similar that informed this choice]

---

### DEC-0002 — [Decision Title]

[same structure]

---

<!--
Append new decisions here. NEVER edit above.

When superseding:
- New entry gets a new ID
- New entry's frontmatter sets `Supersedes: DEC-XXXX`
- Old entry's `Status` field is updated to `SUPERSEDED-BY-<new ID>`
  (this is the ONLY field that may be edited on an old entry — it's a forward pointer)
-->

---

*[as of SHA `<git_sha_short>` | verified `<date>` | speck v7.0.0]*
