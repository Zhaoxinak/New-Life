# -*- coding: utf-8 -*-
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs/tables/packs/core/l10n"
UP = {
    "zh_CN.csv": {
        "events.ev_a_offer.title": "对岸递来的纸条",
        "events.ev_a_offer.body": (
            "拐角烟未散尽。通洋的人留下一张纸条：有本事带货单来谈——位子给你留着。"
            "你捏着纸边，忽然听见宏远楼里茶盖轻叩：有人已经在对岸等你站过去。"
        ),
        "events.ev_a_d8_smoke.title": "拐角的烟",
        "events.ev_a_d8_smoke.body": (
            "码头拐角的烟散得慢。通洋的人只说：「船期，我们等得起。你等不起。」"
            "烟味里没有安慰，只有一条对岸的路。"
        ),
        "events.ev_a_d28_ready.title": "刀钝之前",
        "events.ev_a_d28_ready.body": (
            "通洋送来短笺：截胡要三样——船名、吨位、装卸班次。缺一样，刀就钝。"
            "你把纸按在膝上：反戈不是口号，是清单。"
        ),
        "events.ev_c_d8_board.title": "第一眼牌价",
        "events.ev_c_d8_board.body": (
            "你第一次认真盯着宏远牌价。数字跳得像潮汐，也像别人的呼吸——"
            "有人靠它吃饭，有人靠它报仇。"
        ),
        "events.ev_c_d28_ready.title": "落刀前夜",
        "events.ev_c_d28_ready.body": (
            "你把仓位、保证金、假话与真话摊在桌上。潮声像倒计时。"
            "金融这把刀，就差最后一割。"
        ),
        "events.ev_c_profit_milestone.title": "口袋沉了",
        "events.ev_c_profit_milestone.body": (
            "你平掉仓位，银元沉甸甸。证券行的人开始叫你「先生」——"
            "不是客气，是承认你手里有刀。"
        ),
        "event_choices.ch_d7_defect.label": "投向通洋，准备反戈一击",
        "event_choices.ch_d7_endure.label": "隐忍留在宏远，慢慢离间",
        "event_choices.ch_d7_finance.label": "进证券行，用行情当刀",
    },
    "en.csv": {
        "events.ev_a_offer.title": "A Note from the Far Bank",
        "events.ev_a_offer.body": (
            "Corner smoke lingers. Tongyang leaves a slip: bring manifests and talk—there is a seat. "
            "Paper edge in hand, you hear a tea lid tap in Hongyuan: someone already waits on the far bank."
        ),
        "events.ev_a_d8_smoke.title": "Corner Smoke",
        "events.ev_a_d8_smoke.body": (
            'Dock-corner smoke clears slowly. Tongyang says only: "Sailings can wait for us. You cannot." '
            "No comfort in the smoke—only a road across."
        ),
        "events.ev_a_d28_ready.title": "Before the Blade Dulls",
        "events.ev_a_d28_ready.body": (
            "Tongyuan sends a scrap: hijack needs three—ship, tonnage, shift. Missing one dulls the blade. "
            "Defection is not a slogan; it is a checklist."
        ),
        "events.ev_c_d8_board.title": "First Look at the Board",
        "events.ev_c_d8_board.body": (
            "You watch Hongyuan's price for real. Digits jump like tide—and like someone else's breath. "
            "Some eat by it. Some avenge by it."
        ),
        "events.ev_c_d28_ready.title": "Night Before the Cut",
        "events.ev_c_d28_ready.body": (
            "Positions, margin, lies and truths on the table. Tide like a countdown. "
            "The finance blade waits for one last cut."
        ),
        "events.ev_c_profit_milestone.title": "The Pocket Grows Heavy",
        "events.ev_c_profit_milestone.body": (
            'You flatten; silver weighs. The exchange starts calling you "sir"—'
            "not courtesy; they see the blade in your hand."
        ),
        "event_choices.ch_d7_defect.label": "Cross to Tongyang—prepare the counterstrike",
        "event_choices.ch_d7_endure.label": "Endure at Hongyuan—divide them slowly",
        "event_choices.ch_d7_finance.label": "Enter the exchange—wield the tape",
    },
}


def apply(fname: str, mapping: dict) -> None:
    path = ROOT / fname
    rows = []
    seen = set()
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        header = next(reader)
        rows.append(header)
        for row in reader:
            if row and row[0] in mapping:
                rows.append([row[0], mapping[row[0]]] + row[2:])
                seen.add(row[0])
            else:
                rows.append(row)
    for key, val in mapping.items():
        if key not in seen:
            rows.append([key, val])
    with path.open("w", encoding="utf-8", newline="") as f:
        csv.writer(f, lineterminator="\n").writerows(rows)
    print(fname, "updated", len(seen))


if __name__ == "__main__":
    for fname, mapping in UP.items():
        apply(fname, mapping)
