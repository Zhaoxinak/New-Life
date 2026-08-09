# -*- coding: utf-8 -*-
from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs" / "tables" / "packs" / "core"


def read_csv(path: Path) -> tuple[list[str], list[dict]]:
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        r = csv.DictReader(f)
        return list(r.fieldnames or []), list(r)


def write_csv(path: Path, fields: list[str], rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, lineterminator="\n")
        w.writeheader()
        for row in rows:
            w.writerow({k: row.get(k, "") for k in fields})


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
            if "," in val or '"' in val:
                out.append('%s,"%s"' % (k, val.replace('"', '""')))
            else:
                out.append("%s,%s" % (k, val))
            seen.add(k)
        else:
            out.append(line)
    for k, val in updates.items():
        if k in seen:
            continue
        if "," in val or '"' in val:
            out.append('%s,"%s"' % (k, val.replace('"', '""')))
        else:
            out.append("%s,%s" % (k, val))
    path.write_text("\n".join(out) + "\n", encoding="utf-8-sig")


def main() -> None:
    append_rows(
        ROOT / "relations_init.csv",
        "id",
        [
            {"id": "rel_dock_foreman_player_favor", "source_id": "dock_foreman", "target_id": "player", "relation_key": "favor", "initial": "45", "min": "0", "max": "100", "notes": "工头对阿海"},
            {"id": "rel_dock_foreman_player_trust", "source_id": "dock_foreman", "target_id": "player", "relation_key": "trust", "initial": "50", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_dock_foreman_player_suspicion", "source_id": "dock_foreman", "target_id": "player", "relation_key": "suspicion", "initial": "8", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_stall_aunt_player_favor", "source_id": "stall_aunt", "target_id": "player", "relation_key": "favor", "initial": "40", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_stall_aunt_player_trust", "source_id": "stall_aunt", "target_id": "player", "relation_key": "trust", "initial": "35", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_stall_aunt_player_suspicion", "source_id": "stall_aunt", "target_id": "player", "relation_key": "suspicion", "initial": "5", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_tea_waiter_player_favor", "source_id": "tea_waiter", "target_id": "player", "relation_key": "favor", "initial": "30", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_tea_waiter_player_trust", "source_id": "tea_waiter", "target_id": "player", "relation_key": "trust", "initial": "25", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_tea_waiter_player_suspicion", "source_id": "tea_waiter", "target_id": "player", "relation_key": "suspicion", "initial": "10", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_garage_hand_player_favor", "source_id": "garage_hand", "target_id": "player", "relation_key": "favor", "initial": "28", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_garage_hand_player_trust", "source_id": "garage_hand", "target_id": "player", "relation_key": "trust", "initial": "30", "min": "0", "max": "100", "notes": ""},
            {"id": "rel_garage_hand_player_suspicion", "source_id": "garage_hand", "target_id": "player", "relation_key": "suspicion", "initial": "6", "min": "0", "max": "100", "notes": ""},
        ],
    )

    tips_f, tips = read_csv(ROOT / "tips.csv")
    if not any(t["id"] == "tip_dossier" for t in tips):
        tips.append({k: "" for k in tips_f})
        tips[-1].update({
            "id": "tip_dossier", "category": "unlock", "sort_order": "45",
            "text_key": "tip.dossier", "once": "1", "enabled": "1", "notes": "",
        })
        write_csv(ROOT / "tips.csv", tips_f, tips)

    zh = {
        "npcs.player.background": "从码头装卸干起的年轻人，想在宏远与港区人情里站稳脚跟。",
        "npcs.player.disposition": "你自己。",
        "npcs.su_qing.background": "纱厂女工出身，靠洋行文书半步踏进体面人家；未婚夫是阿海，却也被少爷圈子盯着。",
        "npcs.su_qing.disposition": "有情分，也怕你不够体面。",
        "npcs.zhou_shaoting.background": "宏远独子，副理位子多半是家业安排；码头与茶馆都是他显摆与施压的舞台。",
        "npcs.zhou_shaoting.disposition": "看不起装卸出身的你。",
        "npcs.zhou_hongye.background": "宏远贸易的掌舵人，仓单、人脉与规矩都捏在他手里。赏识不等于交心。",
        "npcs.zhou_hongye.disposition": "当可用之才看，也随时会抽检。",
        "npcs.chen_manager.background": "通洋商行驻港掌柜，专挖宏远墙角；茶是热的，算盘更热。",
        "npcs.chen_manager.disposition": "先把你当棋子掂量。",
        "npcs.dock_foreman.background": "在码头喊了半辈子号子，弟兄的饭碗比舱单更要紧。夜班手脚不干净的事，他耳朵尖。",
        "npcs.dock_foreman.disposition": "认你是自己人，也要你护得住场子。",
        "npcs.stall_aunt.background": "广场糖糕摊是她的情报网：谁买刮刮乐、谁跟少爷同桌，嘴上不落地也能传到你耳朵里。",
        "npcs.stall_aunt.disposition": "热络，爱把你当可聊的主顾。",
        "npcs.tea_waiter.background": "港湾茶馆跑堂，醒木与茶盖之间听尽闲话；赏钱到位，嘴才松。",
        "npcs.tea_waiter.disposition": "把你当可能给赏钱的客人。",
        "npcs.garage_hand.background": "车行修车看店，认得港区每一种轮子的响法；气派一档一价，他说得比广告实在。",
        "npcs.garage_hand.disposition": "少言，但肯跟干活的人交底。",
        "ui.dossier.title": "人物档案",
        "ui.dossier.tab_self": "我",
        "ui.dossier.tab_people": "人物录",
        "ui.dossier.close": "关闭",
        "ui.dossier.hint": "C 开关 · Esc 关闭",
        "ui.dossier.group_story": "主线人物",
        "ui.dossier.group_harbor": "港区人物",
        "ui.dossier.section_company": "公司与身家",
        "ui.dossier.section_company_note": "以下为公司轨（与人物对你的信任/疑心分轨）",
        "ui.dossier.section_relations": "对你的态度",
        "ui.dossier.section_relations_note": "好感 / 信任 / 疑心 —— 对方对你",
        "ui.dossier.section_profile": "档案",
        "ui.dossier.section_log": "往来记录",
        "ui.dossier.log_empty": "尚未留下可载入册的往来。",
        "ui.dossier.field_personality": "性情",
        "ui.dossier.field_motive": "所求",
        "ui.dossier.field_bio": "简介",
        "ui.dossier.field_background": "背景",
        "ui.dossier.field_disposition": "对你",
        "ui.dossier.field_role": "身份",
        "ui.dossier.rel_favor": "好感",
        "ui.dossier.rel_trust": "信任",
        "ui.dossier.rel_suspicion": "疑心",
        "ui.dossier.rel_intimacy": "晚晴与少霆亲密",
        "ui.dossier.rel_father_son": "父子信任",
        "ui.dossier.day_period": "第{day}日 · {period}",
        "ui.dossier.rank": "职级",
        "ui.dossier.favor_tier_0": "冷淡",
        "ui.dossier.favor_tier_1": "生疏",
        "ui.dossier.favor_tier_2": "相识",
        "ui.dossier.favor_tier_3": "亲近",
        "ui.dossier.favor_tier_4": "信赖",
        "ui.dossier.trust_tier_0": "戒备",
        "ui.dossier.trust_tier_1": "观望",
        "ui.dossier.trust_tier_2": "可托",
        "ui.dossier.trust_tier_3": "倚重",
        "ui.dossier.trust_tier_4": "托付",
        "ui.dossier.suspicion_tier_0": "无虞",
        "ui.dossier.suspicion_tier_1": "留意",
        "ui.dossier.suspicion_tier_2": "疑心",
        "ui.dossier.suspicion_tier_3": "猜忌",
        "ui.dossier.suspicion_tier_4": "敌视",
        "tip.dossier": "按 C 打开人物档案：查看属性、好感与往来记录。",
        "journal.street.dock_foreman": "街边与老郑交谈，听他提起夜班舱单。",
        "journal.street.stall_aunt": "在阿婶摊前攀谈，听了广场与手气的闲话。",
        "journal.street.tea_waiter": "茶馆外撞见小福，他压低声音说闲话。",
        "journal.street.garage_hand": "向阿强打听车行档位与上路规矩。",
        "journal.street.su_qing": "户外与晚晴短暂寒暄。",
        "journal.street.zhou_shaoting": "街上与少霆照面，话里带刺。",
        "journal.street.zhou_hongye": "偶遇老板，他只丢下一句要稳。",
        "journal.street.chen_manager": "路上与陈掌柜点到为止地过了一招。",
        "journal.flag.heard_foreman_rumor": "记下老郑的提醒：夜班有人改单。",
        "journal.flag.heard_waiter_gossip": "记下小福的闲话：有人把晚晴与少霆搁一桌说。",
        "journal.flag.met_street_aunt": "阿婶把你当成能聊的主顾。",
        "journal.flag.met_garage_hand": "阿强肯跟你交车行的底。",
        "journal.favor.up": "对方对你的好感有所回升（+{n}）。",
        "journal.favor.down": "对方对你的好感有所下降（{n}）。",
        "ui.chrome.dossier": "人物",
        "periods.morning": "白天",
        "periods.afternoon": "中午",
        "periods.evening": "晚上",
    }
    en = {
        "npcs.player.background": "A young dock worker climbing through Hongyuan and harbor ties.",
        "npcs.player.disposition": "Yourself.",
        "npcs.su_qing.background": "Mill girl turned clerk; engaged to Hai, watched by the young master's circle.",
        "npcs.su_qing.disposition": "Fond, but fears you lack standing.",
        "npcs.zhou_shaoting.background": "Hongyuan heir and vice manager; docks and tea houses are his stage.",
        "npcs.zhou_shaoting.disposition": "Looks down on your loading past.",
        "npcs.zhou_hongye.background": "Steers Hongyuan Trade; manifests, ties, and rules sit in his hand.",
        "npcs.zhou_hongye.disposition": "Sees talent — and audits it.",
        "npcs.chen_manager.background": "Tongyang's harbor manager; tea is hot, the abacus hotter.",
        "npcs.chen_manager.disposition": "Weighs you as a piece first.",
        "npcs.dock_foreman.background": "Half a life calling dock chants; crew bowls matter more than paper.",
        "npcs.dock_foreman.disposition": "Counts you as crew — if you hold the line.",
        "npcs.stall_aunt.background": "Plaza cakes and a gossip net: scratch tickets, back tables, loose lips.",
        "npcs.stall_aunt.disposition": "Warm; treats you as a talkative customer.",
        "npcs.tea_waiter.background": "Tea-house runner; tips loosen what the clapper hears.",
        "npcs.tea_waiter.disposition": "Sees a possible tipper.",
        "npcs.garage_hand.background": "Garage hand who knows every loud wheel in the port.",
        "npcs.garage_hand.disposition": "Quiet, but straight with workers.",
        "ui.dossier.title": "Dossier",
        "ui.dossier.tab_self": "Self",
        "ui.dossier.tab_people": "People",
        "ui.dossier.close": "Close",
        "ui.dossier.hint": "C toggle · Esc close",
        "ui.dossier.group_story": "Story cast",
        "ui.dossier.group_harbor": "Harbor folk",
        "ui.dossier.section_company": "Firm & means",
        "ui.dossier.section_company_note": "Company track (separate from NPC trust/suspicion toward you)",
        "ui.dossier.section_relations": "Toward you",
        "ui.dossier.section_relations_note": "Favor / trust / suspicion — how they see you",
        "ui.dossier.section_profile": "Profile",
        "ui.dossier.section_log": "Record",
        "ui.dossier.log_empty": "No dossier-worthy dealings yet.",
        "ui.dossier.field_personality": "Temper",
        "ui.dossier.field_motive": "Aim",
        "ui.dossier.field_bio": "Brief",
        "ui.dossier.field_background": "Background",
        "ui.dossier.field_disposition": "Toward you",
        "ui.dossier.field_role": "Role",
        "ui.dossier.rel_favor": "Favor",
        "ui.dossier.rel_trust": "Trust",
        "ui.dossier.rel_suspicion": "Suspicion",
        "ui.dossier.rel_intimacy": "Wanqing–Shaoting intimacy",
        "ui.dossier.rel_father_son": "Father–son trust",
        "ui.dossier.day_period": "Day {day} · {period}",
        "ui.dossier.rank": "Rank",
        "ui.dossier.favor_tier_0": "Cold",
        "ui.dossier.favor_tier_1": "Distant",
        "ui.dossier.favor_tier_2": "Acquainted",
        "ui.dossier.favor_tier_3": "Close",
        "ui.dossier.favor_tier_4": "Devoted",
        "ui.dossier.trust_tier_0": "Wary",
        "ui.dossier.trust_tier_1": "Watching",
        "ui.dossier.trust_tier_2": "Reliable",
        "ui.dossier.trust_tier_3": "Relied on",
        "ui.dossier.trust_tier_4": "Entrusted",
        "ui.dossier.suspicion_tier_0": "Clear",
        "ui.dossier.suspicion_tier_1": "Noticing",
        "ui.dossier.suspicion_tier_2": "Suspicious",
        "ui.dossier.suspicion_tier_3": "Distrustful",
        "ui.dossier.suspicion_tier_4": "Hostile",
        "tip.dossier": "Press C for the dossier: stats, favor, and dealings.",
        "journal.street.dock_foreman": "Spoke with Old Zheng about the night manifest.",
        "journal.street.stall_aunt": "Chatted at Auntie's stall about the plaza and luck.",
        "journal.street.tea_waiter": "Caught Xiao Fu outside the tea house; he whispered gossip.",
        "journal.street.garage_hand": "Asked Ah Qiang about vehicle tiers and registration.",
        "journal.street.su_qing": "A brief outdoor greeting with Wanqing.",
        "journal.street.zhou_shaoting": "Crossed Shaoting in the street; barbs exchanged.",
        "journal.street.zhou_hongye": "Ran into the boss; he wanted steadiness, not noise.",
        "journal.street.chen_manager": "A measured encounter with Manager Chen on the road.",
        "journal.flag.heard_foreman_rumor": "Logged Zheng's tip: someone altered the night sheet.",
        "journal.flag.heard_waiter_gossip": "Logged Xiao Fu's gossip about Wanqing and Shaoting.",
        "journal.flag.met_street_aunt": "Auntie now treats you as a talkative regular.",
        "journal.flag.met_garage_hand": "Ah Qiang will share garage straight talk with you.",
        "journal.favor.up": "Their favor toward you rose (+{n}).",
        "journal.favor.down": "Their favor toward you fell ({n}).",
        "ui.chrome.dossier": "People",
        "periods.morning": "Morning",
        "periods.afternoon": "Afternoon",
        "periods.evening": "Evening",
    }
    upsert_l10n(ROOT / "l10n" / "zh_CN.csv", zh)
    upsert_l10n(ROOT / "l10n" / "en.csv", en)
    print("dossier data ok")


if __name__ == "__main__":
    main()
