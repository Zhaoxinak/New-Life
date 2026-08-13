# -*- coding: utf-8 -*-
"""P19: 例行朝账建言池扩写 + 仇人踩线戏。"""
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
            # merge tags/stage lightly on replace
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
    # stage cue
    stage = row.get("stage") or {"segment": "council"}
    if "segment" not in stage:
        stage["segment"] = "council"
    row["stage"] = stage
    tags = list(row.get("tags") or [])
    if "seg_council" not in tags:
        tags.append("seg_council")
    if "council" not in tags:
        tags.append("council")
    if "meeting" not in tags:
        tags.append("meeting")
    row["tags"] = tags
    return row


def main() -> None:
    # —— 新台词节点 ——
    rows = [
        # 周管事变体
        d(
            "dialog_council_zhou_manifest",
            "char_zhou_guanshi",
            "council.zhou.manifest",
            "dialog_council_after_zhou",
            effects=[
                {"op": "set_meeting_segment", "value": "council"},
                {"op": "record_council_speech", "char": "char_zhou_guanshi", "spoke": True, "topic_key": "council.zhou.manifest", "stance": "bright_steady"},
                {"op": "add_policy_draft", "key": "bright_steady", "value": 2},
            ],
        ),
        d(
            "dialog_council_zhou_yard",
            "char_zhou_guanshi",
            "council.zhou.yard",
            "dialog_council_after_zhou",
            effects=[
                {"op": "set_meeting_segment", "value": "council"},
                {"op": "record_council_speech", "char": "char_zhou_guanshi", "spoke": True, "topic_key": "council.zhou.yard", "stance": "look_away"},
                {"op": "add_policy_draft", "key": "look_away", "value": 1},
            ],
        ),
        # 王胖子变体
        d(
            "dialog_council_wang_street",
            "char_wang_pangzi",
            "council.wang.street",
            "dialog_council_after_wang",
            effects=[
                {"op": "record_council_speech", "char": "char_wang_pangzi", "spoke": True, "stance": "watch_jufeng"},
                {"op": "add_policy_draft", "key": "watch_jufeng", "value": 1},
            ],
        ),
        d(
            "dialog_council_wang_hands",
            "char_wang_pangzi",
            "council.wang.hands",
            "dialog_council_after_wang",
            effects=[
                {"op": "record_council_speech", "char": "char_wang_pangzi", "spoke": True, "stance": "bright_steady"},
                {"op": "add_policy_draft", "key": "bright_steady", "value": 1},
            ],
        ),
        # 子安变体
        d(
            "dialog_council_zian_boast",
            "char_qian_zian",
            "council.zian.boast",
            "dialog_council_after_zian",
            effects=[
                {"op": "record_council_speech", "char": "char_qian_zian", "spoke": True, "stance": "son_first"},
                {"op": "add_policy_draft", "key": "son_first", "value": 2},
                {"op": "add", "meter": "father_son", "value": -3},
            ],
        ),
        # 孙六踩线
        d(
            "dialog_council_sun_step",
            "char_apprentice_sun_liu",
            "council.sun.step",
            "dialog_council_after_rival",
            effects=[
                {"op": "record_council_speech", "char": "char_apprentice_sun_liu", "spoke": True, "stance": "bright_steady", "mode": "speak"},
                {"op": "add_policy_draft", "key": "bright_steady", "value": 1},
                {"op": "add_ladder_score", "char": "char_apprentice_sun_liu", "value": 4},
                {"op": "add_ladder_score", "char": "char_lin_ruisheng", "value": -3},
            ],
        ),
        d(
            "dialog_council_sun_flatter",
            "char_apprentice_sun_liu",
            "council.sun.flatter",
            "dialog_council_after_rival",
            effects=[
                {"op": "record_council_speech", "char": "char_apprentice_sun_liu", "spoke": True, "stance": "son_first", "mode": "speak"},
                {"op": "add_policy_draft", "key": "son_first", "value": 1},
                {"op": "add_ladder_score", "char": "char_apprentice_sun_liu", "value": 5},
                {"op": "add_ladder_score", "char": "char_lin_ruisheng", "value": -2},
            ],
        ),
        # 赵外场踩线
        d(
            "dialog_council_zhao_step",
            "char_zhao_waichang",
            "council.zhao.step",
            "dialog_council_after_rival",
            effects=[
                {"op": "record_council_speech", "char": "char_zhao_waichang", "spoke": True, "stance": "bright_steady", "mode": "speak"},
                {"op": "add_policy_draft", "key": "bright_steady", "value": 1},
                {"op": "add_ladder_score", "char": "char_zhao_waichang", "value": 4},
                {"op": "add_ladder_score", "char": "char_lin_ruisheng", "value": -4},
            ],
        ),
        d(
            "dialog_council_zhao_sneer",
            "char_zhao_waichang",
            "council.zhao.sneer",
            "dialog_council_after_rival",
            effects=[
                {"op": "record_council_speech", "char": "char_zhao_waichang", "spoke": True, "stance": "watch_jufeng", "mode": "speak"},
                {"op": "add_policy_draft", "key": "watch_jufeng", "value": 1},
                {"op": "add_ladder_score", "char": "char_zhao_waichang", "value": 3},
                {"op": "add_ladder_score", "char": "char_lin_ruisheng", "value": -3},
            ],
        ),
        # 路由节点
        {
            "dialog_id": "dialog_council_zhou_pick",
            "speaker": "narrator",
            "loc_key": "council.pick.zhou",
            "tags": ["meeting", "council", "seg_council"],
            "stage": {"segment": "council"},
            "effects": [{"op": "set_meeting_segment", "value": "council"}],
            "next_by_condition": [
                {"require": [{"cycle_mod": 3, "equals": 1}], "id": "dialog_council_zhou_manifest"},
                {"require": [{"cycle_mod": 3, "equals": 2}], "id": "dialog_council_zhou_yard"},
                {"default": "dialog_council_zhou_order"},
            ],
        },
        {
            "dialog_id": "dialog_council_after_zhou",
            "speaker": "narrator",
            "loc_key": "council.after.zhou",
            "tags": ["meeting", "council", "seg_council"],
            "stage": {"segment": "council"},
            "next_by_condition": [
                {"require": [{"cycle_mod": 3, "equals": 1}], "id": "dialog_council_wang_street"},
                {"require": [{"cycle_mod": 3, "equals": 2}], "id": "dialog_council_wang_pass"},
                {"require": [{"cycle_mod": 2, "equals": 0}], "id": "dialog_council_wang_hands"},
                {"default": "dialog_council_wang_front"},
            ],
        },
        {
            "dialog_id": "dialog_council_after_wang",
            "speaker": "narrator",
            "loc_key": "council.after.wang",
            "tags": ["meeting", "council", "seg_council"],
            "stage": {"segment": "council"},
            "next_by_condition": [
                {"require": [{"council_has": "char_qian_zian"}, {"cycle_mod": 2, "equals": 1}], "id": "dialog_council_zian_boast"},
                {"require": [{"council_has": "char_qian_zian"}], "id": "dialog_council_zian_show"},
                {"require": [{"council_has": "char_apprentice_sun_liu"}, {"cycle_mod": 2, "equals": 0}], "id": "dialog_council_sun_flatter"},
                {"require": [{"council_has": "char_apprentice_sun_liu"}], "id": "dialog_council_sun_step"},
                {"require": [{"council_has": "char_zhao_waichang"}, {"cycle_mod": 2, "equals": 1}], "id": "dialog_council_zhao_sneer"},
                {"require": [{"council_has": "char_zhao_waichang"}], "id": "dialog_council_zhao_step"},
                {"require": [{"council_has": "char_lin_ruisheng"}], "id": "dialog_meeting_council_player_pick"},
                {"default": "dialog_meeting_policy_resolve"},
            ],
        },
        {
            "dialog_id": "dialog_council_after_rival",
            "speaker": "narrator",
            "loc_key": "council.after.rival",
            "tags": ["meeting", "council", "seg_council"],
            "stage": {"segment": "council"},
            "next_by_condition": [
                {"require": [{"council_has": "char_lin_ruisheng"}], "id": "dialog_meeting_council_player_pick"},
                {"default": "dialog_meeting_policy_resolve"},
            ],
        },
        {
            "dialog_id": "dialog_council_after_zian",
            "speaker": "narrator",
            "loc_key": "council.after.zian",
            "tags": ["meeting", "council", "seg_council"],
            "stage": {"segment": "council"},
            "next_by_condition": [
                {"require": [{"council_has": "char_apprentice_sun_liu"}, {"cycle_mod": 2, "equals": 0}], "id": "dialog_council_sun_flatter"},
                {"require": [{"council_has": "char_apprentice_sun_liu"}], "id": "dialog_council_sun_step"},
                {"require": [{"council_has": "char_zhao_waichang"}, {"cycle_mod": 2, "equals": 1}], "id": "dialog_council_zhao_sneer"},
                {"require": [{"council_has": "char_zhao_waichang"}], "id": "dialog_council_zhao_step"},
                {"require": [{"council_has": "char_lin_ruisheng"}], "id": "dialog_meeting_council_player_pick"},
                {"default": "dialog_meeting_policy_resolve"},
            ],
        },
        # 旁听碎片扩写
        d(
            "dialog_m000_council_listen_rival",
            "narrator",
            "dialog.m000.council_listen_rival",
            "dialog_meeting_policy_resolve",
            tags=["meeting", "council", "m000", "keyword_highlight"],
            stage={
                "segment": "council",
                "keywords": ["孙六", "跑街", "满师", "东家", "货单"],
                "camera": "listen",
            },
            effects=[
                {"op": "record_council_speech", "char": "char_apprentice_sun_liu", "spoke": True, "stance": "bright_steady", "mode": "speak"},
                {"op": "add_policy_draft", "key": "bright_steady", "value": 1},
            ],
        ),
        d(
            "dialog_m000_council_listen_zian",
            "narrator",
            "dialog.m000.council_listen_zian",
            "dialog_meeting_policy_resolve",
            tags=["meeting", "council", "m000", "keyword_highlight"],
            stage={
                "segment": "council",
                "keywords": ["少爷", "排场", "聚丰"],
                "camera": "listen",
            },
            effects=[
                {"op": "record_council_speech", "char": "char_qian_zian", "spoke": True, "stance": "son_first", "mode": "speak"},
                {"op": "add_policy_draft", "key": "son_first", "value": 2},
            ],
        ),
    ]

    upsert_rows("def_dialog.json", "dialog_id", rows)

    # —— 改写既有链 ——
    data = load("def_dialog.json")
    for row in data["rows"]:
        did = str(row.get("dialog_id", ""))
        if did == "dialog_council_zhou_order":
            row["next"] = "dialog_council_after_zhou"
            # keep effects; ensure segment
            eff = list(row.get("effects") or [])
            if not any(isinstance(e, dict) and e.get("op") == "set_meeting_segment" for e in eff):
                eff.insert(0, {"op": "set_meeting_segment", "value": "council"})
            row["effects"] = eff
        elif did == "dialog_council_zhou_pass":
            row["next"] = "dialog_council_after_zhou"
        elif did == "dialog_council_wang_front":
            row["next"] = "dialog_council_after_wang"
        elif did == "dialog_council_wang_pass":
            row["next"] = "dialog_council_after_wang"
            row["loc_key"] = row.get("loc_key") or "council.wang.pass"
        elif did == "dialog_council_zian_show":
            row["next"] = "dialog_council_after_zian"
        elif did == "dialog_council_zian_pass":
            row["next"] = "dialog_council_after_zian"
        elif did == "dialog_m000_council_gate":
            row["next_by_condition"] = [
                {
                    "require": [
                        {
                            "or": [
                                {"meeting_tier": "report"},
                                {"meeting_tier": "decide"},
                                {"flag": "flag_meeting_report_eligible", "value": True},
                            ]
                        }
                    ],
                    "id": "dialog_council_zhou_pick",
                },
                {"default": "dialog_m000_council_listen"},
            ]
            row.pop("next", None)
        elif did == "dialog_m000_council_listen":
            row["next"] = ""
            row["next_by_condition"] = [
                {"require": [{"council_has": "char_apprentice_sun_liu"}], "id": "dialog_m000_council_listen_rival"},
                {"require": [{"council_has": "char_qian_zian"}], "id": "dialog_m000_council_listen_zian"},
                {"default": "dialog_m000_council_listen_wang"},
            ]
        elif did == "dialog_meeting_council_player_pick":
            # ensure comes after rivals in new flow; keep as is
            pass

    save("def_dialog.json", data)

    merge_l10n(
        {
            "council.zhou.manifest": "货单上有两处墨色新旧不一。先对清楚，再谈别的。",
            "council.zhou.yard": "后院这几日少问。明面稳住，比瞎打听强。",
            "council.wang.street": "街面上聚丰又在压价。客问起来，咱们得有个说法。",
            "council.wang.hands": "人手紧归紧，该出的力还得出。别让客等着干瞪眼。",
            "council.zian.boast": "我跟洋人那边也说得上话——钱记要面子，得我出面才压得住。",
            "council.sun.step": "东家，有的师弟看着勤快，货单上却常出错。不如让会做人的先顶上。",
            "council.sun.flatter": "还是东家眼毒。谁跟得紧、谁只会闷头，朝账上一眼就看得出来。",
            "council.zhao.step": "外场这活，嘴皮子比腿快。有人只会算账，客面前却撑不住场。",
            "council.zhao.sneer": "聚丰那边笑话咱们外场嫩。该让能办事的人多露面，别拖后腿。",
            "council.pick.zhou": "管事先开口。",
            "council.after.zhou": "堂上静了一息。",
            "council.after.wang": "又一轮目光转过去。",
            "council.after.rival": "那人话音落地，有人偷偷看你一眼。",
            "council.after.zian": "少爷说完，茶盏磕了一下。",
            "dialog.m000.council_listen_rival": "门帘外，你听见孙六的声音——字字往你身上踩，却句句在拍东家。",
            "dialog.m000.council_listen_zian": "帘后传来少爷的嗓门：排场、面子、洋人——他比谁都会往自己脸上贴金。",
        }
    )

    # docs snippet update handled separately
    print("P19 council content done")


if __name__ == "__main__":
    main()
