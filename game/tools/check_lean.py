from PIL import Image

def lean(path: str, cols: int = 6) -> str:
	im = Image.open(path).convert("RGBA")
	w, h = im.size
	cw = w // cols
	# use middle frame
	c = 2
	cell = im.crop((c * cw, 0, (c + 1) * cw, h))
	# chroma rough
	left = right = 0
	for y in range(cell.height):
		for x in range(cell.width):
			r, g, b, a = cell.getpixel((x, y))
			if a < 10:
				continue
			if g > 100 and g > r + 25 and g > b + 25:
				continue
			if x < cell.width // 2:
				left += 1
			else:
				right += 1
	return "R" if right > left else "L", left, right

for label, path in [
	("NE", r"C:\Users\Administrator\.cursor\projects\f-Games-New-Life\assets\player_ne_strip.png"),
	("NW", r"C:\Users\Administrator\.cursor\projects\f-Games-New-Life\assets\player_nw_strip.png"),
	("SE", r"C:\Users\Administrator\.cursor\projects\f-Games-New-Life\assets\player_se_strip.png"),
]:
	side, l, r = lean(path)
	print(label, "lean", side, "L", l, "R", r)
