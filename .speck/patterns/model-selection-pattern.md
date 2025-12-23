# Model Selection Pattern

**Purpose**: Guide agents and users to select the optimal LLM for each task based on cost, quality, speed, and task characteristics.

**Last Updated**: December 2025

---

## 🎯 Quick Reference: Which Model When?

| Task Type | Recommended Model | Why |
|-----------|------------------|-----|
| **Complex architecture design** | Opus 4.5 | Deep reasoning, multi-system understanding |
| **Production code review (critical)** | Opus 4.5 | Highest accuracy, catches subtle bugs |
| **Standard feature implementation** | Sonnet 4.5 | Best balance of quality/cost/speed |
| **Interactive pair programming** | Gemini 3 Flash / GPT-5.2 | Speed for flow state |
| **Quick fixes and small changes** | Gemini 3 Flash | Fast, cheap, reliable |
| **Large codebase analysis** | GPT-5.2 / Gemini 3 Flash | Long context handling |
| **Multi-file refactoring** | Sonnet 4.5 / Opus 4.5 | 0% edit error rate |
| **Long-horizon autonomous tasks** | Codex Max / Sonnet 4.5 | Context compaction, sustained coherence |
| **Mathematical/algorithmic problems** | GPT-5.2 Extra High | Superior reasoning |
| **Budget-constrained high volume** | Gemini 3 Flash | Best price/performance |
| **Cross-model validation** | Different model than author | Fresh perspective, catches blind spots |

---

## 📊 Model Profiles (December 2025)

### Tier 1: Frontier Reasoning (Complex Tasks)

#### Claude Opus 4.5
- **Strengths**: Highest SWE-bench (80.9%), exceptional multi-step reasoning, understands complex architectures, 76% more token-efficient than Sonnet
- **Weaknesses**: Slowest (49 tok/s), most expensive ($5/$25 per M tokens)
- **Best for**: Architecture decisions, complex debugging, mission-critical code review
- **Avoid for**: Quick iterations, high-volume tasks, budget-constrained work

#### GPT-5.2 Extra High (Reasoning)
- **Strengths**: 80% SWE-bench, 100% AIME 2025 with tools, exceptional long-context (77% at 256K), fast (187 tok/s)
- **Weaknesses**: Requires reasoning mode for best results, higher cost than standard
- **Best for**: Mathematical problems, long-document analysis, complex tool orchestration
- **Avoid for**: Simple tasks where reasoning overhead unnecessary

### Tier 2: Production Workhorses (Daily Development)

#### Claude Sonnet 4.5
- **Strengths**: 77-82% SWE-bench, **0% code edit error rate**, maintains coherence 30+ hours, reliable
- **Weaknesses**: Slightly slower than Flash models, moderate cost ($3/$15 per M tokens)
- **Best for**: Feature implementation, bug fixing, code review, most development work
- **Trade-off**: The "default choice" - excellent for 90% of tasks

#### GPT-5.2 (Medium Reasoning)
- **Strengths**: Fast (187 tok/s), good SWE-bench, excellent tool calling (98.7%), multimodal
- **Weaknesses**: Needs configuration for optimal results, context smaller than Gemini
- **Best for**: Speed-sensitive work, API integrations, visual debugging
- **Trade-off**: Faster than Sonnet but requires more parameter tuning

### Tier 3: Speed/Cost Optimized (High Volume)

#### Gemini 3 Flash
- **Strengths**: 78% SWE-bench (beats Pro!), fastest (218 tok/s), cheapest ($0.50/$3), most reliable of Gemini family
- **Weaknesses**: Less sophisticated reasoning on very complex tasks
- **Best for**: Interactive development, high-volume tasks, budget-conscious teams
- **Note**: Outperforms Gemini 3 Pro on coding while being faster and cheaper

#### Grok Code
- **Strengths**: Very fast (92 tok/s), extreme cost efficiency, good for defined problems
- **Weaknesses**: Struggles with complex architecture, less versatile
- **Best for**: Rapid prototyping, algorithmic problems, quick iterations
- **Avoid for**: Production code review, complex multi-file changes

### Tier 4: Specialized

#### GPT-5.1 Codex Max / Codex
- **Strengths**: Context compaction for long sessions, optimized for multi-week projects
- **Weaknesses**: Less versatile for quick queries
- **Best for**: Large refactoring, migrations, long autonomous coding sessions

#### Composer 1 (Cursor)
- **Strengths**: Native Cursor integration, 4x faster than similar models, parallel tool execution
- **Weaknesses**: Optimized for Cursor only
- **Best for**: Cursor users who want seamless integration

### ⚠️ Caution

#### Gemini 3 Pro
- **Known Issues**: Aggressive code deletion, context loss, memory leaks (137GB reported)
- **Recommendation**: Avoid for production code without constant human oversight
- **Use case**: Only for research/analysis where reliability issues are acceptable

---

## 🔄 Multi-Model Strategy

### The Principle
No single model dominates all dimensions. Use different models for different tasks:

```
Task Assessment
     ↓
┌────────────────────────────────────────────────┐
│  Is this a complex reasoning task?             │
│  - Architecture design                         │
│  - Complex debugging                           │
│  - Critical code review                        │
│  → Use Opus 4.5 or GPT-5.2 Extra High         │
└────────────────────────────────────────────────┘
     ↓ No
┌────────────────────────────────────────────────┐
│  Is speed critical for flow state?             │
│  - Interactive pair programming                │
│  - Rapid prototyping                           │
│  - Quick fixes                                 │
│  → Use Gemini 3 Flash or GPT-5.2              │
└────────────────────────────────────────────────┘
     ↓ No
┌────────────────────────────────────────────────┐
│  Is this standard development work?            │
│  - Feature implementation                      │
│  - Bug fixes                                   │
│  - Code modifications                          │
│  → Use Sonnet 4.5 (default)                   │
└────────────────────────────────────────────────┘
```

### Cross-Model Validation Pattern

For critical decisions, use a different model to validate:

1. **Author with Model A** → Generates solution
2. **Review with Model B** → Fresh perspective catches blind spots
3. **Synthesize** → Combine insights

**Example Pairings**:
- Sonnet 4.5 authors code → Opus 4.5 reviews
- GPT-5.2 designs architecture → Sonnet 4.5 implements
- Any model implements → Different model validates

---

## 📋 Model Selection by Speck Command

### Project Level

| Command | Recommended Model | Reasoning |
|---------|------------------|-----------|
| `/project-specify` | Sonnet 4.5 | Standard Q&A, good reasoning |
| `/project-domain` | Opus 4.5 | Deep domain understanding, terminology precision |
| `/project-ux` | Sonnet 4.5 | Creative + analytical balance |
| `/project-context` | Sonnet 4.5 | Standard documentation |
| `/project-constitution` | Opus 4.5 | Principle extraction requires deep reasoning |
| `/project-architecture` | **Opus 4.5** | Complex system design, critical decisions |
| `/project-plan` | Sonnet 4.5 | Structured output, good organization |
| `/project-validate` | **Different model than author** | Cross-validation catches blind spots |

### Epic Level

| Command | Recommended Model | Reasoning |
|---------|------------------|-----------|
| `/epic-specify` | Sonnet 4.5 | Standard specification work |
| `/epic-architecture` | Opus 4.5 / Sonnet 4.5 | Depends on epic complexity |
| `/epic-plan` | Sonnet 4.5 | Technical specification |
| `/epic-breakdown` | Sonnet 4.5 | Story organization |
| `/epic-validate` | **Different model than author** | Cross-validation |

### Story Level

| Command | Recommended Model | Reasoning |
|---------|------------------|-----------|
| `/story-specify` | Sonnet 4.5 / Gemini 3 Flash | Quick, reliable |
| `/story-plan` | Sonnet 4.5 | Technical design |
| `/story-tasks` | Gemini 3 Flash | Fast, structured output |
| `/story-implement` | **Varies by task** | See implementation guide below |
| `/story-validate` | **Different model than implementer** | Catch implementer's blind spots |

### Implementation Task Selection

```
Story Implementation
     ↓
┌─────────────────────────────────────────┐
│ Complex algorithm / data structure?     │
│ → GPT-5.2 Extra High (math reasoning)  │
└─────────────────────────────────────────┘
     ↓ No
┌─────────────────────────────────────────┐
│ Large multi-file refactoring?           │
│ → Sonnet 4.5 (0% edit error rate)      │
└─────────────────────────────────────────┘
     ↓ No
┌─────────────────────────────────────────┐
│ UI/frontend with rapid iteration?       │
│ → Gemini 3 Flash (speed for flow)      │
└─────────────────────────────────────────┘
     ↓ No
┌─────────────────────────────────────────┐
│ Standard feature implementation?        │
│ → Sonnet 4.5 (reliable default)        │
└─────────────────────────────────────────┘
```

---

## 💰 Cost Optimization Strategies

### Token Efficiency Matters More Than Per-Token Price

| Model | Input/Output (per M) | Token Efficiency |
|-------|---------------------|------------------|
| Gemini 3 Flash | $0.50 / $3 | Good |
| GPT-5.2 | $1.75 / $14 | Very Good |
| Sonnet 4.5 | $3 / $15 | Good |
| Opus 4.5 | $5 / $25 | **Best** (76% fewer tokens) |

**Paradox**: Opus 4.5's higher per-token cost often results in lower total cost due to superior efficiency.

### Budget Tiers

**Tight Budget**:
- Default: Gemini 3 Flash
- Complex: Sonnet 4.5
- Critical: Opus 4.5 (sparingly)

**Moderate Budget**:
- Default: Sonnet 4.5
- Complex: Opus 4.5
- Quick fixes: Gemini 3 Flash

**Performance Priority**:
- Default: Sonnet 4.5
- Complex: Opus 4.5
- Cross-validation: Always use different model

---

## 🔧 How Agents Should Use This Pattern

### Before Starting a Command

1. **Assess task complexity**: Simple → Complex scale
2. **Check speed requirements**: Is user waiting interactively?
3. **Consider budget context**: Is this a cost-sensitive project?
4. **Apply selection logic**: Use the decision trees above

### Suggesting Model Switches

When the current model may not be optimal, suggest:

```
💡 **Model Recommendation**: This task involves [complex architecture design / 
deep reasoning / critical code review]. Consider switching to Opus 4.5 for 
this step, then returning to Sonnet 4.5 for implementation.
```

Or for speed:

```
💡 **Model Recommendation**: For this interactive debugging session, 
Gemini 3 Flash or GPT-5.2 would provide faster responses while 
maintaining sufficient quality.
```

### Cross-Validation Prompts

After generating critical artifacts:

```
💡 **Cross-Validation Recommended**: This [architecture / critical code / 
security-sensitive change] was authored with [Model A]. For additional 
confidence, consider having [Model B] review it with fresh perspective.
```

---

## 📚 Sources

This pattern is based on December 2025 benchmarks and user reports:

- SWE-bench Verified scores
- Terminal-Bench 2.0 evaluations
- Token efficiency measurements
- Production reliability reports
- Speed benchmarks (tokens/second)
- Pricing data from official sources

**Update Frequency**: This pattern should be reviewed monthly as model capabilities evolve rapidly.

---

*Generated by Speck methodology*
*Pattern Version: 1.0.0*
