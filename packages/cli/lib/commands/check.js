/**
 * Check for available updates
 */

import { getLatestRelease, getChangelog } from '../github.js';
import { getCurrentVersion } from '../sync.js';

export async function check(targetDir) {
  console.log('🥓 Checking for Speck updates...\n');
  
  // Get current version
  const currentVersion = getCurrentVersion(targetDir);
  if (!currentVersion) {
    console.log('⚠️  Could not detect current Speck version.');
    console.log('   Use "speck init" to initialize Speck first.');
    return;
  }
  
  console.log(`📌 Current version: ${currentVersion}`);
  
  // Get latest version
  console.log('📡 Checking latest release...');
  const latest = await getLatestRelease();
  const latestVersion = latest.tag_name;
  
  console.log(`🎯 Latest version:  ${latestVersion}\n`);
  
  if (currentVersion === latestVersion) {
    console.log('✅ You are up to date!');
    return;
  }
  
  // Show what's new
  console.log('🆕 New versions available:\n');
  
  const changelog = await getChangelog(currentVersion, latestVersion);
  if (changelog && changelog.length > 0) {
    for (const release of changelog) {
      console.log(`   ${release.version}: ${release.name}`);
      console.log(`   ${release.url}\n`);
    }
  }
  
  console.log(`
To upgrade, run:
  npx @telum-ai/speck upgrade

Or to upgrade to a specific version:
  npx @telum-ai/speck upgrade ${latestVersion}

Use --dry-run to preview changes first:
  npx @telum-ai/speck upgrade --dry-run
`);
}
