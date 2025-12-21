# Design System: [Project Name]

**Project**: [PROJECT_ID]  
**Created**: [DATE]  
**Version**: 1.0  
**Status**: [Draft/Active/Deprecated]

---

## 🔬 Research Informing This Design System

**Web Search Findings**:
- [Topic]: [Finding with source URL]
- [Topic]: [Finding with source URL]

**Deep Research Reports** (if any):
- [Report filename]: [Key insights that influenced design decisions]

**Research Impact on Design Decisions**:
- [Design Token]: Chosen based on [research finding]
- [Component Pattern]: Informed by [source/report]

---

## 🎨 Design Tokens

### Color System

#### Brand Colors
| Token | Value | Usage |
|-------|-------|-------|
| `primary-50` | #F0F9FF | Lightest tint for backgrounds |
| `primary-100` | #E0F2FE | Light backgrounds |
| `primary-200` | #BAE6FD | Hover states for light elements |
| `primary-300` | #7DD3FC | Borders, dividers |
| `primary-400` | #38BDF8 | Secondary actions |
| `primary-500` | #0EA5E9 | **Primary brand, CTAs** |
| `primary-600` | #0284C7 | Hover state for primary |
| `primary-700` | #0369A1 | Active/pressed states |
| `primary-800` | #075985 | Dark accents |
| `primary-900` | #0C4A6E | Darkest, high contrast |

#### Neutral Colors
| Token | Value | Usage |
|-------|-------|-------|
| `gray-50` | #F9FAFB | Subtle backgrounds |
| `gray-100` | #F3F4F6 | Light backgrounds |
| `gray-200` | #E5E7EB | Borders |
| `gray-300` | #D1D5DB | Disabled borders |
| `gray-400` | #9CA3AF | Placeholder text |
| `gray-500` | #6B7280 | Secondary text |
| `gray-600` | #4B5563 | Primary text |
| `gray-700` | #374151 | Headings |
| `gray-800` | #1F2937 | High emphasis text |
| `gray-900` | #111827 | Highest contrast |

#### Semantic Colors
| Token | Value | Usage |
|-------|-------|-------|
| `success-500` | #10B981 | Success states, confirmations |
| `warning-500` | #F59E0B | Warnings, caution states |
| `error-500` | #EF4444 | Errors, destructive actions |
| `info-500` | #3B82F6 | Informational messages |

#### Dark Mode Colors
[Define if applicable]

### Typography Scale

#### Font Families
| Token | Value | Usage |
|-------|-------|-------|
| `font-sans` | Inter, system-ui, -apple-system, sans-serif | Body text, UI |
| `font-mono` | 'JetBrains Mono', monospace | Code, technical |
| `font-display` | [Display font if different] | Headlines |

#### Type Scale
| Token | Size | Line Height | Usage |
|-------|------|-------------|-------|
| `text-xs` | 12px | 16px | Captions, labels |
| `text-sm` | 14px | 20px | Secondary text |
| `text-base` | 16px | 24px | **Body text default** |
| `text-lg` | 18px | 28px | Lead paragraphs |
| `text-xl` | 20px | 28px | Small headings |
| `text-2xl` | 24px | 32px | Section headings |
| `text-3xl` | 30px | 36px | Page headings |
| `text-4xl` | 36px | 40px | Hero headings |
| `text-5xl` | 48px | 48px | Display |
| `text-6xl` | 60px | 60px | Extra large display |

#### Font Weights
| Token | Value | Usage |
|-------|-------|-------|
| `font-light` | 300 | De-emphasized text |
| `font-normal` | 400 | **Body text default** |
| `font-medium` | 500 | Buttons, emphasis |
| `font-semibold` | 600 | Headings |
| `font-bold` | 700 | Strong emphasis |

### Spacing System

Base unit: [4px or 8px]

| Token | Value | Pixels | Usage |
|-------|-------|--------|-------|
| `space-0` | 0 | 0px | No space |
| `space-0.5` | 0.125rem | 2px | Tight spacing |
| `space-1` | 0.25rem | 4px | Between related elements |
| `space-2` | 0.5rem | 8px | **Default spacing** |
| `space-3` | 0.75rem | 12px | Small gaps |
| `space-4` | 1rem | 16px | Medium gaps |
| `space-5` | 1.25rem | 20px | Between sections |
| `space-6` | 1.5rem | 24px | Large gaps |
| `space-8` | 2rem | 32px | Major sections |
| `space-10` | 2.5rem | 40px | Page padding |
| `space-12` | 3rem | 48px | Hero sections |
| `space-16` | 4rem | 64px | Extra large |

### Size Scale
[Define standard sizes for components]

### Border Radius
| Token | Value | Usage |
|-------|-------|-------|
| `radius-none` | 0 | Sharp corners |
| `radius-sm` | 2px | Subtle rounding |
| `radius-md` | 4px | **Default radius** |
| `radius-lg` | 8px | Cards, containers |
| `radius-xl` | 12px | Modals, large cards |
| `radius-2xl` | 16px | Special elements |
| `radius-full` | 9999px | Pills, avatars |

### Shadows
| Token | Value | Usage |
|-------|-------|-------|
| `shadow-none` | none | No shadow |
| `shadow-sm` | 0 1px 2px rgba(0,0,0,0.05) | Subtle elevation |
| `shadow-md` | 0 4px 6px rgba(0,0,0,0.1) | **Default shadow** |
| `shadow-lg` | 0 10px 15px rgba(0,0,0,0.1) | Modals, dropdowns |
| `shadow-xl` | 0 20px 25px rgba(0,0,0,0.1) | High elevation |

### Animation
| Token | Value | Usage |
|-------|-------|-------|
| `duration-fast` | 150ms | Micro interactions |
| `duration-normal` | 250ms | **Default transitions** |
| `duration-slow` | 350ms | Complex animations |
| `ease-default` | cubic-bezier(0.4, 0, 0.2, 1) | Standard easing |

---

## 🧩 Component Library

### Primitive Components

#### Button
**Purpose**: Trigger actions and navigate

**Variants**:
- `primary` - Main actions
- `secondary` - Alternative actions
- `ghost` - Minimal emphasis
- `danger` - Destructive actions

**Sizes**: `sm`, `md` (default), `lg`

**States**: default, hover, active, focus, disabled, loading

**Example**:
```jsx
<Button variant="primary" size="md" onClick={handleClick}>
  Click Me
</Button>
```

#### Input
**Purpose**: Text entry fields

**Types**:
- `text` - Single line text
- `email` - Email validation
- `password` - Obscured entry
- `number` - Numeric input
- `textarea` - Multi-line text

**States**: default, focus, error, disabled, readonly

#### Label
[Component definition]

#### Link
[Component definition]

### Layout Components

#### Container
**Purpose**: Constrain content width

**Variants**:
- `full` - Full width
- `prose` - Reading width (~65ch)
- `narrow` - Form width
- `wide` - Dashboard width

#### Grid
**Purpose**: Responsive grid layouts

**Props**:
- `columns` - 1-12 or responsive object
- `gap` - Spacing between items
- `align` - Alignment options

#### Stack
**Purpose**: Vertical or horizontal spacing

**Props**:
- `direction` - vertical/horizontal
- `gap` - Space between children
- `align` - Alignment
- `justify` - Distribution

### Feedback Components

#### Alert
[Component definition]

#### Toast
[Component definition]

#### Progress
[Component definition]

### Navigation Components

#### Nav
[Component definition]

#### Tabs
[Component definition]

#### Breadcrumb
[Component definition]

### Overlay Components

#### Modal
[Component definition]

#### Tooltip
[Component definition]

#### Popover
[Component definition]

### Data Display Components

#### Table
[Component definition]

#### Card
[Component definition]

#### Badge
[Component definition]

---

## 🎨 Design Patterns

### Form Patterns

#### Field Layout
```
Label (required indicator)
Input field
Helper text or error message
```

#### Validation
- Validate on blur
- Show errors below fields
- Inline success indicators
- Summary for form-level errors

#### Button Placement
- Primary action on right
- Cancel/secondary on left
- Full width on mobile

### Loading Patterns

#### Skeleton Screens
Show layout structure while loading

#### Spinner Usage
- Small: Inline with text
- Medium: Button/input loading
- Large: Full page loading

#### Progressive Loading
1. Show skeleton
2. Load critical content
3. Load secondary content
4. Enable interactions

### Empty States

#### Structure
1. Illustration (optional)
2. Headline
3. Description
4. Action (if applicable)

#### Types
- First use (onboarding)
- No results (search/filter)
- Error state
- Success completion

### Error Handling

#### Inline Errors
- Show below field
- Red border/text
- Icon + message

#### Page-level Errors
- Alert component at top
- Clear error description
- Recovery action

#### 404/Error Pages
- Friendly message
- Helpful actions
- Maintain navigation

---

## 📱 Responsive Behavior

### Breakpoints
| Token | Value | Target |
|-------|-------|--------|
| `sm` | 640px | Large phones |
| `md` | 768px | Tablets |
| `lg` | 1024px | Desktop |
| `xl` | 1280px | Large desktop |
| `2xl` | 1536px | Extra large |

### Mobile Adaptations
- Stack horizontal layouts
- Full-width buttons
- Simplified navigation
- Touch-friendly targets (44px min)

### Container Queries
[If using container queries, define here]

---

## ♿ Accessibility Guidelines

### Color Contrast
- Normal text: 4.5:1 minimum
- Large text: 3:1 minimum
- UI elements: 3:1 minimum

### Focus Indicators
- 2px solid outline
- 3:1 contrast with background
- Visible on all interactive elements

### Keyboard Navigation
- Tab through all interactive elements
- Escape closes overlays
- Enter/Space activates buttons
- Arrow keys for menus/tabs

### Screen Reader Support
- Semantic HTML preferred
- ARIA labels when needed
- Live regions for updates
- Skip links for navigation

### Motion Preferences
- Respect `prefers-reduced-motion`
- Provide motion-free alternatives
- Essential motion only

---

## 🛠️ Implementation Guide

### Technology Stack
- CSS Framework: [Tailwind/CSS Modules/Styled Components]
- Component Framework: [React/Vue/Svelte]
- Build Tool: [Vite/Webpack/etc]

### File Structure
```
design-system/
├── tokens/
│   ├── colors.css
│   ├── typography.css
│   └── spacing.css
├── components/
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.module.css
│   │   └── Button.stories.tsx
│   └── [other components]
└── patterns/
    ├── forms.md
    └── layouts.md
```

### Naming Conventions
- Components: PascalCase
- CSS classes: BEM or utility classes
- Design tokens: kebab-case
- Props: camelCase

### Code Standards
[Specific coding guidelines]

---

## 📋 Usage Guidelines

### Do's
- ✅ Use design tokens for all values
- ✅ Follow component APIs
- ✅ Test across breakpoints
- ✅ Validate accessibility

### Don'ts
- ❌ Hard-code values
- ❌ Create one-off components
- ❌ Override system styles
- ❌ Skip accessibility testing

### Getting Started
1. Install design system package
2. Import tokens/components
3. Follow patterns
4. Test thoroughly

---

## 🔄 Governance

### Change Process
1. Propose change with rationale
2. Design review
3. Implementation
4. Documentation update
5. Version release

### Version Control
- Semantic versioning
- Breaking changes documented
- Migration guides provided

### Quality Checklist
- [ ] Follows design principles
- [ ] Uses existing tokens
- [ ] Accessible (WCAG AA)
- [ ] Responsive
- [ ] Documented
- [ ] Tested

---

## 📚 Resources

### Design Tools
- Figma library: [Link]
- Sketch symbols: [Link]
- Adobe XD kit: [Link]

### Development
- Storybook: [Link]
- NPM package: [Link]
- GitHub repo: [Link]

### Documentation
- Usage examples: [Link]
- Video tutorials: [Link]
- FAQ: [Link]

---

**Next Steps**:
1. Review with stakeholders
2. Build component library
3. Create Storybook stories
4. Document patterns
5. Train team members
