# -*- coding: utf-8 -*-
"""P22: E021* 轻清算 — 看客优先 + 站位/称呼验证拍 + 落点拍。"""
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


def nbc_start(prefix: str, skip_id: str) -> list:
    return [
        {
            "require": [{"grudge": "grudge_onlooker", "status": "open"}],
            "id": f"dialog_{prefix}_flash_onlooker",
        },
        {
            "require": [{"grudge": "grudge_zian_slight", "status": "open"}],
            "id": f"dialog_{prefix}_flash",
        },
        {"default": skip_id},
    ]


def onlooker_choice_effects(route: str) -> tuple[list, list]:
    """return (punish_effects, forgive_effects)"""
    common_close = [{"op": "set_flag", "key": "flag_grudge_window_light", "value": False}]
    if route == "a":
        punish = [
            {"op": "resolve_grudge", "id": "grudge_onlooker", "mode": "punish"},
            {"op": "add", "key": "stat_support_low", "value": 10},
            {"op": "add", "key": "stat_network", "value": 3},
        ] + common_close
        forgive = [
            {"op": "resolve_grudge", "id": "grudge_onlooker", "mode": "forgive"},
            {"op": "add", "key": "stat_support_low", "value": 8},
            {
                "op": "set",
                "edge": {"from": "char_lin_ruisheng", "to": "char_zhou_guanshi"},
                "key": "debt",
                "value": "看客被你放过，欠一声",
            },
        ] + common_close
    elif route == "b":
        punish = [
            {"op": "resolve_grudge", "id": "grudge_onlooker", "mode": "punish"},
            {"op": "add", "key": "stat_support_low", "value": 8},
            {"op": "add", "key": "stat_credit_market", "value": 5},
            {"op": "add", "key": "stat_network", "value": 3},
        ] + common_close
        forgive = [
            {"op": "resolve_grudge", "id": "grudge_onlooker", "mode": "forgive"},
            {"op": "add", "key": "stat_support_low", "value": 6},
            {"op": "add", "key": "stat_credit_market", "value": 3},
            {
                "op": "set",
                "edge": {"from": "char_lin_ruisheng", "to": "char_zhou_guanshi"},
                "key": "debt",
                "value": "街市上被你放过，欠一声",
            },
        ] + common_close
    else:
        punish = [
            {"op": "resolve_grudge", "id": "grudge_onlooker", "mode": "punish"},
            {"op": "add", "key": "stat_support_low", "value": 8},
            {"op": "add", "key": "stat_suspicion", "value": 4},
            {"op": "add", "key": "stat_credit_foreign", "value": 3},
        ] + common_close
        forgive = [
            {"op": "resolve_grudge", "id": "grudge_onlooker", "mode": "forgive"},
            {"op": "add", "key": "stat_support_low", "value": 6},
            {"op": "add", "key": "stat_network", "value": 5},
            {
                "op": "set",
                "edge": {"from": "char_lin_ruisheng", "to": "char_zhou_guanshi"},
                "key": "debt",
                "value": "借势压过又放过",
            },
        ] + common_close
    return punish, forgive


def build_onlooker_branch(prefix: str, route: str, event_id: str) -> list:
    punish_fx, forgive_fx = onlooker_choice_effects(route)
    tags = ["mainline", "reckoning"]
    if route == "b":
        tags.append("route_b")
    elif route == "c":
        tags.append("route_c")
    loc = f"dialog.{prefix}"
    return [
        {
            "dialog_id": f"dialog_{prefix}_flash_onlooker",
            "speaker": "narrator",
            "loc_key": "dialog.grudge.onlooker.flash",
            "tags": ["flashback"],
            "next": f"dialog_{prefix}_onlooker_setup",
        },
        {
            "dialog_id": f"dialog_{prefix}_onlooker_setup",
            "speaker": "narrator",
            "loc_key": f"{loc}.onlooker.setup",
            "tags": tags,
            "next": f"dialog_{prefix}_onlooker_address",
        },
        {
            "dialog_id": f"dialog_{prefix}_onlooker_address",
            "speaker": "narrator",
            "loc_key": f"{loc}.onlooker.address",
            "tags": tags + ["rank_address"],
            "next": f"dialog_{prefix}_onlooker_choice",
        },
        {
            "dialog_id": f"dialog_{prefix}_onlooker_choice",
            "event_id": event_id,
            "speaker": "narrator",
            "loc_key": f"{loc}.onlooker.choice",
            "tags": tags + ["choice"],
            "choices": [
                {
                    "id": "A",
                    "loc_key": f"{loc}.onlooker.a",
                    "effects": punish_fx,
                    "next": f"dialog_{prefix}_onlooker_punish",
                },
                {
                    "id": "B",
                    "loc_key": f"{loc}.onlooker.b",
                    "effects": forgive_fx,
                    "next": f"dialog_{prefix}_onlooker_forgive",
                },
            ],
            "next": "",
        },
        {
            "dialog_id": f"dialog_{prefix}_onlooker_punish",
            "speaker": "narrator",
            "loc_key": f"{loc}.onlooker.punish",
            "tags": tags,
            "next": f"dialog_{prefix}_onlooker_land_punish",
        },
        {
            "dialog_id": f"dialog_{prefix}_onlooker_forgive",
            "speaker": "narrator",
            "loc_key": f"{loc}.onlooker.forgive",
            "tags": tags,
            "next": f"dialog_{prefix}_onlooker_land_forgive",
        },
        {
            "dialog_id": f"dialog_{prefix}_onlooker_land_punish",
            "speaker": "narrator",
            "loc_key": f"{loc}.onlooker.land.punish",
            "tags": tags + ["rank_address"],
            "next": "",
        },
        {
            "dialog_id": f"dialog_{prefix}_onlooker_land_forgive",
            "speaker": "narrator",
            "loc_key": f"{loc}.onlooker.land.forgive",
            "tags": tags + ["rank_address"],
            "next": "",
        },
    ]


def main() -> None:
    data = load("def_dialog.json")
    rows = data["rows"]
    by = {str(r.get("dialog_id")): r for r in rows}

    # —— A：看客优先；闪回后补称呼拍；结局落点 ——
    if "dialog_e021_start" in by:
        by["dialog_e021_start"]["next_by_condition"] = nbc_start("e021", "dialog_e021_skip")
        by["dialog_e021_start"]["tags"] = ["mainline", "reckoning"]
    if "dialog_e021_setup" in by:
        by["dialog_e021_setup"]["next"] = "dialog_e021_address"
        by["dialog_e021_setup"]["tags"] = ["mainline", "reckoning"]
    if "dialog_e021_punish" in by:
        by["dialog_e021_punish"]["next"] = "dialog_e021_land_punish"
    if "dialog_e021_forgive" in by:
        by["dialog_e021_forgive"]["next"] = "dialog_e021_land_forgive"

    # —— B ——
    if "dialog_e021b_start" in by:
        by["dialog_e021b_start"]["next_by_condition"] = nbc_start("e021b", "dialog_e021b_skip")
        by["dialog_e021b_start"]["tags"] = ["mainline", "reckoning", "route_b"]
    if "dialog_e021b_flash" in by:
        by["dialog_e021b_flash"]["next"] = "dialog_e021b_setup"
    if "dialog_e021b_punish" in by:
        by["dialog_e021b_punish"]["next"] = "dialog_e021b_land_punish"
    if "dialog_e021b_forgive" in by:
        by["dialog_e021b_forgive"]["next"] = "dialog_e021b_land_forgive"

    # —— C ——
    if "dialog_e021c_start" in by:
        by["dialog_e021c_start"]["next_by_condition"] = nbc_start("e021c", "dialog_e021c_skip")
        by["dialog_e021c_start"]["tags"] = ["mainline", "reckoning", "route_c"]
    if "dialog_e021c_flash" in by:
        by["dialog_e021c_flash"]["next"] = "dialog_e021c_setup"
    if "dialog_e021c_punish" in by:
        by["dialog_e021c_punish"]["next"] = "dialog_e021c_land_punish"
    if "dialog_e021c_forgive" in by:
        by["dialog_e021c_forgive"]["next"] = "dialog_e021c_land_forgive"

    new_rows: list = []
    # slight address / setup / land for all routes
    new_rows.extend(
        [
            {
                "dialog_id": "dialog_e021_address",
                "speaker": "narrator",
                "loc_key": "dialog.e021.slight.address",
                "tags": ["mainline", "reckoning", "rank_address"],
                "next": "dialog_e021_choice",
            },
            {
                "dialog_id": "dialog_e021_land_punish",
                "speaker": "narrator",
                "loc_key": "dialog.e021.slight.land.punish",
                "tags": ["mainline", "reckoning", "rank_address"],
                "next": "",
            },
            {
                "dialog_id": "dialog_e021_land_forgive",
                "speaker": "narrator",
                "loc_key": "dialog.e021.slight.land.forgive",
                "tags": ["mainline", "reckoning", "rank_address"],
                "next": "",
            },
            {
                "dialog_id": "dialog_e021b_setup",
                "speaker": "narrator",
                "loc_key": "dialog.e021b.slight.setup",
                "tags": ["mainline", "reckoning", "route_b"],
                "next": "dialog_e021b_address",
            },
            {
                "dialog_id": "dialog_e021b_address",
                "speaker": "narrator",
                "loc_key": "dialog.e021b.slight.address",
                "tags": ["mainline", "reckoning", "route_b", "rank_address"],
                "next": "dialog_e021b_choice",
            },
            {
                "dialog_id": "dialog_e021b_land_punish",
                "speaker": "narrator",
                "loc_key": "dialog.e021b.slight.land.punish",
                "tags": ["mainline", "reckoning", "route_b", "rank_address"],
                "next": "",
            },
            {
                "dialog_id": "dialog_e021b_land_forgive",
                "speaker": "narrator",
                "loc_key": "dialog.e021b.slight.land.forgive",
                "tags": ["mainline", "reckoning", "route_b", "rank_address"],
                "next": "",
            },
            {
                "dialog_id": "dialog_e021c_setup",
                "speaker": "narrator",
                "loc_key": "dialog.e021c.slight.setup",
                "tags": ["mainline", "reckoning", "route_c"],
                "next": "dialog_e021c_address",
            },
            {
                "dialog_id": "dialog_e021c_address",
                "speaker": "narrator",
                "loc_key": "dialog.e021c.slight.address",
                "tags": ["mainline", "reckoning", "route_c", "rank_address"],
                "next": "dialog_e021c_choice",
            },
            {
                "dialog_id": "dialog_e021c_land_punish",
                "speaker": "narrator",
                "loc_key": "dialog.e021c.slight.land.punish",
                "tags": ["mainline", "reckoning", "route_c", "rank_address"],
                "next": "",
            },
            {
                "dialog_id": "dialog_e021c_land_forgive",
                "speaker": "narrator",
                "loc_key": "dialog.e021c.slight.land.forgive",
                "tags": ["mainline", "reckoning", "route_c", "rank_address"],
                "next": "",
            },
        ]
    )
    new_rows.extend(build_onlooker_branch("e021", "a", "E021"))
    new_rows.extend(build_onlooker_branch("e021b", "b", "E021B"))
    new_rows.extend(build_onlooker_branch("e021c", "c", "E021C"))

    upsert(rows, new_rows)
    save("def_dialog.json", data)

    merge_l10n(
        {
            "dialog.e021.start": "外场的位子坐了几天，前堂的空气已经不一样了。有笔旧账，今天适合当众了结——或者当众按住。",
            "dialog.e021.slight.setup": "钱子安今日又在前堂指手画脚。你站进外场该站的中线——比他想象的更靠中间。",
            "dialog.e021.slight.address": "有人低声试了试：「林外场。」这一声不是玩笑。位子真不真，就看接下来谁先让。",
            "dialog.e021.slight.choice": "（你怎么做？）",
            "dialog.e021b.slight.choice": "（你怎么做？）",
            "dialog.e021c.slight.choice": "（你怎么做？）",
            "dialog.e021.slight.land.punish": "看客把目光钉在中线。少爷退到门边时，没人再敢拿「瑞生」叫你。",
            "dialog.e021.slight.land.forgive": "你仍站中线，却收了刀。看客懂了：不是他没输，是「林外场」准他留脸。",
            "dialog.e021.onlooker.setup": "那几个爱传闲话的人又聚在货箱边。你走过去时，有人下意识让出半步。",
            "dialog.e021.onlooker.address": "有人还没习惯叫你「林外场」——正好，今天让他们习惯。",
            "dialog.e021.onlooker.choice": "（你怎么做？）",
            "dialog.e021.onlooker.a": "惩罚——当众斥回，调开闲差",
            "dialog.e021.onlooker.b": "宽恕——压着他们，收为眼线",
            "dialog.e021.onlooker.punish": "你把话摔在明处。笑声死了。有人脸红到耳根，被派去搬最沉的箱。",
            "dialog.e021.onlooker.forgive": "你本可以让他们当场丢脸。你只淡淡一句：过去的事我记下了；以后嘴严点，有你们的好处。",
            "dialog.e021.onlooker.land.punish": "下层伙计看你的眼神齐了——怕，也是服。新称呼在前堂立住了。",
            "dialog.e021.onlooker.land.forgive": "他们诺诺连声。怕比恨更听话；「林外场」三个字，第一次有了分量。",
            "dialog.e021b.start": "茶楼外的风里，已经有人把「聚丰在谈他」五个字咬热了。旧账若要讨，市井比前堂更适合。",
            "dialog.e021b.slight.setup": "钱子安今日也在街市晃。有人起哄让他「管管」你——你站着，像已经不属于他管的人。",
            "dialog.e021b.slight.address": "茶客里有人咬耳朵：聚丰在谈的，就是这位。闲话比公文快，称呼也跟着变。",
            "dialog.e021b.slight.land.punish": "街市的敬，常常从怕开始。有人起身时，先给你让了半步。",
            "dialog.e021b.slight.land.forgive": "他保住了脸，却知道市井上你已经「值个价」。看客把这一幕记进闲话里。",
            "dialog.e021b.onlooker.setup": "那几张熟脸又在茶桌边起哄。有人看见你，笑意僵了半拍。",
            "dialog.e021b.onlooker.address": "像忽然想起聚丰的名字——也想起，你不再是随便取笑的学徒。",
            "dialog.e021b.onlooker.choice": "（你怎么做？）",
            "dialog.e021b.onlooker.a": "惩罚——当众揭他们势利，让闲话反过来咬人",
            "dialog.e021b.onlooker.b": "宽恕——点破又收手，收他们当耳目",
            "dialog.e021b.onlooker.punish": "你把话放在明处：笑人跟靴的时候，怎不想想自己会不会变成别人嘴里的笑话。茶桌一静。",
            "dialog.e021b.onlooker.forgive": "你本可以让他们在茶客面前抬不起头。你只淡淡道：嘴严点，往后有你们听的。",
            "dialog.e021b.onlooker.land.punish": "有人起身溜了。街市证人改敬——闲话开始改口。",
            "dialog.e021b.onlooker.land.forgive": "他们诺诺。市井里，被放过的人比被踩的人更肯递话。",
            "dialog.e021c.start": "从洋行台阶下来的人，靴底还带着另一边的尘。前堂若再有闲话，你可以选择——借那股势，轻轻压回去。",
            "dialog.e021c.slight.setup": "钱子安又要当众拿你垫话。你站得很稳——像背后有一扇他推不开的门。",
            "dialog.e021c.slight.address": "有人用洋腔学舌「林朋友」。不是职称，是另一套天上的资格——今天要验证它管不管用。",
            "dialog.e021c.slight.land.punish": "看客倒抽凉气。这胜仗脏一点，也爽一点——靠山不用报全名，势已经够用。",
            "dialog.e021c.slight.land.forgive": "他保住了脸，却知道脸是你恩准留下的。狐假虎威，收在刀鞘里更吓人。",
            "dialog.e021c.onlooker.setup": "闲话又起。有人瞥见你袖里那点「洋行的气味」，嗓门矮了。",
            "dialog.e021c.onlooker.address": "「林朋友」三个字不必你自报——看客已经在猜你的靠山。",
            "dialog.e021c.onlooker.choice": "（你怎么做？）",
            "dialog.e021c.onlooker.a": "惩罚——点破靠山，让他们当众塌脸",
            "dialog.e021c.onlooker.b": "宽恕——亮势又收，收为耳目",
            "dialog.e021c.onlooker.punish": "你不必报洋人的名。只需一句「有些路，不是你们配打听的」。笑声死在喉咙里。",
            "dialog.e021c.onlooker.forgive": "你让他们看见刀，又把刀收回鞘。留下一句：嘴严，有你们的好处。",
            "dialog.e021c.onlooker.land.punish": "怕比敬来得快；嫌疑也会跟着长一点。新称呼借势立住了。",
            "dialog.e021c.onlooker.land.forgive": "他们懂——这不是慈悲，是收编。势在袖里，比亮在嘴上更久。",
            "ui.reckon.address_named": "看客改口：%s",
            "ui.reckon.standing.punish": "你站中线。对方退到侧光或门边。看客围成见证场。",
            "ui.reckon.standing.forgive": "你仍站高位。对方保住站位，却失去主动——看客知道是你收了手。",
            "ui.reckon.crowd.punish": "闲话倒戈：这一回，笑的人换了边。",
            "ui.reckon.crowd.forgive": "闲话变短：不是他没输，是你准他留脸。",
        }
    )
    print("P22 light reckon done")


if __name__ == "__main__":
    main()
