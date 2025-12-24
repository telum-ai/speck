#!/usr/bin/env node

/**
 * Speck CLI
 * 
 * Manages Speck methodology installation and updates in your projects.
 * Runs directly from GitHub - no npm publishing required.
 * 
 * Usage:
 *   npx github:telum-ai/speck init          # Initialize Speck in current directory
 *   npx github:telum-ai/speck upgrade       # Upgrade to latest version
 *   npx github:telum-ai/speck upgrade v2.1.0 # Upgrade to specific version
 *   npx github:telum-ai/speck check         # Check for available updates
 *   npx github:telum-ai/speck version       # Show current and latest versions
 * 
 * Access Control:
 *   Requires read permission to telum-ai/speck repository.
 *   If repo is private, user must be a collaborator or org member.
 */

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync, readFileSync } from 'fs';

import { init } from '../lib/commands/init.js';
import { upgrade } from '../lib/commands/upgrade.js';
import { check } from '../lib/commands/check.js';
import { showVersion } from '../lib/commands/version.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const pkg = JSON.parse(readFileSync(join(__dirname, '..', 'package.json'), 'utf-8'));

const HELP = `
🥓 Speck CLI v${pkg.version}

USAGE
  npx github:telum-ai/speck <command> [options]

COMMANDS
  init              Initialize Speck in current directory
  upgrade [version] Upgrade to latest (or specified) version
  check             Check for available updates
  version           Show current and latest versions
  help              Show this help message

OPTIONS
  --dry-run         Show what would change without making changes
  --force           Overwrite existing files without prompting
  --ignore <glob>   Additional patterns to ignore (can be repeated)

EXAMPLES
  npx github:telum-ai/speck init
  npx github:telum-ai/speck upgrade
  npx github:telum-ai/speck upgrade v2.1.0
  npx github:telum-ai/speck check
  npx github:telum-ai/speck upgrade --dry-run

ACCESS CONTROL
  Requires read permission to telum-ai/speck repository.
  If the repo is private, you must be a collaborator or org member.

MORE INFO
  https://github.com/telum-ai/speck
`;

async function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  
  // Parse options
  const options = {
    dryRun: args.includes('--dry-run'),
    force: args.includes('--force'),
    ignore: [],
  };
  
  // Parse --ignore options
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--ignore' && args[i + 1]) {
      options.ignore.push(args[i + 1]);
    }
  }
  
  // Get version argument for upgrade command
  const versionArg = args.find(a => a.startsWith('v') && !a.startsWith('--'));
  
  try {
    switch (command) {
      case 'init':
        await init(process.cwd(), options);
        break;
        
      case 'upgrade':
        await upgrade(process.cwd(), versionArg || 'latest', options);
        break;
        
      case 'check':
        await check(process.cwd());
        break;
        
      case 'version':
      case '-v':
      case '--version':
        await showVersion(process.cwd());
        break;
        
      case 'help':
      case '-h':
      case '--help':
      case undefined:
        console.log(HELP);
        break;
        
      default:
        console.error(`Unknown command: ${command}`);
        console.log(HELP);
        process.exit(1);
    }
  } catch (error) {
    console.error(`\n❌ Error: ${error.message}`);
    if (process.env.DEBUG) {
      console.error(error.stack);
    }
    process.exit(1);
  }
}

main();
