# -*- coding: utf-8 -*-
"""One-shot generator for P2 chapter-1 packs. Run from repo root:
python game/tools/gen_p2_packs.py
"""
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "packs" / "anchao"


def dump(name: str, data: dict) -> None:
    path = ROOT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("wrote", path.relative_to(ROOT.parent.parent))


EVENTS = [
    {"event_id": "E001", "loc_key": "event.e001.name", "dialog_entry": "dialog_e001_start", "effects_when": "dialog", "require": [], "effects": []},
    {"event_id": "E002", "loc_key": "event.e002.name", "dialog_entry": "dialog_e002_start", "effects_when": "dialog", "require": [], "effects": []},
    {"event_id": "E003", "loc_key": "event.e003.name", "dialog_entry": "dialog_e003_start", "effects_when": "dialog", "require": [], "effects": []},
    {"event_id": "E004", "loc_key": "event.e004.name", "dialog_entry": "dialog_e004_start", "effects_when": "dialog", "require": [], "effects": []},
    {"event_id": "E005", "loc_key": "event.e005.name", "dialog_entry": "dialog_e005_start", "effects_when": "dialog", "require": [], "effects": []},
    {"event_id": "E006", "loc_key": "event.e006.name", "dialog_entry": "dialog_e006_start", "effects_when": "dialog", "require": [], "effects": []},
    {"event_id": "E007", "loc_key": "event.e007.name", "dialog_entry": "dialog_e007_start", "effects_when": "dialog", "require": [], "effects": []},
    {"event_id": "E008", "loc_key": "event.e008.name", "dialog_entry": "dialog_e008_start", "effects_when": "dialog", "require": [], "effects": []},
    {"event_id": "E009", "loc_key": "event.e009.name", "dialog_entry": "dialog_e009_start", "effects_when": "dialog", "require": [], "effects": []},
]

CALENDAR = [
    {"day": 1, "slot": "morning", "event_id": "E001", "require": []},
    {"day": 2, "slot": "evening", "event_id": "E002", "require": []},
    {"day": 3, "slot": "afternoon", "event_id": "E003", "require": []},
    {"day": 4, "slot": "morning", "event_id": "E004", "require": []},
    {"day": 4, "slot": "evening", "event_id": "E005", "require": []},
    {"day": 5, "slot": "morning", "event_id": "E006", "require": []},
    {"day": 5, "slot": "afternoon", "event_id": "E007", "require": []},
    {"day": 6, "slot": "evening", "event_id": "E008", "require": []},
    {"day": 7, "slot": "late_night", "event_id": "E009", "require": []},
]

DIALOGS = [
    # E001
    {"dialog_id": "dialog_e001_start", "event_id": "E001", "speaker": "narrator", "loc_key": "dialog.e001.start", "next": "dialog_e001_exam_q1"},
    {"dialog_id": "dialog_e001_exam_q1", "speaker": "char_qian_demao", "loc_key": "dialog.e001.exam.q1", "next": "dialog_e001_exam_a1"},
    {"dialog_id": "dialog_e001_exam_a1", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e001.exam.a1", "next": "dialog_e001_exam_q2"},
    {"dialog_id": "dialog_e001_exam_q2", "speaker": "char_qian_demao", "loc_key": "dialog.e001.exam.q2", "next": "dialog_e001_exam_a2"},
    {"dialog_id": "dialog_e001_exam_a2", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e001.exam.a2", "next": "dialog_e001_exam_praise"},
    {"dialog_id": "dialog_e001_exam_praise", "speaker": "char_qian_demao", "loc_key": "dialog.e001.exam.praise", "next": "dialog_e001_exam_hedge"},
    {"dialog_id": "dialog_e001_exam_hedge", "speaker": "char_qian_demao", "loc_key": "dialog.e001.exam.hedge", "next": "dialog_e001_exam_ack"},
    {"dialog_id": "dialog_e001_exam_ack", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e001.exam.ack", "next": "dialog_e001_exam_close"},
    {"dialog_id": "dialog_e001_exam_close", "speaker": "char_qian_demao", "loc_key": "dialog.e001.exam.close", "effects": [
        {"op": "add", "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"}, "key": "score", "value": 8},
        {"op": "add", "key": "stat_trust_firm", "value": 5},
    ], "next": ""},
    # E002
    {"dialog_id": "dialog_e002_start", "event_id": "E002", "speaker": "char_liu_ruyan", "loc_key": "dialog.e002.start", "next": "dialog_e002_lin_ask"},
    {"dialog_id": "dialog_e002_lin_ask", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e002.lin_ask", "next": "dialog_e002_liu_busy"},
    {"dialog_id": "dialog_e002_liu_busy", "speaker": "char_liu_ruyan", "loc_key": "dialog.e002.liu_busy", "next": "dialog_e002_lin_say"},
    {"dialog_id": "dialog_e002_lin_say", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e002.lin_say", "next": "dialog_e002_liu_wedding"},
    {"dialog_id": "dialog_e002_liu_wedding", "speaker": "char_liu_ruyan", "loc_key": "dialog.e002.liu_wedding", "next": "dialog_e002_lin_promise"},
    {"dialog_id": "dialog_e002_lin_promise", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e002.lin_promise", "next": "dialog_e002_liu_bright"},
    {"dialog_id": "dialog_e002_liu_bright", "speaker": "char_liu_ruyan", "loc_key": "dialog.e002.liu_bright", "next": "dialog_e002_lin_wait"},
    {"dialog_id": "dialog_e002_lin_wait", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e002.lin_wait", "next": "dialog_e002_liu_ok"},
    {"dialog_id": "dialog_e002_liu_ok", "speaker": "char_liu_ruyan", "loc_key": "dialog.e002.liu_ok", "effects": [
        {"op": "add", "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "key": "score", "value": 10},
        {"op": "set_flag", "key": "flag_need_marriage_fund", "value": True},
    ], "next": ""},
    # E003
    {"dialog_id": "dialog_e003_start", "event_id": "E003", "speaker": "narrator", "loc_key": "dialog.e003.start", "next": "dialog_e003_notice"},
    {"dialog_id": "dialog_e003_notice", "speaker": "narrator", "loc_key": "dialog.e003.notice", "next": "dialog_e003_math"},
    {"dialog_id": "dialog_e003_math", "speaker": "narrator", "loc_key": "dialog.e003.math", "next": "dialog_e003_choice"},
    {"dialog_id": "dialog_e003_choice", "event_id": "E003", "speaker": "narrator", "loc_key": "dialog.e003.choice_prompt", "choices": [
        {"id": "A", "loc_key": "dialog.e003.choice.a", "effects": [
            {"op": "add", "key": "stat_intel", "value": 5},
            {"op": "add", "key": "stat_suspicion", "value": 5},
            {"op": "unlock_clue", "id": "clue_suspicious_manifest"},
        ], "next": "dialog_e003_outro_a"},
        {"id": "B", "loc_key": "dialog.e003.choice.b", "effects": [
            {"op": "add", "key": "stat_intel", "value": 3},
            {"op": "unlock_clue", "id": "clue_suspicious_manifest", "quality": "partial"},
        ], "next": "dialog_e003_outro_b"},
        {"id": "C", "loc_key": "dialog.e003.choice.c", "effects": [
            {"op": "set_flag", "key": "flag_day3_ignored", "value": True},
        ], "next": "dialog_e003_outro_c"},
    ]},
    {"dialog_id": "dialog_e003_outro_a", "speaker": "narrator", "loc_key": "dialog.e003.outro.a", "next": ""},
    {"dialog_id": "dialog_e003_outro_b", "speaker": "narrator", "loc_key": "dialog.e003.outro.b", "next": ""},
    {"dialog_id": "dialog_e003_outro_c", "speaker": "narrator", "loc_key": "dialog.e003.outro.c", "next": ""},
    # E004
    {"dialog_id": "dialog_e004_start", "event_id": "E004", "speaker": "char_qian_demao", "loc_key": "dialog.e004.start", "next": "dialog_e004_zian"},
    {"dialog_id": "dialog_e004_zian", "speaker": "char_qian_zian", "loc_key": "dialog.e004.zian", "next": "dialog_e004_crowd"},
    {"dialog_id": "dialog_e004_crowd", "speaker": "narrator", "loc_key": "dialog.e004.crowd", "next": "dialog_e004_outro"},
    {"dialog_id": "dialog_e004_outro", "speaker": "narrator", "loc_key": "dialog.e004.outro", "effects": [
        {"op": "set_flag", "key": "flag_zian_arrived", "value": True},
        {"op": "unlock_grudge", "id": "grudge_zian_slight"},
    ], "next": ""},
    # E005
    {"dialog_id": "dialog_e005_start", "event_id": "E005", "speaker": "narrator", "loc_key": "dialog.e005.start", "next": "dialog_e005_notice"},
    {"dialog_id": "dialog_e005_notice", "speaker": "narrator", "loc_key": "dialog.e005.notice", "next": "dialog_e005_zian_ask"},
    {"dialog_id": "dialog_e005_zian_ask", "speaker": "char_qian_zian", "loc_key": "dialog.e005.zian_ask", "next": "dialog_e005_retainer"},
    {"dialog_id": "dialog_e005_retainer", "speaker": "narrator", "loc_key": "dialog.e005.retainer", "next": "dialog_e005_zian_hook"},
    {"dialog_id": "dialog_e005_zian_hook", "speaker": "char_qian_zian", "loc_key": "dialog.e005.zian_hook", "effects": [
        {"op": "add", "meter": "pursuit", "value": 5},
        {"op": "set_flag", "key": "flag_zian_notices_liu", "value": True},
        {"op": "add", "edge": {"from": "char_qian_zian", "to": "char_liu_ruyan"}, "key": "score", "value": 5},
    ], "next": ""},
    # E006
    {"dialog_id": "dialog_e006_start", "event_id": "E006", "speaker": "char_qian_demao", "loc_key": "dialog.e006.start", "next": "dialog_e006_narr"},
    {"dialog_id": "dialog_e006_narr", "speaker": "narrator", "loc_key": "dialog.e006.narr", "next": "dialog_e006_zian"},
    {"dialog_id": "dialog_e006_zian", "speaker": "char_qian_zian", "loc_key": "dialog.e006.zian", "next": "dialog_e006_lin"},
    {"dialog_id": "dialog_e006_lin", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e006.lin", "next": "dialog_e006_aside"},
    {"dialog_id": "dialog_e006_aside", "speaker": "narrator", "loc_key": "dialog.e006.aside", "next": "dialog_e006_qian_soft"},
    {"dialog_id": "dialog_e006_qian_soft", "speaker": "char_qian_demao", "loc_key": "dialog.e006.qian_soft", "effects": [
        {"op": "add", "key": "stat_trust_firm", "value": -10},
        {"op": "add", "edge": {"from": "char_lin_ruisheng", "to": "char_qian_demao"}, "key": "score", "value": -10},
        {"op": "unlock_grudge", "id": "grudge_demao_defer"},
    ], "next": ""},
    # E007
    {"dialog_id": "dialog_e007_start", "event_id": "E007", "speaker": "narrator", "loc_key": "dialog.e007.start", "next": "dialog_e007_bradley_greet"},
    {"dialog_id": "dialog_e007_bradley_greet", "speaker": "char_bradley", "loc_key": "dialog.e007.bradley_greet", "next": "dialog_e007_qian_reply"},
    {"dialog_id": "dialog_e007_qian_reply", "speaker": "char_qian_demao", "loc_key": "dialog.e007.qian_reply", "next": "dialog_e007_observe"},
    {"dialog_id": "dialog_e007_observe", "speaker": "narrator", "loc_key": "dialog.e007.observe", "next": "dialog_e007_choice"},
    {"dialog_id": "dialog_e007_choice", "event_id": "E007", "speaker": "narrator", "loc_key": "dialog.e007.choice_prompt", "choices": [
        {"id": "A", "loc_key": "dialog.e007.choice.a", "effects": [
            {"op": "add", "key": "stat_intel", "value": 5},
            {"op": "add", "meter": "impression_bradley", "value": 10},
            {"op": "add", "edge": {"from": "char_bradley", "to": "char_lin_ruisheng"}, "key": "score", "value": 10},
            {"op": "add", "key": "stat_trust_firm", "value": -5},
            {"op": "add", "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"}, "key": "suspicion", "value": 1},
            {"op": "add", "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"}, "key": "score", "value": -5},
            {"op": "set_flag", "key": "flag_know_bradley_scouting", "value": True},
        ], "next": "dialog_e007_outro_a"},
        {"id": "B", "loc_key": "dialog.e007.choice.b", "effects": [
            {"op": "add", "key": "stat_intel", "value": 3},
            {"op": "set_flag", "key": "flag_know_bradley_scouting", "value": True},
        ], "next": "dialog_e007_outro_b"},
        {"id": "C", "loc_key": "dialog.e007.choice.c", "check": {
            "require": {"key": "stat_intel", "op": ">=", "value": 10},
            "on_pass": {"effects": [
                {"op": "add", "key": "stat_intel", "value": 8},
                {"op": "set_flag", "key": "flag_know_bradley_scouting", "value": True},
                {"op": "set_flag", "key": "flag_heard_bradley_needs_comprador", "value": True},
            ], "next": "dialog_e007_outro_c_ok"},
            "on_fail": {"effects": [
                {"op": "add", "key": "stat_suspicion", "value": 10},
                {"op": "set_flag", "key": "flag_know_bradley_scouting", "value": True},
            ], "next": "dialog_e007_outro_c_fail"},
        }},
    ]},
    {"dialog_id": "dialog_e007_outro_a", "speaker": "narrator", "loc_key": "dialog.e007.outro.a", "next": ""},
    {"dialog_id": "dialog_e007_outro_b", "speaker": "narrator", "loc_key": "dialog.e007.outro.b", "next": ""},
    {"dialog_id": "dialog_e007_outro_c_ok", "speaker": "narrator", "loc_key": "dialog.e007.outro.c_ok", "next": ""},
    {"dialog_id": "dialog_e007_outro_c_fail", "speaker": "narrator", "loc_key": "dialog.e007.outro.c_fail", "next": ""},
    # E008
    {"dialog_id": "dialog_e008_start", "event_id": "E008", "speaker": "narrator", "loc_key": "dialog.e008.start", "next": "dialog_e008_lin_ask"},
    {"dialog_id": "dialog_e008_lin_ask", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e008.lin_ask", "next": "dialog_e008_liu_show"},
    {"dialog_id": "dialog_e008_liu_show", "speaker": "narrator", "loc_key": "dialog.e008.liu_show", "next": "dialog_e008_lin_shock"},
    {"dialog_id": "dialog_e008_lin_shock", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e008.lin_shock", "next": "dialog_e008_liu_explain"},
    {"dialog_id": "dialog_e008_liu_explain", "speaker": "char_liu_ruyan", "loc_key": "dialog.e008.liu_explain", "next": "dialog_e008_lin_rage"},
    {"dialog_id": "dialog_e008_lin_rage", "speaker": "char_lin_ruisheng", "loc_key": "dialog.e008.lin_rage", "next": "dialog_e008_liu_fear"},
    {"dialog_id": "dialog_e008_liu_fear", "speaker": "char_liu_ruyan", "loc_key": "dialog.e008.liu_fear", "next": "dialog_e008_choice"},
    {"dialog_id": "dialog_e008_choice", "event_id": "E008", "speaker": "narrator", "loc_key": "dialog.e008.choice_prompt", "choices": [
        {"id": "A", "loc_key": "dialog.e008.choice.a", "effects": [
            {"op": "add", "key": "stat_trust_firm", "value": -20},
            {"op": "add", "key": "stat_suspicion", "value": 10},
            {"op": "add", "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"}, "key": "score", "value": -15},
            {"op": "add", "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"}, "key": "suspicion", "value": 1},
            {"op": "set_flag", "key": "flag_need_marriage_fund", "value": True},
            {"op": "set_flag", "key": "flag_marked_restless", "value": True},
            {"op": "unlock_grudge", "id": "grudge_zian_fiancee"},
        ], "next": "dialog_e008_outro_a"},
        {"id": "B", "loc_key": "dialog.e008.choice.b", "effects": [
            {"op": "add", "key": "stat_intel", "value": 5},
            {"op": "add", "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "key": "score", "value": 5},
            {"op": "set_flag", "key": "flag_need_marriage_fund", "value": True},
            {"op": "set_flag", "key": "flag_endure_preview", "value": True},
            {"op": "unlock_grudge", "id": "grudge_zian_fiancee"},
        ], "next": "dialog_e008_outro_b"},
        {"id": "C", "loc_key": "dialog.e008.choice.c", "effects": [
            {"op": "add", "key": "stat_network", "value": 5},
            {"op": "add", "key": "stat_intel", "value": 10},
            {"op": "add", "key": "stat_credit_market", "value": 5},
            {"op": "set_flag", "key": "flag_need_marriage_fund", "value": True},
            {"op": "add", "edge": {"from": "char_zhao_hongyun", "to": "char_lin_ruisheng"}, "key": "score", "value": 5},
            {"op": "unlock_grudge", "id": "grudge_zian_fiancee"},
        ], "next": "dialog_e008_outro_c"},
    ]},
    {"dialog_id": "dialog_e008_outro_a", "speaker": "narrator", "loc_key": "dialog.e008.outro.a", "next": ""},
    {"dialog_id": "dialog_e008_outro_b", "speaker": "narrator", "loc_key": "dialog.e008.outro.b", "next": ""},
    {"dialog_id": "dialog_e008_outro_c", "speaker": "narrator", "loc_key": "dialog.e008.outro.c", "next": ""},
    # E009
    {"dialog_id": "dialog_e009_start", "event_id": "E009", "speaker": "narrator", "loc_key": "dialog.e009.start", "next": "dialog_e009_monologue"},
    {"dialog_id": "dialog_e009_monologue", "event_id": "E009", "speaker": "narrator", "loc_key": "dialog.e009.monologue", "next": "dialog_e009_choice"},
    {"dialog_id": "dialog_e009_choice", "event_id": "E009", "speaker": "narrator", "loc_key": "dialog.e009.choice_prompt", "choices": [
        {"id": "A", "loc_key": "dialog.e009.choice.a", "effects": [
            {"op": "set_flag", "key": "route_endure", "value": True},
            {"op": "add", "key": "stat_trust_firm", "value": 5},
            {"op": "add", "key": "stat_intel", "value": 5},
        ], "next": "dialog_e009_outro_a"},
        {"id": "B", "loc_key": "dialog.e009.choice.b", "effects": [
            {"op": "set_flag", "key": "route_defect", "value": True},
            {"op": "add", "key": "stat_network", "value": 10},
            {"op": "add", "key": "stat_trust_firm", "value": -5},
        ], "next": "dialog_e009_outro_b"},
        {"id": "C", "loc_key": "dialog.e009.choice.c", "effects": [
            {"op": "set_flag", "key": "route_foreign", "value": True},
            {"op": "add", "key": "stat_intel", "value": 10},
        ], "next": "dialog_e009_outro_c"},
    ]},
    {"dialog_id": "dialog_e009_outro_a", "speaker": "narrator", "loc_key": "dialog.e009.outro.a", "next": ""},
    {"dialog_id": "dialog_e009_outro_b", "speaker": "narrator", "loc_key": "dialog.e009.outro.b", "next": ""},
    {"dialog_id": "dialog_e009_outro_c", "speaker": "narrator", "loc_key": "dialog.e009.outro.c", "next": ""},
    # Action outros
    {"dialog_id": "dialog_act_01_outro_default", "speaker": "narrator", "loc_key": "dialog.act.01.outro.default", "next": ""},
    {"dialog_id": "dialog_act_01_outro_tight", "speaker": "narrator", "loc_key": "dialog.act.01.outro.tight", "next": ""},
    {"dialog_id": "dialog_act_02_outro_default", "speaker": "narrator", "loc_key": "dialog.act.02.outro.default", "next": ""},
    {"dialog_id": "dialog_act_03_outro_default", "speaker": "narrator", "loc_key": "dialog.act.03.outro.default", "next": ""},
    {"dialog_id": "dialog_act_03_outro_tight", "speaker": "narrator", "loc_key": "dialog.act.03.outro.tight", "next": ""},
    {"dialog_id": "dialog_act_03_outro_well", "speaker": "narrator", "loc_key": "dialog.act.03.outro.well", "next": ""},
]

LOC = {
    "zh_CN": {
        "ui.new_game": "新的一局",
        "ui.save": "存档",
        "ui.load": "读档",
        "ui.save_ok": "已保存",
        "ui.load_ok": "已读档",
        "ui.event_pending": "有事件待处理",
        "ui.dialog_busy": "对话进行中",
        "ui.loc_closed": "此地此时未开放",
        "ui.require_fail": "条件未满足",
        "ui.resolve_event": "处理事件",
        "ui.continue": "继续",
        "ui.rest": "歇一口气（推进时段）",
        "ui.hub_title": "地点枢纽",
        "ui.run_ended": "本局结束：%s",
        "ui.grudge_title": "恩怨账",
        "ui.grudge_empty": "尚无埋债",
        "ui.grudge_open": "未清算",
        "ui.grudge_latent": "未触发",
        "stat.money": "银两",
        "stat.intel": "情报",
        "stat.network": "人脉",
        "stat.trust_firm": "商行信任",
        "stat.suspicion": "嫌疑",
        "stat.support_mid": "中层支持",
        "stat.support_low": "下层支持",
        "stat.credit_bank": "票号信用",
        "stat.credit_market": "街市信用",
        "stat.credit_foreign": "洋行信用",
        "loc.01.name": "商行前堂",
        "loc.02.name": "商行后院",
        "loc.03.name": "天津街市",
        "loc.06.name": "货栈小屋",
        "act.01.name": "前堂当差",
        "act.02.name": "整理货单",
        "act.03.name": "茶楼打听",
        "act.08.name": "休息整理",
        "grudge.zian_slight": "子安轻慢",
        "grudge.demao_defer": "东家搁置",
        "grudge.zian_fiancee": "金镯纳妾",
        "event.e001.name": "开场与老板考校",
        "event.e002.name": "未婚妻来访",
        "event.e003.name": "货单异常",
        "event.e004.name": "少爷驾到",
        "event.e005.name": "暮色初见",
        "event.e006.name": "升职搁置",
        "event.e007.name": "洋行第一次考察",
        "event.e008.name": "纳妾风波",
        "event.e009.name": "复仇抉择",
        "dialog.e001.start": "光绪十六年，天津。你叫林瑞生，钱记商行的学徒。三年了，就等着满师那天——可这天底下，从来就没有「安稳」二字。",
        "dialog.e001.exam.q1": "这批南洋柚木，到岸价多少？",
        "dialog.e001.exam.a1": "回东家，到岸价每方三两七。",
        "dialog.e001.exam.q2": "市价呢？",
        "dialog.e001.exam.a2": "眼下天津行价四两二。不过聚丰行刚放了一批货，估摸三日内会跌到四两。",
        "dialog.e001.exam.praise": "不错。账上的数目你记得比我还清楚。",
        "dialog.e001.exam.hedge": "满师的事，我考虑考虑。跑街这位置，不是光记数字就行的。得懂人情，知进退。",
        "dialog.e001.exam.ack": "是，东家。",
        "dialog.e001.exam.close": "年轻人，路要一步一步走。",
        "dialog.e002.start": "瑞生，今天蒸了你爱吃的糖三角。",
        "dialog.e002.lin_ask": "又跑这一趟。厂里不忙？",
        "dialog.e002.liu_busy": "忙完了。我……我跟你说个事。",
        "dialog.e002.lin_say": "说。",
        "dialog.e002.liu_wedding": "咱们……什么时候能办喜事？厂里姐妹都问。娘说聘礼可慢慢凑，箱笼总得先备起来。",
        "dialog.e002.lin_promise": "快了。等满师当了跑街，多拿二两月例，再攒两三个月，就把聘礼酒席凑像样。",
        "dialog.e002.liu_bright": "真的？",
        "dialog.e002.lin_wait": "真的。再等等。我不想叫你空着手进门。",
        "dialog.e002.liu_ok": "好，我等你。慢一点没事，只要你别总叫我看着个空日子。",
        "dialog.e003.start": "林瑞生在整理货单时，注意到一批货的记录有些奇怪。",
        "dialog.e003.notice": "「南洋木器·二十箱」，到岸价每箱三两七——可箱体比普通木箱小一半，苦力搬运时却很轻。",
        "dialog.e003.math": "二十箱共七十四两，走的却是运费高三倍的快船。谁会为了七十四两木头花二十二两运费？",
        "dialog.e003.choice_prompt": "（你怎么做？）",
        "dialog.e003.choice.a": "追上去问苦力",
        "dialog.e003.choice.b": "默默记下，不动声色",
        "dialog.e003.choice.c": "假装没看见",
        "dialog.e003.outro.a": "苦力支吾说「东家吩咐走暗道入库」。你把这张单子记进了心里。",
        "dialog.e003.outro.b": "你没声张。纸上的数、箱子的轻，都先压着——日后对得上再说。",
        "dialog.e003.outro.c": "你翻过下一张货单。有些事，假装没看见，也许更省事。",
        "dialog.e004.start": "子安从北京来了。往后他在商行帮衬，你们多照顾。",
        "dialog.e004.zian": "各位师兄多关照。我就是来天津看看的，别的也不懂。",
        "dialog.e004.crowd": "伙计们齐声应「是」。有人偷看靴尖，有人低头理货单。",
        "dialog.e004.outro": "子安的目光在你脸上停了半息，又滑开。那半息的轻慢，像小石子——当时不疼，日后却一直硌着。",
        "dialog.e005.start": "黄昏，柳如烟提着饭盒来商行门口等你。两人并肩往华界走。",
        "dialog.e005.notice": "钱子安从茶楼晃回来，恰好在街对面看见这一幕。他的脚步顿住了。",
        "dialog.e005.zian_ask": "刚才跟林瑞生一块儿走的那丫头，谁？",
        "dialog.e005.retainer": "「回少爷，纺纱厂的女工，好像叫柳如烟。听说跟林师兄定了亲的。」",
        "dialog.e005.zian_hook": "定了亲？……打听打听，住哪儿。",
        "dialog.e006.start": "子安刚从北京来，对天津买卖不熟。瑞生啊，跑街的事暂缓一缓，你先带子安认认门路。",
        "dialog.e006.narr": "满师被一句话搁置了。跑街不只是名头——月例、油水、街面体面，都一起往后挪了。",
        "dialog.e006.zian": "林师兄，多关照啊。",
        "dialog.e006.lin": "少爷客气。",
        "dialog.e006.aside": "散场后，钱德茂把你单独叫到一旁。",
        "dialog.e006.qian_soft": "年轻人，要沉得住气。跑街的位置，等子安安顿好了，迟早是你的。",
        "dialog.e007.start": "一辆漆黑洋式马车停在钱记门前。下来一个穿中式长衫的洋人，自称宝顺洋行「白先生」。",
        "dialog.e007.bradley_greet": "钱东家，久仰。宝顺洋行新开了古董行当，听说钱记交游广阔，特来讨教。",
        "dialog.e007.qian_reply": "白先生客气。请里面坐。",
        "dialog.e007.observe": "白瑞德从瓷器聊到青铜，目光却一直在扫陈设、伙计与货单。他不是来聊古董的，是在评估钱记。",
        "dialog.e007.choice_prompt": "（你怎么做？）",
        "dialog.e007.choice.a": "主动搭话，展示对文物的了解",
        "dialog.e007.choice.b": "默默倒茶，不动声色",
        "dialog.e007.choice.c": "找借口接近，偷听后续谈话",
        "dialog.e007.outro.a": "白瑞德多看了你一眼。钱德茂的笑容淡了一分——学徒不该这么抢话。",
        "dialog.e007.outro.b": "白先生没注意你。你却把他的打量，一一记在心里。",
        "dialog.e007.outro.c_ok": "你听清了：他要找有官场背景的本地人长期合作，对钱记的评估尚未定论。",
        "dialog.e007.outro.c_fail": "「瑞生，茶凉了。」钱德茂的声音不重，你却背上发凉。",
        "dialog.e008.start": "柳如烟眼圈红着，进门就坐下，不说话。",
        "dialog.e008.lin_ask": "怎么了？",
        "dialog.e008.liu_show": "她从袖子里掏出红绸包，打开——一对赤金镯子。怕是她半年工钱都换不来。",
        "dialog.e008.lin_shock": "这哪来的？",
        "dialog.e008.liu_explain": "钱家……派人送来的。说是少爷的心意。那婆子还说，少爷若开口，娘家日子也能照应。",
        "dialog.e008.lin_rage": "他这是什么意思？纳妾？你是我的人，他拿对镯子就想……",
        "dialog.e008.liu_fear": "瑞生，我害怕。可你别说出去，钱家的势力我们惹不起。",
        "dialog.e008.choice_prompt": "（你怎么做？）",
        "dialog.e008.choice.a": "找老板理论",
        "dialog.e008.choice.b": "隐忍不发",
        "dialog.e008.choice.c": "去找赵鸿运打听",
        "dialog.e008.outro.a": "钱德茂嘴上安抚，眼神却冷。你被暗中标成了「不安分」。",
        "dialog.e008.outro.b": "你按住怒火。眼下争不过钱家；得争那条更大的钱路。",
        "dialog.e008.outro.c": "赵鸿运听完，笑眯眯地说：有意思。可空口无凭，你得先拿出点值钱的东西来。",
        "dialog.e009.start": "你独自坐在小屋里。窗外是天津华界的夜色，远处租界的灯火亮着。",
        "dialog.e009.monologue": "升职没了，未婚妻被人盯上了，东家让你去伺候他儿子。你认了三年师父——不会再空下去了。",
        "dialog.e009.choice_prompt": "灯油快尽了。三条路摊开——没有一条干净，但总得选一个下手处。",
        "dialog.e009.choice.a": "先忍着。留在钱记，把刀子藏进袖子里",
        "dialog.e009.choice.b": "另寻东家。聚丰若肯开门，钱记就不是唯一的天",
        "dialog.e009.choice.c": "借洋人之势。要渠道、要官场——他们缺，你有",
        "dialog.e009.outro.a": "你决定留在钱记。表面更勤快，暗中留意货单与闲话——等到位子偏你，再翻旧账。",
        "dialog.e009.outro.b": "聚丰赵鸿运一直想挖钱记墙脚。你手里若有够分量的货情，他会开门——也会开价。",
        "dialog.e009.outro.c": "洋人要渠道与官场背景，你要权势。先把自己变成他们用得上的门路。",
        "dialog.act.01.outro.default": "前堂散了。算盘声歇下，你袖口还沾着木屑味。",
        "dialog.act.01.outro.tight": "银子紧巴。这点散碎银子先垫着，别叫如烟看出窘相。",
        "dialog.act.02.outro.default": "货单理齐了。有几处数目对得别扭——你先记下，不声张。",
        "dialog.act.03.outro.default": "茶楼一壶粗茶，换来几句街市闲话。值不值，看你怎么用。",
        "dialog.act.03.outro.tight": "掏钱的手顿了顿。消息贵，空口袋更贵。",
        "dialog.act.03.outro.well": "你丢下茶钱，旁人看你的眼神也客气了半分。",
        "fb.zian_slight": "他当众笑你配不上那门亲事——目光滑开的那半息。",
        "fb.demao_defer": "升职的话，被他轻轻搁到了「等子安安顿好」。",
        "fb.zian_fiancee": "一对赤金镯子。厂里活路，被拿来压你。",
        "clue.suspicious_manifest": "可疑货单",
    }
}

ACTIONS = [
    {
        "act_id": "act_01", "loc_id": "loc_01", "loc_key": "act.01.name", "require": [],
        "effects": [
            {"op": "add_range", "key": "stat_money", "min": 2, "max": 3},
            {"op": "add", "key": "stat_trust_firm", "value": 1},
        ],
        "goto_dialog_by_condition": [
            {"require": [{"key": "stat_money", "op": "<", "value": 20}], "id": "dialog_act_01_outro_tight"},
            {"default": "dialog_act_01_outro_default"},
        ],
    },
    {
        "act_id": "act_02", "loc_id": "loc_01", "loc_key": "act.02.name", "require": [],
        "effects": [{"op": "add_range", "key": "stat_intel", "min": 1, "max": 2}],
        "goto_dialog_by_condition": [{"default": "dialog_act_02_outro_default"}],
    },
    {
        "act_id": "act_03", "loc_id": "loc_06", "loc_key": "act.03.name", "require": [],
        "effects": [
            {"op": "add", "key": "stat_money", "value": -1},
            {"op": "add_range", "key": "stat_intel", "min": 2, "max": 4},
            {"op": "add", "key": "stat_network", "value": 1},
        ],
        "goto_dialog_by_condition": [
            {"require": [{"key": "stat_money", "op": "<", "value": 20}], "id": "dialog_act_03_outro_tight"},
            {"require": [{"key": "stat_money", "op": ">=", "value": 50}], "id": "dialog_act_03_outro_well"},
            {"default": "dialog_act_03_outro_default"},
        ],
    },
    {
        "act_id": "act_08", "loc_id": "loc_06", "loc_key": "act.08.name", "require": [],
        "effects": [{"op": "add", "key": "stat_suspicion", "value": -1}],
    },
]

LOCATIONS = [
    {"loc_id": "loc_01", "loc_key": "loc.01.name", "open_slots": ["morning", "noon", "afternoon"], "hotspots": ["hz_front_hall", "hz_front_door"]},
    {"loc_id": "loc_02", "loc_key": "loc.02.name", "open_slots": ["morning", "noon", "afternoon", "evening"], "hotspots": ["hz_yard"]},
    {"loc_id": "loc_03", "loc_key": "loc.03.name", "open_slots": ["morning", "noon", "afternoon", "evening"], "hotspots": ["hz_market"]},
    {"loc_id": "loc_06", "loc_key": "loc.06.name", "open_slots": ["morning", "noon", "afternoon", "evening", "late_night"], "hotspots": ["hz_cottage"]},
]

GRUDGES = [
    {"grudge_id": "grudge_zian_slight", "debtor": "char_qian_zian", "initial_status": "latent", "flashback_key": "fb.zian_slight", "loc_key": "grudge.zian_slight", "bury_event": "E004"},
    {"grudge_id": "grudge_demao_defer", "debtor": "char_qian_demao", "initial_status": "latent", "flashback_key": "fb.demao_defer", "loc_key": "grudge.demao_defer", "bury_event": "E006"},
    {"grudge_id": "grudge_zian_fiancee", "debtor": "char_qian_zian", "initial_status": "latent", "flashback_key": "fb.zian_fiancee", "loc_key": "grudge.zian_fiancee", "bury_event": "E008"},
]

CLUES = [
    {"clue_id": "clue_suspicious_manifest", "loc_key": "clue.suspicious_manifest", "arc": "opium"},
]

REG = {
    "pack_id": "base",
    "events": [
        {"event_id": eid, "chapter": 1, "event_type": "mainline", "dialog_entry": f"dialog_{eid.lower()}_start", "status": "active"}
        for eid in ["E001", "E002", "E003", "E004", "E005", "E006", "E007", "E008", "E009"]
    ],
}
# fix dialog entries that aren't all dialog_e00x_start pattern - they are
for e in REG["events"]:
    e["dialog_entry"] = f"dialog_{e['event_id'].lower()}_start"

PACK = {
    "pack_id": "anchao",
    "display_name": "暗潮",
    "schema_version": "0.1",
    "content_version": "0.3.0-p2",
    "depends_on": [],
    "tables": [
        {"name": "def_stat", "file": "def_stat.json"},
        {"name": "def_location", "file": "def_location.json"},
        {"name": "def_action", "file": "def_action.json"},
        {"name": "def_event", "file": "def_event.json"},
        {"name": "def_dialog", "file": "def_dialog.json"},
        {"name": "def_edge_init", "file": "def_edge_init.json"},
        {"name": "def_grudge", "file": "def_grudge.json"},
        {"name": "def_clue", "file": "def_clue.json"},
        {"name": "def_calendar", "file": "def_calendar.json"},
        {"name": "def_tick", "file": "def_tick.json"},
        {"name": "def_meter_init", "file": "def_meter_init.json"},
        {"name": "registry_events", "file": "registry/events.json"},
        {"name": "def_loc_string", "file": "l10n/zh_CN.json"},
    ],
}


def main() -> None:
    dump("pack.json", PACK)
    dump("def_event.json", {"rows": EVENTS})
    dump("def_dialog.json", {"rows": DIALOGS})
    dump("def_calendar.json", {"rows": CALENDAR})
    dump("def_action.json", {"rows": ACTIONS})
    dump("def_location.json", {"rows": LOCATIONS})
    dump("def_grudge.json", {"rows": GRUDGES})
    dump("def_clue.json", {"rows": CLUES})
    dump("registry/events.json", REG)
    dump("l10n/zh_CN.json", LOC)
    print("dialogs", len(DIALOGS), "events", len(EVENTS))


if __name__ == "__main__":
    main()
