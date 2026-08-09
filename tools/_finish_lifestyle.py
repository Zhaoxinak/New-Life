# -*- coding: utf-8 -*-
from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs" / "tables" / "packs" / "core"


def read_csv(path: Path) -> tuple[list[str], list[dict]]:
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
    for k, val in updates.items():
        if k in seen:
            continue
        if "," in val or '"' in val or val.startswith(" "):
            esc = val.replace('"', '""')
            out.append(f'{k},"{esc}"')
        else:
            out.append(f"{k},{val}")
    path.write_text("\n".join(out) + "\n", encoding="utf-8-sig")
    print(path.name, "l10n", len(updates))


def fix_conditions() -> None:
    path = ROOT / "conditions.csv"
    fields, rows = read_csv(path)
    keep = []
    for r in rows:
        rid = str(r.get("id", ""))
        if (
            rid.startswith("c_garage_")
            or rid.startswith("c_home_up_")
            or rid.startswith("c_home_drive")
            or rid.startswith("c_chatter_home_tier")
            or rid.startswith("c_chatter_vehicle_")
        ):
            continue
        keep.append(r)
    rows = keep

    def add(cid, owner_type, owner_id, group, typ, key, op, value, notes=""):
        row = {k: "" for k in fields}
        row.update(
            {
                "id": cid,
                "owner_type": owner_type,
                "owner_id": owner_id,
                "cond_group": str(group),
                "cond_type": typ,
                "key": key,
                "op": op,
                "value": str(value),
                "notes": notes,
            }
        )
        rows.append(row)

    add("c_garage_buy_1_money", "action", "garage_buy_1", 1, "stat", "money", "gte", 60)
    add("c_garage_buy_1_day", "action", "garage_buy_1", 1, "day", "day", "gte", 3)
    add("c_garage_buy_1_tier", "action", "garage_buy_1", 1, "stat", "vehicle_tier", "eq", 0)
    add("c_garage_buy_2_money", "action", "garage_buy_2", 1, "stat", "money", "gte", 150)
    add("c_garage_buy_2_day", "action", "garage_buy_2", 1, "day", "day", "gte", 7)
    add("c_garage_buy_2_net", "action", "garage_buy_2", 1, "stat", "network_base", "gte", 35)
    add("c_garage_buy_2_tier", "action", "garage_buy_2", 1, "stat", "vehicle_tier", "eq", 1)
    add("c_garage_buy_3_money", "action", "garage_buy_3", 1, "stat", "money", "gte", 320)
    add("c_garage_buy_3_day", "action", "garage_buy_3", 1, "day", "day", "gte", 12)
    add("c_garage_buy_3_tier", "action", "garage_buy_3", 1, "stat", "vehicle_tier", "eq", 2)
    add("c_garage_buy_3_elite", "action", "garage_buy_3", 1, "stat", "network_elite", "gte", 8)
    add("c_garage_buy_3_money_g2", "action", "garage_buy_3", 2, "stat", "money", "gte", 320)
    add("c_garage_buy_3_day_g2", "action", "garage_buy_3", 2, "day", "day", "gte", 12)
    add("c_garage_buy_3_tier_g2", "action", "garage_buy_3", 2, "stat", "vehicle_tier", "eq", 2)
    add("c_garage_buy_3_net_alt", "action", "garage_buy_3", 2, "stat", "network_base", "gte", 55)
    add("c_garage_buy_4_money", "action", "garage_buy_4", 1, "stat", "money", "gte", 700)
    add("c_garage_buy_4_day", "action", "garage_buy_4", 1, "day", "day", "gte", 18)
    add("c_garage_buy_4_tier", "action", "garage_buy_4", 1, "stat", "vehicle_tier", "eq", 3)
    add("c_garage_buy_4_elite", "action", "garage_buy_4", 1, "stat", "network_elite", "gte", 25)
    add("c_home_up_2_money", "action", "home_upgrade_2", 1, "stat", "money", "gte", 120)
    add("c_home_up_2_day", "action", "home_upgrade_2", 1, "day", "day", "gte", 5)
    add("c_home_up_2_tier", "action", "home_upgrade_2", 1, "stat", "home_tier", "eq", 1)
    add("c_home_up_3_money", "action", "home_upgrade_3", 1, "stat", "money", "gte", 300)
    add("c_home_up_3_day", "action", "home_upgrade_3", 1, "day", "day", "gte", 10)
    add("c_home_up_3_tier", "action", "home_upgrade_3", 1, "stat", "home_tier", "eq", 2)
    add("c_home_up_3_bike", "action", "home_upgrade_3", 1, "stat", "vehicle_tier", "gte", 1)
    add("c_home_up_3_money_g2", "action", "home_upgrade_3", 2, "stat", "money", "gte", 300)
    add("c_home_up_3_day_g2", "action", "home_upgrade_3", 2, "day", "day", "gte", 10)
    add("c_home_up_3_tier_g2", "action", "home_upgrade_3", 2, "stat", "home_tier", "eq", 2)
    add("c_home_up_3_net_g2", "action", "home_upgrade_3", 2, "stat", "network_base", "gte", 40)
    add("c_home_up_4_money", "action", "home_upgrade_4", 1, "stat", "money", "gte", 650)
    add("c_home_up_4_day", "action", "home_upgrade_4", 1, "day", "day", "gte", 16)
    add("c_home_up_4_tier", "action", "home_upgrade_4", 1, "stat", "home_tier", "eq", 3)
    add("c_home_up_4_elite", "action", "home_upgrade_4", 1, "stat", "network_elite", "gte", 20)
    add("c_home_drive_car", "action", "home_drive", 1, "stat", "vehicle_tier", "gte", 4)
    add("c_chatter_home_tier2", "idle_chatter", "chatter_home_tier2", 1, "stat", "home_tier", "gte", 2)
    add("c_chatter_vehicle_rickshaw", "idle_chatter", "chatter_vehicle_rickshaw", 1, "stat", "vehicle_tier", "gte", 2)
    write_csv(path, fields, rows)
    print("conditions.csv fixed", sum(1 for r in rows if r["id"].startswith("c_garage_") or r["id"].startswith("c_home_")))


def add_chatter() -> None:
    path = ROOT / "idle_chatter.csv"
    fields, rows = read_csv(path)
    existing = {r["id"] for r in rows}
    news = [
        ("chatter_garage_01", "garage", "", "any", "all", "10", "1", "1", "车行闲话"),
        ("chatter_garage_02", "garage", "garage_counter", "any", "all", "8", "1", "1", ""),
        ("chatter_home_tier2", "home", "", "any", "all", "7", "1", "1", "住房档≥2"),
        ("chatter_vehicle_rickshaw", "plaza", "", "any", "all", "6", "1", "1", "座驾≥2"),
    ]
    keys = ["id", "location_id", "hotspot_id", "periods", "tags", "weight", "cooldown_days", "enabled", "notes"]
    added = 0
    for n in news:
        if n[0] in existing:
            continue
        row = {k: "" for k in fields}
        for i, k in enumerate(keys):
            if k in fields:
                row[k] = n[i]
        rows.append(row)
        added += 1
    write_csv(path, fields, rows)
    print("idle_chatter +", added)


def l10n() -> None:
    zh = {
        "quest.enter_home.title": "回到自己的自宅",
        "quest.enter_home.hint": "1. 回到港区||2. 走到北署街正中「自宅」（或坐公交到自宅站）||3. 走近门口进入||4. 这里是降嫌疑、整理情报的据点；「宅基包工」可升级门脸",
        "quest.home_settle.title": "在家安顿（整理或休息）",
        "quest.home_settle.hint": "1. 进入「自宅」||2. 任选其一：||　·「书桌」→「整理情报」或「分析局势」||　· 已是晚上：「床边」→「休息恢复」（降嫌疑）||　·「宅基包工」→升级房产（可选）||3. 做完整理/休息一项即完成",
        "quest.b_wedge.hint": "任选其一做完即过（为后面对立攒「父子张力」→目标≥70，悬停顶栏「局势」可看）：||A. 宏远 →「副理办公室」→「传递假消息」（情报≥15，中午）或「对接副理」（白天/中午）||B. 信任≥55 且第14天后：宏远 →「老板办公室」→「讨好老板」||C. 第7天起下午/晚：自宅 →「客厅」→「与未婚妻对话」；晚晴好感≥40 可晚上「引导她吹枕边风」||D. 第22天+货仓主管：宏远 →「财务室门口」→「栽赃财务漏洞」（情报≥25）",
        "quest.deepen.hint": "任选其一做完即可：||A. 信任≥55、第14天起：宏远 →「老板办公室」→「讨好老板」/「接受老板任务」/「主动背锅」||B. 第8天起下午/晚：码头 →「码头拐角」→「与竞品线人接头」||C. 第7天起下午/晚：自宅 →「客厅」→「与未婚妻对话」或「引导她吹枕边风」（好感≥40）||D. A线：通洋 →「业务洽谈室」→「商议挖人/抢单」（情报≥20、声望≥20）||E. C线：交易所 →「交易大厅」→「买入…」（钱≥50）或「做空…」（钱≥80）",
        "dialogue_lines.dlg_home_window_l01.text": "自宅窗玻璃上结着雾。巷口灯火一晃一晃，像有人故意走慢。",
        "idle_chatter.chatter_garage_01.text": "轮胎味混着机油。有人在问：黄包车包月还是先骑脚踏？",
        "idle_chatter.chatter_garage_02.text": "柜上算盘一响：上牌、交钱、钥匙——气派是一档一价。",
        "idle_chatter.chatter_home_tier2.text": "粉刷味还没散尽。邻居路过，会多看你家门一眼。",
        "idle_chatter.chatter_vehicle_rickshaw.text": "有人嘀咕：海哥包月了黄包车，港湾环线都免票了。",
    }
    en = {
        "quest.enter_home.title": "Go Home",
        "quest.enter_home.hint": "1. Return to the harbor||2. Walk to Home on the north street (or bus to Home stop)||3. Enter at the door||4. Rest/intel hub; Contractor can upgrade the facade",
        "quest.home_settle.title": "Settle at Home",
        "quest.home_settle.hint": "1. Enter Home||2. Desk → Organize/Analyze; or Night Bedside → Rest; or Contractor (optional)||3. Organize or Rest completes it",
        "quest.b_wedge.hint": "Do any one (raise Father-Son Tension toward ≥70; hover Mood):||A. Hongyuan → VP Office → Fake Tip (Intel≥15, noon) or Meet VP||B. Trust≥55 from Day 14: Boss Office → Flatter||C. From Day 7 afternoon/evening: Home → Living → Talk to fiancée; Favor≥40 for pillow talk||D. Day 22+ Warehouse Manager: Finance Door → Frame the Books (Intel≥25)",
        "quest.deepen.hint": "Do any one:||A. Trust≥55 from Day 14: Boss Office actions||B. From Day 8 afternoon/evening: Dock Corner → Rival Contact||C. From Day 7 afternoon/evening: Home Living → fiancée talk||D. Route A: Tongyang Meet → Plot Poach||E. Route C: Exchange Hall → Buy/Short",
        "dialogue_lines.dlg_home_window_l01.text": "Fog on the home window. Alley lamps flicker like someone slowing on purpose.",
        "idle_chatter.chatter_garage_01.text": "Tire and oil. Someone asks: monthly rickshaw, or a bicycle first?",
        "idle_chatter.chatter_garage_02.text": "Abacus at the counter: papers, coin, keys — grandeur priced by tier.",
        "idle_chatter.chatter_home_tier2.text": "Paint smell still hangs. Neighbors glance at your door.",
        "idle_chatter.chatter_vehicle_rickshaw.text": "Whispers: Hai booked a rickshaw — Harbor Ring rides free.",
    }
    upsert_l10n(ROOT / "l10n" / "zh_CN.csv", zh)
    upsert_l10n(ROOT / "l10n" / "en.csv", en)


def smoke() -> None:
    errors = []
    _, locs = read_csv(ROOT / "locations.csv")
    ids = {r["id"] for r in locs}
    for need in ["company", "home", "rival", "tea_house", "plaza", "garage", "exchange", "dock"]:
        if need not in ids:
            errors.append(f"missing location {need}")
    _, acts = read_csv(ROOT / "actions.csv")
    aids = {r["id"] for r in acts}
    for need in [
        "garage_buy_1",
        "garage_buy_2",
        "garage_buy_3",
        "garage_buy_4",
        "home_upgrade_2",
        "home_upgrade_3",
        "home_upgrade_4",
        "home_drive",
    ]:
        if need not in aids:
            errors.append(f"missing action {need}")
    _, conds = read_csv(ROOT / "conditions.csv")
    for r in conds:
        if str(r["id"]).startswith("c_garage_buy_1"):
            if str(r.get("cond_type", "")) == "" or str(r.get("cond_group", "")) == "":
                errors.append(f"bad cond {r['id']}")
    # sample one
    sample = next((r for r in conds if r["id"] == "c_garage_buy_1_money"), None)
    if not sample or sample.get("cond_type") != "stat" or sample.get("key") != "money":
        errors.append(f"c_garage_buy_1_money malformed: {sample}")
    _, tips = read_csv(ROOT / "tips.csv")
    tids = {r["id"] for r in tips}
    for need in ["tip_transit", "tip_garage", "tip_home_upgrade"]:
        if need not in tids:
            errors.append(f"missing tip {need}")
    _, stats = read_csv(ROOT / "stats.csv")
    sids = {r["id"] for r in stats}
    for need in ["vehicle_tier", "home_tier"]:
        if need not in sids:
            errors.append(f"missing stat {need}")
    game = Path(__file__).resolve().parents[1] / "game"
    for rel in [
        "art/world/harbor_outdoor.png",
        "art/locations/garage.png",
        "world/TransitStop.gd",
        "ui/TransitPanel.gd",
        "world/HarborOutdoor.gd",
    ]:
        if not (game / rel).exists():
            errors.append(f"missing file {rel}")
    text = (game / "world" / "HarborOutdoor.gd").read_text(encoding="utf-8")
    for need in ["company", "home", "rival", "tea_house", "plaza", "garage", "exchange", "dock"]:
        if f'"{need}"' not in text:
            errors.append(f"LAYOUT missing {need}")
    if "TransitStopScene" not in text:
        errors.append("HarborOutdoor missing TransitStopScene")
    main = (game / "scenes" / "Main.tscn").read_text(encoding="utf-8")
    if "TransitPanel" not in main:
        errors.append("Main.tscn missing TransitPanel")
    zh = (ROOT / "l10n" / "zh_CN.csv").read_text(encoding="utf-8-sig")
    for key in ["tip.transit", "tip.garage", "tip.home_upgrade", "locations.garage.name", "quest.enter_home.title"]:
        if key not in zh:
            errors.append(f"zh missing {key}")
    if "出租屋」" in zh and "quest.home_settle.hint" in zh:
        # soft check: home_settle should say 自宅
        for line in zh.splitlines():
            if line.startswith("quest.home_settle.hint,") and "出租屋" in line and "自宅" not in line:
                errors.append("quest.home_settle.hint still rental-only")
    if errors:
        print("SMOKE FAIL:")
        for e in errors:
            print(" -", e)
        raise SystemExit(1)
    print("SMOKE OK")


def main() -> None:
    fix_conditions()
    add_chatter()
    l10n()
    smoke()


if __name__ == "__main__":
    main()
