# -*- coding: utf-8 -*-
"""Cut painted player-home from harbor map → NPC cottage overlays (+ tinted interiors)."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
MAP = ROOT / "game" / "art" / "world" / "harbor_outdoor.png"
HOME_INT = ROOT / "game" / "art" / "locations" / "home.png"
COTTAGE_DIR = ROOT / "game" / "art" / "world" / "cottages"
LOC_DIR = ROOT / "game" / "art" / "locations"

NPCS = {
    "tea_waiter": ("nh_tea_waiter", (0.98, 1.03, 0.96), -10),
    "stall_aunt": ("nh_stall_aunt", (1.06, 0.96, 0.96), 14),
    "garage_hand": ("nh_garage_hand", (0.94, 0.98, 1.06), -20),
    "dock_foreman": ("nh_dock_foreman", (1.0, 0.94, 0.88), 24),
    "zhou_shaoting": ("nh_zhou_shaoting", (1.04, 0.98, 1.0), 6),
    "chen_manager": ("nh_chen_manager", (0.92, 1.02, 0.97), -26),
}

## Tight on house + fence + short porch (skip outer forest / boulevard).
HOME_BOX = (0.455, 0.055, 0.565, 0.232)


def _tint_rgb(im: Image.Image, mul: tuple[float, float, float]) -> Image.Image:
    r, g, b, a = im.split()
    r = r.point(lambda v: max(0, min(255, int(v * mul[0]))))
    g = g.point(lambda v: max(0, min(255, int(v * mul[1]))))
    b = b.point(lambda v: max(0, min(255, int(v * mul[2]))))
    return Image.merge("RGBA", (r, g, b, a))


def _shift_hue(im: Image.Image, degrees: float) -> Image.Image:
    if abs(degrees) < 1:
        return im.copy()
    hsv = im.convert("RGB").convert("HSV")
    h, s, v = hsv.split()
    rot = int(degrees * 255 / 360) % 256
    h = h.point(lambda x: (x + rot) % 256)
    out = Image.merge("HSV", (h, s, v)).convert("RGBA")
    out.putalpha(im.split()[-1])
    return out


def _keep_structure(r: int, g: int, b: int) -> bool:
    """True for roof / wall / fence / path / flowers / door / shutters."""
    # Red roof tiles
    if r > 120 and r > g + 25 and r > b + 30:
        return True
    # Cream / stone walls
    if r > 150 and g > 140 and b > 120 and abs(r - g) < 40 and abs(g - b) < 45:
        return True
    # White picket
    if r > 200 and g > 195 and b > 180 and abs(r - g) < 25:
        return True
    # Cobble / porch path
    if 120 < r < 210 and 100 < g < 190 and 70 < b < 160 and abs(r - g) < 45:
        return True
    # Brown door / wood
    if 40 < r < 120 and 25 < g < 90 and b < 70 and r >= g:
        return True
    # Dark green shutters (not bright forest)
    if 30 < g < 110 and g > r + 5 and g > b and r < 90 and b < 80 and (r + g + b) < 240:
        return True
    # Yellow / orange flowers
    if r > 180 and g > 120 and b < 100:
        return True
    # Chimney stone
    if 70 < r < 150 and 55 < g < 130 and 40 < b < 110 and abs(r - g) < 35:
        return True
    # Window glass dark
    if r < 80 and g < 90 and b < 100 and (r + g + b) < 200:
        return True
    return False


def _is_forest(r: int, g: int, b: int) -> bool:
    if g > r + 20 and g > b + 12 and g > 50:
        return True
    if g > 85 and r < 95 and b < 75:
        return True
    return False


def _is_blue_pole(r: int, g: int, b: int) -> bool:
    return b > 135 and b > r + 20 and g > 85 and r < 175


def extract_home_prop() -> Image.Image:
    src = Image.open(MAP).convert("RGBA")
    W, H = src.size
    x0, y0, x1, y1 = [int(v * s) for v, s in zip(HOME_BOX, (W, H, W, H))]
    crop = src.crop((x0, y0, x1, y1)).convert("RGBA")
    cw, ch = crop.size
    px = crop.load()

    ## Soft elliptical keep-mask centered on the house yard.
    cx, cy = cw * 0.50, ch * 0.48
    rx, ry = cw * 0.46, ch * 0.50

    out = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    opx = out.load()
    for y in range(ch):
        for x in range(cw):
            r, g, b, a = px[x, y]
            nx = (x - cx) / max(1.0, rx)
            ny = (y - cy) / max(1.0, ry)
            dist = math.sqrt(nx * nx + ny * ny)
            if dist > 1.05:
                continue
            if _is_blue_pole(r, g, b):
                continue
            if _is_forest(r, g, b) and not _keep_structure(r, g, b):
                continue
            ## Drop wide boulevard wings; keep center porch strip.
            if y > int(ch * 0.72) and abs(x - cw // 2) > 16:
                if not _keep_structure(r, g, b) or _is_forest(r, g, b):
                    continue
                if abs(x - cw // 2) > 18:
                    continue
            if not _keep_structure(r, g, b) and _is_forest(r, g, b):
                continue
            ## Grass inside yard: keep mild green near center, kill outer canopy.
            if _is_forest(r, g, b):
                if dist > 0.78:
                    continue
                ## Yard grass (lower saturation / mixed with brown)
                if g < 120 or r > 70:
                    pass
                else:
                    continue
            fade = 1.0
            if dist > 0.88:
                fade = max(0.0, 1.0 - (dist - 0.88) / 0.17)
            aa = int(255 * fade)
            if aa <= 0:
                continue
            opx[x, y] = (r, g, b, aa)

    ## Second pass: fill small holes inside the house mass.
    bbox = out.getbbox()
    if bbox is None:
        return out
    ## Trim + pad
    l, t, r0, b0 = bbox
    pad = 3
    l = max(0, l - pad)
    t = max(0, t - pad)
    r0 = min(cw, r0 + pad)
    b0 = min(ch, b0 + pad)
    out = out.crop((l, t, r0, b0))
    a = out.split()[-1].filter(ImageFilter.MaxFilter(3))
    a = a.filter(ImageFilter.GaussianBlur(0.45))
    rgb = out.convert("RGB")
    out = Image.merge("RGBA", (*rgb.split(), a))
    return out


def _interior_variant(base: Image.Image, hue: float, mul: tuple[float, float, float]) -> Image.Image:
    im = _shift_hue(base.convert("RGBA"), hue)
    im = _tint_rgb(im, mul)
    rgb = ImageEnhance.Color(im.convert("RGB")).enhance(1.06)
    rgb = ImageEnhance.Contrast(rgb).enhance(1.03)
    out = rgb.convert("RGBA")
    out.putalpha(255)
    return out


def main() -> None:
    COTTAGE_DIR.mkdir(parents=True, exist_ok=True)
    LOC_DIR.mkdir(parents=True, exist_ok=True)
    base = extract_home_prop()
    preview = ROOT / "tools" / "_home_prop_base.png"
    base.save(preview)
    print("base", base.size, "->", preview)

    home_int = Image.open(HOME_INT).convert("RGBA")
    for npc_id, (loc_id, mul, hue) in NPCS.items():
        outdoor = _tint_rgb(base, mul)
        d = ImageDraw.Draw(outdoor)
        accent = {
            "tea_waiter": (70, 150, 85, 230),
            "stall_aunt": (210, 80, 80, 230),
            "garage_hand": (85, 95, 115, 230),
            "dock_foreman": (150, 110, 65, 230),
            "zhou_shaoting": (210, 170, 55, 230),
            "chen_manager": (55, 115, 95, 230),
        }[npc_id]
        aw, ah = outdoor.size
        ## Small flower accent inside fence so each annex reads distinct.
        d.ellipse([12, int(ah * 0.62), 22, int(ah * 0.62) + 10], fill=accent)

        op = COTTAGE_DIR / f"{npc_id}.png"
        outdoor.save(op)
        print("cottage", op.name, outdoor.size)

        interior = _interior_variant(home_int, hue, mul)
        ip = LOC_DIR / f"{loc_id}.png"
        interior.save(ip)
        print("interior", ip.name)


if __name__ == "__main__":
    main()
