/**
 * Greeting Service Contract
 * 
 * This contract defines the interface for the greeting service.
 * The service is a pure function with no side effects.
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
export function greet(name?: string): string;

/**
 * Type definitions for the greeting service
 */

/**
 * Input type for the greeting service
 */
export interface GreetingInput {
  name?: string;
}

/**
 * Output type for the greeting service
 */
export interface GreetingOutput {
  message: string;
}

/**
 * Contract Requirements
 * 
 * FR-001: Service SHALL accept a name parameter
 *   - Function accepts optional string parameter
 *   - Handles undefined, null, empty, and whitespace inputs
 * 
 * FR-002: Service SHALL return greeting in format "Hello, {name}!"
 *   - Returns string with format "Hello, {name}!"
 *   - Name is trimmed before insertion
 * 
 * FR-003: Service SHALL handle empty names by returning "Hello, stranger!"
 *   - Empty string returns "Hello, stranger!"
 *   - Whitespace-only returns "Hello, stranger!"
 *   - Undefined/null returns "Hello, stranger!"
 * 
 * NFR-001: Service response time SHALL be < 5ms
 *   - Single string operation
 *   - No I/O or external calls
 *   - Expected execution time < 1ms
 * 
 * NFR-002: Service SHALL be stateless
 *   - Pure function with no side effects
 *   - Same input always produces same output
 *   - No global state modifications
 */
