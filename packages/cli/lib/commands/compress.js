/**
 * speck compress / decompress — zero-dependency context compaction for completed epics
 */

import { existsSync, readdirSync, readFileSync, writeFileSync, mkdirSync, rmSync, statSync } from 'fs';
import { join, basename, dirname } from 'path';
import { execSync } from 'child_process';
import readline from 'readline';

function askQuestion(query) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => rl.question(query, (ans) => {
    rl.close();
    resolve(ans);
  }));
}

function getProjects(cwd) {
  const specsDir = join(cwd, 'specs', 'projects');
  if (!existsSync(specsDir)) return [];
  try {
    return readdirSync(specsDir).filter(d => {
      return existsSync(join(specsDir, d, 'project.md'));
    });
  } catch {
    return [];
  }
}

export async function compressCommand(cwd, epicId, options = {}) {
  console.log('🥓 Running Speck Context Compaction (Compress)...');

  const projects = getProjects(cwd);
  if (projects.length === 0) {
    console.log('❌ No Speck projects found.');
    return;
  }

  let projectID = projects[0];
  if (projects.length > 1) {
    console.log('Multiple projects detected:');
    projects.forEach((p, idx) => console.log(`  [${idx + 1}] ${p}`));
    const choice = await askQuestion('\nWhich project? [1]: ');
    const num = parseInt(choice || '1', 10);
    if (num > 0 && num <= projects.length) {
      projectID = projects[num - 1];
    }
  }

  const projectDir = join(cwd, 'specs', 'projects', projectID);
  const epicsDir = join(projectDir, 'epics');

  if (!existsSync(epicsDir)) {
    console.log('❌ No epics directory found in project.');
    return;
  }

  const epics = readdirSync(epicsDir).filter(f => {
    try {
      return statSync(join(epicsDir, f)).isDirectory() && (f.startsWith('E') || f.match(/^[0-9]{3}-/));
    } catch {
      return existsSync(join(epicsDir, f, 'epic.md'));
    }
  });

  if (epics.length === 0) {
    console.log('❌ No epic directories found.');
    return;
  }

  let selectedEpic = epicId;
  if (selectedEpic && !existsSync(join(epicsDir, selectedEpic))) {
    console.log(`⚠️  Epic "${epicId}" not found.`);
    selectedEpic = null;
  }

  if (!selectedEpic) {
    console.log('Available epics:');
    epics.forEach((e, idx) => console.log(`  [${idx + 1}] ${e}`));
    const choice = await askQuestion('\nWhich epic do you want to compact? [1]: ');
    const num = parseInt(choice || '1', 10);
    if (num > 0 && num <= epics.length) {
      selectedEpic = epics[num - 1];
    } else {
      selectedEpic = epics[0];
    }
  }

  const targetEpicDir = join(epicsDir, selectedEpic);
  const storiesDir = join(targetEpicDir, 'stories');

  if (!existsSync(storiesDir)) {
    console.log(`❌ No stories found inside epic directory: epics/${selectedEpic}/stories/`);
    return;
  }

  // 1. Verify validation status of the epic
  const validationReportPath = join(targetEpicDir, 'epic-validation-report.md');
  let isValidated = existsSync(validationReportPath);

  if (!isValidated && !options.force) {
    console.log(`\n❌ Error: Epic ${selectedEpic} is not fully validated!`);
    console.log('   Compacting unvalidated epics carries a risk of losing outstanding tasks.');
    console.log('   Please validate this epic using "/epic-validate" or pass --force to bypass this gate.');
    return;
  }

  // 2. Scan active story folders
  const storyFolders = readdirSync(storiesDir).filter(f => {
    try {
      const p = join(storiesDir, f);
      return statSync(p).isDirectory() && f.startsWith('S');
    } catch {
      return false;
    }
  });

  if (storyFolders.length === 0) {
    console.log('✅ Workspace already compacted. No individual active story directories found.');
    return;
  }

  console.log(`\n📦 Compacting ${storyFolders.length} story directory/directories inside epics/${selectedEpic}/...`);

  // 3. Extract story metadata to compile validated-summary.md
  const storyMetadata = [];
  for (const s of storyFolders) {
    const sDir = join(storiesDir, s);
    const specPath = join(sDir, 'spec.md');
    const valReportPath = join(sDir, 'validation-report.md');

    let name = s;
    let state = 'IMPL-GREEN';
    let date = new Date().toISOString().split('T')[0];
    let accomplishments = 'N/A';

    if (existsSync(specPath)) {
      const specContent = readFileSync(specPath, 'utf-8');
      const nameMatch = specContent.match(/# Story Specification:\s*([^\r\n]+)/i) || specContent.match(/#\s*([^\r\n]+)/);
      if (nameMatch) {
        name = nameMatch[1].trim();
      }
      
      const frMatches = [...specContent.matchAll(/(FR-[0-9]+)/g)];
      if (frMatches.length > 0) {
        accomplishments = [...new Set(frMatches.map(m => m[1]))].join(', ');
      }
    }

    if (existsSync(valReportPath)) {
      const valContent = readFileSync(valReportPath, 'utf-8');
      const stateMatch = valContent.match(/readiness_state_verified:\s*([^\r\n]+)/i) || valContent.match(/readiness_state_claimed:\s*([^\r\n]+)/i);
      if (stateMatch) {
        state = stateMatch[1].trim().replace(/['"]/g, '');
      }
      const dateMatch = valContent.match(/verified\s*([0-9]{4}-[0-9]{2}-[0-9]{2})/i);
      if (dateMatch) {
        date = dateMatch[1];
      }
    }

    storyMetadata.push({ id: s, name, state, date, accomplishments });
  }

  // 4. Generate/Append consolidated validated-summary.md
  const summaryPath = join(storiesDir, 'validated-summary.md');
  let summaryContent = `# Validated Stories Summary: ${selectedEpic}\n\n`;
  summaryContent += `This file is the consolidated reference for all validated stories in epic \`${selectedEpic}\`.\n`;
  summaryContent += `The individual story directories have been archived under \`.speck/archive/${projectID}-${selectedEpic}-stories.tar.gz\` to eliminate workspace context rot.\n\n`;
  summaryContent += `To restore individual story folders for editing, run:\n`;
  summaryContent += `\`npx speck decompress --epic ${selectedEpic}\`\n\n`;
  summaryContent += `## Validated Stories Index\n\n`;
  summaryContent += `| Story ID | Name | Verified State | Completion Date | Key Accomplishments / FRs |\n`;
  summaryContent += `|----------|------|----------------|-----------------|---------------------------|\n`;

  for (const m of storyMetadata) {
    summaryContent += `| ${m.id} | ${m.name} | \`${m.state}\` | ${m.date} | ${m.accomplishments} |\n`;
  }

  writeFileSync(summaryPath, summaryContent);
  console.log(`📝 Generated validated-summary.md reference in epics/${selectedEpic}/stories/`);

  // 5. Pack original folders using standard system tar
  const archiveDir = join(cwd, '.speck', 'archive');
  if (!existsSync(archiveDir)) {
    mkdirSync(archiveDir, { recursive: true });
  }

  const archiveFile = join(archiveDir, `${projectID}-${selectedEpic}-stories.tar.gz`);
  const foldersList = storyFolders.join(' ');

  console.log('🎒 Bundling story directories into tar.gz archive...');
  try {
    // Navigate to target directory and compress matching story folders (tar works identically on Win10/Mac/Linux)
    execSync(`tar -czf "${archiveFile}" -C "${storiesDir}" ${foldersList}`, { stdio: 'ignore' });
  } catch (err) {
    console.log(`❌ tar compression failed: ${err.message}`);
    console.log('   Compaction aborted. Story directories remain untouched.');
    return;
  }

  if (existsSync(archiveFile)) {
    console.log(`✅ Compressed archive successfully written: .speck/archive/${basename(archiveFile)}`);

    // 6. Delete individual story folders safely
    for (const folder of storyFolders) {
      rmSync(join(storiesDir, folder), { recursive: true, force: true });
    }
    console.log('🧹 Cleaned up individual story subdirectories. Context compaction complete!');
  } else {
    console.log('❌ Error: Archive file was not written. Aborting cleanup.');
  }
}

export async function decompressCommand(cwd, epicId, options = {}) {
  console.log('🥓 Running Speck Context Restoration (Decompress)...');

  const projects = getProjects(cwd);
  if (projects.length === 0) {
    console.log('❌ No Speck projects found.');
    return;
  }

  let projectID = projects[0];
  if (projects.length > 1) {
    console.log('Multiple projects detected:');
    projects.forEach((p, idx) => console.log(`  [${idx + 1}] ${p}`));
    const choice = await askQuestion('\nWhich project? [1]: ');
    const num = parseInt(choice || '1', 10);
    if (num > 0 && num <= projects.length) {
      projectID = projects[num - 1];
    }
  }

  const projectDir = join(cwd, 'specs', 'projects', projectID);
  const epicsDir = join(projectDir, 'epics');

  if (!existsSync(epicsDir)) {
    console.log('❌ No epics directory found.');
    return;
  }

  const archiveDir = join(cwd, '.speck', 'archive');
  if (!existsSync(archiveDir)) {
    console.log('❌ No archived context files found (.speck/archive/ is missing).');
    return;
  }

  const archives = readdirSync(archiveDir).filter(f => f.endsWith('-stories.tar.gz'));
  if (archives.length === 0) {
    console.log('❌ No archived story tarballs found.');
    return;
  }

  let selectedEpic = epicId;
  let targetArchive = selectedEpic ? `${projectID}-${selectedEpic}-stories.tar.gz` : null;

  if (selectedEpic && !existsSync(join(archiveDir, targetArchive))) {
    console.log(`⚠️  Archive for epic "${epicId}" not found.`);
    targetArchive = null;
    selectedEpic = null;
  }

  if (!targetArchive) {
    console.log('Available compacted epics:');
    archives.forEach((a, idx) => {
      // Extract epic name from tag
      const name = a.replace(`${projectID}-`, '').replace('-stories.tar.gz', '');
      console.log(`  [${idx + 1}] ${name}`);
    });
    const choice = await askQuestion('\nWhich epic do you want to restore? [1]: ');
    const num = parseInt(choice || '1', 10);
    if (num > 0 && num <= archives.length) {
      targetArchive = archives[num - 1];
      selectedEpic = targetArchive.replace(`${projectID}-`, '').replace('-stories.tar.gz', '');
    } else {
      targetArchive = archives[0];
      selectedEpic = targetArchive.replace(`${projectID}-`, '').replace('-stories.tar.gz', '');
    }
  }

  const targetEpicDir = join(epicsDir, selectedEpic);
  const storiesDir = join(targetEpicDir, 'stories');
  const archivePath = join(archiveDir, targetArchive);

  if (!existsSync(storiesDir)) {
    mkdirSync(storiesDir, { recursive: true });
  }

  console.log(`\n📦 Extracting stories for epic ${selectedEpic}...`);
  try {
    execSync(`tar -xzf "${archivePath}" -C "${storiesDir}"`, { stdio: 'ignore' });
    console.log('✅ Context restored successfully! All story directories are active again.');
    
    // Remove archive file to keep state clean (it can be re-compressed on demand)
    rmSync(archivePath, { force: true });
    console.log('🧹 Cleaned up archive file from .speck/archive/');
  } catch (err) {
    console.log(`❌ Failed to extract archive: ${err.message}`);
  }
}
