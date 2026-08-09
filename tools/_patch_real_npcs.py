# -*- coding: utf-8 -*-
from __future__ import annotations

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs" / "tables" / "packs" / "core"


def write_csv(path: Path, fields: list[str], rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, lineterminator="\n")
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in fields})


def read_csv(path: Path) -> tuple[list[str], list[dict]]:
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        r = csv.DictReader(f)
        return list(r.fieldnames or []), list(r)


def append_rows(path: Path, key: str, news: list[dict]) -> None:
    fields, rows = read_csv(path)
    have = {str(r.get(key, "")) for r in rows}
    for n in news:
        if str(n.get(key, "")) in have:
            continue
        rows.append({**{k: "" for k in fields}, **n})
        have.add(str(n.get(key, "")))
    write_csv(path, fields, rows)


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
            if "," in val or '"' in val or val.startswith(" "):
                out.append(f'{k},"{val.replace(chr(34), chr(34)+chr(34))}"')
            else:
                out.append(f"{k},{val}")
            seen.add(k)
        else:
            out.append(line)
    for k, val in updates.items():
        if k in seen:
            continue
        if "," in val or '"' in val or val.startswith(" "):
            out.append(f'{k},"{val.replace(chr(34), chr(34)+chr(34))}"')
        else:
            out.append(f"{k},{val}")
    path.write_text("\n".join(out) + "\n", encoding="utf-8-sig")


def main() -> None:
    # pack.json tables
    meta_path = ROOT / "pack.json"
    meta = json.loads(meta_path.read_text(encoding="utf-8"))
    tables = list(meta.get("tables", []))
    for t in ("npc_homes", "npc_schedules"):
        if t not in tables:
            # insert after npcs
            if "npcs" in tables:
                i = tables.index("npcs") + 1
                tables[i:i] = [t] if t == "npc_homes" else []
                if t == "npc_schedules":
                    hi = tables.index("npc_homes") + 1 if "npc_homes" in tables else i
                    if "npc_schedules" not in tables:
                        tables.insert(hi, "npc_schedules")
            else:
                tables.append(t)
    # ensure both
    if "npc_homes" not in tables:
        tables.append("npc_homes")
    if "npc_schedules" not in tables:
        tables.append("npc_schedules")
    meta["tables"] = tables
    meta["version"] = "0.9.6"
    meta["description"] = "Demo 0.9.6：港区真NPC作息与街访。"
    meta_path.write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    append_rows(
        ROOT / "npcs.csv",
        "id",
        [
            {"id": "dock_foreman", "portrait_key": "", "tags": "harbor|street", "enabled": "1", "is_player": "0", "notes": "码头工头"},
            {"id": "stall_aunt", "portrait_key": "", "tags": "harbor|street", "enabled": "1", "is_player": "0", "notes": "广场摊贩"},
            {"id": "tea_waiter", "portrait_key": "", "tags": "harbor|street", "enabled": "1", "is_player": "0", "notes": "茶馆跑堂"},
            {"id": "garage_hand", "portrait_key": "", "tags": "harbor|street", "enabled": "1", "is_player": "0", "notes": "车行伙计"},
        ],
    )

    write_csv(
        ROOT / "npc_homes.csv",
        ["npc_id", "home_x", "home_y", "show_cottage", "tint", "street_dialogue_id", "notes"],
        [
            {"npc_id": "dock_foreman", "home_x": "0.30", "home_y": "0.86", "show_cottage": "1", "tint": "8a6a4a", "street_dialogue_id": "dlg_street_foreman", "notes": "码头南侧工棚"},
            {"npc_id": "stall_aunt", "home_x": "0.16", "home_y": "0.64", "show_cottage": "1", "tint": "c07070", "street_dialogue_id": "dlg_street_aunt", "notes": "广场旁"},
            {"npc_id": "tea_waiter", "home_x": "0.14", "home_y": "0.44", "show_cottage": "1", "tint": "5a8a70", "street_dialogue_id": "dlg_street_waiter", "notes": "茶馆旁"},
            {"npc_id": "garage_hand", "home_x": "0.16", "home_y": "0.88", "show_cottage": "1", "tint": "6a6a72", "street_dialogue_id": "dlg_street_garage", "notes": "车行旁"},
            {"npc_id": "su_qing", "home_x": "0.50", "home_y": "0.25", "show_cottage": "0", "tint": "4a5568", "street_dialogue_id": "dlg_street_su", "notes": "住主角自宅线"},
            {"npc_id": "zhou_shaoting", "home_x": "0.92", "home_y": "0.14", "show_cottage": "1", "tint": "6b4e3d", "street_dialogue_id": "dlg_street_son", "notes": "北署东侧少爷宅"},
            {"npc_id": "zhou_hongye", "home_x": "0.12", "home_y": "0.12", "show_cottage": "0", "tint": "5a4030", "street_dialogue_id": "dlg_street_boss", "notes": "多在公司"},
            {"npc_id": "chen_manager", "home_x": "0.88", "home_y": "0.34", "show_cottage": "1", "tint": "2f4f45", "street_dialogue_id": "dlg_street_chen", "notes": "通洋侧宅"},
        ],
    )

    sched = []
    def S(sid, npc, period, kind, dest, w="10"):
        sched.append({
            "id": sid, "npc_id": npc, "period": period, "dest_kind": kind,
            "dest_id": dest, "weight": w, "enabled": "1", "notes": "",
        })
    # residents
    S("sch_foreman_m", "dock_foreman", "morning", "building", "dock")
    S("sch_foreman_a", "dock_foreman", "afternoon", "building", "dock")
    S("sch_foreman_e", "dock_foreman", "evening", "home", "dock_foreman")
    S("sch_aunt_m", "stall_aunt", "morning", "home", "stall_aunt")
    S("sch_aunt_a", "stall_aunt", "afternoon", "building", "plaza")
    S("sch_aunt_e", "stall_aunt", "evening", "home", "stall_aunt")
    S("sch_waiter_m", "tea_waiter", "morning", "building", "tea_house")
    S("sch_waiter_a", "tea_waiter", "afternoon", "building", "tea_house")
    S("sch_waiter_e", "tea_waiter", "evening", "home", "tea_waiter")
    S("sch_garage_m", "garage_hand", "morning", "building", "garage")
    S("sch_garage_a", "garage_hand", "afternoon", "building", "garage")
    S("sch_garage_e", "garage_hand", "evening", "home", "garage_hand")
    # cast
    S("sch_su_m", "su_qing", "morning", "building", "company")
    S("sch_su_a", "su_qing", "afternoon", "building", "tea_house")
    S("sch_su_e", "su_qing", "evening", "building", "home")
    S("sch_son_m", "zhou_shaoting", "morning", "building", "company")
    S("sch_son_a", "zhou_shaoting", "afternoon", "building", "tea_house")
    S("sch_son_e", "zhou_shaoting", "evening", "home", "zhou_shaoting")
    S("sch_boss_m", "zhou_hongye", "morning", "building", "company")
    S("sch_boss_a", "zhou_hongye", "afternoon", "building", "company")
    S("sch_boss_e", "zhou_hongye", "evening", "building", "company")
    S("sch_chen_m", "chen_manager", "morning", "building", "rival")
    S("sch_chen_a", "chen_manager", "afternoon", "building", "exchange")
    S("sch_chen_e", "chen_manager", "evening", "home", "chen_manager")
    write_csv(
        ROOT / "npc_schedules.csv",
        ["id", "npc_id", "period", "dest_kind", "dest_id", "weight", "enabled", "notes"],
        sched,
    )

    append_rows(
        ROOT / "flags.csv",
        "id",
        [
            {"id": "heard_foreman_rumor", "default": "0", "tags": "street", "notes": "工头改单传闻"},
            {"id": "heard_waiter_gossip", "default": "0", "tags": "street", "notes": "跑堂闲话晚晴少霆"},
            {"id": "met_street_aunt", "default": "0", "tags": "street", "notes": ""},
            {"id": "met_garage_hand", "default": "0", "tags": "street", "notes": ""},
        ],
    )

    dlgs = [
        "dlg_street_foreman", "dlg_street_aunt", "dlg_street_waiter", "dlg_street_garage",
        "dlg_street_su", "dlg_street_son", "dlg_street_boss", "dlg_street_chen",
    ]
    append_rows(
        ROOT / "dialogues.csv",
        "id",
        [{"id": d, "tags": "street", "priority": "40", "once": "0", "enabled": "1", "notes": "街访"} for d in dlgs],
    )

    speakers = {
        "dlg_street_foreman": "dock_foreman",
        "dlg_street_aunt": "stall_aunt",
        "dlg_street_waiter": "tea_waiter",
        "dlg_street_garage": "garage_hand",
        "dlg_street_su": "su_qing",
        "dlg_street_son": "zhou_shaoting",
        "dlg_street_boss": "zhou_hongye",
        "dlg_street_chen": "chen_manager",
    }
    lines = []
    choices = []
    for d, sp in speakers.items():
        lines.append({"id": f"{d}_l01", "dialogue_id": d, "sort": "1", "speaker_id": sp, "emotion": "neutral", "enabled": "1", "notes": ""})
        lines.append({"id": f"{d}_l02", "dialogue_id": d, "sort": "2", "speaker_id": "player", "emotion": "resolve", "enabled": "1", "notes": ""})
        lines.append({"id": f"{d}_l03", "dialogue_id": d, "sort": "3", "speaker_id": sp, "emotion": "neutral", "enabled": "1", "notes": ""})
        choices.append({"id": f"dch_{d}_ok", "dialogue_id": d, "after_line_id": f"{d}_l03", "sort": "1", "enabled": "1", "notes": ""})
    append_rows(ROOT / "dialogue_lines.csv", "id", lines)
    append_rows(ROOT / "dialogue_choices.csv", "id", choices)

    effects = [
        ("fx_street_foreman_net", "dialogue_choice", "dch_dlg_street_foreman_ok", "stat", "", "network_base", "add", "2", "1", ""),
        ("fx_street_foreman_flag", "dialogue_choice", "dch_dlg_street_foreman_ok", "flag", "", "heard_foreman_rumor", "set", "1", "1", ""),
        ("fx_street_aunt_intel", "dialogue_choice", "dch_dlg_street_aunt_ok", "stat", "", "intel", "add", "2", "1", ""),
        ("fx_street_aunt_flag", "dialogue_choice", "dch_dlg_street_aunt_ok", "flag", "", "met_street_aunt", "set", "1", "1", ""),
        ("fx_street_waiter_intel", "dialogue_choice", "dch_dlg_street_waiter_ok", "stat", "", "intel", "add", "2", "1", ""),
        ("fx_street_waiter_flag", "dialogue_choice", "dch_dlg_street_waiter_ok", "flag", "", "heard_waiter_gossip", "set", "1", "1", ""),
        ("fx_street_garage_net", "dialogue_choice", "dch_dlg_street_garage_ok", "stat", "", "network_base", "add", "1", "1", ""),
        ("fx_street_garage_flag", "dialogue_choice", "dch_dlg_street_garage_ok", "flag", "", "met_garage_hand", "set", "1", "1", ""),
        ("fx_street_su_favor", "dialogue_choice", "dch_dlg_street_su_ok", "relation", "", "su_qing:player:favor", "add", "2", "1", ""),
        ("fx_street_son_tension", "dialogue_choice", "dch_dlg_street_son_ok", "stat", "", "father_son_tension", "add", "2", "1", ""),
        ("fx_street_son_sus", "dialogue_choice", "dch_dlg_street_son_ok", "stat", "", "suspicion", "add", "1", "1", ""),
        ("fx_street_boss_trust", "dialogue_choice", "dch_dlg_street_boss_ok", "stat", "", "trust", "add", "1", "1", ""),
        ("fx_street_chen_favor", "dialogue_choice", "dch_dlg_street_chen_ok", "relation", "", "chen_manager:player:favor", "add", "2", "1", ""),
        ("fx_street_chen_intel", "dialogue_choice", "dch_dlg_street_chen_ok", "stat", "", "intel", "add", "1", "1", ""),
    ]
    fields, rows = read_csv(ROOT / "effects.csv")
    have = {r["id"] for r in rows}
    for e in effects:
        if e[0] in have:
            continue
        row = {k: "" for k in fields}
        for i, k in enumerate(["id", "owner_type", "owner_id", "effect_type", "target", "key", "op", "value", "chance", "notes"]):
            if k in fields:
                row[k] = e[i]
        rows.append(row)
    write_csv(ROOT / "effects.csv", fields, rows)

    tips_f, tips = read_csv(ROOT / "tips.csv")
    if not any(t["id"] == "tip_street_npc" for t in tips):
        tips.append({k: "" for k in tips_f})
        tips[-1].update({"id": "tip_street_npc", "category": "unlock", "sort_order": "44", "text_key": "tip.street_npc", "once": "1", "enabled": "1", "notes": ""})
        write_csv(ROOT / "tips.csv", tips_f, tips)

    zh = {
        "npcs.dock_foreman.name": "老郑",
        "npcs.dock_foreman.title": "码头工头",
        "npcs.dock_foreman.role": "装卸工头",
        "npcs.dock_foreman.bio": "码头上叫得动号子的人，耳尖心硬。",
        "npcs.dock_foreman.personality": "直爽护短",
        "npcs.dock_foreman.motive": "保住兄弟们的饭碗",
        "npcs.stall_aunt.name": "阿婶",
        "npcs.stall_aunt.title": "摊贩",
        "npcs.stall_aunt.role": "广场小吃摊",
        "npcs.stall_aunt.bio": "什么消息都烤得焦香，什么人都能攀谈。",
        "npcs.stall_aunt.personality": "热络爱聊",
        "npcs.stall_aunt.motive": "多卖两份、多听两句",
        "npcs.tea_waiter.name": "小福",
        "npcs.tea_waiter.title": "茶馆跑堂",
        "npcs.tea_waiter.role": "港湾茶馆跑堂",
        "npcs.tea_waiter.bio": "醒木一响他就到，闲话比茶热。",
        "npcs.tea_waiter.personality": "机灵嘴碎",
        "npcs.tea_waiter.motive": "多挣赏钱",
        "npcs.garage_hand.name": "阿强",
        "npcs.garage_hand.title": "车行伙计",
        "npcs.garage_hand.role": "车行修车/看店",
        "npcs.garage_hand.bio": "油污罩衫，认得港区每一辆响轮子。",
        "npcs.garage_hand.personality": "务实寡言",
        "npcs.garage_hand.motive": "把车行撑下去",
        "npc_homes.dock_foreman": "老郑的工棚",
        "npc_homes.stall_aunt": "阿婶小屋",
        "npc_homes.tea_waiter": "小福住处",
        "npc_homes.garage_hand": "阿强住处",
        "npc_homes.zhou_shaoting": "少霆外宅",
        "npc_homes.chen_manager": "陈掌柜驻处",
        "dialogue_lines.dlg_street_foreman_l01.text": "号子刚歇。阿海，夜班舱单有人动过手脚——你自己留神。",
        "dialogue_lines.dlg_street_foreman_l02.text": "我记下了。",
        "dialogue_lines.dlg_street_foreman_l03.text": "弟兄们还听你的。别让他们白白挨刀。",
        "dialogue_lines.dlg_street_aunt_l01.text": "来来，糖糕热乎。广场刮刮乐？那是给手气好的人预备的。",
        "dialogue_lines.dlg_street_aunt_l02.text": "阿婶消息倒快。",
        "dialogue_lines.dlg_street_aunt_l03.text": "快的是嘴，准的才值钱。你慢慢听。",
        "dialogue_lines.dlg_street_waiter_l01.text": "嘘——后座有人把少爷和晚晴的名字搁一桌说。茶盖一碰，话就断了。",
        "dialogue_lines.dlg_street_waiter_l02.text": "……你看清楚是谁？",
        "dialogue_lines.dlg_street_waiter_l03.text": "看不清楚。但我耳朵不坏。",
        "dialogue_lines.dlg_street_garage_l01.text": "脚踏车、黄包车、摩托、轿车——气派一档一价。缺钱先扛码头。",
        "dialogue_lines.dlg_street_garage_l02.text": "我知道了。",
        "dialogue_lines.dlg_street_garage_l03.text": "买了记得来上牌。别让轮子丢在巷子里。",
        "dialogue_lines.dlg_street_su_l01.text": "阿海？我刚好路过……今天码头风大。",
        "dialogue_lines.dlg_street_su_l02.text": "你回家早些。",
        "dialogue_lines.dlg_street_su_l03.text": "嗯。灯替你留着。",
        "dialogue_lines.dlg_street_son_l01.text": "哟，装卸英雄也有空在街上晃？职位可不是逛出来的。",
        "dialogue_lines.dlg_street_son_l02.text": "……少霆副理。",
        "dialogue_lines.dlg_street_son_l03.text": "记住你的位子。别挡道。",
        "dialogue_lines.dlg_street_boss_l01.text": "阿海。公司要的是稳，不是热闹。",
        "dialogue_lines.dlg_street_boss_l02.text": "是，老板。",
        "dialogue_lines.dlg_street_boss_l03.text": "去忙你的。眼睛放亮。",
        "dialogue_lines.dlg_street_chen_l01.text": "宏远的人？街上遇见也算缘。通洋茶总是热的。",
        "dialogue_lines.dlg_street_chen_l02.text": "陈掌柜。",
        "dialogue_lines.dlg_street_chen_l03.text": "有货色再来谈。空话我不听。",
        "dialogue_choices.dch_dlg_street_foreman_ok.label": "记下了",
        "dialogue_choices.dch_dlg_street_aunt_ok.label": "多谢阿婶",
        "dialogue_choices.dch_dlg_street_waiter_ok.label": "我明白了",
        "dialogue_choices.dch_dlg_street_garage_ok.label": "回头去看",
        "dialogue_choices.dch_dlg_street_su_ok.label": "你也保重",
        "dialogue_choices.dch_dlg_street_son_ok.label": "……借过",
        "dialogue_choices.dch_dlg_street_boss_ok.label": "是",
        "dialogue_choices.dch_dlg_street_chen_ok.label": "后会有期",
        "tip.street_npc": "港区有固定作息的人：上班、串门、回家。走近按 E 街访，当天每位通常一次。",
        "ui.npc.inside": "（已进屋）",
    }
    en = {
        "npcs.dock_foreman.name": "Old Zheng",
        "npcs.dock_foreman.title": "Dock Foreman",
        "npcs.dock_foreman.role": "Loading foreman",
        "npcs.dock_foreman.bio": "The voice that moves the dock crew.",
        "npcs.dock_foreman.personality": "Blunt, loyal",
        "npcs.dock_foreman.motive": "Keep the brothers fed",
        "npcs.stall_aunt.name": "Auntie",
        "npcs.stall_aunt.title": "Stallkeeper",
        "npcs.stall_aunt.role": "Plaza snacks",
        "npcs.stall_aunt.bio": "Talk as hot as her cakes.",
        "npcs.stall_aunt.personality": "Chatty",
        "npcs.stall_aunt.motive": "Sell more, hear more",
        "npcs.tea_waiter.name": "Xiao Fu",
        "npcs.tea_waiter.title": "Tea Runner",
        "npcs.tea_waiter.role": "Tea house waiter",
        "npcs.tea_waiter.bio": "Ears sharper than the clapper.",
        "npcs.tea_waiter.personality": "Sharp tongue",
        "npcs.tea_waiter.motive": "Tips",
        "npcs.garage_hand.name": "Ah Qiang",
        "npcs.garage_hand.title": "Garage Hand",
        "npcs.garage_hand.role": "Mechanic / clerk",
        "npcs.garage_hand.bio": "Knows every loud wheel in the port.",
        "npcs.garage_hand.personality": "Quiet, practical",
        "npcs.garage_hand.motive": "Keep the garage open",
        "npc_homes.dock_foreman": "Zheng's Shed",
        "npc_homes.stall_aunt": "Auntie's Hut",
        "npc_homes.tea_waiter": "Xiao Fu's Room",
        "npc_homes.garage_hand": "Ah Qiang's Quarters",
        "npc_homes.zhou_shaoting": "Shaoting's Annex",
        "npc_homes.chen_manager": "Chen's Lodge",
        "dialogue_lines.dlg_street_foreman_l01.text": "Break's short. Hai — someone touched the night manifest. Watch yourself.",
        "dialogue_lines.dlg_street_foreman_l02.text": "Noted.",
        "dialogue_lines.dlg_street_foreman_l03.text": "The crew still listens to you. Don't let them take the blade.",
        "dialogue_lines.dlg_street_aunt_l01.text": "Hot cakes. Plaza scratch tickets? For lucky hands.",
        "dialogue_lines.dlg_street_aunt_l02.text": "News travels fast.",
        "dialogue_lines.dlg_street_aunt_l03.text": "Fast mouths are cheap. True ones aren't.",
        "dialogue_lines.dlg_street_waiter_l01.text": "Shh — back table said Young Master and Wanqing in one breath. Lid clicked; talk died.",
        "dialogue_lines.dlg_street_waiter_l02.text": "Who?",
        "dialogue_lines.dlg_street_waiter_l03.text": "Couldn't see. My ears work.",
        "dialogue_lines.dlg_street_garage_l01.text": "Bike, rickshaw, moto, sedan — grandeur priced by tier. Broke? Work the dock.",
        "dialogue_lines.dlg_street_garage_l02.text": "Got it.",
        "dialogue_lines.dlg_street_garage_l03.text": "Register if you buy. Don't leave wheels in an alley.",
        "dialogue_lines.dlg_street_su_l01.text": "Hai? I was passing — the dock wind's sharp today.",
        "dialogue_lines.dlg_street_su_l02.text": "Go home early.",
        "dialogue_lines.dlg_street_su_l03.text": "Mm. I'll leave the lamp.",
        "dialogue_lines.dlg_street_son_l01.text": "The loading hero strolling? Titles aren't earned by wandering.",
        "dialogue_lines.dlg_street_son_l02.text": "...Vice Manager.",
        "dialogue_lines.dlg_street_son_l03.text": "Know your place. Don't block the road.",
        "dialogue_lines.dlg_street_boss_l01.text": "Hai. The firm wants steady, not noise.",
        "dialogue_lines.dlg_street_boss_l02.text": "Yes, sir.",
        "dialogue_lines.dlg_street_boss_l03.text": "Get to work. Eyes open.",
        "dialogue_lines.dlg_street_chen_l01.text": "Hongyuan man? Chance on the street. Tongyang tea stays hot.",
        "dialogue_lines.dlg_street_chen_l02.text": "Manager Chen.",
        "dialogue_lines.dlg_street_chen_l03.text": "Come when you have goods. Empty talk bores me.",
        "dialogue_choices.dch_dlg_street_foreman_ok.label": "Noted",
        "dialogue_choices.dch_dlg_street_aunt_ok.label": "Thanks",
        "dialogue_choices.dch_dlg_street_waiter_ok.label": "I see",
        "dialogue_choices.dch_dlg_street_garage_ok.label": "I'll look",
        "dialogue_choices.dch_dlg_street_su_ok.label": "Take care",
        "dialogue_choices.dch_dlg_street_son_ok.label": "...Excuse me",
        "dialogue_choices.dch_dlg_street_boss_ok.label": "Yes",
        "dialogue_choices.dch_dlg_street_chen_ok.label": "Another time",
        "tip.street_npc": "Harbor folk keep schedules: work, visit, go home. Approach and press E to talk (usually once per day each).",
        "ui.npc.inside": "(inside)",
    }
    upsert_l10n(ROOT / "l10n" / "zh_CN.csv", zh)
    upsert_l10n(ROOT / "l10n" / "en.csv", en)
    print("npc data done")


if __name__ == "__main__":
    main()
