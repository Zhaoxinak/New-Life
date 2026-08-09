# -*- coding: utf-8 -*-
"""Variety pass: weather pivots, scarce grind, new play verbs."""
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


def patch_action_limits(updates: dict) -> None:
    """updates: action_id -> (cooldown_days, max_uses)"""
    path = ROOT / "actions.csv"
    lines = path.read_text(encoding="utf-8-sig").splitlines()
    out = [lines[0]]
    header = lines[0].split(",")
    # id,hotspot_id,periods,tags,time_cost,suspicion_base,cooldown_days,max_uses,...
    for line in lines[1:]:
        if not line.strip():
            out.append(line)
            continue
        parts = line.split(",")
        aid = parts[0]
        if aid in updates and len(parts) >= 8:
            cd, mu = updates[aid]
            parts[6] = str(cd)
            parts[7] = str(mu)
            line = ",".join(parts)
            print("limit", aid, "cd", cd, "max", mu)
        out.append(line)
    path.write_text("\n".join(out) + "\n", encoding="utf-8")


# --- scarcity on grind ---
patch_action_limits(
    {
        "dock_work": (0, 3),
        "dock_overtime": (0, 1),
        "dock_errand": (0, 2),
        "co_work": (0, 3),
        "plaza_help_stall": (0, 2),
        "plaza_sell_goods": (0, 2),
        "plaza_ball_wager": (0, 2),
        "plaza_scratch": (0, 1),
        "plaza_practice": (0, 2),
        "home_rest": (0, 2),
    }
)

# --- new actions ---
append_rows(
    "actions.csv",
    [
        "dock_shelter_talk,dock_loading,any,all|weather,1,0,0,2,50,1,雨天棚下闲聊,dlg_dock_shelter,,",
        "dock_board_rumor,dock_board,morning|afternoon,all|C,1,0,1,1,51,1,船期牌旁放风影响股价,dlg_dock_board_rumor,rule_dock_board_rumor,",
        "plaza_dice,plaza_court,afternoon|evening,all|gamble,1,0,0,3,52,1,棚下掷骰,dlg_plaza_dice,,chk_plaza_dice",
        "plaza_storyteller,plaza_whisper,afternoon|evening,all|leisure,1,0,1,1,53,1,听说书/码头段子,dlg_plaza_storyteller,,",
        "home_window_watch,home_desk,evening,all|leisure,1,0,0,1,54,1,窗边观街听雨,dlg_home_window,,",
        "co_memo_run,company_floor,morning|afternoon,B,1,0,0,2,55,1,跑楼送公文有分支,dlg_co_memo,,",
    ],
)

append_rows(
    "conditions.csv",
    [
        # shelter: rain OR storm
        "c_act_dock_shelter_rain,action,dock_shelter_talk,1,weather,rain,eq,1,",
        "c_act_dock_shelter_storm,action,dock_shelter_talk,2,weather,storm,eq,1,",
        # ball/practice blocked in bad weather
        "c_act_plaza_ball_no_rain,action,plaza_ball_wager,1,weather,rain,eq,0,",
        "c_act_plaza_ball_no_storm,action,plaza_ball_wager,1,weather,storm,eq,0,",
        "c_act_plaza_practice_no_storm,action,plaza_practice,1,weather,storm,eq,0,",
        "c_act_dock_overtime_no_storm,action,dock_overtime,1,weather,storm,eq,0,",
        # dice / story / board / memo gates
        "c_act_plaza_dice_money,action,plaza_dice,1,stat,money,gte,8,",
        "c_act_plaza_storyteller_money,action,plaza_storyteller,1,stat,money,gte,5,",
        "c_act_dock_board_rumor_intel,action,dock_board_rumor,1,stat,intel,gte,3,",
    ],
)

append_rows(
    "checks.csv",
    [
        "chk_plaza_dice,plaza_dice,,0.42,0.10,0.88,1,掷骰：人脉略助手气",
    ],
)
append_rows(
    "check_mods.csv",
    [
        "mod_chk_plaza_dice_net,chk_plaza_dice,stat_scale,network_base,0.003,25,-0.08,0.14,1,",
        "mod_chk_plaza_dice_sus,chk_plaza_dice,stat_scale,suspicion,-0.002,25,-0.10,0.04,1,",
    ],
)

append_rows(
    "stock_rules.csv",
    [
        "rule_dock_board_rumor,dock_board_rumor,on_action,price_shock,price_delta:-4,intel_cost:3,money_cost:0,suspicion:3,1,船期牌放风：轻砸盘",
    ],
)

append_rows(
    "dialogues.csv",
    [
        "dlg_dock_shelter,all,50,0,1,雨棚闲聊",
        "dlg_dock_board_rumor,all|C,50,0,1,船期牌放风",
        "dlg_plaza_dice,all,50,0,1,掷骰",
        "dlg_plaza_storyteller,all,50,0,1,听说书",
        "dlg_home_window,all,50,0,1,窗边观街",
        "dlg_co_memo,B,50,0,1,跑楼送公文",
    ],
)

append_rows(
    "dialogue_lines.csv",
    [
        "dlg_dock_shelter_l01,dlg_dock_shelter,1,narrator,neutral,1,",
        "dlg_dock_shelter_l02,dlg_dock_shelter,2,player,resolve,1,",
        "dlg_dock_shelter_l03,dlg_dock_shelter,3,narrator,neutral,1,",
        "dlg_dock_board_rumor_l01,dlg_dock_board_rumor,1,narrator,neutral,1,",
        "dlg_dock_board_rumor_l02,dlg_dock_board_rumor,2,player,tense,1,",
        "dlg_dock_board_rumor_l03,dlg_dock_board_rumor,3,narrator,cold,1,",
        "dlg_plaza_dice_l01,dlg_plaza_dice,1,narrator,neutral,1,",
        "dlg_plaza_dice_l02,dlg_plaza_dice,2,player,tense,1,",
        "dlg_plaza_dice_l03,dlg_plaza_dice,3,narrator,neutral,1,",
        "dlg_plaza_storyteller_l01,dlg_plaza_storyteller,1,narrator,neutral,1,",
        "dlg_plaza_storyteller_l02,dlg_plaza_storyteller,2,player,resolve,1,",
        "dlg_plaza_storyteller_l03,dlg_plaza_storyteller,3,narrator,soft,1,",
        "dlg_home_window_l01,dlg_home_window,1,narrator,neutral,1,",
        "dlg_home_window_l02,dlg_home_window,2,player,resolve,1,",
        "dlg_home_window_l03,dlg_home_window,3,narrator,neutral,1,",
        "dlg_co_memo_l01,dlg_co_memo,1,narrator,neutral,1,",
        "dlg_co_memo_l02,dlg_co_memo,2,player,resolve,1,",
        "dlg_co_memo_l03,dlg_co_memo,3,narrator,neutral,1,",
    ],
)

append_rows(
    "dialogue_choices.csv",
    [
        "dch_dlg_dock_shelter_ok,dlg_dock_shelter,dlg_dock_shelter_l03,1,1,",
        "dch_dlg_dock_board_rumor_ok,dlg_dock_board_rumor,dlg_dock_board_rumor_l03,1,1,",
        "dch_dlg_plaza_dice_ok,dlg_plaza_dice,dlg_plaza_dice_l03,1,1,",
        "dch_dlg_plaza_storyteller_dock,dlg_plaza_storyteller,dlg_plaza_storyteller_l03,1,1,听码头段子",
        "dch_dlg_plaza_storyteller_love,dlg_plaza_storyteller,dlg_plaza_storyteller_l03,2,1,听巷弄人情",
        "dch_dlg_plaza_storyteller_coin,dlg_plaza_storyteller,dlg_plaza_storyteller_l03,3,1,听银钱门道",
        "dch_dlg_home_window_ok,dlg_home_window,dlg_home_window_l03,1,1,",
        "dch_dlg_co_memo_careful,dlg_co_memo,dlg_co_memo_l03,1,1,稳妥送达",
        "dch_dlg_co_memo_peek,dlg_co_memo,dlg_co_memo_l03,2,1,路上偷看一眼",
    ],
)

append_rows(
    "effects.csv",
    [
        # shelter
        "fx_dock_shelter_intel,action,dock_shelter_talk,stat,,intel,add,3,1,",
        "fx_dock_shelter_net,action,dock_shelter_talk,stat,,network_base,add,2,1,",
        "fx_dock_shelter_sus,action,dock_shelter_talk,stat,,suspicion,add,-2,1,雨声掩护",
        # board rumor suspicion already in stock rule; small trust hit optional
        "fx_dock_board_rumor_trust,action,dock_board_rumor,stat,,trust,add,-1,1,",
        # dice stake
        "fx_plaza_dice_stake,action,plaza_dice,stat,,money,add,-8,1,",
        "fx_chk_plaza_dice_win,check_success,chk_plaza_dice,stat,,money,add,18,1,净约+10",
        "fx_chk_plaza_dice_win_net,check_success,chk_plaza_dice,stat,,network_base,add,1,1,",
        "fx_chk_plaza_dice_lose_sus,check_fail,chk_plaza_dice,stat,,suspicion,add,1,1,",
        # storyteller fee + branches
        "fx_plaza_story_fee,action,plaza_storyteller,stat,,money,add,-5,1,",
        "fx_story_dock_intel,dialogue_choice,dch_dlg_plaza_storyteller_dock,stat,,intel,add,4,1,",
        "fx_story_dock_net,dialogue_choice,dch_dlg_plaza_storyteller_dock,stat,,network_base,add,1,1,",
        "fx_story_love_sus,dialogue_choice,dch_dlg_plaza_storyteller_love,stat,,suspicion,add,-4,1,",
        "fx_story_love_favor,dialogue_choice,dch_dlg_plaza_storyteller_love,relation,,su_qing:player:favor,add,1,1,心软一点",
        "fx_story_coin_intel,dialogue_choice,dch_dlg_plaza_storyteller_coin,stat,,intel,add,2,1,",
        "fx_story_coin_elite,dialogue_choice,dch_dlg_plaza_storyteller_coin,stat,,network_elite,add,1,1,",
        # window
        "fx_home_window_intel,action,home_window_watch,stat,,intel,add,2,1,",
        "fx_home_window_sus,action,home_window_watch,stat,,suspicion,add,-3,1,",
        # memo
        "fx_co_memo_base_trust,action,co_memo_run,stat,,trust,add,1,1,",
        "fx_co_memo_careful_trust,dialogue_choice,dch_dlg_co_memo_careful,stat,,trust,add,3,1,",
        "fx_co_memo_careful_money,dialogue_choice,dch_dlg_co_memo_careful,stat,,money,add,6,1,跑腿津贴",
        "fx_co_memo_peek_intel,dialogue_choice,dch_dlg_co_memo_peek,stat,,intel,add,4,1,",
        "fx_co_memo_peek_sus,dialogue_choice,dch_dlg_co_memo_peek,stat,,suspicion,add,5,1,",
        "fx_co_memo_peek_money,dialogue_choice,dch_dlg_co_memo_peek,stat,,money,add,4,1,",
    ],
)

append_rows(
    "idle_chatter.csv",
    [
        "chatter_dock_shelter,dock,dock_loading,any,all,8,1,1,",
        "chatter_plaza_dice,plaza,plaza_court,afternoon|evening,all,6,1,1,",
    ],
)
append_rows(
    "tips.csv",
    [
        "tip_variety,system,24,tip.variety,1,1,",
    ],
)

# weather condition for shelter chatter - optional rain
append_rows(
    "conditions.csv",
    [
        "c_idle_chatter_dock_shelter_rain,idle_chatter,chatter_dock_shelter,1,weather,rain,eq,1,",
        "c_idle_chatter_dock_shelter_storm,idle_chatter,chatter_dock_shelter,2,weather,storm,eq,1,",
    ],
)

zh = {
    "actions.dock_shelter_talk.name": "雨棚下听闲话",
    "actions.dock_shelter_talk.description": "只有下雨/暴雨：挤在棚下，号子停了，嘴却闲不住。",
    "actions.dock_shelter_talk.result": "雨声盖过耳语。你捞到几句平时听不到的话。",
    "actions.dock_board_rumor.name": "船期牌旁放风",
    "actions.dock_board_rumor.description": "耗一点情报，让船期说法走样——股价会轻晃（冷却1天）。",
    "actions.dock_board_rumor.result": "牌下有人接话。行情像被雨点打皱了一下。",
    "actions.plaza_dice.name": "棚下掷骰",
    "actions.plaza_dice.description": "押八块银元掷一把。手气看人脉，输了当交朋友。",
    "actions.plaza_dice.result": "骰子停了。棚下起哄声比输赢还响。",
    "actions.plaza_storyteller.name": "听说书先生",
    "actions.plaza_storyteller.description": "花五块听一段：码头、人情或银钱门道（隔天一次）。",
    "actions.plaza_storyteller.result": "锣鼓收了。故事留下气味，也留下线索。",
    "actions.home_window_watch.name": "窗边观街",
    "actions.home_window_watch.description": "晚上靠窗看巷口灯火——歇一口气，也听得见风声。",
    "actions.home_window_watch.result": "巷口走过去两个人。你把窗帘又拉紧一分。",
    "actions.co_memo_run.name": "跑楼送公文",
    "actions.co_memo_run.description": "把卷宗送到别层。稳妥涨信任；偷看一眼涨情报也涨嫌疑。",
    "actions.co_memo_run.result": "楼梯转角的脚步声还在耳边。",
    "dialogue_choices.dch_dlg_dock_shelter_ok.label": "再听两句就走",
    "dialogue_choices.dch_dlg_dock_board_rumor_ok.label": "把话说到恰到好处",
    "dialogue_choices.dch_dlg_plaza_dice_ok.label": "掷！",
    "dialogue_choices.dch_dlg_plaza_storyteller_dock.label": "听码头段子",
    "dialogue_choices.dch_dlg_plaza_storyteller_love.label": "听巷弄人情",
    "dialogue_choices.dch_dlg_plaza_storyteller_coin.label": "听银钱门道",
    "dialogue_choices.dch_dlg_home_window_ok.label": "把窗帘拉上",
    "dialogue_choices.dch_dlg_co_memo_careful.label": "稳妥送达，不乱看",
    "dialogue_choices.dch_dlg_co_memo_peek.label": "路上偷看一眼卷宗",
    "dialogue_lines.dlg_dock_shelter_l01.text": "暴雨把装卸号子砸哑了。众人挤在雨棚下，烟头一点红，闲话比海水咸。",
    "dialogue_lines.dlg_dock_shelter_l02.text": "挤进来。耳朵比嘴巴管用。",
    "dialogue_lines.dlg_dock_shelter_l03.text": "有人骂船期，有人骂账房。雨停之前，你已经多知道两件不该知道的事。",
    "dialogue_lines.dlg_dock_board_rumor_l01.text": "船期牌被雨水洇开字迹。你只要在旁轻声一句，牌下的人就会替你传开。",
    "dialogue_lines.dlg_dock_board_rumor_l02.text": "……今晚那班，怕是靠不了岸。",
    "dialogue_lines.dlg_dock_board_rumor_l03.text": "话像油珠散开。你听见远处证券行的人开始改口风——宏远的价轻轻顿了一下。",
    "dialogue_lines.dlg_plaza_dice_l01.text": "半场边支了张矮桌，骰盅一扣：八块银元，单把定输赢。",
    "dialogue_lines.dlg_plaza_dice_l02.text": "来。输了当交朋友。",
    "dialogue_lines.dlg_plaza_dice_l03.text": "盅揭开的一瞬，棚下齐齐吸气。点数比良心干净。",
    "dialogue_lines.dlg_plaza_storyteller_l01.text": "情报茶摊旁支着醒木。先生问：今儿听码头、听人情，还是听银钱？",
    "dialogue_lines.dlg_plaza_storyteller_l02.text": "听一段能用的。",
    "dialogue_lines.dlg_plaza_storyteller_l03.text": "醒木一响，故事落地。你付了钱，也把句子记进袖口。",
    "dialogue_lines.dlg_home_window_l01.text": "出租屋窗玻璃上结着雾。巷口灯火一晃一晃，像有人故意走慢。",
    "dialogue_lines.dlg_home_window_l02.text": "再看一会。城里的夜比码头老实。",
    "dialogue_lines.dlg_home_window_l03.text": "你把看见的背影和听见的碎语叠在一起——够今晚睡前咀嚼。",
    "dialogue_lines.dlg_co_memo_l01.text": "副理丢来一卷宗：送到三楼，别耽搁。封口的蜡还热。",
    "dialogue_lines.dlg_co_memo_l02.text": "我这就去。",
    "dialogue_lines.dlg_co_memo_l03.text": "楼梯转角没人。你可以稳妥送到，也可以让眼睛比脚步快一步。",
    "idle_chatter.chatter_dock_shelter.text": "雨棚下有人骂：这种天还想出货？除非账在心里。",
    "idle_chatter.chatter_plaza_dice.text": "骰盅一响，旁边小孩跟着喊点数——输赢他们比谁都懂。",
    "ui.locked.reason_max_uses": "今日已做过 {n} 次",
    "ui.locked.reason_cooldown": "冷却中 · 第{day}天可再做",
    "tip.variety": "别只会搬货：雨天去雨棚听闲话；广场可掷骰/听说书；船期牌能放风晃股价；公司可跑楼送公文（可偷看）。同类打工每天有次数上限。",
    "tip.money_ways": "赚钱：码头搬货（每日有限）/晚班/跑腿；雨棚听闲话不赚钱但长情报；广场帮摊、卖货、刮刮乐、掷骰；公司办公与送公文。交易所与通洋是中后期。",
}

en = {
    "actions.dock_shelter_talk.name": "Shelter Gossip (Rain)",
    "actions.dock_shelter_talk.description": "Rain/storm only: crowd under the shed — chants stop, mouths don't.",
    "actions.dock_shelter_talk.result": "Rain covers whispers. You catch lines you wouldn't on a clear day.",
    "actions.dock_board_rumor.name": "Whisper at the Sailing Board",
    "actions.dock_board_rumor.description": "Spend a little intel; nudge talk so the price twitches (1-day cooldown).",
    "actions.dock_board_rumor.result": "Word spreads under the board. Hongyuan's price flinches.",
    "actions.plaza_dice.name": "Shed Dice",
    "actions.plaza_dice.description": "Stake 8 silver on a throw. Network helps luck.",
    "actions.plaza_dice.result": "Dice settle. The holler outruns the purse.",
    "actions.plaza_storyteller.name": "Listen to the Storyteller",
    "actions.plaza_storyteller.description": "Pay 5 for a tale: dock, hearts, or coin (once a day).",
    "actions.plaza_storyteller.result": "The clapper falls. The story leaves a smell — and a clue.",
    "actions.home_window_watch.name": "Watch the Lane",
    "actions.home_window_watch.description": "Evening at the window — rest the nerves, catch the street.",
    "actions.home_window_watch.result": "Two backs pass the lantern. You draw the curtain tighter.",
    "actions.co_memo_run.name": "Run a Memo Upstairs",
    "actions.co_memo_run.description": "Deliver a dossier. Careful builds trust; a peek builds intel and heat.",
    "actions.co_memo_run.result": "Stairwell footsteps linger in your ear.",
    "dialogue_choices.dch_dlg_dock_shelter_ok.label": "One more earful, then go",
    "dialogue_choices.dch_dlg_dock_board_rumor_ok.label": "Place the words just so",
    "dialogue_choices.dch_dlg_plaza_dice_ok.label": "Throw!",
    "dialogue_choices.dch_dlg_plaza_storyteller_dock.label": "A dock yarn",
    "dialogue_choices.dch_dlg_plaza_storyteller_love.label": "A lane of hearts",
    "dialogue_choices.dch_dlg_plaza_storyteller_coin.label": "A coin lesson",
    "dialogue_choices.dch_dlg_home_window_ok.label": "Draw the curtain",
    "dialogue_choices.dch_dlg_co_memo_careful.label": "Deliver clean — don't look",
    "dialogue_choices.dch_dlg_co_memo_peek.label": "Peek at the dossier on the stairs",
    "dialogue_lines.dlg_dock_shelter_l01.text": "Rain kills the loading chant. Under the shed, cigarettes glow; gossip is saltier than the sea.",
    "dialogue_lines.dlg_dock_shelter_l02.text": "Squeeze in. Ears beat mouths.",
    "dialogue_lines.dlg_dock_shelter_l03.text": "Someone curses sailing dates, someone curses the books. Before the rain lifts, you know two things you shouldn't.",
    "dialogue_lines.dlg_dock_board_rumor_l01.text": "Rain blurs the board ink. One soft sentence, and the crowd will carry it for you.",
    "dialogue_lines.dlg_dock_board_rumor_l02.text": "…Tonight's berth may not hold.",
    "dialogue_lines.dlg_dock_board_rumor_l03.text": "Word spreads like oil. Far off, exchange mouths rewrite — Hongyuan's price dips.",
    "dialogue_lines.dlg_plaza_dice_l01.text": "A low table by the court. Cup down: eight silver, one throw.",
    "dialogue_lines.dlg_plaza_dice_l02.text": "In. Losing still buys friends.",
    "dialogue_lines.dlg_plaza_dice_l03.text": "The cup lifts; the shed inhales. The pips are cleaner than conscience.",
    "dialogue_lines.dlg_plaza_storyteller_l01.text": "A storyteller's clapper by the tea stall: dock, hearts, or coin today?",
    "dialogue_lines.dlg_plaza_storyteller_l02.text": "Something I can use.",
    "dialogue_lines.dlg_plaza_storyteller_l03.text": "Clapper falls. You pay; you sleeve a sentence.",
    "dialogue_lines.dlg_home_window_l01.text": "Fog on the glass. Lane lanterns sway like someone walking slow on purpose.",
    "dialogue_lines.dlg_home_window_l02.text": "A little longer. City nights are more honest than the dock.",
    "dialogue_lines.dlg_home_window_l03.text": "You stack a silhouette with a scrap of talk — enough to chew before sleep.",
    "dialogue_lines.dlg_co_memo_l01.text": "The vice drops a dossier: third floor, no delay. Wax still warm.",
    "dialogue_lines.dlg_co_memo_l02.text": "On it.",
    "dialogue_lines.dlg_co_memo_l03.text": "Empty stair turn. Deliver clean — or let your eyes outrun your feet.",
    "idle_chatter.chatter_dock_shelter.text": "Under the shed: weather like this, only books still move cargo.",
    "idle_chatter.chatter_plaza_dice.text": "The cup rattles; kids shout the pips louder than the bettors.",
    "ui.locked.reason_max_uses": "Already done {n}× today",
    "ui.locked.reason_cooldown": "Cooling down · free again day {day}",
    "tip.variety": "Don't only haul crates: rain unlocks shelter gossip; plaza has dice/storyteller; sailing board can nudge price; company memo runs branch. Daily caps on grind jobs.",
    "tip.money_ways": "Earn: dock labor (daily capped)/overtime/errands; plaza help/sell/scratch/dice; company desk and memo runs. Exchange and Tongyang pay later.",
}

upsert_l10n("l10n/zh_CN.csv", zh)
upsert_l10n("l10n/en.csv", en)
print("done")
