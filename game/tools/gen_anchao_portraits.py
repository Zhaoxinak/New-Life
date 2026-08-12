# -*- coding: utf-8 -*-
"""Generate stylized placeholder portraits for Anchao speakers."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parents[1] / "art" / "portraits" / "anchao"
W, H = 256, 320

# speaker_id -> (bg RGB, accent RGB, display name)
CAST = {
    "narrator": ((72, 66, 58), (160, 148, 128), "旁白"),
    "char_lin_ruisheng": ((48, 62, 78), (140, 170, 190), "林瑞生"),
    "char_qian_demao": ((92, 48, 32), (200, 130, 90), "钱德茂"),
    "char_qian_zian": ((70, 42, 68), (180, 130, 170), "钱子安"),
    "char_liu_ruyan": ((74, 52, 72), (190, 150, 180), "柳如烟"),
    "char_bradley": ((40, 55, 85), (130, 160, 200), "白瑞德"),
    "char_zhao_hongyun": ((82, 62, 34), (190, 155, 95), "赵鸿运"),
    "char_wang_pangzi": ((78, 56, 38), (180, 140, 100), "王胖子"),
    "char_zhou_guanshi": ((64, 60, 52), (160, 150, 130), "周管事"),
    "char_qing_daren": ((58, 32, 38), (160, 90, 100), "庆大人"),
    "char_msg_broker": ((70, 58, 42), (170, 145, 110), "消息通"),
    "char_bank_clerk": ((52, 64, 60), (140, 165, 155), "票号柜员"),
    "char_firm_hand": ((66, 54, 44), (165, 140, 115), "后院伙计"),
}


def _font(size: int) -> ImageFont.ImageFont:
    candidates = [
        r"C:\Windows\Fonts\msyh.ttc",
        r"C:\Windows\Fonts\msyhbd.ttc",
        r"C:\Windows\Fonts\simhei.ttf",
        r"C:\Windows\Fonts\simsun.ttc",
    ]
    for path in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def draw_portrait(speaker_id: str, bg, accent, name: str) -> None:
    img = Image.new("RGBA", (W, H), (*bg, 255))
    draw = ImageDraw.Draw(img)

    # top edge strip
    draw.rectangle([0, 0, W, 10], fill=(*accent, 255))
    # outer frame
    draw.rectangle([8, 18, W - 9, H - 9], outline=(*accent, 220), width=3)

    # head silhouette circle
    cx, cy, r = W // 2, 118, 54
    head = tuple(min(255, c + 35) for c in bg)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(*head, 255), outline=(*accent, 255), width=2)
    # shoulders
    draw.ellipse([cx - 88, cy + 40, cx + 88, H - 70], fill=(*head, 255), outline=(*accent, 180), width=2)

    # name plate
    draw.rectangle([20, H - 68, W - 21, H - 22], fill=(20, 18, 16, 210))
    font = _font(28)
    bbox = draw.textbbox((0, 0), name, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(((W - tw) / 2, H - 62 + (36 - th) / 2), name, font=font, fill=(240, 228, 200, 255))

    # small id mark
    tiny = _font(14)
    mark = "暗潮"
    mb = draw.textbbox((0, 0), mark, font=tiny)
    draw.text((W - (mb[2] - mb[0]) - 16, 20), mark, font=tiny, fill=(*accent, 180))

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{speaker_id}.png"
    img.save(path)
    print("wrote", path.relative_to(OUT.parent.parent.parent))


def main() -> None:
    for sid, (bg, accent, name) in CAST.items():
        draw_portrait(sid, bg, accent, name)
    print("portraits:", len(CAST))


if __name__ == "__main__":
    main()
