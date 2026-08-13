# -*- coding: utf-8 -*-
"""P25: rank_address 节点挂 keyword_highlight + 称呼词表 stage.keywords。"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "packs" / "anchao"

ADDRESS_KEYWORDS = [
    "聚丰的林跑街",
    "林外场",
    "林跑街",
    "林朋友",
    "林先生",
    "跑街",
    "外场",
    "月例",
]


def load(name: str):
    return json.loads((ROOT / name).read_text(encoding="utf-8"))


def save(name: str, data) -> None:
    (ROOT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("updated", name)


def merge_l10n(entries: dict) -> None:
    data = load("l10n/zh_CN.json")
    data.setdefault("zh_CN", {}).update(entries)
    save("l10n/zh_CN.json", data)


def main() -> None:
    data = load("def_dialog.json")
    n = 0
    for row in data["rows"]:
        tags = list(row.get("tags") or [])
        if "rank_address" not in tags and not (
            "rank_up" in tags and any(x in str(row.get("dialog_id", "")) for x in ("title", "crowd", "land", "address"))
        ):
            continue
        if "keyword_highlight" not in tags:
            tags.append("keyword_highlight")
            row["tags"] = tags
            n += 1
        stage = row.get("stage")
        if not isinstance(stage, dict):
            stage = {}
        kws = list(stage.get("keywords") or [])
        for w in ADDRESS_KEYWORDS:
            if w not in kws:
                kws.append(w)
        # long first for data clarity
        kws.sort(key=lambda s: (-len(s), s))
        stage["keywords"] = kws
        row["stage"] = stage
    save("def_dialog.json", data)
    merge_l10n({"ui.tag_address": "称呼"})
    print("P25 keyword highlight on", n, "rows (plus stage keywords refresh)")


if __name__ == "__main__":
    main()
