# -*- coding: utf-8 -*-
"""Smoke: Town nav assets, whitebody sheets, place_bridge, schedule goal_pressure."""
from __future__ import annotations

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
PACK = ROOT / "docs" / "tables" / "packs" / "core"
NAV = GAME / "world" / "town" / "nav" / "data"
ART = GAME / "art" / "town" / "residents"


def main() -> None:
    grid_path = NAV / "outdoor_navigation_grid.json"
    net_path = NAV / "movement_network.json"
    assert grid_path.is_file(), f"missing {grid_path}"
    assert net_path.is_file(), f"missing {net_path}"
    grid = json.loads(grid_path.read_text(encoding="utf-8"))
    assert int(grid.get("cellSize", 0)) == 12
    assert int(grid.get("width", 0)) > 0 and int(grid.get("height", 0)) > 0
    assert len(grid.get("cells", [])) > 1000, "grid too small"
    net = json.loads(net_path.read_text(encoding="utf-8"))
    assert len(net.get("nodes", [])) > 10
    assert len(net.get("edges", [])) > 10

    sheets = list(ART.glob("*_walk4_3dir_v1_alpha.png"))
    assert len(sheets) >= 4, "need resident walk sheets"
    for need in ("TownOutdoorPathfinder.gd",):
        assert (GAME / "world" / "town" / "nav" / need).is_file()
    for need in ("TownWhitebodyRig.gd",):
        assert (GAME / "world" / "town" / need).is_file()
    assert (GAME / "world" / "TownOutdoorNpc.gd").is_file()
    assert (GAME / "systems" / "NpcPerception.gd").is_file()

    bridge = list(csv.DictReader((PACK / "place_bridge.csv").open(encoding="utf-8-sig")))
    locs = {r["location_id"] for r in bridge if r.get("enabled", "1") != "0"}
    for need in ("dock", "home", "company", "tea_house", "plaza"):
        assert need in locs, f"place_bridge missing {need}"

    homes = list(csv.DictReader((PACK / "npc_homes.csv").open(encoding="utf-8-sig")))
    assert "town_place_id" in homes[0], "npc_homes missing town_place_id"
    assert any(r.get("town_place_id") for r in homes)

    schedules = list(csv.DictReader((PACK / "npc_schedules.csv").open(encoding="utf-8-sig")))
    assert "goal_pressure" in schedules[0], "npc_schedules missing goal_pressure"

    pack = (PACK / "pack.json").read_text(encoding="utf-8")
    assert "0.9.17" in pack

    proj = (GAME / "project.godot").read_text(encoding="utf-8")
    assert "NpcPerception=" in proj

    print("smoke_town_agents: OK")


if __name__ == "__main__":
    main()
