# -*- coding: utf-8 -*-
"""P24: E018A 章终钉「林跑街」；B/C 补看客/落点拍；任命戏 demao 恩怨 silent。"""
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


def silence_demao(effects: list) -> list:
    out = []
    for e in effects:
        if not isinstance(e, dict):
            out.append(e)
            continue
        ne = dict(e)
        if ne.get("op") == "resolve_grudge" and ne.get("id") == "grudge_demao_defer":
            ne["silent"] = True
        out.append(ne)
    return out


def main() -> None:
    data = load("def_dialog.json")
    rows = data["rows"]
    by = {str(r.get("dialog_id")): r for r in rows}

    # —— A：title 后站位→看客→落点→close；demao 恩怨 silent ——
    if "dialog_e018_a_title" in by:
        by["dialog_e018_a_title"]["next"] = "dialog_e018_a_standing"
        by["dialog_e018_a_title"]["tags"] = ["mainline", "ending", "rank_up", "rank_address"]
    if "dialog_e018_a_demao_choice" in by:
        for ch in by["dialog_e018_a_demao_choice"].get("choices") or []:
            if isinstance(ch, dict) and isinstance(ch.get("effects"), list):
                ch["effects"] = silence_demao(ch["effects"])
    if "dialog_e018_a_qian" in by:
        by["dialog_e018_a_qian"]["next"] = "dialog_e018_a_seat"
    if "dialog_e018_a_close" in by:
        by["dialog_e018_a_close"]["tags"] = ["mainline", "ending", "rank_address"]

    # —— B：title → crowd → land → close ——
    if "dialog_e018_b_title" in by:
        by["dialog_e018_b_title"]["next"] = "dialog_e018_b_crowd"
        by["dialog_e018_b_title"]["tags"] = ["mainline", "ending", "rank_up", "rank_address"]
    if "dialog_e018_b_close" in by:
        by["dialog_e018_b_close"]["tags"] = ["mainline", "ending", "rank_address"]

    # —— C：title → standing → crowd → land → close ——
    if "dialog_e018_c_title" in by:
        by["dialog_e018_c_title"]["next"] = "dialog_e018_c_standing"
        tags = list(by["dialog_e018_c_title"].get("tags") or [])
        for t in ["rank_up", "rank_address"]:
            if t not in tags:
                tags.append(t)
        by["dialog_e018_c_title"]["tags"] = tags
    if "dialog_e018_c_close" in by:
        by["dialog_e018_c_close"]["tags"] = ["mainline", "ending", "rank_address"]

    new_rows = [
        {
            "dialog_id": "dialog_e018_a_seat",
            "speaker": "narrator",
            "loc_key": "dialog.e018.a.seat",
            "tags": ["mainline", "ending"],
            "next": "dialog_e018_a_demao",
        },
        {
            "dialog_id": "dialog_e018_a_standing",
            "speaker": "narrator",
            "loc_key": "dialog.e018.a.standing",
            "tags": ["mainline", "ending", "rank_address"],
            "next": "dialog_e018_a_crowd",
        },
        {
            "dialog_id": "dialog_e018_a_crowd",
            "speaker": "narrator",
            "loc_key": "dialog.e018.a.crowd",
            "tags": ["mainline", "ending", "rank_address"],
            "next": "dialog_e018_a_land",
        },
        {
            "dialog_id": "dialog_e018_a_land",
            "speaker": "narrator",
            "loc_key": "dialog.e018.a.land",
            "tags": ["mainline", "ending", "rank_address"],
            "next": "dialog_e018_a_close",
        },
        {
            "dialog_id": "dialog_e018_b_crowd",
            "speaker": "narrator",
            "loc_key": "dialog.e018.b.crowd",
            "tags": ["mainline", "ending", "route_b", "rank_address"],
            "next": "dialog_e018_b_land",
        },
        {
            "dialog_id": "dialog_e018_b_land",
            "speaker": "narrator",
            "loc_key": "dialog.e018.b.land",
            "tags": ["mainline", "ending", "route_b", "rank_address"],
            "next": "dialog_e018_b_close",
        },
        {
            "dialog_id": "dialog_e018_c_standing",
            "speaker": "narrator",
            "loc_key": "dialog.e018.c.standing",
            "tags": ["mainline", "ending", "route_c", "rank_address"],
            "next": "dialog_e018_c_crowd",
        },
        {
            "dialog_id": "dialog_e018_c_crowd",
            "speaker": "narrator",
            "loc_key": "dialog.e018.c.crowd",
            "tags": ["mainline", "ending", "route_c", "rank_address"],
            "next": "dialog_e018_c_land",
        },
        {
            "dialog_id": "dialog_e018_c_land",
            "speaker": "narrator",
            "loc_key": "dialog.e018.c.land",
            "tags": ["mainline", "ending", "route_c", "rank_address"],
            "next": "dialog_e018_c_close",
        },
    ]

    upsert(rows, new_rows)
    save("def_dialog.json", data)

    merge_l10n(
        {
            "dialog.e018.a.seat": "东家话音未落，前堂中线空出半步。你走过去时，没人再拿你当随意使唤的学徒。",
            "dialog.e018.a.title": "第一次，有人在你背后叫出完整的三个字：「林跑街。」",
            "dialog.e018.a.standing": "你站进跑街该站的位置——柜前、送客位之间。旁人下意识让路，像这件事早就该发生。",
            "dialog.e018.a.crowd": "有人低声复述：「林跑街。」不是玩笑，是改口。王胖子冲你挤眼；钱子安不在场，却像已经被这句话甩在门外。",
            "dialog.e018.a.land": "月例、应酬账、后堂那道缝——一块钉进「林跑街」三个字里。称呼立住了，位子才算真的。",
            "dialog.e018.a.close": "林瑞生低着头应了。他能进后堂了——更多账目、更多秘密。后堂的门只开了一道缝。这不只是个位置：月例更厚，街面上的体面更足，婚事也终于像能往前挪一挪。光绪十六年的秋天，林瑞生当上了钱记商行的跑街。可他还没想到：从天津到京城的那条线，不会让一个跑街的小子轻易翻身。暗潮，才刚刚涌动。",
            "dialog.e018.b.crowd": "有人朝你拱手，半是试探，半是改口。街市风声会很快传回钱记：那个被你们当学徒使唤的小子，如今有人拿月薪请了。",
            "dialog.e018.b.land": "「聚丰的林跑街」五个字，在另一家门脸底下钉死。钱记屋檐外的名字，第一次压过屋檐里的闲话。",
            "dialog.e018.c.standing": "洋行会客室里，你不再坐边角。名片之后是资格——站位先变，再谈分成。",
            "dialog.e018.c.crowd": "出门时买办侧目。华界闲话会先于你回到钱记：林朋友有路子，不好随便踩。",
            "dialog.e018.c.land": "「林朋友」被钉进往来名册。另一套天上的椅子，终于有了你的名字——也有了分量。",
            "promo.beat.standing_paojie": "你站进跑街位。柜前送客之间，旁人让出半步。",
            "promo.tip_ending_a": "章终落定：%s · 月例档 %d 两",
        }
    )
    print("P24 ending address done")


if __name__ == "__main__":
    main()
