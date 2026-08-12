# -*- coding: utf-8 -*-
"""P11: finance services + ACT_11 bank loop + day-end money bands."""
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
            index[k] = len(rows) - 1
    save(table_file, data)


def upsert_dialogs(new_rows: list) -> None:
    upsert_rows("def_dialog.json", "dialog_id", new_rows)


def main() -> None:
    services = {
        "rows": [
            {
                "service_id": "svc_bank_loan_short",
                "provider": "org_bank",
                "service_type": "loan",
                "loc_hint": "loc_04",
                "loc_key": "svc.bank_loan_short",
                "require": [{"key": "stat_money", "op": ">=", "value": 10}],
                "effects_on_open": [
                    {"op": "add", "key": "stat_money", "value": 15},
                    {"op": "add", "key": "stat_suspicion", "value": 3},
                    {"op": "add", "key": "stat_credit_bank", "value": 2},
                    {"op": "set_flag", "key": "flag_bank_loan_active", "value": True},
                ],
                "debt_template": {
                    "principal": 15,
                    "interest_per_day": 1,
                    "due_in_days": 3,
                    "collateral": "none",
                },
                "risk": {
                    "overdue_flag": "flag_bank_loan_overdue",
                    "on_overdue": [
                        {"op": "add", "key": "stat_suspicion", "value": 5},
                        {"op": "add", "key": "stat_credit_bank", "value": -10},
                    ],
                },
            },
            {
                "service_id": "svc_bank_rollover",
                "provider": "org_bank",
                "service_type": "rollover",
                "loc_hint": "loc_04",
                "loc_key": "svc.bank_rollover",
                "require": [
                    {"flag": "flag_bank_loan_active", "value": True},
                    {"flag": "flag_bank_tier2", "value": True},
                ],
                "effects_on_open": [
                    {"op": "add", "key": "stat_money", "value": -2},
                    {"op": "add", "key": "stat_credit_bank", "value": -5},
                ],
                "debt_template": {"extend_days": 2, "extra_interest": 1},
            },
            {
                "service_id": "svc_bank_remit_home",
                "provider": "org_bank",
                "service_type": "remit",
                "loc_hint": "loc_04",
                "loc_key": "svc.bank_remit_home",
                "require": [{"key": "stat_money", "op": ">=", "value": 20}],
                "effects_on_open": [
                    {"op": "add", "key": "stat_money", "value": -5},
                    {"op": "add", "key": "stat_credit_bank", "value": 3},
                    {"op": "add", "meter": "impression_qing", "value": 2},
                    {"op": "clear_flag", "key": "flag_need_marriage_fund"},
                ],
            },
            {
                "service_id": "svc_bank_market_info",
                "provider": "org_bank",
                "service_type": "info",
                "loc_hint": "loc_04",
                "loc_key": "svc.bank_market_info",
                "require": [{"key": "stat_money", "op": ">=", "value": 10}],
                "effects_on_open": [
                    {"op": "add", "key": "stat_money", "value": -2},
                    {"op": "add_range", "key": "stat_intel", "min": 1, "max": 3},
                    {"op": "add", "key": "stat_credit_bank", "value": 1},
                ],
            },
        ]
    }
    save("def_finance_service.json", services)

    pack = load("pack.json")
    pack["content_version"] = "1.1.0-p11"
    tables = pack.setdefault("tables", [])
    names = {t.get("name") for t in tables}
    if "def_finance_service" not in names:
        # insert before def_tick
        insert_at = next((i for i, t in enumerate(tables) if t.get("name") == "def_tick"), len(tables))
        tables.insert(insert_at, {"name": "def_finance_service", "file": "def_finance_service.json"})
    save("pack.json", pack)

    # ACT_11 action
    actions = load("def_action.json")
    for row in actions["rows"]:
        if row.get("act_id") == "act_bank_visit":
            row["require"] = [{"key": "stat_money", "op": ">=", "value": 10}]
            row["effects"] = []
            row["goto_dialog_by_condition"] = [
                {"require": [{"key": "stat_money", "op": ">=", "value": 50}], "id": "dialog_act_11_outro_well"},
                {"require": [{"key": "stat_money", "op": "<", "value": 20}], "id": "dialog_act_11_outro_tight"},
                {"default": "dialog_act_11_outro_mid"},
            ]
            break
    save("def_action.json", actions)

    dialogs = [
        {
            "dialog_id": "dialog_act_11_menu",
            "speaker": "narrator",
            "loc_key": "dialog.act_11.menu",
            "tags": ["action", "act_11"],
            "choices": [
                {
                    "id": "loan",
                    "loc_key": "dialog.act_11.choice.loan",
                    "require": [
                        {"key": "stat_money", "op": ">=", "value": 10},
                        {"flag": "flag_bank_loan_active", "op": "!=", "value": True},
                    ],
                    "next": "dialog_act_11_loan",
                },
                {
                    "id": "repay",
                    "loc_key": "dialog.act_11.choice.repay",
                    "require": [{"flag": "flag_bank_loan_active", "value": True}],
                    "next": "dialog_act_11_repay",
                },
                {
                    "id": "rollover",
                    "loc_key": "dialog.act_11.choice.rollover",
                    "require": [
                        {"flag": "flag_bank_loan_active", "value": True},
                        {"flag": "flag_bank_tier2", "value": True},
                    ],
                    "next": "dialog_act_11_rollover",
                },
                {
                    "id": "remit",
                    "loc_key": "dialog.act_11.choice.remit",
                    "require": [{"key": "stat_money", "op": ">=", "value": 20}],
                    "next": "dialog_act_11_remit",
                },
                {
                    "id": "market",
                    "loc_key": "dialog.act_11.choice.market",
                    "require": [{"key": "stat_money", "op": ">=", "value": 10}],
                    "next": "dialog_act_11_market",
                },
                {
                    "id": "tier2",
                    "loc_key": "dialog.act_11.choice.tier2",
                    "require": [{"flag": "flag_bank_tier2", "value": True}],
                    "next": "dialog_act_11_tier2",
                },
                {
                    "id": "leave",
                    "loc_key": "dialog.act_11.choice.leave",
                    "require": [],
                    "next": "",
                },
            ],
        },
        {
            "dialog_id": "dialog_act_11_loan",
            "speaker": "narrator",
            "loc_key": "dialog.act_11.loan",
            "tags": ["action", "act_11", "finance"],
            "effects": [{"op": "open_service", "id": "svc_bank_loan_short"}],
            "next": "",
        },
        {
            "dialog_id": "dialog_act_11_repay",
            "speaker": "narrator",
            "loc_key": "dialog.act_11.repay",
            "tags": ["action", "act_11", "finance"],
            "effects": [
                {
                    "op": "repay_debt",
                    "service_id": "svc_bank_loan_short",
                    "from_money": True,
                    "pay_all": True,
                }
            ],
            "next": "",
        },
        {
            "dialog_id": "dialog_act_11_rollover",
            "speaker": "narrator",
            "loc_key": "dialog.act_11.rollover",
            "tags": ["action", "act_11", "finance"],
            "effects": [{"op": "open_service", "id": "svc_bank_rollover"}],
            "next": "",
        },
        {
            "dialog_id": "dialog_act_11_remit",
            "speaker": "narrator",
            "loc_key": "dialog.act_11.remit",
            "tags": ["action", "act_11", "finance"],
            "effects": [{"op": "open_service", "id": "svc_bank_remit_home"}],
            "next": "",
        },
        {
            "dialog_id": "dialog_act_11_market",
            "speaker": "narrator",
            "loc_key": "dialog.act_11.market",
            "tags": ["action", "act_11", "finance"],
            "effects": [{"op": "open_service", "id": "svc_bank_market_info"}],
            "next": "",
        },
        {
            "dialog_id": "dialog_act_11_tier2",
            "speaker": "narrator",
            "loc_key": "dialog.act_11.tier2",
            "tags": ["action", "act_11"],
            "effects": [{"op": "add_range", "key": "stat_network", "min": 2, "max": 4}],
            "next": "",
        },
        {
            "dialog_id": "dialog_act_11_outro_tight",
            "speaker": "narrator",
            "loc_key": "dialog.act_11.outro.tight",
            "tags": ["action", "act_11", "money_tight"],
            "next": "dialog_act_11_menu",
        },
        {
            "dialog_id": "dialog_act_11_outro_mid",
            "speaker": "narrator",
            "loc_key": "dialog.act_11.outro.mid",
            "tags": ["action", "act_11"],
            "next": "dialog_act_11_menu",
        },
        {
            "dialog_id": "dialog_act_11_outro_well",
            "speaker": "narrator",
            "loc_key": "dialog.act_11.outro.well",
            "tags": ["action", "act_11", "money_well"],
            "next": "dialog_act_11_menu",
        },
    ]
    upsert_dialogs(dialogs)

    # def_tick money bands (FinanceService also refreshes; ticks keep living cost)
    ticks = {
        "rows": [
            {
                "tick_id": "tick_living_cost",
                "when": "on_day_end",
                "require": [],
                "effects": [{"op": "add", "key": "stat_money", "value": -1}],
            },
        ]
    }
    save("def_tick.json", ticks)

    # l10n
    l10n = load("l10n/zh_CN.json")
    zh = l10n.setdefault("zh_CN", {})
    zh.update(
        {
            "act.bank_visit": "钱庄办事",
            "svc.bank_loan_short": "票号短借",
            "svc.bank_rollover": "票号展期",
            "svc.bank_remit_home": "汇银回乡",
            "svc.bank_market_info": "票号行情",
            "dialog.act_11.menu": "票号柜面算盘轻响。你要办哪一桩？",
            "dialog.act_11.choice.loan": "短借十五两",
            "dialog.act_11.choice.repay": "还清往来账",
            "dialog.act_11.choice.rollover": "展期两日",
            "dialog.act_11.choice.remit": "汇兑 / 办体面",
            "dialog.act_11.choice.market": "打听行情",
            "dialog.act_11.choice.tier2": "高阶往来",
            "dialog.act_11.choice.leave": "告辞",
            "dialog.act_11.loan": "柜员拨算盘：「短借十五两，利钱照算，按期还。」银子入袋，心里却多了一桩账。",
            "dialog.act_11.repay": "你把银子推过柜台。算盘一响，这桩往来账清了。",
            "dialog.act_11.rollover": "柜员皱眉又展颜：「再宽两日，利钱另算。信用可别再砸。」",
            "dialog.act_11.remit": "汇五两出去，票号盖了戳。体面这东西，有时比银子更急。",
            "dialog.act_11.market": "花两吊打听行情：洋货价、票号风向、钱记上下游，零碎拼成一张图。",
            "dialog.act_11.tier2": "自从身子里有了五十两活钱，票号把你记进簿子：「林掌柜，照旧？」",
            "dialog.act_11.outro.tight": "柜员打量你：「零碎客，借可以，利钱照算。」",
            "dialog.act_11.outro.mid": "票号肯办常规汇兑、小借小还；柜员语气客气，仍把你当过客。",
            "dialog.act_11.outro.well": "票号把你当能周转的人，柜面语气也热络几分。",
            "ui.debt_active": "票号债",
            "ui.debt_overdue": "逾期",
            "ui.edge_title": "交情",
            "ui.debt_cant_pay": "银两不足，还不起这桩账。",
            "ui.debt_none": "柜上没有你的往来账。",
            "tier.仇隙": "仇隙",
            "tier.不睦": "不睦",
            "tier.泛泛": "泛泛",
            "tier.相善": "相善",
            "tier.厚交": "厚交",
        }
    )
    save("l10n/zh_CN.json", l10n)
    print("P11 packs ready")


if __name__ == "__main__":
    main()
