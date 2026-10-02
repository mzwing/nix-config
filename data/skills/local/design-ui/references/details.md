# Details

## Typography

- `text-wrap: balance` on headings and other short text; `text-wrap: pretty` on short and medium paragraphs, captions, and list items. Leave long text and code alone, and never apply either to text that streams in word by word, since every update reflows earlier lines.
- On macOS, smooth fonts once at the root: `-webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale;` on `html`.
- `font-variant-numeric: tabular-nums` on numbers that change or line up (counters, timers, prices, table columns), not on static or decorative ones. Some fonts (Inter) redraw the `1`; check it.
- Keep the product's type system; don't bring in a new or paid typeface to polish something.
- Text that changes weight with state follows [weight without reflow](motion.md#weight-without-reflow).

## Radii

When a rounded surface sits close inside another, `inner = max(0, outer − gap − border)`: the gap is the space between them (usually the parent's padding), the border is the parent's border width. Never give parent and child the same radius. Past about 24px of gap, or with uneven gaps, treat them as separate surfaces and pick each radius by eye.

## Shadows and borders

Shadows for elevation (cards, buttons, popovers, dialogs); borders for structure (dividers, table cells, input outlines). A translucent shadow ring works on any background, a solid border only on the one it was picked for.

```css
:root {
  --shadow-border: 0 0 0 1px rgb(0 0 0 / 0.06), 0 1px 2px -1px rgb(0 0 0 / 0.06), 0 2px 4px 0 rgb(0 0 0 / 0.04);
  --shadow-border-hover: 0 0 0 1px rgb(0 0 0 / 0.08), 0 1px 2px -1px rgb(0 0 0 / 0.08), 0 2px 4px 0 rgb(0 0 0 / 0.06);
}
```

Layered shadows vanish on dark themes, so use a single white ring there: `0 0 0 1px rgb(255 255 255 / 0.08)`, and `0.13` on hover.

- Floating layers step up one level each, so a popup opened inside a dialog still reads as above it: a lighter surface on dark themes, a stronger shadow on light ones.
- Images get a 1px inset outline at 10% opacity, black on light and white on dark: `outline: 1px solid rgb(0 0 0 / 0.1); outline-offset: -1px;`.

## State fills

Two translucent tokens serve every hover and active fill, so they read correctly on any surface:

| Token | Light | Dark |
|---|---|---|
| `--hover` | `rgb(0 0 0 / 0.04)` | `rgb(255 255 255 / 0.06)` |
| `--active` | `rgb(0 0 0 / 0.07)` | `rgb(255 255 255 / 0.1)` |

## Optical alignment

- A button with an icon gets 2px less padding on the icon side than on the text side.
- Play triangles sit about 2px right of center; fix other lopsided glyphs in the SVG rather than with margins.

## Icons

- One icon set, the project's.
- Stroke matches the adjacent text on a 24px grid: 1.5px next to regular 14–16px text, 2px next to medium or semibold, 2.5px next to bold. One stroke weight per surface; inline icons are 1–1.25em.
- One SVG drawn with `currentColor`; CSS sets the hover, selected, and disabled colors. Strip hardcoded fills and strokes on import.
- Outline for the default state, filled for selected or active (the active tab, a saved bookmark); the change is an [icon swap](motion.md#icon-swaps).
- Hover or selection may thicken a stroke from 1.5px to 2px on the fast tier along with its color.
- Check each icon at the smallest size it renders (often 16px) and use the set's native sizes (16, 20, 24).
- In right-to-left layouts flip directional icons (back and forward, chevrons, send) and nothing else (logos, check marks, clocks, media controls).
- Icon-only controls get an accessible name; decorative icons are hidden from assistive technology.

## Hit areas

Visible controls may be 28px or 36px tall, but the hit area stays at least 40px, 44px on touch. Extend small controls with a pseudo-element, shrinking it where it would overlap a neighbour's hit area:

```css
.icon-button { position: relative; }
.icon-button::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  translate: -50% -50%;
  width: max(100%, 40px);
  height: max(100%, 40px);
}
```
