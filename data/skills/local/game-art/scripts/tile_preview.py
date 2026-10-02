#!/usr/bin/env nix
#! nix shell --impure --expr ``(import <nixpkgs> { }).python3.withPackages (ps: [ ps.numpy ps.pillow ])`` --command python3
"""Repeat a tile into a grid so seams, repeated motifs, and tone drift show, or shift it by half so its seams meet in the middle for repainting."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--repeat", type=int, default=2, help="Tiles per side of the preview grid.")
    parser.add_argument("--offset", action="store_true", help="Write the tile shifted by half its size instead of a grid.")
    parser.add_argument("--mask", type=Path, help="With --offset, also write an edit mask that is transparent along the seam cross.")
    parser.add_argument("--band", type=int, default=48, help="Width in pixels of the mask's transparent seam band.")
    args = parser.parse_args()

    tile = Image.open(args.input)
    width, height = tile.size
    args.output.parent.mkdir(parents=True, exist_ok=True)

    if args.offset:
        ImageChops.offset(tile, width // 2, height // 2).save(args.output)
        if args.mask:
            mask = Image.new("RGBA", (width, height), (0, 0, 0, 255))
            draw = ImageDraw.Draw(mask)
            half = args.band // 2
            draw.rectangle((width // 2 - half, 0, width // 2 + half, height), fill=(0, 0, 0, 0))
            draw.rectangle((0, height // 2 - half, width, height // 2 + half), fill=(0, 0, 0, 0))
            args.mask.parent.mkdir(parents=True, exist_ok=True)
            mask.save(args.mask)
            print(args.mask)
    else:
        grid = Image.new(tile.mode, (width * args.repeat, height * args.repeat))
        for row in range(args.repeat):
            for col in range(args.repeat):
                grid.paste(tile, (col * width, row * height))
        grid.save(args.output)
    print(args.output)


if __name__ == "__main__":
    main()
