/**
 * Upgrade Speck to a new version
 */

import { getLatestRelease, getReleaseByTag, getChangelog } from '../github.js';
import { 
  extractRelease, 
  planSync, 
  executeSync, 
  saveVersion, 
  loadIgnorePatterns,
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
  const sourceDir = await extractRelease(targetVersion);
  console.log('   Done!\n');
  
  // Plan the sync
  const ignorePatterns = loadIgnorePatterns(targetDir);
  if (options.ignore) {
    ignorePatterns.push(...options.ignore);
  }
  
  const plan = planSync(sourceDir, targetDir, ignorePatterns);
  
  // Show what will change
  if (plan.create.length > 0) {
    console.log('📋 New files:');
    for (const file of plan.create.slice(0, 10)) {
      console.log(`   + ${file}`);
    }
    if (plan.create.length > 10) {
      console.log(`   ... and ${plan.create.length - 10} more`);
    }
    console.log('');
  }
  
  if (plan.update.length > 0) {
    console.log('📋 Files to update:');
    for (const file of plan.update.slice(0, 15)) {
      console.log(`   ~ ${file}`);
    }
    if (plan.update.length > 15) {
      console.log(`   ... and ${plan.update.length - 15} more`);
    }
    console.log('');
  }
  
  if (plan.create.length === 0 && plan.update.length === 0) {
    console.log('✅ No changes needed - all files are up to date!');
    return;
  }
  
  console.log(`📊 Summary: ${plan.create.length} new, ${plan.update.length} updated, ${plan.skip.length} skipped\n`);
  
  // Dry run stops here
  if (options.dryRun) {
    console.log('🔍 Dry run - no changes made.');
    console.log('   Run without --dry-run to apply changes.');
    return;
  }
  
  // Execute sync
  console.log('✨ Applying changes...');
  const results = executeSync(sourceDir, targetDir, plan);
  
  if (results.errors.length > 0) {
    console.log('\n❌ Some files failed:');
    for (const { file, error } of results.errors) {
      console.log(`   ${file}: ${error}`);
    }
  }
  
  // Save new version
  saveVersion(targetDir, targetVersion);
  
  console.log(`
✅ Upgraded from ${currentVersion} to ${targetVersion}!

📁 Created ${results.created.length} files
📝 Updated ${results.updated.length} files

Review the changes and commit when ready:
  git add -A
  git commit -m "chore: upgrade Speck to ${targetVersion}"

To check for future updates:
  npx github:telum-ai/speck check
`);
}
