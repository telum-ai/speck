# speck-larp / backend-skip (2)

| **Execution** | Interactive skill command | Interactive skill command | Interactive skill command |
| **Tooling** | Native Browser MCP or Playwright | Playwright or manual capture | Playwright or manual capture |

### Fallbacks & Adaptations
- **Visual Testing / Browser MCP**: Spawning dynamic browser actions via Playwright/Browser MCP is highly streamlined in Claude/Cursor (using the browser tools or MCP integration). On Codex or other hosts, if automation tools are unavailable, execute the persona steps manually against the target build, take screenshots, save them to `<story-or-epic-dir>/larp-recordings/`, and write the findings note manually.
