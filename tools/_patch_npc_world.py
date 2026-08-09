# -*- coding: utf-8 -*-
"""NPC traits, social web, story-tied world beats + l10n."""
from __future__ import annotations

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs" / "tables" / "packs" / "core"


def read_csv(path: Path):
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        r = csv.DictReader(f)
        return list(r.fieldnames or []), list(r)


def write_csv(path: Path, fields, rows):
    with path.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, lineterminator="\n")
        w.writeheader()
        for row in rows:
            w.writerow({k: row.get(k, "") for k in fields})


def append_rows(path: Path, key: str, news: list[dict]):
    fields, rows = read_csv(path)
    have = {str(r.get(key, "")) for r in rows}
    for n in news:
        if str(n.get(key, "")) in have:
            continue
        rows.append({**{k: "" for k in fields}, **n})
        have.add(str(n.get(key, "")))
    write_csv(path, fields, rows)


def upsert_l10n(path: Path, updates: dict[str, str]):
    text = path.read_text(encoding="utf-8-sig")
    lines = text.splitlines()
    out, seen = [], set()
    for line in lines:
        if not line.strip() or "," not in line:
            out.append(line)
            continue
        k = line.split(",", 1)[0]
        if k in updates:
            val = updates[k]
            out.append('%s,"%s"' % (k, val.replace('"', '""')) if ("," in val or '"' in val) else "%s,%s" % (k, val))
            seen.add(k)
        else:
            out.append(line)
    for k, val in updates.items():
        if k in seen:
            continue
        out.append('%s,"%s"' % (k, val.replace('"', '""')) if ("," in val or '"' in val) else "%s,%s" % (k, val))
    path.write_text("\n".join(out) + "\n", encoding="utf-8-sig")


def main():
    meta = json.loads((ROOT / "pack.json").read_text(encoding="utf-8"))
    tables = list(meta.get("tables", []))
    for t in ("npc_traits", "npc_beats"):
        if t not in tables:
            i = tables.index("npc_schedules") + 1 if "npc_schedules" in tables else len(tables)
            tables.insert(i, t)
    meta["tables"] = tables
    meta["version"] = "0.9.7"
    meta["description"] = "Demo 0.9.7：NPC属性、人际网与港区节拍故事。"
    (ROOT / "pack.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # Traits: one row per npc
    trait_fields = [
        "id", "influence", "nerve", "gossip", "temper", "means", "faction", "notes",
    ]
    traits = [
        {"id": "su_qing", "influence": "35", "nerve": "42", "gossip": "40", "temper": "28", "means": "30", "faction": "hongyuan", "notes": "虚荣与软心"},
        {"id": "zhou_shaoting", "influence": "70", "nerve": "55", "gossip": "50", "temper": "72", "means": "80", "faction": "hongyuan", "notes": "少爷气"},
        {"id": "zhou_hongye", "influence": "95", "nerve": "80", "gossip": "35", "temper": "60", "means": "95", "faction": "hongyuan", "notes": "掌舵"},
        {"id": "chen_manager", "influence": "75", "nerve": "70", "gossip": "55", "temper": "50", "means": "85", "faction": "tongyang", "notes": "通洋"},
        {"id": "dock_foreman", "influence": "45", "nerve": "65", "gossip": "40", "temper": "55", "means": "25", "faction": "dock", "notes": "工头"},
        {"id": "stall_aunt", "influence": "25", "nerve": "50", "gossip": "85", "temper": "35", "means": "20", "faction": "harbor", "notes": "情报摊"},
        {"id": "tea_waiter", "influence": "20", "nerve": "45", "gossip": "90", "temper": "30", "means": "15", "faction": "harbor", "notes": "耳目"},
        {"id": "garage_hand", "influence": "22", "nerve": "48", "gossip": "30", "temper": "40", "means": "28", "faction": "harbor", "notes": "车行"},
    ]
    write_csv(ROOT / "npc_traits.csv", trait_fields, traits)

    # NPC-NPC social web
    append_rows(
        ROOT / "relations_init.csv",
        "id",
        [
            {"id": "rel_foreman_aunt_favor", "source_id": "dock_foreman", "target_id": "stall_aunt", "relation_key": "favor", "initial": "55", "min": "0", "max": "100", "notes": "码头熟人"},
            {"id": "rel_aunt_foreman_favor", "source_id": "stall_aunt", "target_id": "dock_foreman", "relation_key": "favor", "initial": "50", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_waiter_aunt_favor", "source_id": "tea_waiter", "target_id": "stall_aunt", "relation_key": "favor", "initial": "60", "min": "0", "max": "100", "notes": "闲话互通"},
            {"id": "rel_aunt_waiter_favor", "source_id": "stall_aunt", "target_id": "tea_waiter", "relation_key": "favor", "initial": "58", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_waiter_su_favor", "source_id": "tea_waiter", "target_id": "su_qing", "relation_key": "favor", "initial": "40", "min": "0", "max": "100", "notes": "认得茶客"},
            {"id": "rel_waiter_son_favor", "source_id": "tea_waiter", "target_id": "zhou_shaoting", "relation_key": "favor", "initial": "35", "min": "0", "max": "100", "notes": "怕少爷"},
            {"id": "rel_waiter_son_suspicion", "source_id": "tea_waiter", "target_id": "zhou_shaoting", "relation_key": "suspicion", "initial": "25", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_garage_foreman_favor", "source_id": "garage_hand", "target_id": "dock_foreman", "relation_key": "favor", "initial": "45", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_foreman_boss_trust", "source_id": "dock_foreman", "target_id": "zhou_hongye", "relation_key": "trust", "initial": "40", "min": "0", "max": "100", "notes": "听老板的"},
            {"id": "rel_foreman_boss_suspicion", "source_id": "dock_foreman", "target_id": "zhou_hongye", "relation_key": "suspicion", "initial": "20", "min": "0", "max": "100", "notes": "舱单疑云"},
            {"id": "rel_chen_son_favor", "source_id": "chen_manager", "target_id": "zhou_shaoting", "relation_key": "favor", "initial": "30", "min": "0", "max": "100", "notes": "可利用"},
            {"id": "rel_chen_boss_suspicion", "source_id": "chen_manager", "target_id": "zhou_hongye", "relation_key": "suspicion", "initial": "55", "min": "0", "max": "100", "notes": "对家"},
            {"id": "rel_son_su_favor", "source_id": "zhou_shaoting", "target_id": "su_qing", "relation_key": "favor", "initial": "55", "min": "0", "max": "100", "notes": "觊觎"},
            {"id": "rel_su_son_favor", "source_id": "su_qing", "target_id": "zhou_shaoting", "relation_key": "favor", "initial": "45", "min": "0", "max": "100", "notes": "动摇"},
            {"id": "rel_su_son_suspicion", "source_id": "su_qing", "target_id": "zhou_shaoting", "relation_key": "suspicion", "initial": "20", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_boss_su_trust", "source_id": "zhou_hongye", "target_id": "su_qing", "relation_key": "trust", "initial": "35", "min": "0", "max": "100", "notes": "准儿媳观察"},
        ],
    )

    beat_fields = [
        "id", "period", "weight", "min_day", "max_day", "require_flag", "block_flag", "require_route",
        "actor_a", "actor_b", "text_key",
        "source_id", "target_id", "relation_key", "relation_delta",
        "trait_npc", "trait_key", "trait_delta",
        "once", "enabled", "notes",
    ]

    def B(**kw):
        row = {k: "" for k in beat_fields}
        row.update({"period": "any", "weight": "10", "min_day": "1", "max_day": "30", "once": "0", "enabled": "1"})
        row.update(kw)
        return row

    beats = [
        # Early harbor life
        B(id="beat_foreman_aunt_dock", period="morning", weight="18", actor_a="dock_foreman", actor_b="stall_aunt",
          text_key="beat.foreman_aunt_dock", source_id="dock_foreman", target_id="stall_aunt", relation_key="favor", relation_delta="2",
          notes="工头买糕听消息"),
        B(id="beat_aunt_waiter_swap", period="afternoon", weight="16", actor_a="stall_aunt", actor_b="tea_waiter",
          text_key="beat.aunt_waiter_swap", source_id="stall_aunt", target_id="tea_waiter", relation_key="favor", relation_delta="2",
          trait_npc="stall_aunt", trait_key="gossip", trait_delta="1", notes="广场茶馆互通"),
        B(id="beat_garage_foreman_wheel", period="afternoon", weight="12", actor_a="garage_hand", actor_b="dock_foreman",
          text_key="beat.garage_foreman_wheel", source_id="garage_hand", target_id="dock_foreman", relation_key="favor", relation_delta="2",
          notes="修车聊码头"),
        # Son / Su tea — story mid
        B(id="beat_waiter_sees_son_su", period="afternoon", weight="22", min_day="3", require_flag="",
          actor_a="tea_waiter", actor_b="zhou_shaoting", text_key="beat.waiter_sees_son_su",
          source_id="su_qing", target_id="zhou_shaoting", relation_key="intimacy", relation_delta="2",
          trait_npc="tea_waiter", trait_key="gossip", trait_delta="2", once="0", notes="茶馆同桌"),
        B(id="beat_son_su_gift_echo", period="evening", weight="20", min_day="4",
          actor_a="zhou_shaoting", actor_b="su_qing", text_key="beat.son_su_gift_echo",
          source_id="zhou_shaoting", target_id="su_qing", relation_key="favor", relation_delta="3",
          source_id2="",  # ignore
          notes="少爷示好回响"),
        # Day5 promotion stolen fallout
        B(id="beat_foreman_boss_manifest", period="morning", weight="24", min_day="5",
          actor_a="dock_foreman", actor_b="zhou_hongye", text_key="beat.foreman_boss_manifest",
          source_id="dock_foreman", target_id="zhou_hongye", relation_key="suspicion", relation_delta="4",
          trait_npc="dock_foreman", trait_key="temper", trait_delta="3", notes="舱单与打压余波"),
        B(id="beat_boss_son_office", period="afternoon", weight="18", min_day="5",
          actor_a="zhou_hongye", actor_b="zhou_shaoting", text_key="beat.boss_son_office",
          source_id="zhou_hongye", target_id="zhou_shaoting", relation_key="father_son_trust", relation_delta="-3",
          notes="父子办公室低语"),
        # Su distance / betrayal window
        B(id="beat_su_son_distance", period="evening", weight="26", min_day="4", require_flag="",
          actor_a="su_qing", actor_b="zhou_shaoting", text_key="beat.su_son_distance",
          source_id="su_qing", target_id="zhou_shaoting", relation_key="intimacy", relation_delta="4",
          source_id="su_qing", target_id="zhou_shaoting",
          trait_npc="su_qing", trait_key="nerve", trait_delta="-2", notes="手帕裂缝前后"),
        B(id="beat_aunt_whispers_su", period="afternoon", weight="15", min_day="6",
          actor_a="stall_aunt", actor_b="su_qing", text_key="beat.aunt_whispers_su",
          source_id="stall_aunt", target_id="tea_waiter", relation_key="favor", relation_delta="1",
          notes="阿婶嚼晚晴舌根"),
        # Route B
        B(id="beat_b_pillow_echo", period="evening", weight="28", min_day="8", require_route="route_focus_b",
          actor_a="zhou_shaoting", actor_b="su_qing", text_key="beat.b_pillow_echo",
          source_id="su_qing", target_id="zhou_shaoting", relation_key="intimacy", relation_delta="3",
          source_id="zhou_hongye",  # oops fix below
          notes="B线枕边风回响"),
        B(id="beat_b_waiter_corridor", period="afternoon", weight="22", min_day="8", require_route="route_focus_b",
          actor_a="tea_waiter", actor_b="zhou_shaoting", text_key="beat.b_waiter_corridor",
          source_id="tea_waiter", target_id="zhou_shaoting", relation_key="suspicion", relation_delta="3",
          notes="茶馆听对立"),
        # Route A
        B(id="beat_a_chen_probe", period="afternoon", weight="24", min_day="7", require_route="route_focus_a",
          actor_a="chen_manager", actor_b="dock_foreman", text_key="beat.a_chen_probe",
          source_id="chen_manager", target_id="dock_foreman", relation_key="favor", relation_delta="3",
          trait_npc="chen_manager", trait_key="influence", trait_delta="1", notes="通洋挖墙脚"),
        # Route C
        B(id="beat_c_exchange_whisper", period="morning", weight="22", min_day="7", require_route="route_focus_c",
          actor_a="chen_manager", actor_b="stall_aunt", text_key="beat.c_exchange_whisper",
          source_id="chen_manager", target_id="stall_aunt", relation_key="favor", relation_delta="2",
          trait_npc="stall_aunt", trait_key="gossip", trait_delta="2", notes="交易所风向"),
        # Always-on tension
        B(id="beat_son_flex_company", period="morning", weight="10", min_day="2",
          actor_a="zhou_shaoting", actor_b="zhou_hongye", text_key="beat.son_flex_company",
          source_id="zhou_shaoting", target_id="zhou_hongye", relation_key="father_son_trust", relation_delta="-1",
          trait_npc="zhou_shaoting", trait_key="temper", trait_delta="1", notes="少爷张扬"),
        B(id="beat_boss_watch_dock", period="morning", weight="8", min_day="6", require_flag="boss_watching",
          actor_a="zhou_hongye", actor_b="dock_foreman", text_key="beat.boss_watch_dock",
          source_id="dock_foreman", target_id="zhou_hongye", relation_key="suspicion", relation_delta="2",
          notes="老板盯码头"),
    ]
    # Fix botched B() calls - rebuild clean list
    beats = [
        B(id="beat_foreman_aunt_dock", period="morning", weight="18", actor_a="dock_foreman", actor_b="stall_aunt",
          text_key="beat.foreman_aunt_dock", source_id="dock_foreman", target_id="stall_aunt", relation_key="favor", relation_delta="2"),
        B(id="beat_aunt_waiter_swap", period="afternoon", weight="16", actor_a="stall_aunt", actor_b="tea_waiter",
          text_key="beat.aunt_waiter_swap", source_id="stall_aunt", target_id="tea_waiter", relation_key="favor", relation_delta="2",
          trait_npc="stall_aunt", trait_key="gossip", trait_delta="1"),
        B(id="beat_garage_foreman_wheel", period="afternoon", weight="12", actor_a="garage_hand", actor_b="dock_foreman",
          text_key="beat.garage_foreman_wheel", source_id="garage_hand", target_id="dock_foreman", relation_key="favor", relation_delta="2"),
        B(id="beat_waiter_sees_son_su", period="afternoon", weight="22", min_day="3", actor_a="tea_waiter", actor_b="zhou_shaoting",
          text_key="beat.waiter_sees_son_su", source_id="su_qing", target_id="zhou_shaoting", relation_key="intimacy", relation_delta="2",
          trait_npc="tea_waiter", trait_key="gossip", trait_delta="2"),
        B(id="beat_son_su_gift_echo", period="evening", weight="20", min_day="4", actor_a="zhou_shaoting", actor_b="su_qing",
          text_key="beat.son_su_gift_echo", source_id="zhou_shaoting", target_id="su_qing", relation_key="favor", relation_delta="3"),
        B(id="beat_foreman_boss_manifest", period="morning", weight="24", min_day="5", actor_a="dock_foreman", actor_b="zhou_hongye",
          text_key="beat.foreman_boss_manifest", source_id="dock_foreman", target_id="zhou_hongye", relation_key="suspicion", relation_delta="4",
          trait_npc="dock_foreman", trait_key="temper", trait_delta="3"),
        B(id="beat_boss_son_office", period="afternoon", weight="18", min_day="5", actor_a="zhou_hongye", actor_b="zhou_shaoting",
          text_key="beat.boss_son_office", source_id="zhou_hongye", target_id="zhou_shaoting", relation_key="father_son_trust", relation_delta="-3"),
        B(id="beat_su_son_distance", period="evening", weight="26", min_day="4", actor_a="su_qing", actor_b="zhou_shaoting",
          text_key="beat.su_son_distance", source_id="su_qing", target_id="zhou_shaoting", relation_key="intimacy", relation_delta="4",
          trait_npc="su_qing", trait_key="nerve", trait_delta="-2"),
        B(id="beat_aunt_whispers_su", period="afternoon", weight="15", min_day="6", actor_a="stall_aunt", actor_b="tea_waiter",
          text_key="beat.aunt_whispers_su", source_id="stall_aunt", target_id="tea_waiter", relation_key="favor", relation_delta="1",
          trait_npc="stall_aunt", trait_key="gossip", trait_delta="2"),
        B(id="beat_b_pillow_echo", period="evening", weight="28", min_day="8", require_route="route_focus_b",
          actor_a="zhou_shaoting", actor_b="su_qing", text_key="beat.b_pillow_echo",
          source_id="su_qing", target_id="zhou_shaoting", relation_key="intimacy", relation_delta="3"),
        B(id="beat_b_waiter_corridor", period="afternoon", weight="22", min_day="8", require_route="route_focus_b",
          actor_a="tea_waiter", actor_b="zhou_shaoting", text_key="beat.b_waiter_corridor",
          source_id="tea_waiter", target_id="zhou_shaoting", relation_key="suspicion", relation_delta="3"),
        B(id="beat_a_chen_probe", period="afternoon", weight="24", min_day="7", require_route="route_focus_a",
          actor_a="chen_manager", actor_b="dock_foreman", text_key="beat.a_chen_probe",
          source_id="chen_manager", target_id="dock_foreman", relation_key="favor", relation_delta="3",
          trait_npc="chen_manager", trait_key="influence", trait_delta="1"),
        B(id="beat_c_exchange_whisper", period="morning", weight="22", min_day="7", require_route="route_focus_c",
          actor_a="chen_manager", actor_b="stall_aunt", text_key="beat.c_exchange_whisper",
          source_id="chen_manager", target_id="stall_aunt", relation_key="favor", relation_delta="2",
          trait_npc="stall_aunt", trait_key="gossip", trait_delta="2"),
        B(id="beat_son_flex_company", period="morning", weight="10", min_day="2", actor_a="zhou_shaoting", actor_b="zhou_hongye",
          text_key="beat.son_flex_company", source_id="zhou_hongye", target_id="zhou_shaoting", relation_key="father_son_trust", relation_delta="-1",
          trait_npc="zhou_shaoting", trait_key="temper", trait_delta="1"),
        B(id="beat_boss_watch_dock", period="morning", weight="14", min_day="6", require_flag="boss_watching",
          actor_a="zhou_hongye", actor_b="dock_foreman", text_key="beat.boss_watch_dock",
          source_id="dock_foreman", target_id="zhou_hongye", relation_key="suspicion", relation_delta="2"),
        B(id="beat_su_boss_tea", period="afternoon", weight="12", min_day="3", actor_a="su_qing", actor_b="zhou_hongye",
          text_key="beat.su_boss_tea", source_id="zhou_hongye", target_id="su_qing", relation_key="trust", relation_delta="1",
          notes="准儿媳露面"),
    ]
    write_csv(ROOT / "npc_beats.csv", beat_fields, beats)

    zh = {
        "ui.dossier.section_traits": "人物属性",
        "ui.dossier.section_web": "人物关系",
        "ui.dossier.section_web_note": "港区人际（不含对你）",
        "ui.dossier.trait_influence": "势力",
        "ui.dossier.trait_nerve": "胆色",
        "ui.dossier.trait_gossip": "耳目",
        "ui.dossier.trait_temper": "脾气",
        "ui.dossier.trait_means": "身家",
        "ui.dossier.faction": "阵营",
        "ui.dossier.faction_hongyuan": "宏远",
        "ui.dossier.faction_tongyang": "通洋",
        "ui.dossier.faction_dock": "码头",
        "ui.dossier.faction_harbor": "港区市井",
        "ui.dossier.web_edge": "{name} · {rel} {n}",
        "tip.npc_world": "港区会自己过日子：人物档案里能看到他们的属性、人际与街巷传闻。",
        "beat.foreman_aunt_dock": "老郑在阿婶摊前买了份热糕，两人低声交换夜班舱口的风声。",
        "beat.aunt_waiter_swap": "阿婶与小福碰头：广场谁出手阔绰、茶馆后座又坐了谁，一对一对上了。",
        "beat.garage_foreman_wheel": "阿强给工棚板车打了气，顺嘴问老郑码头上最近谁不痛快。",
        "beat.waiter_sees_son_su": "小福看见少霆与晚晴同桌落座，茶盖一碰，闲话已经热了。",
        "beat.son_su_gift_echo": "少爷又往晚晴那边递了东西；她收下时笑得勉强，港区眼睛却尖。",
        "beat.foreman_boss_manifest": "升迁风波过后，老郑盯着舱单直咂嘴——上头的手比号子还乱。",
        "beat.boss_son_office": "公司里父子压着嗓子说话，门缝漏出的不是家常，是算计。",
        "beat.su_son_distance": "晚晴与少霆走得更近了些；手帕上的线头，像港风里扯不开的结。",
        "beat.aunt_whispers_su": "阿婶把晚晴的闲话烤进糖糕香里，小福听了只点头，不敢多嘴。",
        "beat.b_pillow_echo": "B线风声：枕边与茶桌之间，晚晴和少霆的名字又缠到一处。",
        "beat.b_waiter_corridor": "小福在走廊听见少爷压人的口气，吓得把茶盘端得更稳。",
        "beat.a_chen_probe": "陈掌柜借着问货色，在码头边试探老郑——通洋的手伸进了号子堆。",
        "beat.c_exchange_whisper": "交易所外，陈掌柜丢给阿婶半句行情；她转头就能把风声烤热。",
        "beat.son_flex_company": "少霆在公司门前张扬，鸿业眼底的信任又薄了一层。",
        "beat.boss_watch_dock": "老板盯上码头后，老郑嗓门小了，疑心却重了。",
        "beat.su_boss_tea": "晚晴在茶馆外遇到老板，礼数周到；鸿业把她又往准儿媳的尺子上量了量。",
    }
    en = {
        "ui.dossier.section_traits": "Traits",
        "ui.dossier.section_web": "Social web",
        "ui.dossier.section_web_note": "Harbor ties (not toward you)",
        "ui.dossier.trait_influence": "Influence",
        "ui.dossier.trait_nerve": "Nerve",
        "ui.dossier.trait_gossip": "Ears",
        "ui.dossier.trait_temper": "Temper",
        "ui.dossier.trait_means": "Means",
        "ui.dossier.faction": "Faction",
        "ui.dossier.faction_hongyuan": "Hongyuan",
        "ui.dossier.faction_tongyang": "Tongyang",
        "ui.dossier.faction_dock": "Dock",
        "ui.dossier.faction_harbor": "Harbor street",
        "ui.dossier.web_edge": "{name} · {rel} {n}",
        "tip.npc_world": "The harbor keeps living: dossiers show traits, ties, and street beats.",
        "beat.foreman_aunt_dock": "Old Zheng buys cakes from Auntie; night-bay whispers change hands.",
        "beat.aunt_waiter_swap": "Auntie and Xiao Fu match plaza spenders to tea-house back tables.",
        "beat.garage_foreman_wheel": "Ah Qiang pumps a cart tire and asks who on the dock is sore.",
        "beat.waiter_sees_son_su": "Xiao Fu spots Shaoting and Wanqing at one table; gossip heats with the lid.",
        "beat.son_su_gift_echo": "The young master presses another gift on Wanqing; her smile is thin, eyes are not.",
        "beat.foreman_boss_manifest": "After the promotion storm, Zheng stares at manifests — hands above the chants.",
        "beat.boss_son_office": "Father and son speak low in the office; the draft under the door is calculation.",
        "beat.su_son_distance": "Wanqing and Shaoting draw closer; the handkerchief knot won't loosen in harbor wind.",
        "beat.aunt_whispers_su": "Auntie bakes Wanqing's name into cake-steam; Xiao Fu only nods.",
        "beat.b_pillow_echo": "Route B echo: pillow and tea table tangle Wanqing with Shaoting again.",
        "beat.b_waiter_corridor": "Xiao Fu hears the young master's crush in a corridor and steadies his tray.",
        "beat.a_chen_probe": "Chen probes Zheng by the dock — Tongyang fingers in the chant crew.",
        "beat.c_exchange_whisper": "Outside the exchange, Chen feeds Auntie a tip; she can warm any rumor.",
        "beat.son_flex_company": "Shaoting swaggers at the firm gate; Hongye's trust thins another shade.",
        "beat.boss_watch_dock": "With the boss watching the dock, Zheng's voice drops and suspicion rises.",
        "beat.su_boss_tea": "Wanqing greets the boss by the tea house; he measures her again as almost-kin.",
    }
    upsert_l10n(ROOT / "l10n" / "zh_CN.csv", zh)
    upsert_l10n(ROOT / "l10n" / "en.csv", en)

    tips_f, tips = read_csv(ROOT / "tips.csv")
    if not any(t["id"] == "tip_npc_world" for t in tips):
        tips.append({k: "" for k in tips_f})
        tips[-1].update({"id": "tip_npc_world", "category": "unlock", "sort_order": "46", "text_key": "tip.npc_world", "once": "1", "enabled": "1", "notes": ""})
        write_csv(ROOT / "tips.csv", tips_f, tips)
    print("npc world data ok", len(beats), "beats")


if __name__ == "__main__":
    main()
