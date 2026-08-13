# -*- coding: utf-8 -*-
"""P23: E022* 主清算 — 称呼验证 + 罚/恕分拍（台词/看客）+ 落点。"""
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


def silence_slight(effects: list) -> list:
    out = []
    for e in effects:
        if not isinstance(e, dict):
            out.append(e)
            continue
        ne = dict(e)
        if ne.get("op") == "resolve_grudge" and ne.get("id") == "grudge_zian_slight" and ne.get("if_open"):
            ne["silent"] = True
        out.append(ne)
    return out


def main() -> None:
    data = load("def_dialog.json")
    rows = data["rows"]
    by = {str(r.get("dialog_id")): r for r in rows}

    for prefix, tags in [
        ("e022", ["mainline", "reckoning"]),
        ("e022b", ["mainline", "reckoning", "route_b"]),
        ("e022c", ["mainline", "reckoning", "route_c"]),
    ]:
        start = f"dialog_{prefix}_start"
        setup = f"dialog_{prefix}_setup"
        choice = f"dialog_{prefix}_choice"
        punish = f"dialog_{prefix}_punish"
        forgive = f"dialog_{prefix}_forgive"
        if start in by:
            by[start]["tags"] = tags
        if setup in by:
            by[setup]["next"] = f"dialog_{prefix}_address"
            by[setup]["tags"] = tags
            by[setup]["effects"] = [
                {"op": "set_flag", "key": "flag_reckoning_zian_started", "value": True}
            ]
        if choice in by:
            by[choice]["tags"] = tags + ["choice"]
            for ch in by[choice].get("choices") or []:
                if isinstance(ch, dict) and isinstance(ch.get("effects"), list):
                    ch["effects"] = silence_slight(ch["effects"])
                # route A punish/forgive to speak nodes
                if prefix == "e022" and isinstance(ch, dict):
                    if ch.get("id") == "A":
                        ch["next"] = "dialog_e022_punish_lin"
                    elif ch.get("id") == "B":
                        ch["next"] = "dialog_e022_forgive_lin"
                elif isinstance(ch, dict):
                    if ch.get("id") == "A":
                        ch["next"] = f"dialog_{prefix}_punish"
                    elif ch.get("id") == "B":
                        ch["next"] = f"dialog_{prefix}_forgive"
        if punish in by and prefix != "e022":
            by[punish]["next"] = f"dialog_{prefix}_crowd_punish"
            by[punish]["tags"] = tags
        if forgive in by and prefix != "e022":
            by[forgive]["next"] = f"dialog_{prefix}_crowd_forgive"
            by[forgive]["tags"] = tags

    # A route: replace collapsed punish/forgive with lin → crowd → land
    if "dialog_e022_punish" in by:
        by["dialog_e022_punish"]["speaker"] = "narrator"
        by["dialog_e022_punish"]["loc_key"] = "dialog.e022.punish.crowd"
        by["dialog_e022_punish"]["next"] = "dialog_e022_land_punish"
        by["dialog_e022_punish"]["tags"] = ["mainline", "reckoning"]
    if "dialog_e022_forgive" in by:
        by["dialog_e022_forgive"]["speaker"] = "narrator"
        by["dialog_e022_forgive"]["loc_key"] = "dialog.e022.forgive.crowd"
        by["dialog_e022_forgive"]["next"] = "dialog_e022_land_forgive"
        by["dialog_e022_forgive"]["tags"] = ["mainline", "reckoning"]

    new_rows = [
        {
            "dialog_id": "dialog_e022_address",
            "speaker": "narrator",
            "loc_key": "dialog.e022.address",
            "tags": ["mainline", "reckoning", "rank_address"],
            "next": "dialog_e022_choice",
        },
        {
            "dialog_id": "dialog_e022_punish_lin",
            "speaker": "char_lin_ruisheng",
            "loc_key": "dialog.e022.punish.lin",
            "tags": ["mainline", "reckoning"],
            "next": "dialog_e022_punish",
        },
        {
            "dialog_id": "dialog_e022_forgive_lin",
            "speaker": "char_lin_ruisheng",
            "loc_key": "dialog.e022.forgive.lin",
            "tags": ["mainline", "reckoning"],
            "next": "dialog_e022_forgive",
        },
        {
            "dialog_id": "dialog_e022_land_punish",
            "speaker": "narrator",
            "loc_key": "dialog.e022.land.punish",
            "tags": ["mainline", "reckoning", "rank_address"],
            "next": "",
        },
        {
            "dialog_id": "dialog_e022_land_forgive",
            "speaker": "narrator",
            "loc_key": "dialog.e022.land.forgive",
            "tags": ["mainline", "reckoning", "rank_address"],
            "next": "",
        },
        {
            "dialog_id": "dialog_e022b_address",
            "speaker": "narrator",
            "loc_key": "dialog.e022b.address",
            "tags": ["mainline", "reckoning", "route_b", "rank_address"],
            "next": "dialog_e022b_choice",
        },
        {
            "dialog_id": "dialog_e022b_crowd_punish",
            "speaker": "narrator",
            "loc_key": "dialog.e022b.crowd.punish",
            "tags": ["mainline", "reckoning", "route_b"],
            "next": "dialog_e022b_land_punish",
        },
        {
            "dialog_id": "dialog_e022b_crowd_forgive",
            "speaker": "narrator",
            "loc_key": "dialog.e022b.crowd.forgive",
            "tags": ["mainline", "reckoning", "route_b"],
            "next": "dialog_e022b_land_forgive",
        },
        {
            "dialog_id": "dialog_e022b_land_punish",
            "speaker": "narrator",
            "loc_key": "dialog.e022b.land.punish",
            "tags": ["mainline", "reckoning", "route_b", "rank_address"],
            "next": "",
        },
        {
            "dialog_id": "dialog_e022b_land_forgive",
            "speaker": "narrator",
            "loc_key": "dialog.e022b.land.forgive",
            "tags": ["mainline", "reckoning", "route_b", "rank_address"],
            "next": "",
        },
        {
            "dialog_id": "dialog_e022c_address",
            "speaker": "narrator",
            "loc_key": "dialog.e022c.address",
            "tags": ["mainline", "reckoning", "route_c", "rank_address"],
            "next": "dialog_e022c_choice",
        },
        {
            "dialog_id": "dialog_e022c_crowd_punish",
            "speaker": "narrator",
            "loc_key": "dialog.e022c.crowd.punish",
            "tags": ["mainline", "reckoning", "route_c"],
            "next": "dialog_e022c_land_punish",
        },
        {
            "dialog_id": "dialog_e022c_crowd_forgive",
            "speaker": "narrator",
            "loc_key": "dialog.e022c.crowd.forgive",
            "tags": ["mainline", "reckoning", "route_c"],
            "next": "dialog_e022c_land_forgive",
        },
        {
            "dialog_id": "dialog_e022c_land_punish",
            "speaker": "narrator",
            "loc_key": "dialog.e022c.land.punish",
            "tags": ["mainline", "reckoning", "route_c", "rank_address"],
            "next": "",
        },
        {
            "dialog_id": "dialog_e022c_land_forgive",
            "speaker": "narrator",
            "loc_key": "dialog.e022c.land.forgive",
            "tags": ["mainline", "reckoning", "route_c", "rank_address"],
            "next": "",
        },
    ]

    upsert(rows, new_rows)
    save("def_dialog.json", data)

    merge_l10n(
        {
            "dialog.e022.start": "父子为着账和脸面闹得前堂人人侧目。你知道——有些话，今天说，才够分量。",
            "dialog.e022.setup": "钱德茂在，钱子安在，伙计们装忙。你站在外场的位子上，第一次觉得自己的声音能压过少爷的笑。",
            "dialog.e022.address": "有人已经改口叫你「林外场」。位子若只是空名，今天就会穿帮；若是真的——就看谁先让你把话说完。",
            "dialog.e022.choice": "（婚事这桩债，你怎么收？）",
            "dialog.e022.punish.lin": "东家明鉴：如烟与我定亲三年。金镯的事，请少爷收回。商行的规矩，不该坏在内宅。",
            "dialog.e022.punish.crowd": "前堂静得能听见算盘珠子。钱德茂眉头一跳。钱子安想笑，笑不出来——伙计们的眼神已经站到你这边。",
            "dialog.e022.forgive.lin": "少爷看上的人，是我的定亲。这事，我记着。今日我不多说——只请东家一句：商行不夺人姻缘。",
            "dialog.e022.forgive.crowd": "你本可以把少爷撕开。你没有。你只把话说死，把刀收回鞘里。钱德茂眼神复杂；子安恨意更深——看客敬的是「能收住」的人。",
            "dialog.e022.land.punish": "婚事主动权回到你嘴里。新位子不是赏的——是你当众坐实的。",
            "dialog.e022.land.forgive": "你能杀却收刀。旁人从此记得：林外场的面子，不是随便能踩的。",
            # keep short aliases used by old pack keys if any UI still refs them
            "dialog.e022.punish": "「如烟与我定亲三年。金镯请收回。」前堂静了；婚事主动权回到你嘴里。",
            "dialog.e022.forgive": "你能杀却收刀，只请东家一句：商行不夺姻缘。看客敬「能收住」的人。",
            "dialog.e022b.start": "街面上的风先闻见了火药味。聚丰盯着钱记那单货，钱子安也在找能挽回脸面的机会。",
            "dialog.e022b.setup": "钱子安想拿这单生意压你一头。你站在路中间，第一次像个能决定单子往哪边走的人。",
            "dialog.e022b.address": "闲话里已经有「聚丰在谈他」。街面认的不是月例，是谁能把价、把人、把脸一起拿住。",
            "dialog.e022b.choice": "（婚事这桩债，你怎么在街面上收？）",
            "dialog.e022b.punish": "你把货价、婚事、少爷先前的荒唐话一并摊在街面上。看客先是愣，随即倒向能办成事的一边。",
            "dialog.e022b.forgive": "你把最狠的话咽回去，只留一句：买卖归买卖，姻缘归姻缘。少爷若懂规矩，彼此都省脸。",
            "dialog.e022b.crowd.punish": "钱子安想发作，嘴却快不过人群里的窃笑。今天丢的，不只是他的脸，还有这单买卖的话头。",
            "dialog.e022b.crowd.forgive": "你给了他台阶，却把如烟的名字牢牢按回自己这边。街面上的人会记住：你能截单，也能收刀。",
            "dialog.e022b.land.punish": "截胡成功。位子在街面上被坐实——不是钱记屋檐下的空名。",
            "dialog.e022b.land.forgive": "你留了场面，也钉死了婚事。市井里，能收刀的人比只会掀桌的更吓人。",
            "dialog.e022c.start": "洋行的门、庆系的手书、钱记的前堂，原本不该落在一条线上。可你今天偏要借那条线，去勒住钱子安的气。",
            "dialog.e022c.setup": "钱子安以为自己还占着少爷的位子。可你今日背后，不只是一间前堂。",
            "dialog.e022c.address": "看客分不清你借了谁的势，只看得出「林朋友」比从前更不好惹——今天要验证这势能不能压住人。",
            "dialog.e022c.choice": "（这桩婚事债，你怎么用「势」来收？）",
            "dialog.e022c.punish": "你没有把洋人的名字说满，只让前堂听懂半句。半句就够了。钱子安的火一下矮了。",
            "dialog.e022c.forgive": "你让所有人都看见自己有本事把场面掀翻，却只拿回该拿的那一份。",
            "dialog.e022c.crowd.punish": "这胜仗脏，却真。婚事的主动权，也就在这脏里被你硬生生夺了回来。",
            "dialog.e022c.crowd.forgive": "钱子安保住了面皮，丢掉的却是心气。旁人明白：你能借势，却未必滥用势。",
            "dialog.e022c.land.punish": "狐假虎威立住了。新资格不是月例纸，是当众压住人的那一口气。",
            "dialog.e022c.land.forgive": "你亮势又收刀。旁人从此忌惮的，不只是靠山，还有你会不会出手。",
            "ui.reckon.main_title": "主清算",
            "ui.reckon.shame.punish": "失态：对方想笑，笑不出来。话头从他嘴里掉到地上。",
            "ui.reckon.shame.forgive": "失态压住了——不是他没输，是你准他不在当场崩盘。",
            "ui.reckon.land.main.punish": "落点：婚事主动权回到你嘴里；新位子当众坐实。",
            "ui.reckon.land.main.forgive": "落点：你收势的手；旁人敬「能收住」的人。",
        }
    )
    print("P23 main reckon done")


if __name__ == "__main__":
    main()
