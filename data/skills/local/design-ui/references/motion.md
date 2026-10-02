# Motion

## Tokens

| Tier | Enter | Exit | Use for |
|---|---|---|---|
| fast | 80ms | 60ms | Hover, focus rings, fades, tooltips, checkboxes and radios, selection indicators, popups and menus |
| moderate | 160ms | 120ms | Short travel and small expansion: tab and segment indicators, switch thumbs, list selection; drawers and sheets that must land exactly |
| slow | 240ms | 160ms | Large surfaces: dialogs, side panels, stepped flows |

The bigger the thing that moves, the slower the tier. Never hand-write a duration or invent a fourth tier. A deliberate outlier, such as a one-off intro, gets one named token next to the code that owns it.

```css
:root {
  --motion-fast: 80ms;
  --motion-moderate: 160ms;
  --motion-slow: 240ms;
  --motion-fast-exit: 60ms;
  --motion-moderate-exit: 120ms;
  --motion-slow-exit: 160ms;
  --ease-enter: linear(0, 0.005 1.1%, 0.02 2.3%, 0.082 5.1%, 0.16 7.7%, 0.462 16.9%, 0.556 20.2%, 0.638 23.5%, 0.707 26.8%, 0.767 30.2%, 0.818 33.8%, 0.861 37.6%, 0.9 42.1%, 0.93 47%, 0.954 52.5%, 0.972 58.7%, 0.992 74.3%, 1);
  --ease-enter-slow: linear(0, 0.006 1.3%, 0.023 2.7%, 0.052 4.2%, 0.092 5.8%, 0.183 8.8%, 0.501 18.4%, 0.596 21.7%, 0.68 25%, 0.748 28.2%, 0.806 31.4%, 0.855 34.8%, 0.896 38.4%, 0.932 42.5%, 0.959 47%, 0.978 51.9%, 0.992 57.6%, 1.002 70.9%, 1);
  --ease-exit: ease-in-out;
}
```

The enter curves are the springs Motion produces for `{ type: "spring", duration, bounce }`, sampled into `linear()`. `--ease-enter` is critically damped (bounce 0) for the fast and moderate tiers; `--ease-enter-slow` is the slow tier's bounce 0.12, which lands a little sooner rather than visibly overshooting. Both settle exactly at the tier's duration, so CSS and a spring library move identically. Engines without `linear()` fall back to `cubic-bezier(0.23, 1, 0.32, 1)`.

If the project already uses Motion, pass the same values: `{ type: "spring", duration: 0.08, bounce: 0 }`, `{ type: "spring", duration: 0.16, bounce: 0 }`, and `{ type: "spring", duration: 0.24, bounce: 0.12 }` to enter, and `{ duration: 0.06 }`, `{ duration: 0.12 }`, `{ duration: 0.16 }` to exit. Tune other spring APIs to settle within the tier's duration without visible overshoot.

Color and background changes use the fast tier with plain `ease`.

## Enter and exit

Enter on the tier's duration and enter curve; exit on the tier's exit duration with `--ease-exit`, so a dismissal reads crisp and final instead of replaying the entrance backwards. A transition takes the timing of the state it is going to, so the enter timing goes on the shown state and the exit timing on the base:

```css
.popup {
  opacity: 0;
  scale: 1 0.96;
  translate: 0 -4px;
  transform-origin: top;
  transition: opacity var(--motion-fast-exit) var(--ease-exit), scale var(--motion-fast-exit) var(--ease-exit), translate var(--motion-fast-exit) var(--ease-exit);
}
.popup[data-open] {
  opacity: 1;
  scale: 1;
  translate: 0;
  transition-duration: var(--motion-fast);
  transition-timing-function: var(--ease-enter);
}
```

- Never enter from `scale(0)`. Popups and messages start at 0.96, dialogs at 0.97.
- Popups grow from their anchor: `transform-origin` on the side facing the trigger and a 4px slide toward it, following the side the popup actually landed on after collision flipping.
- Dialogs fade and scale from 0.97 on the slow tier (`--motion-slow` with `--ease-enter-slow`) and leave on the slow exit.
- Messages and toasts enter from opacity 0, 8px down, and scale 0.96 on the moderate tier, growing from the side they belong to.
- An element that starts from `display: none` needs a start state: `@starting-style`, or set the open attribute one frame after mounting.
- Keep an exiting element mounted until its transition ends (`transitionend`, backed by a timer at the exit duration plus 100ms, since background tabs can stall it).
- Don't animate things into their resting state on first render; animate later changes only.
- Stagger only infrequent entrances, such as a page header or a first-run list, at about 50ms per item. Never stagger routine, repeated interactions.
- Hover, typing, and keyboard navigation get fast-tier color, opacity, or the shared highlight, and no entrance choreography.

## What to animate

- `transform` (translate, scale, rotate) and `opacity`, plus `filter: blur()` on crossfades. Never `top`, `left`, `width`, `height`, `margin`, or `padding`: they relayout every frame and slip past reduced-motion handling. The one exception is the shared hover highlight's size, which only changes between items of different sizes.
- Name the properties; never `transition: all`. Tailwind's bare `transition` class is `all` at 150ms, outside this system.
- Interactive state uses transitions, which retarget from wherever they are when the user changes their mind. Keyframe animations are for one-shot sequences.
- `will-change` only on an element that visibly stutters on its first frame, and only for `transform`, `opacity`, or `filter`.

## One element, A to B

- A state change moves or morphs the same element (an indicator that slides, a highlight that travels, a popup that grows from its trigger) instead of fading one thing out and another in.
- One shared indicator per group: one hover highlight per list ([fluid-hover.md](fluid-hover.md)), one selected pill per tab strip, and one focus ring that travels between rows, shown only on `:focus-visible`.
- Tabs: the selected pill travels on the moderate tier. The hover pill starts at the selected pill, rides at 40% opacity on the fast tier, and travels back to the selected pill as it fades when the pointer leaves; the selected pill dims to 85% while another tab is hovered.
- Every motion has a cause: an action or a data change. Apart from progress indicators, nothing loops, wobbles, or breathes on its own.

## Icon swaps

Two glyphs stacked in one fixed-size cell crossfade, so the cell never resizes. The arriving glyph takes longer than the leaving one, so an appearance always outlasts a disappearance.

| Glyph | Opacity | Blur | Scale | Timing |
|---|---|---|---|---|
| Leaving | 1 → 0 | 0 → 4px | 1 → 0.6 | fast exit, `ease-in` |
| Arriving | 0 → 1 | 4px → 0 | 0.6 → 1 | fast, `ease-out` |

```css
.swap { display: inline-grid; }
.swap > * {
  grid-area: 1 / 1;
  transition: opacity var(--motion-fast-exit) ease-in, scale var(--motion-fast-exit) ease-in, filter var(--motion-fast-exit) ease-in;
}
.swap > [data-shown] {
  transition-duration: var(--motion-fast);
  transition-timing-function: ease-out;
}
.swap > :not([data-shown]) {
  opacity: 0;
  scale: 0.6;
  filter: blur(4px);
}
```

Keep the control's accessible name stable and announce the new state ("Copied") from a visually hidden `aria-live="polite"` element.

## Weight without reflow

Text that gets heavier when selected, open, or active reserves its heaviest width with an invisible copy, so its neighbours never move:

```html
<span class="weight"><span class="weight-label">Inbox</span><span class="weight-ghost" aria-hidden="true">Inbox</span></span>
```

```css
.weight { display: inline-grid; }
.weight > * { grid-area: 1 / 1; }
.weight-ghost { visibility: hidden; font-variation-settings: "wght" 550; }
.weight-label {
  font-variation-settings: "wght" 400;
  transition: font-variation-settings var(--motion-fast) ease, color var(--motion-fast) ease;
}
[aria-selected="true"] .weight-label { font-variation-settings: "wght" 550; }
```

- The pair is 400 at rest and 550 when active.
- Fonts with an optical-size axis (Inter) hold the width almost constant by raising `opsz` with the weight: `"wght" 400, "opsz" 14` → `"wght" 550, "opsz" 18`.
- A static font can't animate its weight; keep the ghost copy anyway so nothing shifts.

## Press feedback

Pressing shrinks the button's surface by exactly 1px per side while the label stays put. Don't scale buttons: on a wide button 2% is 8px sideways but under 1px vertically. The press is fast and the release slow; its 180ms is the one sanctioned off-tier duration.

```css
.button {
  --button-bg: var(--primary);
  position: relative;
  isolation: isolate;
}
.button::before {
  content: "";
  position: absolute;
  inset: 1px;
  z-index: -1;
  border-radius: inherit;
  background: var(--button-bg);
  box-shadow: 0 0 0 1px var(--button-bg);
  transition: box-shadow 180ms cubic-bezier(0.23, 1, 0.32, 1), background-color var(--motion-fast) ease;
}
.button:hover { --button-bg: color-mix(in oklab, var(--primary) 90%, var(--background)); }
.button:active { --button-bg: color-mix(in oklab, var(--primary) 80%, var(--background)); }
.button:active::before {
  box-shadow: 0 0 0 0 var(--button-bg);
  transition-duration: var(--motion-fast);
}
```

The button itself has no background; the pseudo-element is its surface. `--button-bg` is the variant's fill, and hover mixes in 10% of the page background, press 20%. Outline variants move their 1px ring inward on press the same way.

## Holding a state long enough to see it

- After a pick in a select or menu, stay open 300ms so the check mark and the selection can land, then close. Escape, outside clicks, and the trigger still close immediately.
- Tooltips open after 200ms of hover; once one is open, its neighbours open instantly for the next 300ms. They enter on the fast tier with a 4px slide toward the trigger and leave on the fast exit.
- Check marks draw themselves: the stroke grows over 80ms `ease-out` and retracts over 40ms `ease-in`, with `stroke-dasharray` taken from `getTotalLength()`.

## Height changes

- Animate collapses to a measured pixel height, never to `auto`.
- A wrapper animates only when it toggles itself. When its measured height changes because a child collapsed, it snaps; otherwise it chases a moving target, lags its child, and lands late, and each nesting level makes it worse.
- Fade content slightly ahead of the height, in over 60ms and out over 40ms, so it dissolves instead of being cut by the clip edge.

## Reduced motion

`prefers-reduced-motion: reduce` means fewer and gentler, not none: keep opacity and color fades, which help comprehension, and drop movement (translate, scale, rotate, size, layout).

```css
@media (prefers-reduced-motion: reduce) {
  .popup { translate: 0; scale: 1; transition-property: opacity; }
}
```

## Checking motion

Slow it down before judging it: the browser's animation inspector at 10%, or screenshots every few frames (CDP `Animation.setPlaybackRate` helps). Look for highlights that blink off between items, neighbours that shift, exits slower than enters, anything growing from scale 0, and anything still moving under reduced motion.
