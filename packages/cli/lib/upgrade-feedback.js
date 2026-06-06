/**
 * Maps Speck releases to feedback items they address.
 * Shown after `speck upgrade` so users know which inline patches / CI overrides can be dropped.
 */

/** @type {{ version: string; items: { id: string; summary: string }[] }[]} */
export const FEEDBACK_ADDRESSED_BY_RELEASE = [
  {
    version: '7.13.2',
    items: [
      { id: 'S1', summary: 'Ambition-aware UI path in epic-specify — Redesign Ambition blocks Rubric Mode default' },
      { id: 'S2', summary: 'Promise-coverage (unaddressed-promise gap) check in epic-analyze and project-analyze' },
      { id: 'S3', summary: 'Forbidding-context filter for banned-language-lint (NOT This / Banned columns)' },
      { id: 'S4', summary: 'banned-language-lint --staged + pre-commit hook wiring' },
      { id: 'S5', summary: 'validate-epic-spec X-Y range parse + overview awk fix' },
      { id: 'S6', summary: 'speck-decision-log index reconciliation from DEC- headings' },
      { id: 'S7', summary: 'staleness-check false-DRIFT fix via rev-list commit count' },
    ],
  },
  {
    version: '7.13.1',
    items: [
      { id: 'F1', summary: 'Form Validation Matrix in ui-spec-template.md and story-ui-spec' },
      { id: 'F2', summary: 'Anti-Surrogate Rules in speck-audit (prohibit API bypass of UI)' },
      { id: 'F3', summary: 'Pass-Count Honesty & Test Hygiene in evidence-contract' },
      { id: 'F4', summary: 'Keystone Dependencies convention + skip-with-reason rules' },
      { id: 'F5', summary: 'JTBD cold-start LARP as centerpiece of epic validation' },
      { id: 'F6', summary: 'Mandatory validation report Deferrals/Not Verified section' },
      { id: 'F7', summary: 'validate-story-spec resilience to Status vs Current State header' },
      { id: 'F8', summary: '/harden flow and harden-report template for post-validate fixing' },
      { id: 'F9', summary: 'Artifact-Config Drift as SHIP-RC only class to prevent false UX-RC claims' },
      { id: 'F10', summary: 'Boundary-crossing try-catch error attribution check' },
    ],
  },
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
    version: '7.12.1',
    items: [
      { id: 'M1', summary: 'Rendering Gotchas in primitives registry + audit/visual-quality grep for pixel-level anti-patterns' },
      { id: 'M2', summary: 'Asset single-source norm + asset-drift-check.sh for duplicate SVG geometry (ASSET_DRIFT.P1 on /recheck)' },
      { id: 'M3', summary: 'Brownfield UI Rubric Mode in /epic-specify — shared Screen Rubric instead of duplicate wireframes' },
    ],
  },
  {
    version: '7.11.0',
    items: [
      { id: 'P1a', summary: 'Quality Judgment loop (Judge -> Fix -> Re-prove) added to evidence-contract' },
      { id: 'P1b', summary: 'Numeric 0-10 JTBD scoring with hard caps and anti-inflation rules' },
      { id: 'P1c', summary: 'Density budget prompt added to experience-chain and ui-spec templates' },
      { id: 'P1d', summary: 'Signal -> Reaction Ledger added to product-contract' },
      { id: 'P1e', summary: 'Longitudinal Proof Mode and timeline.jsonl requirements' },
      { id: 'P2a', summary: 'Human Language Pass guidelines added to product-contract and validation reports' },
      { id: 'P2b', summary: 'speck validate --active-only and pre-commit reconcile hint for legacy projects' },
      { id: 'P2c', summary: 'LARP Runway and build fingerprinting efficiency controls' },
      { id: 'Drift', summary: 'Intra-v7 template-drift detector (manifest + header-diff check) on upgrade & recheck' },
    ],
  },
  {
    version: '7.10.1',
    items: [
      { id: 'P3-fix', summary: 'Orchestrator driving pattern corrected — /story and /epic MUST invoke downstream skills, not inline artifacts' },
    ],
  },
  {
    version: '7.10.0',
    items: [
      { id: 'P1', summary: 'Version-pin freshness check in epic-tech-spec template' },
      { id: 'P2', summary: 'typecheck in tasks-template verification phase' },
      { id: 'P3', summary: '/story and /epic orchestrators MUST invoke downstream skills (anti-pattern fix in v7.10.1)' },
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
