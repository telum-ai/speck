/**
 * Core sync logic for Speck files with smart merging
 */

import { existsSync, readFileSync, writeFileSync, mkdirSync, readdirSync, statSync, rmSync, copyFileSync } from 'fs';
import { join, dirname, relative } from 'path';
import { execSync } from 'child_process';
import { tmpdir } from 'os';

/**
 * Files that should ALWAYS be overwritten (pure methodology)
 */
const ALWAYS_OVERWRITE = [
  '.speck/templates',
  '.speck/patterns',
  '.speck/recipes',
  '.speck/scripts',
  '.speck/README.md',
  '.cursor/commands',
  '.cursor/hooks/hooks',
  '.cursor/hooks/VALIDATION.md',
  '.cursor/MCP-SETUP.md',
  '.github/workflows/speck-orchestrator.yml',
  '.github/workflows/speck-validate-pr.yml',
  '.github/workflows/speck-retrospective.yml',
  '.github/workflows/speck-update-check.yml',
  '.github/workflows/speck-validation.yml',
  '.github/copilot-instructions.md',
  '.github/instructions',
  '.github/ISSUE_TEMPLATE/speck-story.yml',
];

/**
 * Files that need smart merging
 */
const SMART_MERGE_FILES = {
  'AGENTS.md': mergeAgentsMd,
  '.gitignore': mergeGitignore,
  '.cursor/hooks/hooks.json': mergeHooksJson,
  '.cursor/mcp.json': mergeMcpJson,
  '.cursor/mcp.json.example': copyMcpExample,
};

/**
 * Files that should be skipped if user has customized them
 */
const SKIP_IF_CUSTOMIZED = {
  'README.md': isReadmeCustomized,
  '.github/workflows/copilot-setup-steps.yml': isCopilotSetupCustomized,
};

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
// Skip-if-customized detection
// ============================================================

/**
 * Check if README.md has been customized from template
 */
function isReadmeCustomized(sourceContent, targetContent) {
  if (!targetContent) return false;
  
  // Compare first line - if different, user customized it
  const sourceFirstLine = sourceContent.split('\n')[0];
  const targetFirstLine = targetContent.split('\n')[0];
  
  return sourceFirstLine !== targetFirstLine;
}

/**
 * Check if copilot-setup-steps.yml has been customized
 */
function isCopilotSetupCustomized(sourceContent, targetContent) {
  if (!targetContent) return false;
  
  // If user has uncommented any setup steps, they've customized it
  const setupPatterns = [
    /^\s*uses:.*setup-node/m,
    /^\s*uses:.*setup-python/m,
    /^\s*uses:.*rust-toolchain/m,
    /^\s*uses:.*setup-go/m,
    /^\s*run:.*pip install/m,
    /^\s*run:.*npm ci/m,
  ];
  
  return setupPatterns.some(pattern => pattern.test(targetContent));
}

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
 * Get all files from a directory recursively
 */
export function getAllFiles(dir, baseDir = dir) {
  const files = [];
  
  if (!existsSync(dir)) return files;
  
  for (const entry of readdirSync(dir)) {
    const fullPath = join(dir, entry);
    const relativePath = relative(baseDir, fullPath);
    
    if (statSync(fullPath).isDirectory()) {
      files.push(...getAllFiles(fullPath, baseDir));
    } else {
      files.push(relativePath);
    }
  }
  
  return files;
}

/**
 * Check if a path matches any of the always-overwrite patterns
 */
function shouldOverwrite(filePath) {
  const normalized = filePath.replace(/\\/g, '/');
  
  for (const pattern of ALWAYS_OVERWRITE) {
    if (normalized === pattern || normalized.startsWith(pattern + '/')) {
      return true;
    }
  }
  
  return false;
}

/**
 * Recursively copy a directory
 */
function copyDir(src, dest) {
  mkdirSync(dest, { recursive: true });
  
  for (const entry of readdirSync(src)) {
    const srcPath = join(src, entry);
    const destPath = join(dest, entry);
    
    if (statSync(srcPath).isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      copyFileSync(srcPath, destPath);
    }
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
    errors: [],
  };
  
  const verbose = options.verbose || false;
  
  // 1. Handle ALWAYS_OVERWRITE patterns
  for (const pattern of ALWAYS_OVERWRITE) {
    const sourcePath = join(sourceDir, pattern);
    const targetPath = join(targetDir, pattern);
    
    if (!existsSync(sourcePath)) continue;
    
    try {
      const isDir = statSync(sourcePath).isDirectory();
      
      if (isDir) {
        // Remove existing and copy entire directory
        if (existsSync(targetPath)) {
          rmSync(targetPath, { recursive: true, force: true });
        }
        copyDir(sourcePath, targetPath);
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
      
      // Not customized or doesn't exist - copy it
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
  
  return results;
}

/**
 * Check if Speck is initialized in a directory
 */
export function isSpeckInitialized(targetDir) {
  const markers = [
    join(targetDir, '.speck', 'VERSION'),
    join(targetDir, '.speck', 'README.md'),
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

// Legacy exports for backwards compatibility
export function loadIgnorePatterns() { return []; }
export function shouldIgnore() { return false; }
export function planSync() { return { create: [], update: [], skip: [], unchanged: [] }; }
export function executeSync() { return { created: [], updated: [], errors: [] }; }
