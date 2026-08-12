# -*- coding: utf-8 -*-
"""Generate idle chatter pack rows for 暗潮 stage NPCs.
Run: python game/tools/gen_chatter_pack.py
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "packs" / "anchao"


def load(name: str):
    return json.loads((ROOT / name).read_text(encoding="utf-8"))


def save(name: str, data) -> None:
    (ROOT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("wrote", name)


def upsert_dialogs(rows: list[dict]) -> None:
    data = load("def_dialog.json")
    existing = data.get("rows", [])
    index = {str(r.get("dialog_id")): i for i, r in enumerate(existing) if isinstance(r, dict)}
    for nr in rows:
        k = str(nr.get("dialog_id"))
        if k in index:
            existing[index[k]] = nr
        else:
            existing.append(nr)
            index[k] = len(existing) - 1
    data["rows"] = existing
    save("def_dialog.json", data)


def upsert_l10n(pairs: dict[str, str]) -> None:
    data = load("l10n/zh_CN.json")
    zh = data.setdefault("zh_CN", {})
    zh.update(pairs)
    save("l10n/zh_CN.json", data)


def edge_req(frm: str, to: str, tiers: list[str] | None = None, score_op: str | None = None, score_v=None):
    r: dict = {"edge": {"from": frm, "to": to}}
    if tiers:
        r["tier_in"] = tiers
    if score_op is not None:
        r["key"] = "score"
        r["op"] = score_op
        r["value"] = score_v
    return r


def flag_req(fid: str, value=True):
    return {"flag": fid, "value": value}


def dialog(did: str, speaker: str, loc_key: str, effects=None, choices=None, nxt=None):
    row = {
        "dialog_id": did,
        "speaker": speaker,
        "loc_key": loc_key,
        "tags": ["chatter"],
        "effects": effects or [],
    }
    if choices:
        row["choices"] = choices
    elif nxt:
        row["next"] = nxt
    else:
        row["next"] = ""
    return row


def bye_choice():
    return [
        {
            "id": "A",
            "loc_key": "dialog.chat.opt.bye",
            "effects": [],
            "next": "",
        }
    ]


# --- content ---

CHARS = {
    "char_lin_ruisheng": "lin_ruisheng",
    "char_qian_demao": "qian_demao",
    "char_qian_zian": "qian_zian",
    "char_liu_ruyan": "liu_ruyan",
    "char_zhou_guanshi": "zhou_guanshi",
    "char_wang_pangzi": "wang_pangzi",
    "char_bradley": "bradley",
    "char_zhao_hongyun": "zhao_hongyun",
    "char_qing_daren": "qing_daren",
    "char_msg_broker": "msg_broker",
    "char_bank_clerk": "bank_clerk",
    "char_firm_hand": "firm_hand",
}

TEXTS: dict[str, str] = {
    "dialog.chat.opt.bye": "告辞。",
    "ui.chatter_none": "对方正忙，只略一点头。",
    "ui.click_chat": "（左键闲聊 · 右键档案）",
    "ui.chatter_start": "与%s闲谈…",
    "dialog.chat.generic.nod": "对方抬眼看了你一下，又把目光挪开。此刻不宜多言。",
    "dialog.chat.generic.repeat": "刚才已经搭过话了。再盯着，倒像没事找事。",
}

CHATTER_ROWS: list[dict] = []
DIALOGS: list[dict] = []

# generic
DIALOGS.append(
    dialog("dialog_chat_generic_nod", "narrator", "dialog.chat.generic.nod", choices=bye_choice())
)
DIALOGS.append(
    dialog("dialog_chat_generic_repeat", "narrator", "dialog.chat.generic.repeat", choices=bye_choice())
)


def add_line(
    char_id: str,
    short: str,
    suffix: str,
    text: str,
    *,
    priority: int = 10,
    require: list | None = None,
    once: bool = False,
    effects: list | None = None,
    speaker: str | None = None,
):
    did = f"dialog_chat_{short}_{suffix}"
    loc = f"dialog.chat.{short}.{suffix}"
    cid = f"chatter_{short}_{suffix}"
    TEXTS[loc] = text
    DIALOGS.append(dialog(did, speaker or char_id, loc, effects=effects, choices=bye_choice()))
    CHATTER_ROWS.append(
        {
            "chatter_id": cid,
            "char_id": char_id,
            "dialog_id": did,
            "priority": priority,
            "once": once,
            "once_per_slot": True,
            "require": require or [],
        }
    )


def add_fallback(char_id: str, short: str, text: str):
    did = f"dialog_chat_{short}_fallback"
    loc = f"dialog.chat.{short}.fallback"
    TEXTS[loc] = text
    DIALOGS.append(dialog(did, char_id if char_id != "char_lin_ruisheng" else "narrator", loc, choices=bye_choice()))
    # fallback is resolved in code when no chatter matches; still register low priority
    CHATTER_ROWS.append(
        {
            "chatter_id": f"chatter_{short}_fallback",
            "char_id": char_id,
            "dialog_id": did,
            "priority": 0,
            "once": False,
            "once_per_slot": True,
            "require": [],
        }
    )


# Player self-talk
add_fallback("char_lin_ruisheng", "lin_ruisheng", "你低头看了看自己的袖口。银两、婚事、体面——件件压在肩上。")
add_line(
    "char_lin_ruisheng",
    "lin_ruisheng",
    "money",
    "口袋轻得像被掏空。你默念：先把眼前这关熬过去。",
    priority=40,
    require=[{"key": "stat_money", "op": "<=", "value": 15}],
)
add_line(
    "char_lin_ruisheng",
    "lin_ruisheng",
    "heat",
    "钱记的暗账热度，像一根细针扎在后心。你告诫自己：少开口，多看。",
    priority=35,
    require=[{"org": "org_qianji", "key": "firm_heat", "op": ">=", "value": 30}],
)
add_line(
    "char_lin_ruisheng",
    "lin_ruisheng",
    "dawn",
    "你深吸一口气。天津的风里有煤烟与河腥，日子还长。",
    priority=5,
)

# 钱德茂
add_fallback("char_qian_demao", "qian_demao", "钱德茂翻着账册，头也不抬：「有事报管事。没事，别在堂前晃。」")
add_line(
    "char_qian_demao",
    "qian_demao",
    "early",
    "钱德茂搁下笔，目光冷：「林瑞生。眼在活上，嘴少开。」",
    priority=20,
    require=[{"flag": "seen_event_E001", "value": True}],
)
add_line(
    "char_qian_demao",
    "qian_demao",
    "warm",
    "钱德茂难得点头：「账清、人稳，比会说漂亮话有用。」",
    priority=50,
    require=[edge_req("char_qian_demao", "char_lin_ruisheng", ["相善", "厚交"])],
)
add_line(
    "char_qian_demao",
    "qian_demao",
    "heat",
    "东家把折子一合：「外头风声紧。你若再惹眼，莫怪号规无情。」",
    priority=55,
    require=[{"org": "org_qianji", "key": "firm_heat", "op": ">=", "value": 25}],
)
add_line(
    "char_qian_demao",
    "qian_demao",
    "evening",
    "傍晚的前堂只剩算盘声。钱德茂道：「回去歇着。明日还有活。」",
    priority=15,
    require=[{"slot_in": ["evening", "late_night"]}],
)

# 钱子安
add_fallback("char_qian_zian", "qian_zian", "钱子安斜睨你一眼：「学徒也配跟我闲扯？」说完便顾自拨弄袖扣。")
add_line(
    "char_qian_zian",
    "qian_zian",
    "mock",
    "钱子安笑得刺耳：「林瑞生，听说你很会忍。忍久了，牙可要酸。」",
    priority=20,
)
add_line(
    "char_qian_zian",
    "qian_zian",
    "bad",
    "钱子安压低声：「你最好离我远点。看见你，我就想起不痛快的事。」",
    priority=60,
    require=[edge_req("char_qian_zian", "char_lin_ruisheng", ["仇隙", "不睦"])],
)
add_line(
    "char_qian_zian",
    "qian_zian",
    "pursuit",
    "他忽然提起如烟，又立刻改口：「当我没说。你——自己清楚。」",
    priority=45,
    require=[{"meter": "pursuit", "op": ">=", "value": 20}],
)

# 刘如烟
add_fallback("char_liu_ruyan", "liu_ruyan", "刘如烟整理袖边，轻声：「此刻不便多言。你……自己保重。」")
add_line(
    "char_liu_ruyan",
    "liu_ruyan",
    "soft",
    "如烟望着你：「家里还好吗？银钱的事，别一个人硬扛。」",
    priority=25,
)
add_line(
    "char_liu_ruyan",
    "liu_ruyan",
    "money",
    "她压低声音：「婚期一天天近了。你若再这样拮据，娘家那边……会问。」",
    priority=40,
    require=[{"key": "stat_money", "op": "<=", "value": 20}],
)
add_line(
    "char_liu_ruyan",
    "liu_ruyan",
    "good",
    "如烟微微一笑：「看你气色好些了。能喘口气，我也安心。」",
    priority=50,
    require=[edge_req("char_liu_ruyan", "char_lin_ruisheng", ["相善", "厚交"])],
)

# 周管事
add_fallback("char_zhou_guanshi", "zhou_guanshi", "周管事敲敲柜台：「规矩摆在那儿。闲话，留到茶歇。」")
add_line(
    "char_zhou_guanshi",
    "zhou_guanshi",
    "rule",
    "周管事道：「东家眼色比钟准。你想站稳，先把该做的做干净。」",
    priority=20,
)
add_line(
    "char_zhou_guanshi",
    "zhou_guanshi",
    "trust",
    "他难得放缓语气：「号里有人肯替你说句公道话。别把自己作没了。」",
    priority=45,
    require=[{"key": "stat_trust_firm", "op": ">=", "value": 40}],
)

# 王胖子
add_fallback("char_wang_pangzi", "wang_pangzi", "王胖子嘿嘿一笑：「忙着呢——回头喝酒再说。」")
add_line(
    "char_wang_pangzi",
    "wang_pangzi",
    "gossip",
    "王胖子凑近：「街市上有人打听钱记的货。你耳朵竖着点。」",
    priority=25,
    effects=[{"op": "add", "key": "stat_intel", "value": 1}],
    once=True,
)
add_line(
    "char_wang_pangzi",
    "wang_pangzi",
    "wine",
    "他拍肚子：「上回的酒钱……咳，兄弟我记着呢。真的。」",
    priority=35,
    require=[edge_req("char_wang_pangzi", "char_lin_ruisheng", ["相善", "厚交", "泛泛"])],
)
add_line(
    "char_wang_pangzi",
    "wang_pangzi",
    "pal",
    "王胖子挤挤眼：「自己人。后院那点破事，我帮你捂着。」",
    priority=50,
    require=[edge_req("char_wang_pangzi", "char_lin_ruisheng", ["相善", "厚交"])],
)

# 白瑞德
add_fallback("char_bradley", "bradley", "白瑞德用半生不熟的官话：「稍等。风声——未到。」")
add_line(
    "char_bradley",
    "bradley",
    "wait",
    "白瑞德点头：「林先生。宝顺做事，要看潮。潮未至，莫急。」",
    priority=20,
)
add_line(
    "char_bradley",
    "bradley",
    "impress",
    "他难得多说一句：「你的名字，我听过几次。不错。」",
    priority=50,
    require=[{"meter": "impression_bradley", "op": ">=", "value": 15}],
)

# 赵宏运
add_fallback("char_zhao_hongyun", "zhao_hongyun", "赵宏运抱拳：「聚丰有规矩。闲聊，改日茶楼见。」")
add_line(
    "char_zhao_hongyun",
    "zhao_hongyun",
    "probe",
    "赵宏运似笑非笑：「钱记待你如何？若觉得窄，天津不只有一家字号。」",
    priority=25,
)
add_line(
    "char_zhao_hongyun",
    "zhao_hongyun",
    "route",
    "他压低声：「门，永远为识货的人留着。你何时想清楚，来找我。」",
    priority=55,
    require=[{"flag": "route_defect", "value": True}],
)

# 青大人
add_fallback("char_qing_daren", "qing_daren", "青大人袖手而立，只淡淡看你一眼，并不答话。")
add_line(
    "char_qing_daren",
    "qing_daren",
    "cold",
    "青大人开口，字句极慢：「商贾言利。你若无贴己事，不必近前。」",
    priority=20,
)
add_line(
    "char_qing_daren",
    "qing_daren",
    "heat",
    "他意味深长：「有些账，写在纸上；有些账，写在官面上。」",
    priority=50,
    require=[{"org": "org_qianji", "key": "firm_heat", "op": ">=", "value": 35}],
)

# 消息通
add_fallback("char_msg_broker", "msg_broker", "消息通掂掂手指：「嘴皮子也是价。五两以下，免开尊口。」")
add_line(
    "char_msg_broker",
    "msg_broker",
    "sell",
    "消息通笑：「林相公今日只聊天？聊天免费——真消息，另算。」",
    priority=20,
)
add_line(
    "char_msg_broker",
    "msg_broker",
    "hint",
    "他丢下一句：「码头夜里比白天热闹。你若去，带眼睛，别带嘴。」",
    priority=40,
    once=True,
    effects=[{"op": "add", "key": "stat_intel", "value": 1}],
)

# 柜员
add_fallback("char_bank_clerk", "bank_clerk", "柜员抱着簿子：「票号柜台，谈钱不谈天。」")
add_line(
    "char_bank_clerk",
    "bank_clerk",
    "credit",
    "柜员看了看你：「信用这东西，涨得慢，跌得快。林相公……留意。」",
    priority=20,
)
add_line(
    "char_bank_clerk",
    "bank_clerk",
    "good",
    "他语气稍缓：「簿上有你的名字，且是干净的。难得。」",
    priority=45,
    require=[{"key": "stat_credit_bank", "op": ">=", "value": 40}],
)

# 后院伙计
add_fallback("char_firm_hand", "firm_hand", "伙计扛着筐过去：「忙！回头再说。」")
add_line(
    "char_firm_hand",
    "firm_hand",
    "work",
    "伙计擦汗：「后院活多。东家一拍桌子，咱们腿就得跑。」",
    priority=20,
)
add_line(
    "char_firm_hand",
    "firm_hand",
    "pal",
    "他小声：「你若被前堂挤兑，跟胖子说一声。后院不是木头人。」",
    priority=40,
    require=[edge_req("char_firm_hand", "char_lin_ruisheng", ["相善", "厚交", "泛泛"])],
)


def main():
    # help / ui strings merge
    TEXTS["ui.help_body"] = (
        "[b]怎么玩[/b]\n"
        "1. 底部换地点；场景上点【家具热区】选行动。\n"
        "2. [b]左键点小人[/b]闲聊；[b]右键[/b]或对话头像/姓名打开档案；[b]C[/b] 本档。\n"
        "3. [b]J[/b] 账簿（本档/人物/往来/暗线）；[b]H[/b] 说明。\n"
        "4. 「歇一口气」推进时段；空格推进对白。\n\n"
        "[b]建议试玩[/b]\n"
        "· A 隐忍：前堂干活堆信任。\n"
        "· B 跳槽：街市结交接触竞品。\n"
        "· C 洋行：宝顺接佣金。"
    )

    save(
        "def_chatter.json",
        {
            "rows": CHATTER_ROWS,
        },
    )
    upsert_dialogs(DIALOGS)
    upsert_l10n(TEXTS)

    # pack.json register
    pack = load("pack.json")
    tables = pack.get("tables", [])
    if not any(t.get("name") == "def_chatter" for t in tables):
        # insert after def_dialog
        idx = next((i for i, t in enumerate(tables) if t.get("name") == "def_dialog"), len(tables) - 1)
        tables.insert(idx + 1, {"name": "def_chatter", "file": "def_chatter.json"})
        pack["tables"] = tables
        save("pack.json", pack)
    print("chatter rows", len(CHATTER_ROWS), "dialogs", len(DIALOGS))


if __name__ == "__main__":
    main()
