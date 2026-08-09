#!/usr/bin/env python3
"""Download more CC0 BGM via socks5h proxy and convert to ogg."""
from __future__ import annotations

import re
import subprocess
import sys
import warnings
from pathlib import Path

warnings.filterwarnings("ignore")

try:
	import requests
except ImportError:
	subprocess.check_call([sys.executable, "-m", "pip", "install", "requests", "PySocks", "-q"])
	import requests

PROXY = {"http": "socks5h://127.0.0.1:7890", "https": "socks5h://127.0.0.1:7890"}
DIR = Path(__file__).resolve().parent / "music"
FFMPEG = r"C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"

# Known good OGA file URLs -> local stem
DIRECT = [
	("https://opengameart.org/sites/default/files/tyhosigarden3.ogg", "garden3"),
	("https://opengameart.org/sites/default/files/tyhoshigarden3.ogg", "garden3"),
	("https://opengameart.org/sites/default/files/asiansparrow3.ogg", "sparrow3"),
	("https://opengameart.org/sites/default/files/asiansparrow2.ogg", "sparrow2"),
	("https://opengameart.org/sites/default/files/asiansparrow1.ogg", "sparrow1"),
	("https://opengameart.org/sites/default/files/Tyhosisparrow2.ogg", "sparrow2b"),
	("https://opengameart.org/sites/default/files/Tyhosisparrow3.ogg", "sparrow3b"),
]

PAGES = [
	"https://opengameart.org/content/tyhosi-garden-3",
	"https://opengameart.org/content/tyhosi-asian-sparrow-3",
	"https://opengameart.org/content/tyhosi-asian-sparrow-2",
	"https://opengameart.org/content/tyhosi-asian-sparrow-1",
	"https://opengameart.org/content/tyhosi-garden",
	"https://opengameart.org/content/tyhosi-garden-2",
	"https://opengameart.org/content/oriental-flute-loop",
	"https://opengameart.org/content/koto-meditation",
	"https://opengameart.org/content/asian-ambient",
	"https://opengameart.org/content/far-east-melody",
	"https://opengameart.org/content/eastern-winds",
	"https://opengameart.org/content/night-in-kyoto",
	"https://opengameart.org/content/peaceful-oriental",
	"https://opengameart.org/content/dark-oriental",
	"https://opengameart.org/content/mysterious-oriental",
	"https://opengameart.org/content/chinese-folk",
	"https://opengameart.org/content/guzheng",
	"https://opengameart.org/content/erhu",
	"https://opengameart.org/content/harbor-town",
	"https://opengameart.org/content/seaside-village",
	"https://opengameart.org/content/market-theme",
	"https://opengameart.org/content/town-theme-0",
	"https://opengameart.org/content/rpg-town-theme",
	"https://opengameart.org/content/calm-ambient-loop",
	"https://opengameart.org/content/soft-ambient",
	"https://opengameart.org/content/tension-ambient",
	"https://opengameart.org/content/investigation",
	"https://opengameart.org/content/noir-loop",
	"https://opengameart.org/content/cyber-noir",
	"https://opengameart.org/content/stock-market",
	"https://opengameart.org/content/business-ambient",
	"https://opengameart.org/content/office-ambient",
	"https://opengameart.org/content/dramatic-oriental",
	"https://opengameart.org/content/battle-oriental",
	"https://opengameart.org/content/epic-oriental",
	"https://opengameart.org/content/sad-oriental",
	"https://opengameart.org/content/melancholy-oriental",
]


def get(url: str) -> requests.Response:
	return requests.get(
		url,
		proxies=PROXY,
		timeout=120,
		verify=False,
		headers={"User-Agent": "Mozilla/5.0"},
	)


def download_file(url: str, dest: Path) -> bool:
	if dest.exists() and dest.stat().st_size > 50_000:
		print(f"skip exists {dest.name}")
		return True
	try:
		with get(url) as r:
			if r.status_code != 200:
				print(f"  HTTP {r.status_code} {url}")
				return False
			ctype = r.headers.get("Content-Type", "")
			if "text/html" in ctype and len(r.content) < 200_000:
				print(f"  html bounce {url}")
				return False
			dest.write_bytes(r.content)
		print(f"OK {dest.name} ({dest.stat().st_size})")
		return True
	except Exception as e:
		print(f"FAIL {url}: {e}")
		return False


def to_ogg(src: Path, stem: str) -> Path | None:
	out = DIR / f"{stem}.ogg"
	if out.exists() and out.stat().st_size > 50_000:
		if src != out and src.exists():
			src.unlink(missing_ok=True)
		return out
	if src.suffix.lower() == ".ogg":
		if src.name != out.name:
			src.replace(out)
		return out
	try:
		subprocess.check_call(
			[FFMPEG, "-y", "-i", str(src), "-c:a", "libvorbis", "-q:a", "5", str(out)],
			stdout=subprocess.DEVNULL,
			stderr=subprocess.DEVNULL,
		)
		src.unlink(missing_ok=True)
		print(f"  converted {out.name}")
		return out
	except Exception as e:
		print(f"  convert fail {src}: {e}")
		return None


def discover_from_pages() -> list[tuple[str, str]]:
	found: list[tuple[str, str]] = []
	seen: set[str] = set()
	for page in PAGES:
		try:
			r = get(page)
			if r.status_code != 200:
				continue
			files = re.findall(
				r"https://opengameart.org/sites/default/files/(?!styles/)(?!audio_preview/)[^\"\\s]+\.(?:ogg|mp3|wav)",
				r.text,
			)
			# prefer cc0 pages
			is_cc0 = "CC0" in r.text or "cc0" in r.text or "Public Domain" in r.text
			slug = page.rstrip("/").split("/")[-1]
			for f in sorted(set(files)):
				if f in seen:
					continue
				seen.add(f)
				ext = Path(f).suffix.lower()
				stem = re.sub(r"[^a-z0-9_]+", "_", slug.lower())[:40].strip("_")
				if not stem:
					stem = Path(f).stem.lower()
				# skip huge wav if mp3/ogg also listed later
				found.append((f, f"{stem}{ext}"))
				print(f"found {'CC0' if is_cc0 else '??'} {stem} <- {f}")
				break  # one file per page
		except Exception as e:
			print(f"page fail {page}: {e}")
	return found


def main() -> int:
	DIR.mkdir(parents=True, exist_ok=True)
	jobs = list(DIRECT)
	jobs.extend(discover_from_pages())
	ok = 0
	for url, name in jobs:
		stem = Path(name).stem
		# normalize stems
		stem = re.sub(r"[^a-z0-9_]+", "_", stem.lower()).strip("_")
		dest = DIR / name
		if download_file(url, dest):
			if to_ogg(dest, stem):
				ok += 1
	print(f"done ok={ok}")
	for p in sorted(DIR.glob("*.ogg")):
		print(f"  {p.name:28} {p.stat().st_size:8}")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
