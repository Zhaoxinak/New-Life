# -*- coding: utf-8 -*-
"""P4: E022*/E018 finale + E010–E013 discovery stubs."""
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
    # Discovery stubs
    {
        "event_id": "E010", "loc_key": "event.e010.name", "dialog_entry": "dialog_e010_start",
        "mutex_group": "chapter2.night_cargo", "route_tags": [],
        "require": [
            {"key": "stat_intel", "op": ">=", "value": 8},
            {"flag": "flag_day3_ignored", "value": False},
        ],
        "effects": [], "effects_when": "dialog",
    },
    {
        "event_id": "E010b", "loc_key": "event.e010b.name", "dialog_entry": "dialog_e010b_start",
        "mutex_group": "chapter2.night_cargo", "route_tags": [],
        "require": [{"flag": "flag_e010_delayed", "value": True}],
        "effects": [], "effects_when": "dialog",
    },
    {
        "event_id": "E011", "loc_key": "event.e011.name", "dialog_entry": "dialog_e011_start",
        "mutex_group": "", "route_tags": ["route_foreign"],
        "require": [{"flag": "flag_know_bradley_scouting", "value": True}],
        "effects": [], "effects_when": "dialog",
    },
    {
        "event_id": "E012", "loc_key": "event.e012.name", "dialog_entry": "dialog_e012_start",
        "mutex_group": "", "route_tags": [],
        "require": [{"flag": "flag_endure_preview", "value": True}],
        "effects": [], "effects_when": "dialog",
    },
    {
        "event_id": "E013", "loc_key": "event.e013.name", "dialog_entry": "dialog_e013_start",
        "mutex_group": "", "route_tags": [],
        "require": [
            {"key": "stat_intel", "op": ">=", "value": 18},
            {"or": [
                {"clue": "clue_light_crate", "owned": True},
                {"clue": "clue_suspicious_manifest", "owned": True},
            ]},
        ],
        "effects": [], "effects_when": "dialog",
    },
    # Finale
    {
        "event_id": "E022", "loc_key": "event.e022.name", "dialog_entry": "dialog_e022_start",
        "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_endure"],
        "require": [
            {"grudge": "grudge_zian_fiancee", "status": "open"},
            {"rank_in": ["waichang", "paojie"]},
            {"flag": "flag_e020b_done", "value": False},
            {"flag": "flag_e020c_done", "value": False},
        ],
        "effects": [], "effects_when": "dialog",
    },
    {
        "event_id": "E022B", "loc_key": "event.e022b.name", "dialog_entry": "dialog_e022b_start",
        "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_defect"],
        "require": [
            {"grudge": "grudge_zian_fiancee", "status": "open"},
            {"or": [
                {"flag": "flag_e020b_done", "value": True},
                {"flag": "flag_jufeng_offer_open", "value": True},
            ]},
            {"flag": "flag_e020c_done", "value": False},
        ],
        "effects": [], "effects_when": "dialog",
    },
    {
        "event_id": "E022C", "loc_key": "event.e022c.name", "dialog_entry": "dialog_e022c_start",
        "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_foreign"],
        "require": [
            {"grudge": "grudge_zian_fiancee", "status": "open"},
            {"or": [
                {"flag": "flag_e020c_done", "value": True},
                {"flag": "flag_foreign_door_known", "value": True},
            ]},
            {"flag": "flag_e020b_done", "value": False},
        ],
        "effects": [], "effects_when": "dialog",
    },
    {
        "event_id": "E018", "loc_key": "event.e018.name", "dialog_entry": "dialog_e018_start",
        "mutex_group": "chapter3.finale", "route_tags": ["route_endure", "route_defect", "route_foreign"],
        "require": [
            {"or": [
                {"flag": "flag_e022_done", "value": True},
                {"flag": "flag_e022b_done", "value": True},
                {"flag": "flag_e022c_done", "value": True},
                {"flag": "flag_marriage_agency_reclaimed", "value": True},
            ]},
        ],
        "effects": [], "effects_when": "dialog",
    },
]

# Discovery not on main compressed calendar (optional); finale days 11–12
CAL = [
    {"day": 11, "slot": "afternoon", "event_id": "E022", "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_endure"], "require": []},
    {"day": 11, "slot": "afternoon", "event_id": "E022B", "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_defect"], "require": []},
    {"day": 11, "slot": "afternoon", "event_id": "E022C", "mutex_group": "chapter3.main_reckoning", "route_tags": ["route_foreign"], "require": []},
    {"day": 12, "slot": "morning", "event_id": "E018", "mutex_group": "chapter3.finale", "require": []},
]

E022_PUNISH = [
    {"op": "resolve_grudge", "id": "grudge_zian_fiancee", "mode": "punish"},
    {"op": "add", "meter": "pursuit", "value": -30},
    {"op": "add", "edge": {"from": "char_qian_zian", "to": "char_lin_ruisheng"}, "key": "score", "value": -20},
    {"op": "add", "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"}, "key": "score", "value": 5},
    {"op": "add", "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "key": "score", "value": 10},
    {"op": "add", "meter": "father_son", "value": -10},
    {"op": "set_flag", "key": "flag_marriage_agency_reclaimed", "value": True},
    {"op": "set_flag", "key": "flag_e022_done", "value": True},
    {"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "punish", "if_open": True},
]
E022_FORGIVE = [
    {"op": "resolve_grudge", "id": "grudge_zian_fiancee", "mode": "forgive"},
    {"op": "add", "meter": "pursuit", "value": -20},
    {"op": "set", "edge": {"from": "char_lin_ruisheng", "to": "char_qian_zian"}, "key": "leverage", "value": "婚事上被你放过一次"},
    {"op": "add", "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"}, "key": "score", "value": 10},
    {"op": "add", "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "key": "score", "value": 8},
    {"op": "add", "key": "stat_network", "value": 8},
    {"op": "set_flag", "key": "flag_marriage_agency_reclaimed", "value": True},
    {"op": "set_flag", "key": "flag_e022_done", "value": True},
    {"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "forgive", "if_open": True},
]

DIALOGS = []

# --- Discovery stubs ---
DIALOGS += [
    {"dialog_id": "dialog_e010_start", "event_id": "E010", "speaker": "narrator", "loc_key": "dialog.e010.start", "next": "dialog_e010_choice"},
    {"dialog_id": "dialog_e010_choice", "event_id": "E010", "speaker": "narrator", "loc_key": "dialog.e010.choice", "choices": [
        {"id": "A", "loc_key": "dialog.e010.choice.a", "effects": [
            {"op": "add", "key": "stat_intel", "value": 10},
            {"op": "add", "key": "stat_suspicion", "value": 5},
            {"op": "unlock_clue", "id": "clue_light_crate"},
        ], "next": "dialog_e010_outro_a"},
        {"id": "B", "loc_key": "dialog.e010.choice.b", "effects": [
            {"op": "add", "key": "stat_intel", "value": 8},
            {"op": "add", "key": "stat_suspicion", "value": 10},
            {"op": "unlock_clue", "id": "clue_light_crate", "quality": "partial"},
        ], "next": "dialog_e010_outro_b"},
        {"id": "C", "loc_key": "dialog.e010.choice.c", "effects": [
            {"op": "add", "key": "stat_intel", "value": 3},
            {"op": "set_flag", "key": "flag_e010_delayed", "value": True},
        ], "next": "dialog_e010_outro_c"},
    ]},
    {"dialog_id": "dialog_e010_outro_a", "speaker": "narrator", "loc_key": "dialog.e010.outro.a", "next": ""},
    {"dialog_id": "dialog_e010_outro_b", "speaker": "narrator", "loc_key": "dialog.e010.outro.b", "next": ""},
    {"dialog_id": "dialog_e010_outro_c", "speaker": "narrator", "loc_key": "dialog.e010.outro.c", "next": ""},
    {"dialog_id": "dialog_e010b_start", "event_id": "E010b", "speaker": "narrator", "loc_key": "dialog.e010b.start", "next": "dialog_e010b_choice"},
    {"dialog_id": "dialog_e010b_choice", "event_id": "E010b", "speaker": "narrator", "loc_key": "dialog.e010b.choice", "choices": [
        {"id": "A", "loc_key": "dialog.e010.choice.a", "effects": [
            {"op": "add", "key": "stat_intel", "value": 10},
            {"op": "unlock_clue", "id": "clue_light_crate"},
            {"op": "set_flag", "key": "flag_e010_delayed", "value": False},
        ], "next": "dialog_e010_outro_a"},
        {"id": "B", "loc_key": "dialog.e010.choice.b", "effects": [
            {"op": "add", "key": "stat_intel", "value": 8},
            {"op": "unlock_clue", "id": "clue_light_crate", "quality": "partial"},
            {"op": "set_flag", "key": "flag_e010_delayed", "value": False},
        ], "next": "dialog_e010_outro_b"},
    ]},
    {"dialog_id": "dialog_e011_start", "event_id": "E011", "speaker": "narrator", "loc_key": "dialog.e011.start", "next": "dialog_e011_choice"},
    {"dialog_id": "dialog_e011_choice", "event_id": "E011", "speaker": "narrator", "loc_key": "dialog.e011.choice", "choices": [
        {"id": "A", "loc_key": "dialog.e011.choice.a", "effects": [
            {"op": "add", "key": "stat_intel", "value": 5},
            {"op": "add", "meter": "impression_bradley", "value": 15},
            {"op": "set_flag", "key": "flag_saw_bradley_spy", "value": True},
        ], "next": "dialog_e011_outro"},
        {"id": "B", "loc_key": "dialog.e011.choice.b", "effects": [
            {"op": "add", "key": "stat_intel", "value": 8},
            {"op": "set_flag", "key": "flag_saw_bradley_spy", "value": True},
        ], "next": "dialog_e011_outro"},
    ]},
    {"dialog_id": "dialog_e011_outro", "speaker": "narrator", "loc_key": "dialog.e011.outro", "next": ""},
    {"dialog_id": "dialog_e012_start", "event_id": "E012", "speaker": "narrator", "loc_key": "dialog.e012.start", "next": "dialog_e012_choice"},
    {"dialog_id": "dialog_e012_choice", "event_id": "E012", "speaker": "narrator", "loc_key": "dialog.e012.choice", "choices": [
        {"id": "A", "loc_key": "dialog.e012.choice.a", "effects": [
            {"op": "add", "key": "stat_intel", "value": 15},
            {"op": "set_flag", "key": "flag_liu_spy", "value": True},
        ], "next": "dialog_e012_outro"},
        {"id": "B", "loc_key": "dialog.e012.choice.b", "effects": [
            {"op": "add", "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "key": "score", "value": 10},
            {"op": "add", "meter": "pursuit", "value": 5},
            {"op": "set_flag", "key": "flag_liu_channel_closed", "value": True},
        ], "next": "dialog_e012_outro"},
    ]},
    {"dialog_id": "dialog_e012_outro", "speaker": "narrator", "loc_key": "dialog.e012.outro", "next": ""},
    {"dialog_id": "dialog_e013_start", "event_id": "E013", "speaker": "narrator", "loc_key": "dialog.e013.start", "next": "dialog_e013_choice"},
    {"dialog_id": "dialog_e013_choice", "event_id": "E013", "speaker": "narrator", "loc_key": "dialog.e013.choice", "choices": [
        {"id": "A", "loc_key": "dialog.e013.choice.a", "effects": [
            {"op": "add", "key": "stat_intel", "value": 15},
            {"op": "add", "key": "stat_suspicion", "value": 5},
            {"op": "unlock_clue", "id": "clue_special_goods"},
        ], "next": "dialog_e013_outro"},
        {"id": "B", "loc_key": "dialog.e013.choice.b", "effects": [
            {"op": "add", "key": "stat_intel", "value": 20},
            {"op": "add", "key": "stat_suspicion", "value": 15},
            {"op": "unlock_clue", "id": "clue_special_goods", "quality": "physical"},
            {"op": "set_flag", "key": "flag_ledger_stolen", "value": True},
        ], "next": "dialog_e013_outro"},
    ]},
    {"dialog_id": "dialog_e013_outro", "speaker": "narrator", "loc_key": "dialog.e013.outro", "next": ""},
]


def add_e022_family(prefix: str, eid: str, punish_fx, forgive_fx, start_loc, setup_loc, choice_loc, a_loc, b_loc, pun_loc, forg_loc):
    flash = f"dialog_{prefix}_flash"
    setup = f"dialog_{prefix}_setup"
    choice = f"dialog_{prefix}_choice"
    out_a = f"dialog_{prefix}_punish"
    out_b = f"dialog_{prefix}_forgive"
    DIALOGS.append({"dialog_id": f"dialog_{prefix}_start", "event_id": eid, "speaker": "narrator", "loc_key": start_loc, "next": flash})
    DIALOGS.append({"dialog_id": flash, "speaker": "narrator", "loc_key": "dialog.grudge.zian_fiancee.flash", "tags": ["flashback"], "next": setup})
    DIALOGS.append({"dialog_id": setup, "speaker": "narrator", "loc_key": setup_loc, "next": choice})
    DIALOGS.append({
        "dialog_id": choice, "event_id": eid, "speaker": "narrator", "loc_key": choice_loc,
        "choices": [
            {"id": "A", "loc_key": a_loc, "effects": punish_fx, "next": out_a},
            {"id": "B", "loc_key": b_loc, "effects": forgive_fx, "next": out_b},
        ],
    })
    DIALOGS.append({"dialog_id": out_a, "speaker": "narrator", "loc_key": pun_loc, "next": ""})
    DIALOGS.append({"dialog_id": out_b, "speaker": "narrator", "loc_key": forg_loc, "next": ""})


E022B_PUNISH = [
    {"op": "resolve_grudge", "id": "grudge_zian_fiancee", "mode": "punish"},
    {"op": "add", "meter": "pursuit", "value": -30},
    {"op": "add", "edge": {"from": "char_qian_zian", "to": "char_lin_ruisheng"}, "key": "score", "value": -20},
    {"op": "add", "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "key": "score", "value": 10},
    {"op": "add", "key": "stat_credit_market", "value": 8},
    {"op": "set_flag", "key": "flag_marriage_agency_reclaimed", "value": True},
    {"op": "set_flag", "key": "flag_e022b_done", "value": True},
    {"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "punish", "if_open": True},
]
E022B_FORGIVE = [
    {"op": "resolve_grudge", "id": "grudge_zian_fiancee", "mode": "forgive"},
    {"op": "add", "meter": "pursuit", "value": -20},
    {"op": "set", "edge": {"from": "char_lin_ruisheng", "to": "char_qian_zian"}, "key": "leverage", "value": "截胡当面放过一次"},
    {"op": "add", "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "key": "score", "value": 8},
    {"op": "add", "key": "stat_network", "value": 8},
    {"op": "set_flag", "key": "flag_marriage_agency_reclaimed", "value": True},
    {"op": "set_flag", "key": "flag_e022b_done", "value": True},
    {"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "forgive", "if_open": True},
]
E022C_PUNISH = [
    {"op": "resolve_grudge", "id": "grudge_zian_fiancee", "mode": "punish"},
    {"op": "add", "meter": "pursuit", "value": -30},
    {"op": "add", "edge": {"from": "char_qian_zian", "to": "char_lin_ruisheng"}, "key": "score", "value": -25},
    {"op": "add", "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "key": "score", "value": 8},
    {"op": "add", "key": "stat_suspicion", "value": 8},
    {"op": "add", "key": "stat_credit_foreign", "value": 5},
    {"op": "set_flag", "key": "flag_marriage_agency_reclaimed", "value": True},
    {"op": "set_flag", "key": "flag_e022c_done", "value": True},
    {"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "punish", "if_open": True},
]
E022C_FORGIVE = [
    {"op": "resolve_grudge", "id": "grudge_zian_fiancee", "mode": "forgive"},
    {"op": "add", "meter": "pursuit", "value": -20},
    {"op": "set", "edge": {"from": "char_lin_ruisheng", "to": "char_qian_zian"}, "key": "leverage", "value": "洋势压场后又收手"},
    {"op": "add", "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"}, "key": "score", "value": 5},
    {"op": "add", "key": "stat_network", "value": 6},
    {"op": "set_flag", "key": "flag_marriage_agency_reclaimed", "value": True},
    {"op": "set_flag", "key": "flag_e022c_done", "value": True},
    {"op": "resolve_grudge", "id": "grudge_zian_slight", "mode": "forgive", "if_open": True},
]

add_e022_family("e022", "E022", E022_PUNISH, E022_FORGIVE,
                "dialog.e022.start", "dialog.e022.setup", "dialog.e022.choice",
                "dialog.e022.choice.a", "dialog.e022.choice.b",
                "dialog.e022.punish", "dialog.e022.forgive")
add_e022_family("e022b", "E022B", E022B_PUNISH, E022B_FORGIVE,
                "dialog.e022b.start", "dialog.e022b.setup", "dialog.e022b.choice",
                "dialog.e022b.choice.a", "dialog.e022b.choice.b",
                "dialog.e022b.punish", "dialog.e022b.forgive")
add_e022_family("e022c", "E022C", E022C_PUNISH, E022C_FORGIVE,
                "dialog.e022c.start", "dialog.e022c.setup", "dialog.e022c.choice",
                "dialog.e022c.choice.a", "dialog.e022c.choice.b",
                "dialog.e022c.punish", "dialog.e022c.forgive")

# E018
DIALOGS += [
    {
        "dialog_id": "dialog_e018_start", "event_id": "E018", "speaker": "narrator", "loc_key": "dialog.e018.start",
        "next_by_condition": [
            {"require": [{"flag": "flag_fired", "value": True}], "id": "dialog_e018_fail_fired"},
            {"require": [{"flag": "flag_purged", "value": True}], "id": "dialog_e018_fail_purged"},
            {"require": [{"flag": "flag_liu_betrayed", "value": True}], "id": "dialog_e018_fail_liu"},
            {"require": [{"or": [
                {"key": "stat_suspicion", "op": ">=", "value": 100},
                {"key": "stat_trust_firm", "op": "<=", "value": 0},
            ]}], "id": "dialog_e018_fail_stats"},
            {"require": [
                {"flag": "route_endure", "value": True},
                {"key": "stat_trust_firm", "op": ">=", "value": 50},
                {"key": "stat_intel", "op": ">=", "value": 35},
            ], "id": "dialog_e018_a_narr"},
            {"require": [
                {"flag": "route_defect", "value": True},
                {"key": "stat_network", "op": ">=", "value": 35},
            ], "id": "dialog_e018_b_narr"},
            {"require": [
                {"flag": "route_foreign", "value": True},
                {"or": [
                    {"flag": "flag_ending_c_ready", "value": True},
                    {"flag": "flag_foreign_door_known", "value": True},
                ]},
            ], "id": "dialog_e018_c_narr"},
            {"default": "dialog_e018_fail_stats"},
        ],
    },
    {"dialog_id": "dialog_e018_a_narr", "speaker": "narrator", "loc_key": "dialog.e018.a.narr", "next": "dialog_e018_a_qian"},
    {"dialog_id": "dialog_e018_a_qian", "speaker": "char_qian_demao", "loc_key": "dialog.e018.a.qian", "next": "dialog_e018_a_demao"},
    {
        "dialog_id": "dialog_e018_a_demao", "speaker": "narrator", "loc_key": "dialog.e018.a.demao_grudge",
        "next_by_condition": [
            {"require": [{"grudge": "grudge_demao_defer", "status": "open"}], "id": "dialog_e018_a_demao_choice"},
            {"default": "dialog_e018_a_title"},
        ],
    },
    {"dialog_id": "dialog_e018_a_demao_choice", "speaker": "narrator", "loc_key": "dialog.e018.a.demao_grudge", "choices": [
        {"id": "A", "loc_key": "dialog.e018.a.demao.punish", "effects": [
            {"op": "resolve_grudge", "id": "grudge_demao_defer", "mode": "punish"},
        ], "next": "dialog_e018_a_title"},
        {"id": "B", "loc_key": "dialog.e018.a.demao.forgive", "effects": [
            {"op": "resolve_grudge", "id": "grudge_demao_defer", "mode": "forgive"},
            {"op": "set", "edge": {"from": "char_lin_ruisheng", "to": "char_qian_demao"}, "key": "leverage", "value": "东家欠你一个满师"},
        ], "next": "dialog_e018_a_title"},
    ]},
    {"dialog_id": "dialog_e018_a_title", "speaker": "narrator", "loc_key": "dialog.e018.a.title", "effects": [
        {"op": "set_rank", "value": "paojie"},
        {"op": "add", "key": "stat_money", "value": 5},
        {"op": "add", "key": "stat_trust_firm", "value": 10},
        {"op": "set_flag", "key": "flag_ending_a", "value": True},
        {"op": "set_flag", "key": "flag_houtang_door_ajar", "value": True},
    ], "next": "dialog_e018_a_close"},
    {"dialog_id": "dialog_e018_a_close", "speaker": "narrator", "loc_key": "dialog.e018.a.close", "next": ""},
    {"dialog_id": "dialog_e018_b_narr", "speaker": "narrator", "loc_key": "dialog.e018.b.narr", "next": "dialog_e018_b_zhao"},
    {"dialog_id": "dialog_e018_b_zhao", "speaker": "char_zhao_hongyun", "loc_key": "dialog.e018.b.zhao", "next": "dialog_e018_b_title"},
    {"dialog_id": "dialog_e018_b_title", "speaker": "narrator", "loc_key": "dialog.e018.b.title", "effects": [
        {"op": "set_flag", "key": "flag_rank_jufeng_paojie", "value": True},
        {"op": "add", "key": "stat_money", "value": 10},
        {"op": "add", "key": "stat_credit_market", "value": 15},
        {"op": "set_flag", "key": "flag_ending_b", "value": True},
    ], "next": "dialog_e018_b_close"},
    {"dialog_id": "dialog_e018_b_close", "speaker": "narrator", "loc_key": "dialog.e018.b.close", "next": ""},
    {"dialog_id": "dialog_e018_c_narr", "speaker": "narrator", "loc_key": "dialog.e018.c.narr", "next": "dialog_e018_c_bradley"},
    {"dialog_id": "dialog_e018_c_bradley", "speaker": "char_bradley", "loc_key": "dialog.e018.c.bradley", "next": "dialog_e018_c_close"},
    {"dialog_id": "dialog_e018_c_close", "speaker": "narrator", "loc_key": "dialog.e018.c.close", "effects": [
        {"op": "set_flag", "key": "flag_rank_foreign_agent", "value": True},
        {"op": "add", "key": "stat_money", "value": 20},
        {"op": "add", "key": "stat_credit_foreign", "value": 20},
        {"op": "set_flag", "key": "flag_ending_c", "value": True},
    ], "next": ""},
    {"dialog_id": "dialog_e018_fail_fired", "speaker": "narrator", "loc_key": "dialog.e018.fail.fired", "effects": [{"op": "set_flag", "key": "flag_ending_fail", "value": True}], "next": ""},
    {"dialog_id": "dialog_e018_fail_purged", "speaker": "narrator", "loc_key": "dialog.e018.fail.purged", "effects": [{"op": "set_flag", "key": "flag_ending_fail", "value": True}], "next": ""},
    {"dialog_id": "dialog_e018_fail_liu", "speaker": "narrator", "loc_key": "dialog.e018.fail.liu", "effects": [{"op": "set_flag", "key": "flag_ending_fail", "value": True}], "next": ""},
    {"dialog_id": "dialog_e018_fail_stats", "speaker": "narrator", "loc_key": "dialog.e018.fail.stats", "effects": [{"op": "set_flag", "key": "flag_ending_fail", "value": True}], "next": ""},
]

LOC = {
    "ui.ending_reached": "阶段性结局已达成：%s",
    "event.e010.name": "深夜可疑货物",
    "event.e010b.name": "深夜可疑货物·推迟",
    "event.e011.name": "洋行第二次考察",
    "event.e012.name": "利用柳如烟",
    "event.e013.name": "账房密账",
    "event.e022.name": "清算子安",
    "event.e022b.name": "清算子安·截胡",
    "event.e022c.name": "清算子安·借势",
    "event.e018.name": "阶段性结局",
    "dialog.e010.start": "深夜卸「南洋木器」。箱子轻得出奇，东家守着暗道。",
    "dialog.e010.choice": "（你怎么做？）",
    "dialog.e010.choice.a": "跟上去看清楚",
    "dialog.e010.choice.b": "远远记下，不靠近",
    "dialog.e010.choice.c": "先走开，改天再说",
    "dialog.e010.outro.a": "你摸到箱子的重量——里面不像木头。",
    "dialog.e010.outro.b": "你把夜里的人影与箱数，压进心里。",
    "dialog.e010.outro.c": "你离开了。那批货还会再来。",
    "dialog.e010b.start": "又是同批货——不能再走开。",
    "dialog.e010b.choice": "（你怎么做？）",
    "dialog.e011.start": "白瑞德再访。随从抄挂牌，目光不在古董上。",
    "dialog.e011.choice": "（你怎么做？）",
    "dialog.e011.choice.a": "再搭一句，加深印象",
    "dialog.e011.choice.b": "盯住那个抄牌的随从",
    "dialog.e011.outro": "洋行的第二次来访，把门路又往前推了一寸。",
    "dialog.e012.start": "如烟袖口攥着新布边——送礼已经变成价码。",
    "dialog.e012.choice": "（你怎么做？）",
    "dialog.e012.choice.a": "让她帮忙打听",
    "dialog.e012.choice.b": "护住她，切断通道",
    "dialog.e012.outro": "人情与把柄，从来缠在同一根线里。",
    "dialog.e013.start": "暗格无字账：「特别货」八十进三百出；末页还有庆大人月奉。",
    "dialog.e013.choice": "（你怎么做？）",
    "dialog.e013.choice.a": "抄关键几页",
    "dialog.e013.choice.b": "整本偷走",
    "dialog.e013.outro": "账本上的数，比拳头更沉。",
    "dialog.grudge.zian_fiancee.flash": "（闪回）赤金镯摊在桌上。如烟说：钱家势力我们惹不起。",
    "dialog.e022.start": "前堂为账和脸面闹翻。有些话，今天说才够分量。",
    "dialog.e022.setup": "德茂、子安、伙计都在。你站在外场该站的位子上。",
    "dialog.e022.choice": "（婚事这桩债，怎么收？）",
    "dialog.e022.choice.a": "惩罚——当众钉死定亲，让子安丢脸",
    "dialog.e022.choice.b": "宽恕——放过他，但钉死如烟是我的人",
    "dialog.e022.punish": "「如烟与我定亲三年。金镯请收回。」前堂静了；婚事主动权回到你嘴里。",
    "dialog.e022.forgive": "你能杀却收刀，只请东家一句：商行不夺姻缘。看客敬「能收住」的人。",
    "dialog.e022b.start": "街面火药味。聚丰盯货，子安找脸。",
    "dialog.e022b.setup": "子安想拿生意压你。看客看谁拿住人与单。",
    "dialog.e022b.choice": "（你怎么做？）",
    "dialog.e022b.choice.a": "惩罚——截胡掀脸",
    "dialog.e022b.choice.b": "宽恕——留场面话，婚事钉死",
    "dialog.e022b.punish": "货价、婚事、荒唐话一并摊开；买卖话头丢了。",
    "dialog.e022b.forgive": "买卖归买卖，姻缘归姻缘。你能截单，也能收刀。",
    "dialog.e022c.start": "洋行的门、庆系的手书，要勒住子安的气。",
    "dialog.e022c.setup": "你背后不只是前堂。看客只知你更不好惹。",
    "dialog.e022c.choice": "（你怎么做？）",
    "dialog.e022c.choice.a": "惩罚——借势压场",
    "dialog.e022c.choice.b": "宽恕——亮势收刀，婚事拿回就够",
    "dialog.e022c.punish": "半句洋势够了。脏胜仗夺回婚事主动权。",
    "dialog.e022c.forgive": "能掀翻却只拿该拿的。旁人知你能借势，不滥用。",
    "dialog.e018.start": "光绪十六年的秋天，到了结账的日子。",
    "dialog.e018.a.narr": "德茂疑子安吞货款；父子吵翻；不得不倚重你。",
    "dialog.e018.a.qian": "跑街明天给你。月例提上，应酬账归你。",
    "dialog.e018.a.demao_grudge": "（闪回暂缓）这账——撕开，还是接住？",
    "dialog.e018.a.demao.punish": "惩罚——请东家把「迟早」说成当着众人的话",
    "dialog.e018.a.demao.forgive": "宽恕——接权，不撕破脸",
    "dialog.e018.a.title": "背后第一次有人叫：「林跑街。」",
    "dialog.e018.a.close": "后堂的门缝开了一线。暗潮才刚刚涌动。",
    "dialog.e018.b.narr": "带着客户名单敲开聚丰侧门。",
    "dialog.e018.b.zhao": "你是聚丰跑街，月薪五两；先截钱记那单。",
    "dialog.e018.b.title": "称呼明明白白在另一家门脸给出来。",
    "dialog.e018.b.close": "暗潮换了岸，水一样深。",
    "dialog.e018.c.narr": "白瑞德在宝顺正式会谈。",
    "dialog.e018.c.bradley": "这封信比十箱古董值钱。开价吧。",
    "dialog.e018.c.close": "天津新代理人。暗潮之下，没有干净的手。",
    "dialog.e018.fail.fired": "朱红大门关上。多了一个没人记得的人。",
    "dialog.e018.fail.purged": "离津上船。洗不掉被清除的人。",
    "dialog.e018.fail.liu": "枕边风翻面。厂门口没人叫你名字。",
    "dialog.e018.fail.stats": "嫌疑压垮信任。暗潮把你拍在岸上。",
    "fb.zian_fiancee": "（闪回）赤金镯摊在桌上。如烟说：钱家势力我们惹不起。",
    "clue.light_crate": "轻箱",
    "clue.special_goods": "特别货",
}

CLUES = [
    {"clue_id": "clue_suspicious_manifest", "loc_key": "clue.suspicious_manifest", "arc": "opium"},
    {"clue_id": "clue_light_crate", "loc_key": "clue.light_crate", "arc": "opium"},
    {"clue_id": "clue_special_goods", "loc_key": "clue.special_goods", "arc": "opium"},
]


def main() -> None:
    upsert_rows("def_event.json", "event_id", EVENTS)
    upsert_rows("def_dialog.json", "dialog_id", DIALOGS)
    upsert_rows("def_clue.json", "clue_id", CLUES)

    cal = load("def_calendar.json")
    rows = cal["rows"]
    existing = {(int(r["day"]), r["slot"], r["event_id"]) for r in rows}
    for c in CAL:
        key = (c["day"], c["slot"], c["event_id"])
        if key not in existing:
            rows.append(c)
    save("def_calendar.json", {"rows": rows})

    grudges = load("def_grudge.json")
    for g in grudges["rows"]:
        if g["grudge_id"] == "grudge_zian_fiancee":
            g["flashback_key"] = "dialog.grudge.zian_fiancee.flash"
    save("def_grudge.json", grudges)

    l10n = load("l10n/zh_CN.json")
    l10n.setdefault("zh_CN", {}).update(LOC)
    save("l10n/zh_CN.json", l10n)

    reg = load("registry/events.json")
    have = {e["event_id"] for e in reg.get("events", [])}
    for ev in EVENTS:
        if ev["event_id"] not in have:
            reg["events"].append({
                "event_id": ev["event_id"],
                "chapter": 3 if ev["event_id"].startswith("E0") and int(ev["event_id"][1:3]) >= 18 else 2,
                "event_type": "ending" if ev["event_id"] == "E018" else ("mainline_variant" if ev.get("mutex_group") else "mainline"),
                "dialog_entry": ev["dialog_entry"],
                "mutex_group": ev.get("mutex_group", ""),
                "route_tags": ev.get("route_tags", []),
                "status": "active",
            })
    save("registry/events.json", reg)

    pack = load("pack.json")
    pack["content_version"] = "0.5.0-p4"
    save("pack.json", pack)
    print("dialogs", len(DIALOGS), "events", len(EVENTS))


if __name__ == "__main__":
    main()
