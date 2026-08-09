# -*- coding: utf-8 -*-
"""Append leisure plaza content to core pack tables + l10n."""
from pathlib import Path

ROOT = Path(r"f:\Games\New-Life\docs\tables\packs\core")


def append_rows(rel: str, header_check: str, rows: list[str]) -> None:
    path = ROOT / rel
    text = path.read_text(encoding="utf-8-sig")
    if header_check not in text.splitlines()[0]:
        raise SystemExit(f"unexpected header in {rel}: {text.splitlines()[0]}")
    existing = text
    to_add = []
    for row in rows:
        key = row.split(",", 1)[0]
        # skip if id already present as line start
        if f"\n{key}," in existing or existing.startswith(f"{key},"):
            print(f"skip existing {rel}:{key}")
            continue
        to_add.append(row)
    if not to_add:
        print(f"{rel}: nothing to add")
        return
    if not text.endswith("\n"):
        text += "\n"
    path.write_text(text + "\n".join(to_add) + "\n", encoding="utf-8")
    print(f"{rel}: +{len(to_add)}")


def upsert_l10n(rel: str, updates: dict) -> None:
    path = ROOT / rel
    text = path.read_text(encoding="utf-8-sig")
    lines = text.splitlines()
    out = []
    seen = set()
    for line in lines:
        if not line.strip() or "," not in line:
            out.append(line)
            continue
        key = line.split(",", 1)[0]
        if key in updates:
            val = updates[key]
            if "," in val or '"' in val or "\n" in val:
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
    print(f"{rel}: upsert {len(updates)}")


append_rows(
    "locations.csv",
    "id,default_periods",
    [
        "plaza,any,all,6,1,1,港区休闲广场：球场与路边摊",
    ],
)

append_rows(
    "hotspots.csv",
    "id,location_id",
    [
        "plaza_court,plaza,0.0,morning|afternoon,leisure,18,1,1,320,620,白天练球",
        "plaza_stalls,plaza,0.2,any,leisure|market,19,1,1,620,540,路边摊",
        "plaza_whisper,plaza,0.6,afternoon|evening,intel|leisure,20,1,1,780,400,情报摊",
    ],
)

append_rows(
    "actions.csv",
    "id,hotspot_id",
    [
        "plaza_practice,plaza_court,morning|afternoon,all,1,0,0,0,40,1,练球降压,dlg_plaza_practice,,",
        "plaza_snack,plaza_stalls,any,all,1,0,0,0,41,1,买小吃,dlg_plaza_snack,,",
        "plaza_sell_goods,plaza_stalls,morning|afternoon,all,1,0,0,0,42,1,卖闲置/关键物,dlg_plaza_sell_goods,,",
        "plaza_buy_tip,plaza_stalls,any,all,1,0,0,0,43,1,花钱买小道消息,dlg_plaza_buy_tip,,",
        "plaza_sell_intel,plaza_whisper,afternoon|evening,all,1,0,0,0,44,1,路边卖情报（不替代通洋线）,dlg_plaza_sell_intel,,",
    ],
)

append_rows(
    "conditions.csv",
    "id,owner_type",
    [
        "c_act_plaza_snack_money,action,plaza_snack,1,stat,money,gte,8,",
        "c_act_plaza_buy_tip_money,action,plaza_buy_tip,1,stat,money,gte,12,",
        "c_act_plaza_sell_intel_stat,action,plaza_sell_intel,1,stat,intel,gte,6,",
    ],
)

append_rows(
    "dialogues.csv",
    "id,tags",
    [
        "dlg_plaza_practice,all,50,0,1,休闲练球",
        "dlg_plaza_snack,all,50,0,1,路边小吃",
        "dlg_plaza_sell_goods,all,50,0,1,摊上卖物",
        "dlg_plaza_buy_tip,all,50,0,1,买小道消息",
        "dlg_plaza_sell_intel,all,50,0,1,路边卖情报",
    ],
)

append_rows(
    "dialogue_lines.csv",
    "id,dialogue_id",
    [
        "dlg_plaza_practice_l01,dlg_plaza_practice,1,narrator,neutral,1,",
        "dlg_plaza_practice_l02,dlg_plaza_practice,2,player,resolve,1,",
        "dlg_plaza_practice_l03,dlg_plaza_practice,3,narrator,neutral,1,",
        "dlg_plaza_snack_l01,dlg_plaza_snack,1,narrator,neutral,1,",
        "dlg_plaza_snack_l02,dlg_plaza_snack,2,player,resolve,1,",
        "dlg_plaza_snack_l03,dlg_plaza_snack,3,narrator,neutral,1,",
        "dlg_plaza_sell_goods_l01,dlg_plaza_sell_goods,1,narrator,neutral,1,",
        "dlg_plaza_sell_goods_l02,dlg_plaza_sell_goods,2,player,resolve,1,",
        "dlg_plaza_sell_goods_l03,dlg_plaza_sell_goods,3,narrator,neutral,1,",
        "dlg_plaza_buy_tip_l01,dlg_plaza_buy_tip,1,narrator,neutral,1,",
        "dlg_plaza_buy_tip_l02,dlg_plaza_buy_tip,2,player,tense,1,",
        "dlg_plaza_buy_tip_l03,dlg_plaza_buy_tip,3,narrator,neutral,1,",
        "dlg_plaza_sell_intel_l01,dlg_plaza_sell_intel,1,narrator,neutral,1,",
        "dlg_plaza_sell_intel_l02,dlg_plaza_sell_intel,2,player,resolve,1,",
        "dlg_plaza_sell_intel_l03,dlg_plaza_sell_intel,3,narrator,cold,1,",
    ],
)

append_rows(
    "dialogue_choices.csv",
    "id,dialogue_id",
    [
        "dch_dlg_plaza_practice_ok,dlg_plaza_practice,dlg_plaza_practice_l03,1,1,",
        "dch_dlg_plaza_snack_ok,dlg_plaza_snack,dlg_plaza_snack_l03,1,1,",
        "dch_dlg_plaza_sell_goods_ok,dlg_plaza_sell_goods,dlg_plaza_sell_goods_l03,1,1,",
        "dch_dlg_plaza_sell_goods_key,dlg_plaza_sell_goods,dlg_plaza_sell_goods_l03,2,1,卖关键物多赚一点嫌疑",
        "dch_dlg_plaza_buy_tip_ok,dlg_plaza_buy_tip,dlg_plaza_buy_tip_l03,1,1,",
        "dch_dlg_plaza_sell_intel_ok,dlg_plaza_sell_intel,dlg_plaza_sell_intel_l03,1,1,",
        "dch_dlg_plaza_sell_intel_hold,dlg_plaza_sell_intel,dlg_plaza_sell_intel_l03,2,1,少卖一点",
    ],
)

append_rows(
    "effects.csv",
    "id,owner_type",
    [
        # practice — wash suspicion, lightly socialize
        "fx_plaza_practice_sus,action,plaza_practice,stat,,suspicion,add,-6,1,",
        "fx_plaza_practice_net,action,plaza_practice,stat,,network_base,add,2,1,",
        "fx_dch_plaza_practice_ok_mood,dialogue_choice,dch_dlg_plaza_practice_ok,stat,,suspicion,add,-2,1,",
        # snack
        "fx_plaza_snack_money,action,plaza_snack,stat,,money,add,-8,1,",
        "fx_plaza_snack_sus,action,plaza_snack,stat,,suspicion,add,-3,1,",
        "fx_dch_plaza_snack_ok_net,dialogue_choice,dch_dlg_plaza_snack_ok,stat,,network_base,add,1,1,",
        # sell goods — ordinary
        "fx_dch_plaza_sell_goods_ok_money,dialogue_choice,dch_dlg_plaza_sell_goods_ok,stat,,money,add,14,1,",
        "fx_dch_plaza_sell_goods_ok_sus,dialogue_choice,dch_dlg_plaza_sell_goods_ok,stat,,suspicion,add,1,1,",
        "fx_dch_plaza_sell_goods_ok_net,dialogue_choice,dch_dlg_plaza_sell_goods_ok,stat,,network_base,add,1,1,",
        # sell key-ish goods — more money, more heat
        "fx_dch_plaza_sell_goods_key_money,dialogue_choice,dch_dlg_plaza_sell_goods_key,stat,,money,add,28,1,",
        "fx_dch_plaza_sell_goods_key_sus,dialogue_choice,dch_dlg_plaza_sell_goods_key,stat,,suspicion,add,5,1,",
        "fx_dch_plaza_sell_goods_key_intel,dialogue_choice,dch_dlg_plaza_sell_goods_key,stat,,intel,add,-2,1,顺带流出一点口风",
        # buy tip
        "fx_plaza_buy_tip_money,action,plaza_buy_tip,stat,,money,add,-12,1,",
        "fx_dch_plaza_buy_tip_ok_intel,dialogue_choice,dch_dlg_plaza_buy_tip_ok,stat,,intel,add,5,1,",
        "fx_dch_plaza_buy_tip_ok_sus,dialogue_choice,dch_dlg_plaza_buy_tip_ok,stat,,suspicion,add,2,1,",
        # street sell intel — softer than Tongyang; does NOT set can_join_tongyang
        "fx_dch_plaza_sell_intel_ok_money,dialogue_choice,dch_dlg_plaza_sell_intel_ok,stat,,money,add,22,1,",
        "fx_dch_plaza_sell_intel_ok_intel,dialogue_choice,dch_dlg_plaza_sell_intel_ok,stat,,intel,add,-8,1,",
        "fx_dch_plaza_sell_intel_ok_sus,dialogue_choice,dch_dlg_plaza_sell_intel_ok,stat,,suspicion,add,4,1,",
        "fx_dch_plaza_sell_intel_ok_net,dialogue_choice,dch_dlg_plaza_sell_intel_ok,stat,,network_base,add,2,1,",
        "fx_dch_plaza_sell_intel_hold_money,dialogue_choice,dch_dlg_plaza_sell_intel_hold,stat,,money,add,12,1,",
        "fx_dch_plaza_sell_intel_hold_intel,dialogue_choice,dch_dlg_plaza_sell_intel_hold,stat,,intel,add,-4,1,",
        "fx_dch_plaza_sell_intel_hold_sus,dialogue_choice,dch_dlg_plaza_sell_intel_hold,stat,,suspicion,add,2,1,",
    ],
)

append_rows(
    "idle_chatter.csv",
    "id,location_id",
    [
        "chatter_plaza_01,plaza,,any,all,10,1,1,",
        "chatter_plaza_02,plaza,plaza_court,morning|afternoon,all,8,1,1,",
        "chatter_plaza_03,plaza,plaza_stalls,any,all,8,1,1,",
        "chatter_plaza_04,plaza,plaza_whisper,afternoon|evening,all,6,1,1,",
    ],
)

zh = {
    "locations.plaza.name": "港区休闲广场",
    "locations.plaza.description": "篮球场、路边摊、闲话与银元——码头边上的喘气处。",
    "hotspots.plaza_court.name": "露天球场",
    "hotspots.plaza_court.description": "半场泥地，一个歪篮筐。出汗能冲淡一点盯梢的味道。",
    "hotspots.plaza_stalls.name": "路边摊区",
    "hotspots.plaza_stalls.description": "油烟、糖炒、旧件与手帕——什么都卖，什么都听。",
    "hotspots.plaza_whisper.name": "情报茶摊",
    "hotspots.plaza_whisper.description": "茶壶盖一响，消息比茶便宜；别指望能换通洋的席位。",
    "actions.plaza_practice.name": "练习篮球",
    "actions.plaza_practice.description": "投几球出汗，跟工人聊两句。",
    "actions.plaza_practice.result": "汗落下来，肩膀松一点，码头的人也记住你的脸。",
    "actions.plaza_snack.name": "买路边小吃",
    "actions.plaza_snack.description": "花几块钱吃一口，顺便听摊主骂行情。",
    "actions.plaza_snack.result": "肚子暖了，闲话也暖。嫌疑薄薄褪一层。",
    "actions.plaza_sell_goods.name": "摆摊卖闲置",
    "actions.plaza_sell_goods.description": "把手里旧件、杂货换成银元。",
    "actions.plaza_sell_goods.result": "摊子收了，口袋响了。",
    "actions.plaza_buy_tip.name": "买小道消息",
    "actions.plaza_buy_tip.description": "花点钱向摊主打听码头/公司动静。",
    "actions.plaza_buy_tip.result": "几句半真半假的话，够你记下一条线索。",
    "actions.plaza_sell_intel.name": "路边卖情报",
    "actions.plaza_sell_intel.description": "把知道的碎消息换成钱。不成通洋正路，但能救急。",
    "actions.plaza_sell_intel.result": "银元进袋，消息出门。宏远那边若有风，别装无辜。",
    "dialogue_choices.dch_dlg_plaza_practice_ok.label": "再投一球收工",
    "dialogue_choices.dch_dlg_plaza_snack_ok.label": "吃完抹嘴走人",
    "dialogue_choices.dch_dlg_plaza_sell_goods_ok.label": "卖普通闲置",
    "dialogue_choices.dch_dlg_plaza_sell_goods_key.label": "卖关键物（多赚、惹眼）",
    "dialogue_choices.dch_dlg_plaza_buy_tip_ok.label": "付钱听完",
    "dialogue_choices.dch_dlg_plaza_sell_intel_ok.label": "整包卖了",
    "dialogue_choices.dch_dlg_plaza_sell_intel_hold.label": "只卖一半",
    "dialogue_lines.dlg_plaza_practice_l01.text": "广场半场泥地上，篮筐歪着，像被海风拧过。有人赤膊传球，号子比哨子响。",
    "dialogue_lines.dlg_plaza_practice_l02.text": "来几球。出汗，比在公司陪笑实在。",
    "dialogue_lines.dlg_plaza_practice_l03.text": "球进筐的一瞬，你听见旁边人笑：装卸组长也会玩啊。嫌疑薄了点，脸熟了点。",
    "dialogue_lines.dlg_plaza_snack_l01.text": "油锅一响，糖炒栗子与烤鱿鱼抢鼻子。摊主一边找钱一边骂船期。",
    "dialogue_lines.dlg_plaza_snack_l02.text": "来一份。顺便听你骂。",
    "dialogue_lines.dlg_plaza_snack_l03.text": "烫嘴的味道压住心事。闲话里夹着码头动静，你假装只是路过。",
    "dialogue_lines.dlg_plaza_sell_goods_l01.text": "旧怀表、备用扣、一叠不伤大雅的杂件——摊上的人只问成色，不问来处。",
    "dialogue_lines.dlg_plaza_sell_goods_l02.text": "今天出一点货。",
    "dialogue_lines.dlg_plaza_sell_goods_l03.text": "银元落掌心。卖普通货安生；若动关键物，眼神会多停你一秒。",
    "dialogue_lines.dlg_plaza_buy_tip_l01.text": "茶摊角落有人敲桌：先生，要听新鲜的，还是要听真的？",
    "dialogue_lines.dlg_plaza_buy_tip_l02.text": "真的贵一点也行。",
    "dialogue_lines.dlg_plaza_buy_tip_l03.text": "几句半遮半掩的船期与人事，够你往本子上记一笔。",
    "dialogue_lines.dlg_plaza_sell_intel_l01.text": "情报茶摊的壶盖一响：你有货？这儿不签合同，只认银元。",
    "dialogue_lines.dlg_plaza_sell_intel_l02.text": "有。别问我怎么知道的。",
    "dialogue_lines.dlg_plaza_sell_intel_l03.text": "消息出门，钱进袋。这儿成不了通洋的台阶——顶多让你今晚睡得踏实点。",
    "idle_chatter.chatter_plaza_01.text": "有人喊换场，有人喊找零钱。广场比公司热闹，也比公司松一口气。",
    "idle_chatter.chatter_plaza_02.text": "球撞击地面的闷响一下一下，像在替谁数心跳。",
    "idle_chatter.chatter_plaza_03.text": "摊主说：今天栗子贵，消息更贵。",
    "idle_chatter.chatter_plaza_04.text": "茶摊后头两个人压低声音——你假装看蚂蚁搬家。",
    "unlock.location.plaza": "开局开放 · 港区休闲区",
    "tip.plaza": "码头西侧「港区休闲广场」：练球降嫌疑，摊上可卖闲置/关键物，茶摊可买卖情报（不替代通洋正路）。",
}

en = {
    "locations.plaza.name": "Harbor Leisure Plaza",
    "locations.plaza.description": "A court, street stalls, gossip and silver — a place to breathe by the docks.",
    "hotspots.plaza_court.name": "Open Court",
    "hotspots.plaza_court.description": "Half a dirt court and a crooked hoop. Sweat washes a little heat off you.",
    "hotspots.plaza_stalls.name": "Street Stalls",
    "hotspots.plaza_stalls.description": "Smoke, sweets, spare parts and handkerchiefs — everything for sale, everything overheard.",
    "hotspots.plaza_whisper.name": "Whisper Tea Stall",
    "hotspots.plaza_whisper.description": "Lid clinks, tips are cheap. This will not buy a Tongyang seat.",
    "actions.plaza_practice.name": "Practice Basketball",
    "actions.plaza_practice.description": "Shoot a few, sweat, chat with workers.",
    "actions.plaza_practice.result": "Sweat lands; your shoulders loosen; faces on the dock remember you.",
    "actions.plaza_snack.name": "Buy Street Snacks",
    "actions.plaza_snack.description": "Spend a little, eat, hear the stall curse the market.",
    "actions.plaza_snack.result": "Warm belly, warm gossip. Suspicion thins a little.",
    "actions.plaza_sell_goods.name": "Sell Odds and Ends",
    "actions.plaza_sell_goods.description": "Turn spare goods into silver.",
    "actions.plaza_sell_goods.result": "Stall closes; pocket rattles.",
    "actions.plaza_buy_tip.name": "Buy a Street Tip",
    "actions.plaza_buy_tip.description": "Pay for dock/company whispers.",
    "actions.plaza_buy_tip.result": "Half-true lines — enough for one note.",
    "actions.plaza_sell_intel.name": "Sell Intel on the Street",
    "actions.plaza_sell_intel.description": "Cash for scraps. Not Tongyang's path — just a stopgap.",
    "actions.plaza_sell_intel.result": "Silver in; word out. If Hongyuan sniffs wind, don't play innocent.",
    "dialogue_choices.dch_dlg_plaza_practice_ok.label": "One more shot, then go",
    "dialogue_choices.dch_dlg_plaza_snack_ok.label": "Finish and wipe your mouth",
    "dialogue_choices.dch_dlg_plaza_sell_goods_ok.label": "Sell ordinary junk",
    "dialogue_choices.dch_dlg_plaza_sell_goods_key.label": "Sell something sensitive (more pay, more eyes)",
    "dialogue_choices.dch_dlg_plaza_buy_tip_ok.label": "Pay and listen",
    "dialogue_choices.dch_dlg_plaza_sell_intel_ok.label": "Sell the whole scrap",
    "dialogue_choices.dch_dlg_plaza_sell_intel_hold.label": "Sell only half",
    "dialogue_lines.dlg_plaza_practice_l01.text": "On the dirt half-court the hoop leans like the sea wind twisted it. Bare chests pass the ball louder than any whistle.",
    "dialogue_lines.dlg_plaza_practice_l02.text": "A few shots. Sweat beats smiling at the company.",
    "dialogue_lines.dlg_plaza_practice_l03.text": "The ball drops. Someone laughs: even the foreman plays. Heat thins; faces stick.",
    "dialogue_lines.dlg_plaza_snack_l01.text": "Oil pops; chestnuts and squid fight for your nose. The stall curses sailing dates while making change.",
    "dialogue_lines.dlg_plaza_snack_l02.text": "One portion. Keep cursing.",
    "dialogue_lines.dlg_plaza_snack_l03.text": "Heat on the tongue buries worry. Dock noise hides in the gossip; you pretend you're just passing.",
    "dialogue_lines.dlg_plaza_sell_goods_l01.text": "Old watches, spare buttons, harmless odds — the stall asks for condition, not provenance.",
    "dialogue_lines.dlg_plaza_sell_goods_l02.text": "Moving a little stock today.",
    "dialogue_lines.dlg_plaza_sell_goods_l03.text": "Silver hits your palm. Ordinary goods are safe; sensitive ones buy an extra glance.",
    "dialogue_lines.dlg_plaza_buy_tip_l01.text": "A knuckle taps the tea stall: fresh, or true?",
    "dialogue_lines.dlg_plaza_buy_tip_l02.text": "True — even if it costs.",
    "dialogue_lines.dlg_plaza_buy_tip_l03.text": "Half-veiled sailing dates and office names — enough for one line in your book.",
    "dialogue_lines.dlg_plaza_sell_intel_l01.text": "The whisper stall's lid clinks: got goods? No contracts here — only silver.",
    "dialogue_lines.dlg_plaza_sell_intel_l02.text": "I do. Don't ask how.",
    "dialogue_lines.dlg_plaza_sell_intel_l03.text": "Word leaves; coin stays. This won't step you into Tongyang — it only buys a quieter night.",
    "idle_chatter.chatter_plaza_01.text": "Someone calls for a sub; someone calls for change. Louder than the company — and softer on the lungs.",
    "idle_chatter.chatter_plaza_02.text": "The ball thuds the dirt like it's counting someone's pulse.",
    "idle_chatter.chatter_plaza_03.text": "Stallkeeper: chestnuts cost today. Tips cost more.",
    "idle_chatter.chatter_plaza_04.text": "Two voices drop behind the tea stall — you watch ants instead.",
    "unlock.location.plaza": "Open from day 1 · leisure district",
    "tip.plaza": "West of the dock: Harbor Leisure Plaza — practice to cool suspicion, sell junk/sensitive goods at stalls, buy/sell tips at the tea stall (not a Tongyang shortcut).",
}

upsert_l10n("l10n/zh_CN.csv", zh)
upsert_l10n("l10n/en.csv", en)
print("done")
