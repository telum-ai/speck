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

DEC ID BANDS (concurrent multi-epic execution):
- Project-level: DEC-0001–DEC-0099
- Epic E###: DEC-{NN}01–DEC-{NN}99 (E002 → DEC-0201+)
- Log via /speck-decision-log only — never hand-assign IDs on parallel branches

PLACEHOLDER CONVENTION:
  Tokens marked  REPLACE_BEFORE_SHIP: <hint>  MUST be filled before this artifact
  can claim ship-readiness. /speck-recheck greps for them.
-->

**Project**: REPLACE_BEFORE_SHIP: PROJECT_NAME
**Project ID**: `REPLACE_BEFORE_SHIP: project-id`
**Speck Version**: REPLACE_BEFORE_SHIP: Speck version

---

## How to Use This Log

1. At every phase boundary, the active skill enumerates the decisions being locked
2. For each decision: provide 3+ alternatives + tradeoff + chosen + rationale + SHA + date
3. Each decision gets a unique ID: `DEC-<NNNN>`
4. To revisit a decision: add a NEW entry that supersedes the old one (`Supersedes: DEC-XXXX`)
5. Never edit a locked entry — append the supersession

---

<!-- CATCH-UP-ONLY: Retroactive Reconstruction Caveat
This block is COMMENTED OUT by default. /speck-catch-up uncomments it when the
log is being reconstructed from git history rather than logged at decision time.
Leave commented for greenfield projects.

## ⚠️ Retroactive Reconstruction Caveat

This log was reconstructed during `/speck-catch-up` (methodology import/migration). Entries
marked `Reconstructed: true` were not logged at the time the decision was made;
they were mined from git history (commit messages, learning tags, PR descriptions).

For each retroactive entry:

- The **chosen option** reflects what was actually shipped (verified from code state)
- The **alternatives listed** are plausible reconstructions of what a reasonable
  team would have weighed at the time — NOT a record of what was actually discussed
- The **rationale** is inferred from commit messages and contemporaneous context
- Treat each retroactive entry as a **hypothesis about past intent**, not as history

Going forward, new decisions are logged at decision time and do not carry this
caveat. The retroactive entries remain in place as a starting point for any
future revisit / supersession.
-->

---

## Decision Index

| ID | Date | SHA | Title | Phase | Status |
|----|------|-----|-------|-------|--------|
| DEC-0001 | YYYY-MM-DD | abc1234 | [Title] | specify | LOCKED |
| DEC-0002 | YYYY-MM-DD | abc1234 | [Title] | product-contract | LOCKED |
| DEC-0003 | YYYY-MM-DD | def5678 | [Title] | evidence-contract | LOCKED |

---

## Decisions

### DEC-0001 — REPLACE_BEFORE_SHIP: Decision Title

- **Phase**: REPLACE_BEFORE_SHIP: project-specify / product-contract / evidence-contract / project-plan / epic-plan / etc.
- **Date**: REPLACE_BEFORE_SHIP: YYYY-MM-DD
- **SHA at decision time**: `REPLACE_BEFORE_SHIP: abc1234`
- **Status**: REPLACE_BEFORE_SHIP: LOCKED | SUPERSEDED-BY-<ID> | OPEN
- **Owner**: REPLACE_BEFORE_SHIP: AI agent / human / both
- **Reconstructed**: false  *(set to `true` and add `**Reconstructed from**: <git refs>` ONLY if /speck-catch-up wrote this entry)*

**Question**: REPLACE_BEFORE_SHIP: What was being decided?

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

*[as of SHA `<git_sha_short>` | verified `<date>` | speck]*
