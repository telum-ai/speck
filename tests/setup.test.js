// E2E Test - Setup Validation
import { describe, test, expect } from '@jest/globals';
import { existsSync } from 'fs';
import { join } from 'path';

describe('Project Setup', () => {
  test('package.json exists and is valid', () => {
    const packageJsonPath = join(process.cwd(), 'package.json');
    expect(existsSync(packageJsonPath)).toBe(true);
    
    const packageJson = require(packageJsonPath);
    expect(packageJson.name).toBeDefined();
    expect(packageJson.version).toBeDefined();
  });

  test('Express is installed as a dependency', () => {
    const packageJson = require(join(process.cwd(), 'package.json'));
    expect(packageJson.dependencies).toBeDefined();
    expect(packageJson.dependencies.express).toBeDefined();
  });

  test('src directory exists', () => {
    const srcPath = join(process.cwd(), 'src');
    expect(existsSync(srcPath)).toBe(true);
  });

  test('tests directory exists', () => {
    const testsPath = join(process.cwd(), 'tests');
    expect(existsSync(testsPath)).toBe(true);
  });

  test('src/index.js exists', () => {
    const indexPath = join(process.cwd(), 'src', 'index.js');
    expect(existsSync(indexPath)).toBe(true);
  });
});
