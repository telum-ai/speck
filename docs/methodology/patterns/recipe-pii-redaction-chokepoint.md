# Pattern: PII Redaction Chokepoint + Scanner — PII Reaching a Log Call

**Category**: testing (class-gate recipe)
**Discovered**: 2026-07, issue #100 §1, §1a
**Validated In**: Splang (Speck v9.5.0) — `backend/scripts/check_pii_logging.py` +
`backend/tests/unit/test_pii_logging_guard.py` + `backend/tests/unit/test_pii_logging_gate_blind_spots.py`
**Occurrences**: the scanner itself had 3 recorded blind spots on first ship (A1/A2/A3 below)

## Problem

A log call — anywhere in the codebase, through any of the ways a codebase actually spells "log this"
— includes a PII-bearing field (email, phone, a raw contact identifier) in its message or its
structured fields. This is easy to catch for the obvious case (`logger.info(f"user email:
{email}")`) and easy to miss for every non-obvious spelling: a differently-named logger instance, a
logging call reached through a helper, a field named something the scanner's allowlist doesn't know
about.

## Solution

**Mechanism.** PII reaches a log sink through many syntactic routes, and a scanner that recognizes
only the most common one (`logger.info(...)` on a variable literally named `logger`/`log`/`logging`)
reports a clean scan while real leaks reach production logs through every route it didn't model.

**The tell.** Grep for every **binding** of a logging object in the codebase, not just every call —
`logging.getLogger(...)` assigned to any variable name is a logging binding, whatever it's called.
Then grep every call on any of those bindings, not only the ones matching a fixed name pattern.

**Gate shape — a chokepoint scanner, run as a required CI step**, that:
1. Enumerates every logger **binding** (not just the conventionally-named ones) before scanning any
   calls, and asserts that enumeration's count is **non-zero and reasonable** for the codebase's
   size — an empty binding set on a codebase that obviously logs somewhere is itself the failure
   signal (see mechanic 3 below).
2. Scans every call on every enumerated binding for PII-shaped field names or f-string interpolation
   of a PII-bearing variable, against a maintained name list.
3. **Treats a parse failure as FAIL, never as an empty (clean-looking) result.** This is the load-
   bearing mechanic: a scanner that catches its own `SyntaxError`, prints it to stderr, and returns
   `[]` produces the exact same signal as a file with zero log calls. The one state where the scanner
   inspected nothing must not read as PASS.

**Splang's three recorded blind spots, kept here because they are the class's own best teaching
example** (see `class-gate-not-a-third-fix.md`'s "scanner's own blind spots" sub-pattern for the
general form): (A1) the scanner recognized a receiver only when spelled `logger`/`log`/`logging` —
ten real call sites through an inline `logging.getLogger(...).warning(...)` or a differently-named
binding (`_signal_logger`) scanned zero. (A2) A `SyntaxError` was caught and `[]` returned — the same
value a clean file returns. (A3) The PII name list had `phone`/`email` but not `contact`, the name
this codebase actually uses for the raw value passed to `hash_contact(contact)`.

**The bounding exception.** A scanner of this shape cannot see PII flowing through an opaque
transform before it reaches the log call (e.g. a hash that is reversible in practice, or a field
whose name gives no hint of its content). It catches the syntactic shape, not the semantic content —
name the boundary explicitly rather than claiming full coverage.

## When to Use

- Any codebase with a compliance or privacy requirement around what reaches application logs.
- Especially where logging is done through more than one binding style (direct `logging` module use
  alongside a wrapped/named logger).

## When NOT to Use

- Codebases with a single, structurally-enforced logging chokepoint (e.g. all logging goes through
  one typed function whose signature makes a PII field impossible to pass unredacted) — in that case
  the type system is the gate and a text scanner is redundant.

## Related Patterns

- `class-gate-not-a-third-fix.md` — the "scanner's own blind spots" sub-pattern this recipe is the
  canonical worked example of.
- `inverted-polarity-exception-registry.md` — if some log calls legitimately need to carry a
  PII-shaped field (rare, but real — e.g. an audit log with a documented, access-controlled purpose),
  express those as registry exceptions rather than weakening the scanner's detection.

## Source

- Reference implementation: Splang `backend/scripts/check_pii_logging.py` +
  `backend/tests/unit/test_pii_logging_guard.py` + `backend/tests/unit/test_pii_logging_gate_blind_spots.py:1-22`,
  verified at HEAD `89468af1` (Speck v9.5.0). Blind-spot quotes verbatim from the blind-spot test
  file's own docstrings.
- Filed as: ISSUE #100 §1b table row 4, §1a.
