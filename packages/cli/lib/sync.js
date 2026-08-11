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
  '.speck/recipes',
  '.speck/reference',
  '.speck/scripts',
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
 * shipped) must survive upgrades. Skills are symlinked into .claude/.codex/.agents from
 * .cursor; agents are GENERATED per-harness into each runtime dir (see generate-agents.js),
 * so a custom agent subdir is preserved — wholesale replacement would delete it.
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
  'CLAUDE.md': mergeClaudeMd,
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
  // Root README.md is handled by syncProjectReadme(), not this generic map.
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
  // Retired hosted orchestrator and repository-management files.
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
  // Retired command/rule surfaces replaced by skills.
  '.cursor/commands',
  '.cursor/rules/speck',
  '.claude/commands',
  // Retired generic domain/integration skills; recipes + current official docs replace them.
  '.cursor/skills/clerk-authentication',
  '.cursor/skills/oauth-implementation',
  '.cursor/skills/stripe-integration',
  '.cursor/skills/revenuecat-integration',
  '.cursor/skills/saas-billing-patterns',
  '.cursor/skills/supabase-integration',
  '.cursor/skills/firebase-integration',
  '.cursor/skills/resend-integration',
  '.cursor/skills/sentry-integration',
  '.cursor/skills/posthog-integration',
  '.cursor/skills/tanstack-query',
  '.cursor/skills/progressive-web-apps',
  '.cursor/skills/websocket-implementation',
  '.cursor/skills/multi-tenancy-patterns',
  '.cursor/skills/offline-first-architecture',
  '.cursor/skills/serverless-architecture',
  '.cursor/skills/docker-containerization',
  '.cursor/skills/github-actions-cicd',
  '.cursor/skills/gdpr-compliance',
  '.cursor/skills/model-selection',
  '.cursor/skills/ai-api-integration',
  // Retired host-specific visual-testing skills folded into visual-testing references.
  '.cursor/skills/visual-testing-web',
  '.cursor/skills/visual-testing-desktop-electron',
  '.cursor/skills/visual-testing-desktop-tauri',
  '.cursor/skills/visual-testing-extension',
  '.cursor/skills/visual-testing-mobile-flutter',
  '.cursor/skills/visual-testing-mobile-react-native',
  // Framework-only evaluation and feedback leaked through the old template exporter.
  '.speck/eval',
  '.speck/feedback',
  // Runtime framework material no longer owns project-learned patterns. Remove only
  // the exact files Speck previously shipped; preserve every project-created sibling.
  '.speck/patterns/constitution-as-code.md',
  '.speck/patterns/library/README.md',
  '.speck/patterns/learned/README.md',
  '.speck/patterns/learned/process/parallel-epic-execution.md',
  '.speck/patterns/learned/testing/class-gate-not-a-third-fix.md',
  '.speck/patterns/learned/testing/inverted-polarity-exception-registry.md',
  '.speck/patterns/learned/testing/mirror-sweep.md',
  '.speck/patterns/learned/testing/quality-bound-vs-existence-bound.md',
  '.speck/patterns/learned/testing/recipe-duplicated-rule-schema-type-parity.md',
  '.speck/patterns/learned/testing/recipe-failed-read-is-not-empty.md',
  '.speck/patterns/learned/testing/recipe-growth-table-bounded-select.md',
  '.speck/patterns/learned/testing/recipe-pii-redaction-chokepoint.md',
  '.speck/patterns/learned/testing/recipe-production-writer-registry.md',
  '.speck/patterns/learned/testing/recipe-raw-enum-label-shape.md',
  '.speck/patterns/learned/testing/two-carrier-interval-doctrine.md',
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
 * Merge CLAUDE.md - Speck owns only its managed import block.
 * Existing project instructions before/after the block remain byte-stable apart from
 * surrounding blank-line normalization. A legacy bare @AGENTS.md import is adopted.
 */
function mergeClaudeMd(sourceContent, targetContent) {
  const start = '<!-- SPECK:START -->';
  const end = '<!-- SPECK:END -->';
  const sourceMatch = sourceContent.match(/<!-- SPECK:START -->[\s\S]*?<!-- SPECK:END -->/);
  if (!sourceMatch) {
    throw new Error('source CLAUDE.md is missing the managed SPECK block');
  }
  const managed = sourceMatch[0];

  if (!targetContent) {
    return { content: managed + '\n', action: 'create' };
  }

  const blockPattern = /<!-- SPECK:START -->[\s\S]*?<!-- SPECK:END -->/;
  if (blockPattern.test(targetContent)) {
    const content = targetContent.replace(blockPattern, managed);
    return { content: content.trimEnd() + '\n', action: content === targetContent ? 'skip' : 'merge' };
  }

  // Older preview builds wrote a bare import. Adopt it into the managed block so repeated
  // upgrades cannot accumulate duplicate imports.
  const userContent = targetContent
    .split('\n')
    .filter(line => line.trim() !== '@AGENTS.md')
    .join('\n')
    .trim();
  const content = userContent ? `${managed}\n\n${userContent}\n` : `${managed}\n`;
  return { content, action: 'merge' };
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

/** Shell words that open a nesting level, and the words that close one again. */
const BLOCK_OPENERS = new Set(['if', 'case', 'while', 'until', 'for', 'select', '{']);
const BLOCK_CLOSERS = new Set(['fi', 'esac', 'done', '}']);

/**
 * Strip a trailing `\r` and a trailing comment so a line can be read as shell WORDS.
 * The comment strip only fires on a `#` that starts a word, so `echo "# not a comment"` and
 * `${VAR#prefix}` are left alone.
 */
function hookCodeOf(line) {
  return line.replace(/\r$/, '').replace(/(^|[\s;])#.*$/, '$1');
}

/**
 * How much this line changes the shell's block-nesting depth.
 *
 * Deliberately keyword-only: `(` and `)` are NOT counted, because `case` patterns (`a) … ;;`),
 * array assignments (`ARGS=(hook-impl …)`) and command substitution make paren arithmetic wrong
 * far more often than right. A miscount that reads too DEEP only costs a relocation we then
 * decline — the block appends at the end, exactly as pre-9.6 Speck did — whereas a miscount that
 * reads too SHALLOW is the defect this exists to prevent. So the conservative direction is the
 * default direction.
 */
function hookBlockDepthDelta(line) {
  let delta = 0;
  for (const token of hookCodeOf(line).split(/[\s;&|]+/)) {
    if (!token) continue;
    if (BLOCK_OPENERS.has(token)) delta++;
    else if (BLOCK_CLOSERS.has(token)) delta--;
  }
  return delta;
}

/**
 * Find the first line of a hook after which nothing can ever run.
 *
 * THE SCAR: Speck appended its loader block to the END of an existing hook, unconditionally.
 * A pre-commit.com generated hook terminates in `exec … -mpre_commit "${ARGS[@]}"`, and `exec`
 * REPLACES the shell process — so the appended block was structurally unreachable. chmod +x
 * succeeded, the marker was in the file, and every commit-path gate in that repo was silently
 * dark. This is the whole backlog's thesis living in Speck's own installer: a guard that never
 * executes because a broad adjacent default shadows it.
 *
 * Only genuinely TOP-LEVEL terminators count, and top level is a matter of NESTING, not of
 * column. The first cut read column 0 as top level, which is wrong for every hand-rolled hook
 * whose body simply is not indented:
 *
 *     if [ -n "$SKIP_HOOKS" ]; then
 *     exit 0
 *     fi
 *
 * That `exit 0` fires only on the repo's own documented bypass, but at column 0 it read as
 * unconditional — so the block was spliced ABOVE the guard, and with `|| exit $?` making the
 * block fatal the bypass stopped exempting Speck's gates entirely. Speck would then block a
 * commit the project had deliberately exempted. So we track depth while scanning and accept a
 * candidate only at depth 0. Indentation is still respected on top of that (the regexes are
 * anchored at column 0), because an indented terminator is conditional either way.
 *
 * `exec` with only redirections (`exec >log 2>&1`, `exec 3<&0`) does NOT replace the process —
 * it rewires the current shell's file descriptors and execution continues. Treating that as a
 * terminator would relocate the Speck block for no reason, so it is excluded explicitly.
 *
 * CRLF is handled explicitly: in JS `.` does not match `\r`, so `/^exec[ \t]+(.+)$/` silently
 * failed on `exec echo "…"\r` and a Windows/WSL-generated hook came back with the block appended
 * BELOW the exec — still dark, and with no warning to say so. The raw line is what is returned,
 * so the operator sees their file, not our normalisation.
 *
 * Returns { index, line } or null.
 */
function findHookTerminator(hookContent) {
  const lines = hookContent.split('\n');
  let depth = 0;
  let heredoc = null;
  let continued = false;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const code = line.replace(/\r$/, '');

    // A heredoc body is DATA, not code. `exit 0` printed inside `cat <<EOF … EOF` is text the
    // hook emits, and since the loader is now spliced immediately above the terminator, reading
    // one as code would splice Speck's block into the middle of someone's heredoc.
    if (heredoc) {
      const end = heredoc.stripTabs ? code.replace(/^\t+/, '') : code;
      if (end === heredoc.tag) heredoc = null;
      continue;
    }

    // `continued` means the PREVIOUS line ended in a backslash, so this line's words are
    // arguments to that command — `printf '%s\n' \` / `exec echo x` is an argument list, not a
    // process replacement. Splicing between the halves would break the command outright, and its
    // words are not keywords either, so it contributes no depth.
    if (depth === 0 && !continued) {
      const execMatch = /^exec[ \t]+(.+)$/.exec(code);
      if (execMatch && !/^[0-9]*[<>&|]/.test(execMatch[1].trim())) {
        return { index: i, line };
      }
      // `exit`, `exit 0`, `exit $rc`, with an optional trailing comment.
      if (/^exit([ \t]+[^#\s]+)?[ \t]*(#.*)?$/.test(code)) {
        return { index: i, line };
      }
    }

    if (!continued) {
      // Clamped at 0: an unbalanced closer we mispaired must not drive the counter negative and
      // hand us a phantom top level further down the file.
      depth = Math.max(0, depth + hookBlockDepthDelta(code));
    }
    heredoc = heredocOpenerOf(code);
    continued = /(?:^|[^\\])(?:\\\\)*\\$/.test(code);
  }
  return null;
}

/** The heredoc this line opens, or null. `<<<` is a herestring and opens nothing. */
function heredocOpenerOf(line) {
  const m = /(?:^|[^<])<<(-?)[ \t]*(['"]?)([A-Za-z_][A-Za-z0-9_]*)\2/.exec(hookCodeOf(line));
  return m ? { tag: m[3], stripTabs: m[1] === '-' } : null;
}

/**
 * Splice the loader block into a hook so that it actually runs.
 *
 * With no terminator, appending is right: the Speck gate runs last, after whatever the project
 * already does. With a terminator, the block goes IMMEDIATELY ABOVE it — as late as it legally
 * can, not as early as it legally can.
 *
 * THE SECOND SCAR: the first cut inserted as early as possible, skipping only the shebang and
 * `set`/`shopt`. That is wrong twice over.
 *
 *   1. Environment. A hook that exports a PATH or sources nvm/asdf/pyenv before its terminator
 *      ran Speck's gates in a different environment than every other line of that hook — and
 *      Speck's sub-gates DEGRADE rather than fail when python3 or rg is missing, so the effect
 *      was not a crash but a quietly smaller gate.
 *   2. Guards. A hook shaped `if [ -n "$SKIP_HOOKS" ]; then` / `exit 0` / `fi` / `exec …` has a
 *      real terminator below a real bypass. Inserting at the top put Speck's block ABOVE the
 *      bypass, and with `|| exit $?` making the block fatal, the repo's documented escape hatch
 *      stopped exempting Speck's gates — Speck would block a commit the project had deliberately
 *      exempted. Both are the same mistake: assuming everything above the terminator is preamble.
 *
 * Inserting immediately above the terminator is also the most conservative position available:
 * pre-9.6 Speck appended at the very end, so the latest legal spot is the smallest possible
 * change in gate ordering for every repo that upgrades.
 *
 * Returns { content, shadow } where `shadow` is the terminator that forced the relocation.
 */
function insertHookLoader(hookContent, loaderContent) {
  const shadow = findHookTerminator(hookContent);
  if (!shadow) {
    return { content: hookContent.trimEnd() + `\n\n${loaderContent}\n`, shadow: null };
  }

  const lines = hookContent.split('\n');
  // Never above the shebang — it has to stay line 1 for the kernel to honour it.
  const floor = lines[0] && lines[0].replace(/\r$/, '').startsWith('#!') ? 1 : 0;
  const at = Math.max(shadow.index, floor);
  lines.splice(at, 0, ...loaderContent.split('\n'), '');
  return { content: lines.join('\n').trimEnd() + '\n', shadow };
}

/**
 * Produce the new hook body: fresh install, in-place update, or rescue.
 *
 * An already-installed block is REMOVED before re-inserting rather than replaced in place —
 * because a block installed by an older Speck may itself be sitting in the dead zone, and
 * replacing it there would faithfully keep it dead. Removing and re-inserting re-runs the
 * reachability decision on every sync, which is what makes the upgrade self-healing.
 */
function applyHookLoader(existingContent, loaderStart, loaderEnd, loaderContent) {
  if (!existingContent.trim()) {
    return { content: `#!/usr/bin/env bash\n\n${loaderContent}\n`, shadow: null, isNew: true };
  }
  const blockRegex = new RegExp(`\\n*${escapeRegExp(loaderStart)}[\\s\\S]*?${escapeRegExp(loaderEnd)}\\n*`);
  const hadBlock = blockRegex.test(existingContent);
  const body = hadBlock ? existingContent.replace(blockRegex, '\n') : existingContent;
  const { content, shadow } = insertHookLoader(body, loaderContent);
  return { content, shadow, isNew: false, hadBlock };
}

/**
 * Report a relocation loudly. NOT gated on `verbose`: a shadowed hook means the project's
 * commit-path gates were dark, and silence is precisely the failure mode being repaired.
 */
function warnHookShadow(targetDir, hookName, shadow) {
  console.log(`  ⚠️  .git/hooks/${hookName} line ${shadow.index + 1} is \`${shadow.line.trim()}\` — nothing below it can ever run.`);
  console.log(`      Speck's block was inserted immediately ABOVE that line so the ${hookName} gates stay live —`);
  console.log(`      after everything else this hook does, so your environment setup and your own`);
  console.log(`      skip guards still apply to it.`);
  if (existsSync(join(targetDir, '.pre-commit-config.yaml'))) {
    console.log(`      This hook is managed by pre-commit.com. The durable fix is to let pre-commit own the gate —`);
    console.log(`      add to .pre-commit-config.yaml:`);
    console.log(`        - repo: local`);
    console.log(`          hooks:`);
    console.log(`            - id: speck-${hookName}`);
    console.log(`              name: Speck ${hookName} gates`);
    console.log(`              entry: bash .speck/scripts/validation/${hookName}-hook.sh`);
    console.log(`              language: system`);
    if (hookName === 'commit-msg') {
      // pre-commit passes the message file as the single argument, which is what the gate reads.
      console.log(`              stages: [commit-msg]`);
    } else {
      console.log(`              pass_filenames: false`);
    }
  }
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
  
  // `|| exit $?` is load-bearing, not belt-and-braces. When the block is the LAST thing in
  // the hook, the hook's exit status is the gate's status for free. The moment the block is
  // relocated above a terminator (see insertHookLoader) that stops being true — a failing
  // gate would print its complaint and the commit would sail through anyway. Same dead-guard
  // failure, different hat. Propagating the status explicitly makes the block fatal wherever
  // it sits.
  const loaderContent = `${loaderStart}
if [ -f .speck/scripts/validation/pre-commit-hook.sh ]; then
  bash .speck/scripts/validation/pre-commit-hook.sh || exit $?
fi
${loaderEnd}`;

  try {
    const existing = existsSync(preCommitPath) ? readFileSync(preCommitPath, 'utf-8') : '';
    const { content, shadow, isNew, hadBlock } = applyHookLoader(existing, loaderStart, loaderEnd, loaderContent);
    writeFileSync(preCommitPath, content, { mode: 0o755 });

    if (shadow) warnHookShadow(targetDir, 'pre-commit', shadow);
    if (verbose) {
      console.log(hadBlock
        ? '  ✅ Updated Speck pre-commit Git hook loader'
        : `  ✅ Installed Speck pre-commit Git hook loader${isNew ? '' : ' into the existing hook'}`);
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
  
  // `|| exit $?` — see the pre-commit loader: relocation above a terminator costs the block
  // its position as the hook's last command, and with it the free exit-status propagation.
  const loaderContent = `${loaderStart}
if [ -f .speck/scripts/validation/commit-msg-hook.sh ]; then
  bash .speck/scripts/validation/commit-msg-hook.sh "$1" || exit $?
fi
${loaderEnd}`;

  try {
    // Same shadow, same rescue — commit-msg hooks are generated by pre-commit.com with the
    // identical `exec … hook-impl` tail, so the defect and the fix are one and the same.
    const existing = existsSync(commitMsgPath) ? readFileSync(commitMsgPath, 'utf-8') : '';
    const { content, shadow, isNew, hadBlock } = applyHookLoader(existing, loaderStart, loaderEnd, loaderContent);
    writeFileSync(commitMsgPath, content, { mode: 0o755 });

    if (shadow) warnHookShadow(targetDir, 'commit-msg', shadow);
    if (verbose) {
      console.log(hadBlock
        ? '  ✅ Updated Speck commit-msg Git hook loader'
        : `  ✅ Installed Speck commit-msg Git hook loader${isNew ? '' : ' into the existing hook'}`);
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

  // 5. Symlink Cursor SKILLS into .claude, .codex, and .agents for cross-tool parity.
  //    Codex discovers skills under `.agents/skills` (canonical). Agents are NOT
  //    symlinked — each harness has a different model vocabulary, so agents are generated
  //    per-harness (generate-agents.js) and copied as real dirs via ALWAYS_OVERWRITE above.
  for (const runtimeDir of ['.claude', '.codex', '.agents']) {
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
