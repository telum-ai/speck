/**
 * Core sync logic for Speck files
 */

import { existsSync, readFileSync, writeFileSync, mkdirSync, readdirSync, statSync } from 'fs';
import { join, dirname, relative } from 'path';
import { execSync } from 'child_process';
import { tmpdir } from 'os';

/**
 * Default patterns to always ignore (never sync from template)
 */
const DEFAULT_IGNORE = [
  'specs/**',           // User's specifications
  'src/**',             // User's source code
  'README.md',          // User's README
  '.git/**',            // Git directory
  '.gitignore',         // User's gitignore
  'node_modules/**',    // Dependencies
  'package.json',       // User's package.json
  'package-lock.json',  // User's lockfile
  '.env*',              // Environment files
  'copilot-setup-steps.yml', // Project-specific setup
];

/**
 * Patterns that are methodology files (always sync from template)
 */
const METHODOLOGY_PATTERNS = [
  '.speck/**',
  '.cursor/commands/**',
  '.cursor/hooks/**',
  '.github/workflows/speck-*.yml',
  '.github/copilot-instructions.md',
  '.github/instructions/**',
  '.github/ISSUE_TEMPLATE/speck-*.yml',
  'AGENTS.md',
];

/**
 * Load .speckignore patterns from target directory
 */
export function loadIgnorePatterns(targetDir) {
  const ignoreFile = join(targetDir, '.speckignore');
  const patterns = [...DEFAULT_IGNORE];
  
  if (existsSync(ignoreFile)) {
    const content = readFileSync(ignoreFile, 'utf-8');
    const lines = content.split('\n')
      .map(l => l.trim())
      .filter(l => l && !l.startsWith('#'));
    patterns.push(...lines);
  }
  
  return patterns;
}

/**
 * Check if a path matches any ignore pattern
 */
export function shouldIgnore(filePath, ignorePatterns) {
  const normalizedPath = filePath.replace(/\\/g, '/');
  
  for (const pattern of ignorePatterns) {
    // Simple glob matching
    const regex = new RegExp(
      '^' + pattern
        .replace(/\*\*/g, '.*')
        .replace(/\*/g, '[^/]*')
        .replace(/\?/g, '.') + '$'
    );
    
    if (regex.test(normalizedPath)) {
      return true;
    }
  }
  
  return false;
}

/**
 * Download and extract a release to a temp directory
 */
export async function extractRelease(tag) {
  const tempDir = join(tmpdir(), `speck-${tag}-${Date.now()}`);
  mkdirSync(tempDir, { recursive: true });
  
  const tarballUrl = `https://github.com/telum-ai/speck/archive/refs/tags/${tag}.tar.gz`;
  
  // Download and extract using curl and tar
  execSync(
    `curl -sL "${tarballUrl}" | tar -xz -C "${tempDir}" --strip-components=1`,
    { stdio: 'pipe' }
  );
  
  return tempDir;
}

/**
 * Get all files from a directory recursively
 */
export function getAllFiles(dir, baseDir = dir) {
  const files = [];
  
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
 * Compare files and determine what needs to be synced
 */
export function planSync(sourceDir, targetDir, ignorePatterns) {
  const sourceFiles = getAllFiles(sourceDir);
  const plan = {
    create: [],   // Files to create
    update: [],   // Files to update
    skip: [],     // Files skipped due to ignore patterns
    unchanged: [], // Files that are identical
  };
  
  for (const file of sourceFiles) {
    // Skip ignored patterns
    if (shouldIgnore(file, ignorePatterns)) {
      plan.skip.push(file);
      continue;
    }
    
    const sourcePath = join(sourceDir, file);
    const targetPath = join(targetDir, file);
    
    if (!existsSync(targetPath)) {
      plan.create.push(file);
    } else {
      const sourceContent = readFileSync(sourcePath, 'utf-8');
      const targetContent = readFileSync(targetPath, 'utf-8');
      
      if (sourceContent !== targetContent) {
        plan.update.push(file);
      } else {
        plan.unchanged.push(file);
      }
    }
  }
  
  return plan;
}

/**
 * Execute the sync plan
 */
export function executeSync(sourceDir, targetDir, plan) {
  const results = {
    created: [],
    updated: [],
    errors: [],
  };
  
  for (const file of [...plan.create, ...plan.update]) {
    try {
      const sourcePath = join(sourceDir, file);
      const targetPath = join(targetDir, file);
      
      // Ensure directory exists
      mkdirSync(dirname(targetPath), { recursive: true });
      
      // Copy file
      const content = readFileSync(sourcePath);
      writeFileSync(targetPath, content);
      
      if (plan.create.includes(file)) {
        results.created.push(file);
      } else {
        results.updated.push(file);
      }
    } catch (error) {
      results.errors.push({ file, error: error.message });
    }
  }
  
  return results;
}

/**
 * Get the current Speck version in a directory
 */
export function getCurrentVersion(targetDir) {
  // Try to find version from AGENTS.md
  const agentsPath = join(targetDir, 'AGENTS.md');
  if (existsSync(agentsPath)) {
    const content = readFileSync(agentsPath, 'utf-8');
    const match = content.match(/\*\*Speck Version\*\*:\s*(\d+\.\d+)/);
    if (match) {
      return `v${match[1]}.0`;
    }
  }
  
  // Try to find version from .speck/VERSION
  const versionPath = join(targetDir, '.speck', 'VERSION');
  if (existsSync(versionPath)) {
    return readFileSync(versionPath, 'utf-8').trim();
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
