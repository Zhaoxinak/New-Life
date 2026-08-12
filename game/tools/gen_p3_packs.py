# -*- coding: utf-8 -*-
"""Append P3 content (E019–E021*) onto existing anchao packs."""
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
    rows = data.get("rows", data if isinstance(data, list) else [])
    index = {str(r.get(id_key)): i for i, r in enumerate(rows) if isinstance(r, dict)}
    for nr in new_rows:
        k = str(nr.get(id_key))
        if k in index:
            rows[index[k]] = nr
        else:
            rows.append(nr)
    save(table_file, {"rows": rows})


EVENTS = [
    {
        "event_id": "E019", "loc_key": "event.e019.name", "dialog_entry": "dialog_e019_start",
        "effects_when": "dialog", "mutex_group": "", "route_tags": [],
        "require": [
            {"flag": "flag_e019_done", "value": False},
            {"key": "stat_intel", "op": ">=", "value": 20},
        ],
        "effects": [],
    },
    {
        "event_id": "E020", "loc_key": "event.e020.name", "dialog_entry": "dialog_e020_start",
        "effects_when": "dialog", "mutex_group": "chapter2.rankup", "route_tags": ["route_endure"],
        "require": [
            {"rank": "apprentice"},
            {"key": "stat_trust_firm", "op": ">=", "value": 45},
            {"key": "stat_intel", "op": ">=", "value": 20},
            {"flag": "flag_e020b_done", "value": False},
            {"flag": "flag_e020c_done", "value": False},
        ],
        "effects": [],
    },
    {
        "event_id": "E020B", "loc_key": "event.e020b.name", "dialog_entry": "dialog_e020b_start",
        "effects_when": "dialog", "mutex_group": "chapter2.rankup", "route_tags": ["route_defect"],
        "require": [
            {"rank": "apprentice"},
            {"flag": "route_defect", "value": True},
            {"key": "stat_intel", "op": ">=", "value": 20},
            {"flag": "flag_e020b_done", "value": False},
            {"flag": "flag_rank_waichang_ceremony", "value": False},
        ],
        "effects": [],
    },
    {
        "event_id": "E020C", "loc_key": "event.e020c.name", "dialog_entry": "dialog_e020c_start",
        "effects_when": "dialog", "mutex_group": "chapter2.rankup", "route_tags": ["route_foreign"],
        "require": [
            {"rank": "apprentice"},
            {"flag": "route_foreign", "value": True},
            {"key": "stat_intel", "op": ">=", "value": 20},
            {"flag": "flag_e020c_done", "value": False},
            {"flag": "flag_rank_waichang_ceremony", "value": False},
        ],
        "effects": [],
    },
    {
        "event_id": "E021", "loc_key": "event.e021.name", "dialog_entry": "dialog_e021_start",
        "effects_when": "dialog", "mutex_group": "chapter2.light_reckoning", "route_tags": ["route_endure"],
        "require": [
            {"flag": "flag_grudge_window_light", "value": True},
            {"rank_in": ["waichang", "paojie"]},
            {"flag": "flag_e020b_done", "value": False},
            {"flag": "flag_e020c_done", "value": False},
        ],
        "effects": [],
    },
    {
        "event_id": "E021B", "loc_key": "event.e021b.name", "dialog_entry": "dialog_e021b_start",
        "effects_when": "dialog", "mutex_group": "chapter2.light_reckoning", "route_tags": ["route_defect"],
        "require": [
            {"flag": "flag_grudge_window_light", "value": True},
            {"flag": "flag_e020b_done", "value": True},
            {"rank_in": ["waichang", "paojie"]},
        ],
        "effects": [],
    },
    {
        "event_id": "E021C", "loc_key": "event.e021c.name", "dialog_entry": "dialog_e021c_start",
        "effects_when": "dialog", "mutex_group": "chapter2.light_reckoning", "route_tags": ["route_foreign"],
        "require": [
            {"flag": "flag_grudge_window_light", "value": True},
            {"flag": "flag_e020c_done", "value": True},
            {"rank_in": ["waichang", "paojie"]},
        ],
        "effects": [],
    },
]

CAL = [
    {"day": 8, "slot": "afternoon", "event_id": "E019", "require": [], "mutex_group": ""},
    {"day": 9, "slot": "morning", "event_id": "E020", "require": [], "mutex_group": "chapter2.rankup", "route_tags": ["route_endure"]},
    {"day": 9, "slot": "morning", "event_id": "E020B", "require": [], "mutex_group": "chapter2.rankup", "route_tags": ["route_defect"]},
    {"day": 9, "slot": "morning", "event_id": "E020C", "require": [], "mutex_group": "chapter2.rankup", "route_tags": ["route_foreign"]},
    {"day": 10, "slot": "afternoon", "event_id": "E021", "require": [], "mutex_group": "chapter2.light_reckoning", "route_tags": ["route_endure"]},
    {"day": 10, "slot": "afternoon", "event_id": "E021B", "require": [], "mutex_group": "chapter2.light_reckoning", "route_tags": ["route_defect"]},
    {"day": 10, "slot": "afternoon", "event_id": "E021C", "require": [], "mutex_group": "chapter2.light_reckoning", "route_tags": ["route_foreign"]},
]

E020_FX = [
    {"op": "set_rank", "value": "waichang"},
    {"op": "add", "key": "stat_money", "value": 4},
    {"op": "add", "key": "stat_trust_firm", "value": 5},
    {"op": "add", "key": "stat_network", "value": 5},
    {"op": "set_flag", "key": "flag_rank_waichang_ceremony", "value": True},
    {"op": "set_flag", "key": "flag_grudge_window_light", "value": True},
]
E020B_FX = [
    {"op": "set_rank", "value": "waichang"},
    {"op": "add", "key": "stat_money", "value": 6},
    {"op": "add", "key": "stat_credit_market", "value": 10},
    {"op": "add", "key": "stat_network", "value": 5},
    {"op": "set_flag", "key": "flag_e020b_done", "value": True},
    {"op": "set_flag", "key": "flag_jufeng_offer_open", "value": True},
    {"op": "set_flag", "key": "flag_grudge_window_light", "value": True},
]
E020C_FX = [
    {"op": "set_rank", "value": "waichang"},
    {"op": "add", "key": "stat_money", "value": 3},
    {"op": "add", "key": "stat_credit_foreign", "value": 10},
    {"op": "add", "meter": "impression_bradley", "value": 5},
    {"op": "set_flag", "key": "flag_e020c_done", "value": True},
    {"op": "set_flag", "key": "flag_foreign_door_known", "value": True},
    {"op": "set_flag", "key": "flag_grudge_window_light", "value": True},
]

DIALOGS = [
    # E019
    {"dialog_id": "dialog_e019_start", "event_id": "E019", "speaker": "narrator", "loc_key": "dialog.e019.start", "next": "dialog_e019_choice"},
    {"dialog_id": "dialog_e019_choice", "event_id": "E019", "speaker": "narrator", "loc_key": "dialog.e019.choice_prompt", "choices": [
        {"id": "A", "loc_key": "dialog.e019.choice.a", "effects": [
            {"op": "add", "key": "stat_intel", "value": 3},
            {"op": "add", "key": "stat_trust_firm", "value": 5},
            {"op": "add", "key": "stat_suspicion", "value": 3},
            {"op": "set_flag", "key": "flag_e019_done", "value": True},
            {"op": "set_flag", "key": "flag_info_edge_used", "value": True},
        ], "next": "dialog_e019_outro_a"},
        {"id": "B", "loc_key": "dialog.e019.choice.b", "effects": [
            {"op": "add", "key": "stat_trust_firm", "value": 8},
            {"op": "add", "key": "stat_suspicion", "value": 8},
            {"op": "set_flag", "key": "flag_e019_done", "value": True},
            {"op": "set_flag", "key": "flag_info_edge_used", "value": True},
        ], "next": "dialog_e019_outro_b"},
        {"id": "C", "loc_key": "dialog.e019.choice.c", "effects": [
            {"op": "add", "key": "stat_intel", "value": 2},
            {"op": "set_flag", "key": "flag_e019_done", "value": True},
            {"op": "set_flag", "key": "flag_info_edge_saved", "value": True},
        ], "next": "dialog_e019_outro_c"},
    ]},
    {"dialog_id": "dialog_e019_outro_a", "speaker": "narrator", "loc_key": "dialog.e019.outro.a", "next": ""},
    {"dialog_id": "dialog_e019_outro_b", "speaker": "narrator", "loc_key": "dialog.e019.outro.b", "next": ""},
    {"dialog_id": "dialog_e019_outro_c", "speaker": "narrator", "loc_key": "dialog.e019.outro.c", "next": ""},
    # E020
    {"dialog_id": "dialog_e020_start", "event_id": "E020", "speaker": "narrator", "loc_key": "dialog.e020.start", "next": "dialog_e020_announce"},
    {"dialog_id": "dialog_e020_announce", "speaker": "char_qian_demao", "loc_key": "dialog.e020.announce", "next": "dialog_e020_title"},
    {"dialog_id": "dialog_e020_title", "speaker": "narrator", "loc_key": "dialog.e020.title", "next": "dialog_e020_pay"},
    {"dialog_id": "dialog_e020_pay", "speaker": "char_qian_demao", "loc_key": "dialog.e020.pay", "next": "dialog_e020_window"},
    {"dialog_id": "dialog_e020_window", "speaker": "narrator", "loc_key": "dialog.e020.window", "effects": E020_FX, "next": ""},
    # E020B
    {"dialog_id": "dialog_e020b_start", "event_id": "E020B", "speaker": "narrator", "loc_key": "dialog.e020b.start", "next": "dialog_e020b_quote"},
    {"dialog_id": "dialog_e020b_quote", "speaker": "char_zhao_hongyun", "loc_key": "dialog.e020b.quote", "next": "dialog_e020b_title"},
    {"dialog_id": "dialog_e020b_title", "speaker": "narrator", "loc_key": "dialog.e020b.title", "next": "dialog_e020b_money"},
    {"dialog_id": "dialog_e020b_money", "speaker": "char_zhao_hongyun", "loc_key": "dialog.e020b.money", "next": "dialog_e020b_window"},
    {"dialog_id": "dialog_e020b_window", "speaker": "narrator", "loc_key": "dialog.e020b.window", "effects": E020B_FX, "next": ""},
    # E020C
    {"dialog_id": "dialog_e020c_start", "event_id": "E020C", "speaker": "narrator", "loc_key": "dialog.e020c.start", "next": "dialog_e020c_admit"},
    {"dialog_id": "dialog_e020c_admit", "speaker": "char_bradley", "loc_key": "dialog.e020c.admit", "next": "dialog_e020c_title"},
    {"dialog_id": "dialog_e020c_title", "speaker": "narrator", "loc_key": "dialog.e020c.title", "next": "dialog_e020c_gift"},
    {"dialog_id": "dialog_e020c_gift", "speaker": "char_bradley", "loc_key": "dialog.e020c.gift", "next": "dialog_e020c_window"},
    {"dialog_id": "dialog_e020c_window", "speaker": "narrator", "loc_key": "dialog.e020c.window", "effects": E020C_FX, "next": ""},
]

# E021 family — slight branch only (compressed; onlooker optional)
for prefix, start_key, setup_key, choice_key, pa, pb, pun, forg in [
    ("e021", "dialog.e021.start", "dialog.e021.slight.setup", "dialog.e021.slight.choice",
     "dialog.e021.slight.a", "dialog.e021.slight.b", "dialog.e021.slight.punish", "dialog.e021.slight.forgive"),
    ("e021b", "dialog.e021b.start", "dialog.e021b.slight.choice", "dialog.e021b.slight.choice",
     "dialog.e021b.slight.a", "dialog.e021b.slight.b", "dialog.e021b.slight.punish", "dialog.e021b.slight.forgive"),
    ("e021c", "dialog.e021c.start", "dialog.e021c.slight.choice", "dialog.e021c.slight.choice",
     "dialog.e021c.slight.a", "dialog.e021c.slight.b", "dialog.e021c.slight.punish", "dialog.e021c.slight.forgive"),
]:
    eid = prefix.upper().replace("E021B", "E021B").replace("E021C", "E021C")
    if prefix == "e021":
        eid = "E021"
    elif prefix == "e021b":
        eid = "E021B"
    else:
        eid = "E021C"
    flash = f"dialog_{prefix}_flash"
    choice = f"dialog_{prefix}_choice"
    out_a = f"dialog_{prefix}_punish"
    out_b = f"dialog_{prefix}_forgive"
    skip = f"dialog_{prefix}_skip"
    if prefix == "e021":
        punish_fx = [
            {"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "punish"},
            {"op": "add", "edge": {"from": "char_qian_zian", "to": "char_lin_ruisheng"}, "key": "score", "value": -10},
            {"op": "add", "key": "stat_trust_firm", "value": 5},
            {"op": "set_flag", "key": "flag_grudge_window_light", "value": False},
        ]
        forgive_fx = [
            {"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "forgive"},
            {"op": "add", "edge": {"from": "char_qian_zian", "to": "char_lin_ruisheng"}, "key": "score", "value": -5},
            {"op": "set", "edge": {"from": "char_lin_ruisheng", "to": "char_qian_zian"}, "key": "leverage", "value": "当众放过少爷一次"},
            {"op": "add", "key": "stat_network", "value": 5},
            {"op": "set_flag", "key": "flag_grudge_window_light", "value": False},
        ]
    elif prefix == "e021b":
        punish_fx = [
            {"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "punish"},
            {"op": "add", "edge": {"from": "char_qian_zian", "to": "char_lin_ruisheng"}, "key": "score", "value": -10},
            {"op": "add", "key": "stat_credit_market", "value": 5},
            {"op": "set_flag", "key": "flag_grudge_window_light", "value": False},
        ]
        forgive_fx = [
            {"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "forgive"},
            {"op": "set", "edge": {"from": "char_lin_ruisheng", "to": "char_qian_zian"}, "key": "leverage", "value": "市井上放过少爷一次"},
            {"op": "add", "key": "stat_network", "value": 5},
            {"op": "set_flag", "key": "flag_grudge_window_light", "value": False},
        ]
    else:
        punish_fx = [
            {"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "punish"},
            {"op": "add", "edge": {"from": "char_qian_zian", "to": "char_lin_ruisheng"}, "key": "score", "value": -12},
            {"op": "add", "key": "stat_suspicion", "value": 5},
            {"op": "set_flag", "key": "flag_grudge_window_light", "value": False},
        ]
        forgive_fx = [
            {"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "forgive"},
            {"op": "set", "edge": {"from": "char_lin_ruisheng", "to": "char_qian_zian"}, "key": "leverage", "value": "借洋势压过又收手"},
            {"op": "add", "key": "stat_network", "value": 5},
            {"op": "set_flag", "key": "flag_grudge_window_light", "value": False},
        ]

    DIALOGS.append({
        "dialog_id": f"dialog_{prefix}_start", "event_id": eid, "speaker": "narrator", "loc_key": start_key,
        "next_by_condition": [
            {"require": [{"grudge": "grudge_zian_slight", "status": "open"}], "id": flash},
            {"default": skip},
        ],
    })
    DIALOGS.append({
        "dialog_id": flash, "speaker": "narrator", "loc_key": "dialog.grudge.zian_slight.flash",
        "tags": ["flashback"], "next": choice if prefix != "e021" else "dialog_e021_setup",
    })
    if prefix == "e021":
        DIALOGS.append({"dialog_id": "dialog_e021_setup", "speaker": "narrator", "loc_key": setup_key, "next": choice})
    DIALOGS.append({
        "dialog_id": choice, "event_id": eid, "speaker": "narrator", "loc_key": choice_key,
        "choices": [
            {"id": "A", "loc_key": pa, "effects": punish_fx, "next": out_a},
            {"id": "B", "loc_key": pb, "effects": forgive_fx, "next": out_b},
        ],
    })
    DIALOGS.append({"dialog_id": out_a, "speaker": "narrator", "loc_key": pun, "next": ""})
    DIALOGS.append({"dialog_id": out_b, "speaker": "narrator", "loc_key": forg, "next": ""})
    skip_loc = "dialog.e021.skip" if prefix == "e021" else ("dialog.e021b.skip" if prefix == "e021b" else "dialog.e021c.skip")
    DIALOGS.append({
        "dialog_id": skip, "speaker": "narrator", "loc_key": skip_loc,
        "effects": [{"op": "set_flag", "key": "flag_grudge_window_light", "value": False}],
        "next": "",
    })

# waichang action
ACTIONS_EXTRA = [{
    "act_id": "act_20",
    "loc_id": "loc_01",
    "loc_key": "act.20.name",
    "require": [{"rank_in": ["waichang", "paojie", "houtang"]}],
    "effects": [
        {"op": "add_range", "key": "stat_money", "min": 3, "max": 5},
        {"op": "add", "key": "stat_network", "value": 1},
    ],
    "goto_dialog_by_condition": [{"default": "dialog_act_20_outro"}],
}]
DIALOGS.append({"dialog_id": "dialog_act_20_outro", "speaker": "narrator", "loc_key": "dialog.act.20.outro", "next": ""})

LOC_EXTRA = {
    "event.e019.name": "密账一用",
    "event.e020.name": "升任外场",
    "event.e020b.name": "聚丰报价",
    "event.e020c.name": "洋行门路",
    "event.e021.name": "轻清算",
    "event.e021b.name": "轻清算·街市",
    "event.e021c.name": "轻清算·借势",
    "loc.05.name": "宝顺洋行",
    "act.20.name": "外场跑差",
    "dialog.act.20.outro": "差事办妥。街面有人侧目——叫你时，已经带上「外场」二字。",
    "promo.tip": "升任%s · 月例档 %d 两",
    "promo.beat.ritual": "仪式：当众宣布位子",
    "promo.beat.title": "称呼：%s",
    "promo.beat.permission": "权限：新差事解锁",
    "promo.beat.pay": "月例档上跳",
    "promo.beat.grudge_window": "恩怨窗：有旧账可翻",
    "ui.flashback": "【闪回】",
    "dialog.e019.start": "前堂为货单口径争起来。对方没把你放在眼里。袖里那点账房里摸来的数，像一块烫铁。",
    "dialog.e019.choice_prompt": "（你怎么做？）",
    "dialog.e019.choice.a": "点到为止，逼他让步",
    "dialog.e019.choice.b": "咬得更死",
    "dialog.e019.choice.c": "按住不用",
    "dialog.e019.outro.a": "你只报了一个数、一个日子。对方脸色一变。围观的人看你的眼神换了——不是敬，是忌。",
    "dialog.e019.outro.b": "你追着问了两句不该问穿的。差事赢了，可有人的目光像钉子。",
    "dialog.e019.outro.c": "你把铁按回袖里。今天不当众烫人。",
    "dialog.e020.start": "前堂的人被叫齐了。算盘声停了一拍。",
    "dialog.e020.announce": "瑞生入行三年，差事稳。从今天起，外场跑差归他先盯着。",
    "dialog.e020.title": "有人低声试了一句：「林外场。」像一句玩笑，又像一道门槛。",
    "dialog.e020.pay": "月例按外场规矩加一成。先办好眼前的，别急着谈跑街。",
    "dialog.e020.window": "位子沉了。往后谁再拿你当随意使唤的学徒，得先掂量。有些旧账，也到了可以翻开的时候。",
    "dialog.e020b.start": "茶楼隔间里，赵鸿运把盖碗一推。",
    "dialog.e020b.quote": "林兄弟，钱记那点月例养不住你。聚丰这边位子我可以留——你先把货情理清，启动的银子和位子一块给。",
    "dialog.e020b.title": "他不叫你学徒。他叫的是价码：可投的人。",
    "dialog.e020b.money": "先拿一点定金。不是赏你，是订你。",
    "dialog.e020b.window": "被报价变成了摸得着的东西。市井里那些笑你的嘴，也到了可以讨还的时候。",
    "dialog.e020c.start": "宝顺洋行会客室里，红茶烫着。",
    "dialog.e020c.admit": "林朋友，我记住你了。你若还能再来，我们谈的就不是寒暄。",
    "dialog.e020c.title": "「林朋友」三字被钉在桌上——洋行开始把你写进可往来的人名里。",
    "dialog.e020c.gift": "一点车马。分成的事，等你真能把路走通再谈。",
    "dialog.e020c.window": "银子薄，门路厚。有人再刺你时，你可以借这股势轻轻压回去。",
    "dialog.grudge.zian_slight.flash": "（闪回）他的目光在你脸上停半息，又滑开，像扫过一件不值钱的货。",
    "dialog.e021.start": "外场的位子坐了几天。有笔旧账，今天适合当众了结——或者当众按住。",
    "dialog.e021.skip": "账本翻开，却没有到期的条目。你把袖口放下。",
    "dialog.e021.slight.setup": "钱子安又在前堂指手画脚。你站在外场该站的位置上——比他想象的更靠中间。",
    "dialog.e021.slight.choice": "（你怎么做？）",
    "dialog.e021.slight.a": "惩罚——当众纠正差事口径",
    "dialog.e021.slight.b": "宽恕——压着他，当众放过",
    "dialog.e021.slight.punish": "你把货单数字报准，把他的胡话当场钉死。少爷耳根发青，甩袖走了。",
    "dialog.e021.slight.forgive": "你抬手止住伙计的笑：少爷初来，口径生疏，我改就是。他盯着你，像恨，又像第一次认真打量你。",
    "dialog.e021b.start": "茶楼外的风里，已经有人把「聚丰在谈他」咬热了。",
    "dialog.e021b.skip": "闲话有了，账目却还没到期。",
    "dialog.e021b.slight.choice": "钱子安在街市晃。有人起哄让他「管管」你——你站着，像已经不属于他管的人。",
    "dialog.e021b.slight.a": "惩罚——当众把客户口径说准",
    "dialog.e021b.slight.b": "宽恕——压着他，给台阶下",
    "dialog.e021b.slight.punish": "你报出一串他答不上的数。看客的笑转向他。",
    "dialog.e021b.slight.forgive": "你止住起哄，替他把台阶铺好。他看你的眼神像恨，又像承认你「值个价」。",
    "dialog.e021c.start": "从洋行台阶下来的人，靴底还带着另一边的尘。",
    "dialog.e021c.skip": "势在袖里，你按住不用。",
    "dialog.e021c.slight.choice": "钱子安又要当众拿你垫话。你站得很稳——像背后有一扇他推不开的门。",
    "dialog.e021c.slight.a": "惩罚——借势顶回去",
    "dialog.e021c.slight.b": "宽恕——压住场面，给他留脸",
    "dialog.e021c.slight.punish": "「少爷若有事，不妨托人去洋行那边问一声。」话说得极轻，他却像被烫到。",
    "dialog.e021c.slight.forgive": "你止住更脏的半句：今日不争这个。他保住了脸，却知道脸是你恩准留下的。",
}


def main() -> None:
    upsert_rows("def_event.json", "event_id", EVENTS)
    upsert_rows("def_dialog.json", "dialog_id", DIALOGS)

    cal = load("def_calendar.json")
    rows = cal["rows"]
    existing = {(int(r["day"]), r["slot"], r["event_id"]) for r in rows}
    for c in CAL:
        key = (c["day"], c["slot"], c["event_id"])
        if key not in existing:
            rows.append(c)
    save("def_calendar.json", {"rows": rows})

    act = load("def_action.json")
    aids = {r["act_id"] for r in act["rows"]}
    for a in ACTIONS_EXTRA:
        if a["act_id"] not in aids:
            act["rows"].append(a)
    save("def_action.json", act)

    loc = load("def_location.json")
    lids = {r["loc_id"] for r in loc["rows"]}
    if "loc_05" not in lids:
        loc["rows"].append({
            "loc_id": "loc_05", "loc_key": "loc.05.name",
            "open_slots": ["morning", "noon", "afternoon"], "hotspots": ["hz_foreign"],
        })
        save("def_location.json", loc)

    # align flashback keys
    grudges = load("def_grudge.json")
    for g in grudges["rows"]:
        if g["grudge_id"] == "grudge_zian_slight":
            g["flashback_key"] = "dialog.grudge.zian_slight.flash"
        if g["grudge_id"] == "grudge_demao_defer":
            g["flashback_key"] = g.get("flashback_key", "fb.demao_defer")
        if g["grudge_id"] == "grudge_zian_fiancee":
            g["flashback_key"] = g.get("flashback_key", "fb.zian_fiancee")
    save("def_grudge.json", grudges)

    l10n = load("l10n/zh_CN.json")
    zh = l10n.setdefault("zh_CN", {})
    zh.update(LOC_EXTRA)
    # alias old fb key
    zh["fb.zian_slight"] = zh["dialog.grudge.zian_slight.flash"]
    save("l10n/zh_CN.json", l10n)

    reg = load("registry/events.json")
    have = {e["event_id"] for e in reg.get("events", [])}
    for ev in EVENTS:
        if ev["event_id"] not in have:
            reg["events"].append({
                "event_id": ev["event_id"],
                "chapter": 2,
                "event_type": "mainline_variant" if ev["mutex_group"] else "mainline",
                "dialog_entry": ev["dialog_entry"],
                "mutex_group": ev["mutex_group"],
                "route_tags": ev["route_tags"],
                "status": "active",
            })
    save("registry/events.json", reg)

    pack = load("pack.json")
    pack["content_version"] = "0.4.0-p3"
    save("pack.json", pack)
    print("dialogs added", len(DIALOGS), "events", len(EVENTS))


if __name__ == "__main__":
    main()
