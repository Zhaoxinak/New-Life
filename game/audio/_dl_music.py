#!/usr/bin/env python3
"""Download BGM tracks via local proxy and convert with ffmpeg."""
from __future__ import annotations

import subprocess
import sys
import zipfile
from pathlib import Path

try:
	import requests
except ImportError:
	subprocess.check_call([sys.executable, "-m", "pip", "install", "requests", "-q"])
	import requests

PROXY = "http://127.0.0.1:7890"
PROXIES = {"http": PROXY, "https": PROXY}
DIR = Path(__file__).resolve().parent / "music"
FFMPEG = r"C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"

DOWNLOADS = [
	("https://opengameart.org/sites/default/files/foolsphilosophy.mp3", "fools_philosophy.mp3"),
	("https://opengameart.org/sites/default/files/Four%20Sequence.mp3", "city_pulse.mp3"),
	("https://opengameart.org/sites/default/files/samurai-nights-by-majadroid.zip", "samurai_nights.zip"),
]


def download(url: str, dest: Path) -> None:
	print(f"GET {dest.name} ...")
	with requests.get(
		url,
		proxies=PROXIES,
		timeout=180,
		headers={"User-Agent": "Mozilla/5.0"},
		stream=True,
	) as r:
		r.raise_for_status()
		total = 0
		with dest.open("wb") as f:
			for chunk in r.iter_content(chunk_size=64 * 1024):
				if chunk:
					f.write(chunk)
					total += len(chunk)
	print(f"  -> {total} bytes")


def mp3_to_ogg(mp3: Path) -> Path:
	ogg = mp3.with_suffix(".ogg")
	subprocess.check_call(
		[FFMPEG, "-y", "-i", str(mp3), "-c:a", "libvorbis", "-q:a", "5", str(ogg)],
		stdout=subprocess.DEVNULL,
		stderr=subprocess.DEVNULL,
	)
	mp3.unlink(missing_ok=True)
	print(f"  ogg {ogg.name} {ogg.stat().st_size}")
	return ogg


def extract_samurai(zip_path: Path) -> None:
	tmp = DIR / "_samurai_tmp"
	if tmp.exists():
		for p in tmp.rglob("*"):
			if p.is_file():
				p.unlink()
		for p in sorted(tmp.rglob("*"), reverse=True):
			if p.is_dir():
				p.rmdir()
		tmp.rmdir()
	tmp.mkdir(parents=True)
	with zipfile.ZipFile(zip_path) as zf:
		zf.extractall(tmp)
	# Prefer a full-loop ogg/mp3 if present
	candidates = list(tmp.rglob("*.ogg")) + list(tmp.rglob("*.mp3")) + list(tmp.rglob("*.wav"))
	print("samurai contents:")
	for c in candidates:
		print(f"  {c.relative_to(tmp)} ({c.stat().st_size})")
	if not candidates:
		print("  no audio found")
		return
	# Prefer filenames suggesting full track / loop
	def score(p: Path) -> int:
		n = p.name.lower()
		s = 0
		if "full" in n or "complete" in n or "main" in n:
			s += 10
		if "loop" in n:
			s += 5
		if p.suffix.lower() == ".ogg":
			s += 3
		if "intro" in n or "stinger" in n:
			s -= 5
		return s + min(p.stat().st_size // 100000, 20)

	best = max(candidates, key=score)
	out = DIR / "samurai_nights.ogg"
	if best.suffix.lower() == ".ogg":
		out.write_bytes(best.read_bytes())
	else:
		subprocess.check_call(
			[FFMPEG, "-y", "-i", str(best), "-c:a", "libvorbis", "-q:a", "5", str(out)],
			stdout=subprocess.DEVNULL,
			stderr=subprocess.DEVNULL,
		)
	print(f"  chose {best.name} -> {out.name} ({out.stat().st_size})")
	zip_path.unlink(missing_ok=True)


def main() -> int:
	DIR.mkdir(parents=True, exist_ok=True)
	# quick probe
	probe = DIR / "_probe_py.ogg"
	try:
		download("https://opengameart.org/sites/default/files/asiansparrow4.ogg", probe)
		print("proxy OK")
		probe.unlink(missing_ok=True)
	except Exception as e:
		print("proxy probe FAIL:", e)
		return 1

	for url, name in DOWNLOADS:
		dest = DIR / name
		try:
			download(url, dest)
		except Exception as e:
			print(f"FAIL {name}: {e}")
			continue
		if name.endswith(".mp3"):
			try:
				mp3_to_ogg(dest)
			except Exception as e:
				print(f"convert FAIL {name}: {e}")
		elif name.endswith(".zip"):
			try:
				extract_samurai(dest)
			except Exception as e:
				print(f"extract FAIL {name}: {e}")
	print("done")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
