# -*- coding: utf-8 -*-
"""Generate small top-down cottage props for harbor map overlays.

Replaces vignette crops that were cut from main buildings.
Door foot sits at bottom-center of each PNG (anchor for NpcCottage).
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "game" / "art" / "world" / "cottages"


def _shade(c: tuple[int, int, int], k: float) -> tuple[int, int, int]:
    return tuple(max(0, min(255, int(v * k))) for v in c)  # type: ignore[return-value]


def draw_cottage(
    w: int,
    h: int,
    *,
    wall: tuple[int, int, int],
    roof: tuple[int, int, int],
    accent: tuple[int, int, int] | None = None,
    style: str = "house",
) -> Image.Image:
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # Soft ground pad (matches map grass)
    d.ellipse([6, h - 28, w - 6, h - 4], fill=(70, 110, 45, 90))
    # Short porch path to door (south)
    path_x0, path_x1 = w // 2 - 7, w // 2 + 7
    d.rectangle([path_x0, h - 22, path_x1, h - 2], fill=(168, 145, 108, 230))
    for yy in range(h - 20, h - 2, 3):
        d.line([(path_x0 + 1, yy), (path_x1 - 1, yy)], fill=(140, 120, 88, 180), width=1)

    body = [10, 18, w - 10, h - 24]
    if style == "shed":
        body = [12, 28, w - 12, h - 24]
        d.rectangle(body, fill=wall, outline=_shade(wall, 0.55))
        # flat-ish roof
        d.polygon(
            [(8, 30), (w // 2, 12), (w - 8, 30)],
            fill=roof,
            outline=_shade(roof, 0.7),
        )
        # wide bay
        d.rectangle([w // 2 - 12, h - 48, w // 2 + 12, h - 26], fill=(40, 32, 24, 255))
    elif style == "stall":
        body = [14, 36, w - 14, h - 26]
        d.rectangle(body, fill=wall, outline=_shade(wall, 0.55))
        # awning
        aw = accent or (200, 70, 70)
        for i in range(0, w - 28, 8):
            col = aw if (i // 8) % 2 == 0 else (245, 240, 230)
            d.rectangle([14 + i, 22, min(w - 14, 22 + i), 38], fill=col)
        d.rectangle([w // 2 - 8, h - 44, w // 2 + 8, h - 26], fill=(50, 36, 28, 255))
    else:
        # house: walls + pitched roof
        d.rectangle(body, fill=wall, outline=_shade(wall, 0.55))
        d.polygon(
            [(6, 34), (w // 2, 6), (w - 6, 34)],
            fill=roof,
            outline=_shade(roof, 0.65),
        )
        # windows
        wx = accent or (255, 220, 120)
        d.rectangle([18, 44, 30, 56], fill=wx, outline=_shade(wx, 0.5))
        d.rectangle([w - 30, 44, w - 18, 56], fill=wx, outline=_shade(wx, 0.5))
        # door
        d.rectangle([w // 2 - 7, h - 50, w // 2 + 7, h - 26], fill=(55, 38, 28, 255))
        d.rectangle([w // 2 - 6, h - 48, w // 2 + 6, h - 28], fill=(70, 48, 34, 255))

    # tiny chimney / crate accent
    if style == "house":
        d.rectangle([w - 26, 16, w - 18, 34], fill=(90, 70, 55, 255))
    elif style == "shed":
        d.rectangle([w - 28, h - 40, w - 16, h - 28], fill=(90, 70, 50, 230))
    return im


DEFS = {
    "tea_waiter": dict(w=86, h=78, wall=(120, 88, 58), roof=(55, 70, 48), accent=(255, 210, 100), style="house"),
    "stall_aunt": dict(w=80, h=72, wall=(150, 110, 80), roof=(90, 60, 45), accent=(200, 70, 70), style="stall"),
    "garage_hand": dict(w=88, h=74, wall=(110, 115, 105), roof=(50, 90, 60), style="shed"),
    "dock_foreman": dict(w=90, h=76, wall=(95, 70, 48), roof=(60, 45, 35), accent=(255, 200, 90), style="shed"),
    "zhou_shaoting": dict(w=92, h=82, wall=(170, 150, 120), roof=(160, 70, 50), accent=(255, 230, 140), style="house"),
    "chen_manager": dict(w=88, h=80, wall=(70, 95, 85), roof=(50, 55, 60), accent=(255, 220, 130), style="house"),
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, conf in DEFS.items():
        w = int(conf.pop("w"))
        h = int(conf.pop("h"))
        im = draw_cottage(w, h, **conf)
        path = OUT / f"{name}.png"
        im.save(path)
        print("wrote", path, im.size)


if __name__ == "__main__":
    main()
