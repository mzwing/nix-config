#!/usr/bin/env nix
#! nix shell --impure --expr ``(import <nixpkgs> { }).python3.withPackages (ps: [ ps.numpy ps.pillow ])`` --command python3
"""Lay images side by side on a checkerboard, optionally with true-size thumbnails, to judge a set as a whole; or blend them into one overlay to compare geometry."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw

PAD = 8
LABEL_HEIGHT = 18


def checkerboard(size: int, square: int = 16) -> Image.Image:
    board = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    draw = ImageDraw.Draw(board)
    for y in range(0, size, square):
        for x in range((y // square % 2) * square, size, square * 2):
            draw.rectangle((x, y, x + square - 1, y + square - 1), fill=(210, 210, 210, 255))
    return board


def fit(image: Image.Image, size: int) -> Image.Image:
    scale = min(size / image.width, size / image.height)
    resample = Image.Resampling.NEAREST if scale >= 1 else Image.Resampling.LANCZOS
    return image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), resample)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("images", nargs="+", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--cell", type=int, default=256, help="Each image is scaled to fit a square of this size.")
    parser.add_argument("--cols", type=int, help="Images per row; defaults to one row.")
    parser.add_argument("--thumb", type=int, help="Also show each image at this size, e.g. 32 for an icon legibility check.")
    parser.add_argument("--overlay", action="store_true", help="Blend all images, resized to the first one's size, into a single image instead.")
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)

    if args.overlay:
        first = Image.open(args.images[0]).convert("RGBA")
        blended = first
        for count, path in enumerate(args.images[1:], start=2):
            layer = Image.open(path).convert("RGBA").resize(first.size, Image.Resampling.LANCZOS)
            blended = Image.blend(blended, layer, 1 / count)
        background = checkerboard(max(first.size)).crop((0, 0, *first.size))
        background.alpha_composite(blended)
        background.save(args.output)
        print(args.output)
        return

    cols = args.cols or len(args.images)
    rows = -(-len(args.images) // cols)
    thumb_height = args.thumb + PAD if args.thumb else 0
    cell_width = args.cell + PAD * 2
    cell_height = args.cell + PAD * 2 + thumb_height + LABEL_HEIGHT
    sheet = Image.new("RGBA", (cols * cell_width, rows * cell_height), (255, 255, 255, 255))
    draw = ImageDraw.Draw(sheet)
    board = checkerboard(args.cell)

    for index, path in enumerate(args.images):
        image = Image.open(path).convert("RGBA")
        left = index % cols * cell_width + PAD
        top = index // cols * cell_height + PAD
        sheet.alpha_composite(board, (left, top))
        fitted = fit(image, args.cell)
        sheet.alpha_composite(fitted, (left + (args.cell - fitted.width) // 2, top + (args.cell - fitted.height) // 2))
        if args.thumb:
            small = fit(image, args.thumb)
            sheet.alpha_composite(small, (left + (args.cell - small.width) // 2, top + args.cell + PAD // 2))
        draw.text((left, top + args.cell + thumb_height), path.stem[:40], fill=(60, 60, 60, 255))

    sheet.save(args.output)
    print(args.output)


if __name__ == "__main__":
    main()
