# Adjudicate UI LARP evidence

LARP is a proof producer that runs before validation. Validation does not run
or load the LARP procedure.

- Require checked-in `larp-recordings/<sha>-<persona>-findings.md` for the exact
  build under claim. Missing, wrong-SHA, or incomplete evidence → STOP and
  route back to `speck-larp`.
- Cross-examine whether the recording reached the primary job from a cold
  start, covered naive-hostile DOES-IT-WORK and IS-IT-GOOD judgment, and names
  blockers rather than treating unreachable surfaces as passes.
- High-impact decisions require a recorded `speck-premise-challenge` verdict.
  Missing or failed challenge caps at `IMPL-GREEN`/`INTEGRATION-GREEN`.
- Do not manufacture a LARP verdict inside `validation-report.md`; cite the
  producer artifact and state what its instrument can actually prove.
