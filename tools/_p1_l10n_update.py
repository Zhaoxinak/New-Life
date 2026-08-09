# -*- coding: utf-8 -*-
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs/tables/packs/core/l10n"

UPDATES = {
    "zh_CN.csv": {
        "ui.choice.prefix_soft": "【退】",
        "ui.choice.prefix_hard": "【硬】",
        "ui.choice.prefix_probe": "【试】",
        "ui.choice.tip_soft": "退让 / 缓和",
        "ui.choice.tip_hard": "强硬 / 高代价",
        "ui.choice.tip_probe": "试探 / 套话",
        "dialogue_choices.dch_dlg_co_work_ok.label": "埋头写完，别抬头",
        "dialogue_choices.dch_dlg_co_work_overtime.label": "加班把卷宗摸熟——多留一刻",
        "dialogue_choices.dch_dlg_co_eaves_safe.label": "听完就撤，别多留",
        "dialogue_choices.dch_dlg_co_eaves_linger.label": "再贴一阵——更险也更值",
        "dialogue_choices.dch_dlg_dock_bribe_ok.label": "把茶钱塞过去",
        "dialogue_choices.dch_dlg_dock_work_ok.label": "扛完这班，少开口",
        "dialogue_choices.dch_dlg_dock_work_slow.label": "故意慢半拍，听清号子里的话",
        "dialogue_choices.dch_dlg_boss_task_ok.label": "领了差事就退",
        "dialogue_choices.dch_dlg_boss_task_askpay.label": "委婉多要一点辛苦钱",
        "dialogue_choices.dch_dlg_chen_sell_ok.label": "按价把情报交出去",
        "dialogue_choices.dch_dlg_home_rest_ok.label": "先睡，明天再装没事",
        "dialogue_choices.dch_dlg_home_rest_think.label": "躺着也把线再理一遍",
        "dialogue_choices.dch_dlg_home_organize_ok.label": "把证据压进抽屉最深处",
        "dialogue_choices.dch_dlg_home_organize_burn.label": "烧掉太烫的纸——宁可少一条线",
        "dialogue_choices.dch_dlg_su_talk_soft.label": "轻声安慰，再慢慢问周家近况",
        "dialogue_choices.dch_dlg_su_talk_press.label": "逼问：你和少霆到底走多近",
        "dialogue_choices.dch_dlg_su_talk_scheme.label": "试探她：帮你留意父子的缝",
        "dialogue_choices.dch_dlg_su_guide_ok.label": "软声答应：我会护着你",
        "dialogue_choices.dch_dlg_su_guide_cold.label": "只要结果，别谈我们",
        "dialogue_choices.dch_dlg_son_meet_endure.label": "忍着把事办完，不抬杠",
        "dialogue_choices.dch_dlg_son_meet_needle.label": "硬提一句：老板更信旧人",
        "dialogue_choices.dch_dlg_dock_steal_ok.label": "抄完就走，别贪",
        "dialogue_choices.dch_dlg_dock_steal_extra.label": "多撕半页——赌这一下",
        "hotspots.home_bed.description": "潮声近一点，外面的眼睛就远一点。只有这里能喘口气。",
        "hotspots.home_desk.description": "灯油味里摊开纸片。外面是码头与公司；这里才是你私密的战场。",
        "hotspots.home_living.description": "客厅灯一跳，话就变轻。晚晴未说完的句子，只肯在这里落地。",
        "actions.home_rest.description": "关上门睡一觉，把嫌疑冲淡一点",
        "actions.home_rest.result": "潮声贴着窗。门外的目光暂时够不着你——嫌疑淡了一寸。",
        "actions.home_organize.description": "在灯下把碎片拼成能用的线",
        "actions.home_organize.result": "纸边对齐。这屋里的安静，比办公室的茶盖更让人清醒。",
        "actions.home_plan.description": "对着灯芯，把下一步钉死",
        "actions.home_plan.result": "你把复仇写成三步，又划掉两步——只留给明天能迈出的那一脚。",
        "actions.home_talk_su.description": "关起门，和晚晴把没说完的话说完",
        "actions.home_talk_su.result": "灯油燃尽前，她的声音比白天软；话还没说完，夜已经深了。",
        "actions.home_guide_su.description": "压低声音，推她去少霆那边递话",
        "actions.home_guide_su.result": "她点头很轻，像怕被夜听见——也怕被你听见她其实在犹豫。",
        "dialogue_lines.dlg_su_talk_l01.text": "阿海……门关了。你今天回来得晚。码头还是那么累吗？",
        "dialogue_lines.dlg_su_talk_l02.text": "还行。你呢？在这屋里可以说实话——少霆那边有没有为难你？",
        "dialogue_lines.dlg_su_talk_l03.text": "他……只是爱送东西。洋纱、手帕。我没收重的。……真的。",
        "dialogue_lines.dlg_su_talk_l04.text": "灯光一跳。她指尖不安，像怕吵醒隔壁——又像怕话说太满。",
        "dialogue_line_variants.var_su_talk_l04_betray.text": "灯光一跳。她指尖的不安，已经不像是怕你难过——更像是怕你拆穿。",
        "dialogue_lines.dlg_home_rest_l01.text": "床板吱呀。潮声把一天的硬壳一点点冲开。",
        "dialogue_lines.dlg_home_rest_l02.text": "明天还得到外面装成没事人。今晚，先只做阿海。",
        "dialogue_lines.dlg_home_rest_l03.text": "梦里有人拍桌，也有人摔门——醒时只剩灯芯的余温。",
        "dialogue_lines.dlg_home_organize_l01.text": "旧信、单据、袖口潮腥。这张桌只对你诚实。",
        "dialogue_lines.dlg_home_organize_l02.text": "先把线理直。乱的时候才有刀——可别让人进门看见。",
        "dialogue_lines.dlg_home_organize_l03.text": "桌面干净了，心里未必。窗外号子远了，像另一个世界。",
        "dialogue_lines.dlg_su_guide_l01.text": "灯芯噼啪。你压低声音：若她「无意」再提账目，裂缝会自己长。",
        "dialogue_lines.dlg_su_guide_l04.text": "……我试试。但你不许把我推到火上。这话，只在这屋里说。",
    },
    "en.csv": {
        "ui.choice.prefix_soft": "[Yield] ",
        "ui.choice.prefix_hard": "[Hard] ",
        "ui.choice.prefix_probe": "[Probe] ",
        "ui.choice.tip_soft": "Yield / soften",
        "ui.choice.tip_hard": "Hard / high cost",
        "ui.choice.tip_probe": "Probe / fish for info",
        "dialogue_choices.dch_dlg_co_work_ok.label": "Finish heads-down—don't look up",
        "dialogue_choices.dch_dlg_co_work_overtime.label": "Stay late; learn the dossiers",
        "dialogue_choices.dch_dlg_co_eaves_safe.label": "Hear it and leave—don't linger",
        "dialogue_choices.dch_dlg_co_eaves_linger.label": "Linger longer—riskier, richer",
        "dialogue_choices.dch_dlg_dock_bribe_ok.label": "Slip him the tea money",
        "dialogue_choices.dch_dlg_dock_work_ok.label": "Finish the shift; keep quiet",
        "dialogue_choices.dch_dlg_dock_work_slow.label": "Slow a half-beat; catch the chant",
        "dialogue_choices.dch_dlg_boss_task_ok.label": "Take the errand and withdraw",
        "dialogue_choices.dch_dlg_boss_task_askpay.label": "Gently ask for a little more pay",
        "dialogue_choices.dch_dlg_chen_sell_ok.label": "Hand over the intel at price",
        "dialogue_choices.dch_dlg_home_rest_ok.label": "Sleep first; act fine tomorrow",
        "dialogue_choices.dch_dlg_home_rest_think.label": "Lie still and rethread the line",
        "dialogue_choices.dch_dlg_home_organize_ok.label": "Bury the proof in the deepest drawer",
        "dialogue_choices.dch_dlg_home_organize_burn.label": "Burn the hottest pages—lose a thread",
        "dialogue_choices.dch_dlg_su_talk_soft.label": "Comfort her softly, then ask about the Zhou house",
        "dialogue_choices.dch_dlg_su_talk_press.label": "Press: how close are you to Shaoting?",
        "dialogue_choices.dch_dlg_su_talk_scheme.label": "Probe: watch the father–son seam for me",
        "dialogue_choices.dch_dlg_su_guide_ok.label": "Softly promise: I'll protect you",
        "dialogue_choices.dch_dlg_su_guide_cold.label": "Results only—no talk of us",
        "dialogue_choices.dch_dlg_son_meet_endure.label": "Endure and finish; don't spar",
        "dialogue_choices.dch_dlg_son_meet_needle.label": "Needle him: the boss trusts the old hands",
        "dialogue_choices.dch_dlg_dock_steal_ok.label": "Copy and go—don't get greedy",
        "dialogue_choices.dch_dlg_dock_steal_extra.label": "Tear an extra half-page—gamble it",
        "hotspots.home_bed.description": "Tide closer, eyes farther. Only here can you breathe.",
        "hotspots.home_desk.description": "Paper under lamp oil. Outside is dock and company; here is your private war.",
        "hotspots.home_living.description": "Living-room lamp flickers; voices soften. Wanqing's unfinished sentences land only here.",
        "actions.home_rest.description": "Shut the door and sleep; wash a little suspicion away",
        "actions.home_rest.result": "Tide against the window. Outside eyes can't reach you—suspicion eases an inch.",
        "actions.home_organize.description": "Under the lamp, stitch scraps into a usable line",
        "actions.home_organize.result": "Edges align. This quiet is clearer than any tea-lid tap at the office.",
        "actions.home_plan.description": "By the lamp wick, nail tomorrow's first step",
        "actions.home_plan.result": "You write revenge in three steps, cross out two—leave only the step you can take.",
        "actions.home_talk_su.description": "Close the door; finish what you couldn't say outside",
        "actions.home_talk_su.result": "Before the oil burns out her voice is softer than daytime; night deepens mid-sentence.",
        "actions.home_guide_su.description": "In a low voice, push her to pass word to Shaoting",
        "actions.home_guide_su.result": "She nods lightly, as if night might overhear—and as if you might hear her hesitate.",
        "dialogue_lines.dlg_su_talk_l01.text": "A-Hai… the door's shut. You're late again. Is the dock still that hard?",
        "dialogue_lines.dlg_su_talk_l02.text": "Fine. And you? In this room we can tell truth—has Shaoting pressed you?",
        "dialogue_lines.dlg_su_talk_l03.text": "He… just likes gifts. Yarn, handkerchiefs. I didn't take the dear ones.… Truly.",
        "dialogue_lines.dlg_su_talk_l04.text": "The lamp flickers. Her fingers worry as if waking the neighbors—or saying too much.",
        "dialogue_line_variants.var_su_talk_l04_betray.text": (
            "The lamp flickers. Her restless fingers no longer fear your hurt—they fear being found out."
        ),
        "dialogue_lines.dlg_home_rest_l01.text": "The bed creaks. Tide washes the day's hard shell thin.",
        "dialogue_lines.dlg_home_rest_l02.text": "Tomorrow you act fine outside. Tonight, only be A-Hai.",
        "dialogue_lines.dlg_home_rest_l03.text": "Dreams of slammed cups and doors—wake to the wick's last warmth.",
        "dialogue_lines.dlg_home_organize_l01.text": "Old letters, slips, tide on a cuff. This desk is honest only to you.",
        "dialogue_lines.dlg_home_organize_l02.text": "Straighten the thread. Chaos holds a knife—don't let anyone see the table.",
        "dialogue_lines.dlg_home_organize_l03.text": "The desk is clean; the heart isn't. Outside chants fade like another world.",
        "dialogue_lines.dlg_su_guide_l01.text": (
            "The wick snaps. You lower your voice: if she 'casually' mentions ledgers again, the crack grows itself."
        ),
        "dialogue_lines.dlg_su_guide_l04.text": "…I'll try. But don't push me into the fire. That stays in this room.",
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


def main() -> None:
    for fname, mapping in UPDATES.items():
        apply(fname, mapping)


if __name__ == "__main__":
    main()
