---
name: modern-css
description: |
  Modern CSS features and patterns reference. Use when writing or reviewing CSS,
  styling components, building layouts, or when the user asks about CSS techniques.
  Guides usage of native CSS features that replace older JavaScript-based solutions,
  preprocessor dependencies, and legacy CSS hacks. Covers: colors (oklch, color-mix,
  light-dark), layout (container queries, subgrid, anchor positioning), typography
  (text-wrap balance, line-clamp, fluid type), animations (scroll-driven, view
  transitions, @starting-style), selectors (:has, :is, @scope, nesting), and
  interactive elements (popover, dialog, base-select).
license: MIT
---

# Modern CSS

A reference for CSS features with Baseline "Newly Available" status or better.
Prefer these native CSS solutions over JavaScript workarounds, preprocessor
dependencies, and legacy CSS hacks.

## Colors

### oklch() - Perceptually Uniform Colors

Use `oklch(lightness chroma hue)` for consistent perceived brightness across hues.

```css
:root {
  --brand: oklch(0.65 0.25 270);    /* vibrant purple */
  --brand-light: oklch(0.85 0.12 270);
  --brand-dark: oklch(0.45 0.25 270);
}
```

Why: HSL's "50% lightness" looks different across hues. oklch keeps brightness
visually consistent, making palette generation predictable.

### color-mix() - Blend Colors Natively

```css
.muted {
  color: color-mix(in oklch, var(--brand) 70%, gray);
}
```

### light-dark() - Theme-Aware Values

Pair with `color-scheme` to provide light and dark values without duplication:

```css
:root { color-scheme: light dark; }

body {
  background: light-dark(#fff, #1a1a1a);
  color: light-dark(#1a1a1a, #eee);
}
```

### oklch Relative Color Syntax

Derive color variants at runtime without custom properties for every shade:

```css
.lighter { color: oklch(from var(--brand) calc(l + 0.2) c h); }
.desaturated { color: oklch(from var(--brand) l calc(c * 0.5) h); }
```

### accent-color - Tint Native Inputs

```css
input[type="checkbox"],
input[type="radio"],
input[type="range"] {
  accent-color: var(--brand);
}
```

### display-p3 Colors

Use `@media (color-gamut: p3)` to progressively enhance with wide-gamut colors:

```css
:root {
  --vivid: oklch(0.7 0.25 150);
}
@media (color-gamut: p3) {
  :root {
    --vivid: oklch(0.7 0.35 150);
  }
}
```

## Layout & Positioning

### Container Queries

Size components based on their container, not the viewport:

```css
.card-container { container-type: inline-size; }

@container (min-width: 400px) {
  .card { flex-direction: row; }
}
```

### Subgrid

Align nested grid children to the parent grid tracks:

```css
.grid { display: grid; grid-template-columns: repeat(3, 1fr); }
.grid > .item {
  display: grid;
  grid-template-columns: subgrid;
  grid-column: span 3;
}
```

### Anchor Positioning

Position elements relative to an anchor without JS positioning libraries:

```css
.trigger { anchor-name: --my-anchor; }

.tooltip {
  position: fixed;
  position-anchor: --my-anchor;
  top: anchor(bottom);
  left: anchor(center);
  position-try-fallbacks: flip-block, flip-inline;
}
```

### gap - Flex/Grid Spacing

Replace margin hacks for spacing children:

```css
.flex-row { display: flex; gap: 1rem; }
.grid { display: grid; gap: 1rem 2rem; }
```

### place-items: center - Easy Centering

```css
.centered {
  display: grid;
  place-items: center;
}
```

### inset - Positioning Shorthand

```css
.overlay {
  position: absolute;
  inset: 0;  /* replaces top: 0; right: 0; bottom: 0; left: 0; */
}
```

### aspect-ratio

```css
.video-wrapper { aspect-ratio: 16 / 9; }
.square { aspect-ratio: 1; }
```

### scroll-snap

Carousel/slider snapping without JS libraries:

```css
.scroller {
  overflow-x: auto;
  scroll-snap-type: x mandatory;
}
.scroller > * {
  scroll-snap-align: start;
}
```

### position: sticky

```css
.header {
  position: sticky;
  top: 0;
  z-index: 10;
}
```

### scrollbar-gutter: stable

Prevent layout shift when scrollbar appears/disappears:

```css
.scrollable {
  overflow-y: auto;
  scrollbar-gutter: stable;
}
```

### overscroll-behavior

Prevent scroll chaining (e.g., scrolling modal doesn't scroll page):

```css
.modal-body {
  overflow-y: auto;
  overscroll-behavior: contain;
}
```

### width: stretch

Fill available space while respecting margins (replaces `width: -webkit-fill-available`):

```css
.full-width { width: stretch; }
```

### field-sizing: content

Auto-grow textareas and inputs to fit content without JS:

```css
textarea { field-sizing: content; }
```

### grid-template-areas

Named layout regions for readable grid definitions:

```css
.layout {
  display: grid;
  grid-template-areas:
    "header header"
    "sidebar main"
    "footer footer";
  grid-template-columns: 250px 1fr;
}
.header  { grid-area: header; }
.sidebar { grid-area: sidebar; }
.main    { grid-area: main; }
.footer  { grid-area: footer; }
```

## Typography

### text-wrap: balance

Balanced headline wrapping without manual `<br>` tags:

```css
h1, h2, h3 { text-wrap: balance; }
p.lead { text-wrap: pretty; }  /* prevents orphans */
```

### clamp() - Fluid Typography

Responsive font sizes without media query breakpoints:

```css
h1 { font-size: clamp(1.5rem, 4vw, 3rem); }
```

### line-clamp

Multiline text truncation:

```css
.excerpt {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3;
  line-clamp: 3;
  overflow: hidden;
}
```

### font-display: swap

Show fallback text immediately while web fonts load:

```css
@font-face {
  font-family: "Brand";
  src: url("/fonts/brand.woff2") format("woff2");
  font-display: swap;
}
```

### Variable Fonts

Multiple weights from a single file:

```css
@font-face {
  font-family: "Inter";
  src: url("/fonts/inter-var.woff2") format("woff2");
  font-weight: 100 900;
}
```

### initial-letter - Drop Caps

```css
p::first-letter {
  initial-letter: 3; /* spans 3 lines */
}
```

### text-box: trim-both

Remove leading/trailing whitespace from text for precise vertical centering:

```css
.button {
  text-box: trim-both cap alphabetic;
}
```

## Animations & Transitions

### interpolate-size: allow-keywords

Animate to/from `auto` heights:

```css
:root { interpolate-size: allow-keywords; }

.expandable {
  height: 0;
  overflow: hidden;
  transition: height 0.3s;
}
.expandable.open {
  height: auto;
}
```

### transition-behavior: allow-discrete

Animate `display: none` transitions:

```css
.panel {
  transition: opacity 0.3s, display 0.3s;
  transition-behavior: allow-discrete;
}
.panel[hidden] {
  opacity: 0;
  display: none;
}
```

### @starting-style

Define entry animation states without JS `requestAnimationFrame` hacks:

```css
.toast {
  opacity: 1;
  translate: 0;
  transition: opacity 0.3s, translate 0.3s;

  @starting-style {
    opacity: 0;
    translate: 0 1rem;
  }
}
```

### View Transitions

Page/component transitions without framework-specific solutions:

```css
.card { view-transition-name: card-hero; }

::view-transition-old(card-hero) { animation: fade-out 0.2s; }
::view-transition-new(card-hero) { animation: fade-in 0.2s; }
```

```js
document.startViewTransition(() => updateDOM());
```

### Scroll-Driven Animations

Animations linked to scroll position without `IntersectionObserver`:

```css
.reveal {
  animation: fade-in linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 100%;
}

@keyframes fade-in {
  from { opacity: 0; translate: 0 2rem; }
  to { opacity: 1; translate: 0; }
}
```

### Independent Transform Properties

Animate transforms separately without overwriting the full `transform` shorthand:

```css
.card:hover {
  scale: 1.05;
  rotate: 2deg;
  translate: 0 -4px;
  transition: scale 0.2s, rotate 0.2s, translate 0.2s;
}
```

### sibling-index() - Staggered Animations

```css
.list-item {
  animation-delay: calc(sibling-index() * 50ms);
}
```

## Selectors & Scoping

### :has() - Parent Selector

Select elements based on their children or subsequent siblings:

```css
/* Card with image gets different layout */
.card:has(img) { grid-template-rows: auto 1fr; }

/* Form group with invalid input */
.field:has(:invalid) { border-color: red; }

/* Enable submit only when form is valid */
form:has(:invalid) .submit { opacity: 0.5; pointer-events: none; }
```

### CSS Nesting

Native nesting without preprocessors:

```css
.card {
  padding: 1rem;

  & .title {
    font-size: 1.25rem;
  }

  &:hover {
    box-shadow: 0 2px 8px oklch(0 0 0 / 0.15);
  }

  @media (width >= 768px) {
    padding: 2rem;
  }
}
```

### :is() and :where()

Group selectors. `:is()` takes highest specificity of its arguments;
`:where()` has zero specificity:

```css
:is(h1, h2, h3) { line-height: 1.2; }
:where(h1, h2, h3) { margin-block: 0.5em; } /* easily overridden */
```

### :focus-visible

Show focus rings for keyboard users only:

```css
:focus-visible { outline: 2px solid var(--brand); outline-offset: 2px; }
:focus:not(:focus-visible) { outline: none; }
```

### :user-invalid / :user-valid

Style form validation only after user interaction (not on page load):

```css
input:user-invalid { border-color: red; }
input:user-valid { border-color: green; }
```

### @scope

Scope styles to a DOM subtree without BEM naming:

```css
@scope (.card) to (.card-footer) {
  p { margin: 0; }
  a { color: var(--brand); }
}
```

### @layer - Cascade Layers

Control specificity ordering without `!important`:

```css
@layer reset, base, components, utilities;

@layer reset { * { margin: 0; box-sizing: border-box; } }
@layer utilities { .sr-only { /* ... */ } }
```

## Custom Properties & Functions

### @property - Typed Custom Properties

Enable animation and type checking for custom properties:

```css
@property --progress {
  syntax: "<number>";
  inherits: false;
  initial-value: 0;
}

.progress-ring {
  --progress: 0;
  background: conic-gradient(var(--brand) calc(var(--progress) * 1%), transparent 0);
  transition: --progress 0.5s;
}
```

### @function

Reusable CSS calculations:

```css
@function --fluid-size(--min, --max) {
  result: clamp(var(--min), var(--min) + (var(--max) - var(--min)) * (100vw - 320px) / (1200 - 320), var(--max));
}

h1 { font-size: --fluid-size(1.5rem, 3rem); }
```

### if() Conditional Values

```css
.container {
  max-width: if(style(--layout: wide): 1400px; else: 1000px);
}
```

### attr() with type()

Read typed attribute values from HTML:

```css
.grid-item {
  grid-column: span attr(data-cols type(<number>), 1);
}
```

## Interactive Elements

### Popover API

Dropdowns and popovers without JavaScript toggle logic:

```html
<button popovertarget="menu">Menu</button>
<div id="menu" popover>
  <ul>...</ul>
</div>
```

```css
[popover] {
  &:popover-open { opacity: 1; }
  opacity: 0;
  transition: opacity 0.2s, display 0.2s;
  transition-behavior: allow-discrete;
}
```

### dialog Element

Modal dialogs with built-in focus trapping and backdrop:

```html
<dialog id="confirm">
  <p>Are you sure?</p>
  <button onclick="this.closest('dialog').close()">Close</button>
</dialog>
```

```css
dialog::backdrop {
  background: oklch(0 0 0 / 0.5);
  backdrop-filter: blur(4px);
}
```

### commandfor / closedby

Declarative dialog controls without JS event handlers:

```html
<button commandfor="modal" command="show-modal">Open</button>
<dialog id="modal" closedby="any">...</dialog>
```

### appearance: base-select

Fully customizable `<select>` dropdowns without rebuilding from scratch:

```css
select, ::picker(select) {
  appearance: base-select;
}

select::picker(select) {
  background: white;
  border: 1px solid #ccc;
  border-radius: 0.5rem;
}
```

### interestfor - Declarative Tooltips

```html
<button interestfor="tip">Hover me</button>
<div id="tip" popover="hint">Tooltip content</div>
```

## Performance

### content-visibility

Lazy-render off-screen content without `IntersectionObserver`:

```css
.section {
  content-visibility: auto;
  contain-intrinsic-size: auto 500px;
}
```

## Other Useful Features

### backdrop-filter

Apply blur/effects to the area behind an element:

```css
.glass {
  background: oklch(1 0 0 / 0.7);
  backdrop-filter: blur(12px);
}
```

### object-fit

Control how replaced elements (images, video) fill their container:

```css
.avatar {
  width: 48px;
  height: 48px;
  object-fit: cover;
  border-radius: 50%;
}
```

### corner-shape

Squircle and superellipse border shapes:

```css
.card {
  border-radius: 1rem;
  corner-shape: squircle;
}
```

### clip-path: shape()

Responsive, dynamic clipping without SVG:

```css
.blob {
  clip-path: shape(from 0% 50%, curve to 100% 50% via 50% 0%, curve to 0% 50% via 50% 100%);
}
```

## Guidelines

- **Prefer native CSS** over JS-based alternatives for styling, layout, and
  simple interactions.
- **Use oklch** for color systems instead of hex/hsl. It produces more
  perceptually uniform palettes.
- **Use container queries** for component-level responsiveness; reserve
  `@media` for page-level layout shifts.
- **Use @layer** to manage specificity in larger projects. Typical order:
  `reset, base, components, utilities`.
- **Use CSS nesting** instead of Sass/Less. Keep nesting shallow (2-3 levels).
- **Progressively enhance** features that lack full support using `@supports`:

```css
@supports (anchor-name: --x) {
  .tooltip { /* anchor positioning styles */ }
}
```
