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
    print(path, len(updates))


zh = {
    "scratch.vendor.intro": "摊主把一张银箔票拍在木板上：十块一张——想刮几张刮几张，刮爽了再说。",
    "scratch.vendor.again": "摊主又抽出一张：手还热着？接着刮——银元还在桌上响。",
    "scratch.vendor.start": "银箔沙沙响。摊主笑：轻一点——刮爽了再停。",
    "scratch.vendor.broke": "摊主撇嘴：口袋空空还想碰运气？先去码头扛两箱——或先收工。",
    "scratch.hint.buy": "买一张就刮；揭晓后可连刮，点「收工走人」才过时段。",
    "scratch.hint.again": "再买一张继续刮，或点「收工走人」结束这一时段。",
    "scratch.hint.done_chain": "奖金已入袋。再刮一张，或收工走人（才过时段）。",
    "scratch.btn.again": "再刮一张（{cost} 银元）",
    "scratch.btn.again_quick": "再来！",
    "scratch.btn.leave": "收工走人",
    "scratch.session.empty": "还没开刮 · 想刮几张刮几张",
    "scratch.session.stats": "已刮 {n} 张 · 花 {spent} / 中 {won} · 盈亏 {net}",
    "scratch.progress.session": "刮开 {pct}% · 第 {n} 张 · 盈亏 {net}",
    "scratch.session.summary": "连刮 {n} 张：花 {spent}、中 {won}、盈亏 {net}。最佳：{best}",
    "tip.plaza_scratch": "广场「港彩刮刮乐」：10银元一张，揭晓后可连刮到爽；点「收工走人」才过时段。没买可取消。",
    "actions.plaza_scratch.description": "花十块买银箔票，可连刮多张，刮爽了再收工。",
    "actions.plaza_scratch.result": "箔屑还粘在指甲缝里。这阵连刮，算进这一时段了。",
}
en = {
    "scratch.vendor.intro": "The stallkeeper slaps a foil ticket down: ten silver each — scratch as many as you want.",
    "scratch.vendor.again": "Another ticket slides out: hand still hot? Keep going.",
    "scratch.vendor.start": "Foil whispers. Go gentle — stop when you have had enough.",
    "scratch.vendor.broke": "Empty pockets? Haul crates first — or clock out.",
    "scratch.hint.buy": "Buy one and scratch; chain as many as you like. Leave ends the period.",
    "scratch.hint.again": "Buy another, or Leave to end this period.",
    "scratch.hint.done_chain": "Paid out. Scratch another, or Leave (ends the period).",
    "scratch.btn.again": "Scratch another ({cost} silver)",
    "scratch.btn.again_quick": "Again!",
    "scratch.btn.leave": "Clock out",
    "scratch.session.empty": "No tickets yet — scratch as many as you want",
    "scratch.session.stats": "Tickets {n} · spent {spent} / won {won} · net {net}",
    "scratch.progress.session": "Cleared {pct}% · ticket {n} · net {net}",
    "scratch.session.summary": "Scratched {n}: spent {spent}, won {won}, net {net}. Best: {best}",
    "tip.plaza_scratch": "Harbor Scratch Tickets: 10 silver each, chain as many as you like; Leave ends the period. Cancel if you buy none.",
    "actions.plaza_scratch.description": "Buy foil tickets for ten silver; keep chaining until you clock out.",
    "actions.plaza_scratch.result": "Foil dust under your nails. That binge is written into this period.",
}
upsert(r"f:\Games\New-Life\docs\tables\packs\core\l10n\zh_CN.csv", zh)
upsert(r"f:\Games\New-Life\docs\tables\packs\core\l10n\en.csv", en)
