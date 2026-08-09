# -*- coding: utf-8 -*-
"""Deep restore audit: full GDRE tree vs game, refs, docs sync, asset integrity."""
from __future__ import annotations

import hashlib
import json
import re
import struct
from collections import Counter
from pathlib import Path

ROOT = Path(r"f:/Games/New-Life")
PCK = ROOT / "_pck_extract"
GDRE = ROOT / "_gdre_recover"
GAME = ROOT / "game"
DOCS = ROOT / "docs" / "tables" / "packs"

SKIP_PREFIX = (".godot/", ".autoconverted/")
CONTENT_EXT = {
    ".gd",
    ".tscn",
    ".csv",
    ".png",
    ".ogg",
    ".json",
    ".svg",
    ".godot",
    ".cfg",
    ".md",
    ".txt",
}


def rel_files(base: Path) -> dict[str, Path]:
    out: dict[str, Path] = {}
    for p in base.rglob("*"):
        if not p.is_file():
            continue
        rel = p.relative_to(base).as_posix()
        if rel.startswith(SKIP_PREFIX):
            continue
        if rel == "gdre_export.log":
            continue
        out[rel] = p
    return out


def main() -> None:
    gdre = rel_files(GDRE)
    game = rel_files(GAME)

    gdre_content = {
        r: p
        for r, p in gdre.items()
        if Path(r).suffix.lower() in CONTENT_EXT or r == "project.godot"
    }

    issues: list[tuple] = []
    ok_by_cat: Counter = Counter()

    for rel, gp in sorted(gdre_content.items()):
        cat = Path(rel).suffix.lower().lstrip(".") or "other"
        if rel == "project.godot":
            cat = "project"
        gp_game = game.get(rel)
        if not gp_game:
            issues.append(("FAIL", cat, rel, "missing in game"))
            continue
        if gp.read_bytes() == gp_game.read_bytes():
            ok_by_cat[cat] += 1
        else:
            issues.append(
                (
                    "DIFF",
                    cat,
                    rel,
                    f"size gdre={gp.stat().st_size} game={gp_game.stat().st_size}",
                )
            )

    extras = []
    for rel in sorted(game):
        if Path(rel).suffix.lower() not in CONTENT_EXT and rel != "project.godot":
            continue
        if rel not in gdre_content:
            extras.append(rel)

    docs_issues: list[tuple] = []
    if DOCS.exists() and (GAME / "data" / "packs").exists():
        for p in (GAME / "data" / "packs").rglob("*"):
            if not p.is_file() or p.suffix.lower() not in {".csv", ".json"}:
                continue
            rel = p.relative_to(GAME / "data" / "packs").as_posix()
            d = DOCS / rel
            if not d.exists():
                docs_issues.append(("docs_missing", rel))
            elif d.read_bytes() != p.read_bytes():
                docs_issues.append(("docs_diff", rel))
        for p in DOCS.rglob("*"):
            if not p.is_file() or p.suffix.lower() not in {".csv", ".json"}:
                continue
            rel = p.relative_to(DOCS).as_posix()
            if not (GAME / "data" / "packs" / rel).exists():
                docs_issues.append(("game_missing_vs_docs", rel))

    ref_re = re.compile(
        r"res://([A-Za-z0-9_./\\-]+\.(?:gd|tscn|png|ogg|svg|csv|json|tres|res|wav|mp3))"
    )
    missing_refs: list[tuple[str, str]] = []
    checked_refs = 0
    for rel in gdre_content:
        if not rel.endswith((".gd", ".tscn")):
            continue
        text = (GAME / rel).read_text(encoding="utf-8", errors="replace")
        for m in ref_re.finditer(text):
            target = m.group(1).replace("\\", "/")
            checked_refs += 1
            exists = (GAME / target).exists()
            if not exists and target.startswith("data/packs/"):
                exists = (DOCS / target[len("data/packs/") :]).exists()
            if not exists:
                missing_refs.append((rel, target))

    png_bad: list[tuple] = []
    png_info: list[tuple] = []
    for rel in sorted(r for r in gdre_content if r.endswith(".png")):
        data = (GAME / rel).read_bytes()
        if data[:8] != b"\x89PNG\r\n\x1a\n":
            png_bad.append((rel, "bad signature"))
            continue
        w, h = struct.unpack(">II", data[16:24])
        png_info.append((rel, w, h, len(data)))

    ogg_bad = []
    for rel in sorted(r for r in gdre_content if r.endswith(".ogg")):
        if (GAME / rel).read_bytes()[:4] != b"OggS":
            ogg_bad.append(rel)

    pg = (GAME / "project.godot").read_text(encoding="utf-8", errors="replace")
    autoload_missing = []
    for line in pg.splitlines():
        if '="*res://' in line or '="res://' in line:
            m = re.search(r'res://([^"]+)', line)
            if m and not (GAME / m.group(1)).exists():
                autoload_missing.append(m.group(1))

    pck_gd = {
        p.relative_to(PCK).as_posix().replace(".gd.remap", ".gd")
        for p in PCK.rglob("*.gd.remap")
    }
    pck_tscn = {
        p.relative_to(PCK).as_posix().replace(".tscn.remap", ".tscn")
        for p in PCK.rglob("*.tscn.remap")
    }
    game_gd = {
        p.relative_to(GAME).as_posix()
        for p in GAME.rglob("*.gd")
        if ".godot" not in p.parts
    }
    game_tscn = {
        p.relative_to(GAME).as_posix()
        for p in GAME.rglob("*.tscn")
        if ".godot" not in p.parts
    }

    # preload/load path strings without res://
    load_re = re.compile(
        r'(?:preload|load)\(\s*"([^"]+\.(?:gd|tscn|png|ogg|svg|csv))"\s*\)'
    )
    load_missing = []
    for rel in gdre_content:
        if not rel.endswith(".gd"):
            continue
        text = (GAME / rel).read_text(encoding="utf-8", errors="replace")
        for m in load_re.finditer(text):
            target = m.group(1).replace("res://", "")
            if not (GAME / target).exists():
                load_missing.append((rel, target))

    # Compare recovered PNGs vs PCK .import source path existence
    import_paths_ok = []
    import_paths_bad = []
    for imp in (PCK / "art").rglob("*.import") if (PCK / "art").exists() else []:
        text = imp.read_text(encoding="utf-8", errors="replace")
        # source path line: path="res://art/..."
        m = re.search(r'path="res://([^"]+)"', text)
        src = m.group(1) if m else None
        if not src:
            # Godot 4 import often has source_file=
            m2 = re.search(r'source_file="res://([^"]+)"', text)
            src = m2.group(1) if m2 else None
        if not src:
            continue
        if (GAME / src).exists():
            import_paths_ok.append(src)
        else:
            import_paths_bad.append(src)

    for imp in (PCK / "audio").rglob("*.import") if (PCK / "audio").exists() else []:
        text = imp.read_text(encoding="utf-8", errors="replace")
        m2 = re.search(r'source_file="res://([^"]+)"', text)
        if not m2:
            m2 = re.search(r'path="res://([^"]+\.ogg)"', text)
        if not m2:
            continue
        src = m2.group(1)
        if (GAME / src).exists():
            import_paths_ok.append(src)
        else:
            import_paths_bad.append(src)

    small_png = [(r, s, w, h) for r, w, h, s in png_info if s < 8000]

    # Scene ext_resource script paths
    scene_script_missing = []
    for rel in sorted(r for r in gdre_content if r.endswith(".tscn")):
        text = (GAME / rel).read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r'path="res://([^"]+\.gd)"', text):
            if not (GAME / m.group(1)).exists():
                scene_script_missing.append((rel, m.group(1)))

    report = {
        "ok_by_cat": dict(ok_by_cat),
        "ok_total": sum(ok_by_cat.values()),
        "issue_count": len(issues),
        "issues": [{"status": a, "cat": b, "path": c, "notes": d} for a, b, c, d in issues],
        "extras_in_game_not_gdre": extras,
        "docs_issue_count": len(docs_issues),
        "docs_issues": [{"kind": a, "path": b} for a, b in docs_issues],
        "missing_ref_count": len(missing_refs),
        "missing_refs": [{"from": a, "to": b} for a, b in missing_refs],
        "load_missing": [{"from": a, "to": b} for a, b in load_missing],
        "refs_checked": checked_refs,
        "png_bad": png_bad,
        "ogg_bad": ogg_bad,
        "png_count": len(png_info),
        "png_info": [{"path": r, "w": w, "h": h, "bytes": s} for r, w, h, s in png_info],
        "small_png": [{"path": r, "bytes": s, "w": w, "h": h} for r, s, w, h in small_png],
        "autoload_missing": autoload_missing,
        "script_set_equal": pck_gd == game_gd,
        "scene_set_equal": pck_tscn == game_tscn,
        "only_game_gd": sorted(game_gd - pck_gd),
        "only_pck_gd": sorted(pck_gd - game_gd),
        "only_game_tscn": sorted(game_tscn - pck_tscn),
        "only_pck_tscn": sorted(pck_tscn - game_tscn),
        "icon_same": (GDRE / "icon.svg").read_bytes() == (GAME / "icon.svg").read_bytes(),
        "import_paths_ok": len(import_paths_ok),
        "import_paths_bad": import_paths_bad,
        "scene_script_missing": scene_script_missing,
        "gdre_content_files": len(gdre_content),
        "main_scene_exists": (GAME / "ui" / "TitleMenu.tscn").exists(),
    }
    out = ROOT / "_restore_deep_audit.json"
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    print("OK_TOTAL", report["ok_total"], report["ok_by_cat"])
    print("ISSUES", report["issue_count"])
    print("EXTRAS", extras)
    print("DOCS_ISSUES", report["docs_issue_count"])
    print("MISSING_REFS", report["missing_ref_count"], "checked", checked_refs)
    print("LOAD_MISSING", len(load_missing))
    print("PNG_BAD", png_bad, "OGG_BAD", ogg_bad)
    print("SMALL_PNG", len(small_png))
    for x in small_png:
        print(" ", x)
    print("AUTOLOAD_MISSING", autoload_missing)
    print("SCRIPT_SET", report["script_set_equal"], "SCENE_SET", report["scene_set_equal"])
    print("IMPORT_BAD", import_paths_bad)
    print("SCENE_SCRIPT_MISSING", scene_script_missing)
    print("ICON", report["icon_same"], "MAIN", report["main_scene_exists"])


if __name__ == "__main__":
    main()
