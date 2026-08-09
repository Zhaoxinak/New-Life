# -*- coding: utf-8 -*-
"""Extract Godot 4.x PCK format v3/v4 (directory at end of file)."""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path


def extract_pck(pck_path: Path, out_dir: Path, *, strip_res: bool = True) -> int:
    data = pck_path.read_bytes()
    if data[:4] != b"GDPC":
        raise SystemExit(f"not a GDPC pack: {pck_path}")

    version, major, minor, patch, flags = struct.unpack_from("<5I", data, 4)
    file_base, dir_offset = struct.unpack_from("<QQ", data, 24)
    print(
        f"PCK v{version} Godot {major}.{minor}.{patch} flags=0x{flags:x} "
        f"file_base={file_base} dir_offset={dir_offset}"
    )
    if dir_offset <= 0 or dir_offset >= len(data):
        raise SystemExit(f"bad dir_offset={dir_offset}")

    off = dir_offset
    (file_count,) = struct.unpack_from("<I", data, off)
    off += 4
    print(f"file_count={file_count}")

    out_dir.mkdir(parents=True, exist_ok=True)
    written = 0
    for i in range(file_count):
        (name_len,) = struct.unpack_from("<I", data, off)
        off += 4
        raw_name = data[off : off + name_len]
        off += name_len
        # trim trailing NULs used for alignment/padding
        name = raw_name.split(b"\x00", 1)[0].decode("utf-8", errors="replace")
        file_ofs, file_size = struct.unpack_from("<QQ", data, off)
        off += 16
        md5 = data[off : off + 16]
        off += 16
        (file_flags,) = struct.unpack_from("<I", data, off)
        off += 4

        if file_flags & 0x2:  # deleted
            continue
        if file_flags & 0x1:
            print(f"skip encrypted: {name}")
            continue

        abs_ofs = file_base + file_ofs
        payload = data[abs_ofs : abs_ofs + file_size]
        if len(payload) != file_size:
            print(f"WARN truncated {name}: want {file_size} got {len(payload)}")

        rel = name
        if strip_res and rel.startswith("res://"):
            rel = rel[len("res://") :]
        elif rel.startswith("user://"):
            rel = Path("@@user@@") / rel[len("user://") :]
        # normalize
        rel = str(rel).replace("\\", "/").lstrip("/")
        dest = out_dir / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(payload)
        written += 1
        if written <= 20 or written % 100 == 0:
            print(f"[{written}/{file_count}] {rel} ({file_size})")

    print(f"done: wrote {written} files -> {out_dir}")
    return written


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("pck", type=Path)
    ap.add_argument("-o", "--out", type=Path, required=True)
    args = ap.parse_args()
    extract_pck(args.pck, args.out)


if __name__ == "__main__":
    main()
