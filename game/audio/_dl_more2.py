#!/usr/bin/env python3
import re, subprocess, sys, warnings
from pathlib import Path
warnings.filterwarnings("ignore")
import requests

PROXY = {"http": "socks5h://127.0.0.1:7890", "https": "socks5h://127.0.0.1:7890"}
DIR = Path(__file__).resolve().parent / "music"
FFMPEG = r"C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
H = {"User-Agent": "Mozilla/5.0"}

SEARCHES = [
	"https://opengameart.org/art-search-advanced?keys=oriental&field_art_type_tid%5B%5D=12&sort_by=count&sort_order=DESC",
	"https://opengameart.org/art-search-advanced?keys=asian&field_art_type_tid%5B%5D=12&sort_by=count&sort_order=DESC",
	"https://opengameart.org/users/tozan",
	"https://opengameart.org/users/neuroblade",
	"https://opengameart.org/content/tyhosi-garden-2",
	"https://opengameart.org/content/tyhosi-garden",
	"https://opengameart.org/content/tyhosi-asian-sparrow-3-tea-house",
	"https://opengameart.org/content/tyhosi-asian-sparrow-2",
	"https://opengameart.org/content/tyhosi-asian-sparrow",
	"https://opengameart.org/content/asian-sparrow",
	"https://opengameart.org/content/japanese-town",
	"https://opengameart.org/content/chinese-village",
	"https://opengameart.org/content/oriental-dream",
	"https://opengameart.org/content/oriental-night",
	"https://opengameart.org/content/shamisen",
	"https://opengameart.org/content/koto-theme",
	"https://opengameart.org/content/erhu-melody",
	"https://opengameart.org/content/guzheng-loop",
	"https://opengameart.org/content/tea-ceremony",
	"https://opengameart.org/content/lantern-festival",
	"https://opengameart.org/content/misty-mountains",
	"https://opengameart.org/content/foggy-harbor",
	"https://opengameart.org/content/docks",
	"https://opengameart.org/content/port",
	"https://opengameart.org/content/wharf",
	"https://opengameart.org/content/investigative",
	"https://opengameart.org/content/detective-theme",
	"https://opengameart.org/content/sneaky",
	"https://opengameart.org/content/stealth-ambient",
	"https://opengameart.org/content/thriller-ambient",
	"https://opengameart.org/content/dark-city",
	"https://opengameart.org/content/rainy-night",
	"https://opengameart.org/content/melancholy",
	"https://opengameart.org/content/sad-piano-loop",
	"https://opengameart.org/content/emotional-strings",
]

KNOWN = [
	# Tozan sparrow / garden series (probe common filenames)
	("https://opengameart.org/sites/default/files/asiansparrow3_0.ogg", "sparrow3"),
	("https://opengameart.org/sites/default/files/asiansparrow3.ogg", "sparrow3"),
	("https://opengameart.org/sites/default/files/Tyhosisparrow3.ogg", "sparrow3"),
	("https://opengameart.org/sites/default/files/asiansparrow2_0.ogg", "sparrow2"),
	("https://opengameart.org/sites/default/files/asiansparrow2.ogg", "sparrow2"),
	("https://opengameart.org/sites/default/files/Tyhosisparrow2.ogg", "sparrow2"),
	("https://opengameart.org/sites/default/files/asiansparrow1_0.ogg", "sparrow1"),
	("https://opengameart.org/sites/default/files/asiansparrow1.ogg", "sparrow1"),
	("https://opengameart.org/sites/default/files/tyhosigarden2.ogg", "garden2"),
	("https://opengameart.org/sites/default/files/tyhoshigarden2.ogg", "garden2"),
	("https://opengameart.org/sites/default/files/tyhosigarden.ogg", "garden1"),
	("https://opengameart.org/sites/default/files/tyhosigarden1.ogg", "garden1"),
	("https://opengameart.org/sites/default/files/tyhosisgarden.ogg", "garden1"),
]


def get(url, stream=False):
	return requests.get(url, proxies=PROXY, timeout=90, verify=False, headers=H, stream=stream)


def save(url, stem):
	out = DIR / f"{stem}.ogg"
	if out.exists() and out.stat().st_size > 40000:
		print("skip", stem)
		return True
	tmp = DIR / ("_tmp_" + Path(url).name)
	try:
		r = get(url)
		if r.status_code != 200:
			print("404", stem, url)
			return False
		if b"<html" in r.content[:200].lower():
			print("html", stem)
			return False
		tmp.write_bytes(r.content)
		if tmp.suffix.lower() == ".ogg" or url.endswith(".ogg"):
			tmp.replace(out)
		else:
			subprocess.check_call([FFMPEG,"-y","-i",str(tmp),"-c:a","libvorbis","-q:a","5",str(out)],
				stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
			tmp.unlink(missing_ok=True)
		print("OK", stem, out.stat().st_size)
		return True
	except Exception as e:
		print("FAIL", stem, e)
		tmp.unlink(missing_ok=True)
		return False


def scrape():
	links = []
	for u in SEARCHES:
		try:
			r = get(u)
			if r.status_code != 200:
				continue
			# content pages
			for m in re.findall(r'href="(/content/[^"]+)"', r.text):
				if "comment" in m: continue
				links.append("https://opengameart.org" + m)
			# direct files on page
			for m in re.findall(r'https://opengameart.org/sites/default/files/(?!styles/)(?!audio_preview/)[^\"\\s]+\.(?:ogg|mp3)', r.text):
				links.append(m)
		except Exception as e:
			print("search fail", u, e)
	# unique content pages first
	pages = []
	seen = set()
	for l in links:
		if "/content/" in l and l not in seen:
			seen.add(l)
			pages.append(l)
	print("pages", len(pages))
	jobs = []
	for page in pages[:60]:
		try:
			r = get(page)
			if r.status_code != 200: continue
			text = r.text
			cc0 = ("CC0" in text) or ("cc0" in text)
			files = re.findall(r'https://opengameart.org/sites/default/files/(?!styles/)(?!audio_preview/)[^\"\\s]+\.(?:ogg|mp3)', text)
			files = [f for f in sorted(set(files)) if "preview" not in f.lower()]
			if not files: continue
			slug = page.rstrip("/").split("/")[-1]
			# oriental/asian filter for non-cc0 skip unless tags match
			tags_ok = any(k in text.lower() for k in ["oriental","asian","chinese","japanese","koto","shaku","erhu","guzheng","harbor","port","town","ambient","market","tea"])
			if not cc0 and not tags_ok:
				continue
			f = files[0]
			# prefer ogg
			for cand in files:
				if cand.endswith(".ogg"):
					f = cand; break
			stem = re.sub(r"[^a-z0-9]+","_", slug.lower()).strip("_")[:36]
			jobs.append((f, stem, cc0))
			print(("CC0" if cc0 else "?? "), stem, "<-", Path(f).name)
		except Exception as e:
			pass
	return jobs


def main():
	DIR.mkdir(exist_ok=True)
	ok = 0
	for url, stem in KNOWN:
		if save(url, stem):
			ok += 1
	for url, stem, cc0 in scrape():
		# avoid overwriting our curated names
		if (DIR / f"{stem}.ogg").exists():
			continue
		if save(url, stem):
			ok += 1
	print("done", ok)
	for p in sorted(DIR.glob("*.ogg")):
		print(f"  {p.name:32} {p.stat().st_size:8}")


if __name__ == "__main__":
	main()
