# visual-quality / universal-design-quality-principles

## Universal Design Quality Principles

Apply these in EVERY UI implementation, adapted to the project's design system:

### 1. Typography as Hero
- Typography is a primary design element, not just functional text
- Create clear visual hierarchy: display → heading → subheading → body → caption
- Use size, weight, letter-spacing, and line-height contrasts deliberately
- Headlines should have PRESENCE — not just be bigger body text
- Consider: tracking (letter-spacing), case transforms, font pairing tension

### 2. Deliberate Negative Space
- Whitespace is an active design element, not emptiness
- Generous padding creates perceived quality and luxury
- Group related items tightly; separate unrelated items generously
- Let content breathe — cramped layouts feel cheap
- Use asymmetric spacing for visual interest where appropriate

### 3. Consistent Motion Philosophy
- Every animation must follow the project's motion philosophy
- "Minimal and instant" means NO gratuitous transitions
- "Fluid and delightful" means purposeful easing and choreography
- Never add random animations — motion must serve communication
- Respect `prefers-reduced-motion` always

### 4. Texture and Depth
- Flat, solid-color backgrounds feel generic and lifeless
- Consider: subtle gradients, noise textures, background patterns, grain overlays
- Use layered shadows (not a single box-shadow) for realistic depth
- Borders can be replaced with shadow/contrast for more sophistication
- Dark modes benefit especially from subtle texture to avoid "dead screen"

### 5. State-Specific Styling
- Default state is just the starting point — hover, focus, active, disabled ALL need design
- Hover states should feel intentional: scale, color shift, shadow lift, border change
- Focus states must be visually distinct AND accessible (not just browser default)
- Active/pressed states should provide tactile feedback (scale down, darken, etc.)
- Loading states need skeleton screens or shimmer — never blank space
- Error states should be designed, not just red text

### 6. Color with Purpose
- Use color for hierarchy and drama, not just decoration
- Consider color inversion patterns for emphasis (dark section amid light, or vice versa)
- Accent colors should POP — used sparingly for maximum impact
- Avoid "all one temperature" — use warm/cool contrast deliberately
- Background color variations create natural section separation

### 7. Component Personality
- Buttons should have CHARACTER: weight, presence, satisfying interaction
- Cards should feel like real objects: weight, shadow, surface texture
- Inputs should feel inviting: generous padding, clear focus states, smooth transitions
- Empty states are design opportunities, not afterthoughts
- Every component should feel like it belongs to THIS product, not any product
