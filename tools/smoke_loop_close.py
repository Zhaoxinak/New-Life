# -*- coding: utf-8 -*-
"""Smoke: loop-close data (quests hints, tips, place_bridge, matters)."""
from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / "docs" / "tables" / "packs" / "core"


def _rows(name: str) -> list[dict[str, str]]:
    path = PACK / f"{name}.csv"
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def _l10n_keys(locale: str) -> set[str]:
    path = PACK / "l10n" / f"{locale}.csv"
    keys: set[str] = set()
    with path.open(encoding="utf-8-sig", newline="") as f:
        for row in csv.reader(f):
            if row and row[0] and not row[0].startswith("#"):
                keys.add(row[0])
    return keys


def main() -> None:
    quests = _rows("quests")
    assert quests, "quests empty"
    for q in quests:
        assert "hint_location_id" in q, "quests missing hint_location_id"
        assert "hint_npc_id" in q, "quests missing hint_npc_id"
    enabled = [q for q in quests if q.get("enabled", "1") != "0"]
    assert any(q.get("hint_location_id") for q in enabled), "no location hints"
    assert any(q.get("hint_npc_id") for q in enabled), "no npc hints"

    bridge = {r["location_id"]: r["portal_id"] for r in _rows("place_bridge") if r.get("enabled", "1") != "0"}
    for need in ("dock", "home", "company", "tea_house", "rival", "plaza", "exchange", "garage"):
        assert need in bridge, f"place_bridge missing {need}"

    tip_ids = {r["id"] for r in _rows("tips")}
    for tid in ("tip_matter_offer", "tip_matter_accept", "tip_matter_go_place", "tip_matter_miss"):
        assert tid in tip_ids, f"missing tip {tid}"

    matters = _rows("social_matters")
    assert matters, "social_matters empty"
    for m in matters:
        assert m.get("place_id"), f"matter {m.get('id')} missing place_id"

    for locale in ("zh_CN", "en"):
        keys = _l10n_keys(locale)
        for k in (
            "matter.miss",
            "tip.matter_go_place",
            "tip.matter_miss",
            "quest.where.npc",
            "quest.where.place",
            "quest.where.matter",
            "quest.where.indoor",
            "quest.where.porch",
        ):
            assert k in keys, f"{locale} missing {k}"

    pack = (PACK / "pack.json").read_text(encoding="utf-8")
    assert "0.9.16" in pack, "pack version not bumped"

    print("smoke_loop_close: OK")


if __name__ == "__main__":
    main()
