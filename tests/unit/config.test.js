/**
 * Basic configuration test
 * Verifies the greeting function works correctly
 */

const { greet } = require('../../src/index');

describe('Greeting API', () => {
  test('greets with default name', () => {
    expect(greet()).toBe('Hello, World!');
  });

  test('greets with custom name', () => {
    expect(greet('Speck')).toBe('Hello, Speck!');
  });
});
