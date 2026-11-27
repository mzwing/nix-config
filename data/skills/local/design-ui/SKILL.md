---
name: design-ui
description: Design, build, and review user interfaces in any frontend stack (plain CSS, Tailwind, UnoCSS, Vue, Svelte, Solid, React, Dioxus). Covers tokens, layout, color, type, surfaces, icons, states, and motion, including hover, press, enter, and exit animations. Use when creating or restyling UI, adding interaction or animation, or polishing and reviewing existing UI.
---

# Design UI

Build in the project's own stack. Never add a second styling system, component kit, or animation library to apply these rules: everything here works in plain CSS plus a few lines of JS, and maps directly onto Tailwind, UnoCSS, or a framework's own transitions.

Which element or API builds a control and its browser fallbacks (`<dialog>`, `popover`, anchor positioning, `@starting-style`, view transitions, `interpolate-size`) belong to the `modern-web-guidance` skill; this skill decides how it looks and moves, and these tokens and timings apply to whatever primitive that skill picks.

## Start from what exists

- Editing an existing interface: match its visual language, tokens, and components. These rules govern new decisions; they are not a license to restyle what is there.
- Porting a design (an upstream library, a mockup, another app): copy its decisions as they are, including values that differ from this skill. Deviate only where the target can't execute them, and say where.
- A new interface with no direction: settle palette, type, radius, spacing, and motion as tokens before building screens. Take the palette from the product and its brand; don't default to dark greys or purple gradients.

## Tokens first

Define color, spacing, radius, type, and motion once, in whatever the project already uses (CSS custom properties, Tailwind `@theme`, UnoCSS theme, SCSS variables), then use only tokens. No raw hex, one-off pixel values, or ad-hoc durations in components; a value you need becomes a token or a step on an existing scale. Motion tokens are in [references/motion.md](references/motion.md#tokens).

## Rubric

- Color: neutrals, one primary, at most one accent; 3–5 colors in total. The accent marks primary actions and focus, not decoration.
- Contrast: body text meets WCAG AA. Whenever you set a background, set the text color too, and check light and dark themes.
- Type: at most two families and three text sizes per view, fine print aside. Body line-height 1.4–1.6, headings tighter; reading text stays within 60–75ch.
- Spacing: one 4/8-based scale.
- Size: controls are 36px tall, 28px when compact, shared by buttons, inputs, selects, tabs, and rows. Hit areas stay at least 40px, 44px on touch ([details](references/details.md#hit-areas)).
- Layout: design the 390px width first; no horizontal overflow; overlays respect `env(safe-area-inset-*)`.
- States: loading, empty, error, disabled, hover, focus-visible, and selected are designed, not left to defaults. Skeletons match the size of the content they stand in for.

## Avoid the generic look

- No gradient blobs or giant hero gradients standing in for content.
- No emoji as icons; use the project's icon set.
- No placeholder boxes or lorem ipsum in shipped UI.
- Charts that carry data come from a chart library, never hand-drawn SVG.
- One primary action per view.

## Motion

Motion explains a state change; it is never decoration. Three speeds, 80, 160, and 240ms, slower for bigger things, with exits one tier quicker (60, 120, 160ms); never a fourth speed.

Read [references/motion.md](references/motion.md) before adding or changing animations, and [references/fluid-hover.md](references/fluid-hover.md) for lists, menus, tabs, and grids with hover.

## Details

Typography, radii, shadows, state fills, icons, and hit areas are in [references/details.md](references/details.md). Read it before polishing or reviewing.

## Verify

Render the result and look at it at 1280px and 390px wide, in light and dark if both exist; reading the code is not verification. Check motion as described in [references/motion.md](references/motion.md#checking-motion).

## Reviewing

Report each finding as its location (`file:line`), what a person using the product sees, and one fix. Drop anything you can't point to in the code or the rendered page. "Nothing to change" is a valid result.

Adapted from Fluid Functionalism (MIT, Micka) and make-interfaces-feel-better (MIT, Jakub Krehel).
