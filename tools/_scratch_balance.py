# -*- coding: utf-8 -*-
from pathlib import Path


def upsert(path: str, updates: dict) -> None:
    p = Path(path)
    lines = p.read_text(encoding="utf-8-sig").splitlines()
    out, seen = [], set()
    for line in lines:
        if not line.strip() or "," not in line:
            out.append(line)
            continue
        key = line.split(",", 1)[0]
        if key in updates:
            val = updates[key]
            if "," in val or '"' in val:
                out.append(f'{key},"{val.replace(chr(34), chr(34)+chr(34))}"')
            else:
                out.append(f"{key},{val}")
            seen.add(key)
        else:
            out.append(line)
    for k, val in updates.items():
        if k in seen:
            continue
        if "," in val or '"' in val:
            out.append(f'{k},"{val.replace(chr(34), chr(34)+chr(34))}"')
        else:
            out.append(f"{k},{val}")
    p.write_text("\n".join(out) + "\n", encoding="utf-8")


zh = {
    "scratch.prize.small.title": "小彩 · 6 银元",
    "scratch.prize.small.body": "几枚零钱。不够回本，够摊主再递一张。",
    "scratch.prize.mid.title": "中彩 · 18 银元",
    "scratch.prize.mid.body": "略赚一截。摊主笑：运气热了？再来一张呗。",
    "scratch.prize.big.title": "大彩 · 50 银元",
    "scratch.prize.big.body": "厚一点了。码头有人侧目——别连刮到吐。",
    "scratch.prize.jackpot.title": "头彩 · 120 银元",
    "scratch.prize.jackpot.body": "少见的厚彩。银元烫手；多数时候庄家才是赢家。",
    "scratch.burst.small": "+6",
    "scratch.burst.mid": "+18",
    "scratch.burst.big": "+50！",
    "scratch.burst.jackpot": "头彩！",
    "scratch.vendor.intro": "摊主把银箔票拍在木板上：十块一张。庄家总要吃一口——想刮几张随便，别指望越刮越富。",
    "tip.plaza_scratch": "「港彩刮刮乐」可连刮，但庄家抽成：多数回不了本，偶有大彩。点「收工走人」才过时段。",
}
en = {
    "scratch.prize.small.title": "Small win · 6 silver",
    "scratch.prize.small.body": "Loose change. Not enough to break even — enough for another ticket.",
    "scratch.prize.mid.title": "Mid win · 18 silver",
    "scratch.prize.mid.body": "A thin profit. He grins: hot hand? One more?",
    "scratch.prize.big.title": "Big win · 50 silver",
    "scratch.prize.big.body": "A thicker fold. Eyes turn — don't binge until you're empty.",
    "scratch.prize.jackpot.title": "Jackpot · 120 silver",
    "scratch.prize.jackpot.body": "A rare thick hit. Silver burns; the house still wins most nights.",
    "scratch.burst.small": "+6",
    "scratch.burst.mid": "+18",
    "scratch.burst.big": "+50!",
    "scratch.burst.jackpot": "JACKPOT!",
    "scratch.vendor.intro": "Foil tickets: ten silver each. The house takes a cut — scratch as many as you like, don't expect to get rich.",
    "tip.plaza_scratch": "Scratch tickets chain, but the house edges you: most don't break even. Leave ends the period.",
}
upsert(r"f:\Games\New-Life\docs\tables\packs\core\l10n\zh_CN.csv", zh)
upsert(r"f:\Games\New-Life\docs\tables\packs\core\l10n\en.csv", en)
print("ok")
