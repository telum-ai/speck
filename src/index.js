/**
 * Greeting API - Entry Point
 * Simple greeting function for E2E test validation
 */

function greet(name = 'World') {
  return `Hello, ${name}!`;
}

module.exports = { greet };
