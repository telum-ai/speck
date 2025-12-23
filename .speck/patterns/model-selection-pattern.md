# Model Selection Pattern

**Purpose**: Guide agents and users to select the optimal LLM for each task based on cost, quality, speed, and task characteristics.

**Last Updated**: December 2025

---

## 🎯 Quick Reference: Which Model When?

| Task Type | Recommended Model | Why |
|-----------|------------------|-----|
| **Complex architecture design** | Opus 4.5 | Deep reasoning, multi-system understanding |
| **Production code review (critical)** | Opus 4.5 | Highest accuracy, catches subtle bugs |
| **Security-sensitive code** | GPT-5.2 Extra High | Lowest vulnerability rate (16/MLOC) |
| **Standard feature implementation** | Sonnet 4.5 | Best balance of quality/cost/speed |
| **Interactive pair programming** | Gemini 3 Flash / GPT-5.2 | Speed for flow state |
| **UI/Frontend work ("vibe coding")** | Gemini 3 Flash / Gemini 3 Pro | Excels at visual polish and interfaces |
| **Quick fixes and small changes** | Gemini 3 Flash / Grok Code | Fast, cheap, reliable |
| **Large codebase analysis** | GPT-5.2 / Gemini 3 Flash | Long context handling |
| **Multi-file refactoring** | Sonnet 4.5 / Opus 4.5 | 0% edit error rate |
| **Long-horizon autonomous tasks** | Codex Max / Sonnet 4.5 | Context compaction, sustained coherence |
| **Mathematical/algorithmic problems** | GPT-5.2 Extra High | 100% AIME 2025, superior reasoning |
| **Budget-constrained high volume** | Gemini 3 Flash / Grok Code | $0.20-$0.50/M input tokens |
| **Real-time agentic pipelines** | Grok Code / Composer 1 | 250-455 tok/s speed |
| **Speck story implementation** | **Composer 1** | 4x faster, native Cursor integration |
| **Multi-file editing in Cursor** | **Composer 1** | Parallel tool execution |
| **Zero-to-one project building** | **Composer 1** | Built for this use case |
| **Cross-model validation** | Different model than author | Fresh perspective, catches blind spots |
| **LLM-as-Judge evaluation** | Opus 4.5 / GPT-5.2 Extra High | Stronger judges catch more issues |

---

## 📊 Model Profiles (December 2025)

### Tier 1: Frontier Reasoning (Complex Tasks)

#### Claude Opus 4.5
- **Strengths**: Highest SWE-bench (80.9%), exceptional multi-step reasoning, understands complex architectures, 76% more token-efficient than Sonnet
- **Code Quality**: 83.62% pass rate, 55 control flow mistakes/MLOC, 44 blocker vulns/MLOC
- **Speed/Cost**: Slowest (49-70 tok/s), most expensive ($5/$25 per M tokens)
- **Best for**: Architecture decisions, complex debugging, mission-critical code review, SEO analysis, business analysis
- **Avoid for**: Quick iterations, high-volume tasks, budget-constrained work

#### GPT-5.2 Extra High (Reasoning)
- **Strengths**: 80% SWE-bench, 100% AIME 2025, exceptional long-context (77% at 256K), fast (187 tok/s)
- **Code Quality**: **Best security** - only 22 control flow mistakes/MLOC, **16 blocker vulns/MLOC** (lowest!)
- **Weaknesses**: Requires reasoning mode for best results, 38% on SimpleQA (factual accuracy)
- **Best for**: Mathematical problems, security-sensitive code, long-document analysis, complex tool orchestration
- **Avoid for**: Simple tasks where reasoning overhead unnecessary

### Tier 2: Production Workhorses (Daily Development)

#### Claude Sonnet 4.5
- **Strengths**: 77-82% SWE-bench, **0% code edit error rate**, maintains coherence 30+ hours, reliable
- **Code Quality**: ~80% pass rate, but 152 control flow mistakes/MLOC (higher than Opus)
- **Token Usage**: Uses 12-22% MORE tokens than Opus for similar tasks
- **Speed/Cost**: Moderate speed, $3/$15 per M tokens
- **Best for**: Feature implementation, bug fixing, code review, most development work
- **Trade-off**: The "default choice" - excellent for 90% of tasks

#### GPT-5.2 (Medium Reasoning)
- **Strengths**: Fast (187 tok/s), good SWE-bench, excellent tool calling (98.7%), multimodal, 70.9% beats experts
- **Weaknesses**: Needs configuration for optimal results, context smaller than Gemini
- **Best for**: Speed-sensitive work, API integrations, visual debugging
- **Trade-off**: Faster than Sonnet but requires more parameter tuning

### Tier 3: Speed/Cost Optimized (High Volume)

#### Gemini 3 Flash
- **Strengths**: 78% SWE-bench (beats Pro!), very fast (218 tok/s), cheapest ($0.50/$3), most reliable of Gemini family
- **Special Strength**: Excels at "vibe coding" and frontend/visual interfaces
- **Weaknesses**: Less sophisticated reasoning on very complex tasks
- **Best for**: Interactive development, UI/frontend work, high-volume tasks, budget-conscious teams
- **Note**: Outperforms Gemini 3 Pro on coding while being faster and cheaper

#### Grok Code
- **Strengths**: **Fastest** (455 tok/s!), extreme cost efficiency ($0.20/$1.50), 90%+ cache hit rates
- **Weaknesses**: 70.8% SWE-bench (lower than leaders), struggles with complex architecture
- **Best for**: Rapid prototyping, agentic workflows, real-time product pipelines
- **Avoid for**: Production code review, complex multi-file changes, visual polish

### Tier 4: Specialized

#### GPT-5.1 Codex Max / Codex
- **Strengths**: Context compaction for long sessions, optimized for multi-week projects, 88% on Aider Polyglot
- **Code Quality**: ~80% pass rate, 98 control flow mistakes/MLOC
- **Weaknesses**: Less versatile for quick queries, may falter in visual polish
- **Best for**: Large refactoring, migrations, long autonomous coding sessions, GitHub Copilot integration

#### Composer 1 (Cursor) ⭐ RECOMMENDED FOR SPECK

Cursor's first proprietary LLM, purpose-built for coding. **Since Speck is a Cursor-centric methodology, Composer should be your default for most tasks.**

- **Architecture**: Mixture-of-Experts (MoE), trained via reinforcement learning on real software engineering challenges
- **Strengths**: 
  - **4x faster** than Sonnet 4.5/GPT-5.2 (250 tok/s)
  - Native Cursor integration (semantic search, file editing, terminal commands)
  - Parallel tool execution (reads multiple files simultaneously)
  - Frontier-level on Cursor Bench for agentic tasks
  - Completes tasks in <30 seconds
  - Excellent at fixing linter errors, writing tests autonomously
- **Pricing**: $1.25/$10 per M tokens (competitive with GPT-5.2)
- **Weaknesses**: 
  - Slightly less "smart" for vague prompts (give explicit instructions!)
  - May overcomplicate simple tasks
  - Less depth in complex reasoning vs Opus 4.5
- **Best for**: 
  - All Speck story implementation (`/story-implement`)
  - Rapid prototyping and MVPs
  - Multi-file editing and refactoring
  - Zero-to-one project building
  - Iterative development where speed matters
- **Multi-Agent Pattern**: Use heavier models (Opus/GPT-5.2) for planning, Composer for execution

**User Feedback (X/Twitter)**: "Total game changer" - eliminates wait times, enables step-by-step control. Users report building full apps in minutes. Works well in stacks with Gemini 3 Flash for rapid MVP building (~$1.42/MVP reported).

### ⚠️ Caution

#### Gemini 3 Pro
- **Known Issues**: Aggressive code deletion, context loss, memory leaks (137GB reported)
- **Code Quality**: 200 control flow mistakes/MLOC (highest error rate!)
- **Recommendation**: Avoid for production code without constant human oversight
- **Use case**: Only for multimodal research/analysis where reliability issues are acceptable

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

### LLM-as-Judge Best Practices

When using one LLM to evaluate another's work (increasingly common in 2025):

**1. Use Rubric-Based Grading**:
```
Evaluate this code against the following criteria:
- Correctness: Does it solve the problem? (1-5)
- Maintainability: Is it readable and well-structured? (1-5)
- Security: Are there any vulnerabilities? (1-5)
- Performance: Is it efficient? (1-5)
```

**2. Consider Ensemble Approaches**:
- Have 2-3 different models evaluate the same output
- Aggregate scores to reduce individual model biases
- Flag cases where models disagree significantly

**3. Match Judge Capability to Task**:
- Use Opus 4.5 or GPT-5.2 Extra High as judges (stronger models catch more issues)
- Weaker judges may miss subtle problems or prefer their own style
- Cross-model evaluation highlights style preferences and accuracy differences

**4. Evaluate Against References**:
- Provide spec.md or acceptance criteria as reference
- Ask judge to verify alignment, not just quality

---

---

## 🎯 Cursor-Centric Strategy (IMPORTANT for Speck Users!)

Since Speck is designed for Cursor, leverage Composer as your primary execution model.

### The Speck + Cursor Multi-Agent Pattern

```
Heavy Reasoning Model (Opus 4.5 / GPT-5.2)
    ↓ Plans architecture, makes decisions
    ↓ Creates specs, designs systems
    
Composer 1 (Default for Execution)
    ↓ Implements the plan 4x faster
    ↓ Handles multi-file edits, refactoring
    ↓ Fixes linter errors, writes tests
    
Validation Model (Different from implementer)
    ↓ Reviews Composer's output
    ↓ Catches blind spots
```

### When to Use Composer vs. Other Models

| Scenario | Use Composer? | Alternative |
|----------|---------------|-------------|
| `/story-implement` | ✅ **Yes** (default) | Opus 4.5 for security-critical |
| `/story-tasks` | ✅ **Yes** (fast structured output) | Gemini 3 Flash |
| Multi-file refactoring | ✅ **Yes** (parallel tool use) | Sonnet 4.5 |
| Rapid prototyping | ✅ **Yes** (speed matters) | - |
| Zero-to-one project | ✅ **Yes** (built for this) | - |
| Complex architecture design | ❌ No | Opus 4.5 |
| Vague/ambiguous prompts | ❌ No | Sonnet 4.5 |
| Security-critical code | ❌ No | GPT-5.2 Extra High |
| Deep reasoning tasks | ❌ No | Opus 4.5 |

### Composer Best Practices

1. **Be explicit**: Composer excels with clear instructions, may overcomplicate vague prompts
2. **Use for execution, not planning**: Pair with heavier models for the "thinking" phase
3. **Leverage parallel tool use**: Let it read/edit multiple files simultaneously
4. **Trust its linting**: It fixes linter errors autonomously
5. **Iterate fast**: Its speed enables rapid feedback loops

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
| `/story-specify` | Sonnet 4.5 / Composer 1 | Quick, reliable |
| `/story-plan` | Sonnet 4.5 | Technical design, reasoning needed |
| `/story-tasks` | **Composer 1** / Gemini 3 Flash | Fast, structured output |
| `/story-implement` | **Composer 1** (default) | 4x faster, native Cursor integration |
| `/story-validate` | **Different model than implementer** | Catch implementer's blind spots |

**Note**: Since Speck is Cursor-centric, Composer 1 should be your default for story-level execution.

### Implementation Task Selection (Cursor/Speck Users)

```
Story Implementation
     ↓
┌─────────────────────────────────────────┐
│ Security-critical code?                 │
│ → GPT-5.2 Extra High (lowest vulns)    │
└─────────────────────────────────────────┘
     ↓ No
┌─────────────────────────────────────────┐
│ Complex algorithm / math problem?       │
│ → GPT-5.2 Extra High (100% AIME 2025)  │
└─────────────────────────────────────────┘
     ↓ No
┌─────────────────────────────────────────┐
│ Vague/ambiguous requirements?           │
│ → Sonnet 4.5 (handles ambiguity well)  │
└─────────────────────────────────────────┘
     ↓ No
┌─────────────────────────────────────────┐
│ Using Cursor IDE? (Speck default)       │
│ → Composer 1 (4x faster, native tools) │
└─────────────────────────────────────────┘
     ↓ Not using Cursor
┌─────────────────────────────────────────┐
│ Need maximum speed/low cost?            │
│ → Gemini 3 Flash or Grok Code          │
└─────────────────────────────────────────┘
     ↓ No
┌─────────────────────────────────────────┐
│ Standard feature implementation?        │
│ → Sonnet 4.5 (reliable default)        │
└─────────────────────────────────────────┘
```

**For Cursor/Speck users**: Composer 1 should be your default unless the task requires special handling (security, complex math, ambiguous requirements).

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

---

## 📈 Benchmark Comparison Tables

### Coding Performance

| Model | SWE-Bench Verified | Terminal-Bench | Pass Rate | Control Flow Errors/MLOC | Blocker Vulns/MLOC |
|-------|-------------------|----------------|-----------|--------------------------|-------------------|
| Opus 4.5 | 80.9% | 59.3% | 83.62% | 55 | 44 |
| GPT-5.2 Extra High | 80.0% | 47.6% | 80.66% | **22** | **16** |
| Gemini 3 Flash | 78.0% | N/A | N/A | N/A | N/A |
| Sonnet 4.5 | 77.2% | 50.0% | ~80% | 152 | ~198 |
| Gemini 3 Pro | 76.8% | 42.1% | 81.72% | 200 | N/A |
| Grok Code | 70.8% | N/A | N/A | N/A | N/A |
| Codex Max | ~80% | N/A | 80% | 98 | N/A |

**Key Insight**: GPT-5.2 Extra High has the **best security profile** with lowest vulnerability rates.

### Speed and Pricing

| Model | Input/Output ($/M) | Tokens/Second | 10M Token Project Cost |
|-------|-------------------|---------------|------------------------|
| Grok Code | $0.20 / $1.50 | **455** | ~$10 |
| Gemini 3 Flash | $0.50 / $3 | 218 | ~$30 |
| Gemini 3 Pro | $2 / $12 | 95-128 | ~$140 |
| GPT-5.2 | $1.75 / $14 | 187 | ~$158 |
| Composer 1 | N/A (economical) | 250 | Low |
| Sonnet 4.5 | $3 / $15 | Moderate | ~$180 |
| Opus 4.5 | $5 / $25 | 49-70 | ~$300 |

**Key Insight**: Grok Code is 30x cheaper than Opus 4.5 for high-volume work.

---

## 📚 Sources

This pattern is based on December 2025 benchmarks and user reports:

- SWE-bench Verified scores
- Terminal-Bench 2.0 evaluations
- SonarQube code quality analysis
- Token efficiency measurements
- Production reliability reports
- Speed benchmarks (tokens/second)
- Pricing data from official sources
- X/Twitter developer community reports

**Key Citations**:
- [LLM Comparison Guide: December 2025 Rankings](https://www.digitalapplied.com/blog/llm-comparison-guide-december-2025)
- [New data on code quality: GPT-5.2, Opus 4.5, Gemini 3](https://www.sonarsource.com/blog/new-data-on-code-quality-gpt-5-2-high-opus-4-5-gemini-3-and-more/)
- [LLM Evaluation in 2025: LLM-as-Judge Best Practices](https://medium.com/@QuarkAndCode/llm-evaluation-in-2025-metrics-rag-llm-as-judge-best-practices-ad2872cfa7cb)
- [Composer: Building a fast frontier model with RL](https://cursor.com/blog/composer)
- [Grok Code Fast 1 | xAI](https://x.ai/news/grok-code-fast-1)

**Update Frequency**: This pattern should be reviewed monthly as model capabilities evolve rapidly.

---

*Generated by Speck methodology*
*Pattern Version: 1.0.0*
