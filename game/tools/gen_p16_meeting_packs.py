# -*- coding: utf-8 -*-
"""P16: 朝账系统内容落地 — M001/M002/M003、竞争者、日历迁移、建言池。"""
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


def patch_dialog(dialog_id: str, **fields) -> None:
    data = load("def_dialog.json")
    for row in data["rows"]:
        if row.get("dialog_id") == dialog_id:
            row.update(fields)
            save("def_dialog.json", data)
            print("patched", dialog_id)
            return
    print("WARN missing", dialog_id)


def merge_l10n(entries: dict) -> None:
    data = load("l10n/zh_CN.json")
    bucket = data.setdefault("zh_CN", {})
    bucket.update(entries)
    save("l10n/zh_CN.json", data)


def d(dialog_id: str, speaker: str, loc_key: str, next_id: str = "", **extra) -> dict:
    row = {
        "dialog_id": dialog_id,
        "speaker": speaker,
        "loc_key": loc_key,
        "next": next_id or "",
    }
    row.update(extra)
    return row


def main() -> None:
    # --- characters ---
    upsert_rows(
        "def_char.json",
        "char_id",
        [
            {
                "char_id": "char_apprentice_xiao_chen",
                "loc_key": "char_apprentice_xiao_chen",
                "blurb_key": "char.xiao_chen.blurb",
                "title_key": "char.xiao_chen.title",
                "org_id": "org_qianji",
                "is_player": False,
                "demo": True,
                "rank_label": "学徒",
                "home_loc": "loc_01",
                "tags": ["竞争者", "学徒池"],
            },
            {
                "char_id": "char_apprentice_xiao_liu",
                "loc_key": "char_apprentice_xiao_liu",
                "blurb_key": "char.xiao_liu.blurb",
                "title_key": "char.xiao_liu.title",
                "org_id": "org_qianji",
                "is_player": False,
                "demo": True,
                "rank_label": "学徒",
                "home_loc": "loc_01",
                "tags": ["竞争者", "学徒池"],
            },
            {
                "char_id": "char_apprentice_a_fu",
                "loc_key": "char_apprentice_a_fu",
                "blurb_key": "char.a_fu.blurb",
                "title_key": "char.a_fu.title",
                "org_id": "org_qianji",
                "is_player": False,
                "demo": True,
                "rank_label": "学徒",
                "home_loc": "loc_02",
                "tags": ["竞争者", "学徒池"],
            },
            {
                "char_id": "char_apprentice_sun_liu",
                "loc_key": "char_apprentice_sun_liu",
                "blurb_key": "char.sun_liu.blurb",
                "title_key": "char.sun_liu.title",
                "org_id": "org_qianji",
                "is_player": False,
                "demo": True,
                "rank_label": "学徒",
                "home_loc": "loc_01",
                "tags": ["竞争者", "学徒池"],
            },
            {
                "char_id": "char_li_waichang",
                "loc_key": "char_li_waichang",
                "blurb_key": "char.li_waichang.blurb",
                "title_key": "char.li_waichang.title",
                "org_id": "org_qianji",
                "is_player": False,
                "demo": True,
                "rank_label": "外场",
                "home_loc": "loc_03",
                "tags": ["竞争者", "外场池"],
            },
            {
                "char_id": "char_zhao_waichang",
                "loc_key": "char_zhao_waichang",
                "blurb_key": "char.zhao_waichang.blurb",
                "title_key": "char.zhao_waichang.title",
                "org_id": "org_qianji",
                "is_player": False,
                "demo": True,
                "rank_label": "外场",
                "home_loc": "loc_03",
                "tags": ["竞争者", "外场池"],
            },
        ],
    )

    # --- events ---
    upsert_rows(
        "def_event.json",
        "event_id",
        [
            {
                "event_id": "M001",
                "loc_key": "event.m001.name",
                "dialog_entry": "dialog_m001_start",
                "effects_when": "dialog",
                "require": [],
                "effects": [],
            },
            {
                "event_id": "M002",
                "loc_key": "event.m002.name",
                "dialog_entry": "dialog_m002_start",
                "effects_when": "dialog",
                "require": [{"flag": "flag_meeting_witness", "value": True}],
                "effects": [],
            },
            {
                "event_id": "M003",
                "loc_key": "event.m003.name",
                "dialog_entry": "dialog_m003_start",
                "effects_when": "dialog",
                "mutex_group": "chapter2.rankup",
                "require": [
                    {"rank": "apprentice"},
                    {"key": "stat_trust_firm", "op": ">=", "value": 45},
                    {"key": "stat_intel", "op": ">=", "value": 20},
                ],
                "effects": [],
            },
        ],
    )

    # --- dialogs: M001 ---
    m001 = [
        d("dialog_m001_start", "narrator", "dialog.m001.start", "dialog_m001_zhou_order", tags=["meeting", "m001"]),
        d("dialog_m001_zhou_order", "char_zhou_guanshi", "dialog.m001.zhou_order", "dialog_m001_rollcall", tags=["meeting", "m001"]),
        d("dialog_m001_rollcall", "char_zhou_guanshi", "dialog.m001.rollcall", "dialog_m001_report_wang", tags=["meeting", "m001"]),
        d(
            "dialog_m001_report_wang",
            "char_wang_pangzi",
            "dialog.m001.report_wang",
            "dialog_m001_demao_comment",
            tags=["meeting", "ladder", "m001"],
        ),
        d("dialog_m001_demao_comment", "char_qian_demao", "dialog.m001.demao_comment", "dialog_m001_paojie_echo", tags=["meeting", "m001"]),
        d(
            "dialog_m001_paojie_echo",
            "char_qian_demao",
            "dialog.m001.paojie_echo",
            "dialog_m001_manshi_hint",
            tags=["meeting", "keyword_highlight", "m001"],
        ),
        d("dialog_m001_manshi_hint", "narrator", "dialog.m001.manshi_hint", "dialog_m001_council_zhou", tags=["meeting", "m001"]),
        d(
            "dialog_m001_council_zhou",
            "char_zhou_guanshi",
            "dialog.m001.council_zhou",
            "dialog_m001_council_wang_pass",
            tags=["meeting", "council", "m001"],
            effects=[
                {"op": "record_council_speech", "char": "char_zhou_guanshi", "spoke": True, "stance": "bright_steady", "mode": "speak"},
                {"op": "add_policy_draft", "key": "bright_steady", "value": 2},
            ],
        ),
        d(
            "dialog_m001_council_wang_pass",
            "narrator",
            "dialog.m001.council_wang_pass",
            "dialog_m001_policy_wood",
            tags=["meeting", "council", "m001"],
            effects=[{"op": "record_council_speech", "char": "char_wang_pangzi", "spoke": False, "mode": "pass"}],
        ),
        d("dialog_m001_policy_wood", "char_qian_demao", "dialog.m001.policy_wood", "dialog_m001_tasks", tags=["meeting", "m001"]),
        d(
            "dialog_m001_tasks",
            "char_zhou_guanshi",
            "dialog.m001.tasks",
            "dialog_m001_close",
            tags=["meeting", "m001"],
            effects=[
                {"op": "init_ladder_pool", "pool_id": "pool_apprentice"},
                {"op": "set_flag", "key": "flag_meeting_witness", "value": True},
                {"op": "set_meeting_tier", "value": "listen"},
                {"op": "init_council_queue", "ids": ["char_zhou_guanshi", "char_wang_pangzi"]},
                {"op": "assign_weekly_tasks", "ids": ["task_tidy_manifest", "task_front_duty"]},
                {"op": "add_meeting_report", "value": 0},
            ],
        ),
        d(
            "dialog_m001_close",
            "narrator",
            "dialog.m001.close",
            "",
            tags=["meeting", "m001"],
            effects=[{"op": "complete_meeting_cycle", "summary_key": "meeting.summary.m001"}],
        ),
    ]

    # --- dialogs: M002 (embeds E004/E006 via next links) ---
    m002 = [
        d("dialog_m002_start", "narrator", "dialog.m002.start", "dialog_m002_zhou_rollcall", tags=["meeting", "m002"]),
        d("dialog_m002_zhou_rollcall", "char_zhou_guanshi", "dialog.m002.zhou_rollcall", "dialog_e004_start", tags=["meeting", "m002"]),
        # after E004 outro → report_zian
        d("dialog_m002_report_zian", "char_qian_zian", "dialog.m002.report_zian", "dialog_m002_player_named", tags=["meeting", "m002"]),
        d("dialog_m002_player_named", "char_qian_demao", "dialog.m002.player_named", "dialog_e006_start", tags=["meeting", "m002"]),
        # after E006 → ladder_read
        d(
            "dialog_m002_ladder_read",
            "char_zhou_guanshi",
            "dialog.m002.ladder_read",
            "dialog_m002_council_zian",
            tags=["meeting", "ladder", "m002"],
            effects=[
                {"op": "bias_ladder_npc", "char": "char_qian_zian", "value": 12},
                {"op": "add_ladder_score", "char": "char_lin_ruisheng", "value": -5},
                {"op": "set_flag", "key": "seen_event_E004", "value": True},
                {"op": "set_flag", "key": "seen_event_E006", "value": True},
            ],
        ),
        d(
            "dialog_m002_council_zian",
            "char_qian_zian",
            "dialog.m002.council_zian",
            "dialog_m002_council_zhou_pass",
            tags=["meeting", "council", "m002"],
            effects=[
                {"op": "record_council_speech", "char": "char_qian_zian", "spoke": True, "stance": "son_first", "mode": "speak"},
                {"op": "add_policy_draft", "key": "son_first", "value": 3},
            ],
        ),
        d(
            "dialog_m002_council_zhou_pass",
            "narrator",
            "dialog.m002.council_zhou_pass",
            "dialog_m002_council_wang",
            tags=["meeting", "council", "m002"],
            effects=[{"op": "record_council_speech", "char": "char_zhou_guanshi", "spoke": False, "mode": "pass"}],
        ),
        d(
            "dialog_m002_council_wang",
            "char_wang_pangzi",
            "dialog.m002.council_wang",
            "dialog_m002_policy_son",
            tags=["meeting", "council", "m002"],
            effects=[
                {"op": "record_council_speech", "char": "char_wang_pangzi", "spoke": True, "stance": "bright_steady", "mode": "speak"},
                {"op": "add_policy_draft", "key": "bright_steady", "value": 1},
            ],
        ),
        d("dialog_m002_policy_son", "char_qian_demao", "dialog.m002.policy_son", "dialog_m002_task_humiliate", tags=["meeting", "m002"]),
        d(
            "dialog_m002_task_humiliate",
            "char_qian_demao",
            "dialog.m002.task_humiliate",
            "dialog_m002_close",
            tags=["meeting", "m002"],
            effects=[
                {"op": "assign_weekly_tasks", "ids": ["task_front_duty", "task_errand"]},
                {"op": "set_meeting_tier", "value": "listen"},
            ],
        ),
        d(
            "dialog_m002_close",
            "narrator",
            "dialog.m002.close",
            "",
            tags=["meeting", "m002"],
            effects=[{"op": "complete_meeting_cycle", "summary_key": "meeting.summary.m002"}],
        ),
    ]

    # --- council shared pool ---
    council = [
        d(
            "dialog_council_zhou_order",
            "char_zhou_guanshi",
            "council.zhou.order",
            "dialog_council_wang_front",
            tags=["meeting", "council"],
            effects=[
                {"op": "record_council_speech", "char": "char_zhou_guanshi", "spoke": True, "topic_key": "council.zhou.order", "stance": "bright_steady"},
                {"op": "add_policy_draft", "key": "bright_steady", "value": 2},
            ],
        ),
        d(
            "dialog_council_zhou_pass",
            "narrator",
            "council.zhou.pass",
            "dialog_council_wang_front",
            tags=["meeting", "council"],
            effects=[{"op": "record_council_speech", "char": "char_zhou_guanshi", "spoke": False, "mode": "pass"}],
        ),
        d(
            "dialog_council_wang_front",
            "char_wang_pangzi",
            "council.wang.front_busy",
            "dialog_meeting_council_player_pick",
            tags=["meeting", "council"],
            effects=[
                {"op": "record_council_speech", "char": "char_wang_pangzi", "spoke": True, "stance": "bright_steady"},
                {"op": "add_policy_draft", "key": "bright_steady", "value": 1},
            ],
        ),
        d(
            "dialog_council_wang_pass",
            "narrator",
            "council.wang.pass",
            "dialog_meeting_council_player_pick",
            tags=["meeting", "council"],
            effects=[{"op": "record_council_speech", "char": "char_wang_pangzi", "spoke": False, "mode": "pass"}],
        ),
        d(
            "dialog_council_zian_show",
            "char_qian_zian",
            "council.zian.show",
            "dialog_meeting_council_next",
            tags=["meeting", "council"],
            effects=[
                {"op": "record_council_speech", "char": "char_qian_zian", "spoke": True, "stance": "son_first"},
                {"op": "add_policy_draft", "key": "son_first", "value": 2},
                {"op": "add", "meter": "father_son", "value": -5},
            ],
        ),
        {
            "dialog_id": "dialog_meeting_council_player_pick",
            "speaker": "char_qian_demao",
            "loc_key": "council.player.pick",
            "tags": ["meeting", "council"],
            "choices": [
                {
                    "id": "council_speak",
                    "loc_key": "council.choice.speak",
                    "next": "dialog_meeting_council_topic",
                },
                {
                    "id": "council_silent",
                    "loc_key": "council.choice.silent",
                    "next": "dialog_meeting_council_player_pass",
                },
            ],
        },
        {
            "dialog_id": "dialog_meeting_council_topic",
            "speaker": "narrator",
            "loc_key": "council.player.topic",
            "tags": ["meeting", "council"],
            "choices": [
                {"id": "steady", "loc_key": "council.choice.steady", "next": "dialog_council_player_steady"},
                {"id": "market", "loc_key": "council.choice.market", "next": "dialog_council_player_market"},
                {"id": "look_away", "loc_key": "council.choice.look_away", "next": "dialog_council_player_look_away"},
                {
                    "id": "risk",
                    "loc_key": "council.choice.risk",
                    "require": [{"key": "stat_intel", "op": ">=", "value": 15}],
                    "next": "dialog_council_player_risk",
                },
            ],
        },
        d(
            "dialog_council_player_steady",
            "char_lin_ruisheng",
            "council.player.steady",
            "dialog_meeting_council_demao_nod",
            tags=["meeting", "council"],
            effects=[
                {"op": "record_council_speech", "char": "char_lin_ruisheng", "spoke": True, "stance": "bright_steady", "mode": "speak"},
                {"op": "add_policy_draft", "key": "bright_steady", "value": 2},
                {"op": "add", "key": "stat_trust_firm", "value": 2},
            ],
        ),
        d(
            "dialog_council_player_market",
            "char_lin_ruisheng",
            "council.player.market",
            "dialog_meeting_council_demao_nod",
            tags=["meeting", "council"],
            effects=[
                {"op": "record_council_speech", "char": "char_lin_ruisheng", "spoke": True, "stance": "watch_jufeng", "mode": "speak"},
                {"op": "add_policy_draft", "key": "watch_jufeng", "value": 2},
                {"op": "add", "key": "stat_network", "value": 2},
            ],
        ),
        d(
            "dialog_council_player_look_away",
            "char_lin_ruisheng",
            "council.player.look_away",
            "dialog_meeting_council_demao_nod",
            tags=["meeting", "council"],
            effects=[
                {"op": "record_council_speech", "char": "char_lin_ruisheng", "spoke": True, "stance": "look_away", "mode": "speak"},
                {"op": "add_policy_draft", "key": "look_away", "value": 2},
            ],
        ),
        d(
            "dialog_council_player_risk",
            "char_lin_ruisheng",
            "council.player.risk",
            "dialog_meeting_council_demao_cut",
            tags=["meeting", "council"],
            effects=[
                {"op": "record_council_speech", "char": "char_lin_ruisheng", "spoke": True, "stance": "risk_report", "mode": "speak"},
                {"op": "add_policy_draft", "key": "risk_report", "value": 2},
                {"op": "add", "key": "stat_intel", "value": 2},
                {"op": "add", "key": "stat_suspicion", "value": 3},
            ],
        ),
        d(
            "dialog_meeting_council_player_pass",
            "char_lin_ruisheng",
            "council.player.pass",
            "dialog_meeting_council_next",
            tags=["meeting", "council"],
            effects=[{"op": "record_council_speech", "char": "char_lin_ruisheng", "spoke": False, "mode": "pass"}],
        ),
        d("dialog_meeting_council_demao_nod", "char_qian_demao", "council.demao.nod", "dialog_meeting_council_next", tags=["meeting", "council"]),
        d("dialog_meeting_council_demao_cut", "char_qian_demao", "council.demao.cut", "dialog_meeting_council_next", tags=["meeting", "council"]),
        d("dialog_meeting_council_next", "narrator", "council.next", "dialog_m003_policy", tags=["meeting", "council"]),
    ]

    # --- dialogs: M003 ---
    m003 = [
        d("dialog_m003_start", "narrator", "dialog.m003.start", "dialog_m003_enter_hall", tags=["meeting", "m003"]),
        d("dialog_m003_enter_hall", "char_zhou_guanshi", "dialog.m003.enter_hall", "dialog_m003_report_choice", tags=["meeting", "m003"]),
        {
            "dialog_id": "dialog_m003_report_choice",
            "speaker": "char_qian_demao",
            "loc_key": "dialog.m003.report_choice",
            "tags": ["meeting", "m003"],
            "choices": [
                {"id": "honest", "loc_key": "dialog.m003.choice.honest", "next": "dialog_m003_report_a"},
                {"id": "polish", "loc_key": "dialog.m003.choice.polish", "next": "dialog_m003_report_b"},
                {"id": "hold", "loc_key": "dialog.m003.choice.hold", "next": "dialog_m003_report_c"},
            ],
        },
        d(
            "dialog_m003_report_a",
            "char_lin_ruisheng",
            "dialog.m003.report_a",
            "",
            tags=["meeting", "m003"],
            effects=[{"op": "add", "key": "stat_trust_firm", "value": 3}],
            next_by_condition=[
                {"require": [{"flag": "route_defect", "value": True}], "id": "dialog_e020b_start"},
                {"require": [{"flag": "route_foreign", "value": True}], "id": "dialog_e020c_start"},
                {"default": "dialog_e020_start"},
            ],
        ),
        d(
            "dialog_m003_report_b",
            "char_lin_ruisheng",
            "dialog.m003.report_b",
            "",
            tags=["meeting", "m003"],
            effects=[{"op": "add", "key": "stat_trust_firm", "value": 1}, {"op": "add_meeting_report", "value": 5}],
            next_by_condition=[
                {"require": [{"flag": "route_defect", "value": True}], "id": "dialog_e020b_start"},
                {"require": [{"flag": "route_foreign", "value": True}], "id": "dialog_e020c_start"},
                {"default": "dialog_e020_start"},
            ],
        ),
        d(
            "dialog_m003_report_c",
            "char_lin_ruisheng",
            "dialog.m003.report_c",
            "",
            tags=["meeting", "m003"],
            effects=[{"op": "add", "key": "stat_intel", "value": 2}],
            next_by_condition=[
                {"require": [{"flag": "route_defect", "value": True}], "id": "dialog_e020b_start"},
                {"require": [{"flag": "route_foreign", "value": True}], "id": "dialog_e020c_start"},
                {"default": "dialog_e020_start"},
            ],
        ),
        # after E020* window → council
        d("dialog_m003_policy", "char_qian_demao", "dialog.m003.policy", "dialog_m003_tasks", tags=["meeting", "m003"]),
        d(
            "dialog_m003_tasks",
            "char_zhou_guanshi",
            "dialog.m003.tasks",
            "dialog_m003_close",
            tags=["meeting", "m003"],
            effects=[
                {"op": "set_flag", "key": "flag_meeting_report_eligible", "value": True},
                {"op": "set_meeting_tier", "value": "report"},
                {"op": "assign_weekly_tasks", "ids": ["task_street_watch", "task_delivery"]},
                {"op": "init_ladder_pool", "pool_id": "pool_waichang"},
            ],
        ),
        d(
            "dialog_m003_close",
            "narrator",
            "dialog.m003.close",
            "",
            tags=["meeting", "m003"],
            effects=[{"op": "complete_meeting_cycle", "summary_key": "meeting.summary.m003"}],
        ),
    ]

    upsert_rows("def_dialog.json", "dialog_id", m001 + m002 + council + m003)

    # Patch E004/E006/E020* outros to return into meeting shells
    patch_dialog(
        "dialog_e004_outro",
        next="dialog_m002_report_zian",
    )
    # Keep E004 effects; also mark seen when embedded
    e004 = load("def_dialog.json")
    for row in e004["rows"]:
        if row.get("dialog_id") == "dialog_e004_outro":
            eff = list(row.get("effects") or [])
            if not any(e.get("key") == "seen_event_E004" for e in eff):
                eff.append({"op": "set_flag", "key": "seen_event_E004", "value": True})
            row["effects"] = eff
    save("def_dialog.json", e004)

    patch_dialog("dialog_e006_qian_soft", next="dialog_m002_ladder_read")

    for did, eid in [
        ("dialog_e020_window", "E020"),
        ("dialog_e020b_window", "E020B"),
        ("dialog_e020c_window", "E020C"),
    ]:
        data = load("def_dialog.json")
        for row in data["rows"]:
            if row.get("dialog_id") == did:
                row["next"] = "dialog_council_zhou_order"
                eff = list(row.get("effects") or [])
                if not any(e.get("key") == f"seen_event_{eid}" for e in eff):
                    eff.append({"op": "set_flag", "key": f"seen_event_{eid}", "value": True})
                # B/C also set their done flags already in effects typically
                row["effects"] = eff
                break
        save("def_dialog.json", data)
        print("patched", did, "→ council")

    # --- calendar rewrite (Demo compressed + 朝账迁移) ---
    calendar_rows = [
        {"day": 1, "slot": "morning", "event_id": "E001", "require": []},
        {"day": 1, "slot": "morning", "event_id": "M001", "require": []},
        {"day": 2, "slot": "evening", "event_id": "E002", "require": []},
        {"day": 3, "slot": "afternoon", "event_id": "E003", "require": []},
        # D4–D7 free + weekly tasks
        {"day": 8, "slot": "morning", "event_id": "M002", "require": []},
        {"day": 8, "slot": "evening", "event_id": "E005", "require": []},
        {"day": 9, "slot": "afternoon", "event_id": "E007", "require": []},
        {"day": 10, "slot": "evening", "event_id": "E008", "require": []},
        {"day": 11, "slot": "late_night", "event_id": "E009", "require": []},
        # discovery arc shifted +4 from old D8+
        {"day": 12, "slot": "late_night", "event_id": "E010", "require": [], "mutex_group": "chapter2.night_cargo"},
        {"day": 13, "slot": "afternoon", "event_id": "E011", "require": []},
        {"day": 13, "slot": "evening", "event_id": "E012", "require": []},
        {"day": 14, "slot": "late_night", "event_id": "E010b", "require": [], "mutex_group": "chapter2.night_cargo"},
        {"day": 15, "slot": "late_night", "event_id": "E013", "require": []},
        {"day": 16, "slot": "afternoon", "event_id": "E019", "require": [], "mutex_group": ""},
        # M003 replaces standalone E020* on D17
        {"day": 17, "slot": "morning", "event_id": "M003", "require": [], "mutex_group": "chapter2.rankup"},
        {"day": 18, "slot": "afternoon", "event_id": "E021", "require": [], "mutex_group": "chapter2.light_reckoning", "route_tags": ["route_endure"]},
        {"day": 18, "slot": "afternoon", "event_id": "E021B", "require": [], "mutex_group": "chapter2.light_reckoning", "route_tags": ["route_defect"]},
        {"day": 18, "slot": "afternoon", "event_id": "E021C", "require": [], "mutex_group": "chapter2.light_reckoning", "route_tags": ["route_foreign"]},
        {"day": 19, "slot": "afternoon", "event_id": "E014", "require": []},
        {"day": 20, "slot": "late_night", "event_id": "E015", "require": []},
        {"day": 21, "slot": "afternoon", "event_id": "E016", "require": []},
        {"day": 21, "slot": "evening", "event_id": "E017", "require": [], "route_tags": ["route_foreign"], "mutex_group": ""},
        {"day": 22, "slot": "afternoon", "event_id": "E022", "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_endure"], "require": []},
        {"day": 22, "slot": "afternoon", "event_id": "E022B", "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_defect"], "require": []},
        {"day": 22, "slot": "afternoon", "event_id": "E022C", "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_foreign"], "require": []},
        {"day": 23, "slot": "morning", "event_id": "E018", "mutex_group": "chapter3.finale", "require": []},
    ]
    save("def_calendar.json", {"rows": calendar_rows})

    # --- ticks ---
    # 汇报分结算在 MeetingSystem.on_day_end（朝账日到达时），不在此重复挂 finalize。
    tick = load("def_tick.json")
    tick["rows"] = [r for r in tick["rows"] if r.get("tick_id") != "tick_meeting_report_weekly"]
    save("def_tick.json", tick)

    # --- registry ---
    reg = load("registry/events.json")
    events = reg.get("events", [])
    by_id = {e["event_id"]: i for i, e in enumerate(events)}
    for erow in [
        {"event_id": "M001", "chapter": 1, "event_type": "meeting", "dialog_entry": "dialog_m001_start", "status": "active"},
        {"event_id": "M002", "chapter": 1, "event_type": "meeting", "dialog_entry": "dialog_m002_start", "status": "active", "embeds": ["E004", "E006"]},
        {"event_id": "M003", "chapter": 2, "event_type": "meeting", "dialog_entry": "dialog_m003_start", "status": "active", "embeds": ["E020", "E020B", "E020C"], "mutex_group": "chapter2.rankup"},
    ]:
        eid = erow["event_id"]
        if eid in by_id:
            events[by_id[eid]] = erow
        else:
            events.append(erow)
    # mark E004/E006/E020* embedded
    for eid, parent in [("E004", "M002"), ("E006", "M002"), ("E020", "M003"), ("E020B", "M003"), ("E020C", "M003")]:
        if eid in by_id:
            events[by_id[eid]]["embedded_in"] = parent
            events[by_id[eid]]["status"] = "embedded"
    reg["events"] = events
    save("registry/events.json", reg)

    # --- pack version ---
    pack = load("pack.json")
    pack["content_version"] = "1.11.0-kairo"
    save("pack.json", pack)

    # --- l10n ---
    merge_l10n(
        {
            "event.m001.name": "首次旁听朝账",
            "event.m002.name": "满师朝账",
            "event.m003.name": "升外场朝账",
            "char_apprentice_xiao_chen": "小陈",
            "char_apprentice_xiao_liu": "小刘",
            "char_apprentice_a_fu": "阿福",
            "char_apprentice_sun_liu": "孙六",
            "char_li_waichang": "李外场",
            "char_zhao_waichang": "赵外场",
            "char.xiao_chen.title": "学徒·小陈",
            "char.xiao_liu.title": "学徒·小刘",
            "char.a_fu.title": "学徒·阿福",
            "char.sun_liu.title": "学徒·孙六",
            "char.li_waichang.title": "外场·李",
            "char.zhao_waichang.title": "外场·赵",
            "char.xiao_chen.blurb": "勤快老实，闷头干活，学徒池里最稳的劲敌。",
            "char.xiao_liu.blurb": "偷懒滑头，分数低却偶发蹭活。",
            "char.a_fu.blurb": "平庸陪跑，有时可拉拢传话。",
            "char.sun_liu.blurb": "会拍马，朝账周常突然蹿升。",
            "char.li_waichang.blurb": "外场实干派，差事完成度稳。",
            "char.zhao_waichang.blurb": "外场媚上派，东家信任高时得分猛。",
            "ladder.pool_apprentice.name": "学徒序",
            "ladder.pool_waichang.name": "外场序",
            "ladder.pool_paojie.name": "跑街序",
            "meeting.task.tidy_manifest": "整理货单",
            "meeting.task.front_duty": "前堂值更",
            "meeting.task.errand": "跑腿传话",
            "meeting.task.street_watch": "街面盯梢",
            "meeting.task.delivery": "送货清账",
            "meeting.task.intel": "打听消息",
            "meeting.task.entertain": "应酬账",
            "meeting.task.lead_clerk": "带伙计",
            "meeting.tier.listen": "旁听",
            "meeting.tier.report": "汇报",
            "meeting.tier.decide": "定调",
            "meeting.summary.m001": "首次旁听朝账，领了首周差事。",
            "meeting.summary.m002": "满师搁置，少爷占了序位。",
            "meeting.summary.m003": "升任外场，首次堂内建言。",
            "ui.meeting_today": "今日朝账",
            "ui.meeting_in_days": "距朝账 %d日",
            "ui.meeting_tasks_assigned": "本周差事已摊派",
            "ui.ladder_pending": "序位 —",
            "ui.ladder_up": "序位上升",
            "ui.ladder_down": "序位下滑",
            "dialog.m001.start": "考校刚散，前堂里已有人摆好了茶碗。周管事朝门帘外一指——今日是朝账日，你不够格入堂，只能在门外续茶、听着。",
            "dialog.m001.zhou_order": "瑞生，门外候着。茶凉了就续，别探头探脑。",
            "dialog.m001.rollcall": "点名——前堂王胖子，账房……少爷今日不在。学徒们门外听着便是。",
            "dialog.m001.report_wang": "……学徒里这周小陈排第一，瑞生第二。货单错两处，已改。",
            "dialog.m001.demao_comment": "嗯。数字对得上，人还嫩。",
            "dialog.m001.paojie_echo": "……林跑街，本月街面应酬你盯紧。瑞生满师的事，名册上先搁着，跑街这位置，不是光记数字就行的。",
            "dialog.m001.manshi_hint": "你听见「满师」二字从门帘里漏出来，又被轻轻按回去。",
            "dialog.m001.council_zhou": "……后院这几日按章走。谁要图省事，最后省的是东家的脸。",
            "dialog.m001.council_wang_pass": "王胖子没接话。堂里顿了一下——原来建言时，也可以不说。",
            "dialog.m001.policy_wood": "本月木材行情盯紧，少惹是非。散。",
            "dialog.m001.tasks": "你——本周把货单理清楚两遍，前堂值更别躲。朝账前做不利索，堂里就没你的位子。",
            "dialog.m001.close": "门帘落下，堂里的声音闷成一团。你低头看手里的茶托——跑街、满师、月例，全在那一道门里分。",
            "dialog.m002.start": "第七日一早，前堂比平日更早开了门。你照旧站在门帘外，手里是一壶续不满的热茶。",
            "dialog.m002.zhou_rollcall": "开门。今日朝账——还有贵客。",
            "dialog.m002.report_zian": "街面上……都还行吧。我也没细问。",
            "dialog.m002.player_named": "门帘外那个——瑞生，满师三年，货价行情你答得上来。堂里的事，你听着。",
            "dialog.m002.ladder_read": "本周序：少爷钱子安第一，林瑞生第二。满师名册，东家已有话。",
            "dialog.m002.council_zian": "我看街面上要摆排场，别老抠那几两银子。钱记的脸面，不能比聚丰矮一截。",
            "dialog.m002.council_zhou_pass": "周管事目光一扫，竟没开口。门帘外的人只听见茶碗轻轻一响。",
            "dialog.m002.council_wang": "前堂人手紧，货单先理清楚，比扩门面稳当。",
            "dialog.m002.policy_son": "排场的事，等子安先站稳了再说。这周，先把少爷那边安顿好。",
            "dialog.m002.task_humiliate": "瑞生，这周先把少爷那边招呼好。堂上的位子，等他能坐稳了再说。",
            "dialog.m002.close": "满师的名册上，你的名字被轻轻搁到了「以后再说」。门帘外的人听得一清二楚。",
            "dialog.m003.start": "这一回，周管事掀开门帘：「进去。这周轮到你报。」",
            "dialog.m003.enter_hall": "站这边。别低着头——东家看的是人，不只是数。",
            "dialog.m003.report_choice": "林瑞生，你这周差事办得怎样？自己说。",
            "dialog.m003.choice.honest": "如实报账，不夸大",
            "dialog.m003.choice.polish": "报喜不报忧",
            "dialog.m003.choice.hold": "留一手，只说东家该听的",
            "dialog.m003.report_a": "回东家，货单两处差错已改，前堂值更没断。银钱进出，都在账上。",
            "dialog.m003.report_b": "回东家，这周诸事顺当，街面也没出岔子。",
            "dialog.m003.report_c": "回东家，明面的我都办妥了。有些风声……回头单独回。",
            "dialog.m003.policy": "嗯。外场的人，嘴要稳，腿要勤。这周方针——先把差事立住。",
            "dialog.m003.tasks": "外场差事：街面盯一轮，货单送清楚两趟。别砸了刚得的称呼。",
            "dialog.m003.close": "你走出前堂时，门帘在身后合上。这一回，堂里有你的位子了。",
            "council.zhou.order": "后院账房这几日按章走，货单别拖拉。谁要省事，最后省的是东家的脸。",
            "council.zhou.pass": "周管事目光一扫，没开口。",
            "council.wang.front_busy": "前堂这几日货来货往，人手紧。要再减人，怕误了客。",
            "council.wang.pass": "王胖子低头喝茶，没接话。",
            "council.zian.show": "我看街面上要摆排场，别老抠那几两银子。钱记的脸面，不能比聚丰矮一截。",
            "council.player.pick": "林外场，你也说说——这星期你怎么看？",
            "council.choice.speak": "建言",
            "council.choice.silent": "不言",
            "council.player.topic": "你要说哪一句？",
            "council.choice.steady": "稳明面，紧货单",
            "council.choice.market": "盯聚丰压价",
            "council.choice.look_away": "少问后院",
            "council.choice.risk": "直报货单不对（要胆）",
            "council.player.steady": "回东家，孙辈以为：明面货单先理清楚，比急着扩门面稳当。",
            "council.player.market": "回东家，聚丰那边近来压价，街面上眼多，得防一手。",
            "council.player.look_away": "回东家，后院的事，外场不便多问——先把明面稳住。",
            "council.player.risk": "回东家，货单上有两处对不上。我怕……不是笔误。",
            "council.player.pass": "……你退后半步，没接话。",
            "council.demao.nod": "嗯。",
            "council.demao.cut": "够了。这话到此为止。",
            "council.next": "建言轮过，东家要定调了。",
            "hud.tip.ladder.title": "【序位】同池明面排名，朝账③段按序升降",
            "hud.tip.ladder.rank": "当前：%d / %d",
            "hud.tip.ladder.pool": "池：%s",
            "hud.tip.meeting.title": "【朝账】每周晨会：汇报·赏罚·建言·摊派",
            "hud.tip.meeting.tier": "参与：%s",
            "hud.tip.meeting.days": "距下次：%d 日",
            "hud.tip.meeting.score": "本周汇报分：%d",
            "hud.tip.meeting.no_tasks": "本周差事：无",
        }
    )

    print("P16 meeting pack done.")


if __name__ == "__main__":
    main()
