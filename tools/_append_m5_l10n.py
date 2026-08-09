# -*- coding: utf-8 -*-
from pathlib import Path

zh = Path(r"f:\Games\New-Life\docs\tables\packs\core\l10n\zh_CN.csv")
en = Path(r"f:\Games\New-Life\docs\tables\packs\core\l10n\en.csv")
zh_lines = [
    "matter.matter_dock_hands.title,码头缺人手",
    "matter.matter_dock_hands.body,货场这会儿缺一双手。接下后过几小时结算辛苦钱。",
    "matter.matter_tea_word.title,茶馆传句话",
    "matter.matter_tea_word.body,堂口要人把话带到。不费事，能换点消息。",
    "matter.matter_plaza_errand.title,广场跑腿",
    "matter.matter_plaza_errand.body,摊位缺人送一趟。腿脚勤快就有小钱。",
    "matter.matter_night_watch.title,夜码头盯梢",
    "matter.matter_night_watch.body,晚上码头要多一双眼。留意动静，能攒点情报。",
    "matter.offer,港区出了件事：「{name}」（{place}）。按 L 打开世界日志可接下。",
    "matter.accept,{who}接下了「{name}」。",
    "matter.expire,「{name}」没人接手，散了。",
    "matter.done,{who}了结了「{name}」。",
    "journal.matter.matter_dock_hands,听说他帮码头出过手。",
    "journal.matter.matter_tea_word,茶馆传话里有他的名字。",
    "journal.matter.matter_plaza_errand,广场跑腿见过他。",
    "journal.matter.matter_night_watch,夜码头盯梢时有他。",
    "world_log.period_cross,时辰转到{period}。",
    "world_log.weather,天色转：{name}",
    "world_log.action,你做完了：{name}",
    "world_log.raw,{text}",
    "ui.world_log.title,世界日志",
    "ui.world_log.hint,L 开关 · 可接下港区事项",
    "ui.world_log.close,关闭",
    "ui.world_log.filter_all,全部",
    "ui.world_log.filter_matter,事项",
    "ui.world_log.filter_beat,巷闻",
    "ui.world_log.filter_period,时辰",
    "ui.world_log.filter_weather,天气",
    "ui.world_log.no_matter,眼下没有等人接手的港区事项。",
    "ui.world_log.accept,接下这事",
    "ui.world_log.matter_doing,进行中：{name}",
    "ui.world_log.matter_meta,地点 {place} · 约 {clock} 前了结",
    "ui.world_log.line_head,第{day}日 {clock} · {period}",
    "ui.matter.you,你",
    "tip.matter_offer,港区出了公共事项。按 L 打开世界日志，可接下或看别人抢了没有。",
    "tip.matter_accept,你接下了事项。过几小时会结算；日志里能回看。",
    "ui.dossier.day_period_clock,第{day}日 · {period} {clock}",
]
en_lines = [
    "matter.matter_dock_hands.title,Dock needs hands",
    "matter.matter_dock_hands.body,The yard is short-handed. Accept and get paid after a few hours.",
    "matter.matter_tea_word.title,Tea-house message",
    "matter.matter_tea_word.body,Pass a word along the hall. Easy intel.",
    "matter.matter_plaza_errand.title,Plaza errand",
    "matter.matter_plaza_errand.body,A stall needs a quick run. Small cash.",
    "matter.matter_night_watch.title,Night dock watch",
    "matter.matter_night_watch.body,Keep an eye on the pier tonight. Intel later.",
    'matter.offer,A harbor matter appeared: "{name}" ({place}). Press L to accept.',
    'matter.accept,{who} took "{name}".',
    'matter.expire,"{name}" expired unclaimed.',
    'matter.done,{who} finished "{name}".',
    "journal.matter.matter_dock_hands,Heard he helped at the dock.",
    "journal.matter.matter_tea_word,His name was in a tea-house pass-along.",
    "journal.matter.matter_plaza_errand,Seen on a plaza errand.",
    "journal.matter.matter_night_watch,Spotted on night dock watch.",
    "world_log.period_cross,Period shifted to {period}.",
    "world_log.weather,Weather: {name}",
    "world_log.action,You finished: {name}",
    "world_log.raw,{text}",
    "ui.world_log.title,World Log",
    "ui.world_log.hint,L to toggle · accept harbor matters",
    "ui.world_log.close,Close",
    "ui.world_log.filter_all,All",
    "ui.world_log.filter_matter,Matters",
    "ui.world_log.filter_beat,Gossip",
    "ui.world_log.filter_period,Time",
    "ui.world_log.filter_weather,Weather",
    "ui.world_log.no_matter,No open harbor matters right now.",
    "ui.world_log.accept,Accept",
    "ui.world_log.matter_doing,In progress: {name}",
    "ui.world_log.matter_meta,At {place} · settle by {clock}",
    "ui.world_log.line_head,Day {day} {clock} · {period}",
    "ui.matter.you,You",
    "tip.matter_offer,A public matter appeared. Press L to open the World Log and accept it.",
    "tip.matter_accept,You accepted a matter. It settles in a few hours; check the log.",
    "ui.dossier.day_period_clock,Day {day} · {period} {clock}",
]
for path, lines in ((zh, zh_lines), (en, en_lines)):
    text = path.read_text(encoding="utf-8")
    if not text.endswith("\n"):
        text += "\n"
    # skip duplicates
    existing = set()
    for line in text.splitlines():
        if "," in line:
            existing.add(line.split(",", 1)[0])
    add = [ln for ln in lines if ln.split(",", 1)[0] not in existing]
    if add:
        text += "\n".join(add) + "\n"
        path.write_text(text, encoding="utf-8")
print("l10n ok", len(zh_lines))
