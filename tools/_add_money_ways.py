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
            print(f"skip {rel}:{key}")
            continue
        to_add.append(row)
    if to_add:
        path.write_text(text + "\n".join(to_add) + "\n", encoding="utf-8")
        print(f"{rel}: +{len(to_add)}")
    else:
        print(f"{rel}: nothing")


def upsert_l10n(rel: str, updates: dict) -> None:
    path = ROOT / rel
    text = path.read_text(encoding="utf-8-sig")
    lines = text.splitlines()
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
    print(f"{rel}: upsert {len(updates)}")


def patch_effect_money(action_id: str, new_value: int) -> None:
    path = ROOT / "effects.csv"
    lines = path.read_text(encoding="utf-8-sig").splitlines()
    out = []
    for line in lines:
        parts = line.split(",")
        if (
            len(parts) >= 9
            and parts[1] == "action"
            and parts[2] == action_id
            and parts[3] == "stat"
            and parts[5] == "money"
            and parts[6] == "add"
        ):
            parts[7] = str(new_value)
            line = ",".join(parts)
            print(f"buff {action_id} money -> {new_value}")
        out.append(line)
    path.write_text("\n".join(out) + "\n", encoding="utf-8")


patch_effect_money("dock_work", 24)
patch_effect_money("co_work", 14)

# co_work overtime also pays a little
append_rows(
    "effects.csv",
    [
        "fx_dch_co_work_overtime_money,dialogue_choice,dch_dlg_co_work_overtime,stat,,money,add,6,1,加班津贴",
        # new actions
        "fx_dock_overtime_money,action,dock_overtime,stat,,money,add,32,1,",
        "fx_dock_overtime_sus,action,dock_overtime,stat,,suspicion,add,2,1,夜班惹眼",
        "fx_dock_overtime_net,action,dock_overtime,stat,,network_base,add,1,1,",
        "fx_dch_dock_overtime_ok_money,dialogue_choice,dch_dlg_dock_overtime_ok,stat,,money,add,4,1,干满再加一点",
        "fx_dock_errand_money,action,dock_errand,stat,,money,add,16,1,",
        "fx_dock_errand_intel,action,dock_errand,stat,,intel,add,1,1,",
        "fx_dock_errand_net,action,dock_errand,stat,,network_base,add,1,1,",
        "fx_plaza_help_stall_money,action,plaza_help_stall,stat,,money,add,18,1,",
        "fx_plaza_help_stall_net,action,plaza_help_stall,stat,,network_base,add,2,1,",
        "fx_plaza_help_stall_sus,action,plaza_help_stall,stat,,suspicion,add,-1,1,",
        "fx_plaza_ball_wager_stake,action,plaza_ball_wager,stat,,money,add,-8,1,先押注",
        "fx_chk_plaza_ball_win_money,check_success,chk_plaza_ball,stat,,money,add,22,1,赢回本+利",
        "fx_chk_plaza_ball_win_net,check_success,chk_plaza_ball,stat,,network_base,add,2,1,",
        "fx_chk_plaza_ball_lose_sus,check_fail,chk_plaza_ball,stat,,suspicion,add,1,1,输了被人看笑话",
        "fx_chk_plaza_ball_lose_net,check_fail,chk_plaza_ball,stat,,network_base,add,1,1,脸熟也算收获",
    ],
)

append_rows(
    "actions.csv",
    [
        "dock_overtime,dock_loading,evening,all,1,0,0,0,45,1,晚班加班多赚,dlg_dock_overtime,,",
        "dock_errand,dock_board,morning|afternoon,all,1,0,0,0,46,1,跑腿送信换小费,dlg_dock_errand,,",
        "plaza_help_stall,plaza_stalls,morning|afternoon,all,1,0,0,0,47,1,帮摊主打杂,dlg_plaza_help_stall,,",
        "plaza_ball_wager,plaza_court,afternoon,all,1,0,0,0,48,1,半场小赌,dlg_plaza_ball_wager,,chk_plaza_ball",
    ],
)

append_rows(
    "conditions.csv",
    [
        "c_act_plaza_ball_wager_money,action,plaza_ball_wager,1,stat,money,gte,8,",
    ],
)

# checks.csv schema
checks_header = (ROOT / "checks.csv").read_text(encoding="utf-8-sig").splitlines()[0]
print("checks header:", checks_header)
check_mods_header = (ROOT / "check_mods.csv").read_text(encoding="utf-8-sig").splitlines()[0]
print("check_mods header:", check_mods_header)

zh = {
    "actions.dock_overtime.name": "晚班加班搬货",
    "actions.dock_overtime.description": "晚上多扛几班。工钱厚，灯下也更招眼。",
    "actions.dock_overtime.result": "夜号子比白天狠。银元沉，嫌疑也薄薄加一层。",
    "actions.dock_errand.name": "跑腿送信",
    "actions.dock_errand.description": "帮船主/账房送个条子，换小费，顺带听两句船期。",
    "actions.dock_errand.result": "条子送到，小费到手。耳朵里多了一点码头动静。",
    "actions.plaza_help_stall.name": "帮摊打杂",
    "actions.plaza_help_stall.description": "帮摊主搬筐、收摊、找零钱——老实工钱。",
    "actions.plaza_help_stall.result": "袖子沾了油烟。口袋响了，摊主也记住你。",
    "actions.plaza_ball_wager.name": "半场小赌",
    "actions.plaza_ball_wager.description": "押八块银元比投篮。赢了翻本，输了当交朋友。",
    "actions.plaza_ball_wager.result": "人群起哄。输赢都在泥地上。",
    "dialogue_choices.dch_dlg_dock_overtime_ok.label": "干满这一班",
    "dialogue_choices.dch_dlg_dock_errand_ok.label": "送到就走",
    "dialogue_choices.dch_dlg_plaza_help_stall_ok.label": "把筐搬完",
    "dialogue_choices.dch_dlg_plaza_ball_wager_ok.label": "押上，开投",
    "dialogue_lines.dlg_dock_overtime_l01.text": "汽灯把甲板照成白刃。晚班的人少，工钱写在黑板上——比白天厚一截。",
    "dialogue_lines.dlg_dock_overtime_l02.text": "加一班。今晚不回去早睡。",
    "dialogue_lines.dlg_dock_overtime_l03.text": "号子砸到后半夜。银元沉，脊背更沉；远处有人盯着你数箱子。",
    "dialogue_lines.dlg_dock_errand_l01.text": "船期牌下有人招手：条子送到北栈，小费现结。",
    "dialogue_lines.dlg_dock_errand_l02.text": "给我。腿比嘴快。",
    "dialogue_lines.dlg_dock_errand_l03.text": "门一敲，银元一响。回来时你把听到的船号悄悄记下。",
    "dialogue_lines.dlg_plaza_help_stall_l01.text": "摊主喊：谁手快？筐沉，零钱乱，急死人。",
    "dialogue_lines.dlg_plaza_help_stall_l02.text": "我来。工钱怎么算？",
    "dialogue_lines.dlg_plaza_help_stall_l03.text": "忙过一阵，袖口全是味。摊主塞给你一叠零钱：下次还来。",
    "dialogue_lines.dlg_plaza_ball_wager_l01.text": "半场边上有人拍球：八块银元，三球两进。敢不敢？",
    "dialogue_lines.dlg_plaza_ball_wager_l02.text": "敢。输了当交朋友。",
    "dialogue_lines.dlg_plaza_ball_wager_l03.text": "人群围上来。球出手的一瞬，你听见银元在掌心里发烫。",
    "tip.low_money": "金钱紧时优先：码头「搬货/晚班加班/跑腿」、广场「帮摊打杂/卖闲置」、公司「日常办公」。私货与卖情报来钱快但惹嫌疑。",
    "tip.money_ways": "赚钱捷径：白天码头搬货或跑腿；晚上可加班；广场帮摊/卖货；公司办公略少但涨信任。交易所与通洋是中后期大头。",
}

en = {
    "actions.dock_overtime.name": "Night Overtime Loading",
    "actions.dock_overtime.description": "Extra evening shifts. Better pay, more eyes under the lamps.",
    "actions.dock_overtime.result": "Night chants hit harder. Silver sinks; a thin layer of heat sticks.",
    "actions.dock_errand.name": "Run Harbor Errands",
    "actions.dock_errand.description": "Deliver slips for captains/clerks — tips plus overheard sailing talk.",
    "actions.dock_errand.result": "Slip delivered, tip pocketed. A scrap of dock noise stays in your ear.",
    "actions.plaza_help_stall.name": "Help at a Stall",
    "actions.plaza_help_stall.description": "Haul crates, make change — honest day wages.",
    "actions.plaza_help_stall.result": "Sleeves smell of oil smoke. Pocket rattles; the stall remembers you.",
    "actions.plaza_ball_wager.name": "Half-Court Wager",
    "actions.plaza_ball_wager.description": "Stake 8 silver on shots. Win flips the bet; lose buys familiarity.",
    "actions.plaza_ball_wager.result": "The crowd hollers. Wins and losses land in the dirt.",
    "dialogue_choices.dch_dlg_dock_overtime_ok.label": "Work the full shift",
    "dialogue_choices.dch_dlg_dock_errand_ok.label": "Deliver and go",
    "dialogue_choices.dch_dlg_plaza_help_stall_ok.label": "Finish the crates",
    "dialogue_choices.dch_dlg_plaza_ball_wager_ok.label": "Stake it and shoot",
    "dialogue_lines.dlg_dock_overtime_l01.text": "Gas lamps blade the deck white. Fewer hands at night — the board pays thicker.",
    "dialogue_lines.dlg_dock_overtime_l02.text": "One more shift. No early sleep.",
    "dialogue_lines.dlg_dock_overtime_l03.text": "Chants into midnight. Silver sinks; someone counts your crates from afar.",
    "dialogue_lines.dlg_dock_errand_l01.text": "A wave under the sailing board: take this slip north — tip on delivery.",
    "dialogue_lines.dlg_dock_errand_l02.text": "Give it here. Legs beat mouths.",
    "dialogue_lines.dlg_dock_errand_l03.text": "Knock, silver. You pocket a ship number on the way back.",
    "dialogue_lines.dlg_plaza_help_stall_l01.text": "Stallkeeper: who is fast? Crates heavy, change a mess.",
    "dialogue_lines.dlg_plaza_help_stall_l02.text": "I'll take it. What's the pay?",
    "dialogue_lines.dlg_plaza_help_stall_l03.text": "After the rush, sleeves reek. A stack of change: come again.",
    "dialogue_lines.dlg_plaza_ball_wager_l01.text": "Someone thumps the ball: eight silver, two of three. In?",
    "dialogue_lines.dlg_plaza_ball_wager_l02.text": "In. Losing still buys friends.",
    "dialogue_lines.dlg_plaza_ball_wager_l03.text": "The circle closes. The coin burns as the ball leaves your hand.",
    "tip.low_money": "When money is tight: Dock load / night overtime / errands; Plaza help stall / sell goods; Company desk work. Black market and intel sell faster but raise heat.",
    "tip.money_ways": "Earn: day dock labor or errands; night overtime; plaza help/sell; company work pays less but builds trust. Exchange and Tongyang are mid-late money.",
}

# dialogues / lines / choices
append_rows(
    "dialogues.csv",
    [
        "dlg_dock_overtime,all,50,0,1,晚班加班",
        "dlg_dock_errand,all,50,0,1,跑腿",
        "dlg_plaza_help_stall,all,50,0,1,帮摊",
        "dlg_plaza_ball_wager,all,50,0,1,半场小赌",
    ],
)
append_rows(
    "dialogue_lines.csv",
    [
        "dlg_dock_overtime_l01,dlg_dock_overtime,1,narrator,neutral,1,",
        "dlg_dock_overtime_l02,dlg_dock_overtime,2,player,resolve,1,",
        "dlg_dock_overtime_l03,dlg_dock_overtime,3,narrator,neutral,1,",
        "dlg_dock_errand_l01,dlg_dock_errand,1,narrator,neutral,1,",
        "dlg_dock_errand_l02,dlg_dock_errand,2,player,resolve,1,",
        "dlg_dock_errand_l03,dlg_dock_errand,3,narrator,neutral,1,",
        "dlg_plaza_help_stall_l01,dlg_plaza_help_stall,1,narrator,neutral,1,",
        "dlg_plaza_help_stall_l02,dlg_plaza_help_stall,2,player,resolve,1,",
        "dlg_plaza_help_stall_l03,dlg_plaza_help_stall,3,narrator,neutral,1,",
        "dlg_plaza_ball_wager_l01,dlg_plaza_ball_wager,1,narrator,neutral,1,",
        "dlg_plaza_ball_wager_l02,dlg_plaza_ball_wager,2,player,tense,1,",
        "dlg_plaza_ball_wager_l03,dlg_plaza_ball_wager,3,narrator,neutral,1,",
    ],
)
append_rows(
    "dialogue_choices.csv",
    [
        "dch_dlg_dock_overtime_ok,dlg_dock_overtime,dlg_dock_overtime_l03,1,1,",
        "dch_dlg_dock_errand_ok,dlg_dock_errand,dlg_dock_errand_l03,1,1,",
        "dch_dlg_plaza_help_stall_ok,dlg_plaza_help_stall,dlg_plaza_help_stall_l03,1,1,",
        "dch_dlg_plaza_ball_wager_ok,dlg_plaza_ball_wager,dlg_plaza_ball_wager_l03,1,1,",
    ],
)

upsert_l10n("l10n/zh_CN.csv", zh)
upsert_l10n("l10n/en.csv", en)

# tips row
append_rows(
    "tips.csv",
    [
        "tip_money_ways,status,23,tip.money_ways,1,1,",
    ],
)
print("partial done — checks next")
