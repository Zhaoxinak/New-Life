"""Rebuild normal (non-lunge) 8-dir walk sheet from strip assets."""
from __future__ import annotations

import os
from PIL import Image, ImageFilter

ASSETS = r"C:\Users\Administrator\.cursor\projects\f-Games-New-Life\assets"
OUT = r"f:\Games\New-Life\game\art\player\player_walk_8dir.png"
SRC_COLS = 6
OUT_COLS = 6
TARGET_H = 114
DIR_ORDER = ["s", "se", "e", "ne", "n", "nw", "w", "sw"]

# Normal walk strips (NOT *_stride.png).
STRIP_SPEC = {
	"s": ("player_s_strip.png", False),
	"se": ("player_se_strip.png", False),
	"ne": ("player_ne_strip.png", False),
	"n": ("player_n_strip.png", False),
	"nw": ("player_nw_strip.png", False),
	"w": ("player_w_strip.png", False),
}


def is_chroma_bg(r: int, g: int, b: int) -> bool:
	if r > 160 and b > 160 and g < 120 and r + b > g * 2 + 80:
		return True
	if g > 100 and g > r + 25 and g > b + 25:
		return True
	if r > 248 and g > 248 and b > 248:
		return True
	return False


def remove_background(im: Image.Image) -> Image.Image:
	im = im.convert("RGBA")
	w, h = im.size
	px = im.load()
	seed = Image.new("L", (w, h), 0)
	sp = seed.load()
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a < 10 or is_chroma_bg(r, g, b):
				continue
			if r + g + b >= 70:
				sp[x, y] = 255
	mask = seed
	for _ in range(4):
		mask = mask.filter(ImageFilter.MaxFilter(5))
	mp = mask.load()
	out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	op = out.load()
	for y in range(h):
		for x in range(w):
			if mp[x, y] == 0:
				continue
			r, g, b, a = px[x, y]
			if a < 10 or is_chroma_bg(r, g, b):
				continue
			op[x, y] = (r, g, b, 255)
	return out


def keep_largest_blob(fr: Image.Image) -> Image.Image:
	bbox = fr.getbbox()
	if not bbox:
		return fr
	fr = fr.crop(bbox)
	w, h = fr.size
	px = fr.load()
	seen = [[False] * w for _ in range(h)]
	blobs: list[list[tuple[int, int]]] = []

	def neighbors(x: int, y: int):
		for yy in (y - 1, y, y + 1):
			for xx in (x - 1, x, x + 1):
				if xx == x and yy == y:
					continue
				if 0 <= xx < w and 0 <= yy < h:
					yield xx, yy

	for y in range(h):
		for x in range(w):
			if seen[y][x] or px[x, y][3] < 10:
				continue
			stack = [(x, y)]
			seen[y][x] = True
			blob: list[tuple[int, int]] = []
			while stack:
				cx, cy = stack.pop()
				blob.append((cx, cy))
				for nx, ny in neighbors(cx, cy):
					if seen[ny][nx] or px[nx, ny][3] < 10:
						continue
					seen[ny][nx] = True
					stack.append((nx, ny))
			blobs.append(blob)
	if not blobs:
		return fr
	blobs.sort(key=len, reverse=True)
	main = set(blobs[0])
	for blob in blobs[1:]:
		if len(blob) >= 12:
			main.update(blob)
	out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	op = out.load()
	for x, y in main:
		op[x, y] = px[x, y]
	return out


def normalize_frame(fr: Image.Image) -> Image.Image:
	fr = keep_largest_blob(fr)
	bbox = fr.getbbox()
	if not bbox:
		return fr
	fr = fr.crop(bbox)
	scale = TARGET_H / float(max(1, fr.height))
	nw = max(1, int(round(fr.width * scale)))
	nh = max(1, int(round(fr.height * scale)))
	return fr.resize((nw, nh), Image.Resampling.NEAREST)


def extract_cells(path: str, flip_h: bool = False) -> list[Image.Image]:
	im = remove_background(Image.open(path))
	w, h = im.size
	cw = w // SRC_COLS
	frames: list[Image.Image] = []
	for c in range(SRC_COLS):
		cell = im.crop((c * cw, 0, (c + 1) * cw, h))
		if flip_h:
			cell = cell.transpose(Image.FLIP_LEFT_RIGHT)
		fr = normalize_frame(cell)
		if fr.getbbox():
			frames.append(fr)
	# Pad / trim to OUT_COLS
	if not frames:
		blank = Image.new("RGBA", (48, TARGET_H), (0, 0, 0, 0))
		return [blank] * OUT_COLS
	if len(frames) >= OUT_COLS:
		idxs = [int(round(i * (len(frames) - 1) / (OUT_COLS - 1))) for i in range(OUT_COLS)]
		return [frames[j] for j in idxs]
	while len(frames) < OUT_COLS:
		frames.append(frames[-1].copy())
	return frames


def main() -> None:
	raw: dict[str, list[Image.Image]] = {}
	for d, (fname, flip) in STRIP_SPEC.items():
		path = os.path.join(ASSETS, fname)
		print(d, "<=", fname)
		raw[d] = extract_cells(path, flip)
		fr = raw[d][0]
		rs = gs = bs = n = 0
		for p in fr.getdata():
			if p[3] > 10:
				rs += p[0]
				gs += p[1]
				bs += p[2]
				n += 1
		print("  avg", (rs // n, gs // n, bs // n) if n else None, "frames", len(raw[d]))

	print("e <= mirror w")
	raw["e"] = [fr.transpose(Image.FLIP_LEFT_RIGHT) for fr in raw["w"]]
	print("sw <= mirror se")
	raw["sw"] = [fr.transpose(Image.FLIP_LEFT_RIGHT) for fr in raw["se"]]

	rows = [raw[d] for d in DIR_ORDER]
	max_fw = max(fr.width for frames in rows for fr in frames)
	max_fh = max(fr.height for frames in rows for fr in frames)
	pad = 4
	fw = max_fw + pad * 2
	fh = max_fh + pad * 2
	fw += fw % 2
	fh += fh % 2
	print("frame", fw, fh, "cols", OUT_COLS)

	out = Image.new("RGBA", (fw * OUT_COLS, fh * len(DIR_ORDER)), (0, 0, 0, 0))
	for r, frames in enumerate(rows):
		for c, fr in enumerate(frames):
			dx = c * fw + (fw - fr.width) // 2
			dy = r * fh + (fh - fr.height - pad)
			out.paste(fr, (dx, dy), fr)
		print(DIR_ORDER[r], [frames[c].width for c in range(OUT_COLS)])

	out.save(OUT)
	print("saved", OUT, out.size)
	with open(os.path.join(os.path.dirname(OUT), "player_walk_8dir.meta.txt"), "w", encoding="utf-8") as f:
		f.write(f"frame_w={fw}\nframe_h={fh}\ncols={OUT_COLS}\nrows={len(DIR_ORDER)}\n")


if __name__ == "__main__":
	main()
