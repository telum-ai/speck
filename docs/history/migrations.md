# Compatibility migration history

Speck still recognizes three upgrade boundaries because old project repositories can carry their exact marker files and artifact formats. This is compatibility machinery, not the current operating method.

| Legacy signal | Recovery route | Why it remains |
|---------------|----------------|----------------|
| `.speck/.migration-needs-catchup` or `<!-- v7 MIGRATION SCAFFOLD -->` | `speck-catch-up` | Reconstructs empty contract/state scaffolds and replaces unsupported legacy green with honest current state. |
| `.speck/.v8-reprove-needed`, `V8_STALE`, or `[pre-v8-proof]` | `speck-reprove` | Preserves historical claims while re-evaluating them under the current outcome and adversary gates. |
| `.speck/.v9-graph-needed` | `speck-graph-up` | Builds the witness graph from older truth artifacts before normal graph checks run. |

The CLI detects version crossings and writes these markers in `packages/cli/lib/migrate.js`. The root AGENTS engagement ladder detects them; each recovery skill owns the semantic procedure and removes its marker only after the repaired state is recorded.

The old version names remain in marker filenames, sentinels, migration IDs, and legacy artifact names because changing them would make existing repositories unreachable. They should not appear in current explanations unless an exact compatibility mechanism requires them.

Release rationale is preserved in `docs/history/north-stars/` and `CHANGELOG.md`.
