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

import { existsSync, readdirSync, statSync, readFileSync, writeFileSync } from 'fs';
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
 * Decide which post-upgrade actions the (currentVersion → targetVersion)
 * transition requires. Actions are independent and can combine (a v6 → v8
 * jump needs both):
 *   - scaffoldV7: run the per-project v6 → v7 artifact scaffolding script
 *   - reproveV8:  drop the .speck/.v8-reprove-needed marker (semantic re-prove)
 *
 * Exported for testability.
 */
export function detectMigration(currentVersion, targetVersion) {
  const fromMajor = majorOf(currentVersion);
  const toMajor = majorOf(targetVersion);
  if (toMajor == null) {
    return { scaffoldV7: false, reproveV8: false, targetMajor: null };
  }

  // Crossing into v7 from anything older → run v6→v7 scaffolding per project.
  // (Also fires on a v6→v8 jump: you need the v7 artifacts before the v8 re-prove.)
  const scaffoldV7 = toMajor >= 7 && (fromMajor == null || fromMajor < 7);

  // Crossing into v8 from anything older → semantic re-prove (cap-and-worklist).
  // The mechanical upgrade is trusted; v7-era "green" is NOT (see docs/v8/v8-north-star.md §5).
  const reproveV8 = toMajor >= 8 && (fromMajor == null || fromMajor < 8);

  return { scaffoldV7, reproveV8, targetMajor: toMajor };
}

/**
 * Write the repo-level .speck/.v8-reprove-needed marker — the direct analog of
 * v6→v7's .speck/.migration-needs-catchup. Non-destructive and idempotent:
 * never overwrites an existing marker. Returns { written, path, reason }.
 */
export function writeV8ReproveMarker(targetDir, targetVersion = '8.0.0') {
  const speckDir = join(targetDir, '.speck');
  if (!existsSync(speckDir)) {
    return { written: false, path: null, reason: '.speck directory not present' };
  }
  const markerPath = join(speckDir, '.v8-reprove-needed');
  if (existsSync(markerPath)) {
    return { written: false, path: markerPath, reason: 'marker already present' };
  }
  const date = new Date().toISOString().slice(0, 10);
  const body = `V8 SEMANTIC RE-PROVE NEEDED

This project was upgraded to Speck v8 (Evaluation Over Verification) on ${date}
(target ${targetVersion}). The mechanical upgrade — files, alias-shims, lazy patterns,
version — is done. But v8 does NOT trust v7-era "green" as evaluation-proven
(see docs/v8/v8-north-star.md §5).

BEFORE any new feature work, run:  /speck-reprove

It will:
  - triage suspect-green artifacts against the four v8 principles (P1-P4),
  - cap effective shippable state at INTEGRATION-GREEN,
  - revert consumer FELT-GOOD to \`uncovered\`,
  - preserve each historical v7 claim but stamp it [pre-v8-proof],
  - build a prioritized worklist and emit project-v8-reprove-report.md.

States climb back to \`verified\` only as real v8 evidence lands. Nothing is reset
to zero; nothing suspect keeps claiming ship-readiness.

Delete this marker only after /speck-reprove has produced the report and the
worklist is tracked.
`;
  writeFileSync(markerPath, body);
  return { written: true, path: markerPath, reason: null };
}

/**
 * Run any post-upgrade migrations needed. Idempotent and silent unless
 * options.verbose is set. Returns a summary object:
 *   { kind, targetMajor, projects: [...], v8Reprove: { written, path, reason } | null }
 */
export function runPostUpgradeMigrations(targetDir, currentVersion, targetVersion, options = {}) {
  const { scaffoldV7, reproveV8, targetMajor } = detectMigration(currentVersion, targetVersion);
  const summary = { kind: null, targetMajor, projects: [], v8Reprove: null };

  if (!scaffoldV7 && !reproveV8) {
    summary.targetMajor = null;
    return summary;
  }

  if (scaffoldV7) {
    if (options.verbose) {
      console.log(`\n🔁 Detected ${currentVersion} → ${targetVersion} crossing into v7. Running v6→v7 scaffolding...`);
    }
    const projects = findProjects(targetDir);
    if (projects.length === 0) {
      if (options.verbose) {
        console.log('   No projects under specs/projects/ — nothing to scaffold.');
      }
    } else {
      for (const proj of projects) {
        summary.projects.push(migrateProjectV7(targetDir, proj, options));
      }
    }
    summary.kind = reproveV8 ? 'v6-to-v8' : 'v6-to-v7';
  }

  if (reproveV8) {
    if (options.verbose) {
      console.log(`\n🔁 Detected crossing into Speck v8. Writing .speck/.v8-reprove-needed marker (semantic re-prove)...`);
    }
    summary.v8Reprove = writeV8ReproveMarker(targetDir, targetVersion);
    if (!summary.kind) summary.kind = 'v7-to-v8';
  }

  return summary;
}

/**
 * Standalone helper to manually invoke v7 migration (e.g. for `speck migrate v7` CLI command).
 */
export function migrateToV7(targetDir, options = {}) {
  return runPostUpgradeMigrations(targetDir, '6.0.0', '7.0.0', options);
}
