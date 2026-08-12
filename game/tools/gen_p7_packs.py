# -*- coding: utf-8 -*-
"""P7: chapter-3 bridge E014–E017 between E021 and E022."""
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


EVENTS = [
    {
        "event_id": "E014",
        "loc_key": "event.e014.name",
        "dialog_entry": "dialog_e014_start",
        "mutex_group": "",
        "route_tags": [],
        "require": [
            {"key": "stat_intel", "op": ">=", "value": 35},
            {"clue": "clue_special_goods", "owned": True},
        ],
        "effects": [],
        "effects_when": "dialog",
    },
    {
        "event_id": "E015",
        "loc_key": "event.e015.name",
        "dialog_entry": "dialog_e015_start",
        "mutex_group": "",
        "route_tags": [],
        "require": [
            {"key": "stat_intel", "op": ">=", "value": 35},
            {"clue": "clue_special_goods", "owned": True},
            {"or": [
                {"edge": {"from": "char_wang_pangzi", "to": "char_lin_ruisheng"}, "key": "score", "op": ">=", "value": 35},
                {"key": "stat_network", "op": ">=", "value": 25},
            ]},
        ],
        "effects": [],
        "effects_when": "dialog",
    },
    {
        "event_id": "E016",
        "loc_key": "event.e016.name",
        "dialog_entry": "dialog_e016_start",
        "mutex_group": "",
        "route_tags": [],  # 全线可播；路线加成靠叙事
        "require": [
            {"key": "stat_intel", "op": ">=", "value": 35},
            {"meter": "father_son", "op": "<=", "value": 45},
        ],
        "effects": [],
        "effects_when": "dialog",
    },
    {
        "event_id": "E017",
        "loc_key": "event.e017.name",
        "dialog_entry": "dialog_e017_start",
        "mutex_group": "",
        "route_tags": ["route_foreign"],
        "require": [
            {"meter": "impression_qing", "op": ">=", "value": 30},
            {"meter": "impression_bradley", "op": ">=", "value": 10},
            {"flag": "route_foreign", "value": True},
            {"flag": "route_foreign_closed", "value": False},
        ],
        "effects": [],
        "effects_when": "dialog",
    },
]


DIALOGS = [
    # E014
    {"dialog_id": "dialog_e014_start", "event_id": "E014", "speaker": "narrator", "loc_key": "dialog.e014.start", "next": "dialog_e014_overhear"},
    {"dialog_id": "dialog_e014_overhear", "speaker": "narrator", "loc_key": "dialog.e014.overhear", "next": "dialog_e014_zian_1"},
    {"dialog_id": "dialog_e014_zian_1", "speaker": "char_qian_zian", "loc_key": "dialog.e014.zian_1", "next": "dialog_e014_retainer"},
    {"dialog_id": "dialog_e014_retainer", "speaker": "narrator", "loc_key": "dialog.e014.retainer", "next": "dialog_e014_zian_2"},
    {"dialog_id": "dialog_e014_zian_2", "speaker": "char_qian_zian", "loc_key": "dialog.e014.zian_2", "next": "dialog_e014_realize"},
    {"dialog_id": "dialog_e014_realize", "speaker": "narrator", "loc_key": "dialog.e014.realize", "next": "dialog_e014_choice"},
    {
        "dialog_id": "dialog_e014_choice",
        "event_id": "E014",
        "speaker": "narrator",
        "loc_key": "dialog.e014.choice_prompt",
        "choices": [
            {
                "id": "A",
                "loc_key": "dialog.e014.choice.a",
                "require": [
                    {"key": "stat_support_mid", "op": ">=", "value": 40},
                    {"key": "stat_support_low", "op": ">=", "value": 40},
                ],
                "effects": [
                    {"op": "add", "key": "stat_intel", "value": 15},
                    {"op": "add", "key": "stat_suspicion", "value": 10},
                    {"op": "add", "meter": "impression_qing", "value": 30},
                    {"op": "add", "edge": {"from": "char_qing_daren", "to": "char_lin_ruisheng"}, "key": "score", "value": 25},
                    {"op": "add", "edge": {"from": "char_zhou_guanshi", "to": "char_lin_ruisheng"}, "key": "score", "value": 20},
                    {"op": "grant_item", "id": "item_qing_letter"},
                ],
                "next": "dialog_e014_outro_a",
            },
            {
                "id": "B",
                "loc_key": "dialog.e014.choice.b",
                "effects": [
                    {"op": "add", "key": "stat_trust_firm", "value": 10},
                    {"op": "add", "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"}, "key": "score", "value": 8},
                    {"op": "add", "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"}, "key": "suspicion", "value": 1},
                    {"op": "add", "meter": "father_son", "value": -25},
                    {"op": "add", "edge": {"from": "char_qian_demao", "to": "char_qian_zian"}, "key": "score", "value": -15},
                    {"op": "add", "edge": {"from": "char_qian_zian", "to": "char_qian_demao"}, "key": "score", "value": -10},
                ],
                "next": "dialog_e014_outro_b",
            },
            {
                "id": "C",
                "loc_key": "dialog.e014.choice.c",
                "effects": [
                    {"op": "add", "meter": "father_son", "value": -40},
                    {"op": "add", "key": "stat_intel", "value": 5},
                    {"op": "set_flag", "key": "route_foreign_closed", "value": True},
                ],
                "next": "dialog_e014_outro_c",
            },
        ],
    },
    {"dialog_id": "dialog_e014_outro_a", "speaker": "narrator", "loc_key": "dialog.e014.outro.a", "next": ""},
    {"dialog_id": "dialog_e014_outro_b", "speaker": "narrator", "loc_key": "dialog.e014.outro.b", "next": ""},
    {"dialog_id": "dialog_e014_outro_c", "speaker": "narrator", "loc_key": "dialog.e014.outro.c", "next": ""},
    # E015
    {"dialog_id": "dialog_e015_start", "event_id": "E015", "speaker": "narrator", "loc_key": "dialog.e015.start", "next": "dialog_e015_open"},
    {"dialog_id": "dialog_e015_open", "speaker": "narrator", "loc_key": "dialog.e015.open", "next": "dialog_e015_know"},
    {"dialog_id": "dialog_e015_know", "speaker": "narrator", "loc_key": "dialog.e015.know", "next": "dialog_e015_legal"},
    {"dialog_id": "dialog_e015_legal", "speaker": "narrator", "loc_key": "dialog.e015.legal", "next": "dialog_e015_smuggle"},
    {"dialog_id": "dialog_e015_smuggle", "speaker": "narrator", "loc_key": "dialog.e015.smuggle", "next": "dialog_e015_puzzle"},
    {"dialog_id": "dialog_e015_puzzle", "speaker": "narrator", "loc_key": "dialog.e015.puzzle", "next": "dialog_e015_weight"},
    {"dialog_id": "dialog_e015_weight", "speaker": "narrator", "loc_key": "dialog.e015.weight", "next": "dialog_e015_choice"},
    {
        "dialog_id": "dialog_e015_choice",
        "event_id": "E015",
        "speaker": "narrator",
        "loc_key": "dialog.e015.choice_prompt",
        "choices": [
            {
                "id": "A",
                "loc_key": "dialog.e015.choice.a",
                "effects": [
                    {"op": "add", "key": "stat_intel", "value": 30},
                    {"op": "add", "key": "stat_suspicion", "value": 10},
                    {"op": "unlock_clue", "id": "clue_opium_secret"},
                    {"op": "grant_item", "id": "item_opium_sample"},
                ],
                "next": "dialog_e015_outro_a",
            },
            {
                "id": "B",
                "loc_key": "dialog.e015.choice.b",
                "effects": [
                    {"op": "add", "key": "stat_intel", "value": 15},
                    {"op": "unlock_clue", "id": "clue_opium_infer"},
                ],
                "next": "dialog_e015_outro_b",
            },
            {
                "id": "C",
                "loc_key": "dialog.e015.choice.c",
                "effects": [
                    {"op": "add", "key": "stat_money", "value": 100},
                    {"op": "add", "key": "stat_intel", "value": 10},
                    {"op": "add", "key": "stat_suspicion", "value": 40},
                    {"op": "set_flag", "key": "flag_dirty_money_marked", "value": True},
                    {"op": "set", "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"}, "key": "leverage", "value": "盗卖把柄"},
                    {"op": "unlock_clue", "id": "clue_opium_infer"},
                ],
                "next": "dialog_e015_outro_c",
            },
        ],
    },
    {"dialog_id": "dialog_e015_outro_a", "speaker": "narrator", "loc_key": "dialog.e015.outro.a", "next": ""},
    {"dialog_id": "dialog_e015_outro_b", "speaker": "narrator", "loc_key": "dialog.e015.outro.b", "next": ""},
    {"dialog_id": "dialog_e015_outro_c", "speaker": "narrator", "loc_key": "dialog.e015.outro.c", "next": ""},
    # E016
    {"dialog_id": "dialog_e016_start", "event_id": "E016", "speaker": "narrator", "loc_key": "dialog.e016.start", "next": "dialog_e016_choice"},
    {
        "dialog_id": "dialog_e016_choice",
        "event_id": "E016",
        "speaker": "narrator",
        "loc_key": "dialog.e016.choice_prompt",
        "choices": [
            {"id": "A", "loc_key": "dialog.e016.choice.a", "next": "dialog_e016_a_lin"},
            {
                "id": "B",
                "loc_key": "dialog.e016.choice.b",
                "require": [{"meter": "pursuit", "op": ">=", "value": 40}],
                "next": "dialog_e016_b_liu",
            },
        ],
    },
    {"dialog_id": "dialog_e016_a_lin", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e016.a.lin", "next": "dialog_e016_a_zian"},
    {"dialog_id": "dialog_e016_a_zian", "speaker": "char_qian_zian", "loc_key": "dialog.e016.a.zian", "next": "dialog_e016_a_lin2"},
    {"dialog_id": "dialog_e016_a_lin2", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e016.a.lin2", "next": "dialog_e016_a_zian2"},
    {
        "dialog_id": "dialog_e016_a_zian2",
        "speaker": "char_qian_zian",
        "loc_key": "dialog.e016.a.zian2",
        "effects": [
            {"op": "add", "meter": "father_son", "value": -15},
            {"op": "add", "edge": {"from": "char_qian_zian", "to": "char_qian_demao"}, "key": "score", "value": -10},
            {"op": "set_flag", "key": "flag_power_shift_visible", "value": True},
            {"op": "set_flag", "key": "flag_qian_infighting", "value": True},
        ],
        "next": "dialog_e016_outro_a",
    },
    {"dialog_id": "dialog_e016_outro_a", "speaker": "narrator", "loc_key": "dialog.e016.outro.a", "next": ""},
    {"dialog_id": "dialog_e016_b_liu", "speaker": "char_liu_ruyan", "loc_key": "dialog.e016.b.liu", "next": "dialog_e016_b_zian"},
    {"dialog_id": "dialog_e016_b_zian", "speaker": "char_qian_zian", "loc_key": "dialog.e016.b.zian", "next": "dialog_e016_b_liu2"},
    {
        "dialog_id": "dialog_e016_b_liu2",
        "speaker": "char_liu_ruyan",
        "loc_key": "dialog.e016.b.liu2",
        "effects": [
            {"op": "add", "meter": "father_son", "value": -20},
            {"op": "add", "edge": {"from": "char_qian_zian", "to": "char_liu_ruyan"}, "key": "suspicion", "value": 1},
            {"op": "add", "meter": "liu_source_risk", "value": 10},
            {"op": "set_flag", "key": "flag_power_shift_visible", "value": True},
            {"op": "set_flag", "key": "flag_qian_infighting", "value": True},
        ],
        "next": "dialog_e016_outro_b",
    },
    {"dialog_id": "dialog_e016_outro_b", "speaker": "narrator", "loc_key": "dialog.e016.outro.b", "next": ""},
    # E017
    {"dialog_id": "dialog_e017_start", "event_id": "E017", "speaker": "narrator", "loc_key": "dialog.e017.start", "next": "dialog_e017_lin_hint"},
    {"dialog_id": "dialog_e017_lin_hint", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e017.lin_hint", "next": "dialog_e017_bradley_probe"},
    {"dialog_id": "dialog_e017_bradley_probe", "speaker": "char_bradley", "loc_key": "dialog.e017.bradley_probe", "next": "dialog_e017_lin_hedge"},
    {"dialog_id": "dialog_e017_lin_hedge", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e017.lin_hedge", "next": "dialog_e017_bradley_ask_narr"},
    {"dialog_id": "dialog_e017_bradley_ask_narr", "speaker": "narrator", "loc_key": "dialog.e017.bradley_ask_narr", "next": "dialog_e017_bradley_ask"},
    {"dialog_id": "dialog_e017_bradley_ask", "speaker": "char_bradley", "loc_key": "dialog.e017.bradley_ask", "next": "dialog_e017_choice"},
    {
        "dialog_id": "dialog_e017_choice",
        "event_id": "E017",
        "speaker": "narrator",
        "loc_key": "dialog.e017.choice_prompt",
        "choices": [
            {
                "id": "A",
                "loc_key": "dialog.e017.choice.a",
                "require": [
                    {"meter": "impression_qing", "op": ">=", "value": 30},
                    {"item": "item_qing_letter", "owned": True},
                ],
                "effects": [
                    {"op": "add", "key": "stat_credit_foreign", "value": 15},
                    {"op": "add", "meter": "impression_bradley", "value": 25},
                    {"op": "add", "edge": {"from": "char_bradley", "to": "char_lin_ruisheng"}, "key": "score", "value": 20},
                    {"op": "add", "meter": "eval", "value": -10},
                    {"op": "set_flag", "key": "flag_ending_c_ready", "value": True},
                ],
                "next": "dialog_e017_outro_a_line",
            },
            {
                "id": "B",
                "loc_key": "dialog.e017.choice.b",
                "effects": [
                    {"op": "add", "key": "stat_credit_foreign", "value": 8},
                    {"op": "add", "meter": "impression_bradley", "value": 15},
                    {"op": "add", "edge": {"from": "char_bradley", "to": "char_lin_ruisheng"}, "key": "score", "value": 10},
                ],
                "next": "dialog_e017_outro_b",
            },
            {
                "id": "C",
                "loc_key": "dialog.e017.choice.c",
                "effects": [
                    {"op": "add", "key": "stat_credit_foreign", "value": 3},
                    {"op": "add", "meter": "impression_bradley", "value": 5},
                    {"op": "add", "edge": {"from": "char_bradley", "to": "char_lin_ruisheng"}, "key": "score", "value": 3},
                ],
                "next": "dialog_e017_outro_c",
            },
        ],
    },
    {"dialog_id": "dialog_e017_outro_a_line", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e017.outro.a_line", "next": "dialog_e017_outro_a"},
    {"dialog_id": "dialog_e017_outro_a", "speaker": "narrator", "loc_key": "dialog.e017.outro.a", "next": ""},
    {"dialog_id": "dialog_e017_outro_b", "speaker": "narrator", "loc_key": "dialog.e017.outro.b", "next": ""},
    {"dialog_id": "dialog_e017_outro_c", "speaker": "narrator", "loc_key": "dialog.e017.outro.c", "next": ""},
]


LOC = {
    "event.e014.name": "钱子安的鲁莽",
    "event.e015.name": "真相大白",
    "event.e016.name": "挑拨父子",
    "event.e017.name": "向洋人递刀",
    "dialog.e014.start": "林瑞生偶然听到钱子安在屋里发牢骚——他从账房偷看了父亲的密账，发现「每月往北京送三万两」，不知道背后的庆大人，以为父亲被人骗了或者在私吞家产。",
    "dialog.e014.overhear": "（隔墙，听得真切。）",
    "dialog.e014.zian_1": "三万两！他一个月给我二十两月例，转头给北京送三万两！凭什么？他当我是傻子？",
    "dialog.e014.retainer": "【随从】少爷，要不……问问东家？",
    "dialog.e014.zian_2": "问个屁！他问起来我就说不知道。下次那批货出门，我亲自去截——我看他怎么解释！",
    "dialog.e014.realize": "林瑞生心头一震。结合账房里那本「特别货」密账、末页「庆大人·月奉」——少爷要截的，八成是送往京中的货与银票。若真截了：那边收不到东西，钱德茂未必保得住自己。三万两不是小账。那不是少爷多眼红了几锭银子，而是他第一次看清：家里真正的大钱，从来没准备分到他手上。至于货里究竟是什么，你心里有影，却还没亲眼钉死。眼下更要紧的是——这是一个天大的机会。",
    "dialog.e014.choice_prompt": "（你怎么做？）",
    "dialog.e014.choice.a": "暗中阻止钱子安，自己接手护送银票",
    "dialog.e014.choice.b": "直接告诉钱德茂，让他自己处理",
    "dialog.e014.choice.c": "放任不管",
    "dialog.e014.outro.a": "银票交到周管事手上。他捻了捻封口，看了你一眼，没多问。回京复命时，会提起天津有个叫林瑞生的年轻人，办差妥帖。（获得信物：庆系相关凭据）",
    "dialog.e014.outro.b": "钱德茂听完脸色铁青。他对儿子更不放心了——也对你多了一分疑心：你怎么知道得这么清楚？你明白：你拿到的不是银子，是可被允许经手的信任门缝。",
    "dialog.e014.outro.c": "货被截了。钱家乱成一团。庆大人那边断了线——你那条狐假虎威的路，也断了。",
    "dialog.e015.start": "林瑞生找到机会，在库房深处一个上了锁的暗箱前停下。他从师兄王胖子那里套到了钥匙的位置。",
    "dialog.e015.open": "打开暗箱，里面是油纸包裹的黑色膏状物——整整齐齐码了半箱。林瑞生见过烟馆门口那些鬼鬼祟祟的人，闻过那种甜腻的焦味。",
    "dialog.e015.know": "他知道这是什么了。洋药。鸦片。",
    "dialog.e015.legal": "但林瑞生在码头混了三年，他知道鸦片生意本身不违法——洋药完了税，凭单运销内地，正经买卖人做得。钱记若是正大光明做，也没什么了不起。",
    "dialog.e015.smuggle": "可钱记不是正大光明的。木材货单上写「南洋木器」，海关报关单上没有这批货。它们从暗道入库，半夜卸货，东家亲自盯着。",
    "dialog.e015.puzzle": "加上账房密账里记的「特别货」——进价八十两、售价三百两——和末页「庆大人·月奉」。钱记的鸦片走两条线：一条完税撑门面，一条绕关走私才是真正暴利。一箱八十两转手三百两。跑街月例多那二两，在这半箱黑膏面前都像笑话。",
    "dialog.e015.weight": "东家表面是木材商人，暗地是逃税走私犯，更深处还是京中高官的暗钱通道。那一刻，复仇不再只是未婚妻和升职——自己低头苦熬为的是几两月例；钱家夜里搬的，是能换掉一个人一辈子的银子。",
    "dialog.e015.choice_prompt": "（你怎么做？）",
    "dialog.e015.choice.a": "拿一小块样品，放回暗箱",
    "dialog.e015.choice.b": "不动暗箱，靠已有信息推断",
    "dialog.e015.choice.c": "拿走大量鸦片，转手卖钱",
    "dialog.e015.outro.a": "一小块膏体贴身藏好。货单、暗道、密账、实物——证据链齐了。",
    "dialog.e015.outro.b": "你合上暗箱。脑子里的拼图已经够用；只是少一块实物，要挟时会软一分。",
    "dialog.e015.outro.c": "银子烫手。你头一回真把这条黑钱路掰了一块塞进自己怀里。若是东家查库，你连退路都没有。",
    "dialog.e016.start": "林瑞生开始利用收集到的情报，在钱氏父子之间制造裂痕。你知道：这不是闹脾气，是在给暗线入口拆门。",
    "dialog.e016.choice_prompt": "（你下手的方式？）",
    "dialog.e016.choice.a": "向钱子安「无意」提起往北京汇的三万两",
    "dialog.e016.choice.b": "让柳如烟吹枕边风（需纠缠够热）",
    "dialog.e016.a.lin": "少爷，今天账房来了一笔汇款单子。东家往北京汇了三万两。",
    "dialog.e016.a.zian": "三万两？他给我一个月的月例才多少？二十两！",
    "dialog.e016.a.lin2": "少爷，这话我不该说的。可您是东家独子，这商行迟早……",
    "dialog.e016.a.zian2": "他钱德茂嘴上说让我历练，实际上把我扔在天津，自己把银子往北京搬！",
    "dialog.e016.outro.a": "少爷拍桌的声音，隔着木门都能听见。父子之间，又裂开一道口子——足够你伸手进暗处一寸。",
    "dialog.e016.b.liu": "少爷，我听厂里姐妹说……东家最近好像不打算让您管账上的事。",
    "dialog.e016.b.zian": "他连账都不让我碰？",
    "dialog.e016.b.liu2": "我……我也是听人说的。",
    "dialog.e016.outro.b": "裂痕更深了。可钱子安不是傻子——他开始打量消息从哪儿来。暗线入口就在眼前，也就更危险。",
    "dialog.e017.start": "林瑞生在茶楼「偶遇」白瑞德。两人寒暄后，林瑞生看似无意地提起——",
    "dialog.e017.lin_hint": "白先生，钱记商行最近不太平。少爷和东家闹得厉害，听说少爷还要截东家的货。这种事，外人不好说，可钱记若是内部不稳……跟宝顺洋行合作，怕是不保险。",
    "dialog.e017.bradley_probe": "哦？截货？什么样的货？",
    "dialog.e017.lin_hedge": "这我就不清楚了。只是风声。白先生要跟钱东家合作，还是多看看为好。",
    "dialog.e017.bradley_ask_narr": "白瑞德沉默片刻，然后笑了。",
    "dialog.e017.bradley_ask": "林朋友，你倒是热心。不过——你跟我说这些，图什么？",
    "dialog.e017.choice_prompt": "（你怎么答？）",
    "dialog.e017.choice.a": "直接摊牌，亮出庆大人管事的手书",
    "dialog.e017.choice.b": "暗示有更好的合作人选（自己），但不亮底牌",
    "dialog.e017.choice.c": "不图什么，只是「好心提醒」",
    "dialog.e017.outro.a_line": "白先生要找有官场背景的人。我恰好认识一些京中的朋友。",
    "dialog.e017.outro.a": "白瑞德看过手书，态度明显转变。他表示有兴趣详谈，邀请你到宝顺洋行正式会谈。",
    "dialog.e017.outro.b": "白瑞德领会了意思，却不急着拍板：「再办成一件让我看见的事——然后，我们再谈价。」",
    "dialog.e017.outro.c": "「好心。」白瑞德重复这两个字，像在品尝。他起身时只说：「林朋友，宝顺的门不常开。下次来，带点真东西。」",
    "clue.opium_secret": "鸦片秘密",
    "clue.opium_infer": "鸦片推断",
    "item.qing_letter": "庆系手书",
    "item.opium_sample": "鸦片样品",
}


CAL = [
    {"day": 1, "slot": "morning", "event_id": "E001", "require": []},
    {"day": 2, "slot": "evening", "event_id": "E002", "require": []},
    {"day": 3, "slot": "afternoon", "event_id": "E003", "require": []},
    {"day": 4, "slot": "morning", "event_id": "E004", "require": []},
    {"day": 4, "slot": "evening", "event_id": "E005", "require": []},
    {"day": 5, "slot": "morning", "event_id": "E006", "require": []},
    {"day": 5, "slot": "afternoon", "event_id": "E007", "require": []},
    {"day": 6, "slot": "evening", "event_id": "E008", "require": []},
    {"day": 7, "slot": "late_night", "event_id": "E009", "require": []},
    {"day": 8, "slot": "late_night", "event_id": "E010", "require": [], "mutex_group": "chapter2.night_cargo"},
    {"day": 9, "slot": "afternoon", "event_id": "E011", "require": []},
    {"day": 9, "slot": "evening", "event_id": "E012", "require": []},
    {"day": 10, "slot": "late_night", "event_id": "E010b", "require": [], "mutex_group": "chapter2.night_cargo"},
    {"day": 11, "slot": "late_night", "event_id": "E013", "require": []},
    {"day": 12, "slot": "afternoon", "event_id": "E019", "require": [], "mutex_group": ""},
    {"day": 13, "slot": "morning", "event_id": "E020", "require": [], "mutex_group": "chapter2.rankup", "route_tags": ["route_endure"]},
    {"day": 13, "slot": "morning", "event_id": "E020B", "require": [], "mutex_group": "chapter2.rankup", "route_tags": ["route_defect"]},
    {"day": 13, "slot": "morning", "event_id": "E020C", "require": [], "mutex_group": "chapter2.rankup", "route_tags": ["route_foreign"]},
    {"day": 14, "slot": "afternoon", "event_id": "E021", "require": [], "mutex_group": "chapter2.light_reckoning", "route_tags": ["route_endure"]},
    {"day": 14, "slot": "afternoon", "event_id": "E021B", "require": [], "mutex_group": "chapter2.light_reckoning", "route_tags": ["route_defect"]},
    {"day": 14, "slot": "afternoon", "event_id": "E021C", "require": [], "mutex_group": "chapter2.light_reckoning", "route_tags": ["route_foreign"]},
    {"day": 15, "slot": "afternoon", "event_id": "E014", "require": []},
    {"day": 16, "slot": "late_night", "event_id": "E015", "require": []},
    {"day": 17, "slot": "afternoon", "event_id": "E016", "require": []},
    {"day": 17, "slot": "evening", "event_id": "E017", "require": [], "route_tags": ["route_foreign"], "mutex_group": ""},
    {"day": 18, "slot": "afternoon", "event_id": "E022", "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_endure"], "require": []},
    {"day": 18, "slot": "afternoon", "event_id": "E022B", "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_defect"], "require": []},
    {"day": 18, "slot": "afternoon", "event_id": "E022C", "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_foreign"], "require": []},
    {"day": 19, "slot": "morning", "event_id": "E018", "mutex_group": "chapter3.finale", "require": []},
]


def main() -> None:
    upsert_rows("def_event.json", "event_id", EVENTS)
    upsert_rows("def_dialog.json", "dialog_id", DIALOGS)
    save("def_calendar.json", {"rows": CAL})

    meters = load("def_meter_init.json")
    meters["father_son"] = 55
    meters["eval"] = 30
    meters["liu_source_risk"] = 0
    meters.setdefault("pursuit", 0)
    meters.setdefault("impression_qing", 0)
    meters.setdefault("impression_bradley", 0)
    save("def_meter_init.json", meters)

    # seed wang edge for E015 soft path
    edges = load("def_edge_init.json")
    have = {(r["from"], r["to"]) for r in edges["rows"]}
    if ("char_wang_pangzi", "char_lin_ruisheng") not in have:
        edges["rows"].append({
            "from": "char_wang_pangzi",
            "to": "char_lin_ruisheng",
            "score": 35,
            "suspicion": 0,
            "trust": 1,
            "fear": 0,
        })
        save("def_edge_init.json", edges)

    l10n = load("l10n/zh_CN.json")
    l10n.setdefault("zh_CN", {}).update(LOC)
    save("l10n/zh_CN.json", l10n)

    clues = load("def_clue.json")
    have_c = {c["clue_id"] for c in clues["rows"]}
    for cid, loc in [
        ("clue_opium_secret", "clue.opium_secret"),
        ("clue_opium_infer", "clue.opium_infer"),
    ]:
        if cid not in have_c:
            clues["rows"].append({"clue_id": cid, "loc_key": loc, "arc": "opium"})
    save("def_clue.json", clues)

    reg = load("registry/events.json")
    have_e = {e["event_id"] for e in reg.get("events", [])}
    for ev in EVENTS:
        entry = {
            "event_id": ev["event_id"],
            "chapter": 3,
            "event_type": "mainline",
            "dialog_entry": ev["dialog_entry"],
            "mutex_group": ev.get("mutex_group", ""),
            "route_tags": ev.get("route_tags", []),
            "status": "active",
        }
        if ev["event_id"] not in have_e:
            reg["events"].append(entry)
        else:
            for row in reg["events"]:
                if row["event_id"] == ev["event_id"]:
                    row.update(entry)
    save("registry/events.json", reg)

    pack = load("pack.json")
    pack["content_version"] = "0.8.0-p7"
    save("pack.json", pack)
    print("dialogs", len(DIALOGS), "events", len(EVENTS), "cal", len(CAL))


if __name__ == "__main__":
    main()
