import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

function findMarkdownFiles(dir, files = []) {
  if (!fs.existsSync(dir)) return files;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      findMarkdownFiles(fullPath, files);
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      files.push(fullPath);
    }
  }
  return files;
}

export async function validateCommand(targetDir, options = {}) {
  console.log('🥓 Running Speck validation...\n');

  const specsDir = path.join(targetDir, 'specs/projects');
  if (!fs.existsSync(specsDir)) {
    console.log('ℹ️  No specs/projects directory found. Nothing to validate.');
    return;
  }

  const files = findMarkdownFiles(specsDir);
  const validateScript = path.join(targetDir, '.speck/scripts/validation/validate-template.sh');
  if (!fs.existsSync(validateScript)) {
    console.error(`Error: Validation script not found at ${validateScript}`);
    process.exit(1);
  }

  let exclusions = [];
  const exclusionsPath = path.join(targetDir, '.speck/legacy-exclusions.json');
  if (fs.existsSync(exclusionsPath)) {
    try {
      exclusions = JSON.parse(fs.readFileSync(exclusionsPath, 'utf-8'));
    } catch (err) {
      console.error(`Warning: Failed to parse .speck/legacy-exclusions.json: ${err.message}`);
    }
  }

  let passed = 0;
  let failed = 0;
  let skipped = 0;

  for (const file of files) {
    const relativePath = path.relative(targetDir, file);

    // Check if excluded in legacy-exclusions.json
    if (options.activeOnly && exclusions.includes(relativePath)) {
      skipped++;
      continue;
    }

    // Check frontmatter status
    if (options.activeOnly) {
      try {
        const content = fs.readFileSync(file, 'utf-8');
        const fmMatch = content.match(/^---([\s\S]*?)---/);
        if (fmMatch) {
          const fm = fmMatch[1];
          if (fm.includes('status: historical') || fm.includes('status: Done') || fm.includes('status: completed')) {
            skipped++;
            continue;
          }
        }
      } catch (err) {
        // Ignore read errors
      }
    }

    console.log(`🔍 Validating: ${relativePath}...`);
    try {
      execSync(`bash "${validateScript}" --strict "${file}"`, { stdio: 'inherit' });
      passed++;
    } catch (err) {
      failed++;
      console.log(`❌ Failed: ${relativePath}\n`);
    }
  }

  console.log('\n=========================================');
  console.log(`Summary: ${passed} passed / ${failed} failed / ${skipped} skipped`);
  console.log('=========================================');

  if (failed > 0) {
    process.exit(1);
  } else {
    console.log('\n✅ All active Speck artifacts are valid!');
    process.exit(0);
  }
}
