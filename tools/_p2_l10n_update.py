# -*- coding: utf-8 -*-
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs/tables/packs/core/l10n"

UPDATES = {
    "zh_CN.csv": {
        "ui.hud.mood": "局势",
        "ui.hud.mood_ease": "尚稳",
        "ui.hud.mood_steady": "绷着",
        "ui.hud.mood_tight": "发紧",
        "ui.hud.mood_crack": "将裂",
        "ui.hud.mood_tip": "晚晴好感 {favor} · 父子张力 {tension} · 嫌疑 {suspicion}",
        "events.ev_a_first_strike.title": "船期易主",
        "events.ev_a_first_strike.body": (
            "通洋的人把本该落在宏远桌上的船期单抽走了。"
            "陈掌柜只留一句：「以后还有。」你的名字第一次钉上竞品的业务墙——"
            "这一刀，不是胜负，是你终于站到了宏远对面。"
        ),
        "event_choices.ch_a_ok.label": "把这一刀记成起点",
        "endings.ending_a.name": "刀已出鞘",
        "endings.ending_a.description": (
            "船期易主。宏远的墙上少了一单，通洋的墙上多了你的名。"
            "你站在对岸回望——有些桥，烧了才走得动。"
        ),
        "events.ev_c_first_short.title": "数字落刀",
        "events.ev_c_first_short.body": (
            "利空落地，宏远的数字像被抽走骨头。"
            "你平掉仓位，手心全是汗——也全是钱。"
            "证券行有人看你一眼：这不是赌博，是你第一次用行情当刀。"
        ),
        "event_choices.ch_c_ok.label": "把第一刀收进袖口",
        "endings.ending_c.name": "刀在账上",
        "endings.ending_c.description": (
            "股价跳水，口袋却沉了。胜负不在码头号子里——在跳动的数字上。"
            "你收起第一刀，才明白：有些仇，可以写进行情。"
        ),
        "quest.wait_route.title": "等第 7 天晚上的抉择",
        "quest.wait_route.hint": (
            "1. 顶栏已到第 7 天||"
            "2. 晚上会弹出方向抉择||"
            "3. 三选一：隐忍离间（B）/ 通洋反戈（A）/ 证券做空（C）||"
            "4. 选完后任务栏会跟着你的路线走"
        ),
        "quest.a_strike.title": "等到船期易主（截胡）",
        "quest.a_strike.hint": (
            "1. 在通洋推进接头、截胡相关行动||"
            "2. 情报与人脉够了会触发「船期易主」||"
            "3. 选「把这一刀记成起点」||"
            "4. 阶段结局「刀已出鞘」即完成本线高潮"
        ),
        "quest.c_short.title": "等到数字落刀（做空）",
        "quest.c_short.hint": (
            "1. 在交易所买卖/做空宏远||"
            "2. 利润与条件到位会触发「数字落刀」||"
            "3. 选「把第一刀收进袖口」||"
            "4. 阶段结局「刀在账上」即完成本线高潮"
        ),
        "quest.day7.title": "第 7 天：三条路将分岔",
        "quest.day7.hint": (
            "1. 继续行动推进到第 7 天||"
            "2. 晚上抉择：隐忍离间 / 通洋反戈 / 证券金融||"
            "3. 通洋与交易所入口会开放||"
            "4. 到第 7 天即完成本任务"
        ),
        "quest.done.title": "主线指引告一段落",
        "quest.done.hint": (
            "1. 可继续自由探索或冲完整日程||"
            "2. 顶栏「局势」会随嫌疑、张力、晚晴关系变化||"
            "3. 嫌疑高就回家休息||"
            "4. 关键抉择前记得保存"
        ),
        "quest.finale.title": "冲刺第 28 天附近",
        "quest.finale.hint": (
            "1. 按你的路线继续推进||"
            "2. 关键抉择前先保存||"
            "3. 推进到第 28 天附近||"
            "4. 留意事件与结局演出"
        ),
        "quest.new_path.hint": (
            "1. 确认已选通洋或证券路线||"
            "2. 走进「通洋商行」或「股票交易所」||"
            "3. 走近门口进入即可||"
            "4. 进去后先看设施列表"
        ),
    },
    "en.csv": {
        "ui.hud.mood": "Climate",
        "ui.hud.mood_ease": "Steady",
        "ui.hud.mood_steady": "Held",
        "ui.hud.mood_tight": "Tight",
        "ui.hud.mood_crack": "Cracking",
        "ui.hud.mood_tip": "Wanqing favor {favor} · Tension {tension} · Suspicion {suspicion}",
        "events.ev_a_first_strike.title": "The Sailing Changes Hands",
        "events.ev_a_first_strike.body": (
            "Tongyang pulls the sailing order that should have sat on Hongyuan's desk. "
            "Manager Chen leaves one line: \"There will be more.\" "
            "Your name is nailed to a rival wall—this cut isn't victory; it's choosing the far bank."
        ),
        "event_choices.ch_a_ok.label": "Mark this cut as the start",
        "endings.ending_a.name": "Blade Drawn",
        "endings.ending_a.description": (
            "The sailing changes hands. Hongyuan loses a line; Tongyang gains your name. "
            "From the far bank you look back—some bridges only move you after they burn."
        ),
        "events.ev_c_first_short.title": "Numbers Cut",
        "events.ev_c_first_short.body": (
            "Bad news lands; Hongyuan's numbers lose their bones. "
            "You flatten the short—palms full of sweat and cash. "
            "Someone at the exchange looks once: this isn't a gamble; it's your first cut with the market."
        ),
        "event_choices.ch_c_ok.label": "Sleeve the first cut",
        "endings.ending_c.name": "Blade in the Ledger",
        "endings.ending_c.description": (
            "Price falls; your pocket grows. Victory isn't in dock chants—it's in the ticking digits. "
            "You pocket the first cut and learn: some grudges belong in the tape."
        ),
        "quest.wait_route.title": "Wait for the Day 7 choice",
        "quest.wait_route.hint": (
            "1. Top bar shows Day 7||"
            "2. Evening brings the route choice||"
            "3. Pick Endure/Divide (B), Tongyang (A), or Exchange (C)||"
            "4. The quest tracker follows your route"
        ),
        "quest.a_strike.title": "Wait for the sailing to change hands",
        "quest.a_strike.hint": (
            "1. Push Tongyang contacts and hijack actions||"
            "2. When intel/network are ready, \"The Sailing Changes Hands\" fires||"
            "3. Choose \"Mark this cut as the start\"||"
            "4. Ending \"Blade Drawn\" completes this climax"
        ),
        "quest.c_short.title": "Wait for the numbers to cut",
        "quest.c_short.hint": (
            "1. Trade / short Hongyuan at the Exchange||"
            "2. When profit conditions land, \"Numbers Cut\" fires||"
            "3. Choose \"Sleeve the first cut\"||"
            "4. Ending \"Blade in the Ledger\" completes this climax"
        ),
        "quest.day7.title": "Day 7: three roads fork",
        "quest.day7.hint": (
            "1. Keep acting until Day 7||"
            "2. Evening choice: Endure / Tongyang / Finance||"
            "3. Tongyang and the Exchange unlock||"
            "4. Reaching Day 7 completes this"
        ),
        "quest.done.title": "Guide paused",
        "quest.done.hint": (
            "1. Explore freely or push the full calendar||"
            "2. Top-bar Climate shifts with suspicion, tension, Wanqing||"
            "3. High suspicion: rest at home||"
            "4. Save before key choices"
        ),
        "quest.finale.title": "Push toward Day 28",
        "quest.finale.hint": (
            "1. Keep your route moving||"
            "2. Save before key choices||"
            "3. Advance near Day 28||"
            "4. Watch events and endings"
        ),
        "quest.new_path.hint": (
            "1. Confirm you chose Tongyang or Exchange||"
            "2. Enter Tongyang Firm or the Stock Exchange||"
            "3. Walk in at the door||"
            "4. Check the facility list inside"
        ),
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
    print(f"{fname}: updated {len(seen)}, appended {len(mapping) - len(seen)}")


if __name__ == "__main__":
    for fname, mapping in UPDATES.items():
        apply(fname, mapping)
