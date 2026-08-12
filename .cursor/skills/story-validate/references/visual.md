# Adjudicate visual evidence

Visual testing is an evidence producer selected from the active recipe during
LARP. Validation does not load a host procedure or create captures.

- Require the LARP evidence to cite a visual manifest for the build SHA and
  active recipe host. Missing or mismatched host evidence → route back to
  `visual-testing` through `speck-larp`.
- Inspect the cited pixels directly. Check impacted screens, required states,
  interaction feedback, accessibility output, and runtime logs against
  `design-system.md`, `ux-strategy.md`, `ui-spec.md`, and epic wireframes when present.
- `NEEDS_WORK` or `UGLY` caps at `IMPL-GREEN`. A screenshot path or green
  accessibility scan alone does not establish FELT-GOOD or TASTE.
