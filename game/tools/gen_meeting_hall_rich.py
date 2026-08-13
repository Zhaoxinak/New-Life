# -*- coding: utf-8 -*-
"""Richer procedural meeting hall (fallback if AI art unavailable)."""
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "art" / "meeting" / "hall_front.png"


def noise(img: Image.Image, amount: float = 0.04) -> Image.Image:
    rnd = random.Random(42)
    px = img.load()
    w, h = img.size
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            r, g, b = px[x, y]
            d = int((rnd.random() - 0.5) * 255 * amount)
            px[x, y] = (max(0, min(255, r + d)), max(0, min(255, g + d)), max(0, min(255, b + d)))
    return img


def main() -> None:
    w, h = 1280, 720
    img = Image.new("RGB", (w, h), (86, 58, 38))
    d = ImageDraw.Draw(img, "RGBA")

    # wall wash
    for y in range(h):
        t = y / h
        # warmer upper, cooler lower
        col = (
            int(128 - t * 36),
            int(90 - t * 28),
            int(56 - t * 18),
        )
        d.line([(0, y), (w, y)], fill=col)

    # ceiling beams
    d.rectangle([0, 0, w, 78], fill=(48, 30, 18))
    for x in range(0, w, 96):
        d.rectangle([x + 8, 8, x + 78, 70], fill=(62, 40, 24))
        d.rectangle([x + 14, 14, x + 72, 64], outline=(168, 128, 72), width=2)
        # lattice
        d.line([(x + 43, 14), (x + 43, 64)], fill=(150, 110, 60), width=1)
        d.line([(x + 14, 39), (x + 72, 39)], fill=(150, 110, 60), width=1)
        # window light
        d.rectangle([x + 20, 20, x + 66, 58], fill=(235, 205, 140, 55))

    # side columns with capital
    for x0 in (24, w - 64):
        d.rectangle([x0, 70, x0 + 40, h - 30], fill=(66, 42, 26))
        d.rectangle([x0 - 6, 70, x0 + 46, 92], fill=(92, 62, 36))
        for yy in range(100, h - 40, 28):
            d.line([(x0 + 6, yy), (x0 + 34, yy)], fill=(110, 78, 48), width=1)

    # floor
    floor_y = 340
    d.polygon([(40, floor_y), (w - 40, floor_y), (w - 10, h), (10, h)], fill=(102, 70, 42))
    for i in range(16):
        y0 = floor_y + i * ((h - floor_y) // 16)
        shade = 10 if i % 2 == 0 else -8
        d.rectangle(
            [50 + i, y0, w - 50 - i, y0 + ((h - floor_y) // 16) - 1],
            fill=(112 + shade, 78 + shade, 48 + shade),
        )

    # carpet with perspective
    cx = w // 2
    d.polygon(
        [(cx - 36, 170), (cx + 36, 170), (cx + 88, h - 40), (cx - 88, h - 40)],
        fill=(132, 42, 38, 180),
    )
    d.polygon(
        [(cx - 36, 170), (cx + 36, 170), (cx + 88, h - 40), (cx - 88, h - 40)],
        outline=(180, 100, 70, 160),
    )

    # master's dais
    d.rounded_rectangle([cx - 150, 118, cx + 150, 268], radius=8, fill=(74, 48, 30))
    d.rounded_rectangle([cx - 140, 128, cx + 140, 258], radius=6, outline=(186, 146, 78), width=3)
    # chair
    d.rectangle([cx - 48, 168, cx + 48, 248], fill=(52, 34, 22))
    d.rectangle([cx - 56, 160, cx + 56, 176], fill=(120, 84, 48))
    d.ellipse([cx - 70, 88, cx + 70, 150], fill=(255, 200, 110, 35))

    # lanterns
    for x in (280, 640, 1000):
        d.line([(x, 70), (x, 118)], fill=(70, 46, 28), width=3)
        d.ellipse([x - 34, 112, x + 34, 182], fill=(228, 164, 64))
        d.ellipse([x - 22, 122, x + 22, 168], fill=(255, 214, 120, 120))
        d.ellipse([x - 60, 140, x + 60, 260], fill=(255, 190, 90, 22))

    # mid table
    d.rounded_rectangle([200, 286, w - 200, 338], radius=4, fill=(70, 46, 28))
    d.rectangle([210, 278, w - 210, 292], fill=(148, 108, 60))
    # abacus hint
    d.rectangle([240, 296, 310, 324], fill=(90, 58, 34))
    for ax in range(248, 304, 8):
        d.line([(ax, 300), (ax, 320)], fill=(200, 170, 110), width=1)

    # side benches
    for x0, x1 in ((90, 190), (w - 190, w - 90)):
        d.rounded_rectangle([x0, 300, x1, 360], radius=4, fill=(78, 52, 32))

    img = noise(img, 0.05)
    img = ImageEnhance.Contrast(img).enhance(1.08)
    img = ImageEnhance.Color(img).enhance(1.05)

    # vignette
    vig = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vig)
    for i in range(40):
        a = int(3 + i * 1.2)
        vd.rectangle([i, i, w - 1 - i, h - 1 - i], outline=(30, 18, 10, a))
    vig = vig.filter(ImageFilter.GaussianBlur(8))
    img = Image.alpha_composite(img.convert("RGBA"), vig).convert("RGB")

    # plaque
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([36, h - 56, 250, h - 22], radius=8, fill=(46, 30, 18), outline=(190, 150, 80), width=2)
    d.text((52, h - 48), "钱记 · 前堂朝账", fill=(240, 220, 170))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print("wrote", OUT, img.size)


if __name__ == "__main__":
    main()
