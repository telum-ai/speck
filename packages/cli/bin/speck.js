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
import { incubate } from '../lib/commands/incubate.js';
import { promote } from '../lib/commands/promote.js';
import { feedback } from '../lib/commands/feedback.js';
import { reconcileSettingsCommand } from '../lib/commands/reconcile-settings.js';
import { larpPlay } from '../lib/commands/larp-play.js';
import { compressCommand, decompressCommand } from '../lib/commands/compress.js';
import { migrateToV7 } from '../lib/migrate.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const pkg = JSON.parse(readFileSync(join(__dirname, '..', 'package.json'), 'utf-8'));

const HELP = `
🥓 Speck CLI v${pkg.version}

USAGE
  npx github:telum-ai/speck <command> [options]

COMMANDS
  init              Initialize Speck in current directory
  upgrade [version] Upgrade to latest (or specified) version (auto-migrates v6→v7 projects)
  migrate           Manually re-run v7 migration on every project (idempotent)
  check             Check for available updates
  version           Show current and latest versions
  promote           Bump play level (--to sprint|build|platform)
  incubate          Propose one lean JTBD bet from recent repo signals
  feedback          Draft a feedback note (catchup/recipe/methodology/etc.) for review/submission
  reconcile-settings  Sync Speck-managed Claude hook blocks from settings.json.example
  larp-play         Run autonomous persona-based LARP playback / manual walkthrough
  compress          Compact active story subdirectories of a validated epic into an archive
  decompress        Restore active story subdirectories of a compacted epic from an archive
  help              Show this help message

OPTIONS
  --dry-run         Show what would change without making changes
  --force           Overwrite existing files without prompting
  --ignore <glob>   Additional patterns to ignore (can be repeated)
  --days <n>        Days of git history to mine for incubate (default: 21)
  --to <level>      Target play level for promote command (sprint|build|platform)
  --topic <name>    Feedback topic: catchup|migration|recipe|methodology|cli|docs|other
  --message "<s>"   Inline feedback message (skips interactive prompt)
  --auto            Non-interactive mode for feedback (writes file with placeholders)
  --persona <id>    Target persona script to run in larp-play
  --url <url>       Target base URL for larp-play (default: http://localhost:3000)
  --epic <id>       Target epic directory for context compaction / restoration

EXAMPLES
  npx github:telum-ai/speck init
  npx github:telum-ai/speck upgrade
  npx github:telum-ai/speck upgrade v2.1.0
  npx github:telum-ai/speck check
  npx github:telum-ai/speck promote --to build
  npx github:telum-ai/speck promote --to platform
  npx github:telum-ai/speck incubate --days 30
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
  
  // Parse --days option
  const daysIndex = args.indexOf('--days');
  if (daysIndex !== -1 && args[daysIndex + 1]) {
    options.days = Number(args[daysIndex + 1]);
  }

  // Parse --persona and --url options
  const personaIndex = args.indexOf('--persona');
  if (personaIndex !== -1 && args[personaIndex + 1]) {
    options.persona = args[personaIndex + 1];
  }
  const urlIndex = args.indexOf('--url');
  if (urlIndex !== -1 && args[urlIndex + 1]) {
    options.url = args[urlIndex + 1];
  }
  const epicIndex = args.indexOf('--epic');
  if (epicIndex !== -1 && args[epicIndex + 1]) {
    options.epic = args[epicIndex + 1];
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

      case 'promote': {
        // Parse --to flag
        const toIndex = args.indexOf('--to');
        const toLevel = toIndex !== -1 ? args[toIndex + 1] : undefined;
        await promote(process.cwd(), { ...options, to: toLevel });
        break;
      }

      case 'incubate':
        await incubate(process.cwd(), options);
        break;

      case 'migrate': {
        const summary = migrateToV7(process.cwd(), { verbose: true });
        if (summary.projects.length === 0) {
          console.log('✅ Nothing to migrate — no projects found under specs/projects/, or already on v7.');
        } else {
          const scaffolded = summary.projects.reduce((n, p) => n + p.created, 0);
          console.log(`\n✅ Migration complete: ${summary.projects.length} project(s), ${scaffolded} artifact(s) scaffolded.`);
        }
        break;
      }

      case 'feedback':
        await feedback(process.cwd(), { ...options, _args: args });
        break;

      case 'reconcile-settings':
        await reconcileSettingsCommand(process.cwd(), options);
        break;

      case 'larp-play':
        await larpPlay(process.cwd(), options);
        break;

      case 'compress':
        await compressCommand(process.cwd(), options.epic, options);
        break;

      case 'decompress':
        await decompressCommand(process.cwd(), options.epic, options);
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
