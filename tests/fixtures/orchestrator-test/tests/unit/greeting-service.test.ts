/**
 * Unit tests for Greeting Service
 * 
 * Tests all functional requirements and acceptance criteria from spec.md
 */

import { greet } from '../../src/services/greeting-service';

describe('greet', () => {
  // FR-002: Return greeting in format "Hello, {name}!"
  // Scenario: Greet with valid name
  it('greets with valid name', () => {
    expect(greet('Alice')).toBe('Hello, Alice!');
  });

  // FR-003: Handle empty names
  // Scenario: Greet with empty name
  it('greets with empty name', () => {
    expect(greet('')).toBe('Hello, stranger!');
  });

  // FR-003: Handle empty names (whitespace-only)
  // Scenario: Greet with whitespace-only name
  it('greets with whitespace-only name', () => {
    expect(greet('   ')).toBe('Hello, stranger!');
  });

  // FR-003: Handle empty names (undefined)
  it('greets with undefined', () => {
    expect(greet(undefined)).toBe('Hello, stranger!');
  });

  // FR-001: Accept optional name parameter
  // FR-003: Handle empty names (no arguments)
  it('greets with no arguments', () => {
    expect(greet()).toBe('Hello, stranger!');
  });

  // Additional edge cases from spec.md
  it('greets with name containing special characters', () => {
    expect(greet('Alice-Bob')).toBe('Hello, Alice-Bob!');
  });

  it('greets with name containing numbers', () => {
    expect(greet('Alice123')).toBe('Hello, Alice123!');
  });

  // NFR-001: Service response time SHALL be < 5ms
  it('executes within performance target', () => {
    const start = performance.now();
    greet('Performance Test');
    const duration = performance.now() - start;
    
    expect(duration).toBeLessThan(5);
  });

  // NFR-002: Service SHALL be stateless (verify no side effects)
  it('is stateless and produces consistent results', () => {
    const result1 = greet('Test');
    const result2 = greet('Test');
    
    expect(result1).toBe(result2);
    expect(result1).toBe('Hello, Test!');
  });
});
