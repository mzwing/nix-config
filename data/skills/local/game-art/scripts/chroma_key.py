#!/usr/bin/env nix
#! nix shell --impure --expr ``(import <nixpkgs> { }).python3.withPackages (ps: [ ps.numpy ps.pillow ])`` --command python3
"""Key a flat background color out of a generated image with a soft matte, and unmix the key color from the edge pixels it leaves."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


def parse_color(value: str) -> np.ndarray:
    value = value.lstrip("#")
    if len(value) != 6:
        raise argparse.ArgumentTypeError("expected a #rrggbb color")
    return np.array([int(value[i : i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


def key_out(image: Image.Image, key: np.ndarray, transparent: float, opaque: float, contract: int) -> Image.Image:
    rgba = np.asarray(image.convert("RGBA"), dtype=np.float32)
    rgb = rgba[..., :3].copy()
    distance = np.sqrt(((rgb - key) ** 2).sum(axis=-1))
    alpha = np.clip((distance - transparent) / (opaque - transparent), 0.0, 1.0) * rgba[..., 3] / 255.0
    edge = (alpha > 0) & (alpha < 1)
    weight = alpha[edge][:, None]
    rgb[edge] = np.clip((rgb[edge] - (1 - weight) * key) / weight, 0, 255)
    result = Image.fromarray(np.dstack([rgb, alpha * 255]).round().astype(np.uint8), "RGBA")
    if contract > 0:
        result.putalpha(result.getchannel("A").filter(ImageFilter.MinFilter(contract * 2 + 1)))
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--key-color", type=parse_color, default="#ff00ff")
    parser.add_argument("--transparent-threshold", type=float, default=35, help="Color distance below which a pixel is fully keyed.")
    parser.add_argument("--opaque-threshold", type=float, default=160, help="Color distance above which a pixel is fully kept.")
    parser.add_argument("--edge-contract", type=int, default=0, help="Shrink the matte by this many pixels to cut a remaining fringe.")
    args = parser.parse_args()
    if args.opaque_threshold <= args.transparent_threshold:
        raise SystemExit("--opaque-threshold must be greater than --transparent-threshold")

    result = key_out(Image.open(args.input), args.key_color, args.transparent_threshold, args.opaque_threshold, args.edge_contract)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    result.save(args.output)
    print(args.output)


if __name__ == "__main__":
    main()
