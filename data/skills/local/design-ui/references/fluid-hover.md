# Fluid hover

One highlight per list that glides to the item nearest the cursor. Plain `:hover` lights nothing while the cursor crosses the gaps between rows, so a pass down a menu blinks it off and on, and every blink pulls the eye back. The fluid highlight never goes dark while the cursor is inside the list, and what it lights is what a click hits.

## Rules

- A containing item wins; otherwise the item whose center is nearest the cursor, measured along y for lists, x for strips, and straight-line distance for grids. The cursor in a gap, in the container's padding, or past the last item still lights something.
- One highlight element per list, absolutely positioned inside the container and moved with `transform` on the fast tier. Its width and height change only between items of different sizes.
- Entering the list, the highlight fades in at the nearest item rather than sliding over from where it was last. A list with a current item (a menu's checked row, the selected tab) may start it there and let it travel to the target. Leaving, it fades out on the fast exit.
- A click in a gap goes to the lit item. Grids limit this to gaps within 16px of the item.
- Disabled items stay in the list but are skipped. Only click targets join; lighting something that does nothing promises a click with nowhere to land.
- One list per group of alternatives: a divider between different kinds of rows starts a new list with its own highlight, while a parent and its children are one list.
- Items drop their own `:hover` background; the highlight is the hover treatment. Text on the lit item may still change color.
- Mouse only; touch has no hover.
- Keyboard focus keeps its own ring on the item and may also light it.
- A reflow that moves the lit item snaps the highlight instead of animating it.
- Under reduced motion the highlight still fades in at the nearest item; it just stops traveling.

Use it when everything in the group is clickable, the items sit close together, and they stay put while you look at them: menus, lists, tabs, tables, link grids. Skip it when a wrong click would hurt, when only some cards are clickable, when there is a lot of empty space between items, or when rows reorder under the cursor.

## Implementation

[`assets/fluid-hover.js`](../assets/fluid-hover.js) implements every rule above without dependencies. Copy it into the project (as TypeScript if the project uses it) and call it once the list is mounted: Vue `onMounted`, a Svelte action, Solid `onMount`, or a plain script after the DOM exists. Call `destroy()` when the list unmounts. Render the highlight element yourself so the framework owns every node. Renderers without a DOM port the rules, not the file.

```js
const hover = fluidHover(container, highlight, { axis: "y" });
```

| Option | Default | Meaning |
|---|---|---|
| `axis` | `"y"` | `"y"` for lists, `"x"` for strips, `"xy"` for grids |
| `items` | `"[data-fluid-item]"` | Selector for the click targets inside the container |
| `gapClick` | `true` | `false` turns gap clicks off; a number limits them to that many px from the item (16 for grids) |
| `from` | none | Function returning the item a fresh entry starts from, such as the selected tab |

It sets `data-lit` on the lit item and `data-visible` on the highlight (plus `data-instant` for the frame it jumps without animating), re-measures by itself on resize and DOM changes, and skips items marked `aria-disabled="true"`, `data-disabled`, or `disabled`. `hover.light(item)` lights an item from code, for keyboard focus; `hover.light(null)` clears it.

```html
<div class="fluid-list">
  <div class="fluid-highlight" aria-hidden="true"></div>
  <ul>
    <li data-fluid-item><a href="/inbox">Inbox</a></li>
    <li data-fluid-item><a href="/drafts">Drafts</a></li>
  </ul>
</div>
```

```css
.fluid-list { position: relative; }
.fluid-list [data-fluid-item] { position: relative; }
.fluid-highlight {
  position: absolute;
  top: 0;
  left: 0;
  border-radius: 8px;
  background: var(--hover);
  opacity: 0;
  pointer-events: none;
  transition: transform var(--motion-fast) var(--ease-enter), width var(--motion-fast) var(--ease-enter), height var(--motion-fast) var(--ease-enter), opacity var(--motion-fast-exit) var(--ease-exit);
}
.fluid-highlight[data-visible] {
  opacity: 1;
  transition-duration: var(--motion-fast);
}
.fluid-highlight[data-instant] {
  transition: none;
}
@media (prefers-reduced-motion: reduce) {
  .fluid-highlight { transition: opacity var(--motion-fast-exit) var(--ease-exit); }
}
```

The container must be `position: relative`, since it is the coordinate space. Items paint above the highlight because they are positioned and come after it.
