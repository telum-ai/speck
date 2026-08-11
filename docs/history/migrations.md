# Compatibility migration history

Speck still recognizes three upgrade boundaries because old project repositories can carry their exact marker files and artifact formats. This is compatibility machinery, not the current operating method.

| Legacy signal | `speck-migrate` stage | Why it remains |
|---------------|----------------|----------------|
| `.speck/.migration-needs-catchup` or `<!-- v7 MIGRATION SCAFFOLD -->` | `scaffold` | Reconstructs empty contract/state scaffolds and replaces unsupported legacy green with honest current state. |
| `.speck/.v8-reprove-needed`, `V8_STALE`, or `[pre-v8-proof]` | `proof` | Preserves historical claims while re-evaluating them under the current outcome and adversary gates. |
| `.speck/.v9-graph-needed` | `graph` | Builds the witness graph from older truth artifacts before normal graph checks run. |

The CLI detects version crossings and writes these markers in `packages/cli/lib/migrate.js`. The root AGENTS engagement ladder routes all of them through `speck-migrate`, oldest stage first. Its executable load contract exposes only the active procedure and removes a marker only after repaired state is recorded.

The old version names remain in marker filenames, sentinels, migration IDs, and legacy artifact names because changing them would make existing repositories unreachable. They should not appear in current explanations unless an exact compatibility mechanism requires them.

Release rationale is preserved in `docs/history/north-stars/` and `CHANGELOG.md`.
