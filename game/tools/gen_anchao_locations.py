# -*- coding: utf-8 -*-
"""Generate stylized 2D location backdrop placeholders for Anchao."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parents[1] / "art" / "locations" / "anchao"
W, H = 1280, 720

# loc_id -> (sky, mid, ground, accent, label)
LOCS = {
    "loc_01": ((48, 42, 38), (92, 68, 48), (56, 42, 32), (196, 150, 90), "商行前堂"),
    "loc_02": ((40, 46, 40), (70, 86, 58), (48, 54, 40), (150, 170, 110), "商行后院"),
    "loc_03": ((62, 58, 72), (120, 88, 58), (70, 52, 40), (220, 170, 90), "天津街市"),
    "loc_04": ((42, 48, 52), (78, 90, 88), (50, 56, 54), (160, 190, 180), "钱庄票号"),
    "loc_05": ((36, 44, 62), (70, 78, 102), (44, 48, 64), (140, 170, 210), "宝顺洋行"),
    "loc_06": ((34, 32, 36), (68, 58, 48), (42, 36, 32), (180, 140, 100), "货栈小屋"),
}


def _font(size: int) -> ImageFont.ImageFont:
    for path in (
        r"C:\Windows\Fonts\msyh.ttc",
        r"C:\Windows\Fonts\msyhbd.ttc",
        r"C:\Windows\Fonts\simhei.ttf",
        r"C:\Windows\Fonts\simsun.ttc",
    ):
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def _blend(a, b, t: float):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


def draw_loc(loc_id: str, sky, mid, ground, accent, label: str) -> None:
    img = Image.new("RGB", (W, H), sky)
    draw = ImageDraw.Draw(img)

    # sky gradient
    for y in range(0, int(H * 0.42)):
        t = y / (H * 0.42)
        col = _blend(sky, mid, t * 0.55)
        draw.line([(0, y), (W, y)], fill=col)

    # far buildings / silhouettes
    roof_y = int(H * 0.38)
    for i, x0 in enumerate(range(-40, W + 80, 110)):
        h = 90 + (i * 37) % 120
        w = 70 + (i * 23) % 50
        shade = _blend(mid, (20, 18, 16), 0.35 + (i % 3) * 0.08)
        draw.rectangle([x0, roof_y + 40 - h, x0 + w, roof_y + 80], fill=shade)
        # roof triangle-ish
        draw.polygon(
            [(x0 - 6, roof_y + 40 - h), (x0 + w // 2, roof_y + 10 - h), (x0 + w + 6, roof_y + 40 - h)],
            fill=_blend(shade, accent, 0.15),
        )

    # ground plane
    gy = int(H * 0.58)
    for y in range(gy, H):
        t = (y - gy) / max(1, H - gy)
        draw.line([(0, y), (W, y)], fill=_blend(mid, ground, 0.2 + t * 0.8))

    # venue mass (center building block)
    bx0, bx1 = int(W * 0.18), int(W * 0.82)
    by0, by1 = int(H * 0.28), int(H * 0.72)
    draw.rectangle([bx0, by0, bx1, by1], fill=_blend(mid, ground, 0.25))
    draw.rectangle([bx0, by0, bx1, by1], outline=accent, width=3)

    # columns / windows
    for i in range(5):
        x = bx0 + 40 + i * ((bx1 - bx0 - 80) // 4)
        draw.rectangle([x, by0 + 40, x + 18, by1 - 30], fill=_blend(ground, (10, 10, 10), 0.4))
        draw.rectangle([x + 28, by0 + 70, x + 70, by0 + 140], fill=_blend(sky, accent, 0.25))

    # lanterns / lights
    for lx in (bx0 + 60, bx1 - 80, int(W * 0.5) - 10):
        draw.ellipse([lx, by0 + 20, lx + 28, by0 + 48], fill=accent)
        draw.line([(lx + 14, by0), (lx + 14, by0 + 20)], fill=accent, width=2)

    # fog wash
    fog = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    for y in range(int(H * 0.55), H):
        a = int(30 + (y - H * 0.55) / (H * 0.45) * 50)
        fd.line([(0, y), (W, y)], fill=(210, 200, 180, a))
    img = Image.alpha_composite(img.convert("RGBA"), fog).convert("RGB")
    draw = ImageDraw.Draw(img)

    # title plate
    draw.rectangle([36, H - 92, 420, H - 36], fill=(18, 16, 14))
    draw.rectangle([36, H - 92, 420, H - 36], outline=accent, width=2)
    font = _font(36)
    draw.text((52, H - 82), label, font=font, fill=(236, 224, 196))
    tiny = _font(16)
    draw.text((52, H - 48), "暗潮 · 地点舞台", font=tiny, fill=(*accent, ))

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{loc_id}.png"
    img.save(path)
    print("wrote", path)


def main() -> None:
    for loc_id, args in LOCS.items():
        draw_loc(loc_id, *args)


if __name__ == "__main__":
    main()
