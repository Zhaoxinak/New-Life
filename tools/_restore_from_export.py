# -*- coding: utf-8 -*-
"""Restore New-Life working tree to match builds/DocksideStorm.pck (~2026-08-09 20:15).

Strategy:
1) Replay Cursor composer checkpoints through the export-time session end (f68a44e0 @ 20:14).
2) Overlay authoritative CSV/data from the extracted PCK.
3) Keep demo_ai_town untouched.
"""
from __future__ import annotations

import json
import shutil
import sqlite3
from collections import defaultdict
from pathlib import Path
from urllib.parse import unquote

DB = r"C:\Users\Administrator\AppData\Roaming\Cursor\User\globalStorage\state.vscdb"
ROOT = Path(r"f:\Games\New-Life")
TRANSCRIPT_ROOT = Path(r"C:\Users\Administrator\.cursor\projects\f-Games-New-Life\agent-transcripts")
PCK_EXTRACT = ROOT / "_pck_extract"

# Sessions up to and including the export-time save/load session.
REPLAY = [
    "cc3f74ad-d714-4104-b91d-78cb928677b9",
    "f1e233e3-36f1-4d3c-89f9-6b27940b9691",
    "efc64d10-dd64-46e7-8da5-e065ee4ea804",
    "8e0c7ac0-393e-46f5-be79-a87c4d6e85bb",
    "1ff3a3fc-e21c-4af1-97f6-3d0722de2820",
    "868e8f0f-87d9-4f31-9a35-da5a45beeecb",
    "c6077698-1090-48ca-9180-f715ae220ec9",
    "d4682b4a-25ba-4ec9-9d3f-2dd202ff0929",
    "f68a44e0-ea26-4794-93b2-79e8a501b405",  # ends ~20:14, matches PCK mtime
]

NEWFILE_NAMES = {
    "PILLARS_PLAN.md",
    "FREEDOM_PLAN.md",
    "DIVORCE_PLAN.md",
    "IMPROVEMENT_PLAN.md",
    "STAGING_PLAN.md",
    "PromotionSystem.gd",
    "promotion_gates.csv",
    "_impl_pillars.py",
    "GameSettings.gd",
    "SettingsPanel.gd",
    "SettingsPanel.tscn",
    "VoicePlayer.gd",
    "EventStaging.gd",
    "SaveSlotPanel.gd",
    "SaveSlotPanel.tscn",
    "NpcScheduler.gd",
    "WeatherSystem.gd",
    "RelationJournal.gd",
    "DossierPanel.gd",
    "DossierPanel.tscn",
    "MinimapPanel.gd",
    "MinimapPanel.tscn",
    "ArcadePanel.gd",
    "ArcadePanel.tscn",
    "TransitPanel.gd",
    "TransitPanel.tscn",
    "VehicleProp.gd",
    "TransitStop.gd",
    "TransitStop.tscn",
    "OutdoorNpc.gd",
    "OutdoorNpc.tscn",
    "AtmosphereFx.gd",
    "NpcCottage.gd",
    "edge_tts_speak.py",
    "requirements-voice.txt",
}

c = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)


def uri_to_path(uri: str) -> Path:
    s = unquote(uri)
    if s.startswith("file:///"):
        s = s[len("file:///") :]
    elif s.startswith("file://"):
        s = s[len("file://") :]
    return Path(s)


def get_ofs(cid: str, file_uri: str) -> str | None:
    key = f"ofsContent:{cid}:{file_uri}"
    row = c.execute("SELECT value FROM cursorDiskKV WHERE key=?", (key,)).fetchone()
    if not row:
        return None
    v = row[0]
    return v.decode("utf-8") if isinstance(v, bytes) else v


def apply_diff(v0_text: str, diffs: list) -> str:
    bare = v0_text.split("\n")
    if bare and bare[-1] == "":
        bare = bare[:-1]
    ordered = sorted(diffs, key=lambda d: d["original"]["startLineNumber"], reverse=True)
    for d in ordered:
        start = d["original"]["startLineNumber"] - 1
        end = d["original"]["endLineNumberExclusive"] - 1
        bare[start:end] = d.get("modified") or []
    out = "\n".join(bare)
    if not out.endswith("\n"):
        out += "\n"
    return out


def latest_checkpoint(cid: str):
    rows = c.execute(
        "SELECT key, value FROM cursorDiskKV WHERE key LIKE ? ORDER BY length(value) DESC",
        (f"checkpointId:{cid}:%",),
    ).fetchall()
    if not rows:
        return None
    best = None
    for _k, v in rows:
        obj = json.loads(v if isinstance(v, str) else v.decode("utf-8"))
        score = (len(obj.get("files") or []), len(v if isinstance(v, str) else v))
        if best is None or score > best[0]:
            best = (score, obj)
    return best[1]


def ofs_baseline(cid: str) -> dict[str, str]:
    out: dict[str, str] = {}
    rows = c.execute(
        "SELECT key, value FROM cursorDiskKV WHERE key LIKE ?",
        (f"ofsContent:{cid}:%",),
    ).fetchall()
    for k, v in rows:
        uri = k.split(":", 2)[-1]
        path = str(uri_to_path(uri))
        text = v.decode("utf-8") if isinstance(v, bytes) else v
        if not text:
            continue
        out[path] = text if text.endswith("\n") else text + "\n"
    return out


def materialize_end(cid: str) -> dict[str, str]:
    out: dict[str, str] = {}
    cp = latest_checkpoint(cid)
    if cp is None:
        return out
    for f in cp.get("files") or []:
        uri = f["uri"]["external"]
        path = str(uri_to_path(uri))
        diffs = f.get("originalModelDiffWrtV0") or []
        v0 = get_ofs(cid, uri)
        if v0 is None:
            continue
        if f.get("isNewlyCreated") and (not v0) and not any(d.get("modified") for d in diffs):
            continue
        final = apply_diff(v0, diffs) if diffs else v0
        if final.strip() == "" and f.get("isNewlyCreated"):
            continue
        out[path] = final if final.endswith("\n") else final + "\n"
    return out


def extract_writes(composer_ids: list[str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for cid in composer_ids:
        p = TRANSCRIPT_ROOT / cid / f"{cid}.jsonl"
        if not p.exists():
            continue
        for line in p.read_text(encoding="utf-8").splitlines():
            if '"name":"Write"' not in line:
                continue
            try:
                o = json.loads(line)
            except Exception:
                continue
            for part in o.get("message", {}).get("content", []) or []:
                if part.get("type") == "tool_use" and part.get("name") == "Write":
                    inp = part.get("input") or {}
                    path = inp.get("path")
                    contents = inp.get("contents")
                    if path and isinstance(contents, str):
                        out[str(Path(path))] = (
                            contents if contents.endswith("\n") else contents + "\n"
                        )
    return out


def write_text_files(files: dict[str, str]) -> int:
    n = 0
    for path_str, text in files.items():
        path = Path(path_str)
        try:
            rel = path.relative_to(ROOT).as_posix()
        except ValueError:
            continue
        if rel.startswith("demo_ai_town/") or rel.startswith("_"):
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8", newline="\n")
        n += 1
    return n


def overlay_pck_data() -> int:
    src = PCK_EXTRACT / "data" / "packs"
    if not src.is_dir():
        print("WARN: no PCK data/packs")
        return 0
    targets = [
        ROOT / "game" / "data" / "packs",
        ROOT / "docs" / "tables" / "packs",
    ]
    n = 0
    for dst_root in targets:
        for f in src.rglob("*"):
            if not f.is_file():
                continue
            rel = f.relative_to(src)
            dest = dst_root / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            n += 1
    print(f"overlayed {n} pack files into game/data/packs + docs/tables/packs")
    return n


def overlay_pck_import_sidecars() -> int:
    """Copy .import stubs and project.binary helpers; art binaries stay in .godot if present."""
    n = 0
    art = PCK_EXTRACT / "art"
    if art.is_dir():
        for f in art.rglob("*.import"):
            rel = f.relative_to(PCK_EXTRACT)
            dest = ROOT / "game" / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, dest)
            n += 1
    # Copy exported .godot imported textures so missing pngs still resolve after reimport? 
    # Better: copy ctex into game/.godot/imported
    imp = PCK_EXTRACT / ".godot" / "imported"
    if imp.is_dir():
        dest_imp = ROOT / "game" / ".godot" / "imported"
        dest_imp.mkdir(parents=True, exist_ok=True)
        for f in imp.rglob("*"):
            if f.is_file():
                d = dest_imp / f.relative_to(imp)
                d.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(f, d)
                n += 1
    audio = PCK_EXTRACT / "audio"
    if audio.is_dir():
        for f in audio.rglob("*"):
            if f.is_file():
                d = ROOT / "game" / "audio" / f.relative_to(audio)
                d.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(f, d)
                n += 1
    print(f"overlayed {n} art/audio/import assets from PCK")
    return n


def main() -> None:
    files: dict[str, str] = {}
    for cid in REPLAY:
        base = ofs_baseline(cid)
        end = materialize_end(cid)
        print(f"{cid[:8]} ofs={len(base)} end={len(end)}")
        files.update(base)
        files.update(end)

    writes = extract_writes(REPLAY)
    print(f"transcript writes={len(writes)}")
    for path, text in writes.items():
        name = Path(path).name
        if path not in files or name in NEWFILE_NAMES:
            files[path] = text

    # Special: UnlockScheduler from 868e (known critical)
    # already covered by writes/checkpoints if present

    written = write_text_files(files)
    print(f"wrote {written} text files from checkpoints/transcripts")

    overlay_pck_data()
    overlay_pck_import_sidecars()

    # Ensure SaveSlot / Export docs present markers
    important = [
        "game/autoload/SaveSystem.gd",
        "game/ui/SaveSlotPanel.gd",
        "game/ui/SaveSlotPanel.tscn",
        "game/systems/PromotionSystem.gd",
        "game/systems/UnlockScheduler.gd",
        "game/data/packs/core/quests.csv",
        "docs/tables/packs/core/quests.csv",
        "docs/PILLARS_PLAN.md",
    ]
    print("\nImportant:")
    for rel in important:
        p = ROOT / rel
        print(f"  {rel}: exists={p.exists()} size={p.stat().st_size if p.exists() else 0}")


if __name__ == "__main__":
    main()
