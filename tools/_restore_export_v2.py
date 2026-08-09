# -*- coding: utf-8 -*-
"""Second-pass restore toward DocksideStorm.pck (~20:15) fidelity.

Uses:
- 2432752e ofsContent (disk snapshot at 21:40 — closest full-file dump after export)
- Earlier composer end-states for files not in that snapshot
- Authoritative CSV/data from _pck_extract
"""
from __future__ import annotations

import json
import shutil
import sqlite3
from pathlib import Path
from urllib.parse import unquote

DB = r"C:\Users\Administrator\AppData\Roaming\Cursor\User\globalStorage\state.vscdb"
ROOT = Path(r"f:\Games\New-Life")
PCK = ROOT / "_pck_extract"
TRANSCRIPT_ROOT = Path(r"C:\Users\Administrator\.cursor\projects\f-Games-New-Life\agent-transcripts")

# Sessions at/before export-adjacent snapshot. Include 2432752e ONLY for ofs baseline (21:40).
PRIOR = [
    "cc3f74ad-d714-4104-b91d-78cb928677b9",
    "f1e233e3-36f1-4d3c-89f9-6b27940b9691",
    "efc64d10-dd64-46e7-8da5-e065ee4ea804",
    "8e0c7ac0-393e-46f5-be79-a87c4d6e85bb",
    "1ff3a3fc-e21c-4af1-97f6-3d0722de2820",
    "868e8f0f-87d9-4f31-9a35-da5a45beeecb",
    "c6077698-1090-48ca-9180-f715ae220ec9",
    "d4682b4a-25ba-4ec9-9d3f-2dd202ff0929",
    "f68a44e0-ea26-4794-93b2-79e8a501b405",
]
SNAP_2140 = "2432752e-1b05-4c3f-a246-d9e7fd54f19d"

c = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)


def uri_to_path(uri: str) -> Path:
    s = unquote(uri)
    if s.startswith("file:///"):
        s = s[len("file:///") :]
    elif s.startswith("file://"):
        s = s[len("file://") :]
    return Path(s)


def get_ofs(cid: str, file_uri: str) -> str | None:
    row = c.execute(
        "SELECT value FROM cursorDiskKV WHERE key=?",
        (f"ofsContent:{cid}:{file_uri}",),
    ).fetchone()
    if not row:
        return None
    v = row[0]
    return v.decode("utf-8") if isinstance(v, bytes) else v


def apply_diff(v0_text: str, diffs: list) -> str:
    bare = v0_text.split("\n")
    if bare and bare[-1] == "":
        bare = bare[:-1]
    for d in sorted(diffs, key=lambda x: x["original"]["startLineNumber"], reverse=True):
        start = d["original"]["startLineNumber"] - 1
        end = d["original"]["endLineNumberExclusive"] - 1
        bare[start:end] = d.get("modified") or []
    out = "\n".join(bare)
    return out if out.endswith("\n") else out + "\n"


def latest_checkpoint(cid: str):
    rows = c.execute(
        "SELECT value FROM cursorDiskKV WHERE key LIKE ? ORDER BY length(value) DESC",
        (f"checkpointId:{cid}:%",),
    ).fetchall()
    if not rows:
        return None
    best = None
    for (v,) in rows:
        obj = json.loads(v if isinstance(v, str) else v.decode("utf-8"))
        score = (len(obj.get("files") or []), len(v if isinstance(v, str) else v))
        if best is None or score > best[0]:
            best = (score, obj)
    return best[1]


def ofs_baseline(cid: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for k, v in c.execute(
        "SELECT key, value FROM cursorDiskKV WHERE key LIKE ?",
        (f"ofsContent:{cid}:%",),
    ):
        uri = k.split(":", 2)[-1]
        text = v.decode("utf-8") if isinstance(v, bytes) else v
        if text:
            out[str(uri_to_path(uri))] = text if text.endswith("\n") else text + "\n"
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


def extract_writes(cids: list[str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for cid in cids:
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
                    path, contents = inp.get("path"), inp.get("contents")
                    if path and isinstance(contents, str):
                        out[str(Path(path))] = (
                            contents if contents.endswith("\n") else contents + "\n"
                        )
    return out


def under_root(path_str: str) -> Path | None:
    p = Path(path_str)
    try:
        rel = p.relative_to(ROOT).as_posix()
    except ValueError:
        return None
    if rel.startswith("demo_ai_town/") or rel.startswith("_") or rel.startswith(".tools/"):
        return None
    return p


def main() -> None:
    files: dict[str, str] = {}

    # 1) prior sessions build up to export
    for cid in PRIOR:
        base = ofs_baseline(cid)
        end = materialize_end(cid)
        print(f"{cid[:8]} ofs={len(base)} end={len(end)}")
        files.update(base)
        files.update(end)

    # 2) force 21:40 full-file snapshot on top (best near-export dump)
    snap = ofs_baseline(SNAP_2140)
    print(f"21:40 snap ofs={len(snap)}")
    files.update(snap)

    # 3) transcript writes for known new files (last wins)
    writes = extract_writes(PRIOR + [SNAP_2140])
    # Prefer larger Write for same path when current is stubby
    for path, text in writes.items():
        cur = files.get(path)
        if cur is None or len(text) > len(cur) + 50:
            files[path] = text

    # Critical forced recoveries from known-good transcript chains
    force_scripts = {
        "UnlockScheduler.gd": "func pending_reason",
        "QuestTracker.tscn": 'name="Shell"',
        "DebugPanel.tscn": 'name="Content"',
        "EventPanel.tscn": 'name="ContinueLabel"',
    }
    for name, marker in force_scripts.items():
        # pick largest write containing marker from PRIOR transcripts
        best = None
        for cid in PRIOR:
            p = TRANSCRIPT_ROOT / cid / f"{cid}.jsonl"
            if not p.exists():
                continue
            content = None
            for line in p.read_text(encoding="utf-8").splitlines():
                if name not in line:
                    continue
                try:
                    o = json.loads(line)
                except Exception:
                    continue
                for part in o.get("message", {}).get("content", []) or []:
                    if part.get("type") != "tool_use":
                        continue
                    path = (part.get("input") or {}).get("path", "")
                    if not path.endswith(name):
                        continue
                    if part.get("name") == "Write":
                        content = part["input"]["contents"]
                    elif part.get("name") == "StrReplace" and content is not None:
                        old, new = part["input"].get("old_string"), part["input"].get("new_string")
                        if old in content:
                            content = content.replace(old, new, 1)
            if content and marker in content and (best is None or len(content) > len(best[1])):
                best = (cid, content)
        if best:
            # resolve path from files keys or default under game/
            target = None
            for k in files:
                if k.replace("\\", "/").endswith(name):
                    target = k
                    break
            if target is None:
                if name.endswith(".tscn") or name.endswith(".gd"):
                    if name.startswith("Unlock"):
                        target = str(ROOT / "game/systems" / name)
                    else:
                        target = str(ROOT / "game/ui" / name)
            files[target] = best[1] if best[1].endswith("\n") else best[1] + "\n"
            print(f"forced {name} from {best[0][:8]} len={len(best[1])}")

    written = 0
    for path_str, text in files.items():
        path = under_root(path_str)
        if path is None:
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8", newline="\n")
        written += 1
    print(f"wrote {written} text files")

    # 4) PCK data authoritative
    src = PCK / "data" / "packs"
    n = 0
    if src.is_dir():
        for dest_root in (ROOT / "game/data/packs", ROOT / "docs/tables/packs"):
            for f in src.rglob("*"):
                if f.is_file():
                    d = dest_root / f.relative_to(src)
                    d.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(f, d)
                    n += 1
    print(f"overlayed {n} pack files from PCK")

    # 5) FRAME_W fix
    for rel in ("game/world/Player.gd", "game/world/OutdoorNpc.gd", "game/world/AmbientNpc.gd"):
        p = ROOT / rel
        if p.exists():
            t = p.read_text(encoding="utf-8")
            if "const FRAME_W := 64" in t:
                p.write_text(t.replace("const FRAME_W := 64", "const FRAME_W := 66"), encoding="utf-8", newline="\n")
                print("fixed FRAME_W", rel)

    important = [
        "game/ui/PlayChrome.gd",
        "game/scenes/Main.tscn",
        "game/systems/NpcScheduler.gd",
        "game/world/maps/town/TownPortalCatalog.gd",
        "game/world/maps/town/interiors/InteriorRoom.gd",
        "game/autoload/SaveSystem.gd",
        "game/systems/UnlockScheduler.gd",
    ]
    for rel in important:
        p = ROOT / rel
        print(f"  {rel}: exists={p.exists()} size={p.stat().st_size if p.exists() else 0}")


if __name__ == "__main__":
    main()
