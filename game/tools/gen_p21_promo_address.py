# -*- coding: utf-8 -*-
"""P21: E020* crowd 看客拍 + E018C 称呼钉 + 外座仪式 effect 挂点。"""
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


def upsert(rows: list, new_rows: list, key: str = "dialog_id") -> None:
    index = {str(r.get(key)): i for i, r in enumerate(rows)}
    for nr in new_rows:
        k = str(nr.get(key))
        if k in index:
            rows[index[k]] = nr
        else:
            rows.append(nr)


def main() -> None:
    data = load("def_dialog.json")
    rows = data["rows"]
    by = {str(r.get("dialog_id")): r for r in rows}

    # —— E020 链：title → crowd → pay ——
    if "dialog_e020_title" in by:
        by["dialog_e020_title"]["next"] = "dialog_e020_crowd"
        by["dialog_e020_title"]["tags"] = ["mainline", "rank_up"]
    if "dialog_e020_pay" in by:
        by["dialog_e020_pay"]["tags"] = ["mainline", "rank_up"]
    if "dialog_e020_start" in by:
        by["dialog_e020_start"]["tags"] = ["mainline", "rank_up"]

    # —— E020B：title → crowd → money ——
    if "dialog_e020b_title" in by:
        by["dialog_e020b_title"]["next"] = "dialog_e020b_crowd"
        by["dialog_e020b_title"]["tags"] = ["mainline", "rank_up", "route_b"]
    if "dialog_e020b_start" in by:
        by["dialog_e020b_start"]["tags"] = ["mainline", "rank_up", "route_b"]

    # —— E020C：title → crowd → gift ——
    if "dialog_e020c_title" in by:
        by["dialog_e020c_title"]["next"] = "dialog_e020c_crowd"
        by["dialog_e020c_title"]["tags"] = ["mainline", "rank_up", "route_c"]
    if "dialog_e020c_start" in by:
        by["dialog_e020c_start"]["tags"] = ["mainline", "rank_up", "route_c"]

    # —— E018B：title 触发外座仪式 ——
    if "dialog_e018_b_title" in by:
        eff = list(by["dialog_e018_b_title"].get("effects") or [])
        if not any(isinstance(e, dict) and e.get("op") == "external_rank_ceremony" for e in eff):
            eff.append({"op": "external_rank_ceremony", "value": "jufeng_paojie"})
        by["dialog_e018_b_title"]["effects"] = eff
        by["dialog_e018_b_title"]["tags"] = ["mainline", "ending", "rank_up"]

    # —— E018C：bradley → title → close；title 挂仪式 ——
    if "dialog_e018_c_bradley" in by:
        by["dialog_e018_c_bradley"]["next"] = "dialog_e018_c_title"

    new_rows = [
        {
            "dialog_id": "dialog_e020_crowd",
            "speaker": "narrator",
            "loc_key": "dialog.e020.crowd",
            "next": "dialog_e020_pay",
            "tags": ["mainline", "rank_up"],
        },
        {
            "dialog_id": "dialog_e020b_crowd",
            "speaker": "narrator",
            "loc_key": "dialog.e020b.crowd",
            "next": "dialog_e020b_money",
            "tags": ["mainline", "rank_up", "route_b"],
        },
        {
            "dialog_id": "dialog_e020c_crowd",
            "speaker": "narrator",
            "loc_key": "dialog.e020c.crowd",
            "next": "dialog_e020c_gift",
            "tags": ["mainline", "rank_up", "route_c"],
        },
        {
            "dialog_id": "dialog_e018_c_title",
            "speaker": "narrator",
            "loc_key": "dialog.e018.c.title",
            "next": "dialog_e018_c_close",
            "tags": ["mainline", "ending", "rank_up"],
            "effects": [
                {"op": "set_flag", "key": "flag_rank_foreign_agent", "value": True},
                {"op": "add", "key": "stat_money", "value": 20},
                {"op": "add", "key": "stat_credit_foreign", "value": 20},
                {"op": "set_flag", "key": "flag_ending_c", "value": True},
                {"op": "external_rank_ceremony", "value": "foreign_agent"},
            ],
        },
    ]

    # Move money/flag off close if duplicated on c_close
    if "dialog_e018_c_close" in by:
        by["dialog_e018_c_close"]["effects"] = []
        by["dialog_e018_c_close"]["next"] = ""
        by["dialog_e018_c_close"]["tags"] = ["mainline", "ending"]

    upsert(rows, new_rows)
    save("def_dialog.json", data)

    merge_l10n(
        {
            "dialog.e020.crowd": "王胖子冲你挤眼。原先爱看热闹的几个伙计，目光往别处躲。钱子安靠在柱边，笑了笑，笑意不到眼底。",
            "dialog.e020b.crowd": "隔间外有跑堂经过，眼神往里溜了一下。过不了两日，街市会有人咬耳朵：聚丰在谈钱记那小子。闲话比公文快。",
            "dialog.e020c.crowd": "出门时，买办房有人打量你的靴。华界若有人看见你从洋行台阶下来，闲话会先于你回到钱记：这人有洋人的路子。",
            "dialog.e018.c.title": "「林朋友」被钉进往来名册。另一套天上的椅子，终于有了你的名字。",
            "promo.address.apprentice": "瑞生",
            "promo.address.waichang": "林外场",
            "promo.address.paojie": "林跑街",
            "promo.address.houtang": "林先生",
            "promo.address.jufeng_paojie": "聚丰的林跑街",
            "promo.address.foreign": "林朋友",
            "promo.beat.standing": "你站进前堂中线。旁人下意识让了半步。",
            "promo.beat.standing_jufeng": "聚丰柜前，有人改口叫你「林跑街」。钱记屋檐外的位子，第一次压过屋檐里的闲话。",
            "promo.beat.standing_foreign": "洋行台阶上，买办侧目。华界闲话改口：林朋友有路子。",
            "promo.beat.ritual_jufeng": "不是前堂点名——是聚丰把你写进能办事的人名里。",
            "promo.beat.ritual_foreign": "不是月例任命——是洋行把门路交到你手里。",
            "promo.tip_address": "众人改口：%s · 月例档 %d 两",
            "promo.tip_external": "外座落定：%s",
            "promo.unlock.jufeng": "聚丰跑街账路",
            "promo.unlock.foreign": "洋行往来资格",
        }
    )
    print("P21 promo address / crowd done")


if __name__ == "__main__":
    main()
