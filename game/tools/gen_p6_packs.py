# -*- coding: utf-8 -*-
"""P6: thicken E010–E013 discovery arc + insert into calendar before E019."""
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
        "event_id": "E010",
        "loc_key": "event.e010.name",
        "dialog_entry": "dialog_e010_start",
        "mutex_group": "chapter2.night_cargo",
        "route_tags": [],
        "require": [
            {"key": "stat_intel", "op": ">=", "value": 10},
            {"clue": "clue_suspicious_manifest", "owned": True},
            {"flag": "flag_day3_ignored", "value": False},
        ],
        "effects": [],
        "effects_when": "dialog",
    },
    {
        "event_id": "E010b",
        "loc_key": "event.e010b.name",
        "dialog_entry": "dialog_e010b_start",
        "mutex_group": "chapter2.night_cargo",
        "route_tags": [],
        "require": [
            {"flag": "flag_e010_delayed", "value": True},
            {"key": "stat_intel", "op": ">=", "value": 10},
            {"clue": "clue_suspicious_manifest", "owned": True},
        ],
        "effects": [],
        "effects_when": "dialog",
    },
    {
        "event_id": "E011",
        "loc_key": "event.e011.name",
        "dialog_entry": "dialog_e011_start",
        "mutex_group": "",
        "route_tags": [],  # 发现弧对全线开放；路线加成靠效果
        "require": [{"flag": "flag_know_bradley_scouting", "value": True}],
        "effects": [],
        "effects_when": "dialog",
    },
    {
        "event_id": "E012",
        "loc_key": "event.e012.name",
        "dialog_entry": "dialog_e012_start",
        "mutex_group": "",
        "route_tags": [],
        "require": [
            {"flag": "flag_endure_preview", "value": True},
            {
                "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"},
                "key": "score",
                "op": ">=",
                "value": 40,
            },
        ],
        "effects": [],
        "effects_when": "dialog",
    },
    {
        "event_id": "E013",
        "loc_key": "event.e013.name",
        "dialog_entry": "dialog_e013_start",
        "mutex_group": "",
        "route_tags": [],
        "require": [
            {"key": "stat_intel", "op": ">=", "value": 25},
            {"clue": "clue_light_crate", "owned": True},
        ],
        "effects": [],
        "effects_when": "dialog",
    },
]


DIALOGS = [
    # —— E010 ——
    {"dialog_id": "dialog_e010_start", "event_id": "E010", "speaker": "narrator", "loc_key": "dialog.e010.start", "next": "dialog_e010_notice"},
    {"dialog_id": "dialog_e010_notice", "speaker": "narrator", "loc_key": "dialog.e010.notice", "next": "dialog_e010_doubt"},
    {"dialog_id": "dialog_e010_doubt", "speaker": "narrator", "loc_key": "dialog.e010.doubt", "next": "dialog_e010_choice"},
    {
        "dialog_id": "dialog_e010_choice",
        "event_id": "E010",
        "speaker": "narrator",
        "loc_key": "dialog.e010.choice_prompt",
        "choices": [
            {
                "id": "A",
                "loc_key": "dialog.e010.choice.a",
                "effects": [
                    {"op": "add", "key": "stat_intel", "value": 10},
                    {"op": "add", "key": "stat_suspicion", "value": 5},
                    {"op": "unlock_clue", "id": "clue_light_crate"},
                ],
                "next": "dialog_e010_outro_a",
            },
            {
                "id": "B",
                "loc_key": "dialog.e010.choice.b",
                "check": {
                    "require": {"key": "stat_intel", "op": ">=", "value": 15},
                    "on_pass": {
                        "effects": [
                            {"op": "add", "key": "stat_intel", "value": 15},
                            {"op": "add", "key": "stat_suspicion", "value": 15},
                            {"op": "unlock_clue", "id": "clue_light_crate", "quality": "partial"},
                        ],
                        "next": "dialog_e010_outro_b_ok",
                    },
                    "on_fail": {
                        "effects": [
                            {"op": "add", "key": "stat_suspicion", "value": 25},
                            {"op": "add", "key": "stat_trust_firm", "value": -15},
                            {
                                "op": "add",
                                "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"},
                                "key": "score",
                                "value": -10,
                            },
                        ],
                        "next": "dialog_e010_outro_b_fail",
                    },
                },
            },
            {
                "id": "C",
                "loc_key": "dialog.e010.choice.c",
                "effects": [
                    {"op": "add", "key": "stat_intel", "value": 3},
                    {"op": "set_flag", "key": "flag_e010_delayed", "value": True},
                ],
                "next": "dialog_e010_outro_c",
            },
        ],
    },
    {"dialog_id": "dialog_e010_outro_a", "speaker": "narrator", "loc_key": "dialog.e010.outro.a", "next": ""},
    {"dialog_id": "dialog_e010_outro_b_ok", "speaker": "narrator", "loc_key": "dialog.e010.outro.b_ok", "next": ""},
    {"dialog_id": "dialog_e010_outro_b_fail", "speaker": "narrator", "loc_key": "dialog.e010.outro.b_fail", "next": ""},
    {"dialog_id": "dialog_e010_outro_c", "speaker": "narrator", "loc_key": "dialog.e010.outro.c", "next": ""},
    # —— E010b ——
    {"dialog_id": "dialog_e010b_start", "event_id": "E010b", "speaker": "narrator", "loc_key": "dialog.e010b.start", "next": "dialog_e010b_choice"},
    {
        "dialog_id": "dialog_e010b_choice",
        "event_id": "E010b",
        "speaker": "narrator",
        "loc_key": "dialog.e010b.choice_prompt",
        "choices": [
            {
                "id": "A",
                "loc_key": "dialog.e010b.choice.a",
                "effects": [
                    {"op": "add", "key": "stat_intel", "value": 10},
                    {"op": "add", "key": "stat_suspicion", "value": 5},
                    {"op": "unlock_clue", "id": "clue_light_crate"},
                    {"op": "set_flag", "key": "flag_e010_delayed", "value": False},
                ],
                "next": "dialog_e010b_outro_a",
            },
            {
                "id": "B",
                "loc_key": "dialog.e010b.choice.b",
                "check": {
                    "require": {"key": "stat_intel", "op": ">=", "value": 15},
                    "on_pass": {
                        "effects": [
                            {"op": "add", "key": "stat_intel", "value": 15},
                            {"op": "add", "key": "stat_suspicion", "value": 15},
                            {"op": "unlock_clue", "id": "clue_light_crate", "quality": "partial"},
                            {"op": "set_flag", "key": "flag_e010_delayed", "value": False},
                        ],
                        "next": "dialog_e010b_outro_b_ok",
                    },
                    "on_fail": {
                        "effects": [
                            {"op": "add", "key": "stat_suspicion", "value": 25},
                            {"op": "add", "key": "stat_trust_firm", "value": -15},
                            {
                                "op": "add",
                                "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"},
                                "key": "score",
                                "value": -10,
                            },
                            {"op": "set_flag", "key": "flag_e010_delayed", "value": False},
                        ],
                        "next": "dialog_e010b_outro_b_fail",
                    },
                },
            },
        ],
    },
    {"dialog_id": "dialog_e010b_outro_a", "speaker": "narrator", "loc_key": "dialog.e010b.outro.a", "next": ""},
    {"dialog_id": "dialog_e010b_outro_b_ok", "speaker": "narrator", "loc_key": "dialog.e010b.outro.b_ok", "next": ""},
    {"dialog_id": "dialog_e010b_outro_b_fail", "speaker": "narrator", "loc_key": "dialog.e010b.outro.b_fail", "next": ""},
    # —— E011 ——
    {"dialog_id": "dialog_e011_start", "event_id": "E011", "speaker": "narrator", "loc_key": "dialog.e011.start", "next": "dialog_e011_bradley"},
    {"dialog_id": "dialog_e011_bradley", "speaker": "char_bradley", "loc_key": "dialog.e011.bradley", "next": "dialog_e011_qian"},
    {"dialog_id": "dialog_e011_qian", "speaker": "char_qian_demao", "loc_key": "dialog.e011.qian", "next": "dialog_e011_bradley_2"},
    {"dialog_id": "dialog_e011_bradley_2", "speaker": "char_bradley", "loc_key": "dialog.e011.bradley_2", "next": "dialog_e011_spy"},
    {"dialog_id": "dialog_e011_spy", "speaker": "narrator", "loc_key": "dialog.e011.spy", "next": "dialog_e011_choice"},
    {
        "dialog_id": "dialog_e011_choice",
        "event_id": "E011",
        "speaker": "narrator",
        "loc_key": "dialog.e011.choice_prompt",
        "choices": [
            {
                "id": "A",
                "loc_key": "dialog.e011.choice.a",
                "require": [{"key": "stat_intel", "op": ">=", "value": 20}],
                "effects": [
                    {"op": "add", "key": "stat_intel", "value": 5},
                    {"op": "add", "meter": "impression_bradley", "value": 15},
                    {
                        "op": "add",
                        "edge": {"from": "char_bradley", "to": "char_lin_ruisheng"},
                        "key": "score",
                        "value": 12,
                    },
                    {"op": "add", "key": "stat_trust_firm", "value": -5},
                    {
                        "op": "add",
                        "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"},
                        "key": "score",
                        "value": -5,
                    },
                    {
                        "op": "add",
                        "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"},
                        "key": "suspicion",
                        "value": 1,
                    },
                ],
                "next": "dialog_e011_outro_a",
            },
            {
                "id": "B",
                "loc_key": "dialog.e011.choice.b",
                "effects": [
                    {"op": "add", "key": "stat_intel", "value": 8},
                    {"op": "set_flag", "key": "flag_saw_bradley_spy", "value": True},
                    {"op": "grant_item", "id": "item_bradley_spy_note"},
                ],
                "next": "dialog_e011_outro_b",
            },
            {
                "id": "C",
                "loc_key": "dialog.e011.choice.c",
                "effects": [
                    {"op": "add", "key": "stat_trust_firm", "value": 10},
                    {
                        "op": "add",
                        "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"},
                        "key": "score",
                        "value": 8,
                    },
                    {
                        "op": "add",
                        "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"},
                        "key": "suspicion",
                        "value": -1,
                    },
                    {"op": "add", "meter": "impression_bradley", "value": -5},
                    {
                        "op": "add",
                        "edge": {"from": "char_bradley", "to": "char_lin_ruisheng"},
                        "key": "score",
                        "value": -5,
                    },
                ],
                "next": "dialog_e011_outro_c",
            },
        ],
    },
    {"dialog_id": "dialog_e011_outro_a", "speaker": "narrator", "loc_key": "dialog.e011.outro.a", "next": ""},
    {"dialog_id": "dialog_e011_outro_b", "speaker": "narrator", "loc_key": "dialog.e011.outro.b", "next": ""},
    {"dialog_id": "dialog_e011_outro_c", "speaker": "narrator", "loc_key": "dialog.e011.outro.c", "next": ""},
    # —— E012 ——
    {"dialog_id": "dialog_e012_start", "event_id": "E012", "speaker": "narrator", "loc_key": "dialog.e012.start", "next": "dialog_e012_liu_line"},
    {"dialog_id": "dialog_e012_liu_line", "speaker": "char_liu_ruyan", "loc_key": "dialog.e012.liu_line", "next": "dialog_e012_choice"},
    {
        "dialog_id": "dialog_e012_choice",
        "event_id": "E012",
        "speaker": "char_lin_ruisheng",
        "loc_key": "dialog.e012.choice_prompt",
        "choices": [
            {
                "id": "A",
                "loc_key": "dialog.e012.choice.a",
                "effects": [
                    {
                        "op": "add",
                        "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"},
                        "key": "score",
                        "value": -5,
                    },
                    {"op": "add", "key": "stat_intel", "value": 15},
                    {
                        "op": "set",
                        "edge": {"from": "char_qian_zian", "to": "char_liu_ruyan"},
                        "key": "leverage",
                        "value": "受礼把柄",
                    },
                    {"op": "set_flag", "key": "flag_liu_spy", "value": True},
                ],
                "next": "dialog_e012_outro_a",
            },
            {
                "id": "B",
                "loc_key": "dialog.e012.choice.b",
                "effects": [
                    {
                        "op": "add",
                        "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"},
                        "key": "score",
                        "value": 10,
                    },
                    {
                        "op": "add",
                        "edge": {"from": "char_qian_zian", "to": "char_lin_ruisheng"},
                        "key": "score",
                        "value": -10,
                    },
                    {
                        "op": "set",
                        "edge": {"from": "char_qian_zian", "to": "char_liu_ruyan"},
                        "key": "leverage",
                        "value": "无",
                    },
                    {"op": "add", "meter": "pursuit", "value": 5},
                    {"op": "set_flag", "key": "flag_liu_channel_closed", "value": True},
                ],
                "next": "dialog_e012_outro_b",
            },
            {
                "id": "C",
                "loc_key": "dialog.e012.choice.c",
                "effects": [
                    {
                        "op": "add",
                        "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"},
                        "key": "score",
                        "value": 5,
                    },
                    {
                        "op": "set",
                        "edge": {"from": "char_qian_zian", "to": "char_liu_ruyan"},
                        "key": "leverage",
                        "value": "半收半拖",
                    },
                    {"op": "set_flag", "key": "flag_liu_channel_half", "value": True},
                ],
                "next": "dialog_e012_outro_c",
            },
        ],
    },
    {"dialog_id": "dialog_e012_outro_a", "speaker": "narrator", "loc_key": "dialog.e012.outro.a", "next": ""},
    {"dialog_id": "dialog_e012_outro_b", "speaker": "narrator", "loc_key": "dialog.e012.outro.b", "next": ""},
    {"dialog_id": "dialog_e012_outro_c", "speaker": "narrator", "loc_key": "dialog.e012.outro.c", "next": ""},
    # —— E013 ——
    {"dialog_id": "dialog_e013_start", "event_id": "E013", "speaker": "narrator", "loc_key": "dialog.e013.start", "next": "dialog_e013_ledger"},
    {"dialog_id": "dialog_e013_ledger", "speaker": "narrator", "loc_key": "dialog.e013.ledger", "next": "dialog_e013_realize"},
    {"dialog_id": "dialog_e013_realize", "speaker": "narrator", "loc_key": "dialog.e013.realize", "next": "dialog_e013_choice"},
    {
        "dialog_id": "dialog_e013_choice",
        "event_id": "E013",
        "speaker": "narrator",
        "loc_key": "dialog.e013.choice_prompt",
        "choices": [
            {
                "id": "A",
                "loc_key": "dialog.e013.choice.a",
                "require": [{"key": "stat_intel", "op": ">=", "value": 30}],
                "effects": [
                    {"op": "add", "key": "stat_intel", "value": 15},
                    {"op": "add", "key": "stat_suspicion", "value": 5},
                    {"op": "unlock_clue", "id": "clue_special_goods"},
                ],
                "next": "dialog_e013_outro_a",
            },
            {
                "id": "B",
                "loc_key": "dialog.e013.choice.b",
                "effects": [
                    {"op": "add", "key": "stat_intel", "value": 20},
                    {"op": "add", "key": "stat_suspicion", "value": 25},
                    {"op": "unlock_clue", "id": "clue_special_goods", "quality": "physical"},
                    {"op": "grant_item", "id": "item_special_ledger_copy"},
                    {"op": "set_flag", "key": "flag_ledger_stolen", "value": True},
                ],
                "next": "dialog_e013_outro_b",
            },
            {
                "id": "C",
                "loc_key": "dialog.e013.choice.c",
                "effects": [
                    {"op": "add", "key": "stat_intel", "value": 10},
                    {"op": "unlock_clue", "id": "clue_special_goods", "quality": "partial"},
                ],
                "next": "dialog_e013_outro_c",
            },
        ],
    },
    {"dialog_id": "dialog_e013_outro_a", "speaker": "narrator", "loc_key": "dialog.e013.outro.a", "next": ""},
    {"dialog_id": "dialog_e013_outro_b", "speaker": "narrator", "loc_key": "dialog.e013.outro.b", "next": ""},
    {"dialog_id": "dialog_e013_outro_c", "speaker": "narrator", "loc_key": "dialog.e013.outro.c", "next": ""},
]


LOC = {
    "dialog.e010.start": "林瑞生因加班留到深夜，经过后院库房时，听到搬运声。几个不认识的苦力正从一辆遮了篷布的马车上卸箱子。箱子外标着「南洋木器」，和 Day 3 那批货单上的字，一模一样。",
    "dialog.e010.notice": "箱子搬起来轻飘飘的。苦力们不走正门，钻后门暗道。更怪的是——钱德茂亲自站在暗道口，神色紧张。你从没见他半夜盯过一车木头。",
    "dialog.e010.doubt": "正经木材生意，需要东家亲自守夜吗？",
    "dialog.e010.choice_prompt": "（你怎么做？）",
    "dialog.e010.choice.a": "躲在暗处观察，记下细节",
    "dialog.e010.choice.b": "靠近偷看箱内货物",
    "dialog.e010.choice.c": "离开，不打草惊蛇",
    "dialog.e010.outro.a": "深夜卸货、暗道入库、东家亲自盯场——你把这些记成「轻箱之谜」。箱子里究竟是什么，还差临门一脚。",
    "dialog.e010.outro.b_ok": "撬开一条缝：油纸里裹着黑色膏状物，甜腻焦味扑鼻。你没敢掀到底，心里却已经发沉——这绝不是木器。",
    "dialog.e010.outro.b_fail": "「不该看的别看。」钱德茂的声音不重，像钉进骨头。你退出暗处，背上全是冷汗。",
    "dialog.e010.outro.c": "你转身离开。脚步很轻，心里却记下：这种车，还会再来。",
    "dialog.e010b.start": "又是深夜。同一条暗道，同一批「南洋木器」。你上次走开了——这一次，机会未必再给。",
    "dialog.e010b.choice_prompt": "（不能再装看不见了。）",
    "dialog.e010b.choice.a": "躲在暗处，把细节记全",
    "dialog.e010b.choice.b": "靠近偷看箱内",
    "dialog.e010b.outro.a": "「轻箱之谜」终于落了实处。暗道、东家、轻箱——账房里若还有一本账，你就能把线接上。",
    "dialog.e010b.outro.b_ok": "又是那股甜腻焦味。你退回阴影里，手指还在抖。",
    "dialog.e010b.outro.b_fail": "这一回被发现，东家的警告更冷：「再让我看见你半夜转，就不用来了。」",
    "dialog.e011.start": "白瑞德再次到访钱记商行。这次他带了一个随从，拿着一本册子，仔细记录商行的进出货情况。他提出要看看钱记的仓储能力和物流渠道——语气客气，但要求具体。",
    "dialog.e011.bradley": "钱东家，上次聊得投机。我们洋行做事讲究实在——若要长期合作，得看看贵行的仓储条件、运输路线，也好放心。",
    "dialog.e011.qian": "白先生，这些都是行里的机密……",
    "dialog.e011.bradley_2": "自然。朋友之间，先看后谈，不必勉强。",
    "dialog.e011.spy": "钱德茂犹豫片刻，让账房带白先生去看前仓。林瑞生在旁倒水时注意到——白瑞德的随从趁机在抄写门口的货单挂牌。",
    "dialog.e011.choice_prompt": "（你怎么做？）",
    "dialog.e011.choice.a": "借故接近白瑞德，展示对物流渠道的熟悉",
    "dialog.e011.choice.b": "默默服务，暗中记下随从的举动",
    "dialog.e011.choice.c": "找借口阻止随从抄写货单",
    "dialog.e011.outro.a": "白瑞德对你的渠道见识点了点头。钱东家的眼神却冷了下来。",
    "dialog.e011.outro.b": "你把随从抄挂牌的细节记在心里。洋人在暗中摸钱记的物流——这条，日后用得上。",
    "dialog.e011.outro.c": "「瑞生办事稳。」钱德茂难得夸一句。白先生的笑意淡了淡。",
    "dialog.e012.start": "钱子安不断给人送礼。红绸、衣料、首饰——退回去，第二天又送到厂门口。今夜如烟来找你，又慌又愧，袖口还攥着一块新布的边。那不是布料，是价码；收一回，往后就都要拿钱说话了。",
    "dialog.e012.liu_line": "瑞生，他又送了衣料来。我退回去，他的人又送来。我……我不知道怎么办。",
    "dialog.e012.choice_prompt": "（沉默片刻。灯芯噼啪一声。）",
    "dialog.e012.choice.a": "教她收下礼物，暗中替你打听消息",
    "dialog.e012.choice.b": "让她坚决拒绝，一件都不留",
    "dialog.e012.choice.c": "让她拖延——不收，也不撕破脸",
    "dialog.e012.outro.a": "如烟点头时手在抖。你把自己的未婚妻推进了仇人的视线里。情报会来。代价也会来。",
    "dialog.e012.outro.b": "如烟松了口气。少爷吃了闭门羹，未必善罢甘休——送礼没买下人，他只会更恼。这条枕边渠道，关上了；可你也替她守住了一层最薄的体面。",
    "dialog.e012.outro.c": "「再拖拖。」如烟应得很轻。渠道半开，钱子安的耐心在耗，你的时间也在耗。",
    "dialog.e013.start": "林瑞生趁夜潜入账房。在钱德茂的书桌暗格里，他找到一本封面无字的账册。",
    "dialog.e013.ledger": "翻开账册，里面记的是「特别货」的进出。每箱「特别货」进价八十两，售价三百两——利润是木材的四十倍。账册上还有一列收货人代号，全是化名，但最后一页写着：「庆大人·三千两·月奉」。",
    "dialog.e013.realize": "林瑞生不是傻子。八十两进、三百两出，利润四十倍——木材做不出这个数。而「庆大人」三个字，让他隐约触到了一条他不该碰的线。",
    "dialog.e013.choice_prompt": "（你怎么做？）",
    "dialog.e013.choice.a": "把密账记在脑子里，原样放回",
    "dialog.e013.choice.b": "偷走密账",
    "dialog.e013.choice.c": "只记最后一页（庆大人那行），放回",
    "dialog.e013.outro.a": "数字进了脑子，账册回到暗格。你手里没有纸，却有了要挟的影子——你开始像账房里的人了。",
    "dialog.e013.outro.b": "账册贴在怀里发烫。明天商行若搜查，你就是第一个被盯上的人。暗线账权的代价，也开始压到你身上。",
    "dialog.e013.outro.c": "你只带走末页那一行。其余的数，留给以后——如果还有以后。你离「经手哪笔先走」还差一步。",
    "item.bradley_spy_note": "洋人暗查记录",
    "item.special_ledger_copy": "特别货密账抄件",
    "clue.special_goods": "特别货",
}


# Day1–7 unchanged; discovery; then shift finale
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
    {"day": 15, "slot": "afternoon", "event_id": "E022", "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_endure"], "require": []},
    {"day": 15, "slot": "afternoon", "event_id": "E022B", "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_defect"], "require": []},
    {"day": 15, "slot": "afternoon", "event_id": "E022C", "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_foreign"], "require": []},
    {"day": 16, "slot": "morning", "event_id": "E018", "mutex_group": "chapter3.finale", "require": []},
]


def main() -> None:
    upsert_rows("def_event.json", "event_id", EVENTS)
    upsert_rows("def_dialog.json", "dialog_id", DIALOGS)

    # drop obsolete stub nodes that are no longer linked
    obsolete = {
        "dialog_e010_outro_b",
        "dialog_e011_outro",
        "dialog_e012_outro",
        "dialog_e013_outro",
    }
    dlg = load("def_dialog.json")
    dlg["rows"] = [r for r in dlg["rows"] if r.get("dialog_id") not in obsolete]
    save("def_dialog.json", dlg)

    save("def_calendar.json", {"rows": CAL})

    l10n = load("l10n/zh_CN.json")
    l10n.setdefault("zh_CN", {}).update(LOC)
    # keep choice keys used by older stubs if referenced
    l10n["zh_CN"]["dialog.e010.choice"] = LOC["dialog.e010.choice_prompt"]
    l10n["zh_CN"]["dialog.e011.choice"] = LOC["dialog.e011.choice_prompt"]
    l10n["zh_CN"]["dialog.e012.choice"] = LOC["dialog.e012.choice_prompt"]
    l10n["zh_CN"]["dialog.e013.choice"] = LOC["dialog.e013.choice_prompt"]
    save("l10n/zh_CN.json", l10n)

    clues = load("def_clue.json")
    have_c = {c["clue_id"] for c in clues["rows"]}
    for cid, loc in [
        ("clue_light_crate", "clue.light_crate"),
        ("clue_special_goods", "clue.special_goods"),
        ("clue_suspicious_manifest", "clue.suspicious_manifest"),
    ]:
        if cid not in have_c:
            clues["rows"].append({"clue_id": cid, "loc_key": loc, "arc": "opium"})
    save("def_clue.json", clues)

    reg = load("registry/events.json")
    for row in reg.get("events", []):
        if row["event_id"] in ("E010", "E010b", "E011", "E012", "E013"):
            row["status"] = "active"
            row["chapter"] = 2
            if row["event_id"] == "E011":
                row["route_tags"] = []
            if row["event_id"] == "E010":
                row["mutex_group"] = "chapter2.night_cargo"
            if row["event_id"] == "E010b":
                row["mutex_group"] = "chapter2.night_cargo"
                row["event_type"] = "mainline_retry"
    save("registry/events.json", reg)

    pack = load("pack.json")
    pack["content_version"] = "0.7.0-p6"
    save("pack.json", pack)
    print("dialogs", len(DIALOGS), "events", len(EVENTS), "cal", len(CAL))


if __name__ == "__main__":
    main()
