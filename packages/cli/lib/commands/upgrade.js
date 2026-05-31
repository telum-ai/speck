/**
 * Upgrade Speck to a new version with smart merging
 */

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { getLatestRelease, getReleaseByTag, getChangelog } from '../github.js';
import { 
  extractRelease, 
  smartSync,
  saveVersion, 
  getCurrentVersion 
} from '../sync.js';
import { runPostUpgradeMigrations } from '../migrate.js';
import { runReadmeRegen } from '../readme.js';
import { runSettingsReconcile } from '../claude-settings.js';
import { printFeedbackAddressed } from '../upgrade-feedback.js';

export async function upgrade(targetDir, version, options = {}) {
  console.log('🥓 Upgrading Speck...\n');
  
  // Get current version
  const currentVersion = getCurrentVersion(targetDir);
  if (!currentVersion) {
    console.log('⚠️  Could not detect current Speck version.');
    console.log('   Use "speck init" to initialize Speck first.');
    return;
  }
  console.log(`📌 Current version: ${currentVersion}`);
  
  // Get target version
  let targetRelease;
  if (version === 'latest') {
    console.log('📡 Fetching latest Speck release...');
    targetRelease = await getLatestRelease();
  } else {
    console.log(`📡 Fetching Speck ${version}...`);
    targetRelease = await getReleaseByTag(version);
  }
  
  const targetVersion = targetRelease.tag_name;
  console.log(`🎯 Target version:  ${targetVersion}\n`);
  
  // Check if already up to date
  if (currentVersion === targetVersion) {
    console.log('✅ Already up to date!');
    return;
  }
  
  // Get changelog
  console.log('📜 Changes between versions:');
  const changelog = await getChangelog(currentVersion, targetVersion);
  if (changelog && changelog.length > 0) {
    for (const release of changelog) {
      console.log(`\n   ${release.version}: ${release.name}`);
      // Show first few lines of body
      const bodyLines = release.body?.split('\n').slice(0, 5) || [];
      for (const line of bodyLines) {
        if (line.trim()) {
          console.log(`     ${line}`);
        }
      }
      if (release.body?.split('\n').length > 5) {
        console.log('     ...');
      }
    }
  } else {
    console.log('   (changelog not available)');
  }
  console.log('');
  
  // Download target version
  console.log('📦 Downloading...');
  const sourceDir = await extractRelease(targetVersion, options.token);
  console.log('   Done!\n');
  
  // Dry run - just show what would happen
  if (options.dryRun) {
    console.log('🔍 Dry run - showing what would change:\n');
    console.log('Smart merge strategies:');
    console.log('  • AGENTS.md: Speck controls SPECK:START..END, your content preserved');
    console.log('  • .gitignore: Your entries merged with Speck defaults');
    console.log('  • .cursor/hooks/hooks.json: Your hooks merged with Speck hooks');
    console.log('  • .cursor/mcp.json: Your config takes precedence');
    console.log('  • .claude + .codex: Runtime symlinks to .cursor/skills + .cursor/agents');
    console.log('  • README.md: Project skeleton, footer merge, or Speck-marketing auto-repair');
    console.log('  • .claude/settings.json: Speck-managed hook blocks reconciled from example');
    console.log('  • Everything else: Always updated');
    console.log('  • Removed files: Files deleted from Speck will be removed from your project\n');
    console.log('Run without --dry-run to apply changes.');
    return;
  }
  
  // Execute smart sync
  console.log('✨ Applying changes with smart merging...\n');
  const results = smartSync(sourceDir, targetDir, { verbose: true });
  
  // Summary
  console.log('');
  if (results.errors.length > 0) {
    console.log('❌ Some files failed:');
    for (const { file, error } of results.errors) {
      console.log(`   ${file}: ${error}`);
    }
    console.log('');
  }
  
  // Save new version
  saveVersion(targetDir, targetVersion);

  // Run any post-upgrade migrations (e.g. v6 → v7 project artifact scaffolding).
  // This is silent and idempotent — runs only when actually needed.
  let migrationSummary = null;
  try {
    migrationSummary = runPostUpgradeMigrations(targetDir, currentVersion, targetVersion, { verbose: true });
  } catch (err) {
    console.log(`⚠️  Post-upgrade migration encountered an error: ${err.message}`);
    console.log('   The upgrade itself succeeded. Run `bash .speck/scripts/migrate.sh <project>` manually if needed.');
  }

  if (results.readmeRepaired) {
    console.log(`
🔧 README repaired: replaced legacy Speck marketing content with a project skeleton.
   Run /project-readme (or /project-specify then /project-product-contract) to populate
   from your specs. Your project README is yours — Speck only manages <!-- SPECK:START --> footer.`);
  }

  const readmeResult = runReadmeRegen(targetDir);
  if (readmeResult.ok) {
    console.log(`\n✅ ${readmeResult.message}`);
  }

  const settingsResult = runSettingsReconcile(targetDir, { verbose: false });
  if (settingsResult.hadDrift) {
    console.log('\n⚠️  Claude settings drift detected (Speck-managed hook blocks):');
    for (const d of settingsResult.driftBefore) {
      console.log(`   • ${d.path}: ${d.summary}`);
    }
  }
  if (settingsResult.applied && settingsResult.changes?.length > 0) {
    console.log(`\n✅ Claude settings reconciled: ${settingsResult.changes.join(', ')}`);
  } else if (settingsResult.created) {
    console.log('\n✅ Created .claude/settings.json from example');
  }

  const crossedProfileEnforcement =
    parseFloat(String(currentVersion).replace(/^v/, '')) < 7.7 &&
    parseFloat(String(targetVersion).replace(/^v/, '')) >= 7.7;
  if (crossedProfileEnforcement) {
    console.log(`
📋 PROFILE enforcement (v7.7+): Run /speck-catch-up --phase=profile on existing projects
   to backfill PROFILE gates in evidence-contract.md and project.md.`);
  }

  const crossedSettingsSync =
    parseFloat(String(currentVersion).replace(/^v/, '')) < 7.8 &&
    parseFloat(String(targetVersion).replace(/^v/, '')) >= 7.8;
  if (crossedSettingsSync) {
    console.log(`
🔧 Claude settings (v7.8+): Stop hook is now command-type (stop-gate.sh). Legacy prompt-type
   hooks are reconciled automatically. Run \`speck reconcile-settings\` if drift persists.`);
  }

  console.log(`
✅ Upgraded from ${currentVersion} to ${targetVersion}!

📁 Created: ${results.created.length} files
📝 Updated: ${results.updated.length} files
🔀 Merged:  ${results.merged.length} files
🗑️  Removed: ${results.removed.length} files
⏭️  Skipped: ${results.skipped.length} files`);

  printFeedbackAddressed(currentVersion, targetVersion);
  runTemplateDriftCheck(targetDir);

  if (migrationSummary && migrationSummary.projects.length > 0) {
    console.log(`
🔁 Auto-migrated ${migrationSummary.projects.length} project(s) to v${migrationSummary.targetMajor}:
${migrationSummary.projects.map(p => `   • ${p.path}: ${p.created} new artifact(s) scaffolded`).join('\n')}

⚠️  TWO-STEP UPGRADE — DO NOT COMMIT YET.

   This was step 1 (scaffolding). The migration only created EMPTY template
   artifacts and dropped a .speck/.migration-needs-catchup marker. The project
   still carries every v6 debt: unsupported PASS claims, scattered specs,
   decisions buried in git history, surrogate-proof in old validation reports.

   Step 2 is brownfield reconstruction. Recommended pattern (staging branch):

     git checkout -b speck-v7-migration
     # already done: speck CLI synced files + ran migrate.sh
     # now run catch-up:
     /speck-catch-up                    (or --phase=triage for large projects)
     # ...iterate phases if large project...
     git add -A
     git commit -m "chore: upgrade Speck to ${targetVersion} + brownfield catch-up"
     # open as a PR against main for review BEFORE merging

   On smaller projects you can also bundle into a single commit on main if
   you trust the result. The important rule: scaffolded-template state should
   NEVER reach main. Either catch-up first, or revert.

   Large project tip: /speck-catch-up supports --phase=triage|contracts|
   decisions|epic-artifacts|honesty|state|plan|finalize so you can commit
   between phases instead of doing one giant change.

   See <project>/migration-report.md for what was scaffolded. The next agent
   that engages any of these projects will detect the marker and start
   catch-up automatically.`);
  } else {
    console.log(`
Review the changes and commit when ready:
  git add -A
  git commit -m "chore: upgrade Speck to ${targetVersion}"`);
  }

  console.log(`
To check for future updates:
  npx github:telum-ai/speck check

To share feedback on this upgrade (no telemetry, you submit the file yourself):
  npx github:telum-ai/speck feedback --topic migration

README note: root README.md is your project's public face. Methodology docs: .speck/README.md
`);
}

function findMarkdownFiles(dir, files = []) {
  if (!fs.existsSync(dir)) return files;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      findMarkdownFiles(fullPath, files);
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      files.push(fullPath);
    }
  }
  return files;
}

function runTemplateDriftCheck(targetDir) {
  const specsDir = path.join(targetDir, 'specs/projects');
  if (!fs.existsSync(specsDir)) return;

  const files = findMarkdownFiles(specsDir);
  const driftScript = path.join(targetDir, '.speck/scripts/validation/check-artifact-template-drift.js');
  if (!fs.existsSync(driftScript)) return;

  let driftCount = 0;
  const driftedArtifacts = [];

  for (const file of files) {
    try {
      const output = execSync(`node "${driftScript}" "${file}"`, { encoding: 'utf-8' });
      if (output.includes('TEMPLATE_DRIFT:')) {
        driftCount++;
        const relativePath = path.relative(targetDir, file);
        const missingLines = output.split('\n')
          .filter(l => l.startsWith('  - '))
          .map(l => l.trim());
        driftedArtifacts.push({ path: relativePath, missing: missingLines });
      }
    } catch (err) {
      // Ignore errors running script
    }
  }

  if (driftCount > 0) {
    console.log(`\n⚠️  Detected ${driftCount} artifact(s) with structural template drift:`);
    for (const art of driftedArtifacts.slice(0, 5)) {
      console.log(`   • ${art.path} (missing sections: ${art.missing.join(', ')})`);
    }
    if (driftCount > 5) {
      console.log(`   • ... and ${driftCount - 5} more artifact(s)`);
    }
    console.log('\n   To fix structural drift, run `/recheck` or `/speck-catch-up --phase=refresh`');
  }
}

