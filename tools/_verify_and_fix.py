# -*- coding: utf-8 -*-
import json
import sqlite3
from pathlib import Path
from urllib.parse import unquote

DB = r"C:\Users\Administrator\AppData\Roaming\Cursor\User\globalStorage\state.vscdb"
ROOT = Path(r"f:\Games\New-Life")
TRANSCRIPT_ROOT = Path(r"C:\Users\Administrator\.cursor\projects\f-Games-New-Life\agent-transcripts")
c = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)

cid = "2432752e-1b05-4c3f-a246-d9e7fd54f19d"
diffs = []
for k, v in c.execute(
    "SELECT key,value FROM cursorDiskKV WHERE key LIKE ?",
    (f"ofsContent:{cid}:%",),
):
    uri = k.split(":", 2)[-1]
    s = unquote(uri)
    if s.startswith("file:///"):
        s = s[len("file:///") :]
    p = Path(s)
    text = v.decode("utf-8") if isinstance(v, bytes) else v
    if not text:
        continue
    if not text.endswith("\n"):
        text += "\n"
    if not p.exists():
        diffs.append(("MISSING", str(p)))
        continue
    cur = p.read_text(encoding="utf-8", errors="replace")
    if not cur.endswith("\n"):
        cur += "\n"
    if cur != text:
        diffs.append(("DIFF", str(p), len(text), len(cur)))
print("remaining vs 21:40", len(diffs))
for item in diffs:
    print(item)

# Force EventPanel
contents = None
for cid in [
    "cc3f74ad-d714-4104-b91d-78cb928677b9",
    "f1e233e3-36f1-4d3c-89f9-6b27940b9691",
]:
    p = TRANSCRIPT_ROOT / cid / f"{cid}.jsonl"
    for line in p.read_text(encoding="utf-8").splitlines():
        if "EventPanel.tscn" not in line:
            continue
        o = json.loads(line)
        for part in o.get("message", {}).get("content", []) or []:
            if part.get("type") != "tool_use":
                continue
            path = (part.get("input") or {}).get("path", "")
            if not path.endswith("EventPanel.tscn"):
                continue
            if part.get("name") == "Write":
                contents = part["input"]["contents"]
            elif part.get("name") == "StrReplace" and contents is not None:
                old, new = part["input"].get("old_string"), part["input"].get("new_string")
                if old in contents:
                    contents = contents.replace(old, new, 1)
out = ROOT / "game/ui/EventPanel.tscn"
out.write_text(contents if contents.endswith("\n") else contents + "\n", encoding="utf-8", newline="\n")
print("EventPanel", len(contents), "ContinueLabel", "ContinueLabel" in contents)

# Ensure SfxPlayer fallback still present; if missing, re-patch marker check
sfx = (ROOT / "game/autoload/SfxPlayer.gd").read_text(encoding="utf-8")
print("SfxPlayer imported fallback", "_load_track_from_imported" in sfx)

# Main.tscn quick check
main = (ROOT / "game/scenes/Main.tscn").read_text(encoding="utf-8")
for key in ["SaveSlotPanel", "DossierPanel", "MinimapPanel", "SettingsPanel", "QuestTracker"]:
    print("Main has", key, key in main)
