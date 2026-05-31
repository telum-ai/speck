#!/usr/bin/env node

/**
 * check-artifact-template-drift.js
 * Diffs an instantiated artifact's headers against the required set in template-manifest.json.
 * Detects structural drift in projects upgraded mid-flight.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Resolve paths
const manifestPath = path.join(__dirname, '../../templates/template-manifest.json');

function normalizeHeader(header) {
  return header
    .toLowerCase()
    .replace(/^#+\s*/, '') // strip leading hashes
    .replace(/^\d+[\.\s]*/, '') // strip leading numbers (e.g., "1. ", "1 ")
    .replace(/[^a-z0-9]/g, '') // keep only alphanumeric
    .trim();
}

function detectArtifactType(filePath, content) {
  // 1. Try frontmatter
  const fmMatch = content.match(/^---([\s\S]*?)---/);
  if (fmMatch) {
    const fm = fmMatch[1];
    const typeMatch = fm.match(/artifact_type:\s*([a-zA-Z0-9_-]+)/);
    if (typeMatch) {
      return typeMatch[1].trim();
    }
  }

  // 2. Try filename / path heuristics
  const filename = path.basename(filePath);
  if (filename === 'product-contract.md') return 'product-contract';
  if (filename === 'evidence-contract.md') return 'evidence-contract';
  if (filename === 'spec.md') return 'story-spec';
  if (filename === 'validation-report.md') return 'validation-report';
  if (filename === 'epic-validation-report.md') return 'epic-validation-report';
  if (filePath.includes('/personas/') && filename.endsWith('.md')) return 'persona-larp';

  return null;
}

function main() {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    console.error('Usage: node check-artifact-template-drift.js <file_path>');
    process.exit(1);
  }

  const filePath = args[0];
  if (!fs.existsSync(filePath)) {
    // File doesn't exist, no drift to check
    process.exit(0);
  }

  const content = fs.readFileSync(filePath, 'utf-8');
  const artifactType = detectArtifactType(filePath, content);

  if (!artifactType) {
    // Unknown artifact type, skip
    process.exit(0);
  }

  if (!fs.existsSync(manifestPath)) {
    console.error(`Error: template-manifest.json not found at ${manifestPath}`);
    process.exit(1);
  }

  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf-8'));
  const targetSpec = manifest[artifactType];

  if (!targetSpec) {
    // No required headers defined for this type
    process.exit(0);
  }

  // Extract all headers from content
  const lines = content.split('\n');
  const docHeaders = lines
    .filter(line => line.trim().startsWith('#'))
    .map(line => line.trim());

  const normalizedDocHeaders = docHeaders.map(normalizeHeader);
  const missingHeaders = [];

  for (const reqHeader of targetSpec.required_headers) {
    const normReq = normalizeHeader(reqHeader);
    if (!normalizedDocHeaders.includes(normReq)) {
      missingHeaders.push(reqHeader);
    }
  }

  if (missingHeaders.length > 0) {
    console.log(`TEMPLATE_DRIFT: ${artifactType}`);
    console.log(`FILE: ${filePath}`);
    console.log(`STRUCTURE_VERSION: ${targetSpec.structure_version}`);
    console.log('MISSING_SECTIONS:');
    missingHeaders.forEach(h => console.log(`  - ${h}`));
    process.exit(0); // Exit 0 so we don't break general execution, caller parses output
  }

  process.exit(0);
}

main();
