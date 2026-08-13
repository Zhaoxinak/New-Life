# -*- coding: utf-8 -*-
"""P26: 各职级劲敌人格落地——建言席 + 旁听 + 闲话压迫。"""
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
    save(table_file, data)


def merge_l10n(entries: dict) -> None:
    data = load("l10n/zh_CN.json")
    data.setdefault("zh_CN", {}).update(entries)
    save("l10n/zh_CN.json", data)


def d(dialog_id, speaker, loc_key, next_id="", **extra):
    row = {
        "dialog_id": dialog_id,
        "speaker": speaker,
        "loc_key": loc_key,
        "next": next_id or "",
        "tags": extra.pop("tags", ["meeting", "council"]),
    }
    row.update(extra)
    stage = row.get("stage") or {"segment": "council"}
    if "segment" not in stage:
        stage["segment"] = "council"
    row["stage"] = stage
    tags = list(row.get("tags") or [])
    for t in ("seg_council", "council", "meeting"):
        if t not in tags and "chatter" not in tags:
            tags.append(t)
    row["tags"] = tags
    return row


RIVAL_BRANCHES = [
    {"require": [{"council_has": "char_apprentice_sun_liu"}, {"cycle_mod": 2, "equals": 0}], "id": "dialog_council_sun_flatter"},
    {"require": [{"council_has": "char_apprentice_sun_liu"}], "id": "dialog_council_sun_step"},
    {"require": [{"council_has": "char_apprentice_xiao_chen"}, {"cycle_mod": 2, "equals": 1}], "id": "dialog_council_chen_pass"},
    {"require": [{"council_has": "char_apprentice_xiao_chen"}], "id": "dialog_council_chen_steady"},
    {"require": [{"council_has": "char_li_waichang"}, {"cycle_mod": 2, "equals": 1}], "id": "dialog_council_li_pass"},
    {"require": [{"council_has": "char_li_waichang"}], "id": "dialog_council_li_work"},
    {"require": [{"council_has": "char_zhao_waichang"}, {"cycle_mod": 2, "equals": 1}], "id": "dialog_council_zhao_sneer"},
    {"require": [{"council_has": "char_zhao_waichang"}], "id": "dialog_council_zhao_step"},
]


def main() -> None:
    rows = [
        # —— 小陈：闷头稳明面 ——
        d(
            "dialog_council_chen_steady",
            "char_apprentice_xiao_chen",
            "council.chen.steady",
            "dialog_council_after_rival",
            effects=[
                {"op": "set_meeting_segment", "value": "council"},
                {
                    "op": "record_council_speech",
                    "char": "char_apprentice_xiao_chen",
                    "spoke": True,
                    "topic_key": "council.chen.steady",
                    "stance": "bright_steady",
                    "mode": "speak",
                },
                {"op": "add_policy_draft", "key": "bright_steady", "value": 2},
                {"op": "add_ladder_score", "char": "char_apprentice_xiao_chen", "value": 5},
            ],
        ),
        d(
            "dialog_council_chen_pass",
            "char_apprentice_xiao_chen",
            "council.chen.pass",
            "dialog_council_after_rival",
            effects=[
                {"op": "set_meeting_segment", "value": "council"},
                {
                    "op": "record_council_speech",
                    "char": "char_apprentice_xiao_chen",
                    "spoke": True,
                    "topic_key": "council.chen.pass",
                    "stance": "bright_steady",
                    "mode": "speak",
                },
                {"op": "add_policy_draft", "key": "bright_steady", "value": 1},
                {"op": "add_ladder_score", "char": "char_apprentice_xiao_chen", "value": 3},
            ],
        ),
        # —— 李外场：实干报差事 ——
        d(
            "dialog_council_li_work",
            "char_li_waichang",
            "council.li.work",
            "dialog_council_after_rival",
            effects=[
                {"op": "set_meeting_segment", "value": "council"},
                {
                    "op": "record_council_speech",
                    "char": "char_li_waichang",
                    "spoke": True,
                    "topic_key": "council.li.work",
                    "stance": "bright_steady",
                    "mode": "speak",
                },
                {"op": "add_policy_draft", "key": "bright_steady", "value": 2},
                {"op": "add_ladder_score", "char": "char_li_waichang", "value": 5},
                {"op": "add_ladder_score", "char": "char_lin_ruisheng", "value": -2},
            ],
        ),
        d(
            "dialog_council_li_pass",
            "char_li_waichang",
            "council.li.pass",
            "dialog_council_after_rival",
            effects=[
                {"op": "set_meeting_segment", "value": "council"},
                {
                    "op": "record_council_speech",
                    "char": "char_li_waichang",
                    "spoke": True,
                    "topic_key": "council.li.pass",
                    "stance": "watch_jufeng",
                    "mode": "speak",
                },
                {"op": "add_policy_draft", "key": "watch_jufeng", "value": 1},
                {"op": "add_ladder_score", "char": "char_li_waichang", "value": 4},
            ],
        ),
        # —— 旁听：按入队劲敌分支 ——
        d(
            "dialog_m000_council_listen_chen",
            "narrator",
            "dialog.m000.council_listen_chen",
            "dialog_meeting_policy_resolve",
            tags=["meeting", "council", "m000", "keyword_highlight"],
            stage={
                "segment": "council",
                "keywords": ["小陈", "货单", "满师", "明面"],
                "camera": "listen",
            },
            effects=[
                {
                    "op": "record_council_speech",
                    "char": "char_apprentice_xiao_chen",
                    "spoke": True,
                    "stance": "bright_steady",
                    "mode": "speak",
                },
                {"op": "add_policy_draft", "key": "bright_steady", "value": 1},
                {"op": "add_ladder_score", "char": "char_apprentice_xiao_chen", "value": 2},
            ],
        ),
        d(
            "dialog_m000_council_listen_li",
            "narrator",
            "dialog.m000.council_listen_li",
            "dialog_meeting_policy_resolve",
            tags=["meeting", "council", "m000", "keyword_highlight"],
            stage={
                "segment": "council",
                "keywords": ["李外场", "差事", "街面", "回"],
                "camera": "listen",
            },
            effects=[
                {
                    "op": "record_council_speech",
                    "char": "char_li_waichang",
                    "spoke": True,
                    "stance": "bright_steady",
                    "mode": "speak",
                },
                {"op": "add_policy_draft", "key": "bright_steady", "value": 1},
                {"op": "add_ladder_score", "char": "char_li_waichang", "value": 2},
            ],
        ),
        d(
            "dialog_m000_council_listen_zhao",
            "narrator",
            "dialog.m000.council_listen_zhao",
            "dialog_meeting_policy_resolve",
            tags=["meeting", "council", "m000", "keyword_highlight"],
            stage={
                "segment": "council",
                "keywords": ["赵外场", "客", "嘴皮子", "东家"],
                "camera": "listen",
            },
            effects=[
                {
                    "op": "record_council_speech",
                    "char": "char_zhao_waichang",
                    "spoke": True,
                    "stance": "bright_steady",
                    "mode": "speak",
                },
                {"op": "add_policy_draft", "key": "bright_steady", "value": 1},
                {"op": "add_ladder_score", "char": "char_zhao_waichang", "value": 2},
            ],
        ),
        # —— 闲话：按主劲敌分条（chatter require rival_is）——
        {
            "dialog_id": "dialog_chat_wang_pangzi_rival_nudge",
            "speaker": "char_wang_pangzi",
            "loc_key": "dialog.chat.wang_pangzi.rival_sun",
            "tags": ["chatter"],
            "effects": [],
            "choices": [{"id": "A", "loc_key": "dialog.chat.opt.bye", "effects": [], "next": ""}],
        },
        {
            "dialog_id": "dialog_chat_wang_pangzi_rival_chen",
            "speaker": "char_wang_pangzi",
            "loc_key": "dialog.chat.wang_pangzi.rival_chen",
            "tags": ["chatter"],
            "effects": [],
            "choices": [{"id": "A", "loc_key": "dialog.chat.opt.bye", "effects": [], "next": ""}],
        },
        {
            "dialog_id": "dialog_chat_wang_pangzi_rival_li",
            "speaker": "char_wang_pangzi",
            "loc_key": "dialog.chat.wang_pangzi.rival_li",
            "tags": ["chatter"],
            "effects": [],
            "choices": [{"id": "A", "loc_key": "dialog.chat.opt.bye", "effects": [], "next": ""}],
        },
        {
            "dialog_id": "dialog_chat_wang_pangzi_rival_zhao",
            "speaker": "char_wang_pangzi",
            "loc_key": "dialog.chat.wang_pangzi.rival_zhao",
            "tags": ["chatter"],
            "effects": [],
            "choices": [{"id": "A", "loc_key": "dialog.chat.opt.bye", "effects": [], "next": ""}],
        },
        {
            "dialog_id": "dialog_chat_wang_pangzi_rival_zian",
            "speaker": "char_wang_pangzi",
            "loc_key": "dialog.chat.wang_pangzi.rival_zian",
            "tags": ["chatter"],
            "effects": [],
            "choices": [{"id": "A", "loc_key": "dialog.chat.opt.bye", "effects": [], "next": ""}],
        },
    ]

    upsert_rows("def_dialog.json", "dialog_id", rows)

    # chatter 分条
    chatter = load("def_chatter.json")
    rows_c = chatter["rows"]
    # 去掉旧单条，写入分阶段
    rows_c = [r for r in rows_c if str(r.get("chatter_id", "")) != "chatter_wang_pangzi_rival_nudge"]
    rows_c.extend(
        [
            {
                "chatter_id": "chatter_wang_pangzi_rival_sun",
                "char_id": "char_wang_pangzi",
                "dialog_id": "dialog_chat_wang_pangzi_rival_nudge",
                "priority": 54,
                "once": False,
                "once_per_slot": True,
                "require": [{"meeting_days_leq": 2}, {"rival_is": "char_apprentice_sun_liu"}],
            },
            {
                "chatter_id": "chatter_wang_pangzi_rival_chen",
                "char_id": "char_wang_pangzi",
                "dialog_id": "dialog_chat_wang_pangzi_rival_chen",
                "priority": 54,
                "once": False,
                "once_per_slot": True,
                "require": [{"meeting_days_leq": 2}, {"rival_is": "char_apprentice_xiao_chen"}],
            },
            {
                "chatter_id": "chatter_wang_pangzi_rival_li",
                "char_id": "char_wang_pangzi",
                "dialog_id": "dialog_chat_wang_pangzi_rival_li",
                "priority": 54,
                "once": False,
                "once_per_slot": True,
                "require": [{"meeting_days_leq": 2}, {"rival_is": "char_li_waichang"}],
            },
            {
                "chatter_id": "chatter_wang_pangzi_rival_zhao",
                "char_id": "char_wang_pangzi",
                "dialog_id": "dialog_chat_wang_pangzi_rival_zhao",
                "priority": 54,
                "once": False,
                "once_per_slot": True,
                "require": [{"meeting_days_leq": 2}, {"rival_is": "char_zhao_waichang"}],
            },
            {
                "chatter_id": "chatter_wang_pangzi_rival_zian",
                "char_id": "char_wang_pangzi",
                "dialog_id": "dialog_chat_wang_pangzi_rival_zian",
                "priority": 54,
                "once": False,
                "once_per_slot": True,
                "require": [{"meeting_days_leq": 2}, {"rival_is": "char_qian_zian"}],
            },
        ]
    )
    chatter["rows"] = rows_c
    save("def_chatter.json", chatter)

    data = load("def_dialog.json")
    for row in data["rows"]:
        did = str(row.get("dialog_id", ""))
        if did in ("dialog_council_after_wang", "dialog_council_after_zian"):
            # 王/子安之后：先子安变体（仅 after_wang），再各劲敌
            nxt = []
            if did == "dialog_council_after_wang":
                nxt.extend(
                    [
                        {"require": [{"council_has": "char_qian_zian"}, {"cycle_mod": 2, "equals": 1}], "id": "dialog_council_zian_boast"},
                        {"require": [{"council_has": "char_qian_zian"}], "id": "dialog_council_zian_show"},
                    ]
                )
            nxt.extend(RIVAL_BRANCHES)
            nxt.extend(
                [
                    {"require": [{"council_has": "char_lin_ruisheng"}], "id": "dialog_meeting_council_player_pick"},
                    {"default": "dialog_meeting_policy_resolve"},
                ]
            )
            row["next_by_condition"] = nxt
            row.pop("next", None)
        elif did == "dialog_m000_council_listen":
            row["next"] = ""
            row["next_by_condition"] = [
                {"require": [{"council_has": "char_apprentice_sun_liu"}], "id": "dialog_m000_council_listen_rival"},
                {"require": [{"council_has": "char_apprentice_xiao_chen"}], "id": "dialog_m000_council_listen_chen"},
                {"require": [{"council_has": "char_li_waichang"}], "id": "dialog_m000_council_listen_li"},
                {"require": [{"council_has": "char_zhao_waichang"}], "id": "dialog_m000_council_listen_zhao"},
                {"require": [{"council_has": "char_qian_zian"}], "id": "dialog_m000_council_listen_zian"},
                {"default": "dialog_m000_council_listen_wang"},
            ]
        elif did == "dialog_m000_council_listen_rival":
            row["loc_key"] = "dialog.m000.council_listen_rival"
            row["stage"] = {
                "segment": "council",
                "keywords": ["孙六", "跑街", "满师", "东家", "货单"],
                "camera": "listen",
            }

    save("def_dialog.json", data)

    # stage rival_pool
    stage = load("def_meeting_stage.json")
    stage["rival_pool"] = [
        "char_apprentice_xiao_chen",
        "char_apprentice_sun_liu",
        "char_li_waichang",
        "char_zhao_waichang",
        "char_qian_zian",
    ]
    save("def_meeting_stage.json", stage)

    merge_l10n(
        {
            "council.chen.steady": "货单我对过三遍。明面稳着，比嘴上热闹强。",
            "council.chen.pass": "……东家说得是。差事我按日子回，不添乱。",
            "council.li.work": "街面那两趟，货到、人到、话到。差事回齐了——有人还欠着的，自己心里清楚。",
            "council.li.pass": "聚丰压价归压价，该跑的路我跑完了。外场位子，靠回事儿，不靠嗓门。",
            "council.after.rival": "那人话音落地，堂上目光轻轻一偏——像在称你与他谁更沉。",
            "dialog.m000.council_listen_rival": "门帘外，孙六字字往你身上踩，却句句在拍东家：会做人的，才该先顶上。",
            "dialog.m000.council_listen_chen": "帘后传来小陈闷闷的嗓音：货单、日子、回齐——他不踩你，却把「稳」钉在明面上。",
            "dialog.m000.council_listen_li": "你听见李外场报差事：街面、到货、客话。句句实，像在提醒谁还欠着。",
            "dialog.m000.council_listen_zhao": "赵外场笑着说客面、嘴皮子、东家眼力——笑声里有一根刺，专往你身上扎。",
            "dialog.chat.wang_pangzi.rival_nudge": "朝账快到了。你那劲敌，这几天又往前蹿。",
            "dialog.chat.wang_pangzi.rival_sun": "孙六这几天又往前蹿了。你要是还磨，下次朝账他笑得出来。",
            "dialog.chat.wang_pangzi.rival_chen": "小陈不吭声，货单却回得干净。闷头那种，最难压。",
            "dialog.chat.wang_pangzi.rival_li": "李外场差事都回了。你要是还欠着，堂上他一眼就能把你比下去。",
            "dialog.chat.wang_pangzi.rival_zhao": "赵外场围着东家转呢。信任一高，他分涨得比你腿快。",
            "dialog.chat.wang_pangzi.rival_zian": "少爷那分数，不全靠干活。你跟他抢跑街，别天真。",
            "ui.duty_rival_nudge": "⚠ 距朝账还剩 %d 日——%s 还在往前蹿。",
            "ui.rival_style.chen": "闷头攒分，货单从不拖",
            "ui.rival_style.sun": "会做人，朝账周最爱蹿",
            "ui.rival_style.li": "差事回得稳，专吃你偷懒",
            "ui.rival_style.zhao": "媚上嘴快，东家信他时猛涨",
            "ui.rival_style.zian": "少爷加成压你一头",
            "char.xiao_chen.blurb": "勤快老实，闷头攒分——学徒池里最难压的劲敌。",
            "char.sun_liu.blurb": "会拍马，朝账周暴涨；你松懈时最爱踩一脚。",
            "char.li_waichang.blurb": "实干外场，差事回齐才说话；专吃偷懒的人。",
            "char.zhao_waichang.blurb": "媚上嘴快；东家信任一高，序位就往上窜。",
        }
    )

    print("P26 rival stage content done")


if __name__ == "__main__":
    main()
