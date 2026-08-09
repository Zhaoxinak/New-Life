#!/usr/bin/env python3
import re
import subprocess
import warnings
from pathlib import Path

warnings.filterwarnings("ignore")
import requests

PROXY = {"http": "socks5h://127.0.0.1:7890", "https": "socks5h://127.0.0.1:7890"}
H = {"User-Agent": "Mozilla/5.0"}
DIR = Path(__file__).resolve().parent / "music"
FFMPEG = r"C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"

PAGES = [
	"https://opengameart.org/content/tyhosi-garden-2",
	"https://opengameart.org/content/tyhosi-garden",
	"https://opengameart.org/content/tyhosi-asian-sparrow-3",
	"https://opengameart.org/content/tyhosi-asian-sparrow-2",
	"https://opengameart.org/content/tyhosi-asian-sparrow-1",
	"https://opengameart.org/content/tyhosi-asian-sparrow",
	"https://opengameart.org/content/asian-sparrow-2",
	"https://opengameart.org/content/asianoriental3",
	"https://opengameart.org/content/oriental-flute",
	"https://opengameart.org/content/japanese-theme",
	"https://opengameart.org/content/chinese-theme",
	"https://opengameart.org/content/far-eastern",
	"https://opengameart.org/content/ambient-oriental",
	"https://opengameart.org/content/market-day",
	"https://opengameart.org/content/busy-market",
	"https://opengameart.org/content/townsfolk",
	"https://opengameart.org/content/peaceful-meadow",
	"https://opengameart.org/content/soft-melody",
	"https://opengameart.org/content/melancholy-theme",
	"https://opengameart.org/content/sad-theme",
	"https://opengameart.org/content/dark-theme",
	"https://opengameart.org/content/mystery-theme",
	"https://opengameart.org/content/investigation-theme",
	"https://opengameart.org/content/noir-theme",
	"https://opengameart.org/content/rainy-mood",
	"https://opengameart.org/content/fog",
	"https://opengameart.org/content/harbor-night",
	"https://opengameart.org/content/seaside",
	"https://opengameart.org/content/docks-theme",
	"https://opengameart.org/content/industrial-zone",
	"https://opengameart.org/content/city-night",
	"https://opengameart.org/content/urban-ambient",
	"https://opengameart.org/content/lo-fi-hip-hop",
	"https://opengameart.org/content/chill-lofi",
	"https://opengameart.org/content/relaxing-piano",
	"https://opengameart.org/content/piano-ambient",
	"https://opengameart.org/content/string-quartet",
	"https://opengameart.org/content/dramatic-strings",
	"https://opengameart.org/content/tense-strings",
	"https://opengameart.org/content/suspense",
	"https://opengameart.org/content/thriller",
	"https://opengameart.org/users/tozan/content",
	"https://opengameart.org/users/tozan",
]


def get(url: str, timeout: int = 45):
	return requests.get(url, proxies=PROXY, timeout=timeout, verify=False, headers=H)


def main() -> None:
	DIR.mkdir(exist_ok=True)
	jobs: list[tuple[str, str]] = []
	seen_url: set[str] = set()

	for page in PAGES:
		try:
			r = get(page)
			print(page.split("/")[-1], r.status_code, flush=True)
			if r.status_code != 200:
				continue
			# gather linked content pages from user listings
			for href in re.findall(r'href="(/content/[^"#?]+)"', r.text):
				if "comment" in href:
					continue
				full = "https://opengameart.org" + href
				if full not in PAGES and full not in seen_url:
					# only follow from user pages
					if "/users/" in page:
						PAGES.append(full)
			files = re.findall(
				r"https://opengameart.org/sites/default/files/(?!styles/)(?!audio_preview/)[^\"\\s]+\.(?:ogg|mp3)",
				r.text,
			)
			files = [f for f in sorted(set(files)) if "preview" not in f.lower()]
			if not files:
				continue
			cc0 = "CC0" in r.text or "cc0" in r.text
			tags_ok = any(
				k in r.text.lower()
				for k in [
					"oriental",
					"asian",
					"chinese",
					"japanese",
					"koto",
					"town",
					"market",
					"ambient",
					"harbor",
					"port",
					"mystery",
					"noir",
					"piano",
					"tense",
					"suspense",
					"sparrow",
					"garden",
				]
			)
			if not cc0 and not tags_ok:
				print("  skip license/tags", flush=True)
				continue
			f = files[0]
			for c in files:
				if c.endswith(".ogg"):
					f = c
					break
			if f in seen_url:
				continue
			seen_url.add(f)
			slug = page.rstrip("/").split("/")[-1]
			if slug in ("tozan", "content"):
				slug = Path(f).stem
			stem = re.sub(r"[^a-z0-9]+", "_", slug.lower()).strip("_")[:32]
			print(("  CC0 " if cc0 else "  ??  ") + stem + " <- " + Path(f).name, flush=True)
			jobs.append((f, stem))
		except Exception as e:
			print("err", page, e, flush=True)

	print("JOBS", len(jobs), flush=True)
	for url, stem in jobs:
		out = DIR / f"{stem}.ogg"
		if out.exists() and out.stat().st_size > 40000:
			print("skip", stem, flush=True)
			continue
		try:
			r = get(url, timeout=120)
			if r.status_code != 200 or b"<html" in r.content[:80].lower():
				print("bad", stem, r.status_code, flush=True)
				continue
			tmp = DIR / ("_t" + Path(url).suffix)
			tmp.write_bytes(r.content)
			if url.endswith(".ogg"):
				tmp.replace(out)
			else:
				subprocess.check_call(
					[FFMPEG, "-y", "-i", str(tmp), "-c:a", "libvorbis", "-q:a", "5", str(out)],
					stdout=subprocess.DEVNULL,
					stderr=subprocess.DEVNULL,
				)
				tmp.unlink(missing_ok=True)
			print("OK", stem, out.stat().st_size, flush=True)
		except Exception as e:
			print("FAIL", stem, e, flush=True)

	print("ALL:", flush=True)
	for p in sorted(DIR.glob("*.ogg")):
		print(f"  {p.name:32} {p.stat().st_size:8}", flush=True)


if __name__ == "__main__":
	main()
