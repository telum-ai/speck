/**
 * Initialize Speck in a directory
 */

import { existsSync } from 'fs';
import { join } from 'path';
import { getLatestRelease } from '../github.js';
import { extractRelease, planSync, executeSync, saveVersion, loadIgnorePatterns } from '../sync.js';

export async function init(targetDir, options = {}) {
  console.log('🥓 Initializing Speck...\n');
  
  // Check if already initialized
  const agentsPath = join(targetDir, 'AGENTS.md');
  const speckDir = join(targetDir, '.speck');
  
  if (existsSync(agentsPath) || existsSync(speckDir)) {
    if (!options.force) {
      console.log('⚠️  Speck appears to be already initialized in this directory.');
      console.log('   Use --force to reinitialize, or use "speck upgrade" to update.');
      return;
    }
    console.log('⚠️  Reinitializing (--force specified)...\n');
  }
  
  // Get latest release
  console.log('📡 Fetching latest Speck release...');
  const release = await getLatestRelease();
  console.log(`   Found: ${release.tag_name} - ${release.name}\n`);
  
  // Download release
  console.log('📦 Downloading...');
  const sourceDir = await extractRelease(release.tag_name);
  console.log('   Done!\n');
  
  // Plan the sync
  const ignorePatterns = loadIgnorePatterns(targetDir);
  if (options.ignore) {
    ignorePatterns.push(...options.ignore);
  }
  
  const plan = planSync(sourceDir, targetDir, ignorePatterns);
  
  // Show what will be created
  console.log('📋 Files to create:');
  if (plan.create.length === 0) {
    console.log('   (none)');
  } else {
    for (const file of plan.create.slice(0, 20)) {
      console.log(`   + ${file}`);
    }
    if (plan.create.length > 20) {
      console.log(`   ... and ${plan.create.length - 20} more`);
    }
  }
  
  if (plan.update.length > 0) {
    console.log('\n📋 Files to update:');
    for (const file of plan.update.slice(0, 10)) {
      console.log(`   ~ ${file}`);
    }
    if (plan.update.length > 10) {
      console.log(`   ... and ${plan.update.length - 10} more`);
    }
  }
  
  if (plan.skip.length > 0) {
    console.log(`\n⏭️  Skipped ${plan.skip.length} files (ignored patterns)`);
  }
  
  console.log('');
  
  // Dry run stops here
  if (options.dryRun) {
    console.log('🔍 Dry run - no changes made.');
    return;
  }
  
  // Execute sync
  console.log('✨ Creating files...');
  const results = executeSync(sourceDir, targetDir, plan);
  
  if (results.errors.length > 0) {
    console.log('\n❌ Some files failed:');
    for (const { file, error } of results.errors) {
      console.log(`   ${file}: ${error}`);
    }
  }
  
  // Save version
  saveVersion(targetDir, release.tag_name);
  
  console.log(`
✅ Speck ${release.tag_name} initialized!

📁 Created ${results.created.length} files
📝 Updated ${results.updated.length} files

Next steps:
  1. Review the created files
  2. Configure .speckignore if needed
  3. Run /speck to start your project!

Documentation: https://github.com/telum-ai/speck
`);
}
