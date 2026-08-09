#!/usr/bin/env python3
"""Generate a short neural TTS clip via edge-tts. Used by VoicePlayer (Godot)."""

from __future__ import annotations

import argparse
import asyncio
import sys
from pathlib import Path


async def _synthesize(text: str, voice: str, out_path: Path, rate: str, pitch: str) -> None:
	import edge_tts

	communicate = edge_tts.Communicate(text, voice, rate=rate, pitch=pitch)
	out_path.parent.mkdir(parents=True, exist_ok=True)
	tmp = out_path.with_suffix(out_path.suffix + ".partial")
	await communicate.save(str(tmp))
	tmp.replace(out_path)


def _load_text(args: argparse.Namespace) -> str:
	if args.text_file:
		return Path(args.text_file).read_text(encoding="utf-8").strip()
	return (args.text or "").strip()


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument("--text", default="")
	parser.add_argument("--text-file", default="")
	parser.add_argument("--voice", required=True)
	parser.add_argument("--out", required=True)
	parser.add_argument("--rate", default="+0%")
	parser.add_argument("--pitch", default="+0Hz")
	parser.add_argument("--timeout", type=float, default=20.0)
	args = parser.parse_args()

	text = _load_text(args)
	if not text:
		print("empty text", file=sys.stderr)
		return 2

	out_path = Path(args.out)
	try:
		asyncio.run(
			asyncio.wait_for(
				_synthesize(text, args.voice, out_path, args.rate, args.pitch),
				timeout=args.timeout,
			)
		)
	except asyncio.TimeoutError:
		print("timeout", file=sys.stderr)
		return 3
	except Exception as exc:  # noqa: BLE001 — surface to Godot stderr
		print(f"error: {exc}", file=sys.stderr)
		return 1

	if not out_path.is_file() or out_path.stat().st_size < 32:
		print("empty output", file=sys.stderr)
		return 4
	print(out_path)
	return 0


if __name__ == "__main__":
	sys.exit(main())
