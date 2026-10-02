# Animation

Anything that moves: walk and run cycles, attacks, idles, FX, flags, fire. The image model draws poses, not motion, so the work is choosing phases that read as motion and proving that the loop closes. Generation and processing follow [sprites.md](sprites.md).

## Pipeline

1. Base frame: the subject in its neutral or starting pose, with full style words, the view the game uses, and solid `#FF00FF`. Accept it before animating anything.
2. Plan the phases. Capture the motion's distinct phases, and for a cycle select exactly one full period by its landmarks: foot contacts, wing extremes, flame peaks. Don't force a count: if the motion reads best in 8, 10, or 12 frames, use that many (more frames play smoother) in a multi-row grid that fits, such as `2x5` for 10.
3. Generate the grid as an edit of the base image, naming the phase in each cell, per [sprite-prompts.md](sprite-prompts.md); grounded high-value actions add an anchor sheet. If one phase keeps failing, generate it alone as an edit of the base and paste it into its cell of the raw sheet before processing.
4. Process into frames, a transparent sheet, and a GIF. Deliver frames in play order; the processor names them `idle-1` to `idle-16`, so zero-pad the names when there are more than nine, or ship the order from `pipeline-meta.json`. State the intended frame rate (`--duration` is milliseconds per frame).

## Motion laws

Check the frames against these whatever produced them:

- Cycles loop; alternating gaits spend half the period mirrored.
- Continuity: limbs, props, anatomy, and effects move on continuous paths. Nothing teleports, vanishes, or duplicates between adjacent frames.
- Physics reads in stills: airborne frames show air under the feet, anticipation compresses, follow-through overshoots, and effects stay anchored to their origin unless the request moves them.
- Energy matches the ask: an idle or subtle motion means barely different frames.

## The flip test

View the final frames strictly in order (the transparent sheet, or `scripts/contact_sheet.py` with the frames in play order) and narrate the motion frame by frame, then check loop closure explicitly from the last frame back to the first. A hedge in your narration is a failed frame: regenerate or replace that phase, then flip again.
