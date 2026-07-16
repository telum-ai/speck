<!-- LAZY template — read ONLY when Job C (IS-IT-CRAFTED / the TASTE axis) runs. Zero always-on cost. -->

# Connoisseur Critique — the TASTE Axis (Job C · IS-IT-CRAFTED)

TASTE is the 4th non-collapsible readiness axis: **CORRECT / ON-CONTRACT / FELT-GOOD / TASTE**.
- **FELT-GOOD** (Job B, naive-hostile) = "not broken / not confusing" — legibility.
- **TASTE** (Job C, connoisseur-hostile) = "crafted / premium / it sings" — aesthetic connoisseurship.

They are **non-collapsible**: a screen can be perfectly legible (FELT-GOOD pass) and still cheap-feeling (TASTE fail). Judge the **pixels** (the screenshot), never the AX tree. This is a hostile pass: assume every screen has something that could be more crafted, and argue "no defect" rather than defaulting to it. ≥2 pixel-anchored observations per screen.

## The 🎭 `connoisseur-hostile` persona

A discerning, taste-driven user of THIS product's category who has seen the best-in-class and is quietly unimpressed by the merely-functional. Not a designer running a checklist — a person who feels when something is beautiful and when it is trying too hard or not trying at all.

## The dual anchor (the core rule)

Every verdict is judged against BOTH anchors. **The same treatment can be excellent taste in one product and awful in another** — so a universal rule never overrides the product's declared intent.

- **Anchor A — PRODUCT-RELATIVE** (what THIS product is trying to be):
  - `product-contract.md` **§6b Aesthetic Contract** — Target Feeling, Reference Exemplars, Restraint Rules, What-Would-Cheapen-It.
  - `design-system.md` (if present) — Design Philosophy, Bold Choices (Non-Negotiable), Emotional Keywords, "What This Design IS NOT".
  - `product-contract.md` §5 magic-moment intent + §6 voice.
- **Anchor B — UNIVERSAL** (general craft): reuse the **`visual-quality`** skill's *Universal Design Quality Principles* (Typography-as-Hero, Deliberate Negative Space, Motion Philosophy, Texture/Depth). Do not re-author them — read that skill.

### Splitting Anchor A: HARD rules vs FUZZY intent

- **HARD declared rule** — a checkable Bold-Choice / token (e.g. "max two font weights", "no drop shadows", a named accent token). A violation is an **objective defect** → may be BAD, may block. NOT a fork.
- **FUZZY declared intent** — emotional/vibe language (e.g. "gentle", "confident", "playful"). A mismatch is a **judgment** → **FORK only, never a block**. (An AI must not dress its own aesthetic opinion as rule-enforcement.)

### Verdict logic (per screen, per dimension)

| Situation | Verdict |
|-----------|---------|
| Both anchors satisfied | **GOOD** |
| A HARD declared rule / hard-objective craft defect is violated | **BAD** (may block — see severity) |
| Only soft/subjective concerns, both anchors otherwise met | **ACCEPTABLE** + note |
| Anchors CONFLICT (product declares X; universal craft says X reads cheap here) | **FORK** — the declared intent wins by default; if you judge the *declared intent itself* yields a cheap result, escalate a fork ABOUT the intent — never a silent override |
| Anchor A unanswerable (§6b is `REPLACE_BEFORE_SHIP` AND no `design-system.md`) | judge Anchor B only, stamp **`taste_anchor: universal-only`**, convert borderline calls to FORKS, nudge `/project-design-system` — a universal-only pass may not make a confident product-relative verdict |

## The 8 craft dimensions (per screen)

Give each a GOOD / ACCEPTABLE / BAD with a pixel-anchored reason:

1. **Visual hierarchy / focal clarity** — is the eye led to the one thing that matters?
2. **Spacing, rhythm & alignment** — deliberate negative space, a consistent grid, no raggedness.
3. **Colour & gradient craft/restraint** — a rule behind every accent; gradients tasteful, not garish.
4. **Typography** — intentional scale + weight hierarchy; no proliferation.
5. **Iconography & illustration** — quality + consistency; on-brand, not stock/placeholder.
6. **Motion & micro-interaction delight** — matches the motion philosophy; present where it should sing.
7. **Copy that sings** — voice-perfect, specific, never generic AI cheerleading.
8. **Emotional resonance** — does the *visual feeling* match the intended feeling (Anchor A)?

Plus **cross-product coherence** where a portfolio house-style is declared (else note as out-of-scope for a single repo).

## Severity → blocking (owner ruling: severe BAD hard-blocks)

- A **severe BAD** — a BAD verdict backed by **≥2 pixel-grounded craft-principle violations** on a magic-moment or flagship surface — **caps the readiness state** (PASS-blocking) **even without a named declared rule**. The AI cannot block on vibes: severity requires the concrete, image-anchored violations, listed.
- An ordinary BAD (one soft violation, no named rule) → **cheapens-it note** or **fork**, not a block.
- A HARD-declared-rule violation → BAD, caps state (objective).

The **remedy** for any blocking BAD is still a **surfaced fork** — you gate on the objective floor, but the owner decides the direction of the fix.

## Fork triage (prevents fork-flooding → the axis reverting to advisory-ignored)

Only these become enumerated **owner forks**:
- Anchor conflicts (product intent vs universal craft),
- intent-underspecified borderline calls,
- HIGH-severity Anchor-B-weak defects where the fix direction is contestable.

Low-severity subjective observations go on the **cheapens-it** list as notes — nothing is silently dropped, but the owner gets a small triaged set, not a flood.

## Auto-fix policy (conservative by default — never launder taste)

The agent may auto-fix ONLY:
- (a) a violation of a **named declared rule / token**, or
- (b) a **hard-objective defect** (clipped/overlapping element, off-grid misalignment, contrast/a11y failure).

Anything requiring a **direction choice** ("reduce the accent colours", "collapse the type scale") when no declared rule names it → a **surfaced fork**, never a unilateral edit. Under `universal-only`, auto-fix hard-objective defects only; surface everything else.

## Output → `larp-recordings/<sha>-connoisseur-findings.md` (SHA-stamped)

```markdown
---
artifact_type: connoisseur-findings
taste_anchor: [product+universal | universal-only]
---
# Connoisseur Findings — <persona/surface> — <sha> — <date>

## ✨ Makes-it-premium (protect these in future edits)
- <screen>: <what already sings, pixel-anchored>

## 🩹 Cheapens-it (objective craft defects, P0–P3)
- [P?] <screen>: <defect, pixel-anchored> — <named rule violated | hard-objective | universal-craft>

## 🎨 Aesthetic Forks — Owner Decision
- Fork: <the decision>
  - Option A: <…>  ·  Option B: <…>
  - Pixel reasoning: <…>
  - Anchor status: <which anchor is silent / in conflict>
  - AI recommendation: <A|B + why>

## Per-screen verdicts
| Screen | Hierarchy | Spacing | Colour | Type | Icon | Motion | Copy | Emotion | Verdict |
|--------|-----------|---------|--------|------|------|--------|------|---------|---------|
| <name> | … | … | … | … | … | … | … | … | GOOD/ACCEPTABLE/BAD |

## TASTE verdict
- **taste_axis**: [ai-critiqued | forks-open]  (forks-open if any Aesthetic Fork is open)
- **taste_anchor**: [product+universal | universal-only]
- **Severe-BAD blockers**: <none | list — each capping the claimable state>
```

Stamp with `.speck/scripts/stamp-truth.sh`. The consuming validation report carries `taste_axis` + `taste_anchor` in its frontmatter and an `### 🎨 Aesthetic Forks — Owner Decision` subsection when `taste_axis: forks-open`.
