# UI Specification: [Story Name]

**Story**: [STORY_ID]  
**Epic**: [EPIC_ID]  
**Project**: [PROJECT_ID]  
**Created**: [DATE]  
**Version**: 1.0

---

## 📊 Design Context Sources

**This UI specification uses tokens and patterns from**:

| Document | Path | Key Sections Used |
|----------|------|-------------------|
| Design System | `specs/projects/[PROJECT_ID]/design-system.md` | [Tokens, Components] |
| UX Strategy | `specs/projects/[PROJECT_ID]/ux-strategy.md` | [Principles, Voice/Tone] |
| Epic Wireframes | `[EPIC_PATH]/wireframes.md` | [Relevant screens] |
| Recipe (if active) | `.speck/recipes/[RECIPE]/recipe.yaml` | [visual_testing, stack] |

**If documents missing**: Run `/project-design-system` and `/project-ux` for consistency.

---

## PROFILE surface impact

Does this story touch a declared PROFILE surface (see `project.md` PROFILE surfaces table)?

- [ ] Yes — specify surface(s): ___________
- [ ] No

If **Yes**:
- Surfaces touched: ___________
- Drift check: `bash .speck/scripts/regenerate-project-readme.sh --check` (paste output or link)
- Copy aligned with `product-contract.md` Section 1: [ ] Reviewer sign-off

---

## 📦 Component Overview

**Component Name**: [Name]  
**Type**: [New Component/Modified Component/Composite]  
**Design System Reference**: `design-system.md` version [X.X]  
**Affects**: [List of screens/features affected]

---

## 🎨 Visual Specifications

### Component Anatomy

```
[ASCII diagram showing component structure]
Example:
┌─────────────────────────┐
│ [Icon] Label Text      │ <- Typography specs
│        Subtitle here    │
├─────────────────────────┤
│                         │ <- Content area  
│     Main Content        │
│                         │
├─────────────────────────┤
│ [Secondary] [Primary]   │ <- Actions
└─────────────────────────┘
```

### Dimensions

**Container**
- Width: [Fixed/Fluid/Min-Max]
- Height: [Fixed/Auto/Min-Max]
- Aspect Ratio: [If applicable]

**Spacing** (using design system units)
- Padding: [Top Right Bottom Left]
- Internal spacing: [Between elements]
- External margin: [Context-dependent]

**Sizes** (if variants exist)
- Small: [Dimensions]
- Medium: [Dimensions] (default)
- Large: [Dimensions]

---

## 🎨 Visual Properties

### Colors

| State | Property | Token | Value | Notes |
|-------|----------|-------|-------|-------|
| Default | Background | `color-background-primary` | #FFFFFF | |
| Default | Text | `color-text-primary` | #1A1A1A | |
| Default | Border | `color-border-default` | #E5E5E5 | |
| Hover | Background | `color-background-hover` | #F5F5F5 | |
| Active | Background | `color-background-active` | #EBEBEB | |
| Focus | Outline | `color-focus` | #0066CC | 2px solid |
| Disabled | All | `color-disabled` | #999999 | 50% opacity |
| Error | Border | `color-error` | #CC0000 | |

### Typography

| Element | Token | Size | Weight | Line Height | Letter Spacing |
|---------|-------|------|--------|-------------|----------------|
| Title | `type-heading-sm` | 18px | 600 | 24px | -0.01em |
| Body | `type-body-default` | 16px | 400 | 24px | 0 |
| Caption | `type-caption` | 14px | 400 | 20px | 0.01em |

### Effects

**Shadows**
- Default: `shadow-sm` - [Value]
- Hover: `shadow-md` - [Value]
- Active: `shadow-none`

**Border Radius**
- Default: `radius-md` - [Value]
- Variant: [If different]

---

## 🎭 States & Behavior

### Interactive States

**Default**
- Appearance: [Description]
- Cursor: `default` or `pointer`

**Hover**
- Trigger: Mouse enter
- Changes: [List all changes]
- Transition: `all 200ms ease`

**Focus**
- Trigger: Keyboard navigation
- Changes: [Outline specs]
- Must be visible

**Active**
- Trigger: Mouse down
- Changes: [Visual feedback]

**Disabled**
- Appearance: [Reduced opacity, changed colors]
- Interaction: No hover effects, cursor: `not-allowed`

**Loading**
- Display: [Spinner/skeleton/progress]
- Prevents: All interactions
- Announcement: "Loading"

**Error**
- Visual: [Border, color, icon]
- Message: [Where/how displayed]

### Component-Specific States

[Additional states unique to this component]

---

## ⚡ Interactions

### Mouse Interactions
- **Click**: [Primary action]
- **Right-click**: [Context menu if applicable]
- **Drag**: [If draggable]

### Keyboard Support
- **Tab**: Focus component
- **Enter/Space**: Activate primary action
- **Escape**: Cancel/close if applicable
- **Arrow keys**: [If navigation needed]

### Touch Interactions
- **Tap**: Same as click
- **Long press**: [If applicable]
- **Swipe**: [If applicable]

### Animations

**Entry Animation**
- Trigger: [When component appears]
- Duration: [Time]
- Easing: [Function]

**Interaction Animations**
- Hover: [Description]
- Click: [Description]
- State changes: [Description]

---

## 📱 Responsive Behavior

### Breakpoints

**Mobile (< 768px)**
- Layout: [Changes]
- Sizing: [Adjustments]
- Interactions: [Touch optimizations]

**Tablet (768px - 1023px)**
- Layout: [Changes]
- Sizing: [Adjustments]

**Desktop (≥ 1024px)**
- Layout: [Default]
- Sizing: [Default]

### Validation Matrix (from recipe visual_testing)

*Use the active recipe’s `visual_testing` config to define what “responsive” means for this story.*

| Target | Breakpoint/Device | Required | Notes |
|--------|-------------------|----------|-------|
| Web | mobile (e.g. 375px) | [Yes/No] | |
| Web | tablet (e.g. 768px) | [Yes/No] | |
| Web | desktop (e.g. 1024px) | [Yes/No] | |
| Web | wide (e.g. 1280px) | [Yes/No] | |
| Mobile | iOS (e.g. iPhone 15) | [Yes/No] | |
| Mobile | Android (e.g. Pixel 8) | [Yes/No] | |
| Desktop | OS (macOS/Windows/Linux) | [Yes/No] | |
| Extension | popup sizes (standard/compact/wide) | [Yes/No] | |

### Adaptive Elements
- [Element that changes]
- [How it adapts]

---

## ♿ Accessibility Requirements

### WCAG Compliance
- Level: AA
- Color Contrast: [Ratios for text/UI elements]
- Focus Indicators: [Visible, 3:1 contrast]
- Touch Targets: [Minimum 44x44px]

### Screen Reader
- Role: [ARIA role if needed]
- Label: [aria-label if needed]
- Description: [aria-describedby if needed]
- Announcements: [Live regions if needed]

### Keyboard Navigation
- Focusable: Yes
- Tab order: [Natural/Specific]
- Shortcuts: [If applicable]

---

## 💻 Implementation Guide

### HTML Structure
```html
<div class="component-name" role="[role]" aria-label="[label]">
  <div class="component-name__header">
    [Header content]
  </div>
  <div class="component-name__body">
    [Body content]
  </div>
  <div class="component-name__actions">
    <button class="btn btn--secondary">Secondary</button>
    <button class="btn btn--primary">Primary</button>
  </div>
</div>
```

### CSS Classes (BEM notation)
```css
.component-name { }
.component-name--variant { }
.component-name__element { }
.component-name__element--modifier { }
```

### Component API (if framework)
```jsx
<ComponentName
  variant="default"
  size="medium"
  title="Title text"
  onAction={handleAction}
  disabled={false}
  loading={false}
>
  Content goes here
</ComponentName>
```

### Props/Attributes

| Prop | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| variant | string | "default" | No | Visual variant |
| size | string | "medium" | No | Size variant |
| disabled | boolean | false | No | Disabled state |
| loading | boolean | false | No | Loading state |
| onAction | function | - | No | Click handler |

---

## 📋 Content Guidelines

### Text Content
- Title: [Max characters, guidelines]
- Body: [Max characters, guidelines]
- Actions: [Button label guidelines]

### Dynamic Content
- Empty state: "[Message when no content]"
- Loading: "[Loading message]"
- Error: "[Error message pattern]"

### Microcopy
- Tooltips: [If applicable]
- Help text: [If applicable]
- Validation messages: [Patterns]

---

## 🧪 Testing Checklist

### Visual Testing
- [ ] All states render correctly
- [ ] Responsive at all breakpoints
- [ ] Animations perform smoothly
- [ ] Design tokens applied correctly

### Functional Testing
- [ ] All interactions work as specified
- [ ] Keyboard navigation complete
- [ ] Screen reader announcements correct
- [ ] Error states handle gracefully

### Platform Coverage (from recipe visual_testing)

**Web (if applicable)**:
- [ ] Chrome/Edge
- [ ] Firefox
- [ ] Safari
- [ ] Mobile browsers

**Mobile (if applicable)**:
- [ ] iOS devices (from recipe)
- [ ] Android devices (from recipe)

**Desktop (if applicable)**:
- [ ] macOS
- [ ] Windows
- [ ] Linux

**Extension (if applicable)**:
- [ ] Chrome
- [ ] Edge

---

## 📎 Related Specifications

- Design System: [Link to component in design system]
- Figma/Sketch: [Link to design file]
- Storybook: [Link to component story]
- Epic Wireframes: [Reference to parent wireframes]

---

## ✅ Sign-off Checklist

- [ ] Design approved by: [Name]
- [ ] Dev ready: All specs complete
- [ ] QA criteria defined
- [ ] Accessibility reviewed
- [ ] Content approved

---

## 📝 Notes & Decisions

[Any additional context, decisions made, or special considerations]

---

**Next Steps**: 
1. Developer implementation
2. Create component story
3. Write unit tests
4. QA validation
5. Design review
