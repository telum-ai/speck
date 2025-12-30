/**
 * Greeting Service
 * 
 * A simple, stateless service for generating personalized greeting messages.
 * Implements FR-001, FR-002, FR-003, and NFR-002 from spec.md.
 */

/**
 * Generates a personalized greeting message.
 * 
 * @param name - Optional name to use in the greeting
 * @returns Formatted greeting message
 * 
 * @example
 * greet("Alice") // Returns: "Hello, Alice!"
 * greet("") // Returns: "Hello, stranger!"
 * greet("   ") // Returns: "Hello, stranger!"
 * greet() // Returns: "Hello, stranger!"
 */
export function greet(name?: string): string {
  // FR-001: Accept name parameter (optional)
  // FR-003: Handle empty names (trim and check)
  const trimmedName = name?.trim() || '';
  
  // FR-002: Return greeting in format "Hello, {name}!"
  // FR-003: Return "Hello, stranger!" for empty names
  return trimmedName ? `Hello, ${trimmedName}!` : 'Hello, stranger!';
}
