# -*- coding: utf-8 -*-
"""Audit game/ against DocksideStorm.pck via GDRE recovery ground truth."""
from __future__ import annotations

import hashlib
import json
from collections import Counter
from pathlib import Path

ROOT = Path(r"f:/Games/New-Life")
PCK_EXTRACT = ROOT / "_pck_extract"
GDRE = ROOT / "_gdre_recover"
GAME = ROOT / "game"


def sha16(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()[:16]


def main() -> None:
    pck_scripts = sorted(
        {
            p.relative_to(PCK_EXTRACT).as_posix().replace(".gd.remap", ".gd")
            for p in PCK_EXTRACT.rglob("*.gd.remap")
        }
    )
    pck_scenes = sorted(
        {
            p.relative_to(PCK_EXTRACT).as_posix().replace(".tscn.remap", ".tscn")
            for p in PCK_EXTRACT.rglob("*.tscn.remap")
        }
    )
    pck_csv = sorted(
        p.relative_to(PCK_EXTRACT / "data" / "packs").as_posix()
        for p in (PCK_EXTRACT / "data" / "packs").rglob("*.csv")
    )
    pck_art = sorted(
        p.relative_to(PCK_EXTRACT).as_posix()[: -len(".import")]
        for p in (PCK_EXTRACT / "art").rglob("*.import")
    )
    pck_music = sorted(
        p.name.replace(".ogg.import", "")
        for p in (PCK_EXTRACT / "audio" / "music").glob("*.ogg.import")
    )

    rows: list[dict] = []

    def add(cat: str, path: str, status: str, notes: str = "", detail: str = "") -> None:
        rows.append(
            {
                "cat": cat,
                "path": path,
                "status": status,
                "notes": notes,
                "detail": detail,
            }
        )

    # scripts
    for rel in pck_scripts:
        gdre_p, game_p = GDRE / rel, GAME / rel
        if not gdre_p.exists() or not game_p.exists():
            missing = []
            if not gdre_p.exists():
                missing.append("GDRE")
            if not game_p.exists():
                missing.append("game")
            add("script", rel, "FAIL", "missing: " + ",".join(missing))
        elif gdre_p.read_bytes() == game_p.read_bytes():
            add("script", rel, "OK", "matches GDRE decompile")
        else:
            add(
                "script",
                rel,
                "DIFF",
                "game != GDRE",
                f"game={game_p.stat().st_size} gdre={gdre_p.stat().st_size}",
            )

    # scenes
    for rel in pck_scenes:
        gdre_p, game_p = GDRE / rel, GAME / rel
        if not gdre_p.exists() or not game_p.exists():
            missing = []
            if not gdre_p.exists():
                missing.append("GDRE")
            if not game_p.exists():
                missing.append("game")
            add("scene", rel, "FAIL", "missing: " + ",".join(missing))
        elif gdre_p.read_bytes() == game_p.read_bytes():
            add("scene", rel, "OK", "matches GDRE text scene")
        else:
            add(
                "scene",
                rel,
                "DIFF",
                "game != GDRE",
                f"game={game_p.stat().st_size} gdre={gdre_p.stat().st_size}",
            )

    # csv
    for rel in pck_csv:
        pck_p = PCK_EXTRACT / "data" / "packs" / rel
        game_p = GAME / "data" / "packs" / rel
        docs_p = ROOT / "docs" / "tables" / "packs" / rel
        gdre_p = GDRE / "data" / "packs" / rel
        notes = []
        status = "OK"
        pck_bytes = pck_p.read_bytes()
        for label, p in (("game", game_p), ("docs", docs_p), ("gdre", gdre_p)):
            if not p.exists():
                status = "FAIL"
                notes.append(f"{label} missing")
            elif p.read_bytes() != pck_bytes:
                if status == "OK":
                    status = "DIFF"
                notes.append(f"{label}!=pck ({p.stat().st_size}/{len(pck_bytes)})")
        add("csv", f"data/packs/{rel}", status, "; ".join(notes) or "matches PCK bytes")

    # art
    for rel in pck_art:
        gdre_p, game_p = GDRE / rel, GAME / rel
        if not gdre_p.exists() or not game_p.exists():
            missing = []
            if not gdre_p.exists():
                missing.append("GDRE")
            if not game_p.exists():
                missing.append("game")
            add("art", rel, "FAIL", "missing: " + ",".join(missing))
        elif sha16(gdre_p) == sha16(game_p):
            add("art", rel, "OK", "hash matches GDRE export", f"{game_p.stat().st_size} bytes")
        else:
            add(
                "art",
                rel,
                "DIFF",
                "hash mismatch",
                f"game={game_p.stat().st_size} gdre={gdre_p.stat().st_size}",
            )

    # music
    for name in pck_music:
        rel = f"audio/music/{name}.ogg"
        gdre_p, game_p = GDRE / rel, GAME / rel
        if not gdre_p.exists() or not game_p.exists():
            missing = []
            if not gdre_p.exists():
                missing.append("GDRE")
            if not game_p.exists():
                missing.append("game")
            add("music", rel, "FAIL", "missing: " + ",".join(missing))
        elif sha16(gdre_p) == sha16(game_p):
            add("music", rel, "OK", "hash matches GDRE", f"{game_p.stat().st_size} bytes")
        else:
            add("music", rel, "DIFF", "hash mismatch")

    # project.godot
    pg_g, pg_d = GDRE / "project.godot", GAME / "project.godot"
    if not pg_g.exists() or not pg_d.exists():
        add("project", "project.godot", "FAIL", "missing")
    elif pg_g.read_bytes() == pg_d.read_bytes():
        add("project", "project.godot", "OK", "matches GDRE")
    else:
        add(
            "project",
            "project.godot",
            "DIFF",
            "game != GDRE",
            f"game={pg_d.stat().st_size} gdre={pg_g.stat().st_size}",
        )

    # structural extras in game not from PCK (informational)
    pck_rel_set = set(pck_scripts) | set(pck_scenes) | set(pck_art) | {
        f"audio/music/{m}.ogg" for m in pck_music
    }
    extras = []
    for p in GAME.rglob("*"):
        if not p.is_file():
            continue
        rel = p.relative_to(GAME).as_posix()
        if rel.startswith(".godot/") or rel.startswith(".autoconverted/"):
            continue
        if rel.endswith((".uid", ".import", ".md", ".py", ".txt", ".cfg", ".json", ".svg")):
            continue
        if rel.endswith((".gd", ".tscn", ".png", ".ogg")) and rel not in pck_rel_set:
            extras.append(rel)
        # CSV must match PCK inventory (catch post-export leftovers under data/)
        if rel.endswith(".csv") and rel.startswith("data/packs/"):
            rel_under_packs = rel[len("data/packs/") :]
            if rel_under_packs not in pck_csv:
                extras.append(rel)

    summary = dict(Counter(r["status"] for r in rows))
    out = {
        "source": "builds/DocksideStorm.pck via GDRE full recover",
        "pck_mtime": "2026-08-09 20:15:47",
        "summary": summary,
        "total": len(rows),
        "rows": rows,
        "extras_in_game_not_in_pck": sorted(extras)[:80],
        "extras_count": len(extras),
        "limits": [
            "PCK stores compiled .gdc/.scn; source text comes from GDRE decompile (semantically equivalent, formatting may differ from pre-export hand-written source).",
            "Texture/audio recovery from imported formats can be lossy for 1 asset (GDRE reported Lossy: 1).",
            "demo_ai_town is intentionally outside the export and not part of this audit.",
        ],
    }
    path = ROOT / "_restore_audit.json"
    path.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
    print("TOTAL", len(rows), summary)
    print("FAIL", sum(1 for r in rows if r["status"] == "FAIL"))
    print("DIFF", sum(1 for r in rows if r["status"] == "DIFF"))
    print("OK", sum(1 for r in rows if r["status"] == "OK"))
    print("extras", len(extras))
    for r in rows:
        if r["status"] != "OK":
            print(r["status"], r["cat"], r["path"], r["notes"], r.get("detail", ""))


if __name__ == "__main__":
    main()
