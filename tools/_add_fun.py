# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r"f:\Games\New-Life\docs\tables\packs\core")


def append_rows(rel: str, rows: list[str]) -> None:
    path = ROOT / rel
    text = path.read_text(encoding="utf-8-sig")
    if not text.endswith("\n"):
        text += "\n"
    to_add = []
    for row in rows:
        key = row.split(",", 1)[0]
        if f"\n{key}," in text or text.startswith(f"{key},"):
            print("skip", rel, key)
            continue
        to_add.append(row)
    if to_add:
        path.write_text(text + "\n".join(to_add) + "\n", encoding="utf-8")
        print(rel, "+", len(to_add))


def upsert_l10n(rel: str, updates: dict) -> None:
    path = ROOT / rel
    lines = path.read_text(encoding="utf-8-sig").splitlines()
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
    path.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(rel, "upsert", len(updates))


def patch_action_row(action_id: str, mut) -> None:
    path = ROOT / "actions.csv"
    lines = path.read_text(encoding="utf-8-sig").splitlines()
    out = []
    for line in lines:
        if line.startswith(action_id + ","):
            parts = line.split(",")
            parts = mut(parts)
            line = ",".join(parts)
            print("patched", action_id)
        out.append(line)
    path.write_text("\n".join(out) + "\n", encoding="utf-8")


def remove_effect_ids(ids: set) -> None:
    path = ROOT / "effects.csv"
    lines = path.read_text(encoding="utf-8-sig").splitlines()
    out = [lines[0]]
    removed = 0
    for line in lines[1:]:
        key = line.split(",", 1)[0]
        if key in ids:
            removed += 1
            continue
        out.append(line)
    path.write_text("\n".join(out) + "\n", encoding="utf-8")
    print("removed effects", removed)


# Convert plaza_dice to arcade minigame (no check / dialogue)
def _dice_mut(parts):
    # id,hotspot,periods,tags,time,sus,cd,max,sort,en,notes,dlg,stock,check
    while len(parts) < 14:
        parts.append("")
    parts[3] = "all|gamble|minigame_dice"
    parts[6] = "0"
    parts[7] = "1"  # one session / day; chain inside
    parts[10] = "交互掷骰小游戏"
    parts[11] = ""
    parts[12] = ""
    parts[13] = ""
    return parts


patch_action_row("plaza_dice", _dice_mut)

# Remove old dice stake/check money (arcade handles purse)
remove_effect_ids({
    "fx_plaza_dice_stake",
    "fx_chk_plaza_dice_win",
    "fx_chk_plaza_dice_win_net",
    "fx_chk_plaza_dice_lose_sus",
})

append_rows(
    "locations.csv",
    ["tea_house,afternoon|evening,all,7,1,1,港湾茶馆：听书、掮客、敬酒"],
)
append_rows(
    "hotspots.csv",
    [
        "tea_corner,tea_house,0.1,afternoon|evening,leisure,21,1,1,320,620,堂口闲坐",
        "tea_backroom,tea_house,0.4,evening,intel|plot,22,1,1,700,420,后间",
        "tea_stage,tea_house,0.0,afternoon|evening,leisure,23,1,1,500,500,说书台",
    ],
)
append_rows(
    "actions.csv",
    [
        "plaza_morra,plaza_court,afternoon|evening,all|gamble|minigame_morra,1,0,0,1,56,1,交互豁拳,,,",
        "dock_fish,dock_board,afternoon|evening,all|leisure|minigame_fish,1,0,0,2,57,1,码头钓鱼时机条,,,",
        "tea_gossip,tea_corner,afternoon|evening,all,1,0,0,2,58,1,茶馆闲聊买消息,dlg_tea_gossip,,",
        "tea_toast,tea_corner,evening,all,1,0,0,2,59,1,敬酒交朋友,dlg_tea_toast,,",
        "tea_broker,tea_backroom,evening,all,1,0,2,1,60,1,后间掮客（冷却2天）,dlg_tea_broker,,",
        "tea_listen,tea_stage,afternoon|evening,all,1,0,1,1,61,1,听一段书,dlg_tea_listen,,",
    ],
)
append_rows(
    "conditions.csv",
    [
        "c_act_tea_gossip_money,action,tea_gossip,1,stat,money,gte,5,",
        "c_act_tea_toast_money,action,tea_toast,1,stat,money,gte,8,",
        "c_act_tea_broker_money,action,tea_broker,1,stat,money,gte,20,",
    ],
)
append_rows(
    "dialogues.csv",
    [
        "dlg_tea_gossip,all,50,0,1,茶馆闲聊",
        "dlg_tea_toast,all,50,0,1,敬酒",
        "dlg_tea_broker,all,50,0,1,后间掮客",
        "dlg_tea_listen,all,50,0,1,听书",
    ],
)
append_rows(
    "dialogue_lines.csv",
    [
        "dlg_tea_gossip_l01,dlg_tea_gossip,1,narrator,neutral,1,",
        "dlg_tea_gossip_l02,dlg_tea_gossip,2,player,resolve,1,",
        "dlg_tea_gossip_l03,dlg_tea_gossip,3,narrator,neutral,1,",
        "dlg_tea_toast_l01,dlg_tea_toast,1,narrator,soft,1,",
        "dlg_tea_toast_l02,dlg_tea_toast,2,player,resolve,1,",
        "dlg_tea_toast_l03,dlg_tea_toast,3,narrator,neutral,1,",
        "dlg_tea_broker_l01,dlg_tea_broker,1,narrator,cold,1,",
        "dlg_tea_broker_l02,dlg_tea_broker,2,player,tense,1,",
        "dlg_tea_broker_l03,dlg_tea_broker,3,narrator,neutral,1,",
        "dlg_tea_listen_l01,dlg_tea_listen,1,narrator,soft,1,",
        "dlg_tea_listen_l02,dlg_tea_listen,2,player,resolve,1,",
        "dlg_tea_listen_l03,dlg_tea_listen,3,narrator,soft,1,",
    ],
)
append_rows(
    "dialogue_choices.csv",
    [
        "dch_dlg_tea_gossip_ok,dlg_tea_gossip,dlg_tea_gossip_l03,1,1,",
        "dch_dlg_tea_toast_ok,dlg_tea_toast,dlg_tea_toast_l03,1,1,",
        "dch_dlg_tea_broker_ok,dlg_tea_broker,dlg_tea_broker_l03,1,1,",
        "dch_dlg_tea_broker_pass,dlg_tea_broker,dlg_tea_broker_l03,2,1,少付少听",
        "dch_dlg_tea_listen_ok,dlg_tea_listen,dlg_tea_listen_l03,1,1,",
    ],
)
append_rows(
    "effects.csv",
    [
        "fx_tea_gossip_money,action,tea_gossip,stat,,money,add,-5,1,",
        "fx_tea_gossip_intel,action,tea_gossip,stat,,intel,add,4,1,",
        "fx_tea_gossip_sus,action,tea_gossip,stat,,suspicion,add,1,1,",
        "fx_tea_toast_money,action,tea_toast,stat,,money,add,-8,1,",
        "fx_tea_toast_net,action,tea_toast,stat,,network_base,add,3,1,",
        "fx_tea_toast_sus,action,tea_toast,stat,,suspicion,add,-2,1,",
        "fx_tea_broker_ok_money,dialogue_choice,dch_dlg_tea_broker_ok,stat,,money,add,-20,1,",
        "fx_tea_broker_ok_intel,dialogue_choice,dch_dlg_tea_broker_ok,stat,,intel,add,10,1,",
        "fx_tea_broker_ok_elite,dialogue_choice,dch_dlg_tea_broker_ok,stat,,network_elite,add,2,1,",
        "fx_tea_broker_ok_sus,dialogue_choice,dch_dlg_tea_broker_ok,stat,,suspicion,add,4,1,",
        "fx_tea_broker_pass_money,dialogue_choice,dch_dlg_tea_broker_pass,stat,,money,add,-8,1,",
        "fx_tea_broker_pass_intel,dialogue_choice,dch_dlg_tea_broker_pass,stat,,intel,add,4,1,",
        "fx_tea_listen_sus,action,tea_listen,stat,,suspicion,add,-4,1,",
        "fx_tea_listen_intel,action,tea_listen,stat,,intel,add,2,1,",
        "fx_dch_tea_listen_net,dialogue_choice,dch_dlg_tea_listen_ok,stat,,network_base,add,1,1,",
    ],
)
append_rows(
    "idle_chatter.csv",
    [
        "chatter_tea_01,tea_house,,afternoon|evening,all,10,1,1,",
        "chatter_tea_02,tea_house,tea_stage,any,all,8,1,1,",
    ],
)
append_rows(
    "tips.csv",
    [
        "tip_tea_house,unlock,35,tip.tea_house,1,1,",
        "tip_arcade,unlock,36,tip.arcade,1,1,",
    ],
)

zh = {
    "locations.tea_house.name": "港湾茶馆",
    "locations.tea_house.description": "醒木、热茶、后间交易——码头边上的耳朵与嗓子。",
    "hotspots.tea_corner.name": "堂口茶座",
    "hotspots.tea_corner.description": "谁都坐得下，谁的话都可能是真的。",
    "hotspots.tea_backroom.name": "后间雅座",
    "hotspots.tea_backroom.description": "门帘一落，价钱比茶贵。",
    "hotspots.tea_stage.name": "说书台",
    "hotspots.tea_stage.description": "醒木一响，故事比新闻还快。",
    "unlock.location.tea_house": "开局开放 · 听书与闲话",
    "actions.plaza_dice.name": "棚下掷骰",
    "actions.plaza_dice.description": "开盅比大小，可连玩；收工才过时段。",
    "actions.plaza_dice.result": "骰子停了。手气写进这一时段。",
    "actions.plaza_morra.name": "豁拳定输赢",
    "actions.plaza_morra.description": "出0～5比大小，可连豁；收工才过时段。",
    "actions.plaza_morra.result": "嗓子还哑着。酒钱有了着落，或没有。",
    "actions.dock_fish.name": "堤边钓鱼",
    "actions.dock_fish.description": "看准绿区起竿。手感活，空军也只丢面子。",
    "actions.dock_fish.result": "竿收回来。水声还在袖口。",
    "actions.tea_gossip.name": "茶座打听",
    "actions.tea_gossip.description": "花五块买几句堂口闲话。",
    "actions.tea_gossip.result": "茶凉了，话热了。",
    "actions.tea_toast.name": "敬酒交朋友",
    "actions.tea_toast.description": "晚上敬一轮，涨码头人脉，薄薄降嫌疑。",
    "actions.tea_toast.result": "杯底朝天。有人记住你的脸。",
    "actions.tea_broker.name": "后间问掮客",
    "actions.tea_broker.description": "贵，但消息厚（冷却2天）。",
    "actions.tea_broker.result": "门帘掀起一条缝。你把贵话吞进肚里。",
    "actions.tea_listen.name": "听说书",
    "actions.tea_listen.description": "听一段，心静一点，也夹着码头掌故。",
    "actions.tea_listen.result": "醒木落。你像被故事拍了一下肩。",
    "dialogue_choices.dch_dlg_tea_gossip_ok.label": "再续半杯",
    "dialogue_choices.dch_dlg_tea_toast_ok.label": "干了",
    "dialogue_choices.dch_dlg_tea_broker_ok.label": "全价听完",
    "dialogue_choices.dch_dlg_tea_broker_pass.label": "少付少听",
    "dialogue_choices.dch_dlg_tea_listen_ok.label": "听完再走",
    "dialogue_lines.dlg_tea_gossip_l01.text": "堂口蒸汽里，谁都把真话当成玩笑说。",
    "dialogue_lines.dlg_tea_gossip_l02.text": "今天码头上什么风？",
    "dialogue_lines.dlg_tea_gossip_l03.text": "几句半真半假的船期与人事，够你记一条。",
    "dialogue_lines.dlg_tea_toast_l01.text": "有人举杯：相识一场，先干为敬。",
    "dialogue_lines.dlg_tea_toast_l02.text": "敬。",
    "dialogue_lines.dlg_tea_toast_l03.text": "辣嗓子。人却近了半分。",
    "dialogue_lines.dlg_tea_broker_l01.text": "后间只有一盏灯：先生要听贵的，还是听够用的？",
    "dialogue_lines.dlg_tea_broker_l02.text": "说来听听。",
    "dialogue_lines.dlg_tea_broker_l03.text": "银元过手，名字不过舌。你得到的是厚度，不是保证。",
    "dialogue_lines.dlg_tea_listen_l01.text": "说书先生醒木一拍：今儿讲码头鬼、讲人心。",
    "dialogue_lines.dlg_tea_listen_l02.text": "听。",
    "dialogue_lines.dlg_tea_listen_l03.text": "故事落幕时，茶馆静了一息——像整座港都在换气。",
    "idle_chatter.chatter_tea_01.text": "谁在堂口笑，谁在后间压低声音。茶馆比码头会藏人。",
    "idle_chatter.chatter_tea_02.text": "醒木一响，连账房先生都忘了算盘。",
    "arcade.dice.title": "棚下掷骰",
    "arcade.morra.title": "豁拳定输赢",
    "arcade.fish.title": "码头钓趣",
    "arcade.dice.intro": "八块一把，两颗骰。点数大赢，平手退本，庄家吃零头。",
    "arcade.dice.again": "再来？盅还热。",
    "arcade.dice.hint": "点「开盅」；可连玩，收工才过时段。",
    "arcade.dice.rolling": "盅里乱响——",
    "arcade.dice.win": "你 {you} 大于庄 {house} · 赢得 {pay}",
    "arcade.dice.tie": "打平 {you} · 退回本金",
    "arcade.dice.lose": "你 {you} 小于庄 {house} · 庄家笑纳",
    "arcade.dice.result_vendor": "再来？还是收手？",
    "arcade.morra.intro": "豁拳！出0～5比大小。六块一局，平手退注。",
    "arcade.morra.again": "喉咙还热？再豁。",
    "arcade.morra.hint": "先选点数，再开拳。",
    "arcade.morra.idle": "出拳…",
    "arcade.morra.picked": "你出：{n}",
    "arcade.morra.need_pick": "先选你要出的数。",
    "arcade.morra.show": "你 {you} ｜ 对方 {foe}",
    "arcade.morra.win": "你大！赢得 {pay}",
    "arcade.morra.tie": "打平 · 退注",
    "arcade.morra.lose": "你小 · 酒钱归对面",
    "arcade.morra.result_vendor": "再豁一拳？",
    "arcade.fish.intro": "堤边借杆：光标进绿区起竿。钓到换小费。",
    "arcade.fish.again": "水还活着。再抛？",
    "arcade.fish.hint": "先「抛竿」，绿区再「起竿」。",
    "arcade.fish.cast": "抛竿",
    "arcade.fish.hook": "起竿！",
    "arcade.fish.waiting": "浮子在跳——看准绿区！",
    "arcade.fish.perfect": "正口！鲜鱼换 16 银元",
    "arcade.fish.ok": "上钩了 · 换 10 银元",
    "arcade.fish.miss": "空军。水花笑你。",
    "arcade.fish.result_vendor": "再抛一竿？",
    "arcade.btn.stake": "开局（{n} 银元）",
    "arcade.btn.again": "再来一局",
    "arcade.btn.leave": "收工走人",
    "arcade.broke": "口袋空了。先去码头扛两箱，或收工。",
    "arcade.cancel": "没玩成，摊子收了。",
    "arcade.session.empty": "还没开局 · 想玩几把玩几把",
    "arcade.session.stats": "已玩 {n} 局 · 花 {spent} / 赢 {won} · 盈亏 {net}",
    "arcade.session.summary": "{mode}：玩了 {n} 局，花 {spent} / 赢 {won}，盈亏 {net}",
    "tip.tea_house": "大街西侧「港湾茶馆」：打听、敬酒、听说书；晚上后间可问掮客（贵、冷却）。",
    "tip.arcade": "消遣：广场掷骰/豁拳、码头钓鱼、刮刮乐——都可连玩，收工才过时段。",
    "tip.variety": "好玩的分散在港区：茶馆听书、广场掷骰豁拳刮刮乐、码头钓鱼与雨棚闲话、公司跑楼。打工有每日次数。",
    "tip.plaza": "休闲广场：练球、帮摊、卖货、刮刮乐、掷骰、豁拳；雨天半场小赌暂停。",
}

en = {
    "locations.tea_house.name": "Harbor Tea House",
    "locations.tea_house.description": "Clappers, hot tea, backroom deals — ears and throats by the dock.",
    "hotspots.tea_corner.name": "Hall Seats",
    "hotspots.tea_corner.description": "Anyone may sit; any line may be true.",
    "hotspots.tea_backroom.name": "Back Room",
    "hotspots.tea_backroom.description": "Curtain drops; price outruns tea.",
    "hotspots.tea_stage.name": "Story Stage",
    "hotspots.tea_stage.description": "Clapper falls; stories outrun news.",
    "unlock.location.tea_house": "Open from day 1 · tales and talk",
    "actions.plaza_dice.name": "Shed Dice",
    "actions.plaza_dice.description": "Roll against the house; chain rounds; Leave ends the period.",
    "actions.plaza_dice.result": "Dice settle. Luck is written into this period.",
    "actions.plaza_morra.name": "Morra Bout",
    "actions.plaza_morra.description": "Throw 0–5; chain rounds; Leave ends the period.",
    "actions.plaza_morra.result": "Throat still rough. The drink tab is settled — or not.",
    "actions.dock_fish.name": "Pier Fishing",
    "actions.dock_fish.description": "Hook in the green zone. Timing game; misses only cost pride.",
    "actions.dock_fish.result": "Rod reels in. Water still in your sleeve.",
    "actions.tea_gossip.name": "Tea Hall Gossip",
    "actions.tea_gossip.description": "Spend 5 for hall whispers.",
    "actions.tea_gossip.result": "Tea cools; talk heats.",
    "actions.tea_toast.name": "Toast New Friends",
    "actions.tea_toast.description": "Evening rounds: network up, suspicion thins.",
    "actions.tea_toast.result": "Cups empty. Faces stick.",
    "actions.tea_broker.name": "Backroom Broker",
    "actions.tea_broker.description": "Expensive, thick intel (2-day cooldown).",
    "actions.tea_broker.result": "Curtain lifts a slit. You swallow the costly words.",
    "actions.tea_listen.name": "Listen to the Tale",
    "actions.tea_listen.description": "A story settles the nerves and sleeves a dock anecdote.",
    "actions.tea_listen.result": "Clapper falls. The tale taps your shoulder.",
    "dialogue_choices.dch_dlg_tea_gossip_ok.label": "One more half cup",
    "dialogue_choices.dch_dlg_tea_toast_ok.label": "Down it",
    "dialogue_choices.dch_dlg_tea_broker_ok.label": "Pay full and listen",
    "dialogue_choices.dch_dlg_tea_broker_pass.label": "Pay less, hear less",
    "dialogue_choices.dch_dlg_tea_listen_ok.label": "Stay to the end",
    "dialogue_lines.dlg_tea_gossip_l01.text": "In the steam, truth dresses as jokes.",
    "dialogue_lines.dlg_tea_gossip_l02.text": "What wind on the dock today?",
    "dialogue_lines.dlg_tea_gossip_l03.text": "Half-true sailing talk — enough for one note.",
    "dialogue_lines.dlg_tea_toast_l01.text": "A cup rises: to meeting — drink first.",
    "dialogue_lines.dlg_tea_toast_l02.text": "To you.",
    "dialogue_lines.dlg_tea_toast_l03.text": "Throat burns. Distance thins.",
    "dialogue_lines.dlg_tea_broker_l01.text": "One lamp in back: expensive, or merely enough?",
    "dialogue_lines.dlg_tea_broker_l02.text": "Talk.",
    "dialogue_lines.dlg_tea_broker_l03.text": "Silver moves; names don't. Thickness, not warranty.",
    "dialogue_lines.dlg_tea_listen_l01.text": "Clapper: dock ghosts and human hearts tonight.",
    "dialogue_lines.dlg_tea_listen_l02.text": "Listening.",
    "dialogue_lines.dlg_tea_listen_l03.text": "When it ends the hall breathes — like the whole harbor.",
    "idle_chatter.chatter_tea_01.text": "Someone laughs in the hall; someone whispers behind the curtain.",
    "idle_chatter.chatter_tea_02.text": "One clapper, and even the clerk forgets his abacus.",
    "arcade.dice.title": "Shed Dice",
    "arcade.morra.title": "Morra Bout",
    "arcade.fish.title": "Pier Fishing",
    "arcade.dice.intro": "Eight silver a throw. Higher wins; ties refund; house nibbles.",
    "arcade.dice.again": "Again? The cup is warm.",
    "arcade.dice.hint": "Open the cup; chain rounds; Leave ends the period.",
    "arcade.dice.rolling": "Rattle in the cup—",
    "arcade.dice.win": "You {you} beat house {house} · win {pay}",
    "arcade.dice.tie": "Tie {you} · stake returned",
    "arcade.dice.lose": "You {you} lose to {house} · house keeps it",
    "arcade.dice.result_vendor": "Again — or fold?",
    "arcade.morra.intro": "Morra! 0–5. Six silver; ties refund.",
    "arcade.morra.again": "Throat warm? One more.",
    "arcade.morra.hint": "Pick a number, then throw.",
    "arcade.morra.idle": "Throw…",
    "arcade.morra.picked": "You: {n}",
    "arcade.morra.need_pick": "Pick your number first.",
    "arcade.morra.show": "You {you} | Them {foe}",
    "arcade.morra.win": "You high! Win {pay}",
    "arcade.morra.tie": "Tie · refund",
    "arcade.morra.lose": "You low · drinks on you",
    "arcade.morra.result_vendor": "Another throw?",
    "arcade.fish.intro": "Borrow a rod: hook in the green. Fish pays tip.",
    "arcade.fish.again": "Water's alive. Cast again?",
    "arcade.fish.hint": "Cast, then Hook in the green.",
    "arcade.fish.cast": "Cast",
    "arcade.fish.hook": "Hook!",
    "arcade.fish.waiting": "Bobber dancing — watch the green!",
    "arcade.fish.perfect": "Perfect hit! 16 silver",
    "arcade.fish.ok": "Fish on · 10 silver",
    "arcade.fish.miss": "Empty. Splash laughs.",
    "arcade.fish.result_vendor": "Cast again?",
    "arcade.btn.stake": "Play ({n} silver)",
    "arcade.btn.again": "One more",
    "arcade.btn.leave": "Clock out",
    "arcade.broke": "Empty purse. Haul crates — or leave.",
    "arcade.cancel": "No play; stall closes.",
    "arcade.session.empty": "No rounds yet — play as many as you like",
    "arcade.session.stats": "Rounds {n} · spent {spent} / won {won} · net {net}",
    "arcade.session.summary": "{mode}: {n} rounds, spent {spent} / won {won}, net {net}",
    "tip.tea_house": "West boulevard: Harbor Tea House — gossip, toasts, tales; evening backroom broker (pricey, cooldown).",
    "tip.arcade": "Fun toys: plaza dice/morra, dock fishing, scratch tickets — chain rounds; Leave ends the period.",
    "tip.variety": "Fun is spread out: tea house, plaza dice/morra/scratch, dock fishing and rain shelter, company memo runs. Grind jobs have daily caps.",
    "tip.plaza": "Plaza: practice, stalls, scratch, dice, morra; rain pauses half-court wagers.",
}

upsert_l10n("l10n/zh_CN.csv", zh)
upsert_l10n("l10n/en.csv", en)
print("done")
