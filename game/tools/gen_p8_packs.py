# -*- coding: utf-8 -*-
"""P8: random events R001–R010 + RandomScanner pack rows."""
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "packs" / "anchao"


def load(name: str):
    return json.loads((ROOT / name).read_text(encoding="utf-8"))


def save(name: str, data) -> None:
    (ROOT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("updated", name)


def upsert_rows(table_file: str, id_key: str, new_rows: list) -> None:
    data = load(table_file)
    rows = data["rows"]
    index = {str(r.get(id_key)): i for i, r in enumerate(rows)}
    for nr in new_rows:
        k = str(nr.get(id_key))
        if k in index:
            rows[index[k]] = nr
        else:
            rows.append(nr)
    save(table_file, {"rows": rows})


def ev(eid, name_key, entry, require, route_tags=None, once=True, cooldown_days=0):
    return {
        "event_id": eid,
        "loc_key": name_key,
        "dialog_entry": entry,
        "event_type": "random",
        "mutex_group": "",
        "route_tags": route_tags or [],
        "once": once,
        "cooldown_days": cooldown_days,
        "require": require,
        "effects": [],
        "effects_when": "dialog",
    }


EVENTS = [
    ev("R001", "event.r001.name", "dialog_r001_start", [
        {"loc": "loc_03"},
        {"slot_in": ["evening"]},
        {"key": "stat_money", "op": ">=", "value": 5},
    ]),
    ev("R002", "event.r002.name", "dialog_r002_start", [
        {"loc": "loc_02"},
        {"slot_in": ["noon", "afternoon", "evening"]},
        {"edge": {"from": "char_wang_pangzi", "to": "char_lin_ruisheng"}, "tier_in": ["相善", "厚交"]},
        {"edge": {"from": "char_wang_pangzi", "to": "char_lin_ruisheng"}, "key": "score", "op": ">=", "value": 40},
    ], once=False, cooldown_days=5),
    ev("R003", "event.r003.name", "dialog_r003_start", [
        {"loc": "loc_01"},
        {"slot_in": ["morning", "noon", "afternoon"]},
        {"flag": "flag_zian_arrived", "value": True},
        {"edge": {"from": "char_qian_zian", "to": "char_lin_ruisheng"}, "tier_in": ["仇隙", "不睦"]},
    ]),
    ev("R004", "event.r004.name", "dialog_r004_start", [
        {"loc": "loc_06"},
        {"slot_in": ["evening"]},
        {"edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "tier_in": ["相善", "厚交"]},
        {"meter": "pursuit", "op": ">=", "value": 30},
    ]),
    ev("R005", "event.r005.name", "dialog_r005_start", [
        {"loc": "loc_03"},
        {"slot_in": ["noon", "afternoon", "evening"]},
        {"key": "stat_network", "op": ">=", "value": 20},
    ], route_tags=["route_defect"]),
    ev("R006", "event.r006.name", "dialog_r006_start", [
        {"loc": "loc_04"},
        {"slot_in": ["morning", "noon"]},
        {"key": "stat_money", "op": ">=", "value": 40},  # 压缩演示略降
    ]),
    ev("R007", "event.r007.name", "dialog_r007_start", [
        {"loc": "loc_02"},
        {"slot_in": ["noon", "afternoon", "evening", "late_night"]},
        {"edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"}, "key": "suspicion", "op": ">=", "value": 2},
        {"flag": "flag_surveilled_today", "value": False},
    ], once=False),
    ev("R008", "event.r008.name", "dialog_r008_start", [
        {"loc": "loc_02"},
        {"slot_in": ["noon", "afternoon"]},
        {"key": "stat_trust_firm", "op": ">=", "value": 40},
    ]),
    ev("R009", "event.r009.name", "dialog_r009_start", [
        {"loc": "loc_03"},
        {"slot_in": ["afternoon", "evening"]},
        {"meter": "impression_bradley", "op": ">=", "value": 20},
        {"flag": "route_foreign", "value": True},
        {"flag": "route_foreign_closed", "value": False},
    ], route_tags=["route_foreign"]),
    ev("R010", "event.r010.name", "dialog_r010_start", [
        {"loc": "loc_01"},
        {"slot_in": ["morning", "noon", "afternoon"]},
        {"flag": "flag_zian_arrived", "value": True},
        {"grudge": "grudge_onlooker", "status": "latent"},
        {"edge": {"from": "char_qian_zian", "to": "char_lin_ruisheng"}, "tier_in": ["仇隙", "不睦"]},
    ]),
]


DIALOGS = [
    # R001
    {"dialog_id": "dialog_r001_start", "event_id": "R001", "speaker": "narrator", "loc_key": "dialog.r001.start", "next": "dialog_r001_pay"},
    {"dialog_id": "dialog_r001_pay", "speaker": "narrator", "loc_key": "dialog.r001.pay", "effects": [
        {"op": "add", "key": "stat_money", "value": -5},
        {"op": "add_range", "key": "stat_intel", "min": 3, "max": 8},
    ], "next": ""},
    # R002
    {"dialog_id": "dialog_r002_start", "event_id": "R002", "speaker": "narrator", "loc_key": "dialog.r002.start", "next": "dialog_r002_tip"},
    {"dialog_id": "dialog_r002_tip", "speaker": "narrator", "loc_key": "dialog.r002.tip", "effects": [
        {"op": "add_range", "key": "stat_intel", "min": 5, "max": 10},
    ], "next": ""},
    # R003
    {"dialog_id": "dialog_r003_start", "event_id": "R003", "speaker": "narrator", "loc_key": "dialog.r003.start", "next": "dialog_r003_zian"},
    {"dialog_id": "dialog_r003_zian", "speaker": "char_qian_zian", "loc_key": "dialog.r003.zian", "next": "dialog_r003_outro"},
    {"dialog_id": "dialog_r003_outro", "speaker": "narrator", "loc_key": "dialog.r003.outro", "effects": [
        {"op": "add", "key": "stat_suspicion", "value": 10},
        {"op": "add", "key": "stat_trust_firm", "value": -5},
        {"op": "add", "edge": {"from": "char_qian_zian", "to": "char_lin_ruisheng"}, "key": "score", "value": -5},
        {"op": "unlock_grudge", "id": "grudge_zian_slight"},
        {"op": "set_flag", "key": "flag_zian_slight_worsened", "value": True},
    ], "next": ""},
    # R004
    {"dialog_id": "dialog_r004_start", "event_id": "R004", "speaker": "narrator", "loc_key": "dialog.r004.start", "next": "dialog_r004_liu"},
    {"dialog_id": "dialog_r004_liu", "speaker": "char_liu_ruyan", "loc_key": "dialog.r004.liu", "next": "dialog_r004_choice"},
    {"dialog_id": "dialog_r004_choice", "event_id": "R004", "speaker": "narrator", "loc_key": "dialog.r004.choice_prompt", "choices": [
        {"id": "A", "loc_key": "dialog.r004.choice.a", "effects": [
            {"op": "add", "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "key": "score", "value": 10},
        ], "next": "dialog_r004_outro_a"},
        {"id": "B", "loc_key": "dialog.r004.choice.b", "effects": [
            {"op": "add", "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "key": "score", "value": -10},
        ], "next": "dialog_r004_outro_b"},
    ]},
    {"dialog_id": "dialog_r004_outro_a", "speaker": "narrator", "loc_key": "dialog.r004.outro.a", "next": ""},
    {"dialog_id": "dialog_r004_outro_b", "speaker": "narrator", "loc_key": "dialog.r004.outro.b", "next": ""},
    # R005
    {"dialog_id": "dialog_r005_start", "event_id": "R005", "speaker": "narrator", "loc_key": "dialog.r005.start", "next": "dialog_r005_zhao"},
    {"dialog_id": "dialog_r005_zhao", "speaker": "char_zhao_hongyun", "loc_key": "dialog.r005.zhao", "next": "dialog_r005_outro"},
    {"dialog_id": "dialog_r005_outro", "speaker": "narrator", "loc_key": "dialog.r005.outro", "effects": [
        {"op": "add", "key": "stat_credit_market", "value": 10},
        {"op": "add", "edge": {"from": "char_zhao_hongyun", "to": "char_lin_ruisheng"}, "key": "score", "value": 10},
        {"op": "set_flag", "key": "flag_zhao_contacted", "value": True},
    ], "next": ""},
    # R006
    {"dialog_id": "dialog_r006_start", "event_id": "R006", "speaker": "narrator", "loc_key": "dialog.r006.start", "next": "dialog_r006_clerk"},
    {"dialog_id": "dialog_r006_clerk", "speaker": "narrator", "loc_key": "dialog.r006.clerk", "effects": [
        {"op": "set_flag", "key": "flag_bank_tier2", "value": True},
        {"op": "add", "key": "stat_credit_bank", "value": 15},
    ], "next": ""},
    # R007
    {"dialog_id": "dialog_r007_start", "event_id": "R007", "speaker": "narrator", "loc_key": "dialog.r007.start", "next": "dialog_r007_feel"},
    {"dialog_id": "dialog_r007_feel", "speaker": "narrator", "loc_key": "dialog.r007.feel", "effects": [
        {"op": "set_temp", "key": "plot_success_mod", "value": -0.30},
        {"op": "set_flag", "key": "flag_surveilled_today", "value": True},
    ], "next": ""},
    # R008
    {"dialog_id": "dialog_r008_start", "event_id": "R008", "speaker": "narrator", "loc_key": "dialog.r008.start", "next": "dialog_r008_gossip"},
    {"dialog_id": "dialog_r008_gossip", "speaker": "narrator", "loc_key": "dialog.r008.gossip", "effects": [
        {"op": "add_range", "key": "stat_intel", "min": 2, "max": 5},
    ], "next": ""},
    # R009
    {"dialog_id": "dialog_r009_start", "event_id": "R009", "speaker": "narrator", "loc_key": "dialog.r009.start", "next": "dialog_r009_outro"},
    {"dialog_id": "dialog_r009_outro", "speaker": "narrator", "loc_key": "dialog.r009.outro", "effects": [
        {"op": "add", "key": "stat_credit_foreign", "value": 5},
        {"op": "add", "edge": {"from": "char_bradley", "to": "char_lin_ruisheng"}, "key": "score", "value": 5},
        {"op": "set_flag", "key": "flag_bradley_invite", "value": True},
    ], "next": ""},
    # R010
    {"dialog_id": "dialog_r010_start", "event_id": "R010", "speaker": "narrator", "loc_key": "dialog.r010.start", "next": "dialog_r010_crowd"},
    {"dialog_id": "dialog_r010_crowd", "speaker": "narrator", "loc_key": "dialog.r010.crowd", "next": "dialog_r010_outro"},
    {"dialog_id": "dialog_r010_outro", "speaker": "narrator", "loc_key": "dialog.r010.outro", "effects": [
        {"op": "unlock_grudge", "id": "grudge_onlooker"},
        {"op": "add", "key": "stat_suspicion", "value": 3},
        {"op": "add", "edge": {"from": "char_lin_ruisheng", "to": "char_zhou_guanshi"}, "key": "score", "value": -5},
    ], "next": ""},
]


LOC = {
    "ui.random_pending": "街市上有点动静……",
    "event.r001.name": "茶楼消息",
    "dialog.r001.start": "茶楼角落，跑码头的消息通拍桌：「林师兄，喝茶？有点新鲜的。」",
    "dialog.r001.pay": "五两换几句半真半假的街谈。你挑着听，记下能对上号的门道。",
    "event.r002.name": "师兄报信",
    "dialog.r002.start": "瑞生，过来。有件事你自己留心。",
    "dialog.r002.tip": "王胖子压低嗓子递来商行动静。",
    "event.r003.name": "钱子安发难",
    "dialog.r003.start": "前堂正忙，钱子安忽然提高嗓门，指名道姓冲你来。",
    "dialog.r003.zian": "林瑞生！这几天你跟在我后头转什么？眼里还有没有少爷？当着众人说清楚！",
    "dialog.r003.outro": "你越解释，围观眼神越怪。少爷甩袖子走了，闲话却留下。",
    "event.r004.name": "柳如烟哭诉",
    "dialog.r004.start": "夜里如烟来到小屋，眼圈红着。",
    "dialog.r004.liu": "瑞生……他又来了。你到底怎么看我？",
    "dialog.r004.choice_prompt": "（你怎么应？）",
    "dialog.r004.choice.a": "软声安慰，让她靠着你",
    "dialog.r004.choice.b": "冷着脸，只说「你自己看着办」",
    "dialog.r004.outro.a": "她把额头抵在你肩上，哭声小了。",
    "dialog.r004.outro.b": "她愣住，咬唇走了。",
    "event.r005.name": "聚丰行接触",
    "dialog.r005.start": "茶楼雅座里，有人斟了杯热茶推过来——聚丰行的赵鸿运。",
    "dialog.r005.zhao": "林兄弟，钱记近来不太平。有本事不必吊死一棵树。手里有货情、人路，位子和月钱都好谈。",
    "dialog.r005.outro": "他留下名片起身。跳槽的门缝微微开了——这是报价，不是义气。",
    "event.r006.name": "钱庄邀约",
    "dialog.r006.start": "钱庄掌柜派人送来一张帖子，请你「有空过来一叙」。",
    "dialog.r006.clerk": "「林爷手头宽裕了，票号高阶往来可以谈。」五十两把你从零碎客抬成能周转的人。",
    "event.r007.name": "被监视",
    "dialog.r007.start": "你走到哪儿，背后总像跟了双眼睛。",
    "dialog.r007.feel": "东家疑心重了。今日再动歪心思，失手可能大得多。",
    "event.r008.name": "伙计私语",
    "dialog.r008.start": "午后闲档，伙计把你拉进闲话。",
    "dialog.r008.gossip": "东家脾气、少爷作派、夜里多出来的车——总能拼进你的账。",
    "event.r009.name": "洋行邀约",
    "dialog.r009.start": "一张烫金名片——宝顺洋行请你得空坐坐。",
    "dialog.r009.outro": "洋行的门开了一道缝。进门资格有了，价码另谈。",
    "event.r010.name": "看客起哄",
    "dialog.r010.start": "你刚被少爷差去跑腿，回来时前堂有人故意抬高嗓门。",
    "dialog.r010.crowd": "「哟，林师兄，这回跟得可紧——少爷靴尖都亮了。」笑声不大，刚好够你听见。",
    "dialog.r010.outro": "你没接话。那笑进了人账——跟风落井，日后再兑。",
    "grudge.onlooker": "看客起哄债",
    "dialog.grudge.onlooker.flash": "（闪回）前堂那几声哄笑，像钉子一样钉在耳膜上。",
}


def main() -> None:
    upsert_rows("def_event.json", "event_id", EVENTS)
    upsert_rows("def_dialog.json", "dialog_id", DIALOGS)

    grudges = load("def_grudge.json")
    have_g = {g["grudge_id"] for g in grudges["rows"]}
    if "grudge_onlooker" not in have_g:
        grudges["rows"].append({
            "grudge_id": "grudge_onlooker",
            "debtor": "char_zhou_guanshi",
            "initial_status": "latent",
            "flashback_key": "dialog.grudge.onlooker.flash",
            "loc_key": "grudge.onlooker",
            "bury_event": "R010",
        })
        save("def_grudge.json", grudges)

    edges = load("def_edge_init.json")
    have_e = {(r["from"], r["to"]) for r in edges["rows"]}
    for frm, to, score in [
        ("char_zhao_hongyun", "char_lin_ruisheng", 10),
        ("char_bradley", "char_lin_ruisheng", 5),
        ("char_lin_ruisheng", "char_zhou_guanshi", 0),
        ("char_wang_pangzi", "char_lin_ruisheng", 45),
    ]:
        if (frm, to) not in have_e:
            edges["rows"].append({
                "from": frm, "to": to, "score": score,
                "suspicion": 0, "trust": 0, "fear": 0,
            })
            have_e.add((frm, to))
        else:
            for r in edges["rows"]:
                if r["from"] == frm and r["to"] == to and frm == "char_wang_pangzi":
                    r["score"] = max(int(r.get("score", 0)), 45)
    save("def_edge_init.json", edges)

    # loc_04 钱庄若缺则补最小行
    locs = load("def_location.json")
    have_l = {r["loc_id"] for r in locs["rows"]}
    if "loc_04" not in have_l:
        locs["rows"].append({
            "loc_id": "loc_04",
            "loc_key": "loc.04.name",
            "open_slots": ["morning", "noon", "afternoon"],
        })
        save("def_location.json", locs)
    if "loc_06" not in have_l and "loc_06" not in {r["loc_id"] for r in locs["rows"]}:
        locs = load("def_location.json")
        locs["rows"].append({
            "loc_id": "loc_06",
            "loc_key": "loc.06.name",
            "open_slots": ["evening", "late_night"],
        })
        save("def_location.json", locs)

    l10n = load("l10n/zh_CN.json")
    zh = l10n.setdefault("zh_CN", {})
    zh.update(LOC)
    zh.setdefault("loc.04.name", "钱庄票号")
    zh.setdefault("loc.06.name", "货栈小屋")
    save("l10n/zh_CN.json", l10n)

    # 确保有能触发随机的行动（茶楼/前堂）
    acts = load("def_action.json")
    have_a = {a["act_id"] for a in acts["rows"]}
    extra_acts = []
    if "act_teahouse_listen" not in have_a:
        extra_acts.append({
            "act_id": "act_teahouse_listen",
            "loc_id": "loc_03",
            "loc_key": "act.teahouse_listen",
            "require": [],
            "effects": [{"op": "add", "key": "stat_money", "value": -1}],
        })
    if "act_front_idle" not in have_a:
        extra_acts.append({
            "act_id": "act_front_idle",
            "loc_id": "loc_01",
            "loc_key": "act.front_idle",
            "require": [],
            "effects": [],
        })
    if "act_bank_visit" not in have_a:
        extra_acts.append({
            "act_id": "act_bank_visit",
            "loc_id": "loc_04",
            "loc_key": "act.bank_visit",
            "require": [],
            "effects": [],
        })
    if extra_acts:
        acts["rows"].extend(extra_acts)
        save("def_action.json", acts)
        zh.update({
            "act.teahouse_listen": "茶楼听闲话",
            "act.front_idle": "前堂走动",
            "act.bank_visit": "拜访钱庄",
        })
        save("l10n/zh_CN.json", l10n)

    reg = load("registry/events.json")
    have_r = {e["event_id"] for e in reg.get("events", [])}
    for e in EVENTS:
        entry = {
            "event_id": e["event_id"],
            "chapter": 0,
            "event_type": "random",
            "dialog_entry": e["dialog_entry"],
            "mutex_group": "",
            "route_tags": e.get("route_tags", []),
            "status": "active",
        }
        if e["event_id"] not in have_r:
            reg["events"].append(entry)
        else:
            for row in reg["events"]:
                if row["event_id"] == e["event_id"]:
                    row.update(entry)
    save("registry/events.json", reg)

    pack = load("pack.json")
    pack["content_version"] = "0.9.0-p8"
    save("pack.json", pack)
    print("dialogs", len(DIALOGS), "events", len(EVENTS))


if __name__ == "__main__":
    main()
