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


append_rows(
    "actions.csv",
    [
        "plaza_scratch,plaza_stalls,any,all|minigame_scratch,1,0,0,0,49,1,刮刮乐小游戏,,,",
    ],
)
append_rows(
    "conditions.csv",
    [
        "c_act_plaza_scratch_money,action,plaza_scratch,1,stat,money,gte,10,",
    ],
)
append_rows(
    "effects.csv",
    [
        "fx_plaza_scratch_cost,action,plaza_scratch,stat,,money,add,-10,1,票价",
        "fx_plaza_scratch_none_net,dialogue_choice,dch_plaza_scratch_none,stat,,network_base,add,1,1,安慰奖：脸熟",
        "fx_plaza_scratch_small_money,dialogue_choice,dch_plaza_scratch_small,stat,,money,add,18,1,",
        "fx_plaza_scratch_mid_money,dialogue_choice,dch_plaza_scratch_mid,stat,,money,add,35,1,",
        "fx_plaza_scratch_mid_net,dialogue_choice,dch_plaza_scratch_mid,stat,,network_base,add,1,1,",
        "fx_plaza_scratch_big_money,dialogue_choice,dch_plaza_scratch_big,stat,,money,add,80,1,",
        "fx_plaza_scratch_big_sus,dialogue_choice,dch_plaza_scratch_big,stat,,suspicion,add,2,1,中奖惹眼",
        "fx_plaza_scratch_jackpot_money,dialogue_choice,dch_plaza_scratch_jackpot,stat,,money,add,200,1,",
        "fx_plaza_scratch_jackpot_sus,dialogue_choice,dch_plaza_scratch_jackpot,stat,,suspicion,add,4,1,",
        "fx_plaza_scratch_jackpot_net,dialogue_choice,dch_plaza_scratch_jackpot,stat,,network_base,add,3,1,",
        "fx_plaza_scratch_jackpot_elite,dialogue_choice,dch_plaza_scratch_jackpot,stat,,network_elite,add,1,1,运气也是名片",
    ],
)
append_rows(
    "dialogue_choices.csv",
    [
        "dch_plaza_scratch_none,dlg_plaza_scratch_virtual,,1,1,minigame prize",
        "dch_plaza_scratch_small,dlg_plaza_scratch_virtual,,2,1,minigame prize",
        "dch_plaza_scratch_mid,dlg_plaza_scratch_virtual,,3,1,minigame prize",
        "dch_plaza_scratch_big,dlg_plaza_scratch_virtual,,4,1,minigame prize",
        "dch_plaza_scratch_jackpot,dlg_plaza_scratch_virtual,,5,1,minigame prize",
    ],
)
append_rows(
    "idle_chatter.csv",
    [
        "chatter_plaza_scratch,plaza,plaza_stalls,any,all,7,1,1,",
    ],
)
append_rows(
    "tips.csv",
    [
        "tip_plaza_scratch,unlock,34,tip.plaza_scratch,1,1,",
    ],
)

zh = {
    "scratch.title": "港彩刮刮乐",
    "scratch.cancel": "没买票，摊主把木板收回去了。",
    "scratch.vendor.intro": "摊主把一张银箔票拍在木板上：十块一张——刮开看看码头今天认不认你。",
    "scratch.vendor.broke": "摊主撇嘴：口袋空空还想碰运气？先去码头扛两箱。",
    "scratch.vendor.start": "银箔沙沙响。摊主笑：轻一点，把好运刮出来，别把票刮破了。",
    "scratch.vendor.mid1": "嗯……有点亮边。别停，手气怕冷场。",
    "scratch.vendor.mid2": "箔屑掉进碗里。摊主凑近：再两下，揭晓了。",
    "scratch.vendor.none": "摊主摊手：谢谢惠顾——码头的风有时只吹过，不留银元。",
    "scratch.vendor.small": "哟，漏出几块银光。够喝碗热汤，也算码头点头。",
    "scratch.vendor.mid": "好彩！旁边有人吹口哨。摊主赶紧把票角按住：收好，别让账房听见。",
    "scratch.vendor.big": "木板一震。摊主压低声：今天这张认你——拿稳，别在街上数。",
    "scratch.vendor.jackpot": "汽笛似的起哄！摊主又喜又怕：头彩啊……先生，今晚少走亮处。",
    "scratch.hint.buy": "按「买一张」付款，然后按住鼠标在票面上刮。",
    "scratch.hint.scratch": "按住左键来回刮银箔——刮开一半就会揭晓。",
    "scratch.hint.done": "结果已定。点「收下运气」结束这一时段。",
    "scratch.btn.buy": "买一张（{cost} 银元）",
    "scratch.btn.auto": "性急？一键刮开",
    "scratch.btn.collect": "收下运气",
    "scratch.progress": "刮开 {pct}%",
    "scratch.progress.done": "揭晓！",
    "scratch.card.hidden_title": "？？？",
    "scratch.card.hidden_body": "银箔底下藏着运气。",
    "scratch.prize.none.title": "谢谢惠顾",
    "scratch.prize.none.body": "箔下是空的笑脸。运气改日再来。",
    "scratch.prize.small.title": "小彩 · 18 银元",
    "scratch.prize.small.body": "几枚银元从箔缝里滚出来，够暖一顿。",
    "scratch.prize.mid.title": "中彩 · 35 银元",
    "scratch.prize.mid.body": "号码亮了。摊主眼神活络起来。",
    "scratch.prize.big.title": "大彩 · 80 银元",
    "scratch.prize.big.body": "厚厚一叠。码头有人开始记你的背影。",
    "scratch.prize.jackpot.title": "头彩 · 200 银元",
    "scratch.prize.jackpot.body": "今天的风认你。银元烫手，目光更烫。",
    "scratch.burst.none": "……",
    "scratch.burst.small": "+18",
    "scratch.burst.mid": "+35！",
    "scratch.burst.big": "+80！！",
    "scratch.burst.jackpot": "头彩！！",
    "actions.plaza_scratch.name": "港彩刮刮乐",
    "actions.plaza_scratch.description": "花十块买张银箔票，亲手刮开碰运气。",
    "actions.plaza_scratch.result": "箔屑还粘在指甲缝里。运气写进这一时段了。",
    "dialogue_choices.dch_plaza_scratch_none.label": "谢谢惠顾",
    "dialogue_choices.dch_plaza_scratch_small.label": "小彩",
    "dialogue_choices.dch_plaza_scratch_mid.label": "中彩",
    "dialogue_choices.dch_plaza_scratch_big.label": "大彩",
    "dialogue_choices.dch_plaza_scratch_jackpot.label": "头彩",
    "idle_chatter.chatter_plaza_scratch.text": "有人围着刮刮乐摊起哄：再来一张！箔屑像雪一样掉。",
    "tip.plaza_scratch": "广场路边摊可玩「港彩刮刮乐」：花10银元，按住鼠标刮银箔揭晓奖金。可取消不扣时段。",
    "tip.money_ways": "赚钱：码头搬货/晚班/跑腿；广场帮摊、卖货、刮刮乐；公司办公涨信任。交易所与通洋是中后期大头。",
    "tip.low_money": "金钱紧时优先：码头搬货/晚班/跑腿、广场帮摊卖货；刮刮乐能碰运气但先要有本金。私货与卖情报来钱快但惹嫌疑。",
}

en = {
    "scratch.title": "Harbor Scratch Ticket",
    "scratch.cancel": "No ticket bought — the stall tucks the board away.",
    "scratch.vendor.intro": "The stallkeeper slaps a foil ticket on the board: ten silver — see if the harbor likes you today.",
    "scratch.vendor.broke": "He smirks: empty pockets want luck? Haul crates first.",
    "scratch.vendor.start": "Foil whispers. Go gentle — scratch the luck out, not the ticket.",
    "scratch.vendor.mid1": "A bright edge… keep going. Luck hates a cold hand.",
    "scratch.vendor.mid2": "Foil dust in the bowl. Almost there.",
    "scratch.vendor.none": "He shrugs: thanks for playing — sometimes the wind only passes through.",
    "scratch.vendor.small": "A few coins leak out. Warm soup money. The dock nods.",
    "scratch.vendor.mid": "Nice hit! A whistle nearby. He pins the corner: pocket it quiet.",
    "scratch.vendor.big": "The board jumps. Low voice: today it knows you — don't count it in the street.",
    "scratch.vendor.jackpot": "A whistle-crowd erupts! Joy and fear: jackpot… walk dark tonight, sir.",
    "scratch.hint.buy": "Press Buy to pay, then hold the mouse and scratch the foil.",
    "scratch.hint.scratch": "Hold left mouse and scrub — reveal unlocks around halfway.",
    "scratch.hint.done": "Done. Collect to end this period.",
    "scratch.btn.buy": "Buy one ({cost} silver)",
    "scratch.btn.auto": "Impatient? Reveal all",
    "scratch.btn.collect": "Take the luck",
    "scratch.progress": "Cleared {pct}%",
    "scratch.progress.done": "Revealed!",
    "scratch.card.hidden_title": "???",
    "scratch.card.hidden_body": "Luck hides under the foil.",
    "scratch.prize.none.title": "Thanks for playing",
    "scratch.prize.none.body": "An empty smile under the foil. Try another day.",
    "scratch.prize.small.title": "Small win · 18 silver",
    "scratch.prize.small.body": "Coins roll from the scratch — enough for a warm bowl.",
    "scratch.prize.mid.title": "Mid win · 35 silver",
    "scratch.prize.mid.body": "Numbers light up. The stallkeeper's eyes quicken.",
    "scratch.prize.big.title": "Big win · 80 silver",
    "scratch.prize.big.body": "A thick fold. Someone on the dock starts remembering your back.",
    "scratch.prize.jackpot.title": "Jackpot · 200 silver",
    "scratch.prize.jackpot.body": "The wind picks you. Silver burns; stares burn hotter.",
    "scratch.burst.none": "…",
    "scratch.burst.small": "+18",
    "scratch.burst.mid": "+35!",
    "scratch.burst.big": "+80!!",
    "scratch.burst.jackpot": "JACKPOT!!",
    "actions.plaza_scratch.name": "Harbor Scratch Ticket",
    "actions.plaza_scratch.description": "Spend ten silver; scratch the foil yourself for a prize.",
    "actions.plaza_scratch.result": "Foil dust under your nails. Luck is written into this period.",
    "dialogue_choices.dch_plaza_scratch_none.label": "Thanks for playing",
    "dialogue_choices.dch_plaza_scratch_small.label": "Small win",
    "dialogue_choices.dch_plaza_scratch_mid.label": "Mid win",
    "dialogue_choices.dch_plaza_scratch_big.label": "Big win",
    "dialogue_choices.dch_plaza_scratch_jackpot.label": "Jackpot",
    "idle_chatter.chatter_plaza_scratch.text": "A crowd hounds the scratch stall: one more! Foil falls like snow.",
    "tip.plaza_scratch": "At plaza stalls: Harbor Scratch Ticket — 10 silver, hold-mouse to scratch foil. Cancel costs no period.",
    "tip.money_ways": "Earn: dock labor/overtime/errands; plaza help, sell, scratch tickets; company desk builds trust. Exchange and Tongyang pay later.",
    "tip.low_money": "When tight: dock labor/overtime/errands, plaza help/sell; scratch needs a stake first. Black market and intel are faster but hotter.",
}

upsert_l10n("l10n/zh_CN.csv", zh)
upsert_l10n("l10n/en.csv", en)
print("done")
