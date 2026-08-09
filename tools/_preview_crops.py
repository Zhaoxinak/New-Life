from pathlib import Path
from PIL import Image

im = Image.open(Path(__file__).resolve().parents[1] / "game/art/world/harbor_outdoor.png")
crops = {
    "home": (640, 40, 920, 280),
    "dock": (580, 680, 920, 960),
    "tea": (40, 280, 340, 520),
    "garage": (40, 680, 360, 920),
    "plaza": (40, 460, 360, 680),
    "company": (40, 20, 360, 260),
    "rival": (1120, 20, 1480, 260),
    "exchange": (1000, 380, 1450, 680),
}
out = Path(__file__).resolve().parent / "_cottage_crop_preview"
out.mkdir(exist_ok=True)
for k, box in crops.items():
    c = im.crop(box)
    c.save(out / f"{k}.png")
    print(k, c.size)
print("wrote", out)
