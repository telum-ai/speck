/**
 * Show version information
 */

import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { getLatestRelease } from '../github.js';
import { getCurrentVersion } from '../sync.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export async function showVersion(targetDir) {
  // Get CLI version
  const pkg = JSON.parse(readFileSync(join(__dirname, '..', '..', 'package.json'), 'utf-8'));
  console.log(`🥓 Speck CLI v${pkg.version}\n`);
  
  // Get current project version
  const currentVersion = getCurrentVersion(targetDir);
  if (currentVersion) {
    console.log(`📌 Project Speck version: ${currentVersion}`);
  } else {
    console.log('📌 Project Speck version: (not initialized)');
  }
  
  // Get latest available
  try {
    const latest = await getLatestRelease();
    console.log(`🎯 Latest available:      ${latest.tag_name}`);
    
    if (currentVersion && currentVersion !== latest.tag_name) {
      console.log('\n💡 Run "npx @telum-ai/speck upgrade" to update');
    }
  } catch (error) {
    console.log('🎯 Latest available:      (could not fetch)');
  }
}
