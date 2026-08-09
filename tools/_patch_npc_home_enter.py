# -*- coding: utf-8 -*-
"""Append enterable NPC-home locations, hotspots, actions, effects, dialogues, l10n."""
from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "docs" / "tables" / "packs" / "core"

HOMES = [
    {
        "npc": "tea_waiter",
        "loc": "nh_tea_waiter",
        "name_zh": "小福栖处",
        "name_en": "Xiaofu's Nest",
        "desk_zh": "茶笺抽屉",
        "desk_en": "Tea Notes Drawer",
        "stash_zh": "零钱罐",
        "stash_en": "Tip Jar",
        "intel": 4,
        "sus": 2,
        "money": 8,
        "flavor_zh": "抽屉里夹着茶客闲话：谁今晚在通洋多坐了一盏。",
        "flavor_en": "Scribbled guest chatter: who lingered an extra cup at Tongyang.",
        "stash_zh_line": "罐底几枚铜板，还带着糖霜味。",
        "stash_en_line": "A few coins under sugar dust.",
    },
    {
        "npc": "stall_aunt",
        "loc": "nh_stall_aunt",
        "name_zh": "阿婶糖糕铺后屋",
        "name_en": "Auntie's Back Room",
        "desk_zh": "账本匣",
        "desk_en": "Ledger Box",
        "stash_zh": "糖罐暗格",
        "stash_en": "Sugar Tin Cache",
        "intel": 5,
        "sus": 2,
        "money": 12,
        "flavor_zh": "账角记着谁赊了糖糕，谁替谁带过口信。",
        "flavor_en": "Margins note who tabbed sweets—and who carried whose message.",
        "stash_zh_line": "暗格里一卷零钞，纸边沾着红豆沙。",
        "stash_en_line": "Spare cash sticky with red-bean paste.",
    },
    {
        "npc": "garage_hand",
        "loc": "nh_garage_hand",
        "name_zh": "阿强的棚屋",
        "name_en": "Aqiang's Shed",
        "desk_zh": "零件登记板",
        "desk_en": "Parts Board",
        "stash_zh": "工具箱夹层",
        "stash_en": "Toolbox Liner",
        "intel": 4,
        "sus": 1,
        "money": 10,
        "flavor_zh": "板上写着谁的车夜里进过棚，油渍旁有个圈。",
        "flavor_en": "Board marks whose car rolled in at night—circled in grease.",
        "stash_zh_line": "夹层里几枚垫圈钱，还有一张旧船票根。",
        "stash_en_line": "Washer coins and a torn ferry stub.",
    },
    {
        "npc": "dock_foreman",
        "loc": "nh_dock_foreman",
        "name_zh": "老号工棚",
        "name_en": "Old Mark's Shed",
        "desk_zh": "货单木匣",
        "desk_en": "Manifest Crate",
        "stash_zh": "酒壶暗袋",
        "stash_en": "Flask Pocket",
        "intel": 6,
        "sus": 3,
        "money": 6,
        "flavor_zh": "匣里夹着未报的船期——字迹被潮气咬过。",
        "flavor_en": "An unfiled sailing scrap, ink bitten by damp.",
        "stash_zh_line": "暗袋里半壶酒，瓶底压着一枚铜章拓印。",
        "stash_en_line": "Half a flask—and a copper seal rubbing under it.",
    },
    {
        "npc": "zhou_shaoting",
        "loc": "nh_zhou_shaoting",
        "name_zh": "少霆外宅",
        "name_en": "Shaoting's Annex",
        "desk_zh": "书桌密格",
        "desk_en": "Hidden Desk Slot",
        "stash_zh": "衣橱夹缝",
        "stash_en": "Wardrobe Seam",
        "intel": 7,
        "sus": 4,
        "money": 20,
        "flavor_zh": "密格里是赌桌筹码与对父亲不满的半句话。",
        "flavor_en": "Chips and a half-sentence of resentment toward his father.",
        "stash_zh_line": "夹缝里一叠小票，墨水贵得刺眼。",
        "stash_en_line": "Receipts in ink too expensive to ignore.",
    },
    {
        "npc": "chen_manager",
        "loc": "nh_chen_manager",
        "name_zh": "通洋驻处",
        "name_en": "Tongyang Quarters",
        "desk_zh": "公文匣",
        "desk_en": "Document Case",
        "stash_zh": "印鉴匣旁",
        "stash_en": "Beside the Seal Box",
        "intel": 7,
        "sus": 3,
        "money": 15,
        "flavor_zh": "匣中夹页写着通洋与宏远的对账缺口。",
        "flavor_en": "A slip flags a Tongyang–Hongyuan ledger gap.",
        "stash_zh_line": "印泥旁散着几枚银角，像故意留下的诱饵。",
        "stash_en_line": "Silver bits by the ink pad—bait, maybe.",
    },
]


def _read(path: Path) -> list[dict]:
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def _write(path: Path, rows: list[dict], fieldnames: list[str] | None = None) -> None:
    if not rows and fieldnames is None:
        return
    fields = fieldnames or list(rows[0].keys())
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, lineterminator="\n")
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in fields})


def _append_unique(path: Path, new_rows: list[dict], id_key: str = "id") -> None:
    rows = _read(path)
    ids = {str(r.get(id_key, "")) for r in rows}
    fields = list(rows[0].keys()) if rows else list(new_rows[0].keys())
    added = 0
    for nr in new_rows:
        if str(nr.get(id_key, "")) in ids:
            continue
        rows.append({k: nr.get(k, "") for k in fields})
        ids.add(str(nr[id_key]))
        added += 1
    _write(path, rows, fields)
    print(f"{path.name}: +{added}")


def _upsert_l10n(path: Path, pairs: dict[str, str]) -> None:
    rows = _read(path)
    by_key = {str(r.get("key", "")): r for r in rows}
    fields = list(rows[0].keys()) if rows else ["key", "text"]
    for k, text in pairs.items():
        if k in by_key:
            by_key[k]["text"] = text
        else:
            by_key[k] = {"key": k, "text": text}
    # preserve order: old then new keys
    out = []
    seen = set()
    for r in rows:
        k = str(r.get("key", ""))
        out.append(by_key[k])
        seen.add(k)
    for k, r in by_key.items():
        if k not in seen:
            out.append(r)
    _write(path, out, fields)
    print(f"{path.name}: l10n {len(pairs)} keys")


def patch_npc_homes() -> None:
    path = CORE / "npc_homes.csv"
    rows = _read(path)
    fields = list(rows[0].keys())
    if "location_id" not in fields:
        fields.append("location_id")
    loc_by_npc = {h["npc"]: h["loc"] for h in HOMES}
    for r in rows:
        nid = str(r.get("npc_id", ""))
        r["location_id"] = loc_by_npc.get(nid, r.get("location_id", ""))
    # rewrite with known order / coords from current design
    order = [
        ("tea_waiter", "0.225", "0.430", "1", "5a8a70", "dlg_street_waiter", "西街茶馆东侧小路屋"),
        ("stall_aunt", "0.250", "0.605", "1", "c07070", "dlg_street_aunt", "广场东侧路边屋"),
        ("garage_hand", "0.245", "0.775", "1", "6a6a72", "dlg_street_garage", "车行东侧路边屋"),
        ("dock_foreman", "0.455", "0.695", "1", "8a6a4a", "dlg_street_foreman", "码头脊西侧工棚"),
        ("zhou_shaoting", "0.780", "0.255", "1", "6b4e3d", "dlg_street_son", "对手宅南侧小路旁"),
        ("chen_manager", "0.680", "0.455", "1", "2f4f45", "dlg_street_chen", "通洋支线北侧宅"),
        ("su_qing", "0.520", "0.300", "0", "4a5568", "dlg_street_su", "住主角自宅线"),
        ("zhou_hongye", "0.195", "0.300", "0", "5a4030", "dlg_street_boss", "多在公司"),
    ]
    out = []
    for npc, x, y, show, tint, dlg, notes in order:
        out.append(
            {
                "npc_id": npc,
                "home_x": x,
                "home_y": y,
                "show_cottage": show,
                "tint": tint,
                "street_dialogue_id": dlg,
                "notes": notes,
                "location_id": loc_by_npc.get(npc, ""),
            }
        )
    _write(path, out, ["npc_id", "home_x", "home_y", "show_cottage", "tint", "street_dialogue_id", "notes", "location_id"])
    print("npc_homes.csv rewritten with location_id")


def main() -> None:
    patch_npc_homes()

    loc_rows = []
    hs_rows = []
    act_rows = []
    fx_rows = []
    dlg_rows = []
    line_rows = []
    zh: dict[str, str] = {}
    en: dict[str, str] = {}

    sort0 = 40
    for i, h in enumerate(HOMES):
        loc = h["loc"]
        loc_rows.append(
            {
                "id": loc,
                "default_periods": "any",
                "tags": "npc_home|all",
                "sort_order": str(sort0 + i),
                "enabled": "1",
                "start_unlocked": "1",
                "notes": f"{h['npc']} residence",
            }
        )
        desk = f"{loc}_desk"
        stash = f"{loc}_stash"
        hs_rows += [
            {
                "id": desk,
                "location_id": loc,
                "suspicion_mult": "0.8",
                "periods": "any",
                "tags": "intel|search",
                "sort_order": "1",
                "enabled": "1",
                "start_unlocked": "1",
                "pos_x": "320",
                "pos_y": "480",
                "notes": "search papers",
            },
            {
                "id": stash,
                "location_id": loc,
                "suspicion_mult": "0.6",
                "periods": "any",
                "tags": "loot|search",
                "sort_order": "2",
                "enabled": "1",
                "start_unlocked": "1",
                "pos_x": "640",
                "pos_y": "560",
                "notes": "small loot",
            },
        ]
        a_desk = f"{loc}_search"
        a_stash = f"{loc}_rummage"
        dlg_desk = f"dlg_{loc}_search"
        dlg_stash = f"dlg_{loc}_rummage"
        act_rows += [
            {
                "id": a_desk,
                "hotspot_id": desk,
                "periods": "any",
                "tags": "all",
                "time_cost": "1",
                "suspicion_base": str(h["sus"]),
                "cooldown_days": "1",
                "max_uses": "0",
                "sort_order": "1",
                "enabled": "1",
                "notes": "search intel",
                "dialogue_id": dlg_desk,
                "stock_rule_id": "",
                "check_id": "",
            },
            {
                "id": a_stash,
                "hotspot_id": stash,
                "periods": "any",
                "tags": "all",
                "time_cost": "1",
                "suspicion_base": "1",
                "cooldown_days": "1",
                "max_uses": "0",
                "sort_order": "2",
                "enabled": "1",
                "notes": "rummage loot",
                "dialogue_id": dlg_stash,
                "stock_rule_id": "",
                "check_id": "",
            },
        ]
        fx_rows += [
            {
                "id": f"fx_{a_desk}_intel",
                "owner_type": "action",
                "owner_id": a_desk,
                "effect_type": "stat",
                "target": "",
                "key": "intel",
                "op": "add",
                "value": str(h["intel"]),
                "chance": "1",
                "notes": "",
            },
            {
                "id": f"fx_{a_desk}_sus",
                "owner_type": "action",
                "owner_id": a_desk,
                "effect_type": "stat",
                "target": "",
                "key": "suspicion",
                "op": "add",
                "value": str(h["sus"]),
                "chance": "1",
                "notes": "",
            },
            {
                "id": f"fx_{a_stash}_money",
                "owner_type": "action",
                "owner_id": a_stash,
                "effect_type": "stat",
                "target": "",
                "key": "money",
                "op": "add",
                "value": str(h["money"]),
                "chance": "1",
                "notes": "",
            },
            {
                "id": f"fx_{a_stash}_intel",
                "owner_type": "action",
                "owner_id": a_stash,
                "effect_type": "stat",
                "target": "",
                "key": "intel",
                "op": "add",
                "value": "1",
                "chance": "1",
                "notes": "",
            },
        ]
        dlg_rows += [
            {"id": dlg_desk, "tags": "npc_home", "priority": "40", "once": "0", "enabled": "1", "notes": h["npc"]},
            {"id": dlg_stash, "tags": "npc_home", "priority": "40", "once": "0", "enabled": "1", "notes": h["npc"]},
        ]
        line_rows += [
            {
                "id": f"{dlg_desk}_l01",
                "dialogue_id": dlg_desk,
                "line_index": "1",
                "speaker_id": "narrator",
                "emotion": "neutral",
                "enabled": "1",
                "notes": "",
            },
            {
                "id": f"{dlg_stash}_l01",
                "dialogue_id": dlg_stash,
                "line_index": "1",
                "speaker_id": "narrator",
                "emotion": "neutral",
                "enabled": "1",
                "notes": "",
            },
        ]

        zh.update(
            {
                f"locations.{loc}.name": h["name_zh"],
                f"locations.{loc}.description": f"可潜入翻找。屋主：{h['name_zh']}",
                f"hotspots.{desk}.name": h["desk_zh"],
                f"hotspots.{desk}.description": "翻找纸片与账角，拼一点码头消息。",
                f"hotspots.{stash}.name": h["stash_zh"],
                f"hotspots.{stash}.description": "顺手摸一点零钱或小物证。",
                f"actions.{a_desk}.name": "翻找文书",
                f"actions.{a_desk}.description": "花一点时间，换一点线头。",
                f"actions.{a_desk}.result": h["flavor_zh"],
                f"actions.{a_stash}.name": "摸摸暗处",
                f"actions.{a_stash}.description": "也许有零钱，也许只是灰。",
                f"actions.{a_stash}.result": h["stash_zh_line"],
                f"dialogue_lines.{dlg_desk}_l01.text": h["flavor_zh"],
                f"dialogue_lines.{dlg_stash}_l01.text": h["stash_zh_line"],
                f"npc_homes.{h['npc']}": h["name_zh"],
            }
        )
        en.update(
            {
                f"locations.{loc}.name": h["name_en"],
                f"locations.{loc}.description": f"Snoopable annex. Owner: {h['name_en']}",
                f"hotspots.{desk}.name": h["desk_en"],
                f"hotspots.{desk}.description": "Papers and margins—harbor threads.",
                f"hotspots.{stash}.name": h["stash_en"],
                f"hotspots.{stash}.description": "Loose change or a small tell.",
                f"actions.{a_desk}.name": "Search Papers",
                f"actions.{a_desk}.description": "Spend a beat; pull a thread.",
                f"actions.{a_desk}.result": h["flavor_en"],
                f"actions.{a_stash}.name": "Rummage",
                f"actions.{a_stash}.description": "Coins—or dust.",
                f"actions.{a_stash}.result": h["stash_en_line"],
                f"dialogue_lines.{dlg_desk}_l01.text": h["flavor_en"],
                f"dialogue_lines.{dlg_stash}_l01.text": h["stash_en_line"],
                f"npc_homes.{h['npc']}": h["name_en"],
            }
        )

    _append_unique(CORE / "locations.csv", loc_rows)
    _append_unique(CORE / "hotspots.csv", hs_rows)
    _append_unique(CORE / "actions.csv", act_rows)
    _append_unique(CORE / "effects.csv", fx_rows)
    _append_unique(CORE / "dialogues.csv", dlg_rows)
    _append_unique(CORE / "dialogue_lines.csv", line_rows)
    _upsert_l10n(CORE / "l10n" / "zh_CN.csv", zh)
    _upsert_l10n(CORE / "l10n" / "en.csv", en)
    print("done")


if __name__ == "__main__":
    main()
