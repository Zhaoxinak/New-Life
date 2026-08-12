# -*- coding: utf-8 -*-
"""Generate Kairosoft-like facility floors + chibi sprites for Anchao."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
LOC_OUT = ROOT / "art" / "locations" / "anchao"
SPRITE_OUT = ROOT / "art" / "sprites" / "anchao"
W, H = 1280, 720

# Pastel Kairosoft-ish palettes per location
LOCS = {
    "loc_01": {  # 前堂
        "wall": (232, 214, 186),
        "floor": (198, 168, 128),
        "accent": (210, 96, 72),
        "trim": (120, 78, 48),
        "label": "钱记·前堂",
        "props": "hall",
    },
    "loc_02": {
        "wall": (186, 210, 168),
        "floor": (156, 178, 132),
        "accent": (92, 140, 78),
        "trim": (64, 96, 54),
        "label": "钱记·后院",
        "props": "yard",
    },
    "loc_03": {
        "wall": (255, 228, 176),
        "floor": (222, 186, 120),
        "accent": (236, 140, 64),
        "trim": (140, 90, 40),
        "label": "天津街市",
        "props": "market",
    },
    "loc_04": {
        "wall": (210, 222, 230),
        "floor": (176, 192, 204),
        "accent": (72, 128, 148),
        "trim": (48, 80, 96),
        "label": "钱庄票号",
        "props": "bank",
    },
    "loc_05": {
        "wall": (198, 210, 236),
        "floor": (164, 178, 210),
        "accent": (72, 96, 168),
        "trim": (40, 56, 110),
        "label": "宝顺洋行",
        "props": "foreign",
    },
    "loc_06": {
        "wall": (236, 214, 198),
        "floor": (186, 156, 128),
        "accent": (168, 110, 78),
        "trim": (96, 64, 44),
        "label": "货栈小屋",
        "props": "cottage",
    },
}

CAST = {
    "char_lin_ruisheng": ((90, 140, 170), "林"),
    "char_qian_demao": ((190, 100, 70), "茂"),
    "char_qian_zian": ((160, 90, 150), "安"),
    "char_liu_ruyan": ((190, 130, 170), "烟"),
    "char_bradley": ((80, 110, 170), "白"),
    "char_zhao_hongyun": ((190, 150, 70), "赵"),
    "char_wang_pangzi": ((180, 130, 90), "王"),
    "char_zhou_guanshi": ((140, 130, 110), "周"),
    "char_qing_daren": ((150, 70, 80), "庆"),
    "char_msg_broker": ((160, 130, 90), "讯"),
    "char_bank_clerk": ((100, 140, 130), "柜"),
    "char_firm_hand": ((150, 120, 90), "伙"),
    "narrator": ((130, 120, 110), "旁"),
}


def _font(size: int) -> ImageFont.ImageFont:
    for path in (
        r"C:\Windows\Fonts\msyh.ttc",
        r"C:\Windows\Fonts\simhei.ttf",
        r"C:\Windows\Fonts\simsun.ttc",
    ):
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def _darken(c, t=0.25):
    return tuple(max(0, int(v * (1 - t))) for v in c)


def _lighten(c, t=0.2):
    return tuple(min(255, int(v + (255 - v) * t)) for v in c)


def draw_room(loc_id: str, cfg: dict) -> None:
    img = Image.new("RGB", (W, H), (168, 196, 220))  # soft sky
    draw = ImageDraw.Draw(img)

    # sky band
    for y in range(0, 160):
        t = y / 160
        col = (
            int(168 + 40 * t),
            int(196 + 20 * t),
            int(220 - 10 * t),
        )
        draw.line([(0, y), (W, y)], fill=col)

    # outer wall frame (facility box) — Kairosoft shop feel
    mx, my = 90, 110
    mw, mh = W - 180, H - 220
    wall = cfg["wall"]
    floor = cfg["floor"]
    trim = cfg["trim"]
    accent = cfg["accent"]

    # shadow
    draw.rounded_rectangle([mx + 10, my + 14, mx + mw + 10, my + mh + 14], radius=28, fill=(60, 70, 80))
    # wall
    draw.rounded_rectangle([mx, my, mx + mw, my + mh], radius=28, fill=wall)
    # floor inset
    fx0, fy0 = mx + 36, my + 70
    fx1, fy1 = mx + mw - 36, my + mh - 36
    draw.rounded_rectangle([fx0, fy0, fx1, fy1], radius=18, fill=floor)
    # floor tiles
    tile = 48
    for x in range(fx0, fx1, tile):
        draw.line([(x, fy0), (x, fy1)], fill=_darken(floor, 0.08), width=1)
    for y in range(fy0, fy1, tile):
        draw.line([(fx0, y), (fx1, y)], fill=_darken(floor, 0.08), width=1)

    # back wall strip
    draw.rectangle([fx0, fy0, fx1, fy0 + 54], fill=_lighten(wall, 0.08))
    draw.rectangle([fx0, fy0 + 54, fx1, fy0 + 58], fill=trim)

    # windows
    for i in range(3):
        wx = fx0 + 80 + i * 280
        draw.rounded_rectangle([wx, fy0 + 10, wx + 90, fy0 + 46], radius=6, fill=(180, 220, 240))
        draw.rectangle([wx + 44, fy0 + 10, wx + 46, fy0 + 46], fill=trim)

    _draw_props(draw, cfg["props"], fx0, fy0, fx1, fy1, accent, trim)

    # title plaque
    draw.rounded_rectangle([mx + 24, my + 16, mx + 320, my + 58], radius=12, fill=accent)
    draw.rounded_rectangle([mx + 28, my + 20, mx + 316, my + 54], radius=10, fill=_lighten(accent, 0.25))
    font = _font(28)
    draw.text((mx + 48, my + 24), cfg["label"], font=font, fill=(40, 30, 24))

    # coin / sparkle decorations
    for cx, cy in ((mx + mw - 50, my + 40), (mx + mw - 90, my + 55)):
        draw.ellipse([cx, cy, cx + 18, cy + 18], fill=(255, 210, 70), outline=(200, 150, 30), width=2)

    LOC_OUT.mkdir(parents=True, exist_ok=True)
    path = LOC_OUT / f"{loc_id}.png"
    img.save(path)
    print("wrote", path.relative_to(ROOT))


def _draw_props(draw, kind, fx0, fy0, fx1, fy1, accent, trim):
    mid_x = (fx0 + fx1) // 2
    mid_y = (fy0 + fy1) // 2 + 30
    if kind == "hall":
        # counter
        draw.rounded_rectangle([mid_x - 160, mid_y, mid_x + 160, mid_y + 70], radius=10, fill=_lighten(trim, 0.35))
        draw.rounded_rectangle([mid_x - 150, mid_y + 8, mid_x + 150, mid_y + 28], radius=6, fill=(240, 220, 180))
        # chairs
        for dx in (-220, 220):
            draw.rounded_rectangle([mid_x + dx - 28, mid_y + 20, mid_x + dx + 28, mid_y + 70], radius=8, fill=accent)
        # door
        draw.rounded_rectangle([fx1 - 110, fy0 + 70, fx1 - 40, fy1 - 20], radius=8, fill=_darken(trim, 0.1))
        draw.ellipse([fx1 - 70, mid_y, fx1 - 58, mid_y + 12], fill=(255, 220, 100))
    elif kind == "yard":
        # crates
        for i, (ox, oy) in enumerate(((-180, 40), (-40, 80), (120, 30), (220, 90))):
            x, y = mid_x + ox, mid_y + oy - 40
            draw.rectangle([x, y, x + 70, y + 50], fill=_lighten(trim, 0.2), outline=trim, width=2)
            draw.line([(x, y + 25), (x + 70, y + 25)], fill=trim, width=2)
        # barrel
        draw.ellipse([mid_x - 30, mid_y + 60, mid_x + 40, mid_y + 110], fill=accent, outline=trim, width=2)
    elif kind == "market":
        for i, ox in enumerate((-260, -80, 100, 260)):
            x = mid_x + ox
            draw.polygon([(x - 50, mid_y), (x, mid_y - 40), (x + 50, mid_y)], fill=accent)
            draw.rectangle([x - 45, mid_y, x + 45, mid_y + 55], fill=_lighten(trim, 0.4), outline=trim, width=2)
    elif kind == "bank":
        draw.rounded_rectangle([mid_x - 200, mid_y - 10, mid_x + 200, mid_y + 80], radius=12, fill=_lighten(trim, 0.45))
        for i in range(4):
            x = mid_x - 150 + i * 100
            draw.rectangle([x, mid_y + 5, x + 60, mid_y + 50], fill=(240, 248, 255), outline=trim, width=2)
        # abacus hint
        draw.rectangle([mid_x - 40, mid_y - 50, mid_x + 40, mid_y - 20], fill=accent, outline=trim, width=2)
    elif kind == "foreign":
        draw.rounded_rectangle([mid_x - 180, mid_y - 20, mid_x + 180, mid_y + 90], radius=14, fill=(230, 236, 250))
        draw.ellipse([mid_x - 40, mid_y + 10, mid_x + 40, mid_y + 55], fill=(200, 180, 120))
        draw.rectangle([fx0 + 40, fy0 + 80, fx0 + 120, fy1 - 40], fill=_lighten(accent, 0.35), outline=trim, width=2)
    else:  # cottage
        draw.rounded_rectangle([mid_x - 120, mid_y - 30, mid_x + 120, mid_y + 50], radius=10, fill=_lighten(trim, 0.3))
        draw.rectangle([mid_x - 90, mid_y - 70, mid_x - 20, mid_y - 30], fill=(120, 90, 70))
        draw.rectangle([mid_x + 30, mid_y - 60, mid_x + 100, mid_y - 30], fill=(90, 130, 150))
        draw.ellipse([mid_x + 150, mid_y + 40, mid_x + 210, mid_y + 100], fill=accent)


def draw_chibi(char_id: str, color, glyph: str) -> None:
    w, h = 64, 80
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # shadow
    d.ellipse([14, 68, 50, 78], fill=(0, 0, 0, 60))
    # body
    d.rounded_rectangle([18, 38, 46, 68], radius=8, fill=color)
    # head
    d.ellipse([12, 8, 52, 48], fill=_lighten(color, 0.35), outline=_darken(color, 0.2), width=2)
    # eyes
    d.ellipse([22, 24, 28, 30], fill=(40, 30, 30))
    d.ellipse([36, 24, 42, 30], fill=(40, 30, 30))
    # blush
    d.ellipse([16, 32, 24, 38], fill=(255, 160, 160, 120))
    d.ellipse([40, 32, 48, 38], fill=(255, 160, 160, 120))
    # feet
    d.ellipse([18, 64, 30, 72], fill=_darken(color, 0.3))
    d.ellipse([34, 64, 46, 72], fill=_darken(color, 0.3))
    # glyph badge
    font = _font(14)
    d.rounded_rectangle([40, 0, 62, 18], radius=4, fill=(255, 250, 230), outline=_darken(color, 0.2), width=1)
    d.text((44, 1), glyph, font=font, fill=(50, 40, 30))
    SPRITE_OUT.mkdir(parents=True, exist_ok=True)
    path = SPRITE_OUT / f"{char_id}.png"
    img.save(path)
    print("wrote", path.relative_to(ROOT))


def main() -> None:
    for loc_id, cfg in LOCS.items():
        draw_room(loc_id, cfg)
    for cid, (col, glyph) in CAST.items():
        draw_chibi(cid, col, glyph)


if __name__ == "__main__":
    main()
