# Pattern: Raw-Enum Label Shape — a PGENUM Written as the Python Member Instead of `.value`

**Category**: testing (class-gate recipe)
**Discovered**: 2026-07, issue #100 §1b
**Validated In**: Splang (Speck v9.5.0) — `backend/tests/unit/test_pgenum_label_shape.py`
**Occurrences**: recurring class anywhere a Python enum backs a Postgres native enum column

## Problem

A Python `Enum` (or `IntEnum`/`StrEnum`) member gets written into an enum-typed Postgres column
without going through `.value`. Depending on the ORM and driver, this sometimes "works" (the driver
coerces `repr()`/`str()` of the member to something that happens to match a valid label) and
sometimes silently writes the wrong label, or a label that only coincidentally matches today's enum
member names — a rename of the Python enum's member names then breaks every row written the wrong
way, invisibly, because the column still holds a string and the write path never errored.

## Solution

**Mechanism.** A Python enum member and its Postgres label are two different types wearing the same
name. `SomeEnum.ACTIVE` and `"active"` are not interchangeable at the type level; whether writing the
member object directly "works" depends on ORM coercion behaviour that is not guaranteed and not
always tested.

**The tell.** Grep every write to an enum-typed column for a bare enum member reference
(`SomeEnum.ACTIVE`) not wrapped in `.value` (or the ORM's equivalent explicit coercion).

**Gate shape.** A unit test asserting the **shape** every enum write must take — that the value
handed to the ORM/driver for an enum column is always the primitive label, never the enum member
object — run against every model/column pair that uses a Postgres native enum type. This is closer
to a lint rule than a runtime scanner: it can be checked statically for known enum-typed columns.

**The bounding exception.** ORMs that guarantee coercion of enum members to their `.value` at the
boundary (some do, explicitly, as a documented feature) make this a non-issue for that specific ORM
version — but the guarantee should be pinned to a test of its own (does the ORM actually coerce, or
does it merely happen to today), because an ORM upgrade silently changing that behaviour is exactly
how this class re-appears in a codebase that "already fixed" it.

## When to Use

- Any codebase pairing a Python (or similarly enum-typed language) ORM layer with native Postgres
  enum columns.

## When NOT to Use

- Enum columns implemented as plain `VARCHAR` with an application-level check constraint instead of
  a native Postgres enum type — the failure mode and the fix both differ (see
  `recipe-duplicated-rule-schema-type-parity.md` for the constraint-vs-type-union class instead).

## Related Patterns

- `recipe-duplicated-rule-schema-type-parity.md` — the sibling class for when the enum's source of
  truth is duplicated across a migration and an application-level type, rather than mis-serialized
  at the write boundary.

## Source

- Reference implementation: Splang `backend/tests/unit/test_pgenum_label_shape.py`, verified at HEAD
  `89468af1` (Speck v9.5.0).
- Filed as: ISSUE #100 §1b, table row 3.
