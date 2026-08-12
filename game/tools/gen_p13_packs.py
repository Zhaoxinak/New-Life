# -*- coding: utf-8 -*-
"""P13: fill ACT_01–12 daily actions + outro dialogs; tidy locations."""
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


def main() -> None:
    actions = {
        "rows": [
            {
                "act_id": "act_01",
                "loc_id": "loc_01",
                "loc_key": "act.01.name",
                "require": [{"slot_in": ["morning", "noon"]}],
                "effects": [
                    {"op": "add_range", "key": "stat_money", "min": 2, "max": 3},
                    {"op": "add", "key": "stat_trust_firm", "value": 1},
                ],
                "goto_dialog_by_condition": [
                    {"require": [{"key": "stat_money", "op": "<", "value": 20}], "id": "dialog_act_01_outro_tight"},
                    {"require": [{"key": "stat_money", "op": ">=", "value": 50}], "id": "dialog_act_01_outro_well"},
                    {"default": "dialog_act_01_outro_default"},
                ],
            },
            {
                "act_id": "act_02",
                "loc_id": "loc_02",
                "loc_key": "act.02.name",
                "require": [{"slot_in": ["noon", "afternoon"]}],
                "effects": [{"op": "add_range", "key": "stat_intel", "min": 1, "max": 2}],
                "goto_dialog_by_condition": [{"default": "dialog_act_02_outro_default"}],
            },
            {
                "act_id": "act_03",
                "loc_id": "loc_03",
                "loc_key": "act.03.name",
                "require": [{"slot_in": ["noon", "afternoon", "evening"]}],
                "effects": [
                    {"op": "add", "key": "stat_money", "value": -2},
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
                "act_id": "act_04",
                "loc_id": "loc_03",
                "loc_key": "act.04.name",
                "require": [
                    {"slot_in": ["evening"]},
                    {"key": "stat_money", "op": ">=", "value": 3},
                ],
                "effects": [
                    {"op": "add", "key": "stat_money", "value": -3},
                    {"op": "add", "edge": {"from": "char_wang_pangzi", "to": "char_lin_ruisheng"}, "key": "score", "value": 5},
                    {"op": "add", "edge": {"from": "char_lin_ruisheng", "to": "char_wang_pangzi"}, "key": "score", "value": 3},
                    {"op": "add_range", "key": "stat_intel", "min": 1, "max": 3},
                ],
                "goto_dialog_by_condition": [
                    {"require": [{"key": "stat_money", "op": "<", "value": 20}], "id": "dialog_act_04_outro_tight"},
                    {"require": [{"key": "stat_money", "op": ">=", "value": 50}], "id": "dialog_act_04_outro_well"},
                    {"default": "dialog_act_04_outro_default"},
                ],
            },
            {
                "act_id": "act_05",
                "loc_id": "loc_02",
                "loc_key": "act.05.name",
                "require": [{"slot_in": ["noon", "afternoon"]}],
                "effects": [
                    {"op": "add_range", "key": "stat_money", "min": -3, "max": -1},
                    {"op": "add", "key": "stat_support_mid", "value": 3},
                    {"op": "add", "key": "stat_support_low", "value": 2},
                ],
                "goto_dialog_by_condition": [
                    {"require": [{"key": "stat_money", "op": "<", "value": 20}], "id": "dialog_act_05_outro_tight"},
                    {"require": [{"key": "stat_money", "op": ">=", "value": 50}], "id": "dialog_act_05_outro_well"},
                    {"default": "dialog_act_05_outro_default"},
                ],
            },
            {
                "act_id": "act_06",
                "loc_id": "loc_06",
                "loc_key": "act.06.name",
                "require": [{"slot_in": ["evening"]}],
                "effects": [
                    {"op": "add_range", "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "key": "score", "min": 5, "max": 10},
                    {"op": "add", "edge": {"from": "char_lin_ruisheng", "to": "char_liu_ruyan"}, "key": "score", "value": 3},
                    {"op": "add", "key": "stat_suspicion", "value": -3},
                    {"op": "set_flag", "key": "flag_companied_liu_today", "value": True},
                ],
                "goto_dialog_by_condition": [
                    {"require": [{"flag": "flag_need_marriage_fund", "value": True}], "id": "dialog_act_06_outro_marriage_pressure"},
                    {
                        "require": [
                            {"key": "stat_money", "op": ">=", "value": 30},
                            {"flag": "flag_liu_gift_today", "op": "!=", "value": True},
                        ],
                        "id": "dialog_act_06_outro_gift",
                    },
                    {"require": [{"key": "stat_money", "op": "<", "value": 20}], "id": "dialog_act_06_outro_tight"},
                    {"default": "dialog_act_06_outro_default"},
                ],
            },
            {
                "act_id": "act_07",
                "loc_id": "loc_03",
                "loc_key": "act.07.name",
                "require": [
                    {"slot_in": ["noon", "afternoon"]},
                    {"key": "stat_money", "op": ">=", "value": 2},
                ],
                "effects": [
                    {"op": "add", "key": "stat_money", "value": -2},
                    {"op": "add_range", "key": "stat_network", "min": 2, "max": 5},
                ],
                "goto_dialog_by_condition": [
                    {"require": [{"key": "stat_money", "op": "<", "value": 20}], "id": "dialog_act_07_outro_tight"},
                    {"require": [{"key": "stat_money", "op": ">=", "value": 50}], "id": "dialog_act_07_outro_well"},
                    {"default": "dialog_act_07_outro_default"},
                ],
            },
            {
                "act_id": "act_08",
                "loc_id": "loc_06",
                "loc_key": "act.08.name",
                "require": [{"slot_in": ["evening", "late_night"]}],
                "effects": [
                    {"op": "add_range", "key": "stat_suspicion", "min": -8, "max": -5},
                    {"op": "set_temp", "key": "next_slot_efficiency", "value": 1.1},
                ],
                "goto_dialog_by_condition": [
                    {"require": [{"key": "stat_suspicion", "op": ">=", "value": 2}], "id": "dialog_act_08_outro_suspicion"},
                    {"require": [{"flag": "flag_need_marriage_fund", "value": True}], "id": "dialog_act_08_outro_marriage_pressure"},
                    {"require": [{"key": "stat_money", "op": "<", "value": 20}], "id": "dialog_act_08_outro_tight"},
                    {"default": "dialog_act_08_outro_default"},
                ],
            },
            {
                "act_id": "act_09",
                "loc_id": "loc_02",
                "loc_key": "act.09.name",
                "require": [{"slot_in": ["late_night"]}],
                "effects": [
                    {"op": "add_range", "key": "stat_intel", "min": 2, "max": 5},
                    {"op": "add_range", "key": "stat_suspicion", "min": 5, "max": 10},
                ],
                "goto_dialog_by_condition": [{"default": "dialog_act_09_outro_default"}],
            },
            {
                "act_id": "act_10",
                "loc_id": "loc_03",
                "loc_key": "act.10.name",
                "require": [
                    {"slot_in": ["afternoon", "evening"]},
                    {"key": "stat_network", "op": ">=", "value": 10},
                ],
                "effects": [
                    {"op": "add_range", "key": "stat_network", "min": 3, "max": 5},
                    {"op": "add", "key": "stat_credit_market", "value": 5},
                    {
                        "op": "add_range",
                        "edge": {"from": "char_zhao_hongyun", "to": "char_lin_ruisheng"},
                        "key": "score",
                        "min": 3,
                        "max": 5,
                    },
                    {"op": "add", "edge": {"from": "char_lin_ruisheng", "to": "char_zhao_hongyun"}, "key": "score", "value": 2},
                ],
                "goto_dialog_by_condition": [
                    {"require": [{"key": "stat_money", "op": "<", "value": 20}], "id": "dialog_act_10_outro_tight"},
                    {"require": [{"key": "stat_money", "op": ">=", "value": 50}], "id": "dialog_act_10_outro_well"},
                    {"default": "dialog_act_10_outro_default"},
                ],
            },
            {
                "act_id": "act_11",
                "loc_id": "loc_04",
                "loc_key": "act.bank_visit",
                "require": [
                    {"slot_in": ["morning", "noon"]},
                    {"key": "stat_money", "op": ">=", "value": 10},
                ],
                "effects": [],
                "goto_dialog_by_condition": [
                    {"require": [{"key": "stat_money", "op": ">=", "value": 50}], "id": "dialog_act_11_outro_well"},
                    {"require": [{"key": "stat_money", "op": "<", "value": 20}], "id": "dialog_act_11_outro_tight"},
                    {"default": "dialog_act_11_outro_mid"},
                ],
            },
            {
                "act_id": "act_12",
                "loc_id": "loc_06",
                "loc_key": "act.12.name",
                "require": [{"slot_in": ["late_night"]}],
                "effects": [{"op": "add_range", "key": "stat_intel", "min": 2, "max": 4}],
                "goto_dialog_by_condition": [{"default": "dialog_act_12_outro_default"}],
            },
            {
                "act_id": "act_20",
                "loc_id": "loc_01",
                "loc_key": "act.20.name",
                "require": [{"rank_in": ["waichang", "paojie", "houtang"]}],
                "effects": [
                    {"op": "add_range", "key": "stat_money", "min": 3, "max": 5},
                    {"op": "add", "key": "stat_network", "value": 1},
                ],
                "goto_dialog_by_condition": [{"default": "dialog_act_20_outro"}],
            },
            {
                "act_id": "act_foreign_visit",
                "loc_id": "loc_05",
                "loc_key": "act.foreign_visit",
                "require": [{"slot_in": ["morning", "noon", "afternoon"]}],
                "effects": [],
                "goto_dialog_by_condition": [
                    {"require": [{"flag": "flag_ending_c_ready", "value": True}], "id": "dialog_act_12f_ready"},
                    {"default": "dialog_act_12f_idle"},
                ],
            },
        ]
    }
    # keep act_bank_visit as alias pointing same? Prefer act_11 only — remove bank_visit duplicate.
    save("def_action.json", actions)

    dialogs = [
        {"dialog_id": "dialog_act_01_outro_default", "speaker": "narrator", "loc_key": "dialog.act_01.outro.default", "tags": ["action", "act_01"], "next": ""},
        {"dialog_id": "dialog_act_01_outro_tight", "speaker": "narrator", "loc_key": "dialog.act_01.outro.tight", "tags": ["action", "act_01", "money_tight"], "next": ""},
        {"dialog_id": "dialog_act_01_outro_well", "speaker": "narrator", "loc_key": "dialog.act_01.outro.well", "tags": ["action", "act_01", "money_well"], "next": ""},
        {"dialog_id": "dialog_act_02_outro_default", "speaker": "narrator", "loc_key": "dialog.act_02.outro.default", "tags": ["action", "act_02"], "next": ""},
        {"dialog_id": "dialog_act_03_outro_default", "speaker": "narrator", "loc_key": "dialog.act_03.outro.default", "tags": ["action", "act_03"], "next": ""},
        {"dialog_id": "dialog_act_03_outro_tight", "speaker": "narrator", "loc_key": "dialog.act_03.outro.tight", "tags": ["action", "act_03", "money_tight"], "next": ""},
        {"dialog_id": "dialog_act_03_outro_well", "speaker": "narrator", "loc_key": "dialog.act_03.outro.well", "tags": ["action", "act_03", "money_well"], "next": ""},
        {"dialog_id": "dialog_act_04_outro_default", "speaker": "narrator", "loc_key": "dialog.act_04.outro.default", "tags": ["action", "act_04"], "next": ""},
        {"dialog_id": "dialog_act_04_outro_tight", "speaker": "narrator", "loc_key": "dialog.act_04.outro.tight", "tags": ["action", "act_04", "money_tight"], "next": ""},
        {"dialog_id": "dialog_act_04_outro_well", "speaker": "narrator", "loc_key": "dialog.act_04.outro.well", "tags": ["action", "act_04", "money_well"], "next": ""},
        {"dialog_id": "dialog_act_05_outro_default", "speaker": "narrator", "loc_key": "dialog.act_05.outro.default", "tags": ["action", "act_05"], "next": ""},
        {"dialog_id": "dialog_act_05_outro_tight", "speaker": "narrator", "loc_key": "dialog.act_05.outro.tight", "tags": ["action", "act_05", "money_tight"], "next": ""},
        {"dialog_id": "dialog_act_05_outro_well", "speaker": "narrator", "loc_key": "dialog.act_05.outro.well", "tags": ["action", "act_05", "money_well"], "next": ""},
        {"dialog_id": "dialog_act_06_outro_default", "speaker": "narrator", "loc_key": "dialog.act_06.outro.default", "tags": ["action", "act_06"], "next": ""},
        {"dialog_id": "dialog_act_06_outro_tight", "speaker": "narrator", "loc_key": "dialog.act_06.outro.tight", "tags": ["action", "act_06", "money_tight"], "next": ""},
        {"dialog_id": "dialog_act_06_outro_marriage_pressure", "speaker": "narrator", "loc_key": "dialog.act_06.outro.marriage_pressure", "tags": ["action", "act_06", "marriage_pressure"], "next": ""},
        {
            "dialog_id": "dialog_act_06_outro_gift",
            "speaker": "narrator",
            "loc_key": "dialog.act_06.outro.gift",
            "tags": ["action", "act_06", "optional_gift"],
            "effects": [
                {"op": "add", "key": "stat_money", "value": -3},
                {"op": "add", "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "key": "score", "value": 3},
                {"op": "set", "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"}, "key": "debt", "value": "收过你的小心意"},
                {"op": "set_flag", "key": "flag_liu_gift_today", "value": True},
            ],
            "next": "",
        },
        {"dialog_id": "dialog_act_07_outro_default", "speaker": "narrator", "loc_key": "dialog.act_07.outro.default", "tags": ["action", "act_07"], "next": ""},
        {"dialog_id": "dialog_act_07_outro_tight", "speaker": "narrator", "loc_key": "dialog.act_07.outro.tight", "tags": ["action", "act_07", "money_tight"], "next": ""},
        {"dialog_id": "dialog_act_07_outro_well", "speaker": "narrator", "loc_key": "dialog.act_07.outro.well", "tags": ["action", "act_07", "money_well"], "next": ""},
        {"dialog_id": "dialog_act_08_outro_default", "speaker": "narrator", "loc_key": "dialog.act_08.outro.default", "tags": ["action", "act_08"], "next": ""},
        {"dialog_id": "dialog_act_08_outro_tight", "speaker": "narrator", "loc_key": "dialog.act_08.outro.tight", "tags": ["action", "act_08", "money_tight"], "next": ""},
        {"dialog_id": "dialog_act_08_outro_marriage_pressure", "speaker": "narrator", "loc_key": "dialog.act_08.outro.marriage_pressure", "tags": ["action", "act_08", "marriage_pressure"], "next": ""},
        {"dialog_id": "dialog_act_08_outro_suspicion", "speaker": "narrator", "loc_key": "dialog.act_08.outro.suspicion", "tags": ["action", "act_08", "high_suspicion"], "next": ""},
        {"dialog_id": "dialog_act_09_outro_default", "speaker": "narrator", "loc_key": "dialog.act_09.outro.default", "tags": ["action", "act_09"], "next": ""},
        {"dialog_id": "dialog_act_10_outro_default", "speaker": "narrator", "loc_key": "dialog.act_10.outro.default", "tags": ["action", "act_10"], "next": ""},
        {"dialog_id": "dialog_act_10_outro_tight", "speaker": "char_zhao_hongyun", "loc_key": "dialog.act_10.outro.tight", "tags": ["action", "act_10", "money_tight"], "next": ""},
        {"dialog_id": "dialog_act_10_outro_well", "speaker": "char_zhao_hongyun", "loc_key": "dialog.act_10.outro.well", "tags": ["action", "act_10", "money_well"], "next": ""},
        {"dialog_id": "dialog_act_12_outro_default", "speaker": "narrator", "loc_key": "dialog.act_12.outro.default", "tags": ["action", "act_12"], "next": ""},
    ]
    upsert_rows("def_dialog.json", "dialog_id", dialogs)

    pack = load("pack.json")
    pack["content_version"] = "1.3.0-p13"
    save("pack.json", pack)

    l10n = load("l10n/zh_CN.json")
    zh = l10n.setdefault("zh_CN", {})
    zh.update(
        {
            "act.01.name": "商行干活",
            "act.02.name": "整理货单",
            "act.03.name": "茶楼打听",
            "act.04.name": "请师兄喝酒",
            "act.05.name": "拉拢伙计",
            "act.06.name": "陪伴如烟",
            "act.07.name": "街市结交",
            "act.08.name": "休息整理",
            "act.09.name": "暗中观察",
            "act.10.name": "接触竞品",
            "act.12.name": "整理情报",
            "act.20.name": "外场跑差",
            "act.bank_visit": "钱庄办事",
            "dialog.act_01.outro.default": "前堂忙到日头偏西，周管事记了一笔：「今日勤快。」月例外的碎银落进荷包。",
            "dialog.act_01.outro.tight": "今日又挣得二三两，够吃几天。你掂了掂荷包，聘礼仍像天边的数。",
            "dialog.act_01.outro.well": "活还是那些活，银子却不像以前那样掐着花。你离能经手账的那一步，近了一点。",
            "dialog.act_02.outro.default": "货单上的斤两、箱数、价码对了一遍。有几个数对不上，你在心里画了个问号。",
            "dialog.act_03.outro.default": "一壶茶见底，街面上的闲话筛过一遍，有用的几句记在心上。",
            "dialog.act_03.outro.tight": "茶钱摸出来，心都在疼。这消息最好值当，不然明日只能喝西北风。",
            "dialog.act_03.outro.well": "赏钱给得爽快，跑堂凑近低语：近来票号、洋行、钱记，都有动静。",
            "dialog.act_04.outro.default": "三两大酒钱，换来师兄几段后院门缝里听来的风声。酒尽人散，交情又厚一分。",
            "dialog.act_04.outro.tight": "这顿酒几乎掏空了兜里的活钱。王胖子拍肩：「兄弟，我记着你这份心。」",
            "dialog.act_04.outro.well": "酒钱算不了什么。师兄压低嗓子：「货栈那边别问太细——有人问，推给我。」",
            "dialog.act_05.outro.default": "散碎银子、一包烟、替人顶半个时辰——后院有人冲你点了点头。",
            "dialog.act_05.outro.tight": "只够请一个人吃碗面。谁拿了好处心里都记着，也都知道你并不宽裕。",
            "dialog.act_05.outro.well": "赏钱给得大方，后院几个人交换眼神：「林兄弟，有事言语。」",
            "dialog.act_06.outro.default": "货栈小屋里茶烟袅袅，你们说了些无关紧要的闲话。嫌疑像薄雾，散了一些。",
            "dialog.act_06.outro.tight": "只陪坐说说话。柳如烟倒茶：「你也不容易，别为我乱花钱。」",
            "dialog.act_06.outro.marriage_pressure": "说到婚期，两人都安静了一瞬。不是没情分，是聘礼、铺盖、酒席钱还没着落。",
            "dialog.act_06.outro.gift": "捎了一包点心，如烟推辞半晌才收：「你心里有我，就够了。」",
            "dialog.act_07.outro.default": "街市上又多了几张认得你的脸。门路钱不在银子多少，在“愿意替你递话”的份量上。",
            "dialog.act_07.outro.tight": "只能请一碗茶，话却说得足。你穷归穷，街面却记住了你。",
            "dialog.act_07.outro.well": "小小人情做足了，街市上有人点头：「钱记那个跑腿的，会办事。」",
            "dialog.act_08.outro.default": "闭门不出，把纷乱理一理。明日精神些，再出门碰运气。",
            "dialog.act_08.outro.tight": "在货栈小屋数了数剩银，明日还得找活路。",
            "dialog.act_08.outro.marriage_pressure": "今夜省下一点心意钱，婚期也就又往后推了一步。",
            "dialog.act_08.outro.suspicion": "风头紧，不如歇一日。穷一点，总比被抓现行强。",
            "dialog.act_09.outro.default": "深夜后院，你贴墙听了一阵。心跳快，耳朵更灵——记下几笔，也记下这份险。",
            "dialog.act_10.outro.default": "赵鸿运话里带刺也带笑，聚丰行的门缝似乎开了一条缝。",
            "dialog.act_10.outro.tight": "有心跳槽，得先像能周转的人。穷鬼我请不起——至少还不够被报价的那一档。",
            "dialog.act_10.outro.well": "林掌柜手头活泛，聚丰行缺会算账的人。——话里没银子，眼里有数。",
            "dialog.act_12.outro.default": "零碎线索摊在案上，拼出一条隐约的线。能不能卖钱、换路、要命，还得看下一步。",
            "ui.help": "说明",
            "ui.help_title": "暗潮 · 试玩说明",
            "ui.help_body": (
                "[b]怎么玩[/b]\n"
                "1. 左侧选地点，右侧点行动；主线事件会自动入队，点「处理事件」或空格继续。\n"
                "2. 「歇一口气」推进时段；深夜结束后进入下一日（扣生活费）。\n"
                "3. 空格 / 回车：推进对白与升职演出。\n\n"
                "[b]地点速查[/b]\n"
                "前堂·干活升信任　后院·货单/拉拢/夜探　街市·打听/喝酒/结交/竞品\n"
                "钱庄·借贷汇兑　洋行·佣金门路　货栈·陪伴/休息/整理情报\n\n"
                "[b]三条路[/b]\n"
                "A 隐忍：信任与账权　B 跳槽：街市信用与竞品　C 洋行：洋人信用与分成\n"
                "埋下的恩怨账会在清算事件里罚/恕兑现。\n\n"
                "[b]银两提醒[/b]\n"
                "＜10 断炊　10–19 拮据　≥50 票号当能周转的人\n"
                "钱庄可短借（有息有逾期）；汇兑可缓解婚事压力旗。"
            ),
            "ui.help_close": "合上（Esc）",
        }
    )
    save("l10n/zh_CN.json", l10n)
    print("P13 packs ready")


if __name__ == "__main__":
    main()
