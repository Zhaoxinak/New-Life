#!/usr/bin/env python3
import re, subprocess, time, warnings
from pathlib import Path
warnings.filterwarnings("ignore")
import requests

PROXY = {"http": "socks5h://127.0.0.1:7890", "https": "socks5h://127.0.0.1:7890"}
H = {"User-Agent": "Mozilla/5.0"}
DIR = Path(__file__).resolve().parent / "music"
FFMPEG = r"C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"

# Known good pages / direct files from prior OGA browsing
PAGES = [
	"https://opengameart.org/content/investigation-theme",
	"https://opengameart.org/content/dark-theme",
	"https://opengameart.org/content/suspense",
	"https://opengameart.org/content/town-theme-0",
	"https://opengameart.org/content/tyhosi-garden-3",
	"https://opengameart.org/content/mysterious-sparrow-lake",
	"https://opengameart.org/content/oriental-high-strings-short",
	"https://opengameart.org/content/fools-philosophy",
	"https://opengameart.org/content/four-sequence",
	"https://opengameart.org/content/oriental-somber",
	"https://opengameart.org/content/asianoriental1",
	"https://opengameart.org/content/asianoriental2",
	"https://opengameart.org/content/port-town-loop",
	"https://opengameart.org/content/tyhosi-asian-sparrow-4-kimono-market-zone",
	"https://opengameart.org/content/tyhosi-sparrow",
	"https://opengameart.org/content/samurai-nights",
	# extras worth grabbing if present
	"https://opengameart.org/content/alone",
	"https://opengameart.org/content/sadness",
	"https://opengameart.org/content/hope",
	"https://opengameart.org/content/determination",
	"https://opengameart.org/content/defeat",
	"https://opengameart.org/content/victory-theme",
	"https://opengameart.org/content/menu-theme",
	"https://opengameart.org/content/title-theme",
	"https://opengameart.org/content/overworld",
	"https://opengameart.org/content/cave-theme",
	"https://opengameart.org/content/temple",
	"https://opengameart.org/content/shrine",
	"https://opengameart.org/content/village-theme",
	"https://opengameart.org/content/castle-theme",
	"https://opengameart.org/content/dungeon-theme",
	"https://opengameart.org/content/boss-theme",
	"https://opengameart.org/content/night-theme",
	"https://opengameart.org/content/day-theme",
	"https://opengameart.org/content/rain",
	"https://opengameart.org/content/storm",
	"https://opengameart.org/content/wind",
	"https://opengameart.org/content/ocean",
	"https://opengameart.org/content/waves",
	"https://opengameart.org/content/undercover",
	"https://opengameart.org/content/espionage",
	"https://opengameart.org/content/conspiracy",
	"https://opengameart.org/content/intrigue",
]


def get(url, timeout=50, retries=3):
	last = None
	for i in range(retries):
		try:
			return requests.get(url, proxies=PROXY, timeout=timeout, verify=False, headers=H)
		except Exception as e:
			last = e
			time.sleep(0.6 * (i + 1))
	raise last


def main():
	existing = {p.stem for p in DIR.glob("*.ogg")}
	jobs = []
	for page in PAGES:
		try:
			r = get(page)
			print(page.split("/")[-1], r.status_code, flush=True)
			if r.status_code != 200:
				continue
			files = re.findall(
				r"https://opengameart.org/sites/default/files/(?!styles/)(?!audio_preview/)[^\"\\s]+\.(?:ogg|mp3)",
				r.text,
			)
			files = [f for f in sorted(set(files)) if "preview" not in f.lower()]
			if not files:
				continue
			cc0 = "CC0" in r.text or "cc0" in r.text or "Public Domain" in r.text
			# accept attribution-friendly too if tags fit mood
			tags = r.text.lower()
			mood_ok = any(k in tags for k in [
				"oriental","asian","town","market","ambient","mystery","dark","suspense",
				"piano","sad","night","ocean","rain","intrigue","temple","village","menu","title",
			])
			if not cc0 and not mood_ok:
				continue
			f = next((c for c in files if c.endswith(".ogg")), files[0])
			slug = page.rstrip("/").split("/")[-1]
			stem = re.sub(r"[^a-z0-9]+", "_", slug.lower()).strip("_")[:32]
			if stem in existing:
				print("  have", stem, flush=True)
				continue
			print(("  CC0 " if cc0 else "  ??  ") + stem, flush=True)
			jobs.append((f, stem))
		except Exception as e:
			print("err", page.split("/")[-1], type(e).__name__, flush=True)

	print("NEW JOBS", len(jobs), flush=True)
	for url, stem in jobs:
		out = DIR / f"{stem}.ogg"
		try:
			r = get(url, timeout=120)
			if r.status_code != 200 or b"<html" in r.content[:80].lower():
				print("bad", stem, flush=True)
				continue
			tmp = DIR / ("_t" + Path(url).suffix)
			tmp.write_bytes(r.content)
			if url.endswith(".ogg"):
				tmp.replace(out)
			else:
				subprocess.check_call(
					[FFMPEG, "-y", "-i", str(tmp), "-c:a", "libvorbis", "-q:a", "5", str(out)],
					stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
				)
				tmp.unlink(missing_ok=True)
			print("OK", stem, out.stat().st_size, flush=True)
			existing.add(stem)
		except Exception as e:
			print("FAIL", stem, e, flush=True)

	print("TOTAL", len(list(DIR.glob('*.ogg'))), flush=True)


if __name__ == "__main__":
	main()
