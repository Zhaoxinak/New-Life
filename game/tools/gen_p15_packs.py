# -*- coding: utf-8 -*-
"""P15: thicken R001/R006/R007/R008 with character voice beats."""
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


def main() -> None:
    upsert_rows(
        "def_dialog.json",
        "dialog_id",
        [
            # R001: tipster voice
            {
                "dialog_id": "dialog_r001_broker",
                "speaker": "char_msg_broker",
                "loc_key": "dialog.r001.broker",
                "tags": ["random", "r001"],
                "next": "dialog_r001_pay",
            },
            {
                "dialog_id": "dialog_r001_pay",
                "speaker": "narrator",
                "loc_key": "dialog.r001.pay",
                "tags": ["random", "r001"],
                "effects": [
                    {"op": "add", "key": "stat_money", "value": -5},
                    {"op": "add_range", "key": "stat_intel", "min": 3, "max": 8},
                ],
                "next": "",
            },
            # R006: clerk voice + outro keep effects on clerk end
            {
                "dialog_id": "dialog_r006_clerk",
                "speaker": "char_bank_clerk",
                "loc_key": "dialog.r006.clerk",
                "tags": ["random", "r006"],
                "next": "dialog_r006_outro",
            },
            {
                "dialog_id": "dialog_r006_outro",
                "speaker": "narrator",
                "loc_key": "dialog.r006.outro",
                "tags": ["random", "r006"],
                "effects": [
                    {"op": "set_flag", "key": "flag_bank_tier2", "value": True},
                    {"op": "add", "key": "stat_credit_bank", "value": 15},
                ],
                "next": "",
            },
            # R007: wang warning
            {
                "dialog_id": "dialog_r007_warn",
                "speaker": "char_wang_pangzi",
                "loc_key": "dialog.r007.warn",
                "tags": ["random", "pressure", "r007"],
                "next": "dialog_r007_feel",
            },
            {
                "dialog_id": "dialog_r007_feel",
                "speaker": "narrator",
                "loc_key": "dialog.r007.feel",
                "tags": ["random", "pressure", "r007"],
                "effects": [
                    {"op": "set_temp", "key": "plot_success_mod", "value": -0.3},
                    {"op": "set_flag", "key": "flag_surveilled_today", "value": True},
                ],
                "next": "",
            },
            # R008: firm hand
            {
                "dialog_id": "dialog_r008_gossip",
                "speaker": "char_firm_hand",
                "loc_key": "dialog.r008.gossip",
                "tags": ["random", "r008"],
                "next": "dialog_r008_outro",
            },
            {
                "dialog_id": "dialog_r008_outro",
                "speaker": "narrator",
                "loc_key": "dialog.r008.outro",
                "tags": ["random", "r008"],
                "effects": [{"op": "add_range", "key": "stat_intel", "min": 2, "max": 5}],
                "next": "",
            },
        ],
    )

    patch_dialog(
        "dialog_r001_start",
        speaker="narrator",
        tags=["random", "r001"],
        next="dialog_r001_broker",
        loc_key="dialog.r001.start",
    )
    patch_dialog(
        "dialog_r006_start",
        speaker="narrator",
        tags=["random", "r006"],
        next="dialog_r006_clerk",
        loc_key="dialog.r006.start",
    )
    patch_dialog(
        "dialog_r007_start",
        speaker="narrator",
        tags=["random", "pressure", "r007"],
        next="dialog_r007_warn",
        loc_key="dialog.r007.start",
    )
    patch_dialog(
        "dialog_r008_start",
        speaker="narrator",
        tags=["random", "r008"],
        next="dialog_r008_gossip",
        loc_key="dialog.r008.start",
    )

    pack = load("pack.json")
    pack["content_version"] = "1.5.0-p15"
    save("pack.json", pack)

    l10n = load("l10n/zh_CN.json")
    zh = l10n.setdefault("zh_CN", {})
    zh.update(
        {
            "char_msg_broker": "消息通",
            "char_bank_clerk": "票号柜员",
            "char_firm_hand": "后院伙计",
            "dialog.r001.start": "茶楼角落里，一个跑码头的消息通拍了拍桌子，朝你挤眼。",
            "dialog.r001.broker": "林师兄，喝茶？有点新鲜的——票号、洋行、钱记，今儿都有动静。五两，我把能听的都给你筛一遍。",
            "dialog.r001.pay": "五两银子换来几句半真半假的街谈。你挑着听，记下能对上号的门道，也记下了：消息跟银子一样，越急越贵。",
            "dialog.r006.start": "钱庄掌柜派人送来一张帖子，请你「有空过来一叙」。柜面的口气，已不像对零碎客。",
            "dialog.r006.clerk": "林爷手头宽裕了。票号这边有些高阶往来，可以谈——展期、汇兑门面，往后都好说话。",
            "dialog.r006.outro": "五十两不算巨富，却已够让钱庄把你从“跑腿小子”看成“能周转的人”。高阶往来的门，开了。",
            "dialog.r007.start": "你走到哪儿，背后总像跟了双眼睛。伙计的目光躲闪，拐角处有人假装整理货单。",
            "dialog.r007.warn": "瑞生，今儿后院多了双闲眼睛。东家疑心重，你走路留神——别让人抓住把柄。",
            "dialog.r007.feel": "被盯上的感觉贴着脊背。今日再动歪心思，失手的可能大得多。",
            "dialog.r008.start": "午后闲档，两个伙计在后院压着嗓子扯闲篇，见你走近，犹豫片刻还是把你拉进了话里。",
            "dialog.r008.gossip": "东家这两日火气大，少爷又在外头赊账。夜里还有车进后院，不走大门——你自己掂量。",
            "dialog.r008.outro": "七嘴八舌里，总有一两句能拼进你的账。你点头谢过，把能用的门道悄悄记下。",
        }
    )
    save("l10n/zh_CN.json", l10n)
    print("P15 packs ready")


if __name__ == "__main__":
    main()
