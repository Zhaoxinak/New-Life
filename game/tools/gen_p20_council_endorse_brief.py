# -*- coding: utf-8 -*-
"""P20: decide 附议 + 例行简席压缩建言链。"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "packs" / "anchao"


def load(name: str):
    return json.loads((ROOT / name).read_text(encoding="utf-8"))


def save(name: str, data) -> None:
    (ROOT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("updated", name)


def merge_l10n(entries: dict) -> None:
    data = load("l10n/zh_CN.json")
    data.setdefault("zh_CN", {}).update(entries)
    save("l10n/zh_CN.json", data)


def main() -> None:
    data = load("def_dialog.json")
    by_id = {str(r.get("dialog_id")): r for r in data["rows"]}

    # —— 玩家入口：decide 可附议 ——
    pick = by_id.get("dialog_meeting_council_player_pick")
    if pick:
        pick["choices"] = [
            {
                "id": "council_speak",
                "loc_key": "council.choice.speak",
                "next": "dialog_meeting_council_topic",
            },
            {
                "id": "council_endorse",
                "loc_key": "council.choice.endorse",
                "require": [
                    {"meeting_tier": "decide"},
                    {"council_last_spoke": True},
                ],
                "next": "dialog_meeting_council_endorse",
            },
            {
                "id": "council_silent",
                "loc_key": "council.choice.silent",
                "next": "dialog_meeting_council_player_pass",
            },
        ]

    endorse = {
        "dialog_id": "dialog_meeting_council_endorse",
        "speaker": "char_lin_ruisheng",
        "loc_key": "council.player.endorse",
        "next": "dialog_meeting_council_demao_nod",
        "tags": ["meeting", "council", "seg_council"],
        "stage": {"segment": "council"},
        "effects": [
            {"op": "endorse_last_council"},
        ],
    }

    # —— 简席：周/王只走默认口径，跳过变体抽选 ——
    zhou_pick = by_id.get("dialog_council_zhou_pick")
    if zhou_pick:
        zhou_pick["next_by_condition"] = [
            {"require": [{"council_brief": True}], "id": "dialog_council_zhou_order"},
            {"require": [{"cycle_mod": 3, "equals": 1}], "id": "dialog_council_zhou_manifest"},
            {"require": [{"cycle_mod": 3, "equals": 2}], "id": "dialog_council_zhou_yard"},
            {"default": "dialog_council_zhou_order"},
        ]

    after_zhou = by_id.get("dialog_council_after_zhou")
    if after_zhou:
        after_zhou["next_by_condition"] = [
            {"require": [{"council_brief": True}], "id": "dialog_council_wang_front"},
            {"require": [{"cycle_mod": 3, "equals": 1}], "id": "dialog_council_wang_street"},
            {"require": [{"cycle_mod": 3, "equals": 2}], "id": "dialog_council_wang_pass"},
            {"require": [{"cycle_mod": 2, "equals": 0}], "id": "dialog_council_wang_hands"},
            {"default": "dialog_council_wang_front"},
        ]

    # 简席旁听：听完周+王后直接定调（已有 listen_wang → policy）；若有仇人仍走扩写
    listen = by_id.get("dialog_m000_council_listen")
    if listen:
        listen["next_by_condition"] = [
            {"require": [{"council_has": "char_apprentice_sun_liu"}], "id": "dialog_m000_council_listen_rival"},
            {"require": [{"council_has": "char_qian_zian"}], "id": "dialog_m000_council_listen_zian"},
            {"require": [{"council_brief": True}], "id": "dialog_m000_council_listen_brief"},
            {"default": "dialog_m000_council_listen_wang"},
        ]

    listen_brief = {
        "dialog_id": "dialog_m000_council_listen_brief",
        "speaker": "narrator",
        "loc_key": "dialog.m000.council_listen_brief",
        "next": "dialog_meeting_policy_resolve",
        "tags": ["meeting", "council", "m000", "keyword_highlight", "seg_council"],
        "stage": {
            "segment": "council",
            "camera": "listen",
            "keywords": ["货单", "按章", "东家"],
        },
        "effects": [
            {
                "op": "record_council_speech",
                "char": "char_zhou_guanshi",
                "spoke": True,
                "stance": "bright_steady",
                "mode": "speak",
            },
            {"op": "add_policy_draft", "key": "bright_steady", "value": 2},
            {
                "op": "record_council_speech",
                "char": "char_wang_pangzi",
                "spoke": False,
                "mode": "pass",
            },
            {"op": "set_meeting_segment", "value": "council"},
        ],
    }

    # upsert endorse + listen_brief
    rows = data["rows"]
    index = {str(r.get("dialog_id")): i for i, r in enumerate(rows)}
    for nr in (endorse, listen_brief):
        k = nr["dialog_id"]
        if k in index:
            rows[index[k]] = nr
        else:
            rows.append(nr)

    save("def_dialog.json", data)

    merge_l10n(
        {
            "council.choice.endorse": "附议刚才那句",
            "council.player.endorse": "回东家，刚才那句，晚辈附议。",
            "ui.council_endorse": "你附议了刚才那一句",
            "dialog.m000.council_listen_brief": "门帘外两句就过了——管事按章，王胖子不语。今朝账不长。",
        }
    )
    print("P20 endorse + brief council done")


if __name__ == "__main__":
    main()
