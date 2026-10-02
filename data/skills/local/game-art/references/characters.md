# Characters

Character identity across images: turnarounds (front, side, back), state and damage variants, palette swaps, equipment changes, and the same character in different contexts. The product is the identity, not any single image; apply all of this even when the request never mentions it.

## Asymmetry bookkeeping

Before prompting a turnaround, write the side map for every view. For "her left arm is sleeved":

| View | Sleeved arm appears on | Staff hand appears on |
|---|---|---|
| front | viewer's right | as designed |
| right profile | near side is her right, so bare | ... |
| back | viewer's left | mirrored from the front |

Prompt each view with viewer-relative words from the table, never body-relative ones, and verify each output against the table rather than the original sentence.

## Hands and props

- A held item is gripped: check the hand-object contact in every image. A staff floating beside an open hand fails.
- The item stays in the same hand across all views and frames, mirrored correctly in back views.

## Edit chain

- One accepted base image; every view, variant, and state is an edit of the base or of its nearest neighbor view (`imagegen.py edit --image <base>`): "Keep this exact character, with the same face, colors, proportions, outfit, scale, and background; change only <X>."
- Views are genuinely rotated: a side view is a strict profile, with nose, chest, and toes pointing at the frame edge, not three slightly turned fronts.
- Keep the style words in every edit prompt ("stylized 2D game art, cel shading", or whatever the set uses). Edits without them drift toward photorealism.

## Variants

- Put the freeze list first (pose, framing, background, everything that doesn't change), then the single change.
- Damage states are states, not action frames: worn, cracked, dented, with no debris flying mid-air.
- Verify base and variant together (`scripts/contact_sheet.py base.png variant.png`): background, framing, proportions, and every unrequested detail match. Escalating states (hurt, then critical) are strictly ordered when viewed as a set.

## Verify

For every image in the set, describe blind which side carries the marker detail, what each hand holds, and how the face and proportions compare to the base. One mismatch means a targeted retry of that image only.
