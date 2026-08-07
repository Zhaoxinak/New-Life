#!/usr/bin/env python3
"""W2 data smoke without Godot: load CSVs, simulate dock_work x3."""
from __future__ import annotations

import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "docs" / "tables" / "packs" / "core"


def load_csv(name: str) -> list[dict]:
    path = CORE / f"{name}.csv"
    with path.open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def main() -> int:
    stats_rows = {r["id"]: r for r in load_csv("stats")}
    effects = load_csv("effects")
    actions = {r["id"]: r for r in load_csv("actions")}
    hotspots = {r["id"]: r for r in load_csv("hotspots")}
    assert "dock_work" in actions, "dock_work missing"
    assert actions["dock_work"]["hotspot_id"] == "dock_loading"

    state = {sid: float(row["initial"]) for sid, row in stats_rows.items()}
    day, period_i = 1, 0
    periods = ["morning", "afternoon", "evening"]

    def apply_owner(owner_type: str, owner_id: str) -> int:
        n = 0
        for row in effects:
            if row["owner_type"] != owner_type or row["owner_id"] != owner_id:
                continue
            if row["effect_type"] != "stat":
                continue
            key = row["key"]
            op = row["op"]
            val = float(row["value"])
            cur = state.get(key, 0.0)
            if op == "add":
                cur += val
            elif op == "set":
                cur = val
            elif op == "mul":
                cur *= val
            else:
                cur += val
            lo = float(stats_rows[key]["min"]) if key in stats_rows else -1e9
            hi = float(stats_rows[key]["max"]) if key in stats_rows else 1e9
            state[key] = max(lo, min(hi, cur))
            n += 1
        return n

    money0 = state["money"]
    for i in range(3):
        n = apply_owner("action", "dock_work")
        assert n >= 1, "no action effects"
        period_i += 1
        if period_i >= 3:
            period_i = 0
            day += 1
        print(f"run {i+1}: money={state['money']} day={day} period={periods[period_i]} effects={n}")

    assert state["money"] > money0, f"money {money0} -> {state['money']}"
    assert day > 1 or period_i > 0
    # start unlocks
    locs = [r for r in load_csv("locations") if r["start_unlocked"] == "1"]
    assert any(r["id"] == "dock" for r in locs)
    hs = hotspots["dock_loading"]
    assert hs["start_unlocked"] == "1"
    print("SMOKE PASS (python)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
