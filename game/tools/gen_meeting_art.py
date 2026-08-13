# -*- coding: utf-8 -*-
"""Generate warm meeting-hall backdrop + circular bust crops for MeetingStage."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "art" / "meeting"
BUST_DIR = OUT / "busts"
PORTRAIT_DIR = ROOT / "art" / "portraits" / "anchao"


def make_hall() -> Path:
    OUT.mkdir(parents=True, exist_ok=True)
    w, h = 1280, 720
    img = Image.new("RGB", (w, h), (92, 64, 42))
    d = ImageDraw.Draw(img, "RGBA")

    for y in range(h):
        t = y / h
        d.line(
            [(0, y), (w, y)],
            fill=(int(118 - t * 28), int(82 - t * 22), int(52 - t * 16)),
        )

    d.rectangle([0, 0, w, 90], fill=(58, 38, 24, 255))
    for x in range(40, w, 70):
        d.rectangle([x, 18, x + 42, 72], outline=(180, 140, 80, 220), width=2)
        d.line([(x + 21, 18), (x + 21, 72)], fill=(160, 120, 70, 180), width=1)
        d.line([(x, 45), (x + 42, 45)], fill=(160, 120, 70, 180), width=1)

    for x in (220, 520, 820, 1080):
        d.rectangle([x, 28, x + 90, 70], fill=(230, 200, 130, 90))
        d.ellipse([x + 10, 100, x + 80, 220], fill=(255, 210, 120, 28))

    for x0 in (30, w - 70):
        d.rectangle([x0, 70, x0 + 40, h - 40], fill=(72, 48, 30, 255))
        d.rectangle([x0 + 6, 80, x0 + 34, h - 50], outline=(140, 100, 55, 200), width=2)

    floor_top = 360
    d.rectangle([80, floor_top, w - 80, h - 20], fill=(110, 78, 48, 255))
    for y in range(floor_top, h - 20, 18):
        shade = 8 if (y // 18) % 2 == 0 else -6
        d.rectangle(
            [90, y, w - 90, y + 16],
            fill=(120 + shade, 86 + shade, 52 + shade, 255),
        )
        d.line([(90, y), (w - 90, y)], fill=(70, 48, 30, 120), width=1)

    cx = w // 2
    d.rectangle([cx - 70, 160, cx + 70, h - 50], fill=(140, 48, 42, 170))
    d.rectangle([cx - 70, 160, cx + 70, h - 50], outline=(180, 90, 60, 180), width=3)
    for y in range(180, h - 70, 40):
        d.ellipse([cx - 18, y, cx + 18, y + 18], outline=(190, 120, 70, 140), width=2)

    d.rectangle([cx - 120, 120, cx + 120, 250], fill=(86, 56, 34, 240))
    d.rectangle([cx - 110, 130, cx + 110, 240], outline=(190, 150, 80, 220), width=3)
    d.rectangle([cx - 70, 150, cx + 70, 210], fill=(60, 40, 26, 255))
    d.ellipse([cx - 55, 95, cx + 55, 145], fill=(255, 200, 110, 40))

    for x in (260, 640, 1020):
        d.rectangle([x - 3, 70, x + 3, 110], fill=(90, 60, 35, 255))
        d.ellipse([x - 28, 105, x + 28, 165], fill=(230, 170, 70, 210))
        d.ellipse([x - 20, 112, x + 20, 155], fill=(255, 210, 120, 90))

    d.rectangle([220, 300, w - 220, 340], fill=(78, 52, 32, 230))
    d.rectangle([230, 292, w - 230, 304], fill=(150, 110, 60, 200))

    vig = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vig)
    vd.rectangle([0, 0, w, h], outline=(40, 24, 14, 90), width=50)
    vig = vig.filter(ImageFilter.GaussianBlur(18))
    img = Image.alpha_composite(img.convert("RGBA"), vig).convert("RGB")

    d = ImageDraw.Draw(img)
    d.rounded_rectangle(
        [40, h - 58, 280, h - 24],
        radius=8,
        fill=(52, 34, 22),
        outline=(190, 150, 80),
        width=2,
    )
    d.text((58, h - 50), "Qianji Front Hall", fill=(240, 220, 170))

    path = OUT / "hall_front.png"
    img.save(path, "PNG")
    print("wrote", path, img.size)
    return path


def make_busts() -> None:
    BUST_DIR.mkdir(parents=True, exist_ok=True)
    ids = [
        "char_qian_demao",
        "char_zhou_guanshi",
        "char_lin_ruisheng",
        "char_wang_pangzi",
        "char_qian_zian",
        "char_zhao_hongyun",
        "char_bradley",
        "char_liu_ruyan",
    ]
    for cid in ids:
        src = PORTRAIT_DIR / f"{cid}.png"
        if not src.exists():
            print("missing portrait", cid)
            continue
        src_img = Image.open(src).convert("RGBA")
        w, h = src_img.size
        src_img = src_img.crop((0, 0, w, int(h * 0.82)))
        w, h = src_img.size
        side = min(w, h)
        left = (w - side) // 2
        top = max(0, (h - side) // 2 - side // 10)
        sq = src_img.crop((left, top, left + side, top + side)).resize(
            (128, 128), Image.Resampling.LANCZOS
        )
        mask = Image.new("L", (128, 128), 0)
        ImageDraw.Draw(mask).ellipse([2, 2, 125, 125], fill=255)
        out = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        out.paste(sq, (0, 0))
        out.putalpha(mask)
        ring = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
        ImageDraw.Draw(ring).ellipse([1, 1, 126, 126], outline=(210, 170, 90, 230), width=3)
        out = Image.alpha_composite(out, ring)
        op = BUST_DIR / f"{cid}.png"
        out.save(op)
        print("bust", op)


def make_rival_bust(
    cid: str,
    skin: tuple[int, int, int],
    hair: tuple[int, int, int],
    robe: tuple[int, int, int],
    accent: tuple[int, int, int],
) -> None:
    """Procedural circular bust for rivals without portrait art."""
    BUST_DIR.mkdir(parents=True, exist_ok=True)
    size = 128
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(out)
    # warm plate behind figure
    d.ellipse([4, 4, 123, 123], fill=(skin[0] // 3 + 40, skin[1] // 3 + 28, skin[2] // 3 + 18, 255))
    # shoulders / robe
    d.ellipse([18, 78, 110, 150], fill=(*robe, 255))
    d.rectangle([28, 92, 100, 126], fill=(*robe, 255))
    # collar accent (rival pressure)
    d.polygon([(48, 92), (64, 78), (80, 92)], fill=(*accent, 255))
    # head
    d.ellipse([38, 28, 90, 88], fill=(*skin, 255))
    # hair
    d.ellipse([36, 22, 92, 52], fill=(*hair, 255))
    d.rectangle([40, 34, 88, 46], fill=(*hair, 255))
    # eyes (sharp)
    d.ellipse([50, 52, 58, 60], fill=(30, 22, 18, 255))
    d.ellipse([70, 52, 78, 60], fill=(30, 22, 18, 255))
    # smirk
    d.arc([54, 62, 74, 78], 20, 160, fill=(90, 40, 35, 255), width=2)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse([2, 2, 125, 125], fill=255)
    out.putalpha(mask)
    ring = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(ring).ellipse([1, 1, 126, 126], outline=(200, 70, 50, 240), width=4)
    out = Image.alpha_composite(out, ring)
    op = BUST_DIR / f"{cid}.png"
    out.save(op)
    print("rival bust", op)


def make_rival_busts() -> None:
    make_rival_bust(
        "char_apprentice_sun_liu",
        skin=(220, 180, 150),
        hair=(40, 28, 22),
        robe=(120, 48, 42),
        accent=(190, 90, 50),
    )
    make_rival_bust(
        "char_apprentice_xiao_chen",
        skin=(210, 175, 145),
        hair=(35, 30, 28),
        robe=(70, 78, 92),
        accent=(140, 110, 70),
    )
    make_rival_bust(
        "char_zhao_waichang",
        skin=(205, 168, 140),
        hair=(28, 24, 22),
        robe=(88, 52, 38),
        accent=(170, 120, 60),
    )
    make_rival_bust(
        "char_li_waichang",
        skin=(215, 178, 148),
        hair=(45, 32, 26),
        robe=(62, 72, 58),
        accent=(150, 100, 55),
    )


if __name__ == "__main__":
    make_hall()
    make_busts()
    make_rival_busts()
    print("done")
