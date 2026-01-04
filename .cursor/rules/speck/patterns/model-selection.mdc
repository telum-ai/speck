---
name: model-selection
description: Load at the start of any task to assess whether the current model is optimal. Prompt the user to switch models when task characteristics indicate a better choice exists.
---

# Model Selection

At the start of each significant task, assess whether the current model is optimal for the work ahead. If a different model would be substantially better, prompt the user to switch.

## When to Prompt for Model Switch

Evaluate these conditions and prompt the user if a switch is warranted:

### Upgrade to Opus 4.5 When:
- Task involves complex architecture design or multi-system reasoning
- Critical code review where accuracy is paramount
- Deep domain understanding required (e.g., `/project-domain`, `/project-constitution`)
- User is struggling with a complex problem that needs deeper reasoning

**Prompt template**:
```
💡 **Model Recommendation**: This task involves [complex architecture/deep reasoning/critical review]. 
Consider switching to **Opus 4.5** for higher accuracy. You can switch back to Sonnet after this step.
```

### Upgrade to GPT-5.2 Extra High When:
- Writing security-sensitive code (lowest vulnerability rate)
- Mathematical or algorithmic problems requiring precise reasoning
- Long-document analysis

### Switch to Gemini 3 Flash / Grok Code When:
- User needs fast responses for interactive work
- Simple fixes or quick iterations
- Budget is a concern
- "Vibe coding" or UI polish work

**Prompt template**:
```
💡 **Model Recommendation**: For this interactive/quick-fix work, **Gemini 3 Flash** would provide 
faster responses while maintaining sufficient quality.
```

### Use Composer 1 (in Cursor) When:
- Story implementation (`/story-implement`)
- Multi-file editing and refactoring
- Rapid prototyping
- User is in Cursor IDE and speed matters

### Cross-Validation Recommended When:
- Architecture decisions are being finalized
- Security-sensitive code has been written
- Production deployment is imminent

**Prompt template**:
```
💡 **Cross-Validation Recommended**: This [architecture/critical code] was authored with [current model]. 
For additional confidence, consider having a different model review it before proceeding.
```

## Quick Reference Table

| Task Type | Recommended Model | Why |
|-----------|------------------|-----|
| Complex architecture | Opus 4.5 | Deep reasoning |
| Critical code review | Opus 4.5 | Highest accuracy |
| Security-sensitive code | GPT-5.2 Extra High | Lowest vulns |
| Standard implementation | Sonnet 4.5 | Best balance |
| Story implementation (Cursor) | Composer 1 | 4x faster |
| Interactive/quick fixes | Gemini 3 Flash | Speed |
| Budget-constrained | Gemini 3 Flash | Cheapest quality |
| Mathematical problems | GPT-5.2 Extra High | 100% AIME 2025 |
| Validation | Different model | Fresh perspective |

## Speck Command Recommendations

### Project Level
| Command | Model | Reason |
|---------|-------|--------|
| `/project-domain` | Opus 4.5 | Deep domain understanding |
| `/project-architecture` | Opus 4.5 | Complex system design |
| `/project-constitution` | Opus 4.5 | Principle extraction |
| `/project-validate` | Different model | Cross-validation |
| Other project commands | Sonnet 4.5 | Good balance |

### Story Level
| Command | Model | Reason |
|---------|-------|--------|
| `/story-implement` | Composer 1 | Speed + Cursor integration |
| `/story-tasks` | Composer 1 / Gemini 3 Flash | Fast structured output |
| `/story-plan` | Sonnet 4.5 | Reasoning needed |
| `/story-validate` | Different from implementer | Cross-validation |

## When NOT to Prompt

Don't prompt for model switch if:
- User just switched models (avoid flip-flopping)
- Task is simple and current model is adequate
- User has explicitly stated model preference
- Switching would interrupt flow for minimal gain

## MAX Mode Guidance

If you detect a task that would benefit from MAX mode (project-wide refactoring, large codebase navigation, >25 tool calls needed), inform the user:

```
💡 **MAX Mode**: This task spans multiple modules and may need >25 tool calls. 
Consider enabling MAX mode, but be aware it uses token-based pricing ($5-60+ per complex request).
```

Avoid MAX mode for single-file edits, small features, or bug fixes.

## Cost Awareness

When budget is mentioned or implied:
- Default to Gemini 3 Flash for routine work
- Reserve Opus 4.5 for critical decisions only
- Note that Opus 4.5's higher per-token cost often results in lower total cost due to 76% better token efficiency
