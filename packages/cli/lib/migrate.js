/**
 * Post-upgrade migration runner.
 *
 * Detects when an upgrade crosses a major version boundary that needs
 * project-level artifact scaffolding (currently v6 → v7) and runs the
 * appropriate migration script for every project under specs/projects/.
 *
 * Silent and idempotent: if a project already has v7 artifacts, the
 * migration script skips it. If there are no projects, nothing happens.
 */

import { existsSync, readdirSync, statSync, readFileSync } from 'fs';
import { join } from 'path';
import { execSync } from 'child_process';

/**
 * Parse a version string like "v7.0.0", "7.0.0", or "v6.1.14" into an integer major.
 * Returns null for unparsable input.
 */
function majorOf(version) {
  if (!version) return null;
  const m = String(version).match(/v?(\d+)\./);
  return m ? parseInt(m[1], 10) : null;
}

/**
 * Find every project directory under specs/projects/.
 * A project is any direct subdirectory of specs/projects/.
 */
function findProjects(targetDir) {
  const projectsRoot = join(targetDir, 'specs', 'projects');
  if (!existsSync(projectsRoot)) return [];
  try {
    return readdirSync(projectsRoot)
      .map(name => join(projectsRoot, name))
      .filter(p => {
        try {
          return statSync(p).isDirectory();
        } catch {
          return false;
        }
      });
  } catch {
    return [];
  }
}

/**
 * Run the v6 → v7 migration script for a single project.
 * Returns { path, created, ok, output }.
 */
function migrateProjectV7(targetDir, projectPath, options = {}) {
  const script = join(targetDir, '.speck', 'scripts', 'migrate.sh');
  if (!existsSync(script)) {
    return { path: projectPath, created: 0, ok: false, output: 'migrate.sh not present' };
  }

  try {
    const output = execSync(`bash "${script}" "${projectPath}"`, {
      cwd: targetDir,
      encoding: 'utf-8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });

    // Count scaffolded artifacts by parsing the script's output ("✅" for each created/updated)
    const created = (output.match(/^✅ /gm) || []).length;

    if (options.verbose) {
      console.log(output);
    }

    return { path: projectPath, created, ok: true, output };
  } catch (err) {
    return {
      path: projectPath,
      created: 0,
      ok: false,
      output: err.stdout?.toString() || err.message,
    };
  }
}

/**
 * Decide whether the (currentVersion → targetVersion) transition requires
 * post-upgrade migrations. Currently triggers only for major bumps that
 * cross the 7.x boundary (i.e., 6.x → 7.x).
 *
 * Returns an object describing the migration to run, or null.
 */
function detectMigration(currentVersion, targetVersion) {
  const fromMajor = majorOf(currentVersion);
  const toMajor = majorOf(targetVersion);
  if (toMajor == null) return null;

  // 6.x or earlier → 7.x: run v6→v7 migration script per project
  if (toMajor >= 7 && (fromMajor == null || fromMajor < 7)) {
    return { kind: 'v6-to-v7', targetMajor: toMajor };
  }
  return null;
}

/**
 * Run any post-upgrade migrations needed. Idempotent and silent unless
 * options.verbose is set. Returns a summary object.
 */
export function runPostUpgradeMigrations(targetDir, currentVersion, targetVersion, options = {}) {
  const migration = detectMigration(currentVersion, targetVersion);
  if (!migration) {
    return { kind: null, targetMajor: null, projects: [] };
  }

  if (options.verbose) {
    console.log(`\n🔁 Detected ${currentVersion} → ${targetVersion} (major bump). Running auto-migration...`);
  }

  const projects = findProjects(targetDir);
  if (projects.length === 0) {
    if (options.verbose) {
      console.log('   No projects under specs/projects/ — nothing to migrate.');
    }
    return { kind: migration.kind, targetMajor: migration.targetMajor, projects: [] };
  }

  const results = [];
  for (const proj of projects) {
    const result = migrateProjectV7(targetDir, proj, options);
    results.push(result);
  }

  return {
    kind: migration.kind,
    targetMajor: migration.targetMajor,
    projects: results,
  };
}

/**
 * Standalone helper to manually invoke v7 migration (e.g. for `speck migrate v7` CLI command).
 */
export function migrateToV7(targetDir, options = {}) {
  return runPostUpgradeMigrations(targetDir, '6.0.0', '7.0.0', options);
}
