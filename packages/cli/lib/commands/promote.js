/**
 * speck promote — Bump a project's play level (Sprint → Build → Platform or downgrade)
 *
 * Usage:
 *   npx github:telum-ai/speck promote --to build
 *   npx github:telum-ai/speck promote --to platform
 *   npx github:telum-ai/speck promote --to sprint   # downgrade
 *
 * Reads/writes .speck/project.json in the target directory.
 */

import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';

const VALID_LEVELS = ['sprint', 'build', 'platform'];
const LEVEL_RANK = { sprint: 0, build: 1, platform: 2 };

/**
 * Read play level from .speck/project.json
 */
function readProjectJson(targetDir) {
  const path = join(targetDir, '.speck', 'project.json');
  if (!existsSync(path)) {
    return null;
  }
  try {
    return JSON.parse(readFileSync(path, 'utf-8'));
  } catch {
    return null;
  }
}

/**
 * Write .speck/project.json
 */
function writeProjectJson(targetDir, data) {
  const path = join(targetDir, '.speck', 'project.json');
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, JSON.stringify(data, null, 2) + '\n');
}

/**
 * Promote or downgrade a project's play level
 */
export async function promote(targetDir, options = {}) {
  const toLevel = options.to?.toLowerCase();

  if (!toLevel) {
    console.error('❌ Missing --to flag. Usage: speck promote --to <sprint|build|platform>');
    process.exit(1);
  }

  if (!VALID_LEVELS.includes(toLevel)) {
    console.error(`❌ Invalid play level: "${toLevel}". Must be one of: ${VALID_LEVELS.join(', ')}`);
    process.exit(1);
  }

  const existing = readProjectJson(targetDir);
  const currentLevel = existing?.play_level ?? 'platform';

  if (currentLevel === toLevel) {
    console.log(`ℹ️  Already at play level: ${toLevel}`);
    return;
  }

  const currentRank = LEVEL_RANK[currentLevel] ?? 2;
  const targetRank = LEVEL_RANK[toLevel];
  const direction = targetRank > currentRank ? 'promotion' : 'downgrade';

  const updated = {
    ...(existing ?? {}),
    play_level: toLevel,
    [`${direction === 'promotion' ? 'promoted' : 'downgraded'}_from`]: currentLevel,
    [`${direction === 'promotion' ? 'promoted' : 'downgraded'}_at`]: new Date().toISOString(),
  };

  if (options.dryRun) {
    console.log(`🔍 Dry run — would ${direction} play level:`);
    console.log(`   From: ${currentLevel}`);
    console.log(`   To:   ${toLevel}`);
    console.log(`   File: ${join(targetDir, '.speck', 'project.json')}`);
    console.log(`   Data: ${JSON.stringify(updated, null, 2)}`);
    return;
  }

  writeProjectJson(targetDir, updated);

  const arrow = direction === 'promotion' ? '↑' : '↓';
  console.log(`✅ Play level ${direction}: ${currentLevel} ${arrow} ${toLevel}`);
  console.log(`   Updated: .speck/project.json`);

  // Guidance per transition
  if (direction === 'promotion') {
    if (toLevel === 'build') {
      console.log(`
Next steps for Build:
  1. Expand PRD.md with full sections (run /project-specify to re-specify)
  2. Create context.md — run /project-context
  3. Create COMMERCIAL.md — revenue model and GTM
  4. Start your first epic — run /epic-specify
  5. Run /project-promote (agent) for guided artifact expansion
`);
    } else if (toLevel === 'platform') {
      console.log(`
Next steps for Platform:
  1. Run /project-architecture — system design before planning
  2. Run /project-constitution — technical principles (if needed)
  3. Run /project-design-system — UI consistency (if needed)
  4. Run /project-plan — comprehensive PRD and epic breakdown
  5. Run /project-roadmap — sequence your epics
`);
    }
  } else {
    console.log(`
Downgrade complete. Artifact requirements are now reduced.
Existing files are preserved — the audit will check fewer requirements.
`);
  }
}
