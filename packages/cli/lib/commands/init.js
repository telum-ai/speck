/**
 * Initialize Speck in a directory
 */

import { getLatestRelease } from '../github.js';
import { extractRelease, smartSync, saveVersion, isSpeckInitialized } from '../sync.js';

export async function init(targetDir, options = {}) {
  console.log('🥓 Initializing Speck...\n');
  
  // Check if already initialized (using Speck-specific markers)
  if (isSpeckInitialized(targetDir)) {
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
  const sourceDir = await extractRelease(release.tag_name, options.token);
  console.log('   Done!\n');
  
  // Dry run stops here
  if (options.dryRun) {
    console.log('🔍 Dry run - showing what would be created:\n');
    console.log('Smart merge strategies:');
    console.log('  • AGENTS.md: Speck controls SPECK:START..END');
    console.log('  • .gitignore: Your entries merged with Speck defaults');
    console.log('  • .cursor/hooks/hooks.json: Your hooks merged with Speck hooks');
    console.log('  • .cursor/mcp.json: Your config takes precedence');
    console.log('  • .claude + .codex: Runtime symlinks to .cursor/skills + .cursor/agents');
    console.log('  • README.md: Project skeleton (or footer merge only — never Speck marketing)');
    console.log('  • copilot-setup-steps.yml: Skipped if customized');
    console.log('  • Everything else: Always updated\n');
    console.log('Run without --dry-run to apply changes.');
    return;
  }
  
  // Execute smart sync
  console.log('✨ Creating files with smart merging...\n');
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
  
  // Save version
  saveVersion(targetDir, release.tag_name);
  
  console.log(`
✅ Speck ${release.tag_name} initialized!

📁 Created: ${results.created.length} files
📝 Updated: ${results.updated.length} files
🔀 Merged:  ${results.merged.length} files
⏭️  Skipped: ${results.skipped.length} files

Next steps:
  1. Review the created files — root README.md is YOUR project identity (not Speck marketing)
  2. Methodology docs live at .speck/README.md
  3. Configure MCP servers in .cursor/mcp.json (copy from .cursor/mcp.json.example)
  4. Run /speck to start your project!

To check for updates later:
  npx github:telum-ai/speck check

Documentation: https://github.com/telum-ai/speck
`);
}
