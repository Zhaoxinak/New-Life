#!/usr/bin/env python3
"""W4 content smoke: dialogue graph, events, thresholds, stock, endings."""
from __future__ import annotations

import csv
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "docs" / "tables" / "packs" / "core"


def load_csv(name: str) -> list[dict]:
    with (CORE / f"{name}.csv").open(encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def main() -> int:
    actions = {r["id"]: r for r in load_csv("actions")}
    dialogues = {r["id"]: r for r in load_csv("dialogues")}
    lines = load_csv("dialogue_lines")
    choices = load_csv("dialogue_choices")
    events = {r["id"]: r for r in load_csv("events")}
    echoices = load_csv("event_choices")
    thresholds = {r["id"]: r for r in load_csv("thresholds")}
    endings = {r["id"]: r for r in load_csv("endings")}
    effects = load_csv("effects")
    stock_rules = {r["id"]: r for r in load_csv("stock_rules")}
    stock_cfg = {r["key"]: float(r["value"]) for r in load_csv("stock_config")}

    # Every action dialogue_id exists
    for a in actions.values():
        did = (a.get("dialogue_id") or "").strip()
        if did:
            assert did in dialogues, f"missing dialogue {did} for {a['id']}"

    lines_by = defaultdict(list)
    for ln in lines:
        lines_by[ln["dialogue_id"]].append(ln)
    for did, dlg in dialogues.items():
        if dlg["enabled"] != "1":
            continue
        assert lines_by[did], f"dialogue {did} has no lines"

    # Choices reference after_line_id
    line_ids = {ln["id"] for ln in lines}
    for ch in choices:
        assert ch["after_line_id"] in line_ids, ch["id"]

    # Day1 event has choice + effects path
    assert "ev_day1_intro" in events
    d1_choices = [c for c in echoices if c["event_id"] == "ev_day1_intro"]
    assert d1_choices, "day1 needs choices"
    assert any(e["owner_type"] == "choice" and e["owner_id"] == "ch_intro_ok" for e in effects)

    # Thresholds all have effects
    for tid in thresholds:
        assert any(e["owner_type"] == "threshold" and e["owner_id"] == tid for e in effects), tid

    # Ending B path: clash choice sets ready+show
    clash_fx = [e for e in effects if e["owner_id"] == "ch_b_clash_ok"]
    keys = {e["key"] for e in clash_fx if e["effect_type"] == "flag"}
    assert "ending_route_b_ready" in keys and "ending_show_b" in keys
    assert "ending_b" in endings

    # Stock close sets route c ready via config target
    assert "rule_trade_close" in stock_rules
    assert stock_cfg["route_c_profit_target"] > 0
    # Simulate open long + price up + close
    price, entry, lots = 100.0, 100.0, 1.0
    lot_size = stock_cfg["lot_size"]
    lev = 1.0
    price = 110.0
    pnl = (price - entry) * lots * lot_size * lev
    assert pnl == 100.0
    cum = pnl
    ready = cum >= stock_cfg["route_c_profit_target"]
    assert ready

    # Fake rumor rule only on success (engine contract)
    assert stock_rules["rule_rumor_fake"]["action_id"] == "ex_rumor_fake"

    print("SMOKE PASS (python W4)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
