# speck-reprove — spine

---

## Purpose

**The problem this solves.** A v7 project has weeks of `PASS` / `UX-RC` / `SHIP-RC` claims produced under v7's verification-shaped gates. v8's thesis is that you cannot out-enumerate an agent optimizing for green, so **that green is suspect until re-established under evaluation**. Bumping the version does not make old claims true.

`/speck-reprove` is the migration analog of `/speck-catch-up`: it does NOT reconstruct artifacts (they already exist and are structurally fine) — it **re-proves the truth**. It refuses to inherit v7 green, caps the project honestly, maps each suspect claim to the v8 principle it is suspect under, and hands back a prioritized climb.

This is **not** a reset to zero. Nothing suspect is deleted; the historical claim is preserved and stamped `[pre-v8-proof]`. States climb back to `verified` only as real v8 evidence lands.

## When to Run

Run automatically when ANY of these is true (detect on engagement — this is First Action #1a, before feature work):

1. `.speck/.v8-reprove-needed` marker exists at workspace root (written by `speck upgrade` on the v7→v8 crossing).
2. `/recheck` / `staleness-check.sh` reports `V8_STALE` / `V8_REPROVE.P1` — a truth artifact stamped `speck v<7 or lower`.
3. User says "reprove", "bring this up to v8", "/speck-reprove".

**Block new feature work** until reprove is complete (no `/story-implement`, `/epic-plan`, or ship claim). Refuse with: *"This project was upgraded to Speck v8 but its truth is still v7-shaped green. Run `/speck-reprove` first."*

## Prerequisites

- Project at `specs/projects/<id>/` exists with v7 truth artifacts.
- Git history available (for stamp/claim archaeology).

## Context: $ARGUMENTS
