# -*- coding: utf-8 -*-
"""One-shot P0 l10n updates. Safe to delete after use."""
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs" / "tables" / "packs" / "core" / "l10n"

UPDATES = {
    "zh_CN.csv": {
        "events.ev_day1_intro.title": "顺风里的异响",
        "events.ev_day1_intro.body": (
            "码头风顺，组长升主管几乎板上钉钉，晚晴也开始跟你谈婚事。"
            "你正想松一口气，却听见副理办公室里少霆的笑声——还有她压低的应声。"
            "茶杯盖一合，你突然明白：有人已经在替你安排「接下来该怎么走」。"
        ),
        "event_choices.ch_intro_ok.label": "我已被卷进局里了",
        "events.ev_day6_su_distance.title": "手帕不是给我的",
        "events.ev_day6_su_distance.body": (
            "晚晴从副理办公室出来，袖口多了块洋布手帕——绣着「霆」字。"
            "她看见你，先把帕子藏进掌心，又挤出一句「没什么」。"
            "你一直以为她站在你这边。这一秒，裂缝终于露出了边。"
        ),
        "event_choices.ch_d6_ask.label": "当众质问：那帕子谁给的",
        "event_choices.ch_d6_hold.label": "装作没看见，把恨意吞下",
        "dialogue_line_variants.var_su_talk_l02_low.text": "还行。……别用那种眼神看我。少霆那边，你自己清楚。",
        "dialogue_line_variants.var_su_talk_l03_betray.text": "他说明天还要送。我……我回不了你。阿海，别逼我现在选。",
        "dialogue_line_variants.var_su_talk_l03_drift.text": "洋纱很软。你要是再这样盯着，我就……先收下了。",
        "dialogue_lines.dlg_su_talk_l04.text": "灯光一跳。她指尖的不安，已经不像是怕你难过——更像是怕你拆穿。",
        "events.ev_b_public_clash.title": "茶杯碎了",
        "events.ev_b_public_clash.body": (
            "办公室里一声脆响。周鸿业摔了茶杯，周少霆摔门而去。"
            "窃窃私语里只剩一句：宏远要乱了。"
            "你站在走廊阴影里，看着裂缝真正裂开——而这裂缝，是你亲手推深的。"
        ),
        "event_choices.ch_b_clash_ok.label": "站在裂缝里，把这一刀记住",
        "endings.ending_b.name": "裂缝开了",
        "endings.ending_b.description": (
            "茶杯碎了，门也摔了。胜负不在账本上——在他们父子中间。"
            "你站在阴影里，终于被逼着承认：自己站在了哪一边。"
        ),
        "actions.co_work.description": "把公文写成「可靠」，好在楼里站稳",
        "actions.co_work.result": "毛笔写到发僵。茶盖轻叩：今天，你还像个听话的笔杆。",
        "actions.co_eavesdrop.description": "贴在屏风后，收集能咬人的闲话",
        "actions.co_eavesdrop.result": "屏风后的闲话像刀背——擦过耳边，就能割破谁的前途。",
        "actions.co_meet_son.description": "与副理周旋，把嘲讽听成情报",
        "actions.co_meet_son.result": "少霆的嘲讽挂在廊柱上。他每笑一声，楼里的空气就紧一分。",
        "actions.co_meet_su.description": "在副理处撞见晚晴——看她站在谁那边",
        "actions.co_meet_su.result": "走廊目光一碰就拆开。她袖口的香，不像是家里的。",
        "actions.co_flatter_boss.description": "对老板表忠，换一寸信任",
        "actions.co_flatter_boss.result": "老板茶盖轻叩桌面。算你过关——也算他多看你一眼。",
        "actions.co_pass_rumor.description": "借副理之口，把假话钉进真耳朵",
        "actions.co_pass_rumor.result": "假话进了真耳朵。父子之间，空气紧了一线。",
        "actions.dock_work.description": "扛货换工钱，汗里听号子",
        "actions.dock_work.result": "号子砸在肩上。工钱到手，汗没干——远处有人低声笑：组长也有今天。",
        "actions.dock_chat.description": "压低嗓子打听货场怨气",
        "actions.dock_chat.result": "工人把烟头一摁：夜班的单，有人做了手脚。别大声。",
        "actions.dock_report.description": "对主管表现积极，换一点眼色",
        "actions.dock_report.result": "主管哼了一声，算听见了。码头上的信任，从不肯写成字。",
        "actions.dock_steal_list.description": "趁乱抄进货明细——被看见就完",
        "actions.dock_steal_list.result": "纸边进袖口，心跳却乱。仓门一响，成败只剩半息。",
        "actions.dock_bribe_clerk.description": "塞茶钱，换一句「记不清」",
        "actions.dock_bribe_clerk.result": "银元落袋。他指缝一松，消息比钱先滑出来——也比钱脏。",
        "hotspots.company_boss.description": "茶盖一叩定生死。这里说话，比公文更像命令。",
        "hotspots.company_finance.description": "窗帘常拉死。数字会咬人，闲话会要命。",
        "hotspots.company_floor.description": "屏风后的闲话比公文快。每一步都像被人记账。",
        "hotspots.company_vp.description": "洋纱与嘲讽并存。副理一笑，楼里就有人倒霉。",
        "hotspots.dock_board.description": "船期与行情的公开墙。墨迹未干，就有人改口。",
        "hotspots.dock_corner.description": "拐角烟与私语。适合谈不该写进账的事。",
        "hotspots.dock_loading.description": "号子与潮腥最浓处。力气值钱，嘴更值钱。",
        "hotspots.dock_office.description": "主管批单的小屋。笔尖比人尖，眼神从不闲着。",
        "ui.situation.line": "局势：{text}",
        "ui.situation.suspicion_up": "有人多盯了你一眼",
        "ui.situation.suspicion_down": "风声暂时松了",
        "ui.situation.favor_down": "身边的人更冷了",
        "ui.situation.favor_up": "有人把你往里拉了半步",
        "ui.situation.tension_up": "楼里的裂缝又深了一寸",
        "ui.situation.intel_up": "你多攥住了一句能用的话",
        "ui.situation.money_up": "口袋沉了，也更容易被人盯",
        "ui.situation.generic": "这一步留下了痕迹",
    },
    "en.csv": {
        "events.ev_day1_intro.title": "A Wrong Note in Fair Wind",
        "events.ev_day1_intro.body": (
            "Dock wind feels kind; the warehouse seat is almost yours, and Wanqing talks of marriage. "
            "Then you catch Shaoting's laugh from the vice office—and her low reply. "
            "The tea lid clicks shut. Someone is already arranging what you should do next."
        ),
        "event_choices.ch_intro_ok.label": "I'm already in their game",
        "events.ev_day6_su_distance.title": "The Handkerchief Isn't Mine",
        "events.ev_day6_su_distance.body": (
            'Wanqing leaves the vice office with a foreign handkerchief—embroidered "Ting." '
            'She hides it when she sees you and forces a "it\'s nothing." '
            "You thought she stood with you. In that second, the crack shows its edge."
        ),
        "event_choices.ch_d6_ask.label": "Demand: who gave you that?",
        "event_choices.ch_d6_hold.label": "Pretend not to see—swallow the hate",
        "dialogue_line_variants.var_su_talk_l02_low.text": "Fine.… Don't look at me like that. You know about Shaoting.",
        "dialogue_line_variants.var_su_talk_l03_betray.text": (
            "He said he'll send more tomorrow. I… can't answer you. A-Hai, don't make me choose now."
        ),
        "dialogue_line_variants.var_su_talk_l03_drift.text": "The yarn is soft. Keep staring and I'll… keep it first.",
        "dialogue_lines.dlg_su_talk_l04.text": (
            "The lamp flickers. Her restless fingers no longer fear your hurt—they fear being found out."
        ),
        "events.ev_b_public_clash.title": "The Cup Breaks",
        "events.ev_b_public_clash.body": (
            "A sharp crack in the office. Hongye smashes a cup; Shaoting slams the door. "
            "Whispers say only: Hongyuan will tear itself. "
            "In the corridor shadow you watch the crack open—for you pushed it deeper."
        ),
        "event_choices.ch_b_clash_ok.label": "Stand in the crack. Remember this cut.",
        "endings.ending_b.name": "The Crack Opens",
        "endings.ending_b.description": (
            "Cup broken. Door slammed. Victory isn't in the ledgers—it's between father and son. "
            "In the shadow, you are forced to admit which side you chose."
        ),
        "actions.co_work.description": "Write yourself as reliable so the floor keeps you",
        "actions.co_work.result": "The brush stiffens. A tea lid taps: today you still look like an obedient pen.",
        "actions.co_eavesdrop.description": "Press the screen for gossip that can cut",
        "actions.co_eavesdrop.result": "Gossip behind the screen is a knife-back—one brush can cut a career.",
        "actions.co_meet_son.description": "Jockey with the vice; hear sneers as intel",
        "actions.co_meet_son.result": "Shaoting's sneer hangs on the pillar. Each laugh tightens the air.",
        "actions.co_meet_su.description": "Run into Wanqing at the vice—see whose side she stands",
        "actions.co_meet_su.result": "Eyes meet and tear apart. The scent on her sleeve is not from home.",
        "actions.co_flatter_boss.description": "Play loyal for an inch of trust",
        "actions.co_flatter_boss.result": "The boss taps his tea lid. You pass—and earn one more glance.",
        "actions.co_pass_rumor.description": "Feed a false tip through the vice into a true ear",
        "actions.co_pass_rumor.result": "A false word enters a true ear. Between father and son, the air tightens.",
        "actions.dock_work.description": "Haul for wages; listen to the chant in sweat",
        "actions.dock_work.result": (
            "Chants hit your shoulders. Pay lands; sweat still wet—"
            "someone laughs low: even the foreman has days like this."
        ),
        "actions.dock_chat.description": "Ask yard grudges in a low voice",
        "actions.dock_chat.result": "A worker kills his cigarette: night manifests were fiddled. Keep it quiet.",
        "actions.dock_report.description": "Look eager for a scrap of the chief's eye",
        "actions.dock_report.result": "The chief snorts—heard, at least. Dock trust is never written down.",
        "actions.dock_steal_list.description": "Copy intake sheets unseen—caught means finished",
        "actions.dock_steal_list.result": "Paper into the sleeve; pulse stutters. One sound at the door decides it.",
        "actions.dock_bribe_clerk.description": "Pay tea money for a \"can't recall\"",
        "actions.dock_bribe_clerk.result": "Silver lands. Fingers loosen; news slips out before cash—and dirtier than cash.",
        "hotspots.company_boss.description": "A tea lid can decide a life. Talk here sounds like orders.",
        "hotspots.company_finance.description": "Curtains stay shut. Numbers bite; gossip kills.",
        "hotspots.company_floor.description": "Screen gossip outruns paperwork. Every step feels logged.",
        "hotspots.company_vp.description": "Yarn and sneers share a room. One smile, and someone downstairs pays.",
        "hotspots.dock_board.description": "Public sailings and market wind. Ink still wet, mouths already rewrite it.",
        "hotspots.dock_corner.description": "Corner smoke and whispers. For deals that stay off the books.",
        "hotspots.dock_loading.description": "Chants and tide-smell thickest here. Muscle pays; mouths pay more.",
        "hotspots.dock_office.description": "The chief's hut for stamps. Pens are sharper than people; eyes never idle.",
        "ui.situation.line": "Situation: {text}",
        "ui.situation.suspicion_up": "Someone watched you longer",
        "ui.situation.suspicion_down": "The wind eases—for now",
        "ui.situation.favor_down": "Someone beside you went colder",
        "ui.situation.favor_up": "Someone pulled you half a step closer",
        "ui.situation.tension_up": "The crack upstairs deepened an inch",
        "ui.situation.intel_up": "You gripped one more usable line",
        "ui.situation.money_up": "Your pocket is heavier—and easier to watch",
        "ui.situation.generic": "This step left a mark",
    },
}


def apply_file(fname: str, mapping: dict) -> None:
    path = ROOT / fname
    rows = []
    seen = set()
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        header = next(reader)
        rows.append(header)
        for row in reader:
            if not row:
                rows.append(row)
                continue
            key = row[0]
            if key in mapping:
                rows.append([key, mapping[key]] + row[2:])
                seen.add(key)
            else:
                rows.append(row)
    for key, val in mapping.items():
        if key not in seen:
            rows.append([key, val])
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerows(rows)
    print(f"{fname}: updated {len(seen)}, appended {len(mapping) - len(seen)}")


def main() -> None:
    for fname, mapping in UPDATES.items():
        apply_file(fname, mapping)


if __name__ == "__main__":
    main()
