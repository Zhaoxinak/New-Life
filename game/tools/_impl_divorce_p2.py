# -*- coding: utf-8 -*-
"""Phase 2: home action/dialogue, variants, chatter, l10n upserts."""
import csv
import json
from pathlib import Path

root = Path(r"f:/Games/New-Life/docs/tables/packs/core")


def load(p: Path):
    with p.open(encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))
        fn = list(rows[0].keys()) if rows else []
    return fn, rows


def save(p: Path, fn, rows):
    with p.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fn, lineterminator="\n")
        w.writeheader()
        w.writerows(rows)


def upsert(path: Path, new_rows, id_key="id"):
    fn, rows = load(path)
    by = {r[id_key]: i for i, r in enumerate(rows)}
    for nr in new_rows:
        row = {k: "" for k in fn}
        for k, v in nr.items():
            if k in row:
                row[k] = str(v)
        if row[id_key] in by:
            rows[by[row[id_key]]] = row
            print("upd", path.name, row[id_key])
        else:
            rows.append(row)
            print("add", path.name, row[id_key])
    save(path, fn, rows)


def upsert_l10n(locale: str, pairs: dict):
    path = root / "l10n" / f"{locale}.csv"
    fn, rows = load(path)
    by = {r["key"]: i for i, r in enumerate(rows)}
    for key, text in pairs.items():
        row = {k: "" for k in fn}
        row["key"] = key
        row["text"] = text
        if key in by:
            rows[by[key]] = row
        else:
            rows.append(row)
            print("l10n+", locale, key)
    # keep stable-ish order: sort by key for new batch but preserve existing order mostly
    save(path, fn, rows)


# --- actions ---
upsert(
    root / "actions.csv",
    [
        {
            "id": "home_propose_divorce",
            "hotspot_id": "home_living",
            "periods": "evening",
            "tags": "B|all",
            "time_cost": "1",
            "suspicion_base": "0",
            "cooldown_days": "1",
            "max_uses": "0",
            "sort_order": "27",
            "enabled": "1",
            "notes": "主动谈退婚/散伙",
            "dialogue_id": "dlg_home_divorce",
            "stock_rule_id": "",
            "check_id": "",
        }
    ],
)

# --- dialogues ---
upsert(
    root / "dialogues.csv",
    [{"id": "dlg_home_divorce", "tags": "B|all", "priority": "60", "max_triggers": "0", "enabled": "1", "notes": "客厅谈退婚"}],
)

# --- dialogue lines ---
upsert(
    root / "dialogue_lines.csv",
    [
        {"id": "dlg_home_divorce_l01", "dialogue_id": "dlg_home_divorce", "sort": "1", "speaker_id": "narrator", "emotion": "neutral", "enabled": "1", "notes": ""},
        {"id": "dlg_home_divorce_l02", "dialogue_id": "dlg_home_divorce", "sort": "2", "speaker_id": "su_qing", "emotion": "soft", "enabled": "1", "notes": ""},
        {"id": "dlg_home_divorce_l03", "dialogue_id": "dlg_home_divorce", "sort": "3", "speaker_id": "player", "emotion": "resolve", "enabled": "1", "notes": ""},
        {"id": "dlg_home_divorce_l04", "dialogue_id": "dlg_home_divorce", "sort": "4", "speaker_id": "su_qing", "emotion": "cold", "enabled": "1", "notes": ""},
        {"id": "dlg_home_divorce_l05", "dialogue_id": "dlg_home_divorce", "sort": "5", "speaker_id": "narrator", "emotion": "neutral", "enabled": "1", "notes": ""},
    ],
)

# --- dialogue choices ---
upsert(
    root / "dialogue_choices.csv",
    [
        {"id": "dch_dlg_home_divorce_cold", "dialogue_id": "dlg_home_divorce", "after_line_id": "dlg_home_divorce_l05", "sort": "1", "enabled": "1", "notes": "冷退"},
        {"id": "dch_dlg_home_divorce_wait", "dialogue_id": "dlg_home_divorce", "after_line_id": "dlg_home_divorce_l05", "sort": "2", "enabled": "1", "notes": "再忍"},
        {"id": "dch_dlg_home_divorce_weapon", "dialogue_id": "dlg_home_divorce", "after_line_id": "dlg_home_divorce_l05", "sort": "3", "enabled": "1", "notes": "当刀"},
    ],
)

# --- extra dialogue choice effects for parity ---
fn, rows = load(root / "effects.csv")
extra_fx = [
    ("fx_hd_cold_snooze", "dialogue_choice", "dch_dlg_home_divorce_cold", "flag", "divorce_snooze", "set", "0"),
    ("fx_hd_cold_sus_su", "dialogue_choice", "dch_dlg_home_divorce_cold", "relation", "su_qing:player:suspicion", "add", "15"),
    ("fx_hd_wpn_snooze", "dialogue_choice", "dch_dlg_home_divorce_weapon", "flag", "divorce_snooze", "set", "0"),
    ("fx_hd_wpn_trust", "dialogue_choice", "dch_dlg_home_divorce_weapon", "relation", "su_qing:player:trust", "add", "-30"),
    ("fx_hd_wpn_intimacy", "dialogue_choice", "dch_dlg_home_divorce_weapon", "relation", "su_qing:zhou_shaoting:intimacy", "add", "8"),
]
ids = {r["id"] for r in rows}
for cid, ot, oid, et, key, op, val in extra_fx:
    if cid in ids:
        continue
    rows.append(
        {
            "id": cid,
            "owner_type": ot,
            "owner_id": oid,
            "effect_type": et,
            "target": "",
            "key": key,
            "op": op,
            "value": str(val),
            "chance": "1",
            "notes": "divorce",
        }
    )
    print("fx", cid)
save(root / "effects.csv", fn, rows)

# --- variants ---
upsert(
    root / "dialogue_line_variants.csv",
    [
        {"id": "var_su_talk_l01_divorced", "base_line_id": "dlg_su_talk_l01", "priority": "20", "enabled": "1", "notes": "退婚后冷礼"},
        {"id": "var_su_talk_l03_divorced", "base_line_id": "dlg_su_talk_l03", "priority": "20", "enabled": "1", "notes": "退婚后冷"},
        {"id": "var_su_talk_l01_weapon", "base_line_id": "dlg_su_talk_l01", "priority": "25", "enabled": "1", "notes": "武器化惧意"},
        {"id": "var_su_talk_l03_weapon", "base_line_id": "dlg_su_talk_l03", "priority": "25", "enabled": "1", "notes": "武器化惧意"},
        {"id": "var_chen_lobby_l02_divorced", "base_line_id": "dlg_chen_lobby_l02", "priority": "20", "enabled": "1", "notes": "A线讽一人更好下刀"},
        {"id": "var_home_rest_l02_divorced", "base_line_id": "dlg_home_rest_l02", "priority": "20", "enabled": "1", "notes": "C/日常空屋"},
    ],
)

# variant conditions
upsert(
    root / "conditions.csv",
    [
        {"id": "c_var_su_talk_l01_div", "owner_type": "line_variant", "owner_id": "var_su_talk_l01_divorced", "cond_group": "1", "cond_type": "flag", "key": "divorced_su", "op": "eq", "value": "1", "notes": ""},
        {"id": "c_var_su_talk_l01_div_not_wpn", "owner_type": "line_variant", "owner_id": "var_su_talk_l01_divorced", "cond_group": "1", "cond_type": "flag", "key": "divorce_as_weapon", "op": "eq", "value": "0", "notes": ""},
        {"id": "c_var_su_talk_l03_div", "owner_type": "line_variant", "owner_id": "var_su_talk_l03_divorced", "cond_group": "1", "cond_type": "flag", "key": "divorced_su", "op": "eq", "value": "1", "notes": ""},
        {"id": "c_var_su_talk_l03_div_not_wpn", "owner_type": "line_variant", "owner_id": "var_su_talk_l03_divorced", "cond_group": "1", "cond_type": "flag", "key": "divorce_as_weapon", "op": "eq", "value": "0", "notes": ""},
        {"id": "c_var_su_talk_l01_wpn", "owner_type": "line_variant", "owner_id": "var_su_talk_l01_weapon", "cond_group": "1", "cond_type": "flag", "key": "divorce_as_weapon", "op": "eq", "value": "1", "notes": ""},
        {"id": "c_var_su_talk_l03_wpn", "owner_type": "line_variant", "owner_id": "var_su_talk_l03_weapon", "cond_group": "1", "cond_type": "flag", "key": "divorce_as_weapon", "op": "eq", "value": "1", "notes": ""},
        {"id": "c_var_chen_lobby_div", "owner_type": "line_variant", "owner_id": "var_chen_lobby_l02_divorced", "cond_group": "1", "cond_type": "flag", "key": "divorced_su", "op": "eq", "value": "1", "notes": ""},
        {"id": "c_var_home_rest_div", "owner_type": "line_variant", "owner_id": "var_home_rest_l02_divorced", "cond_group": "1", "cond_type": "flag", "key": "divorced_su", "op": "eq", "value": "1", "notes": ""},
        {"id": "c_chatter_divorce_rumor", "owner_type": "idle_chatter", "owner_id": "chatter_divorce_rumor", "cond_group": "1", "cond_type": "flag", "key": "divorced_su", "op": "eq", "value": "1", "notes": ""},
        {"id": "c_chatter_divorce_weapon", "owner_type": "idle_chatter", "owner_id": "chatter_divorce_weapon", "cond_group": "1", "cond_type": "flag", "key": "divorce_as_weapon", "op": "eq", "value": "1", "notes": ""},
    ],
)

# --- idle chatter ---
upsert(
    root / "idle_chatter.csv",
    [
        {
            "id": "chatter_divorce_rumor",
            "location_id": "tea_house",
            "hotspot_id": "",
            "periods": "afternoon|evening",
            "tags": "all",
            "weight": "12",
            "cooldown_days": "2",
            "enabled": "1",
            "notes": "邻里传宏远亲事散了",
        },
        {
            "id": "chatter_divorce_weapon",
            "location_id": "tea_house",
            "hotspot_id": "tea_stage",
            "periods": "any",
            "tags": "B|all",
            "weight": "10",
            "cooldown_days": "2",
            "enabled": "1",
            "notes": "故意散伙闲话",
        },
    ],
)

# --- fix garbled notes on divorce conditions ---
fn, rows = load(root / "conditions.csv")
note_fix = {
    "c_ev_div_u_g1_day": "handkerchief/gifts",
    "c_ev_div_u_g1_trig": "handkerchief/gifts",
    "c_ev_div_u_g2_day": "favor crack",
    "c_ev_div_u_g2_trig": "favor crack",
    "c_ev_div_u_g3_day": "resigned",
    "c_ev_div_u_g3_trig": "resigned",
    "c_ev_div_u_g4_day": "tongyang",
    "c_ev_div_u_g4_trig": "tongyang",
    "c_ev_div_u_g5_day": "may betray",
    "c_ev_div_u_g5_trig": "may betray",
    "c_act_home_guide_not_div": "lock pillow talk after divorce",
    "c_act_home_div_g1_day": "handkerchief/gifts",
    "c_act_home_div_g1_trig": "handkerchief/gifts",
    "c_act_home_div_g2_day": "favor crack",
    "c_act_home_div_g2_trig": "favor crack",
    "c_act_home_div_g3_day": "resigned",
    "c_act_home_div_g3_trig": "resigned",
    "c_act_home_div_g4_day": "tongyang",
    "c_act_home_div_g4_trig": "tongyang",
    "c_act_home_div_g5_day": "may betray",
    "c_act_home_div_g5_trig": "may betray",
}
for r in rows:
    if r["id"] in note_fix:
        r["notes"] = note_fix[r["id"]]
save(root / "conditions.csv", fn, rows)

# --- l10n zh + en ---
zh = {
    "events.ev_divorce_ultimatum.title": "灯油将尽",
    "events.ev_divorce_ultimatum.body": (
        "灯油噼啪一声。屋里只剩你们两个，连夜潮都像贴在窗纸上听。|||"
        "晚晴先开口，又像被你抢了半句：「这门亲事……还能不能算数？」她指尖抠着桌沿，"
        "「纱厂那条路我走过。你若还要把我卷进周家的局——」|||"
        "「霆」字在她喉咙里滚了一下，没落全。空气里仍有那块手帕的余温。|||"
        "这门亲事，今夜要在忍、散、或当刀使里择一。"
    ),
    "events.ev_divorce_ultimatum.body_divorced": "",
    "events.ev_divorce_aftermath.title": "亲事散了",
    "events.ev_divorce_aftermath.body": (
        "茶馆醒木未响，闲话先响：「宏远那单亲事——散了。」有人叹，有人笑。|||"
        "你推开自家门，屋里空了一角：她的针线匣不在原处，灯花却仍记得你们并坐的位置。"
    ),
    "events.ev_divorce_aftermath.body_divorce_weapon": "街角又加一句，压得更低：「他是故意的。散了好推裂缝。」",
    "event_choices.ch_div_cold.label": "冷着退婚：这门亲事到此为止",
    "event_choices.ch_div_wait.label": "再忍一夜：话先咽回去",
    "event_choices.ch_div_weapon.label": "把退婚当刀：让周家也听见裂响",
    "event_choices.ch_div_after_ok.label": "把闲话听完，把门关上",
    "actions.home_propose_divorce.name": "谈散伙／退婚",
    "actions.home_propose_divorce.description": "把门关严，把这门亲事摊到桌面上",
    "actions.home_propose_divorce.result": "灯灭之前，有些话已经不能当没说过。",
    "dialogue_lines.dlg_home_divorce_l01.text": "客厅只剩一盏灯。桌面上空着，像故意留给一句难听的话。",
    "dialogue_lines.dlg_home_divorce_l02.text": "阿海……你今晚看我的眼神，不像要回家歇脚。",
    "dialogue_lines.dlg_home_divorce_l03.text": "晚晴。手帕、少霆、纱厂——我们别再装听不见。",
    "dialogue_lines.dlg_home_divorce_l04.text": "……你要散？还是要我继续替你在周家门口站着，像个挡箭牌？",
    "dialogue_lines.dlg_home_divorce_l05.text": "夜潮拍岸。三扇门在眼前：冷退、再忍、或把散伙写成复仇的刀。",
    "dialogue_choices.dch_dlg_home_divorce_cold.label": "冷着退婚",
    "dialogue_choices.dch_dlg_home_divorce_wait.label": "再忍一夜",
    "dialogue_choices.dch_dlg_home_divorce_weapon.label": "把退婚当刀使",
    "dialogue_line_variants.var_su_talk_l01_divorced.text": "门开了。她仍叫你一声「阿海」，却像客套——屋里只剩礼貌的冷。",
    "dialogue_line_variants.var_su_talk_l03_divorced.text": "少霆？……亲事散了，他更有理由「接手体面」。你还问这个做什么。",
    "dialogue_line_variants.var_su_talk_l01_weapon.text": "她看见你，肩膀微微缩了一下：「你……还回来。是来看我怕不怕？」",
    "dialogue_line_variants.var_su_talk_l03_weapon.text": "我知道你散伙是给周家看的。可被写成棋子的人——也会发抖。",
    "dialogue_line_variants.var_chen_lobby_l02_divorced.text": "陈掌柜笑得更淡：「一个人更好下刀。少了后顾，船期才狠。」",
    "dialogue_line_variants.var_home_rest_l02_divorced.text": "空屋里算账：数字很清楚，人却少了一半。灯花爆开，像嘲你还在算。",
    "idle_chatter.chatter_divorce_rumor.text": "茶博士压低嗓子：「宏远那单亲事散了。码头仔管不住女人——周家少爷倒笑得轻松。」",
    "idle_chatter.chatter_divorce_weapon.text": "有人咬耳朵：「他是故意散的。家里都散了，还装在宏远尽忠？」",
    "events.ev_day7_choice.body_divorced": "家先散了，局还在——站不站队，仍是你自己的刀。",
    "events.ev_b_public_clash.body_divorced": "走廊里有人嘀咕：家里都散了，还在这装什么忠。",
    "events.ev_b_public_clash.body_divorce_weapon": "有人故意抬高嗓门：「家里都散了还装——裂缝可不只在茶杯上。」",
    "events.ev_a_first_strike.body_divorced": "你少了一份后顾。这一刀落下去，只听见自己的呼吸。",
    "events.ev_c_first_short.body_divorced": "平仓时你想起空屋：账上更孤，数字却更听话。",
    "ui.hud.goal.divorce_talk": "今晚或许该回家谈清楚",
    "ui.hud.goal.divorce_talk_tip": "手帕裂痕、好感崩、辞职跳槽之后，客厅可谈散伙／退婚；也可等摊牌夜。",
}

en = {
    "events.ev_divorce_ultimatum.title": "Lamp Oil Running Out",
    "events.ev_divorce_ultimatum.body": (
        "The lamp cracks. Only the two of you left—night tide pressed to the window paper like an ear.|||"
        "Su Qing starts, then yields half a breath: \"This match… can it still count?\" Her nails dig the table edge. "
        "\"I've walked the mill road. If you drag me into the Zhou game—\"|||"
        "The name \"Ting\" rolls in her throat and dies unfinished. Handkerchief warmth still hangs in the air.|||"
        "Tonight the match chooses: endure, break, or become a blade."
    ),
    "events.ev_divorce_aftermath.title": "The Match Is Off",
    "events.ev_divorce_aftermath.body": (
        "Before the tea-house clapper, gossip lands: \"Hongyuan's engagement—called off.\" Sighs and smirks.|||"
        "You open your door. A corner of the room is emptier: her sewing box gone, the lamp still remembering where you sat."
    ),
    "events.ev_divorce_aftermath.body_divorce_weapon": "A lower voice on the corner: \"He meant it. Break it to push the crack.\"",
    "event_choices.ch_div_cold.label": "Cold break: this match ends here",
    "event_choices.ch_div_wait.label": "Endure one more night: swallow the words",
    "event_choices.ch_div_weapon.label": "Wield the break: let the Zhous hear the crack",
    "event_choices.ch_div_after_ok.label": "Hear the gossip out, shut the door",
    "actions.home_propose_divorce.name": "Talk break-off",
    "actions.home_propose_divorce.description": "Close the door. Put the match on the table.",
    "actions.home_propose_divorce.result": "Before the lamp dies, some words can't be unsaid.",
    "dialogue_lines.dlg_home_divorce_l01.text": "One lamp left in the parlor. The table is empty—space for a hard sentence.",
    "dialogue_lines.dlg_home_divorce_l02.text": "A-Hai… the way you look at me tonight isn't for rest.",
    "dialogue_lines.dlg_home_divorce_l03.text": "Qing. The handkerchief. Shao-ting. The mill. Stop pretending we don't hear.",
    "dialogue_lines.dlg_home_divorce_l04.text": "…You want out? Or should I keep standing at Zhou's door like a shield?",
    "dialogue_lines.dlg_home_divorce_l05.text": "Tide hits the quay. Three doors: cold break, endure, or write the break as a revenge blade.",
    "dialogue_choices.dch_dlg_home_divorce_cold.label": "Cold break-off",
    "dialogue_choices.dch_dlg_home_divorce_wait.label": "Endure one more night",
    "dialogue_choices.dch_dlg_home_divorce_weapon.label": "Use the break as a blade",
    "dialogue_line_variants.var_su_talk_l01_divorced.text": "The door opens. She still says \"A-Hai,\" like courtesy—cold politeness fills the house.",
    "dialogue_line_variants.var_su_talk_l03_divorced.text": "Shao-ting? …The match is off; he has more reason to \"take over with dignity.\" Why ask.",
    "dialogue_line_variants.var_su_talk_l01_weapon.text": "She flinches: \"You came back. To see if I'm afraid?\"",
    "dialogue_line_variants.var_su_talk_l03_weapon.text": "I know you broke it for the Zhous to see. Pieces on a board still shake.",
    "dialogue_line_variants.var_chen_lobby_l02_divorced.text": "Manager Chen's smile thins: \"Alone cuts cleaner. Fewer ties, sharper schedules.\"",
    "dialogue_line_variants.var_home_rest_l02_divorced.text": "Empty-house arithmetic: numbers clear, people halved. The lamp pops like a mockery.",
    "idle_chatter.chatter_divorce_rumor.text": "The tea doctor lowers his voice: \"Hongyuan's match is off. Dock boy couldn't hold her—Young Master Zhou laughs easy.\"",
    "idle_chatter.chatter_divorce_weapon.text": "Someone whispers: \"He meant to break it. Home already cracked—still playing loyal at Hongyuan?\"",
    "events.ev_day7_choice.body_divorced": "Home broke first; the game remains—whether you pick a side is still your blade.",
    "events.ev_b_public_clash.body_divorced": "In the corridor someone mutters: home already broken—what's left to pretend.",
    "events.ev_b_public_clash.body_divorce_weapon": "A voice rises on purpose: \"Home already broken and still pretending—the crack isn't only in the teacup.\"",
    "events.ev_a_first_strike.body_divorced": "One less tie behind you. The cut lands with only your breath for witness.",
    "events.ev_c_first_short.body_divorced": "Closing the position, you think of the empty room: lonelier books, obedient numbers.",
    "ui.hud.goal.divorce_talk": "Tonight you may need to talk it out at home",
    "ui.hud.goal.divorce_talk_tip": "After the handkerchief crack, favor collapse, resign/job-hop—parlor can open break-off talk; or wait for the ultimatum night.",
}

upsert_l10n("zh_CN", zh)
upsert_l10n("en", en)

# pack bump
pack_path = root / "pack.json"
pack = json.loads(pack_path.read_text(encoding="utf-8"))
pack["version"] = "0.9.11"
pack["description"] = "Demo 0.9.11：晚晴退婚/散伙线（可选摊牌+主线软挂钩）。"
pack_path.write_text(json.dumps(pack, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("pack ->", pack["version"])
print("phase2 done")
