# Wireframes: [Epic Name]

**Epic**: [EPIC_ID]  
**Project**: [PROJECT_ID]  
**Created**: [DATE]  
**Version**: 1.0

---

## 📊 Design Context Sources

**These wireframes use tokens and patterns from**:

| Document | Path | Key Sections Used |
|----------|------|-------------------|
| Design System | `specs/projects/[PROJECT_ID]/design-system.md` | [Tokens, Components, Grid] |
| UX Strategy | `specs/projects/[PROJECT_ID]/ux-strategy.md` | [Principles, Voice/Tone, Accessibility] |
| User Journey | `[EPIC_DIR]/user-journey.md` | [Touchpoints, Emotional Arc] |

**If documents missing**: Run `/project-design-system` and `/project-ux` for consistency.

---

## 📱 Screen Inventory

Based on the user journey, this epic requires the following screens:

| Screen ID | Screen Name | Purpose | Device Priority |
|-----------|-------------|---------|-----------------|
| S01 | [Name] | [What it does] | Desktop/Mobile/Both |
| S02 | [Name] | [What it does] | Desktop/Mobile/Both |
| S03 | [Name] | [What it does] | Desktop/Mobile/Both |

**Total Screens**: [Number]  
**Responsive Requirements**: [Mobile-first/Desktop-first/Adaptive]

---

## 🎨 Design System Application

**Source**: Reference `specs/projects/[PROJECT_ID]/design-system.md`

**Components Used** (from design-system.md component library):
- Navigation: [Component names from design system]
- Forms: [Component names]
- Data Display: [Component names]
- Feedback: [Component names]
- Layout: [Component names]

**Design Tokens Applied**:
- Colors: [Token names used, e.g., `primary-500`, `surface-100`]
- Typography: [Token names, e.g., `heading-lg`, `body-md`]
- Spacing: [Token names, e.g., `space-4`, `space-8`]
- Radius: [Token names, e.g., `radius-md`, `radius-lg`]

**Custom Components Needed**:
- [Component]: [Why it's unique to this epic - will be added to design-system.md after validation]
- [Component]: [Why it's unique to this epic]

**⚠️ CRITICAL**: Use existing components from design-system.md before creating custom ones.

---

## 🖼️ Wireframes

### Screen S01: [Screen Name]

**Purpose**: [What this screen accomplishes]  
**Entry Points**: [How users get here]  
**User Goal**: [What users want to do]

#### Desktop Layout (1440px)
```
┌─────────────────────────────────────────────────────────────┐
│ ┌─[Logo]──────────────[Navigation]─────────────[User Menu]─┐│
│ └───────────────────────────────────────────────────────────┘│
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                     [Page Title]                         │ │
│  │                  [Subtitle/Context]                      │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   [Card]    │  │   [Card]    │  │   [Card]    │         │
│  │             │  │             │  │             │         │
│  │  Content    │  │  Content    │  │  Content    │         │
│  │             │  │             │  │             │         │
│  │  [Action]   │  │  [Action]   │  │  [Action]   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                    [Section Title]                       │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │  [Table Header] | [Header] | [Header] | [Header]         │ │
│  ├─────────────────────────────────────────────────────────┤ │
│  │  [Data]        | [Data]   | [Data]   | [Actions]        │ │
│  │  [Data]        | [Data]   | [Data]   | [Actions]        │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
│                              [Primary Action]  [Secondary]    │
└─────────────────────────────────────────────────────────────┘

Legend:
[ ] = Interactive element
─ = Border/Divider
│ = Container edge
```

#### Mobile Layout (375px)
```
┌─────────────────┐
│ ☰  [Logo]  [👤] │
├─────────────────┤
│                 │
│  [Page Title]   │
│  [Subtitle]     │
│                 │
├─────────────────┤
│  ┌─────────────┐│
│  │   [Card]    ││
│  │             ││
│  │  Content    ││
│  │             ││
│  │  [Action]   ││
│  └─────────────┘│
│                 │
│  ┌─────────────┐│
│  │   [Card]    ││
│  │             ││
│  │  Content    ││
│  │             ││
│  │  [Action]   ││
│  └─────────────┘│
│                 │
│ [Primary Action]│
│                 │
└─────────────────┘
```

#### Key Interactions
- **[Element]**: [What happens on interaction]
- **[Element]**: [Behavior description]
- **[Element]**: [State changes]

#### Content Requirements
- **Heading**: [Specific text or content type]
- **Body**: [Content requirements]
- **Actions**: [Button labels and purposes]
- **Help Text**: [Tooltips or guidance needed]

#### States
- **Default**: [Normal state appearance]
- **Loading**: [What shows during data fetch]
- **Empty**: [What shows with no data]
- **Error**: [Error state handling]
- **Success**: [Success feedback]

#### Accessibility Notes
- **Focus Order**: [Tab order through elements]
- **Screen Reader**: [Important announcements]
- **Keyboard Nav**: [Special keyboard interactions]

---

### Screen S02: [Screen Name]

[Repeat the above pattern for each screen]

---

## 🔄 Responsive Behavior

### Breakpoints
- **Mobile**: 320px - 767px
- **Tablet**: 768px - 1023px
- **Desktop**: 1024px+
- **Wide**: 1440px+

### Adaptation Rules
1. **Navigation**: [How nav changes across breakpoints]
2. **Layout**: [Grid/column changes]
3. **Content**: [What shows/hides]
4. **Interactions**: [Touch vs mouse considerations]

---

## 🎯 Interaction Patterns

### Form Interactions
- **Validation**: [When validation occurs]
- **Error Display**: [How errors show]
- **Success Feedback**: [How success is communicated]

### Navigation Patterns
- **Between Screens**: [How users move through the epic]
- **Back Navigation**: [How users go back]
- **Breadcrumbs**: [If applicable]

### Data Interactions
- **Loading States**: [Skeleton screens, spinners]
- **Refresh**: [Pull to refresh, auto-refresh]
- **Pagination**: [How paging works]

---

## 📐 Layout Grid

**Desktop Grid**:
- Columns: 12
- Gutter: 24px
- Margin: 32px

**Mobile Grid**:
- Columns: 4
- Gutter: 16px
- Margin: 16px

---

## 🎨 Visual Hierarchy

### Typography Scale Application
- **Page Title**: [Size/Weight]
- **Section Headers**: [Size/Weight]
- **Body Text**: [Size/Weight]
- **Captions**: [Size/Weight]

### Spacing System Application
- **Between Sections**: [Space unit]
- **Within Cards**: [Space unit]
- **Form Elements**: [Space unit]

---

## 📝 Content Guidelines

### Tone & Voice

**Source**: Reference `specs/projects/[PROJECT_ID]/ux-strategy.md` Voice & Tone section

- Voice: [Extract from ux-strategy.md, e.g., "Friendly but not casual"]
- Tone adjustments: [How tone changes by context - align with ux-strategy.md]
- Terminology: [Specific terms to use/avoid - per ux-strategy.md content guidelines]

### Microcopy
- **Empty States**: "[Message when no data]"
- **Loading**: "[Loading message]"
- **Errors**: "[Error message pattern]"
- **Success**: "[Success message pattern]"

---

## ✅ Wireframe Checklist

Per Screen:
- [ ] All states designed (default, loading, empty, error)
- [ ] Mobile and desktop layouts complete
- [ ] Interactions documented
- [ ] Content requirements specified
- [ ] Accessibility considered

Overall:
- [ ] All journey touchpoints covered
- [ ] Design system properly applied
- [ ] Responsive behavior defined
- [ ] Navigation flow clear
- [ ] Ready for review

---

## 🚀 Next Steps

1. Review with stakeholders
2. Create interactive prototype (if needed)
3. Develop detailed UI specifications (`/story-ui-spec`)
4. Begin story breakdown for implementation
5. Plan usability testing
