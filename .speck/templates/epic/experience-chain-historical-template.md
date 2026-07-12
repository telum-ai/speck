---
speck_version: 8.0
artifact_type: experience-chain-historical
required_for: ui-epics-pre-v7
brownfield_exempt: true
---

# Experience Chain (Historical) — REPLACE_BEFORE_SHIP: EPIC_NAME

<!--
THIS IS A BROWNFIELD EXEMPTION ARTIFACT.

Scaffolded by /speck-catch-up for UI epics that pre-date v7. The epic shipped
without an experience-chain.md, and reverse-engineering one fully would block
catch-up indefinitely. Instead, this lightweight historical record:

  1. Acknowledges the epic exists without a canonical chain
  2. Lists the screens that SHIPPED (extracted from story specs + git history)
  3. Sets a re-validation trigger: when this epic enters re-validation,
     /epic-validate generates the full experience-chain.md on the fly from
     this stub + the (then-current) implementation
  4. Marks `brownfield_exempt: true` so /epic-plan does not refuse to run

This file does NOT satisfy the v7 requirement for NEW epics. New epics MUST
have a real experience-chain.md authored upfront. This exemption is one-time,
per-epic, and ONLY for epics that pre-dated v7 migration.
-->

**Epic**: REPLACE_BEFORE_SHIP: E### - Name
**Project**: `REPLACE_BEFORE_SHIP: project-id`
**Status**: `brownfield_exempt` — full chain pending re-validation
**Scaffolded by**: `/speck-catch-up` on REPLACE_BEFORE_SHIP: YYYY-MM-DD

---

## 1. Shipped screens (auto-extracted)

*From this epic's story specs + git history. The catch-up skill populates this list. Order is best-effort; the agent should walk the implementation to confirm.*

| Order | Screen / route | Origin story | Shipping SHA (first) | Notes |
|-------|----------------|--------------|----------------------|-------|
| 1 | REPLACE_BEFORE_SHIP: screen-1 | REPLACE_BEFORE_SHIP: S001 | REPLACE_BEFORE_SHIP: sha | (any) |
| 2 | REPLACE_BEFORE_SHIP: screen-2 | REPLACE_BEFORE_SHIP: S002 | REPLACE_BEFORE_SHIP: sha | (any) |

---

## 2. Known seams (best effort)

*Where this epic touches other epics. Catch-up infers these from imports / cross-references / shared state. Mark `inferred` vs `confirmed`.*

| Other epic | Where they touch | Confidence |
|------------|-------------------|------------|
| REPLACE_BEFORE_SHIP: other-epic | REPLACE_BEFORE_SHIP: handoff point | inferred / confirmed |

---

## 3. Re-validation trigger

When this epic is next subject to `/epic-validate`:

1. The validator detects `brownfield_exempt: true` in this artifact
2. Instead of failing, it generates the FULL `experience-chain.md` on the fly:
   - Walks the implementation
   - Captures actual screens + transitions + emotional progression
   - Cross-references the user-journey.md if it exists
3. Writes the generated chain as `experience-chain.md` alongside this file
4. Marks this historical artifact as `superseded: true` + links to the generated chain
5. From that point on, the epic is held to v7 standards like any new epic

This deferred-generation pattern keeps catch-up bounded (does NOT require reverse-engineering all chains upfront) while ensuring that ANY future validation of this epic produces the real artifact.

---

## 4. Why this exemption exists

*Trust receipt for future agents reading this file.*

This epic was implemented under Speck v6, which did not require `experience-chain.md`. The v7 migration could have:

1. **Failed catch-up** until every UI epic has a hand-written chain (blocks catch-up for weeks on large projects)
2. **Auto-generated chains during catch-up** (produces low-quality fiction since the agent isn't walking the live implementation at catch-up time)
3. **Brownfield exemption** with deferred real-chain generation at re-validation time (CHOSEN — bounded catch-up effort, real chain when actually needed)

Speck v7.2+ chose option 3. Future agents: do not delete this exemption marker without first generating the full `experience-chain.md` via `/epic-validate` re-walk.

---

*[as of SHA `REPLACE_BEFORE_SHIP: git_sha_short` | scaffolded REPLACE_BEFORE_SHIP: date | speck vX.Y.Z]*
