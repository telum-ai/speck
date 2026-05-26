/**
 * Maps Speck releases to feedback items they address.
 * Shown after `speck upgrade` so users know which inline patches / CI overrides can be dropped.
 */

/** @type {{ version: string; items: { id: string; summary: string }[] }[]} */
export const FEEDBACK_ADDRESSED_BY_RELEASE = [
  {
    version: '7.8.0',
    items: [
      { id: 'H1', summary: 'Command-type Stop hook (lifecycle-scoped)' },
      { id: 'H2', summary: 'SPECK-managed settings blocks + reconcile-settings' },
      { id: 'H3', summary: 'SETTINGS_DRIFT detection on /recheck' },
      { id: 'H4', summary: 'Auto-reconcile on speck upgrade / init' },
    ],
  },
  {
    version: '7.9.0',
    items: [
      { id: '—', summary: 'larp-play, compress, visual assets pipeline, readiness evidence gates' },
    ],
  },
  {
    version: '7.9.1',
    items: [
      { id: 'V1', summary: 'pre-commit-hook empty-array unbound variable' },
      { id: 'V2', summary: 'Multi-line bracket placeholder false-positive' },
      { id: 'V3', summary: 'Fenced code-block placeholder skip' },
      { id: 'V4', summary: 'Generic-ID descriptive-reference filter' },
      { id: 'V5', summary: 'validate-story-spec Draft (Placeholder) lifecycle gating' },
    ],
  },
  {
    version: '7.9.2',
    items: [
      { id: '—', summary: 'larp-play unused import removed' },
    ],
  },
  {
    version: '7.10.0',
    items: [
      { id: 'P1', summary: 'Version-pin freshness check in epic-tech-spec template' },
      { id: 'P2', summary: 'typecheck in tasks-template verification phase' },
      { id: 'P3', summary: '/story and /epic orchestrator driving-pattern clarification' },
      { id: 'P4', summary: 'Upgrade output lists addressed feedback items' },
      { id: 'P5', summary: 'Feedback file template at .speck/templates/feedback/template.md' },
      { id: 'P6', summary: 'Constitution-as-code pattern doc' },
      { id: 'V6', summary: 'validate-artifact-docs aligned to v7 canonical artifacts' },
      { id: 'V7', summary: 'Recipe extends: chain validation' },
    ],
  },
];

function parseVersion(v) {
  return parseFloat(String(v).replace(/^v/, ''));
}

/**
 * @param {string} fromVersion
 * @param {string} toVersion
 * @returns {{ version: string; items: { id: string; summary: string }[] }[]}
 */
export function getFeedbackAddressedBetween(fromVersion, toVersion) {
  const from = parseVersion(fromVersion);
  const to = parseVersion(toVersion);
  if (Number.isNaN(from) || Number.isNaN(to) || to <= from) {
    return [];
  }
  return FEEDBACK_ADDRESSED_BY_RELEASE.filter((entry) => {
    const v = parseVersion(entry.version);
    return v > from && v <= to;
  });
}

/**
 * @param {string} fromVersion
 * @param {string} toVersion
 */
export function printFeedbackAddressed(fromVersion, toVersion) {
  const entries = getFeedbackAddressedBetween(fromVersion, toVersion);
  if (entries.length === 0) return;

  console.log('\n📬 Addresses feedback from prior sessions:');
  for (const entry of entries) {
    console.log(`   ${entry.version}:`);
    for (const item of entry.items) {
      console.log(`     • ${item.id} — ${item.summary}`);
    }
  }
  console.log('\n   If you applied inline patches for fixed items, drop them after verifying upgrade.');
  console.log('   Remove any `continue-on-error: true` CI overrides for fixed validators.');
}
