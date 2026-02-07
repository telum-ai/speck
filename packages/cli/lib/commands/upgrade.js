/**
 * Upgrade Speck to a new version with smart merging
 */

import { getLatestRelease, getReleaseByTag, getChangelog } from '../github.js';
import { 
  extractRelease, 
  smartSync,
  saveVersion, 
  getCurrentVersion 
} from '../sync.js';

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
    console.log('  • .claude/commands: Claude Code slash commands synced');
    console.log('  • README.md: Skipped if customized');
    console.log('  • copilot-setup-steps.yml: Skipped if customized');
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
  
  console.log(`
✅ Upgraded from ${currentVersion} to ${targetVersion}!

📁 Created: ${results.created.length} files
📝 Updated: ${results.updated.length} files
🔀 Merged:  ${results.merged.length} files
🗑️  Removed: ${results.removed.length} files
⏭️  Skipped: ${results.skipped.length} files

Review the changes and commit when ready:
  git add -A
  git commit -m "chore: upgrade Speck to ${targetVersion}"

To check for future updates:
  npx github:telum-ai/speck check
`);
}
