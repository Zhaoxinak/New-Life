"""Chroma-key and normalize the 8-dir walk spritesheet for Godot."""
from __future__ import annotations

import os
from PIL import Image

SRC = r"C:\Users\Administrator\.cursor\projects\f-Games-New-Life\assets\player_walk_8dir.png"
OUT_DIR = r"f:\Games\New-Life\game\art\player"
COLS, ROWS = 6, 8


def is_green(r: int, g: int, b: int) -> bool:
	return g > 120 and g > r + 40 and g > b + 40


def main() -> None:
	os.makedirs(OUT_DIR, exist_ok=True)
	im = Image.open(SRC).convert("RGBA")
	w, h = im.size
	cw, ch = w // COLS, h // ROWS
	print(f"sheet={w}x{h} cell={cw}x{ch}")

	pixels = im.load()
	for y in range(h):
		for x in range(w):
			r, g, b, _a = pixels[x, y]
			if is_green(r, g, b) or (g > 100 and g > r + 25 and g > b + 25):
				pixels[x, y] = (0, 0, 0, 0)

	max_fw = max_fh = 0
	for row in range(ROWS):
		for col in range(COLS):
			cell = im.crop((col * cw, row * ch, (col + 1) * cw, (row + 1) * ch))
			bbox = cell.getbbox()
			if not bbox:
				continue
			max_fw = max(max_fw, bbox[2] - bbox[0])
			max_fh = max(max_fh, bbox[3] - bbox[1])
	print("max content", max_fw, max_fh)

	pad = 4
	fw = max_fw + pad * 2
	fh = max_fh + pad * 2
	fw += fw % 2
	fh += fh % 2
	print("frame size", fw, fh)

	out = Image.new("RGBA", (fw * COLS, fh * ROWS), (0, 0, 0, 0))
	for row in range(ROWS):
		for col in range(COLS):
			cell = im.crop((col * cw, row * ch, (col + 1) * cw, (row + 1) * ch))
			bbox = cell.getbbox()
			if not bbox:
				continue
			content = cell.crop(bbox)
			dx = col * fw + (fw - content.width) // 2
			dy = row * fh + (fh - content.height - pad)
			out.paste(content, (dx, dy), content)

	out_path = os.path.join(OUT_DIR, "player_walk_8dir.png")
	out.save(out_path)
	print("saved", out_path, out.size)

	# Emit frame size for the Godot resource writer.
	meta_path = os.path.join(OUT_DIR, "player_walk_8dir.meta.txt")
	with open(meta_path, "w", encoding="utf-8") as f:
		f.write(f"frame_w={fw}\nframe_h={fh}\ncols={COLS}\nrows={ROWS}\n")
	print("meta", meta_path)


if __name__ == "__main__":
	main()
