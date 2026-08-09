from PIL import Image

im = Image.open(r"f:\Games\New-Life\game\art\player\player_walk_8dir.png").convert("RGBA")
fw, fh = 66, 122
dirs = ["s", "se", "e", "ne", "n", "nw", "w", "sw"]
for i, d in enumerate(dirs):
	cell = im.crop((0, i * fh, fw, (i + 1) * fh))
	head = cell.crop((0, 0, fw, 45))
	skin = dark = total = 0
	for px in head.getdata():
		r, g, b, a = px
		if a < 10:
			continue
		total += 1
		if r > 180 and g > 140 and b > 100 and r > b:
			skin += 1
		if r < 60 and g < 60 and b < 60:
			dark += 1
	left = right = 0
	for y in range(fh):
		for x in range(fw):
			r, g, b, a = cell.getpixel((x, y))
			if a < 10:
				continue
			if x < fw // 2:
				left += 1
			else:
				right += 1
	if left > right + 20:
		bias = "L"
	elif right > left + 20:
		bias = "R"
	else:
		bias = "C"
	face = "FRONT" if skin > 25 else ("BACK" if skin < 8 else "SIDE?")
	print(f"row{i} {d:2} skin={skin:3} dark={dark:3} bias={bias} face~{face}")
