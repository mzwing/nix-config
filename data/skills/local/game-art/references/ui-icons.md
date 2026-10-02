# UI and icons

Buttons with interaction states, panels, bars, wordmark logos, and icon sets. UI is a system: the set matters more than any piece. Apply all of this even when the request never mentions it.

## Interaction states

- Generate the normal state first. Hover and pressed are edits of it with an explicit freeze list: "same shape, same size, same ornament, same frame thickness, same background; change only <the state treatment>".
- Standard treatments: hover gets a subtle outer glow or a slight brighten; pressed gets darker with an inset or inner shadow.
- States must be distinguishable at a glance and identical in geometry. Key every state with `scripts/chroma_key.py` so they share one canvas, then blend them with `scripts/contact_sheet.py --overlay`: the outlines, frame thickness included, must coincide.

## Icon sets

- Decide one style contract for the whole set before generating: the same stroke weight, the same fill treatment (all outlined or all solid, never mixed), the same palette family, padding, background, and visual weight.
- Generate icon 1, then edit-chain the rest from it so they inherit the contract.
- Verify the set side by side with `scripts/contact_sheet.py <icons...> --thumb 32`. One icon with a different treatment, such as sitting in a filled tile while the others float, fails the set even if it is fine alone. Every icon must read at 32px: squint at the thumbnails.

## Panels, bars, wordmarks

- Panels and dialogs are blank and text-ready, with borders that survive 9-slicing: uniform edges, ornament concentrated in the corners.
- Bars separate the frame clearly from the fill, and the fill design works at any percentage.
- Wordmark logos get garbled by image models: generate, then read the text back letter by letter; any wrong, merged, or extra letter means a retry. Deliver the logo isolated on a flat keyable background, not as a full scene, unless a title screen was requested.

## No text anywhere else

Buttons, panels, and icons carry no lettering unless explicitly requested: models garble it, and games localize it.
