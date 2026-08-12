# -*- coding: utf-8 -*-
"""P14: thicken thin randoms + E018 flashback prose; speaker stage is code-side."""
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
    # R002: speaker + extra beat
    patch_dialog(
        "dialog_r002_start",
        speaker="char_wang_pangzi",
        loc_key="dialog.r002.start",
        tags=["random", "r002"],
        next="dialog_r002_tip",
    )
    upsert_rows(
        "def_dialog.json",
        "dialog_id",
        [
            {
                "dialog_id": "dialog_r002_tip",
                "speaker": "char_wang_pangzi",
                "loc_key": "dialog.r002.tip",
                "tags": ["random", "r002"],
                "next": "dialog_r002_outro",
            },
            {
                "dialog_id": "dialog_r002_outro",
                "speaker": "narrator",
                "loc_key": "dialog.r002.outro",
                "tags": ["random", "r002"],
                "effects": [{"op": "add_range", "key": "stat_intel", "min": 5, "max": 10}],
                "next": "",
            },
            {
                "dialog_id": "dialog_r009_bradley",
                "speaker": "char_bradley",
                "loc_key": "dialog.r009.bradley",
                "tags": ["random", "foreign", "r009"],
                "next": "dialog_r009_outro",
            },
        ],
    )
    # Remove effects from old tip if still present after upsert overwrote tip without effects - good.
    # Re-link R009 start → bradley
    patch_dialog(
        "dialog_r009_start",
        speaker="narrator",
        tags=["random", "foreign", "r009"],
        next="dialog_r009_bradley",
    )
    patch_dialog(
        "dialog_r009_outro",
        speaker="narrator",
        tags=["random", "foreign", "r009"],
        loc_key="dialog.r009.outro",
    )

    # E018 flashback + prose
    patch_dialog("dialog_e018_a_narr", loc_key="dialog.e018.a.narr", tags=["mainline", "ending"])
    patch_dialog("dialog_e018_a_qian", loc_key="dialog.e018.a.qian")
    patch_dialog(
        "dialog_e018_a_demao",
        speaker="narrator",
        loc_key="dialog.e018.a.demao_grudge",
        tags=["mainline", "ending", "flashback"],
    )
    patch_dialog(
        "dialog_e018_a_demao_choice",
        speaker="narrator",
        loc_key="dialog.e018.a.demao_grudge",
        tags=["mainline", "ending", "flashback", "choice"],
    )
    patch_dialog("dialog_e018_a_title", tags=["mainline", "ending"])
    patch_dialog("dialog_e018_a_close", tags=["mainline", "ending"])

    # B/C ending tags
    for did, tags in [
        ("dialog_e018_b_narr", ["mainline", "ending"]),
        ("dialog_e018_b_close", ["mainline", "ending"]),
        ("dialog_e018_c_narr", ["mainline", "ending"]),
    ]:
        patch_dialog(did, tags=tags)

    pack = load("pack.json")
    pack["content_version"] = "1.4.0-p14"
    save("pack.json", pack)

    l10n = load("l10n/zh_CN.json")
    zh = l10n.setdefault("zh_CN", {})
    zh.update(
        {
            "dialog.r002.start": "瑞生，过来。有件事……你自己留心就行，别说是我说的。",
            "dialog.r002.tip": "后院那批货，周管事夜里多点了两盏灯。还有人问你是不是常往账房钻——我替你挡了。",
            "dialog.r002.outro": "王胖子拍拍你肩就走了。话不多，却顶用：商行里刚冒头的动静，你心里有数了。",
            "dialog.r009.start": "一张烫金名片递到你手里——宝顺洋行，白瑞德请你「得空坐坐」。先让你被记住，价码另谈。",
            "dialog.r009.bradley": "林朋友，茶楼说话不方便。宝顺洋行随时欢迎——只谈生意，不谈闲话。先进门，价码才有资格谈。",
            "dialog.r009.outro": "他拱手离去。洋行的门对你开了一道缝——从此你不是路边客，而是可能的门路。",
            "dialog.e018.a.narr": (
                "钱德茂发现账目有出入，怀疑钱子安私吞了一笔货款。"
                "钱子安暴怒，当众和父亲吵了一架，摔门而去。"
                "商行人心惶惶，两个老伙计私下说要走。钱德茂不得不重新倚重林瑞生。"
            ),
            "dialog.e018.a.qian": (
                "瑞生啊，子安不争气。跑街的位置，明天就给你。"
                "后堂的事你也多看着。月例提上去，外头的应酬账也归你经手。"
            ),
            "dialog.e018.a.demao_grudge": (
                "也是这前堂——他说「跑街暂缓」，让你去伺候少爷。"
                "今日他把位子递回来。这账，你是当众撕开，还是接住、记下？"
            ),
            "dialog.e018.a.title": "第一次，有人在你背后叫出完整的三个字：「林跑街。」",
            "dialog.e018.a.close": (
                "林瑞生低着头应了。他能进后堂了——更多账目、更多秘密。"
                "后堂的门只开了一道缝。这不只是个位置：月例更厚，街面上的体面更足，婚事也终于像能往前挪一挪。"
                "光绪十六年的秋天，林瑞生当上了钱记商行的跑街。"
                "可他还没想到：从天津到京城的那条线，不会让一个跑街的小子轻易翻身。暗潮，才刚刚涌动。"
            ),
            "dialog.e018.b.narr": "林瑞生带着钱记的客户名单和几份货情抄件，敲开了聚丰行的侧门。",
            "dialog.e018.b.zhao": (
                "好。从今天起，你是聚丰的跑街，月薪五两。"
                "先办一件事——把钱记那批南洋木材的单子，截过来。"
                "你先前被报价的那份资格，今天算是兑现了第一笔钱。"
            ),
            "dialog.e018.b.title": (
                "赵鸿运说「你是聚丰的跑街」时，没有压嗓子。"
                "门边的伙计、柜上的账房，全都听见了。"
                "这一回，称呼是在另一家门脸底下，明明白白给出来的。"
            ),
            "dialog.e018.b.close": (
                "第一步做成了。钱德茂勃然大怒，却查不到是谁走漏的消息。"
                "月薪五两，比在钱记当学徒像样得多；可这五两不是抬举，是价码。"
                "你拿到的，不只是第一笔更像样的活钱，也是第一张真正属于自己的位子。暗潮换了岸，水一样深。"
            ),
            "dialog.e018.c.narr": (
                "白瑞德邀请林瑞生到宝顺洋行天津分行正式会谈。"
                "茶是锡兰红茶，杯子是官窑青花。"
                "林瑞生没有先谈古董。他递上一封信——周管事手书，称「林瑞生办事妥帖，日后有事可托」。"
            ),
            "dialog.e018.c.bradley": "林朋友，你这封信，比十箱古董都值钱。京中的路子，我在天津找了三年都没找到门。",
            "ui.tag_ending": "结局",
            "ui.tag_random": "街市风声",
        }
    )
    save("l10n/zh_CN.json", l10n)
    print("P14 packs ready")


if __name__ == "__main__":
    main()
