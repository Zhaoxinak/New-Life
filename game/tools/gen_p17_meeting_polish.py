# -*- coding: utf-8 -*-
"""P17: 例行朝账 M000 + policy_draft 定调分支 + 日历 D15。"""
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
    row = {"dialog_id": dialog_id, "speaker": speaker, "loc_key": loc_key, "next": next_id or ""}
    row.update(extra)
    return row


POLICY_NBC = [
    {"require": [{"policy_leading": "son_first"}], "id": "dialog_meeting_policy_son_first"},
    {"require": [{"policy_leading": "watch_jufeng"}], "id": "dialog_meeting_policy_watch_jufeng"},
    {"require": [{"policy_leading": "look_away"}], "id": "dialog_meeting_policy_look_away"},
    {"require": [{"policy_leading": "risk_report"}], "id": "dialog_meeting_policy_risk"},
    {"require": [{"policy_leading": "foreign_caution"}], "id": "dialog_meeting_policy_foreign"},
    {"require": [{"policy_leading": "bright_steady"}], "id": "dialog_meeting_policy_bright"},
    {"default": "dialog_meeting_policy_bright"},
]


def main() -> None:
    upsert_rows(
        "def_event.json",
        "event_id",
        [
            {
                "event_id": "M000",
                "loc_key": "event.m000.name",
                "dialog_entry": "dialog_m000_start",
                "effects_when": "dialog",
                "require": [{"flag": "flag_meeting_witness", "value": True}],
                "effects": [],
                "event_type": "meeting",
            }
        ],
    )

    policy_nodes = [
        d(
            "dialog_meeting_policy_resolve",
            "narrator",
            "dialog.meeting.policy_resolve",
            "",
            tags=["meeting", "policy"],
            effects=[{"op": "resolve_meeting_policy"}],
            next_by_condition=POLICY_NBC,
        ),
        d(
            "dialog_meeting_policy_bright",
            "char_qian_demao",
            "dialog.meeting.policy.bright",
            "dialog_meeting_policy_to_tasks",
            tags=["meeting", "policy"],
        ),
        d(
            "dialog_meeting_policy_son_first",
            "char_qian_demao",
            "dialog.meeting.policy.son_first",
            "dialog_meeting_policy_to_tasks",
            tags=["meeting", "policy"],
        ),
        d(
            "dialog_meeting_policy_watch_jufeng",
            "char_qian_demao",
            "dialog.meeting.policy.watch_jufeng",
            "dialog_meeting_policy_to_tasks",
            tags=["meeting", "policy"],
        ),
        d(
            "dialog_meeting_policy_look_away",
            "char_qian_demao",
            "dialog.meeting.policy.look_away",
            "dialog_meeting_policy_to_tasks",
            tags=["meeting", "policy"],
        ),
        d(
            "dialog_meeting_policy_risk",
            "char_qian_demao",
            "dialog.meeting.policy.risk",
            "dialog_meeting_policy_to_tasks",
            tags=["meeting", "policy"],
        ),
        d(
            "dialog_meeting_policy_foreign",
            "char_qian_demao",
            "dialog.meeting.policy.foreign",
            "dialog_meeting_policy_to_tasks",
            tags=["meeting", "policy"],
        ),
        d(
            "dialog_meeting_policy_to_tasks",
            "narrator",
            "dialog.meeting.policy_to_tasks",
            "",
            tags=["meeting", "policy"],
            next_by_condition=[
                {"require": [{"flag": "flag_in_m000", "value": True}], "id": "dialog_m000_tasks"},
                {"require": [{"flag": "flag_in_m003", "value": True}], "id": "dialog_m003_tasks"},
                {"default": "dialog_m000_tasks"},
            ],
        ),
    ]

    # M000 routine graph
    m000 = [
        d(
            "dialog_m000_start",
            "narrator",
            "dialog.m000.start",
            "dialog_m000_rollcall",
            tags=["meeting", "m000"],
            effects=[
                {"op": "set_flag", "key": "flag_in_m000", "value": True},
                {"op": "clear_flag", "key": "flag_in_m003"},
                {"op": "apply_route_policy_bias"},
                {"op": "init_default_council"},
            ],
        ),
        d("dialog_m000_rollcall", "char_zhou_guanshi", "dialog.m000.rollcall", "dialog_m000_ladder", tags=["meeting", "m000"]),
        d(
            "dialog_m000_ladder",
            "char_zhou_guanshi",
            "dialog.m000.ladder",
            "dialog_m000_report",
            tags=["meeting", "ladder", "m000"],
        ),
        d(
            "dialog_m000_report",
            "char_wang_pangzi",
            "dialog.m000.report",
            "dialog_m000_after_report",
            tags=["meeting", "m000"],
        ),
        d(
            "dialog_m000_after_report",
            "narrator",
            "dialog.m000.after_report",
            "",
            tags=["meeting", "m000"],
            next_by_condition=[
                {"require": [{"or": [{"meeting_tier": "report"}, {"meeting_tier": "decide"}, {"flag": "flag_meeting_report_eligible", "value": True}]}], "id": "dialog_m000_player_report"},
                {"default": "dialog_m000_council_gate"},
            ],
        ),
        {
            "dialog_id": "dialog_m000_player_report",
            "speaker": "char_qian_demao",
            "loc_key": "dialog.m000.player_report",
            "tags": ["meeting", "m000"],
            "choices": [
                {
                    "id": "honest",
                    "loc_key": "dialog.m003.choice.honest",
                    "effects": [{"op": "add", "key": "stat_trust_firm", "value": 2}, {"op": "add_meeting_report", "value": 4}],
                    "next": "dialog_m000_council_gate",
                },
                {
                    "id": "polish",
                    "loc_key": "dialog.m003.choice.polish",
                    "effects": [{"op": "add_meeting_report", "value": 6}],
                    "next": "dialog_m000_council_gate",
                },
                {
                    "id": "hold",
                    "loc_key": "dialog.m003.choice.hold",
                    "effects": [{"op": "add", "key": "stat_intel", "value": 1}],
                    "next": "dialog_m000_council_gate",
                },
            ],
        },
        d(
            "dialog_m000_council_gate",
            "narrator",
            "dialog.m000.council_gate",
            "",
            tags=["meeting", "council", "m000"],
            next_by_condition=[
                {"require": [{"or": [{"meeting_tier": "report"}, {"meeting_tier": "decide"}, {"flag": "flag_meeting_report_eligible", "value": True}]}], "id": "dialog_council_zhou_order"},
                {"default": "dialog_m000_council_listen"},
            ],
        ),
        d(
            "dialog_m000_council_listen",
            "narrator",
            "dialog.m000.council_listen",
            "dialog_m000_council_listen_wang",
            tags=["meeting", "council", "m000"],
            effects=[
                {"op": "record_council_speech", "char": "char_zhou_guanshi", "spoke": True, "stance": "bright_steady", "mode": "speak"},
                {"op": "add_policy_draft", "key": "bright_steady", "value": 2},
            ],
        ),
        d(
            "dialog_m000_council_listen_wang",
            "narrator",
            "dialog.m000.council_listen_wang",
            "dialog_meeting_policy_resolve",
            tags=["meeting", "council", "m000"],
            effects=[
                {"op": "record_council_speech", "char": "char_wang_pangzi", "spoke": False, "mode": "pass"},
            ],
        ),
        d(
            "dialog_m000_tasks",
            "char_zhou_guanshi",
            "dialog.m000.tasks",
            "dialog_m000_close",
            tags=["meeting", "m000"],
            effects=[{"op": "assign_rank_tasks"}],
        ),
        d(
            "dialog_m000_close",
            "narrator",
            "dialog.m000.close",
            "",
            tags=["meeting", "m000"],
            effects=[
                {"op": "complete_meeting_cycle", "summary_key": "meeting.summary.m000"},
                {"op": "clear_flag", "key": "flag_in_m000"},
            ],
        ),
    ]

    upsert_rows("def_dialog.json", "dialog_id", policy_nodes + m000)

    # Wire council next → policy resolve; M003 policy → resolve
    data = load("def_dialog.json")
    for row in data["rows"]:
        did = row.get("dialog_id")
        if did == "dialog_meeting_council_next":
            row["next"] = "dialog_meeting_policy_resolve"
        if did == "dialog_m003_start":
            eff = list(row.get("effects") or [])
            # ensure flags
            if not any(e.get("key") == "flag_in_m003" for e in eff):
                eff.append({"op": "set_flag", "key": "flag_in_m003", "value": True})
                eff.append({"op": "clear_flag", "key": "flag_in_m000"})
            row["effects"] = eff
        if did == "dialog_m003_policy":
            # 旧节点改为跳到 resolve
            row["next"] = "dialog_meeting_policy_resolve"
            row["effects"] = list(row.get("effects") or [])
        if did == "dialog_m003_tasks":
            # keep existing; also clear flag_in_m003 on close path — close already has complete
            pass
        if did == "dialog_m003_close":
            eff = list(row.get("effects") or [])
            if not any(e.get("op") == "clear_flag" and e.get("key") == "flag_in_m003" for e in eff):
                eff.append({"op": "clear_flag", "key": "flag_in_m003"})
            row["effects"] = eff
        # M002 scripted policy stays; optional resolve after would override — leave M002 alone
    save("def_dialog.json", data)

    # Calendar: D15 morning M000 (E013 stays late)
    cal = load("def_calendar.json")
    rows = cal["rows"]
    # remove existing M000 rows then add
    rows = [r for r in rows if r.get("event_id") != "M000"]
    rows.append({"day": 15, "slot": "morning", "event_id": "M000", "require": []})
    # D22 morning routine if no other M*
    rows.append({"day": 22, "slot": "morning", "event_id": "M000", "require": []})
    rows.sort(key=lambda r: (int(r.get("day", 0)), str(r.get("slot", "")), str(r.get("event_id", ""))))
    cal["rows"] = rows
    save("def_calendar.json", cal)

    # registry
    reg = load("registry/events.json")
    events = reg.get("events", [])
    by_id = {e["event_id"]: i for i, e in enumerate(events)}
    erow = {
        "event_id": "M000",
        "chapter": 0,
        "event_type": "meeting",
        "dialog_entry": "dialog_m000_start",
        "status": "active",
        "note": "例行朝账；可每周重播",
    }
    if "M000" in by_id:
        events[by_id["M000"]] = erow
    else:
        events.append(erow)
    reg["events"] = events
    save("registry/events.json", reg)

    pack = load("pack.json")
    pack["content_version"] = "1.11.1-kairo"
    save("pack.json", pack)

    merge_l10n(
        {
            "event.m000.name": "前堂朝账",
            "meeting.summary.m000": "例行朝账已过，本周差事已摊。",
            "meeting.policy.bright_steady": "稳明面",
            "meeting.policy.son_first": "先安顿少爷",
            "meeting.policy.watch_jufeng": "盯聚丰",
            "meeting.policy.look_away": "少问后院",
            "meeting.policy.risk_report": "直陈货单",
            "meeting.policy.foreign_caution": "洋行谨慎",
            "ui.ladder_board_title": "序位 · %s",
            "ui.ladder_board_you": "你：第 %d / %d",
            "ui.ladder_board_empty": "尚无序位池——朝账后才会排。",
            "ui.ladder_board_meeting": "距朝账：%d 日",
            "ui.ladder_board_policy": "上次定调：%s",
            "ui.policy_aligned": "你的建言与东家定调相合",
            "ui.policy_rebuked": "东家驳回了你的直陈——眼神沉了沉",
            "dialog.meeting.policy_resolve": "东家抬眼，把众人的话在心里过了一遍。",
            "dialog.meeting.policy.bright": "明面的事先理清楚。这周少惹是非，货单、值更，按章走。",
            "dialog.meeting.policy.son_first": "排场的事先搁着。这周，先把少爷那边安顿好。",
            "dialog.meeting.policy.watch_jufeng": "聚丰那边眼多。街面上盯紧，别被人压了价还不知道。",
            "dialog.meeting.policy.look_away": "后院的事，外场少问。先把明面稳住。",
            "dialog.meeting.policy.risk": "……货单的事，我记下了。但这话，到此为止。",
            "dialog.meeting.policy.foreign": "洋行的事，能不沾就不沾。这周谨慎往来。",
            "dialog.meeting.policy_to_tasks": "定调已落。差事该派了。",
            "dialog.m000.start": "又是朝账日。前堂茶碗摆齐，门帘里外各有各的位子。",
            "dialog.m000.rollcall": "点名——该到的到了。开始。",
            "dialog.m000.ladder": "本周序位，账上已有数。各自心里有数便是。",
            "dialog.m000.report": "前堂这周进出还算清楚。人手紧，但没误客。",
            "dialog.m000.after_report": "汇报过了。下面是建言。",
            "dialog.m000.player_report": "你也说说——这周差事怎样？",
            "dialog.m000.council_gate": "堂上安静了一瞬，轮到谁开口，各人心里清楚。",
            "dialog.m000.council_listen": "门帘外，你听见周管事开口——按章、货单、别省东家的脸。",
            "dialog.m000.council_listen_wang": "王胖子那边没接话。堂里只余茶碗轻响。",
            "dialog.m000.tasks": "本周差事照旧——做不利索，下回朝账就难看。",
            "dialog.m000.close": "朝账散了。门帘落下，一周的路又重新铺开。",
        }
    )

    # help: mention L key
    help_body = load("l10n/zh_CN.json")["zh_CN"].get("ui.help_body", "")
    if "序位" in help_body and "按 L" not in help_body:
        help_body = help_body.replace(
            "· HUD 看「序位」与「距朝账」。",
            "· HUD 点「序位」或按 [b]L[/b] 看迷你排行榜；看「距朝账」。",
        )
        merge_l10n({"ui.help_body": help_body})

    print("P17 done.")


if __name__ == "__main__":
    main()
