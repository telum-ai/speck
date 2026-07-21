/**
 * Core sync logic for Speck files with smart merging
 */

import { existsSync, readFileSync, writeFileSync, mkdirSync, readdirSync, statSync, rmSync, copyFileSync, symlinkSync, lstatSync, unlinkSync } from 'fs';
import { join, dirname, relative } from 'path';
import { execSync } from 'child_process';
import { tmpdir } from 'os';

/**
 * Files that should ALWAYS be overwritten (pure methodology)
 */
const ALWAYS_OVERWRITE = [
  '.speck/templates',
  '.speck/templates/sprint',  // v6.0.0: Sprint play level templates
  '.speck/patterns',
  '.speck/recipes',
  '.speck/scripts',
  '.speck/scripts/validation',
  '.speck/README.md',
  '.speck/VERSION',
  '.cursor/skills',
  '.cursor/agents',
  '.claude/agents',
  '.codex/agents',
  '.cursor/hooks/hooks',
  '.cursor/hooks/VALIDATION.md',
  '.cursor/MCP-SETUP.md',
  '.claude/settings.json.example',
  '.claude/hooks',
  '.claude/loop.md',
  '.speck/mcp',
];

/**
 * Subdirectories inside ALWAYS_OVERWRITE directories that should be preserved
 * across init/upgrade (project-owned extension points).
 *
 * This enables customization without editing template-managed files.
 */
const PRESERVE_SUBDIRS = {
  // Project hook extension points used by .cursor/hooks/hooks/after-file-edit.sh
  '.cursor/hooks/hooks': ['hooks.d'],
};

/**
 * ALWAYS_OVERWRITE directories where PROJECT-CUSTOM subdirectories (ones Speck never
 * shipped) must survive upgrades. Skills are symlinked into .claude/.codex from .cursor;
 * agents are GENERATED per-harness into each runtime dir (see generate-agents.js), so a
 * custom agent subdir is preserved in all three — wholesale replacement would delete it.
 * Anything Speck ships (including retired-skill shims) comes back from the source copy;
 * explicit removals still happen via REMOVE_FILES afterward.
 */
const PRESERVE_UNKNOWN_SUBDIRS = ['.cursor/skills', '.cursor/agents', '.claude/agents', '.codex/agents'];

/**
 * Compute the subdirectories of targetPath that do not exist in sourcePath.
 */
function unknownSubdirs(sourcePath, targetPath) {
  if (!existsSync(targetPath)) return [];
  const sourceEntries = new Set(
    existsSync(sourcePath)
      ? readdirSync(sourcePath).filter(e => statSync(join(sourcePath, e)).isDirectory())
      : []
  );
  return readdirSync(targetPath).filter(e => {
    const p = join(targetPath, e);
    return statSync(p).isDirectory() && !sourceEntries.has(e);
  });
}

/**
 * Files that need smart merging
 */
const SMART_MERGE_FILES = {
  'AGENTS.md': mergeAgentsMd,
  '.gitignore': mergeGitignore,
  '.cursor/hooks/hooks.json': mergeHooksJson,
  '.cursor/mcp.json': mergeMcpJson,
  '.cursor/mcp.json.example': copyMcpExample,
  '.cursor/mcp.project.json.example': copyMcpExample,
};

/**
 * Files that should be skipped if user has customized them
 */
const SKIP_IF_CUSTOMIZED = {
  // v7.6.0: README.md handled by syncProjectReadme() — not copied from Speck repo
};

/**
 * Files/patterns that should NEVER be synced to project repos
 * (test files, internal tooling, etc.)
 */
const SKIP_PATTERNS = [
  /.*-test\.yml$/,       // Test workflow files (e.g., speck-orchestrator-test.yml)
  /^tests\//,            // Test directory
];

/**
 * Check if a file should be skipped during sync
 */
function shouldSkipFile(filePath) {
  return SKIP_PATTERNS.some(pattern => pattern.test(filePath));
}

/**
 * Files that were removed from Speck and should be deleted during upgrade
 */
const REMOVE_FILES = [
  // v4.3.0: Orchestrator disabled — remove from projects on upgrade
  '.github/workflows/speck-orchestrator.yml',
  '.github/workflows/speck-orchestrator-test.yml',
  '.github/workflows/speck-orchestrator-e2e-test.yml',
  '.github/workflows/speck-e2e-cleanup.yml',
  '.github/workflows/copilot-setup-steps.yml',
  '.github/workflows/speck-validation.yml',
  '.github/ISSUE_TEMPLATE/speck-story.yml',
  '.speck/scripts/orchestrate.sh',
  '.github/workflows/speck-update-check.yml',
  '.github/copilot-instructions.md',
  '.github/instructions',
  '.github/pull_request_template.md',
  '.github/workflows/speck-retrospective.yml',
  '.github/workflows/speck-template-feedback.yml',
  '.github/workflows/speck-update-action/action.yml',
  '.github/workflows/speck-validate-pr.yml',
  '.github/workflows/template-sync.yml',
  '.speck/AUTONOMOUS-DEVELOPMENT.md',
  '.speck/DISTRIBUTION.md',
  '.speck/TEMPLATE-FEEDBACK.md',
  '.speck/TEMPLATE-SYNC.md',
  '.speck/templates/context/epic-context.md',
  '.speck/templates/context/project-context.md',
  '.speckignore',
  '.templatesyncignore',
  // v5.0.0: Commands migrated to skills, rules migrated to skills
  '.cursor/commands',
  '.cursor/rules/speck',
  '.claude/commands',
];

// ============================================================
// Smart Merge Functions
// ============================================================

/**
 * Merge AGENTS.md - Speck controls SPECK:START..END, user content preserved
 */
function mergeAgentsMd(sourceContent, targetContent) {
  if (!targetContent) {
    return { content: sourceContent, action: 'create' };
  }
  
  // Extract user content before SPECK:START
  const beforeMatch = targetContent.match(/^([\s\S]*?)<!-- SPECK:START -->/);
  const userBefore = beforeMatch ? beforeMatch[1].trim() : '';
  
  // Extract user content after SPECK:END
  const afterMatch = targetContent.match(/<!-- SPECK:END -->([\s\S]*)$/);
  const userAfter = afterMatch ? afterMatch[1].trim() : '';
  
  // Combine
  let merged = '';
  if (userBefore) {
    merged += userBefore + '\n\n';
  }
  merged += sourceContent;
  if (userAfter) {
    merged += '\n\n' + userAfter;
  }
  
  return { content: merged, action: 'merge' };
}

/**
 * Merge .gitignore - preserve user's file, append missing Speck patterns
 */
function mergeGitignore(sourceContent, targetContent) {
  if (!targetContent) {
    return { content: sourceContent, action: 'create' };
  }
  
  // Get patterns (non-comment, non-empty lines) from both
  const getPatterns = (content) => content
    .split('\n')
    .map(l => l.trim())
    .filter(l => l && !l.startsWith('#'));
  
  const targetPatterns = new Set(getPatterns(targetContent));
  const missingPatterns = getPatterns(sourceContent)
    .filter(pattern => !targetPatterns.has(pattern));
  
  if (missingPatterns.length === 0) {
    return { content: targetContent, action: 'skip' };
  }
  
  // Preserve user's file, append missing Speck patterns at the end
  let merged = targetContent.trimEnd() + '\n';
  merged += '\n# Speck defaults\n';
  merged += missingPatterns.join('\n') + '\n';
  
  return { content: merged, action: 'merge' };
}

/**
 * Merge hooks.json - combine hooks arrays
 */
function mergeHooksJson(sourceContent, targetContent) {
  if (!targetContent) {
    return { content: sourceContent, action: 'create' };
  }
  
  try {
    const source = JSON.parse(sourceContent);
    const target = JSON.parse(targetContent);
    
    const merged = {
      version: source.version || target.version || 1,
      hooks: {}
    };
    
    // Merge each hook type
    const hookTypes = new Set([
      ...Object.keys(source.hooks || {}),
      ...Object.keys(target.hooks || {})
    ]);
    
    for (const hookType of hookTypes) {
      const sourceHooks = source.hooks?.[hookType] || [];
      const targetHooks = target.hooks?.[hookType] || [];
      
      // Deduplicate by command
      const seen = new Set();
      const combined = [];
      for (const hook of [...sourceHooks, ...targetHooks]) {
        const key = JSON.stringify(hook);
        if (!seen.has(key)) {
          seen.add(key);
          combined.push(hook);
        }
      }
      
      merged.hooks[hookType] = combined;
    }
    
    return { 
      content: JSON.stringify(merged, null, 2) + '\n', 
      action: 'merge' 
    };
  } catch (e) {
    // If parsing fails, overwrite with source
    return { content: sourceContent, action: 'update' };
  }
}

/**
 * Merge mcp.json - user config takes precedence
 */
function mergeMcpJson(sourceContent, targetContent) {
  if (!targetContent) {
    // No user mcp.json yet - don't create one, they need to add secrets
    return { content: null, action: 'skip' };
  }
  
  try {
    const source = JSON.parse(sourceContent);
    const target = JSON.parse(targetContent);
    
    // Merge servers - user config takes precedence
    const merged = {
      mcpServers: {
        ...source.mcpServers,  // Speck defaults
        ...target.mcpServers   // User overrides
      }
    };
    
    return { 
      content: JSON.stringify(merged, null, 2) + '\n', 
      action: 'merge' 
    };
  } catch (e) {
    return { content: null, action: 'skip' };
  }
}

/**
 * Copy MCP example file
 */
function copyMcpExample(sourceContent, targetContent) {
  // Always update the example
  return { content: sourceContent, action: 'update' };
}

// ============================================================
// Project README (root) — project identity, not Speck marketing
// ============================================================

const PROJECT_README_TEMPLATE = '.speck/templates/project/readme-template.md';

/**
 * Read the project README skeleton template from the target workspace
 */
export function readProjectReadmeTemplate(targetDir) {
  const templatePath = join(targetDir, PROJECT_README_TEMPLATE);
  if (!existsSync(templatePath)) {
    return null;
  }
  return readFileSync(templatePath, 'utf-8');
}

/**
 * Extract the managed footer block (SPECK:START..END) from template content
 */
export function extractReadmeFooter(templateContent) {
  const match = templateContent.match(/<!-- SPECK:START -->[\s\S]*?<!-- SPECK:END -->/);
  return match ? match[0] : null;
}

/**
 * Detect legacy Speck marketing README copied by pre-v7.6 init/upgrade
 */
export function isSpeckMarketingReadme(content) {
  if (!content) return false;
  const firstLine = content.split('\n')[0].trim();
  if (!firstLine.startsWith('# Speck')) return false;
  return (
    content.includes('Spec-driven development methodology') ||
    content.includes('npx github:telum-ai/speck init')
  );
}

/**
 * Merge project README — user content before SPECK:START preserved, footer updated
 */
export function mergeReadme(templateContent, targetContent) {
  if (!targetContent) {
    return { content: templateContent, action: 'create' };
  }

  const footer = extractReadmeFooter(templateContent);
  if (!footer) {
    return { content: targetContent, action: 'skip' };
  }

  const beforeMatch = targetContent.match(/^([\s\S]*?)<!-- SPECK:START -->/);
  const userBefore = beforeMatch ? beforeMatch[1].trimEnd() : targetContent.trimEnd();

  const afterMatch = targetContent.match(/<!-- SPECK:END -->([\s\S]*)$/);
  const userAfter = afterMatch ? afterMatch[1].trim() : '';

  let merged = userBefore ? userBefore + '\n\n' : '';
  merged += footer;
  if (userAfter) {
    merged += '\n\n' + userAfter;
  }
  merged += '\n';

  return { content: merged, action: 'merge' };
}

/**
 * Sync root README.md — never copy Speck repo marketing README
 */
function syncProjectReadme(targetDir, results, verbose = false) {
  const readmePath = join(targetDir, 'README.md');
  const templateContent = readProjectReadmeTemplate(targetDir);

  if (!templateContent) {
    results.errors.push({
      file: 'README.md',
      error: `Missing template at ${PROJECT_README_TEMPLATE}`,
    });
    return { repaired: false };
  }

  try {
    const targetContent = existsSync(readmePath)
      ? readFileSync(readmePath, 'utf-8')
      : null;

    if (!targetContent) {
      mkdirSync(dirname(readmePath), { recursive: true });
      writeFileSync(readmePath, templateContent);
      results.created.push('README.md');
      if (verbose) console.log('  ✅ Created: README.md (project skeleton)');
      return { repaired: false };
    }

    if (isSpeckMarketingReadme(targetContent)) {
      writeFileSync(readmePath, templateContent);
      results.updated.push('README.md');
      if (verbose) {
        console.log('  🔧 Repaired: README.md (replaced Speck marketing with project skeleton)');
      }
      return { repaired: true };
    }

    if (targetContent.includes('<!-- SPECK:START -->') && targetContent.includes('<!-- SPECK:END -->')) {
      const result = mergeReadme(templateContent, targetContent);
      if (result.action === 'skip') {
        results.skipped.push('README.md');
        if (verbose) console.log('  ⏭️  Skipped: README.md');
        return { repaired: false };
      }
      writeFileSync(readmePath, result.content);
      results.merged.push('README.md');
      if (verbose) console.log('  ✅ Merged: README.md (footer only)');
      return { repaired: false };
    }

    results.skipped.push('README.md');
    if (verbose) console.log('  ⏭️  Skipped: README.md (user-owned, no SPECK markers)');
    return { repaired: false };
  } catch (error) {
    results.errors.push({ file: 'README.md', error: error.message });
    return { repaired: false };
  }
}

// ============================================================
// Skip-if-customized detection
// ============================================================

// ============================================================
// Core sync functions
// ============================================================

/**
 * Download and extract a release to a temp directory
 */
export async function extractRelease(tag, token = null) {
  const tempDir = join(tmpdir(), `speck-${tag}-${Date.now()}`);
  mkdirSync(tempDir, { recursive: true });
  
  let command;
  if (token) {
    // Private repo - use API with auth
    command = `curl -sL -H "Authorization: token ${token}" "https://api.github.com/repos/telum-ai/speck/tarball/${tag}" | tar -xz -C "${tempDir}" --strip-components=1`;
  } else {
    // Public repo - direct tarball URL
    command = `curl -sL "https://github.com/telum-ai/speck/archive/refs/tags/${tag}.tar.gz" | tar -xz -C "${tempDir}" --strip-components=1`;
  }
  
  execSync(command, { stdio: 'pipe' });
  
  return tempDir;
}

/**
 * Recursively copy a directory, respecting SKIP_PATTERNS
 */
function copyDir(src, dest, baseDir = null) {
  mkdirSync(dest, { recursive: true });
  baseDir = baseDir || src;
  
  for (const entry of readdirSync(src)) {
    const srcPath = join(src, entry);
    const destPath = join(dest, entry);
    const relativePath = relative(baseDir, srcPath);
    
    // Skip files matching skip patterns
    if (shouldSkipFile(relativePath) || shouldSkipFile(entry)) {
      continue;
    }
    
    if (statSync(srcPath).isDirectory()) {
      copyDir(srcPath, destPath, baseDir);
    } else {
      copyFileSync(srcPath, destPath);
    }
  }
}

/**
 * Create a relative symlink from a target runtime directory back to .cursor/.
 *
 * Uses symlinks for zero-drift cross-tool compatibility (Cursor, Claude Code, Codex).
 * Git tracks symlinks natively; archives preserve them on Unix.
 */
function symlinkCursorDir(targetDir, runtimeDir, relativeDir) {
  const sourceDir = join(targetDir, '.cursor', relativeDir);
  const destDir = join(targetDir, runtimeDir, relativeDir);

  if (!existsSync(sourceDir) || !statSync(sourceDir).isDirectory()) {
    return { action: 'skip', reason: `missing .cursor/${relativeDir}` };
  }

  mkdirSync(join(targetDir, runtimeDir), { recursive: true });

  if (existsSync(destDir)) {
    rmSync(destDir, { recursive: true, force: true });
  }

  symlinkSync(join('..', '.cursor', relativeDir), destDir);
  return { action: 'sync', path: `${runtimeDir}/${relativeDir}/` };
}

/**
 * Migrate legacy `.claude/agents` and `.codex/agents` SYMLINKS (older Speck symlinked them
 * into `.cursor/agents`) to nothing, so the real per-harness generated dirs can be copied in
 * their place. Uses lstat + unlink so we remove the LINK, never follow it into `.cursor`.
 */
function unlinkLegacyAgentSymlinks(targetDir) {
  for (const runtimeDir of ['.claude', '.codex']) {
    const linkPath = join(targetDir, runtimeDir, 'agents');
    if (existsSync(linkPath) && lstatSync(linkPath).isSymbolicLink()) {
      unlinkSync(linkPath);
    }
  }
}

/**
 * Escape regex special characters in a string
 */
function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * Install or update the Git pre-commit hook loader safely and non-destructively
 */
function installPreCommitHook(targetDir, verbose = false) {
  const gitDir = join(targetDir, '.git');
  if (!existsSync(gitDir)) return;

  const hooksDir = join(gitDir, 'hooks');
  if (!existsSync(hooksDir)) {
    try {
      mkdirSync(hooksDir, { recursive: true });
    } catch (e) {
      if (verbose) console.log(`  ⚠️  Failed to create Git hooks directory: ${e.message}`);
      return;
    }
  }

  const preCommitPath = join(hooksDir, 'pre-commit');
  const loaderStart = '# === SPECK HOOK START ===';
  const loaderEnd = '# === SPECK HOOK END ===';
  
  const loaderContent = `${loaderStart}
if [ -f .speck/scripts/validation/pre-commit-hook.sh ]; then
  bash .speck/scripts/validation/pre-commit-hook.sh
fi
${loaderEnd}`;

  try {
    let hookContent = '';
    let isNew = true;

    if (existsSync(preCommitPath)) {
      hookContent = readFileSync(preCommitPath, 'utf-8');
      isNew = false;
    }

    if (hookContent.includes(loaderStart) && hookContent.includes(loaderEnd)) {
      // Safely replace the old block with the new block (keeps it updated)
      const regex = new RegExp(`${escapeRegExp(loaderStart)}[\\s\\S]*?${escapeRegExp(loaderEnd)}`);
      hookContent = hookContent.replace(regex, loaderContent);
      writeFileSync(preCommitPath, hookContent, { mode: 0o755 });
      if (verbose) console.log('  ✅ Updated Speck pre-commit Git hook loader');
    } else {
      // Append the block to existing hook or write new
      if (isNew) {
        hookContent = `#!/usr/bin/env bash\n\n${loaderContent}\n`;
      } else {
        hookContent = hookContent.trimEnd() + `\n\n${loaderContent}\n`;
      }
      writeFileSync(preCommitPath, hookContent, { mode: 0o755 });
      if (verbose) console.log('  ✅ Installed Speck pre-commit Git hook loader');
    }
    
    // Ensure it is executable on Unix
    try {
      execSync(`chmod +x "${preCommitPath}"`, { stdio: 'ignore' });
    } catch {}
  } catch (error) {
    if (verbose) console.log(`  ⚠️  Failed to install Git pre-commit hook: ${error.message}`);
  }
}

/**
 * Install or update the Git commit-msg hook loader safely and non-destructively
 */
function installCommitMsgHook(targetDir, verbose = false) {
  const gitDir = join(targetDir, '.git');
  if (!existsSync(gitDir)) return;

  const hooksDir = join(gitDir, 'hooks');
  if (!existsSync(hooksDir)) {
    try {
      mkdirSync(hooksDir, { recursive: true });
    } catch (e) {
      if (verbose) console.log(`  ⚠️  Failed to create Git hooks directory: ${e.message}`);
      return;
    }
  }

  const commitMsgPath = join(hooksDir, 'commit-msg');
  const loaderStart = '# === SPECK COMMIT-MSG HOOK START ===';
  const loaderEnd = '# === SPECK COMMIT-MSG HOOK END ===';
  
  const loaderContent = `${loaderStart}
if [ -f .speck/scripts/validation/commit-msg-hook.sh ]; then
  bash .speck/scripts/validation/commit-msg-hook.sh "$1"
fi
${loaderEnd}`;

  try {
    let hookContent = '';
    let isNew = true;

    if (existsSync(commitMsgPath)) {
      hookContent = readFileSync(commitMsgPath, 'utf-8');
      isNew = false;
    }

    if (hookContent.includes(loaderStart) && hookContent.includes(loaderEnd)) {
      // Safely replace the old block with the new block (keeps it updated)
      const regex = new RegExp(`${escapeRegExp(loaderStart)}[\\s\\S]*?${escapeRegExp(loaderEnd)}`);
      hookContent = hookContent.replace(regex, loaderContent);
      writeFileSync(commitMsgPath, hookContent, { mode: 0o755 });
      if (verbose) console.log('  ✅ Updated Speck commit-msg Git hook loader');
    } else {
      // Append the block to existing hook or write new
      if (isNew) {
        hookContent = `#!/usr/bin/env bash\n\n${loaderContent}\n`;
      } else {
        hookContent = hookContent.trimEnd() + `\n\n${loaderContent}\n`;
      }
      writeFileSync(commitMsgPath, hookContent, { mode: 0o755 });
      if (verbose) console.log('  ✅ Installed Speck commit-msg Git hook loader');
    }
    
    // Ensure it is executable on Unix
    try {
      execSync(`chmod +x "${commitMsgPath}"`, { stdio: 'ignore' });
    } catch {}
  } catch (error) {
    if (verbose) console.log(`  ⚠️  Failed to install Git commit-msg hook: ${error.message}`);
  }
}

/**
 * Plan and execute smart sync
 */
export function smartSync(sourceDir, targetDir, options = {}) {
  const results = {
    created: [],
    updated: [],
    merged: [],
    skipped: [],
    removed: [],
    errors: [],
  };
  
  const verbose = options.verbose || false;
  
  // 0. Migrate legacy .claude/.codex agent symlinks → removed, so the real generated agent
  //    dirs can be copied in as ALWAYS_OVERWRITE below. Safe (unlinks the link, not its target).
  unlinkLegacyAgentSymlinks(targetDir);

  // 1. Handle ALWAYS_OVERWRITE patterns
  for (const pattern of ALWAYS_OVERWRITE) {
    // Skip patterns that match skip rules
    if (shouldSkipFile(pattern)) continue;
    
    const sourcePath = join(sourceDir, pattern);
    const targetPath = join(targetDir, pattern);
    
    if (!existsSync(sourcePath)) continue;
    
    try {
      const isDir = statSync(sourcePath).isDirectory();
      
      if (isDir) {
        // Remove existing and copy entire directory
        // (but preserve any project-owned extension points configured under this directory).
        const preserveSubdirs = [...(PRESERVE_SUBDIRS[pattern] || [])];
        if (PRESERVE_UNKNOWN_SUBDIRS.includes(pattern)) {
          preserveSubdirs.push(...unknownSubdirs(sourcePath, targetPath));
        }
        const preserved = [];
        let preserveTmpRoot = null;

        if (preserveSubdirs.length > 0 && existsSync(targetPath)) {
          preserveTmpRoot = join(
            tmpdir(),
            `speck-preserve-${Date.now()}-${Math.random().toString(16).slice(2)}`
          );
          mkdirSync(preserveTmpRoot, { recursive: true });

          for (const subdir of preserveSubdirs) {
            const existingSubdirPath = join(targetPath, subdir);
            if (existsSync(existingSubdirPath) && statSync(existingSubdirPath).isDirectory()) {
              const tmpPath = join(preserveTmpRoot, subdir);
              copyDir(existingSubdirPath, tmpPath);
              preserved.push({ subdir, tmpPath });
            }
          }
        }

        if (existsSync(targetPath)) {
          rmSync(targetPath, { recursive: true, force: true });
        }
        copyDir(sourcePath, targetPath);

        // Restore preserved extension points (overlay on top of copied content).
        for (const { subdir, tmpPath } of preserved) {
          const restorePath = join(targetPath, subdir);
          copyDir(tmpPath, restorePath);
        }

        // Cleanup temp preserve dir
        if (preserveTmpRoot) {
          rmSync(preserveTmpRoot, { recursive: true, force: true });
        }

        results.updated.push(pattern + '/');
      } else {
        // Copy single file
        mkdirSync(dirname(targetPath), { recursive: true });
        copyFileSync(sourcePath, targetPath);
        
        if (existsSync(targetPath)) {
          results.updated.push(pattern);
        } else {
          results.created.push(pattern);
        }
      }
      
      if (verbose) console.log(`  ✅ Updated: ${pattern}`);
    } catch (error) {
      results.errors.push({ file: pattern, error: error.message });
    }
  }
  
  // 2. Handle SMART_MERGE files
  for (const [file, mergeFn] of Object.entries(SMART_MERGE_FILES)) {
    const sourcePath = join(sourceDir, file);
    const targetPath = join(targetDir, file);
    
    if (!existsSync(sourcePath)) continue;
    
    try {
      const sourceContent = readFileSync(sourcePath, 'utf-8');
      const targetContent = existsSync(targetPath) 
        ? readFileSync(targetPath, 'utf-8') 
        : null;
      
      const result = mergeFn(sourceContent, targetContent);
      
      if (result.action === 'skip' || result.content === null) {
        results.skipped.push(file);
        if (verbose) console.log(`  ⏭️  Skipped: ${file}`);
        continue;
      }
      
      mkdirSync(dirname(targetPath), { recursive: true });
      writeFileSync(targetPath, result.content);
      
      if (result.action === 'create') {
        results.created.push(file);
        if (verbose) console.log(`  ✅ Created: ${file}`);
      } else if (result.action === 'merge') {
        results.merged.push(file);
        if (verbose) console.log(`  ✅ Merged: ${file}`);
      } else {
        results.updated.push(file);
        if (verbose) console.log(`  ✅ Updated: ${file}`);
      }
    } catch (error) {
      results.errors.push({ file, error: error.message });
    }
  }
  
  // 3. Handle SKIP_IF_CUSTOMIZED files
  for (const [file, isCustomizedFn] of Object.entries(SKIP_IF_CUSTOMIZED)) {
    const sourcePath = join(sourceDir, file);
    const targetPath = join(targetDir, file);

    if (!existsSync(sourcePath)) continue;

    try {
      const sourceContent = readFileSync(sourcePath, 'utf-8');
      const targetContent = existsSync(targetPath)
        ? readFileSync(targetPath, 'utf-8')
        : null;

      if (targetContent && isCustomizedFn(sourceContent, targetContent)) {
        results.skipped.push(file);
        if (verbose) console.log(`  ⏭️  Skipped (customized): ${file}`);
        continue;
      }

      mkdirSync(dirname(targetPath), { recursive: true });
      writeFileSync(targetPath, sourceContent);

      if (targetContent) {
        results.updated.push(file);
        if (verbose) console.log(`  ✅ Updated: ${file}`);
      } else {
        results.created.push(file);
        if (verbose) console.log(`  ✅ Created: ${file}`);
      }
    } catch (error) {
      results.errors.push({ file, error: error.message });
    }
  }

  // 4. Sync project README (never copy Speck repo marketing README)
  const readmeSync = syncProjectReadme(targetDir, results, verbose);
  results.readmeRepaired = readmeSync.repaired;

  // 5. Symlink Cursor SKILLS into .claude and .codex for cross-tool parity. Agents are NOT
  //    symlinked — each harness has a different model vocabulary, so agents are generated
  //    per-harness (generate-agents.js) and copied as real dirs via ALWAYS_OVERWRITE above.
  for (const runtimeDir of ['.claude', '.codex']) {
    for (const relativeDir of ['skills']) {
      try {
        const symlinkResult = symlinkCursorDir(targetDir, runtimeDir, relativeDir);
        if (symlinkResult.action === 'sync') {
          results.updated.push(symlinkResult.path);
          if (verbose) {
            console.log(`  ✅ Symlinked: ${symlinkResult.path} → .cursor/${relativeDir}/`);
          }
        }
      } catch (error) {
        results.errors.push({ file: `${runtimeDir}/${relativeDir}`, error: error.message });
      }
    }
  }

  // 6. Remove files that were deleted from Speck
  for (const deletedFile of REMOVE_FILES) {
    const targetPath = join(targetDir, deletedFile);
    
    try {
      if (existsSync(targetPath)) {
        const isDir = statSync(targetPath).isDirectory();
        
        if (isDir) {
          rmSync(targetPath, { recursive: true, force: true });
        } else {
          rmSync(targetPath, { force: true });
        }
        
        results.removed.push(deletedFile);
        if (verbose) {
          console.log(`  🗑️  Removed: ${deletedFile}`);
        }
      }
    } catch (error) {
      results.errors.push({ file: deletedFile, error: error.message });
    }
  }
  
  // 7. Install or update Git pre-commit and commit-msg hook loaders
  installPreCommitHook(targetDir, verbose);
  installCommitMsgHook(targetDir, verbose);
  
  return results;
}

/**
 * Check if Speck is initialized in a directory
 */
export function isSpeckInitialized(targetDir) {
  const markers = [
    join(targetDir, '.speck', 'VERSION'),
    join(targetDir, '.speck', 'README.md'),
    join(targetDir, '.cursor', 'skills', 'speck', 'SKILL.md'),
    // Legacy markers for pre-v5 installations
    join(targetDir, '.cursor', 'commands', 'speck.md'),
  ];
  return markers.some(path => existsSync(path));
}

/**
 * Get the current Speck version in a directory
 */
export function getCurrentVersion(targetDir) {
  const versionPath = join(targetDir, '.speck', 'VERSION');
  if (existsSync(versionPath)) {
    return readFileSync(versionPath, 'utf-8').trim();
  }
  
  // Fallback: parse from AGENTS.md for older installations
  if (isSpeckInitialized(targetDir)) {
    const agentsPath = join(targetDir, 'AGENTS.md');
    if (existsSync(agentsPath)) {
      const content = readFileSync(agentsPath, 'utf-8');
      const match = content.match(/\*\*Speck Version\*\*:\s*(\d+\.\d+)/);
      if (match) {
        return `v${match[1]}.0`;
      }
    }
  }
  
  return null;
}

/**
 * Save the current version to .speck/VERSION
 */
export function saveVersion(targetDir, version) {
  const versionPath = join(targetDir, '.speck', 'VERSION');
  mkdirSync(dirname(versionPath), { recursive: true });
  writeFileSync(versionPath, version);
}
