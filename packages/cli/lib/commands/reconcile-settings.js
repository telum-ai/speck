/**
 * speck reconcile-settings — sync Speck-managed Claude hook blocks
 */

import { reconcileSettings, detectSettingsDrift } from '../claude-settings.js';

export async function reconcileSettingsCommand(targetDir, options = {}) {
  console.log('🥓 Reconciling Claude Code settings...\n');

  const dryRun = options.dryRun || false;
  const detection = detectSettingsDrift(targetDir);

  if (!detection.hasExample) {
    console.log('⚠️  No .claude/settings.json.example found — is Speck initialized?');
    return;
  }

  if (detection.drift.length === 0 && detection.hasActive) {
    console.log('✅ Claude settings already in sync with Speck-managed blocks.');
    return;
  }

  if (detection.drift.length > 0) {
    console.log(`⚠️  SETTINGS_DRIFT detected (${detection.drift.length} block(s)):\n`);
    for (const d of detection.drift) {
      console.log(`  • ${d.path}: ${d.summary}`);
      if (d.activeHash && d.exampleHash) {
        console.log(`    active=${d.activeHash} example=${d.exampleHash}`);
      }
    }
    console.log('');
  }

  if (dryRun) {
    console.log('🔍 Dry run — no changes written. Run without --dry-run to reconcile.');
    return;
  }

  const result = reconcileSettings(targetDir, { apply: true, verbose: true });

  if (result.created) {
    console.log('✅ Created .claude/settings.json from example.');
  } else if (result.changes.length > 0) {
    console.log('✅ Reconciled Speck-managed blocks:');
    for (const c of result.changes) {
      console.log(`   • ${c}`);
    }
  } else {
    console.log('✅ No changes needed.');
  }

  console.log(`
User-owned settings preserved: permissions, env, outputStyle, teammateMode, and any custom hook types.
Speck-managed: hooks.Stop, hooks.SessionStart, hooks.PostToolUse (see _speck_managed in settings.json.example).
`);
}
