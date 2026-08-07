#!/usr/bin/env python3
"""W3 data smoke: conditions, checks, unlocks, save-shaped snapshot."""
from __future__ import annotations

import csv
import json
import random
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "docs" / "tables" / "packs" / "core"


def load_csv(name: str) -> list[dict]:
    with (CORE / f"{name}.csv").open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def compare(actual: float, op: str, expected: float) -> bool:
    if op == "eq":
        return abs(actual - expected) < 1e-6
    if op == "gte":
        return actual >= expected - 1e-6
    if op == "lte":
        return actual <= expected + 1e-6
    if op == "gt":
        return actual > expected
    raise ValueError(op)


class State:
    def __init__(self) -> None:
        self.day = 1
        self.period = "morning"
        self.stats = {r["id"]: float(r["initial"]) for r in load_csv("stats")}
        self.flags = {r["id"]: int(r["default"]) for r in load_csv("flags")}
        self.relations = {
            f"{r['source_id']}:{r['target_id']}:{r['relation_key']}": float(r["initial"])
            for r in load_csv("relations_init")
        }
        self.unlocked_locations: set[str] = set()
        self.unlocked_hotspots: set[str] = set()
        self.ranks = load_csv("ranks")
        self.conditions = load_csv("conditions")
        self.checks = {r["id"]: r for r in load_csv("checks")}
        self.check_mods = load_csv("check_mods")
        self.effects = load_csv("effects")
        self.unlock_schedule = [r for r in load_csv("unlock_schedule") if r["enabled"] == "1"]
        self._boot_unlocks()

    def _boot_unlocks(self) -> None:
        for r in load_csv("locations"):
            if r["start_unlocked"] == "1":
                self.unlocked_locations.add(r["id"])
        for r in load_csv("hotspots"):
            if r["start_unlocked"] == "1":
                self.unlocked_hotspots.add(r["id"])
        self.apply_up_to_day(self.day)

    def apply_up_to_day(self, day: int) -> None:
        for r in self.unlock_schedule:
            if int(r["day"]) <= day:
                if r["unlock_type"] == "location":
                    self.unlocked_locations.add(r["unlock_id"])
                elif r["unlock_type"] == "hotspot":
                    self.unlocked_hotspots.add(r["unlock_id"])
                elif r["unlock_type"] == "flag":
                    self.flags[r["unlock_id"]] = 1

    def rank_order(self) -> int:
        trust = self.stats["trust"]
        best = 0
        for r in self.ranks:
            if r["track_id"] != "hongyuan_career":
                continue
            if float(r["stat_min"]) <= trust <= float(r["stat_max"]):
                best = max(best, int(r["sort_order"]))
        return best

    def eval_owner(self, owner_type: str, owner_id: str) -> bool:
        rows = [r for r in self.conditions if r["owner_type"] == owner_type and r["owner_id"] == owner_id]
        if not rows:
            return True
        by_g: dict[str, list] = defaultdict(list)
        for r in rows:
            by_g[r["cond_group"]].append(r)
        for group in by_g.values():
            ok = True
            for r in group:
                if not self.eval_row(r):
                    ok = False
                    break
            if ok:
                return True
        return False

    def eval_row(self, r: dict) -> bool:
        ct, key, op = r["cond_type"], r["key"], r["op"]
        if ct == "stat":
            actual = self.stats[key]
            expected = float(r["value"])
        elif ct == "flag":
            actual = float(self.flags.get(key, 0))
            expected = float(r["value"])
        elif ct == "day":
            actual = float(self.day)
            expected = float(r["value"])
        elif ct == "relation":
            actual = float(self.relations.get(key, 0))
            expected = float(r["value"])
        elif ct == "rank_min":
            need = next(x for x in self.ranks if x["id"] == key)
            actual = float(self.rank_order())
            expected = float(need["sort_order"])
            op = "gte"
        else:
            raise ValueError(ct)
        return compare(actual, op, expected)

    def check_chance(self, check_id: str) -> float:
        chk = self.checks[check_id]
        base = float(chk["base"])
        total = 0.0
        for m in self.check_mods:
            if m["check_id"] != check_id or m["enabled"] != "1":
                continue
            kind, key, scale = m["mod_kind"], m["key"], float(m["scale"])
            if kind == "flag_flat":
                if self.flags.get(key, 0) == 1:
                    total += scale
            elif kind == "stat_scale":
                v = self.stats[key]
                ref = float(m["ref"])
                mn = float(m["min_mod"]) if m["min_mod"] else -1.0
                mx = float(m["max_mod"]) if m["max_mod"] else 1.0
                total += max(mn, min(mx, (v - ref) * scale))
            elif kind == "relation_scale":
                v = float(self.relations.get(key, 0))
                ref = float(m["ref"])
                mn = float(m["min_mod"]) if m["min_mod"] else -1.0
                mx = float(m["max_mod"]) if m["max_mod"] else 1.0
                total += max(mn, min(mx, (v - ref) * scale))
        return max(float(chk["chance_min"]), min(float(chk["chance_max"]), base + total))

    def apply_effects(self, owner_type: str, owner_id: str) -> int:
        n = 0
        for row in self.effects:
            if row["owner_type"] != owner_type or row["owner_id"] != owner_id:
                continue
            if row["effect_type"] != "stat":
                continue
            key, op, val = row["key"], row["op"], float(row["value"])
            cur = self.stats.get(key, 0.0)
            if op == "add":
                cur += val
            elif op == "set":
                cur = val
            elif op == "mul":
                cur *= val
            else:
                cur += val
            self.stats[key] = cur
            n += 1
        return n

    def snapshot(self) -> dict:
        return {
            "day": self.day,
            "period": self.period,
            "stats": dict(self.stats),
            "flags": dict(self.flags),
            "relations": dict(self.relations),
            "unlocked_locations": sorted(self.unlocked_locations),
            "unlocked_hotspots": sorted(self.unlocked_hotspots),
        }


def main() -> int:
    pack = json.loads((CORE / "pack.json").read_text(encoding="utf-8"))
    for t in pack["tables"]:
        if t == "l10n":
            continue
        assert (CORE / f"{t}.csv").exists(), f"missing {t}.csv"

    st = State()
    assert "dock" in st.unlocked_locations
    assert st.eval_owner("action", "dock_work") is True
    # dock_report needs foreman; trust 45 => warehouse_chief >= foreman
    assert st.rank_order() >= 2
    # but dock_office hotspot not unlocked on day 1
    assert "dock_office" not in st.unlocked_hotspots

    # advance to day 2 unlock
    st.day = 2
    st.apply_up_to_day(2)
    assert "dock_office" in st.unlocked_hotspots
    assert st.eval_owner("hotspot", "dock_office") is True
    assert st.eval_owner("action", "dock_report") is True

    # black market locked by intel
    assert st.eval_owner("action", "dock_black_market") is False
    st.stats["intel"] = 10
    assert st.eval_owner("action", "dock_black_market") is True

    chance = st.check_chance("chk_dock_chat")
    assert 0.08 <= chance <= 0.92, chance
    print(f"chk_dock_chat chance={chance:.3f}")

    money0 = st.stats["money"]
    st.apply_effects("action", "dock_work")
    assert st.stats["money"] > money0

    # seeded check pass/fail both paths exist
    rng = random.Random(1)
    passed = sum(1 for _ in range(200) if rng.random() < chance)
    assert 20 < passed < 180, passed

    snap = st.snapshot()
    st2 = State()
    st2.day = snap["day"]
    st2.period = snap["period"]
    st2.stats = dict(snap["stats"])
    st2.flags = {k: int(v) for k, v in snap["flags"].items()}
    st2.relations = dict(snap["relations"])
    st2.unlocked_locations = set(snap["unlocked_locations"])
    st2.unlocked_hotspots = set(snap["unlocked_hotspots"])
    assert st2.stats["money"] == st.stats["money"]
    assert "dock_office" in st2.unlocked_hotspots

    # day 7 unlocks rival + exchange
    st.day = 7
    st.apply_up_to_day(7)
    assert "rival" in st.unlocked_locations and "exchange" in st.unlocked_locations
    print("locations day7:", sorted(st.unlocked_locations))
    print("SMOKE PASS (python W3)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
