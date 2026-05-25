/**
 * README regeneration helper for Speck CLI
 */

import { existsSync } from 'fs';
import { join } from 'path';
import { execSync } from 'child_process';

/**
 * Run regenerate-project-readme.sh (non-fatal)
 * @returns {{ ok: boolean, message: string }}
 */
export function runReadmeRegen(targetDir) {
  const script = join(targetDir, '.speck/scripts/regenerate-project-readme.sh');
  if (!existsSync(script)) {
    return { ok: false, message: 'regenerate-project-readme.sh not found' };
  }

  try {
    const out = execSync(`bash "${script}"`, {
      cwd: targetDir,
      encoding: 'utf-8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    return { ok: true, message: out.trim() || 'README footer refreshed' };
  } catch (err) {
    const code = err.status;
    const stderr = err.stderr?.toString?.() || err.message || '';
    // Exit 1 = no project yet (fresh init) — not a failure
    if (code === 1) {
      return { ok: false, message: 'No Speck project yet — README regen skipped' };
    }
    if (code === 2) {
      return { ok: false, message: 'README lacks SPECK markers — run speck upgrade first' };
    }
    return { ok: false, message: stderr || 'README regen failed' };
  }
}
