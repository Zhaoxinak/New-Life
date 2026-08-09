# -*- coding: utf-8 -*-
"""Add garage location, vehicle/home tiers, transit/lifestyle l10n."""
from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs" / "tables" / "packs" / "core"


def read_csv(path: Path) -> tuple[list[str], list[dict]]:
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))
        fields = list(rows[0].keys()) if rows else []
        # re-read header properly
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        fields = list(reader.fieldnames or [])
        rows = list(reader)
    return fields, rows


def write_csv(path: Path, fields: list[str], rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, lineterminator="\n")
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in fields})


def upsert_rows(path: Path, key: str, new_rows: list[dict]) -> None:
    fields, rows = read_csv(path)
    by = {str(r.get(key, "")): r for r in rows}
    for nr in new_rows:
        by[str(nr[key])] = {**{k: "" for k in fields}, **nr}
    # preserve order: old then new ids
    ordered = []
    seen = set()
    for r in rows:
        kid = str(r.get(key, ""))
        if kid in by:
            ordered.append(by[kid])
            seen.add(kid)
    for nr in new_rows:
        kid = str(nr[key])
        if kid not in seen:
            ordered.append({**{k: "" for k in fields}, **nr})
    write_csv(path, fields, ordered)
    print(f"{path.name}: upsert {len(new_rows)}")


def append_unique(path: Path, key: str, new_rows: list[dict]) -> None:
    fields, rows = read_csv(path)
    existing = {str(r.get(key, "")) for r in rows}
    added = 0
    for nr in new_rows:
        kid = str(nr[key])
        if kid in existing:
            continue
        rows.append({**{k: "" for k in fields}, **nr})
        existing.add(kid)
        added += 1
    write_csv(path, fields, rows)
    print(f"{path.name}: +{added}")


def upsert_l10n(path: Path, updates: dict[str, str]) -> None:
    text = path.read_text(encoding="utf-8-sig")
    lines = text.splitlines()
    out = []
    seen = set()
    for line in lines:
        if not line.strip() or "," not in line:
            out.append(line)
            continue
        k = line.split(",", 1)[0]
        if k in updates:
            val = updates[k]
            if "," in val or '"' in val or val.startswith(" ") or "\n" in val:
                esc = val.replace('"', '""')
                out.append(f'{k},"{esc}"')
            else:
                out.append(f"{k},{val}")
            seen.add(k)
        else:
            out.append(line)
    missing = [k for k in updates if k not in seen]
    for k in missing:
        val = updates[k]
        if "," in val or '"' in val or val.startswith(" "):
            esc = val.replace('"', '""')
            out.append(f'{k},"{esc}"')
        else:
            out.append(f"{k},{val}")
    path.write_text("\n".join(out) + "\n", encoding="utf-8-sig")
    print(f"{path.name}: upsert {len(updates)} (new {len(missing)})")


def main() -> None:
    # stats
    append_unique(
        ROOT / "stats.csv",
        "id",
        [
            {
                "id": "vehicle_tier",
                "category": "lifestyle",
                "min": "0",
                "max": "4",
                "initial": "0",
                "warn_low": "",
                "warn_high": "",
                "hidden": "0",
                "mod_locked": "0",
                "notes": "0步行1脚踏车2黄包车3摩托4轿车",
            },
            {
                "id": "home_tier",
                "category": "lifestyle",
                "min": "1",
                "max": "4",
                "initial": "1",
                "warn_low": "",
                "warn_high": "",
                "hidden": "0",
                "mod_locked": "0",
                "notes": "1出租屋2粉刷3雅寓4洋房",
            },
        ],
    )

    # locations
    append_unique(
        ROOT / "locations.csv",
        "id",
        [
            {
                "id": "garage",
                "default_periods": "any",
                "tags": "all",
                "sort_order": "8",
                "enabled": "1",
                "start_unlocked": "1",
                "notes": "西市井车行：买交通工具",
            }
        ],
    )

    # hotspots
    append_unique(
        ROOT / "hotspots.csv",
        "id",
        [
            {
                "id": "garage_lot",
                "location_id": "garage",
                "suspicion_mult": "0.1",
                "periods": "any",
                "tags": "lifestyle",
                "sort_order": "24",
                "enabled": "1",
                "start_unlocked": "1",
                "pos_x": "360",
                "pos_y": "620",
                "notes": "展车场",
            },
            {
                "id": "garage_counter",
                "location_id": "garage",
                "suspicion_mult": "0.1",
                "periods": "any",
                "tags": "lifestyle",
                "sort_order": "25",
                "enabled": "1",
                "start_unlocked": "1",
                "pos_x": "700",
                "pos_y": "420",
                "notes": "柜台",
            },
            {
                "id": "home_contractor",
                "location_id": "home",
                "suspicion_mult": "0.0",
                "periods": "any",
                "tags": "lifestyle",
                "sort_order": "26",
                "enabled": "1",
                "start_unlocked": "1",
                "pos_x": "520",
                "pos_y": "420",
                "notes": "包工升级房产",
            },
        ],
    )

    actions = [
        ("garage_buy_1", "garage_lot", "any", "all", "1", "0", "0", "1", "70", "1", "买脚踏车", "dlg_garage_buy_1", "", ""),
        ("garage_buy_2", "garage_lot", "any", "all", "1", "0", "0", "1", "71", "1", "买黄包车", "dlg_garage_buy_2", "", ""),
        ("garage_buy_3", "garage_counter", "any", "all", "1", "2", "0", "1", "72", "1", "买摩托", "dlg_garage_buy_3", "", ""),
        ("garage_buy_4", "garage_counter", "any", "all", "1", "0", "0", "1", "73", "1", "买轿车", "dlg_garage_buy_4", "", ""),
        ("home_upgrade_2", "home_contractor", "any", "all", "1", "0", "0", "1", "74", "1", "升粉刷小居", "dlg_home_up_2", "", ""),
        ("home_upgrade_3", "home_contractor", "any", "all", "1", "0", "0", "1", "75", "1", "升临街雅寓", "dlg_home_up_3", "", ""),
        ("home_upgrade_4", "home_contractor", "any", "all", "1", "0", "0", "1", "76", "1", "升港湾洋房", "dlg_home_up_4", "", ""),
        ("home_drive", "home_desk", "any", "all", "0", "0", "0", "0", "77", "1", "开车出门选站", "", "", ""),
    ]
    fields, rows = read_csv(ROOT / "actions.csv")
    existing = {r["id"] for r in rows}
    # mark home_drive as minigame-like via tags — handled in pipeline by tag transit_open
    for a in actions:
        if a[0] in existing:
            continue
        row = {k: "" for k in fields}
        keys = [
            "id",
            "hotspot_id",
            "periods",
            "tags",
            "time_cost",
            "suspicion_base",
            "cooldown_days",
            "max_uses",
            "sort_order",
            "enabled",
            "notes",
            "dialogue_id",
            "stock_rule_id",
            "check_id",
        ]
        for i, k in enumerate(keys):
            row[k] = a[i]
        if a[0] == "home_drive":
            row["tags"] = "all|transit_open"
        rows.append(row)
        existing.add(a[0])
    write_csv(ROOT / "actions.csv", fields, rows)
    print("actions.csv patched")

    # conditions
    conds = [
        ("c_garage_buy_1_money", "action", "garage_buy_1", "1", "stat", "money", "gte", "60", ""),
        ("c_garage_buy_1_day", "action", "garage_buy_1", "1", "day", "day", "gte", "3", ""),
        ("c_garage_buy_1_tier", "action", "garage_buy_1", "1", "stat", "vehicle_tier", "eq", "0", ""),
        ("c_garage_buy_2_money", "action", "garage_buy_2", "1", "stat", "money", "gte", "150", ""),
        ("c_garage_buy_2_day", "action", "garage_buy_2", "1", "day", "day", "gte", "7", ""),
        ("c_garage_buy_2_net", "action", "garage_buy_2", "1", "stat", "network_base", "gte", "35", ""),
        ("c_garage_buy_2_tier", "action", "garage_buy_2", "1", "stat", "vehicle_tier", "eq", "1", ""),
        ("c_garage_buy_3_money", "action", "garage_buy_3", "1", "stat", "money", "gte", "320", ""),
        ("c_garage_buy_3_day", "action", "garage_buy_3", "1", "day", "day", "gte", "12", ""),
        ("c_garage_buy_3_tier", "action", "garage_buy_3", "1", "stat", "vehicle_tier", "eq", "2", ""),
        ("c_garage_buy_3_elite", "action", "garage_buy_3", "1", "stat", "network_elite", "gte", "8", ""),
        ("c_garage_buy_4_money", "action", "garage_buy_4", "1", "stat", "money", "gte", "700", ""),
        ("c_garage_buy_4_day", "action", "garage_buy_4", "1", "day", "day", "gte", "18", ""),
        ("c_garage_buy_4_tier", "action", "garage_buy_4", "1", "stat", "vehicle_tier", "eq", "3", ""),
        ("c_garage_buy_4_elite", "action", "garage_buy_4", "1", "stat", "network_elite", "gte", "25", ""),
        ("c_home_up_2_money", "action", "home_upgrade_2", "1", "stat", "money", "gte", "120", ""),
        ("c_home_up_2_day", "action", "home_upgrade_2", "1", "day", "day", "gte", "5", ""),
        ("c_home_up_2_tier", "action", "home_upgrade_2", "1", "stat", "home_tier", "eq", "1", ""),
        ("c_home_up_3_money", "action", "home_upgrade_3", "1", "stat", "money", "gte", "300", ""),
        ("c_home_up_3_day", "action", "home_upgrade_3", "1", "day", "day", "gte", "10", ""),
        ("c_home_up_3_tier", "action", "home_upgrade_3", "1", "stat", "home_tier", "eq", "2", ""),
        ("c_home_up_3_bike", "action", "home_upgrade_3", "1", "stat", "vehicle_tier", "gte", "1", ""),
        ("c_home_up_4_money", "action", "home_upgrade_4", "1", "stat", "money", "gte", "650", ""),
        ("c_home_up_4_day", "action", "home_upgrade_4", "1", "day", "day", "gte", "16", ""),
        ("c_home_up_4_tier", "action", "home_upgrade_4", "1", "stat", "home_tier", "eq", "3", ""),
        ("c_home_up_4_elite", "action", "home_upgrade_4", "1", "stat", "network_elite", "gte", "20", ""),
        ("c_home_drive_car", "action", "home_drive", "1", "stat", "vehicle_tier", "gte", "4", ""),
    ]
    # For garage_buy_3, plan said elite OR network_base - ConditionEval is AND within group.
    # Use elite only for simplicity, or add group 2 with network_base.
    # Add alt group for buy_3 with network_base >= 55
    conds.append(
        ("c_garage_buy_3_net_alt", "action", "garage_buy_3", "2", "stat", "network_base", "gte", "55", "OR group")
    )
    conds.append(("c_garage_buy_3_money_g2", "action", "garage_buy_3", "2", "stat", "money", "gte", "320", ""))
    conds.append(("c_garage_buy_3_day_g2", "action", "garage_buy_3", "2", "day", "day", "gte", "12", ""))
    conds.append(("c_garage_buy_3_tier_g2", "action", "garage_buy_3", "2", "stat", "vehicle_tier", "eq", "2", ""))

    # home_up_3 alt: network_base >= 40 instead of vehicle
    conds.append(("c_home_up_3_money_g2", "action", "home_upgrade_3", "2", "stat", "money", "gte", "300", ""))
    conds.append(("c_home_up_3_day_g2", "action", "home_upgrade_3", "2", "day", "day", "gte", "10", ""))
    conds.append(("c_home_up_3_tier_g2", "action", "home_upgrade_3", "2", "stat", "home_tier", "eq", "2", ""))
    conds.append(("c_home_up_3_net_g2", "action", "home_upgrade_3", "2", "stat", "network_base", "gte", "40", ""))

    fields, rows = read_csv(ROOT / "conditions.csv")
    existing = {r["id"] for r in rows}
    for c in conds:
        if c[0] in existing:
            continue
        row = {k: "" for k in fields}
        for i, k in enumerate(
            ["id", "owner_type", "owner_id", "group", "type", "key", "op", "value", "notes"]
        ):
            if k in fields:
                row[k] = c[i]
        rows.append(row)
    write_csv(ROOT / "conditions.csv", fields, rows)
    print("conditions.csv patched")

    effects = [
        ("fx_garage_1_money", "action", "garage_buy_1", "stat", "", "money", "add", "-60", "1", ""),
        ("fx_garage_1_tier", "action", "garage_buy_1", "stat", "", "vehicle_tier", "set", "1", "1", ""),
        ("fx_garage_1_net", "action", "garage_buy_1", "stat", "", "network_base", "add", "1", "1", ""),
        ("fx_garage_2_money", "action", "garage_buy_2", "stat", "", "money", "add", "-150", "1", ""),
        ("fx_garage_2_tier", "action", "garage_buy_2", "stat", "", "vehicle_tier", "set", "2", "1", ""),
        ("fx_garage_2_net", "action", "garage_buy_2", "stat", "", "network_base", "add", "2", "1", ""),
        ("fx_garage_3_money", "action", "garage_buy_3", "stat", "", "money", "add", "-320", "1", ""),
        ("fx_garage_3_tier", "action", "garage_buy_3", "stat", "", "vehicle_tier", "set", "3", "1", ""),
        ("fx_garage_3_elite", "action", "garage_buy_3", "stat", "", "network_elite", "add", "2", "1", ""),
        ("fx_garage_3_sus", "action", "garage_buy_3", "stat", "", "suspicion", "add", "2", "1", ""),
        ("fx_garage_4_money", "action", "garage_buy_4", "stat", "", "money", "add", "-700", "1", ""),
        ("fx_garage_4_tier", "action", "garage_buy_4", "stat", "", "vehicle_tier", "set", "4", "1", ""),
        ("fx_garage_4_elite", "action", "garage_buy_4", "stat", "", "network_elite", "add", "4", "1", ""),
        ("fx_home_2_money", "action", "home_upgrade_2", "stat", "", "money", "add", "-120", "1", ""),
        ("fx_home_2_tier", "action", "home_upgrade_2", "stat", "", "home_tier", "set", "2", "1", ""),
        ("fx_home_3_money", "action", "home_upgrade_3", "stat", "", "money", "add", "-300", "1", ""),
        ("fx_home_3_tier", "action", "home_upgrade_3", "stat", "", "home_tier", "set", "3", "1", ""),
        ("fx_home_4_money", "action", "home_upgrade_4", "stat", "", "money", "add", "-650", "1", ""),
        ("fx_home_4_tier", "action", "home_upgrade_4", "stat", "", "home_tier", "set", "4", "1", ""),
        # rest bonus via dialogue_choice on existing? add action extras for home_rest by tier using separate — skip, use tip
    ]
    fields, rows = read_csv(ROOT / "effects.csv")
    existing = {r["id"] for r in rows}
    for e in effects:
        if e[0] in existing:
            continue
        row = {k: "" for k in fields}
        for i, k in enumerate(
            ["id", "owner_type", "owner_id", "effect_type", "target", "key", "op", "value", "chance", "notes"]
        ):
            if k in fields:
                row[k] = e[i]
        rows.append(row)
    # Bonus rest effects: apply always when home_tier high via owner action home_rest additional
    extras = [
        ("fx_home_rest_t2", "action", "home_rest", "stat", "", "suspicion", "add", "-2", "1", "if home_tier handled in code? use always small - actually always applies - BAD"),
    ]
    # Don't add unconditional - handle in ActionPipeline instead or skip
    write_csv(ROOT / "effects.csv", fields, rows)
    print("effects.csv patched")

    dialogs = [
        ("dlg_garage_buy_1", "all", "50", "0", "1", "买脚踏车"),
        ("dlg_garage_buy_2", "all", "50", "0", "1", "买黄包车"),
        ("dlg_garage_buy_3", "all", "50", "0", "1", "买摩托"),
        ("dlg_garage_buy_4", "all", "50", "0", "1", "买轿车"),
        ("dlg_home_up_2", "all", "50", "0", "1", "升房2"),
        ("dlg_home_up_3", "all", "50", "0", "1", "升房3"),
        ("dlg_home_up_4", "all", "50", "0", "1", "升房4"),
    ]
    append_unique(
        ROOT / "dialogues.csv",
        "id",
        [
            {
                "id": d[0],
                "tags": d[1],
                "priority": d[2],
                "once": d[3],
                "enabled": d[4],
                "notes": d[5],
            }
            for d in dialogs
        ],
    )

    lines = []
    for base, texts in [
        ("dlg_garage_buy_1", ("铺子里脚踏车擦得发亮。", "这辆。", "铃一响，码头路一下子短了。")),
        ("dlg_garage_buy_2", ("黄包车夫点头：包月，街坊都认得你。", "包了。", "车帘一掀，腰杆都直了半分。")),
        ("dlg_garage_buy_3", ("摩托轰一声，柜上茶杯都跳。", "就要这响的。", "尾气里有点扎眼——也有点痛快。")),
        ("dlg_garage_buy_4", ("黑壳轿车泊在棚下，像会呼吸。", "开回家。", "轮子一转，港城都侧目。")),
        ("dlg_home_up_2", ("包工掐着烟：粉刷加门闩，潮气能压住。", "做。", "墙白了，灯也敢亮一点。")),
        ("dlg_home_up_3", ("临街窗子一开，巷口都听得见你的脚步。", "升。", "客厅有了像样的椅子——晚晴会愣一下。")),
        ("dlg_home_up_4", ("洋房图样摊开：石阶、铁栅、门楣。", "按这个。", "门牌一换，街坊话音都轻了。")),
    ]:
        for i, t in enumerate(texts, 1):
            speaker = "narrator" if i != 2 else "player"
            lines.append(
                {
                    "id": f"{base}_l0{i}",
                    "dialogue_id": base,
                    "line_index": str(i),
                    "speaker_id": speaker,
                    "mood": "neutral" if i != 2 else "resolve",
                    "enabled": "1",
                    "notes": "",
                }
            )
            # l10n later
    append_unique(ROOT / "dialogue_lines.csv", "id", lines)

    choices = []
    for base in [
        "dlg_garage_buy_1",
        "dlg_garage_buy_2",
        "dlg_garage_buy_3",
        "dlg_garage_buy_4",
        "dlg_home_up_2",
        "dlg_home_up_3",
        "dlg_home_up_4",
    ]:
        choices.append(
            {
                "id": f"dch_{base}_ok",
                "dialogue_id": base,
                "line_id": f"{base}_l03",
                "sort_order": "1",
                "enabled": "1",
                "notes": "",
            }
        )
    append_unique(ROOT / "dialogue_choices.csv", "id", choices)

    tips = [
        {
            "id": "tip_transit",
            "category": "unlock",
            "sort_order": "40",
            "text_key": "tip.transit",
            "once": "1",
            "enabled": "1",
            "notes": "",
        },
        {
            "id": "tip_garage",
            "category": "unlock",
            "sort_order": "41",
            "text_key": "tip.garage",
            "once": "1",
            "enabled": "1",
            "notes": "",
        },
        {
            "id": "tip_home_upgrade",
            "category": "unlock",
            "sort_order": "42",
            "text_key": "tip.home_upgrade",
            "once": "1",
            "enabled": "1",
            "notes": "",
        },
    ]
    # tips.csv columns may vary
    fields, rows = read_csv(ROOT / "tips.csv")
    existing = {r["id"] for r in rows}
    for t in tips:
        if t["id"] in existing:
            continue
        row = {k: t.get(k, "") for k in fields}
        rows.append(row)
    write_csv(ROOT / "tips.csv", fields, rows)
    print("tips.csv patched")

    zh = {
        "locations.garage.name": "车行",
        "locations.garage.description": "西市井尽头：脚踏车到轿车，气派一档一价。",
        "unlock.location.garage": "开局开放 · 买交通工具",
        "hotspots.garage_lot.name": "展车场",
        "hotspots.garage_lot.description": "铃铛、轮毂、新漆味。",
        "hotspots.garage_counter.name": "上牌柜台",
        "hotspots.garage_counter.description": "贵车、手续、闲话都在这儿。",
        "hotspots.home_contractor.name": "宅基包工",
        "hotspots.home_contractor.description": "粉刷、扩厅、洋房——银元说话。",
        "locations.home.name": "自宅",
        "locations.home.t1": "潮气出租屋",
        "locations.home.t2": "粉刷小居",
        "locations.home.t3": "临街雅寓",
        "locations.home.t4": "港湾洋房",
        "vehicle.tier.0": "步行",
        "vehicle.tier.1": "脚踏车",
        "vehicle.tier.2": "黄包车",
        "vehicle.tier.3": "摩托车",
        "vehicle.tier.4": "小轿车",
        "actions.garage_buy_1.name": "买脚踏车",
        "actions.garage_buy_1.description": "60银元。跑腿利落，公交仍买票。",
        "actions.garage_buy_1.result": "铃一响。你有轮子了。",
        "actions.garage_buy_2.name": "包月黄包车",
        "actions.garage_buy_2.description": "150银元。港湾环线免票。",
        "actions.garage_buy_2.result": "车帘一掀，街坊点头。",
        "actions.garage_buy_3.name": "买摩托车",
        "actions.garage_buy_3.description": "320银元。响亮扎眼，免票。",
        "actions.garage_buy_3.result": "尾气散开。有人侧目。",
        "actions.garage_buy_4.name": "买小轿车",
        "actions.garage_buy_4.description": "700银元。最大脸面；家可开车选站。",
        "actions.garage_buy_4.result": "黑壳一亮，港城让路。",
        "actions.home_upgrade_2.name": "粉刷升级",
        "actions.home_upgrade_2.description": "120银元。潮气压住，门牌改名。",
        "actions.home_upgrade_2.result": "墙白了。灯敢亮一点。",
        "actions.home_upgrade_3.name": "扩成临街雅寓",
        "actions.home_upgrade_3.description": "300银元。要有车或人脉撑场面。",
        "actions.home_upgrade_3.result": "客厅像样了。巷口听得见脚步。",
        "actions.home_upgrade_4.name": "迁入港湾洋房",
        "actions.home_upgrade_4.description": "650银元。声望够才压得住街坊。",
        "actions.home_upgrade_4.result": "门楣一换，话音都轻了。",
        "actions.home_drive.name": "开车出门",
        "actions.home_drive.description": "打开港湾环线，直达各站（免票）。",
        "actions.home_drive.result": "引擎一响，你已在路上。",
        "dialogue_choices.dch_dlg_garage_buy_1_ok.label": "成交",
        "dialogue_choices.dch_dlg_garage_buy_2_ok.label": "包月",
        "dialogue_choices.dch_dlg_garage_buy_3_ok.label": "提车",
        "dialogue_choices.dch_dlg_garage_buy_4_ok.label": "开回家",
        "dialogue_choices.dch_dlg_home_up_2_ok.label": "开工",
        "dialogue_choices.dch_dlg_home_up_3_ok.label": "升级",
        "dialogue_choices.dch_dlg_home_up_4_ok.label": "迁居",
        "dialogue_lines.dlg_garage_buy_1_l01.text": "铺子里脚踏车擦得发亮。",
        "dialogue_lines.dlg_garage_buy_1_l02.text": "这辆。",
        "dialogue_lines.dlg_garage_buy_1_l03.text": "铃一响，码头路一下子短了。",
        "dialogue_lines.dlg_garage_buy_2_l01.text": "黄包车夫点头：包月，街坊都认得你。",
        "dialogue_lines.dlg_garage_buy_2_l02.text": "包了。",
        "dialogue_lines.dlg_garage_buy_2_l03.text": "车帘一掀，腰杆都直了半分。",
        "dialogue_lines.dlg_garage_buy_3_l01.text": "摩托轰一声，柜上茶杯都跳。",
        "dialogue_lines.dlg_garage_buy_3_l02.text": "就要这响的。",
        "dialogue_lines.dlg_garage_buy_3_l03.text": "尾气里有点扎眼——也有点痛快。",
        "dialogue_lines.dlg_garage_buy_4_l01.text": "黑壳轿车泊在棚下，像会呼吸。",
        "dialogue_lines.dlg_garage_buy_4_l02.text": "开回家。",
        "dialogue_lines.dlg_garage_buy_4_l03.text": "轮子一转，港城都侧目。",
        "dialogue_lines.dlg_home_up_2_l01.text": "包工掐着烟：粉刷加门闩，潮气能压住。",
        "dialogue_lines.dlg_home_up_2_l02.text": "做。",
        "dialogue_lines.dlg_home_up_2_l03.text": "墙白了，灯也敢亮一点。",
        "dialogue_lines.dlg_home_up_3_l01.text": "临街窗子一开，巷口都听得见你的脚步。",
        "dialogue_lines.dlg_home_up_3_l02.text": "升。",
        "dialogue_lines.dlg_home_up_3_l03.text": "客厅有了像样的椅子——晚晴会愣一下。",
        "dialogue_lines.dlg_home_up_4_l01.text": "洋房图样摊开：石阶、铁栅、门楣。",
        "dialogue_lines.dlg_home_up_4_l02.text": "按这个。",
        "dialogue_lines.dlg_home_up_4_l03.text": "门牌一换，街坊话音都轻了。",
        "transit.title": "港湾环线",
        "transit.fare": "票价 {n} 银元 · 不耗时段",
        "transit.fare_free": "包月免票 · 想去哪站？",
        "transit.to": "到{name}",
        "transit.broke": "票钱不够。先去码头扛两箱。",
        "transit.stop_mark": "站",
        "tip.transit": "各栋门口蓝圈是「港湾环线」站牌：按互动选站，票价2银元，不耗时段。黄包车起免票。",
        "tip.garage": "西市井南端「车行」：脚踏车→黄包车→摩托→轿车，气派与免票一档一价。",
        "tip.home_upgrade": "自宅「宅基包工」可升级房产：出租屋→小居→雅寓→洋房，门牌与气派会变。",
        "tip.tea_house": "西市井「港湾茶馆」：打听、敬酒、听说书；晚上后间可问掮客。",
        "ui.hud.vehicle": "座驾",
        "ui.hud.home_tier": "住所",
        "quest.enter_home.hint": "1. 回到港区||2. 走到北署街正中「自宅」（或坐公交到自宅站）||3. 走近门口进入||4. 这里是降嫌疑、整理情报的据点",
    }
    en = {
        "locations.garage.name": "Garage",
        "locations.garage.description": "West street end: bikes to sedans, tier by tier.",
        "unlock.location.garage": "Open from day 1 · vehicles",
        "hotspots.garage_lot.name": "Lot",
        "hotspots.garage_lot.description": "Bells, hubs, fresh paint.",
        "hotspots.garage_counter.name": "Counter",
        "hotspots.garage_counter.description": "Papers, pricey rides, talk.",
        "hotspots.home_contractor.name": "Contractor",
        "hotspots.home_contractor.description": "Paint, expand, villa — silver talks.",
        "locations.home.name": "Home",
        "locations.home.t1": "Damp Rental",
        "locations.home.t2": "Fresh-Paint Flat",
        "locations.home.t3": "Street Flat",
        "locations.home.t4": "Harbor Villa",
        "vehicle.tier.0": "On foot",
        "vehicle.tier.1": "Bicycle",
        "vehicle.tier.2": "Rickshaw",
        "vehicle.tier.3": "Motorcycle",
        "vehicle.tier.4": "Sedan",
        "actions.garage_buy_1.name": "Buy Bicycle",
        "actions.garage_buy_1.description": "60 silver. Quicker walk; bus still costs.",
        "actions.garage_buy_1.result": "Bell rings. You have wheels.",
        "actions.garage_buy_2.name": "Hire Rickshaw",
        "actions.garage_buy_2.description": "150 silver. Free harbor bus.",
        "actions.garage_buy_2.result": "Curtain lifts; neighbors nod.",
        "actions.garage_buy_3.name": "Buy Motorcycle",
        "actions.garage_buy_3.description": "320 silver. Loud; free bus.",
        "actions.garage_buy_3.result": "Exhaust hangs. Eyes follow.",
        "actions.garage_buy_4.name": "Buy Sedan",
        "actions.garage_buy_4.description": "700 silver. Top face; drive from home.",
        "actions.garage_buy_4.result": "Black shell gleams. The port yields.",
        "actions.home_upgrade_2.name": "Paint Upgrade",
        "actions.home_upgrade_2.description": "120 silver. Damp down; new nameplate.",
        "actions.home_upgrade_2.result": "Walls whitened. Lamp dared brighter.",
        "actions.home_upgrade_3.name": "Street Flat Upgrade",
        "actions.home_upgrade_3.description": "300 silver. Need wheels or network.",
        "actions.home_upgrade_3.result": "A proper parlor. Alley hears your step.",
        "actions.home_upgrade_4.name": "Move to Harbor Villa",
        "actions.home_upgrade_4.description": "650 silver. Elite network required.",
        "actions.home_upgrade_4.result": "New lintel. Voices soften.",
        "actions.home_drive.name": "Drive Out",
        "actions.home_drive.description": "Open harbor bus to any stop (free).",
        "actions.home_drive.result": "Engine turns. You're on the road.",
        "dialogue_choices.dch_dlg_garage_buy_1_ok.label": "Deal",
        "dialogue_choices.dch_dlg_garage_buy_2_ok.label": "Monthly",
        "dialogue_choices.dch_dlg_garage_buy_3_ok.label": "Take it",
        "dialogue_choices.dch_dlg_garage_buy_4_ok.label": "Drive home",
        "dialogue_choices.dch_dlg_home_up_2_ok.label": "Start",
        "dialogue_choices.dch_dlg_home_up_3_ok.label": "Upgrade",
        "dialogue_choices.dch_dlg_home_up_4_ok.label": "Move in",
        "dialogue_lines.dlg_garage_buy_1_l01.text": "Bikes gleam in the shed.",
        "dialogue_lines.dlg_garage_buy_1_l02.text": "This one.",
        "dialogue_lines.dlg_garage_buy_1_l03.text": "One bell — the dock road shortens.",
        "dialogue_lines.dlg_garage_buy_2_l01.text": "Rickshaw man nods: monthly, the street will know you.",
        "dialogue_lines.dlg_garage_buy_2_l02.text": "Book it.",
        "dialogue_lines.dlg_garage_buy_2_l03.text": "Curtain lifts; your back straightens.",
        "dialogue_lines.dlg_garage_buy_3_l01.text": "The motorcycle roars; cups jump.",
        "dialogue_lines.dlg_garage_buy_3_l02.text": "The loud one.",
        "dialogue_lines.dlg_garage_buy_3_l03.text": "Sharp in the nose — and sharp in the chest.",
        "dialogue_lines.dlg_garage_buy_4_l01.text": "A black sedan waits like it breathes.",
        "dialogue_lines.dlg_garage_buy_4_l02.text": "Home.",
        "dialogue_lines.dlg_garage_buy_4_l03.text": "Wheels turn; the harbor looks twice.",
        "dialogue_lines.dlg_home_up_2_l01.text": "Contractor: paint and a latch will hold the damp.",
        "dialogue_lines.dlg_home_up_2_l02.text": "Do it.",
        "dialogue_lines.dlg_home_up_2_l03.text": "Walls white. The lamp may shine.",
        "dialogue_lines.dlg_home_up_3_l01.text": "Street window open — the alley hears your step.",
        "dialogue_lines.dlg_home_up_3_l02.text": "Upgrade.",
        "dialogue_lines.dlg_home_up_3_l03.text": "A proper chair. Wanqing will pause.",
        "dialogue_lines.dlg_home_up_4_l01.text": "Villa plans: steps, iron, lintel.",
        "dialogue_lines.dlg_home_up_4_l02.text": "This one.",
        "dialogue_lines.dlg_home_up_4_l03.text": "New plate. Softer talk outside.",
        "transit.title": "Harbor Ring",
        "transit.fare": "Fare {n} silver · no period cost",
        "transit.fare_free": "Monthly pass · where to?",
        "transit.to": "To {name}",
        "transit.broke": "Can't afford the fare. Work the dock first.",
        "transit.stop_mark": "Stop",
        "tip.transit": "Blue rings at each door are Harbor Ring stops: interact, pick a stop, 2 silver, no period cost. Free from rickshaw tier up.",
        "tip.garage": "South end of West Street: Garage — bike → rickshaw → motorcycle → sedan.",
        "tip.home_upgrade": "Home Contractor upgrades: rental → flat → street flat → villa. Nameplate changes.",
        "tip.tea_house": "West Street Tea House: gossip, toasts, tales; evening broker in back.",
        "ui.hud.vehicle": "Ride",
        "ui.hud.home_tier": "Home",
        "quest.enter_home.hint": "1. Return to the harbor||2. Walk to Home on the north street (or bus to Home stop)||3. Enter at the door||4. Rest, intel, and planning hub",
    }
    upsert_l10n(ROOT / "l10n" / "zh_CN.csv", zh)
    upsert_l10n(ROOT / "l10n" / "en.csv", en)
    print("done")


if __name__ == "__main__":
    main()
