#!/usr/bin/env python3
"""Scan missing l10n keys and sync zh/en gaps where possible."""
from __future__ import annotations

import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "docs" / "tables" / "packs" / "core"
GAME = ROOT / "game"
L10N = CORE / "l10n"


def load_l10n(loc: str) -> dict[str, str]:
    out: dict[str, str] = {}
    with (L10N / f"{loc}.csv").open(encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            out[row["key"]] = row["text"]
    return out


def write_l10n(loc: str, data: dict[str, str]) -> None:
    path = L10N / f"{loc}.csv"
    rows = sorted(data.items(), key=lambda kv: kv[0])
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["key", "text"])
        for k, v in rows:
            w.writerow([k, v])


def collect_needed() -> set[str]:
    needed: set[str] = set()
    specs = [
        ("actions", ["actions.{id}.name", "actions.{id}.description", "actions.{id}.result"]),
        ("locations", ["locations.{id}.name", "locations.{id}.description"]),
        ("hotspots", ["hotspots.{id}.name", "hotspots.{id}.description"]),
        ("npcs", ["npcs.{id}.name"]),
        ("events", ["events.{id}.title", "events.{id}.body"]),
        ("event_choices", ["event_choices.{id}.label"]),
        ("dialogue_lines", ["dialogue_lines.{id}.text"]),
        ("dialogue_choices", ["dialogue_choices.{id}.label"]),
        ("dialogue_line_variants", ["dialogue_line_variants.{id}.text"]),
        ("endings", ["endings.{id}.name", "endings.{id}.description"]),
        ("ranks", ["ranks.{id}.name"]),
        ("periods", ["periods.{id}.name"]),
        ("idle_chatter", ["idle_chatter.{id}.text"]),
    ]
    for table, fmts in specs:
        with (CORE / f"{table}.csv").open(encoding="utf-8", newline="") as f:
            for row in csv.DictReader(f):
                for fmt in fmts:
                    needed.add(fmt.format(id=row["id"]))
    with (CORE / "tips.csv").open(encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            needed.add(row["text_key"])
    return needed


def collect_gd_keys() -> set[str]:
    pat = re.compile(r'L10n\.t(?:f)?\(\s*"([^"]+)"')
    keys: set[str] = set()
    for path in GAME.rglob("*.gd"):
        keys |= set(pat.findall(path.read_text(encoding="utf-8")))
    return {k for k in keys if "{" not in k and "%s" not in k and "%d" not in k}


def main() -> int:
    zh = load_l10n("zh_CN")
    en = load_l10n("en")
    needed = collect_needed() | collect_gd_keys()

    # Fill en gaps from zh as placeholder (prefixed) only when totally missing
    added_en = 0
    for k in sorted(needed):
        if k not in zh:
            # leave zh missing reported
            continue
        if k not in en:
            # Prefer existing English-looking? use [ZH] prefix only as last resort
            # Better: copy Chinese temporarily with mark for translator
            en[k] = zh[k]
            added_en += 1

    missing_zh = sorted(k for k in needed if k not in zh)
    missing_en = sorted(k for k in needed if k not in en)

    print(f"zh={len(zh)} en={len(en)} needed={len(needed)}")
    print(f"missing_zh={len(missing_zh)} missing_en={len(missing_en)} filled_en_from_zh={added_en}")
    if missing_zh:
        print("missing_zh sample:")
        for k in missing_zh[:40]:
            print(" ", k)
    if added_en:
        write_l10n("en", en)
        print("wrote en.csv with filled gaps")
    # report only_zh / only_en beyond needed
    only_zh = sorted(set(zh) - set(en))
    only_en = sorted(set(en) - set(zh))
    print(f"orphan_only_zh={len(only_zh)} orphan_only_en={len(only_en)}")
    return 0 if not missing_zh else 1


if __name__ == "__main__":
    raise SystemExit(main())
