# -*- coding: utf-8 -*-
"""P12: run_org init + foreign commission ACT + org event hooks."""
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


def append_effects(dialog_id: str, effects: list) -> None:
    data = load("def_dialog.json")
    for row in data["rows"]:
        if row.get("dialog_id") == dialog_id:
            existing = row.setdefault("effects", [])
            # dedupe by json dump
            have = {json.dumps(e, sort_keys=True, ensure_ascii=False) for e in existing}
            for e in effects:
                s = json.dumps(e, sort_keys=True, ensure_ascii=False)
                if s not in have:
                    existing.append(e)
                    have.add(s)
            save("def_dialog.json", data)
            return
        for ch in row.get("choices", []):
            if row.get("dialog_id") == dialog_id:
                break
    # choice-level: match by dialog + choice id via effects list merge on choice
    for row in data["rows"]:
        for ch in row.get("choices", []):
            pass
    # fallback: find choice C on dialog_e015_choice
    changed = False
    for row in data["rows"]:
        if row.get("dialog_id") != dialog_id:
            continue
        existing = row.setdefault("effects", [])
        have = {json.dumps(e, sort_keys=True, ensure_ascii=False) for e in existing}
        for e in effects:
            s = json.dumps(e, sort_keys=True, ensure_ascii=False)
            if s not in have:
                existing.append(e)
                have.add(s)
                changed = True
    if changed:
        save("def_dialog.json", data)


def append_choice_effects(dialog_id: str, choice_id: str, effects: list) -> None:
    data = load("def_dialog.json")
    for row in data["rows"]:
        if row.get("dialog_id") != dialog_id:
            continue
        for ch in row.get("choices", []):
            if str(ch.get("id")) != choice_id:
                continue
            existing = ch.setdefault("effects", [])
            have = {json.dumps(e, sort_keys=True, ensure_ascii=False) for e in existing}
            for e in effects:
                s = json.dumps(e, sort_keys=True, ensure_ascii=False)
                if s not in have:
                    existing.append(e)
                    have.add(s)
            save("def_dialog.json", data)
            print("patched choice", dialog_id, choice_id)
            return
    print("WARN missing", dialog_id, choice_id)


def main() -> None:
    orgs = {
        "rows": [
            {
                "org_id": "org_qianji",
                "loc_key": "org.qianji.name",
                "firm_bright": 55,
                "firm_dark": 40,
                "firm_heat": 25,
                "cash_bright": 60,
                "cash_dark": 45,
                "liquidity": 50,
                "payroll_pressure": 20,
                "tribute_pressure": 35,
            },
            {
                "org_id": "org_jufeng",
                "loc_key": "org.jufeng.name",
                "market_appetite": 60,
                "talent_budget": 40,
                "liquidity": 55,
                "poach_pressure": 35,
            },
            {
                "org_id": "org_baoshun",
                "loc_key": "org.baoshun.name",
                "foreign_margin": 65,
                "commission_budget": 50,
                "channel_hunger": 70,
                "compliance_mask": 60,
            },
            {
                "org_id": "org_qing",
                "loc_key": "org.qing.name",
                "tribute_intake": 40,
                "protection_value": 55,
            },
        ]
    }
    save("def_org_init.json", orgs)

    pack = load("pack.json")
    pack["content_version"] = "1.2.0-p12"
    tables = pack.setdefault("tables", [])
    names = {t.get("name") for t in tables}
    if "def_org_init" not in names:
        insert_at = next((i for i, t in enumerate(tables) if t.get("name") == "def_meter_init"), len(tables))
        tables.insert(insert_at, {"name": "def_org_init", "file": "def_org_init.json"})
    save("pack.json", pack)

    # foreign commission service
    fin = load("def_finance_service.json")
    rows = fin["rows"]
    idx = {r["service_id"]: i for i, r in enumerate(rows)}
    commission = {
        "service_id": "svc_foreign_commission",
        "provider": "org_baoshun",
        "service_type": "commission",
        "loc_hint": "loc_05",
        "loc_key": "svc.foreign_commission",
        "require": [{"flag": "flag_ending_c_ready", "value": True}],
        "effects_on_open": [
            {"op": "add", "key": "stat_credit_foreign", "value": 20},
            {"op": "set_flag", "key": "flag_ending_c", "value": True},
            {"op": "set_flag", "key": "flag_rank_foreign_agent", "value": True},
            {"op": "add", "org": "org_baoshun", "key": "compliance_mask", "value": -5},
        ],
        "payout_rule": {
            "upfront_money": 20,
            "monthly_commission_band": "high",
            "narrative_tags": ["foreign", "long_term", "dirty"],
        },
    }
    if "svc_foreign_commission" in idx:
        rows[idx["svc_foreign_commission"]] = commission
    else:
        rows.append(commission)
    save("def_finance_service.json", fin)

    # action
    actions = load("def_action.json")
    have = {r.get("act_id") for r in actions["rows"]}
    if "act_foreign_visit" not in have:
        actions["rows"].append(
            {
                "act_id": "act_foreign_visit",
                "loc_id": "loc_05",
                "loc_key": "act.foreign_visit",
                "require": [],
                "effects": [],
                "goto_dialog_by_condition": [
                    {
                        "require": [{"flag": "flag_ending_c_ready", "value": True}],
                        "id": "dialog_act_12f_ready",
                    },
                    {"default": "dialog_act_12f_idle"},
                ],
            }
        )
        save("def_action.json", actions)
    else:
        for row in actions["rows"]:
            if row.get("act_id") == "act_foreign_visit":
                row["goto_dialog_by_condition"] = [
                    {
                        "require": [{"flag": "flag_ending_c_ready", "value": True}],
                        "id": "dialog_act_12f_ready",
                    },
                    {"default": "dialog_act_12f_idle"},
                ]
        save("def_action.json", actions)

    dialogs = [
        {
            "dialog_id": "dialog_act_12f_idle",
            "speaker": "narrator",
            "loc_key": "dialog.act_12f.idle",
            "tags": ["action", "act_foreign"],
            "effects": [
                {"op": "add", "key": "stat_credit_foreign", "value": 1},
                {"op": "add", "org": "org_baoshun", "key": "channel_hunger", "value": -1},
            ],
            "next": "",
        },
        {
            "dialog_id": "dialog_act_12f_ready",
            "speaker": "narrator",
            "loc_key": "dialog.act_12f.ready",
            "tags": ["action", "act_foreign"],
            "choices": [
                {
                    "id": "commission",
                    "loc_key": "dialog.act_12f.choice.commission",
                    "require": [{"flag": "flag_ending_c_ready", "value": True}],
                    "next": "dialog_act_12f_commission",
                },
                {
                    "id": "leave",
                    "loc_key": "dialog.act_12f.choice.leave",
                    "require": [],
                    "next": "",
                },
            ],
        },
        {
            "dialog_id": "dialog_act_12f_commission",
            "speaker": "narrator",
            "loc_key": "dialog.act_12f.commission",
            "tags": ["action", "act_foreign", "finance", "ending"],
            "effects": [{"op": "open_service", "id": "svc_foreign_commission"}],
            "next": "",
        },
    ]
    upsert_rows("def_dialog.json", "dialog_id", dialogs)

    # E015C 盗卖：黑钱进组织暗账、热度升高
    append_choice_effects(
        "dialog_e015_choice",
        "C",
        [
            {"op": "add", "org": "org_qianji", "key": "cash_dark", "value": 8},
            {"op": "add", "org": "org_qianji", "key": "firm_dark", "value": 5},
            {"op": "add", "org": "org_qianji", "key": "firm_heat", "value": 10},
        ],
    )
    # E013A 揭穿：穿帮热度
    append_choice_effects(
        "dialog_e013_choice",
        "A",
        [
            {"op": "add", "org": "org_qianji", "key": "firm_heat", "value": 8},
            {"op": "add", "org": "org_qianji", "key": "liquidity", "value": -3},
        ],
    )
    # E013B 密账：暗账活跃
    append_choice_effects(
        "dialog_e013_choice",
        "B",
        [
            {"op": "add", "org": "org_qianji", "key": "firm_dark", "value": 6},
            {"op": "add", "org": "org_qianji", "key": "firm_heat", "value": 4},
        ],
    )

    l10n = load("l10n/zh_CN.json")
    zh = l10n.setdefault("zh_CN", {})
    zh.update(
        {
            "org.qianji.name": "钱记商行",
            "org.jufeng.name": "聚丰行",
            "org.baoshun.name": "宝顺洋行",
            "org.qing.name": "庆系",
            "act.foreign_visit": "洋行拜访",
            "svc.foreign_commission": "洋行代理佣金",
            "dialog.act_12f.idle": "洋行门房客气，却不提价码。白瑞德的人只说：再等风声。",
            "dialog.act_12f.ready": "账房递来一份草约：「代理分成，可先支一笔。签不签？」",
            "dialog.act_12f.choice.commission": "接代理佣金",
            "dialog.act_12f.choice.leave": "再想想",
            "dialog.act_12f.commission": "银票落袋，洋行把你写进长期门路。体面有了，退路却窄了。",
            "ui.org_heat": "钱记热度",
            "ui.org_liquidity": "周转",
            "ui.org_commission": "洋行佣金预算",
        }
    )
    save("l10n/zh_CN.json", l10n)
    print("P12 packs ready")


if __name__ == "__main__":
    main()
