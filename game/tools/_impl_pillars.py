# -*- coding: utf-8 -*-
"""Implement 钱·权·女 thin slice (pack 0.9.12)."""
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
        w = csv.DictWriter(f, fieldnames=fn, lineterminator="\n", extrasaction="ignore")
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
        row = {"key": key, "text": text}
        if key in by:
            rows[by[key]]["text"] = text
            print("l10n~", locale, key)
        else:
            rows.append(row)
            print("l10n+", locale, key)
    save(path, fn, rows)


def add_fx(rows, fn, cid, ot, oid, et, key, op, val, notes="pillars"):
    ids = {r["id"] for r in rows}
    if cid in ids:
        return rows
    row = {k: "" for k in fn}
    row.update(
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
            "notes": notes,
        }
    )
    rows.append(row)
    print("fx", cid)
    return rows


# ---------- FLAGS ----------
upsert(
    root / "flags.csv",
    [
        {"id": "power_flex_done", "default": "0", "tags": "core", "notes": "power corridor flex played"},
        {"id": "su_reconcile_path", "default": "0", "tags": "core", "notes": "求合 path lit"},
        {"id": "su_used_as_tool", "default": "0", "tags": "core", "notes": "利用 path lit"},
        {"id": "su_let_go", "default": "0", "tags": "core", "notes": "放手 path lit"},
        {"id": "su_reconcile_done", "default": "0", "tags": "core", "notes": "ev_su_reconcile played"},
        {"id": "su_let_go_done", "default": "0", "tags": "core", "notes": "ev_su_let_go played"},
    ],
)

# ---------- MONEY: home upgrade standing ----------
fn, rows = load(root / "effects.csv")
for cid, oid, key, val in [
    ("fx_home_2_net", "home_upgrade_2", "network_base", "2"),
    ("fx_home_3_net", "home_upgrade_3", "network_base", "3"),
    ("fx_home_4_elite", "home_upgrade_4", "network_elite", "3"),
]:
    rows = add_fx(rows, fn, cid, "action", oid, "stat", key, "add", val, "home standing")

# ---------- EVENTS ----------
upsert(
    root / "events.csv",
    [
        {
            "id": "ev_power_flex",
            "priority": "92",
            "max_triggers": "1",
            "weight": "100",
            "tags": "all",
            "period": "afternoon",
            "enabled": "1",
            "notes": "晋升后走廊场面碾压",
        },
        {
            "id": "ev_su_reconcile",
            "priority": "88",
            "max_triggers": "1",
            "weight": "100",
            "tags": "B|all",
            "period": "evening",
            "enabled": "1",
            "notes": "求合轻节拍",
        },
        {
            "id": "ev_su_let_go",
            "priority": "87",
            "max_triggers": "1",
            "weight": "100",
            "tags": "B|all",
            "period": "evening",
            "enabled": "1",
            "notes": "放手余波",
        },
    ],
)

upsert(
    root / "event_choices.csv",
    [
        {"id": "ch_power_flex_accept", "event_id": "ev_power_flex", "sort": "1", "enabled": "1", "notes": "收下场面"},
        {"id": "ch_power_flex_press", "event_id": "ev_power_flex", "sort": "2", "enabled": "1", "notes": "拿去压人"},
        {"id": "ch_su_reconcile_ok", "event_id": "ev_su_reconcile", "sort": "1", "enabled": "1", "notes": "求合确认"},
        {"id": "ch_su_let_go_ok", "event_id": "ev_su_let_go", "sort": "1", "enabled": "1", "notes": "放手确认"},
    ],
)

# ---------- CONDITIONS ----------
conds = []

def C(cid, ot, oid, g, ctype, key, op, val, notes=""):
    return {
        "id": cid,
        "owner_type": ot,
        "owner_id": oid,
        "cond_group": str(g),
        "cond_type": ctype,
        "key": key,
        "op": op,
        "value": str(val),
        "notes": notes,
    }


# power flex: group1 manager, group2 ty supervisor
for g, flag in [(1, "claimed_promo_manager"), (2, "claimed_promo_ty_supervisor")]:
    conds += [
        C(f"c_ev_power_flex_g{g}_day", "event", "ev_power_flex", g, "day", "day", "gte", "10", "power flex"),
        C(f"c_ev_power_flex_g{g}_done", "event", "ev_power_flex", g, "flag", "power_flex_done", "eq", "0", ""),
        C(f"c_ev_power_flex_g{g}_flag", "event", "ev_power_flex", g, "flag", flag, "eq", "1", flag),
    ]

# reconcile event
conds += [
    C("c_ev_su_rec_path", "event", "ev_su_reconcile", 1, "flag", "su_reconcile_path", "eq", "1", ""),
    C("c_ev_su_rec_done", "event", "ev_su_reconcile", 1, "flag", "su_reconcile_done", "eq", "0", ""),
    C("c_ev_su_rec_day", "event", "ev_su_reconcile", 1, "day", "day", "gte", "6", ""),
    C("c_ev_su_rec_not_tool", "event", "ev_su_reconcile", 1, "flag", "su_used_as_tool", "eq", "0", "利用优先不抢求合演出"),
]

# let go event
conds += [
    C("c_ev_su_lg_flag", "event", "ev_su_let_go", 1, "flag", "su_let_go", "eq", "1", ""),
    C("c_ev_su_lg_done", "event", "ev_su_let_go", 1, "flag", "su_let_go_done", "eq", "0", ""),
    C("c_ev_su_lg_day", "event", "ev_su_let_go", 1, "day", "day", "gte", "6", ""),
]

# office variant
conds += [
    C("c_var_su_office_promo", "line_variant", "var_su_office_l01_promo", 1, "flag", "claimed_promo_manager", "eq", "1", ""),
    C("c_var_su_office_promo_nd", "line_variant", "var_su_office_l01_promo", 1, "flag", "divorced_su", "eq", "0", ""),
]

# talk variants
conds += [
    C("c_var_su_talk_tool_l01", "line_variant", "var_su_talk_l01_tool", 1, "flag", "su_used_as_tool", "eq", "1", ""),
    C("c_var_su_talk_tool_l03", "line_variant", "var_su_talk_l03_tool", 1, "flag", "su_used_as_tool", "eq", "1", ""),
    C("c_var_su_talk_rec_l01", "line_variant", "var_su_talk_l01_reconcile", 1, "flag", "su_reconcile_path", "eq", "1", ""),
    C("c_var_su_talk_rec_l01_nt", "line_variant", "var_su_talk_l01_reconcile", 1, "flag", "su_used_as_tool", "eq", "0", ""),
    C("c_var_su_talk_rec_l03", "line_variant", "var_su_talk_l03_reconcile", 1, "flag", "su_reconcile_path", "eq", "1", ""),
    C("c_var_su_talk_rec_l03_nt", "line_variant", "var_su_talk_l03_reconcile", 1, "flag", "su_used_as_tool", "eq", "0", ""),
    C("c_var_su_talk_lg_l01", "line_variant", "var_su_talk_l01_let_go", 1, "flag", "su_let_go", "eq", "1", ""),
    C("c_var_su_talk_lg_l01_nt", "line_variant", "var_su_talk_l01_let_go", 1, "flag", "su_used_as_tool", "eq", "0", ""),
]

# chatter
conds += [
    C("c_chatter_su_tool", "idle_chatter", "chatter_su_used_tool", 1, "flag", "su_used_as_tool", "eq", "1", ""),
]

# home talk let-go choice
conds += [
    C("c_dch_su_let_go_favor", "dialogue_choice", "dch_dlg_su_talk_let_go", 1, "relation", "su_qing:player:favor", "lte", "45", ""),
    C("c_dch_su_let_go_weapon", "dialogue_choice", "dch_dlg_su_talk_let_go", 1, "flag", "divorce_as_weapon", "eq", "0", ""),
    C("c_dch_su_let_go_once", "dialogue_choice", "dch_dlg_su_talk_let_go", 1, "flag", "su_let_go", "eq", "0", ""),
]

upsert(root / "conditions.csv", conds)

# ---------- EVENT / CHOICE EFFECTS ----------
# power flex accept
for cid, ot, oid, et, key, op, val in [
    ("fx_power_flex_acc_done", "choice", "ch_power_flex_accept", "flag", "power_flex_done", "set", "1"),
    ("fx_power_flex_acc_net", "choice", "ch_power_flex_accept", "stat", "network_base", "add", "4"),
    ("fx_power_flex_acc_trust", "choice", "ch_power_flex_accept", "stat", "trust", "add", "3"),
    ("fx_power_flex_acc_ty", "choice", "ch_power_flex_accept", "stat", "tongyang_trust", "add", "2"),
    ("fx_power_flex_prs_done", "choice", "ch_power_flex_press", "flag", "power_flex_done", "set", "1"),
    ("fx_power_flex_prs_ten", "choice", "ch_power_flex_press", "stat", "father_son_tension", "add", "6"),
    ("fx_power_flex_prs_sus", "choice", "ch_power_flex_press", "stat", "suspicion", "add", "3"),
    ("fx_power_flex_prs_intel", "choice", "ch_power_flex_press", "stat", "intel", "add", "2"),
    ("fx_power_flex_prs_fav", "choice", "ch_power_flex_press", "relation", "su_qing:player:favor", "add", "-4"),
    ("fx_power_flex_prs_ssus", "choice", "ch_power_flex_press", "relation", "su_qing:player:suspicion", "add", "4"),
    # reconcile event
    ("fx_su_rec_done", "choice", "ch_su_reconcile_ok", "flag", "su_reconcile_done", "set", "1"),
    ("fx_su_rec_favor", "choice", "ch_su_reconcile_ok", "relation", "su_qing:player:favor", "add", "12"),
    ("fx_su_rec_trust", "choice", "ch_su_reconcile_ok", "relation", "su_qing:player:trust", "add", "8"),
    ("fx_su_rec_sus", "choice", "ch_su_reconcile_ok", "relation", "su_qing:player:suspicion", "add", "-5"),
    # let go event
    ("fx_su_lg_done", "choice", "ch_su_let_go_ok", "flag", "su_let_go_done", "set", "1"),
    ("fx_su_lg_fav", "choice", "ch_su_let_go_ok", "relation", "su_qing:player:favor", "add", "-6"),
    ("fx_su_lg_net", "choice", "ch_su_let_go_ok", "stat", "network_base", "add", "1"),
]:
    rows = add_fx(rows, fn, cid, ot, oid, et, key, op, val)

# light path flags on existing choices
for cid, ot, oid, flag in [
    ("fx_flag_su_rec_mend", "choice", "ch_ev_flag_su_betray_mend", "su_reconcile_path"),
    ("fx_flag_su_rec_comfort", "choice", "ch_ev_b_d19_su_afraid_comfort", "su_reconcile_path"),
    ("fx_flag_su_rec_soft", "dialogue_choice", "dch_dlg_su_talk_soft", "su_reconcile_path"),
    ("fx_flag_su_tool_scheme", "dialogue_choice", "dch_dlg_su_talk_scheme", "su_used_as_tool"),
    ("fx_flag_su_tool_guide_ok", "dialogue_choice", "dch_dlg_su_guide_ok", "su_used_as_tool"),
    ("fx_flag_su_tool_guide_cold", "dialogue_choice", "dch_dlg_su_guide_cold", "su_used_as_tool"),
    ("fx_flag_su_tool_afraid_use", "choice", "ch_ev_b_d19_su_afraid_use", "su_used_as_tool"),
    ("fx_flag_su_tool_weapon", "choice", "ch_div_weapon", "su_used_as_tool"),
    ("fx_flag_su_tool_hd_weapon", "dialogue_choice", "dch_dlg_home_divorce_weapon", "su_used_as_tool"),
    ("fx_flag_su_lg_cold", "choice", "ch_div_cold", "su_let_go"),
    ("fx_flag_su_lg_hd_cold", "dialogue_choice", "dch_dlg_home_divorce_cold", "su_let_go"),
    ("fx_flag_su_lg_push", "choice", "ch_ev_flag_su_betray_push", "su_let_go"),
    ("fx_flag_su_lg_talk", "dialogue_choice", "dch_dlg_su_talk_let_go", "su_let_go"),
]:
    rows = add_fx(rows, fn, cid, ot, oid, "flag", flag, "set", "1", "arc flag")

# let go talk also soft favor drop
rows = add_fx(
    rows, fn, "fx_dch_su_let_go_favor", "dialogue_choice", "dch_dlg_su_talk_let_go",
    "relation", "su_qing:player:favor", "add", "-8", "let go"
)
rows = add_fx(
    rows, fn, "fx_dch_su_let_go_trust", "dialogue_choice", "dch_dlg_su_talk_let_go",
    "relation", "su_qing:player:trust", "add", "-4", "let go"
)

save(root / "effects.csv", fn, rows)

# ---------- DIALOGUE CHOICE let go ----------
upsert(
    root / "dialogue_choices.csv",
    [
        {
            "id": "dch_dlg_su_talk_let_go",
            "dialogue_id": "dlg_su_talk",
            "after_line_id": "dlg_su_talk_l04",
            "sort": "4",
            "enabled": "1",
            "notes": "放手",
        }
    ],
)

# ---------- VARIANTS ----------
upsert(
    root / "dialogue_line_variants.csv",
    [
        {"id": "var_su_office_l01_promo", "base_line_id": "dlg_su_office_l01", "priority": "20", "enabled": "1", "notes": "经理名分碾压"},
        {"id": "var_su_talk_l01_tool", "base_line_id": "dlg_su_talk_l01", "priority": "30", "enabled": "1", "notes": "利用"},
        {"id": "var_su_talk_l03_tool", "base_line_id": "dlg_su_talk_l03", "priority": "30", "enabled": "1", "notes": "利用"},
        {"id": "var_su_talk_l01_reconcile", "base_line_id": "dlg_su_talk_l01", "priority": "22", "enabled": "1", "notes": "求合"},
        {"id": "var_su_talk_l03_reconcile", "base_line_id": "dlg_su_talk_l03", "priority": "22", "enabled": "1", "notes": "求合"},
        {"id": "var_su_talk_l01_let_go", "base_line_id": "dlg_su_talk_l01", "priority": "21", "enabled": "1", "notes": "放手"},
    ],
)

# ---------- IDLE CHATTER ----------
upsert(
    root / "idle_chatter.csv",
    [
        {
            "id": "chatter_su_used_tool",
            "location_id": "tea_house",
            "hotspot_id": "",
            "periods": "afternoon|evening",
            "tags": "B|all",
            "weight": "11",
            "cooldown_days": "2",
            "enabled": "1",
            "notes": "他拿女人推裂缝",
        }
    ],
)

# ---------- L10N ----------
zh = {
    "actions.home_upgrade_2.result": "墙白了。巷口有人多看一眼——门楣开始值钱。",
    "actions.home_upgrade_3.result": "客厅像样了。街坊话音轻了半分，人脉跟着门面走。",
    "actions.home_upgrade_4.result": "门楣一换，话音都轻了。上层圈子也听见这扇门响。",
    "tip.home_upgrade": "自宅「宅基包工」可升级房产：出租屋→小居→雅寓→洋房。升级不只好看——会涨街坊声望/上层声望，是花钱买场面。",
    "tip.money_ways": "赚钱：码头搬货/晚班/跑腿；广场帮摊、卖货。钱够了去宅基撑门面、车行买车、茶馆敬酒——场面也能买。交易所与通洋是中后期。",
    "ui.hud.goal.face": "有钱了，去宅基撑场面",
    "ui.hud.goal.face_tip": "钱≥120 且房子还能升时：回家→宅基包工。升级涨声望，比干囤钱更有脸。",
    "events.ev_power_flex.title": "走廊让路",
    "events.ev_power_flex.body": (
        "下午的走廊比往常亮。有人侧身，有人把文件挪到胸前——像忽然认出你胸前的名分。||||"
        "转角处，少霆的目光顿了半拍，又若无其事地移开。||||"
        "侧廊里有一声极轻的吸气。是晚晴，或只是你听成了她。"
    ).replace("||||", "|||"),
    "event_choices.ch_power_flex_accept.label": "收下场面：点头走过",
    "event_choices.ch_power_flex_press.label": "拿去压人：让他们记住谁先让路",
    "events.ev_su_reconcile.title": "灯下松一点",
    "events.ev_su_reconcile.body": (
        "夜里她把针线匣又挪回桌角。不是复合的誓言——只是人不那么绷。||||"
        "「阿海……若你还肯把我当家里人，我便少听一些外面的话。」||||"
        "灯油安静。求合不是登记，是先把手收回来。"
    ).replace("||||", "|||"),
    "events.ev_su_reconcile.body_divorced": "亲事已散。她只说：客套共处也行——别再拿我当刀。",
    "event_choices.ch_su_reconcile_ok.label": "点头：先把人拉稳",
    "events.ev_su_let_go.title": "收针线",
    "events.ev_su_let_go.body": (
        "空屋里只剩灯花。她的针线匣合上，像一句说完的话。||||"
        "放手不是恨到尽头，是不再推她进局。人已放，局还在——那是你自己的事。"
    ).replace("||||", "|||"),
    "event_choices.ch_su_let_go_ok.label": "把门关严，不再问",
    "dialogue_choices.dch_dlg_su_talk_let_go.label": "放手：别再把你卷进局里",
    "dialogue_line_variants.var_su_office_l01_promo.text": (
        "副理办公室的门半敞。晚晴抱着文件出来，目光在你胸口的名分上停了一息：「……经理。」像第一次认真叫这个称呼。"
    ),
    "dialogue_line_variants.var_su_talk_l01_tool.text": (
        "门开了。她看见你，先看门口有没有别人——像棋子在核对自己是否该出场。"
    ),
    "dialogue_line_variants.var_su_talk_l03_tool.text": (
        "父子的缝？我递过话。你满意了吗——还是还要把我再推进一寸。"
    ),
    "dialogue_line_variants.var_su_talk_l01_reconcile.text": (
        "她给你留了灯。声音软一点：「回来就好。我们……还能慢慢说。」"
    ),
    "dialogue_line_variants.var_su_talk_l03_reconcile.text": (
        "少霆那边我少回了。你若真想把家稳住，我就少站在裂缝边上。"
    ),
    "dialogue_line_variants.var_su_talk_l01_let_go.text": (
        "屋里很静。她点头如客：「你放手了。也好。别再叫我替你递刀。」"
    ),
    "idle_chatter.chatter_su_used_tool.text": (
        "茶博士咬耳朵：「那码头仔拿女人推周家裂缝——亲事是棋，人也是棋。」"
    ),
    "events.ev_b_public_clash.body_reconcile": "有人却说：家里还没散尽——他仍护着那盏灯。",
    "events.ev_day7_choice.body_let_go": "人已放，局还在——站不站队，只剩你自己的刀。",
    "events.ev_power_flex.body_divorced": "侧廊空着。亲事散了，让路的目光却更干净——少了一份后顾。",
}

en = {
    "actions.home_upgrade_2.result": "Walls whitened. A neighbor looks twice—the doorway starts to cost standing.",
    "actions.home_upgrade_3.result": "The parlor looks real. Voices soften; standing follows the facade.",
    "actions.home_upgrade_4.result": "New lintel, quieter talk. Even elite circles hear this door.",
    "tip.home_upgrade": (
        "Home contractor upgrades: rental → painted flat → street suite → harbor villa. "
        "Not just looks—raises street/elite standing. Spend cash for face."
    ),
    "tip.money_ways": (
        "Earn: dock haul/overtime/errands; plaza stall work. With cash, upgrade home, buy a ride, toast at the tea house—face can be bought. Exchange and Tongyang come later."
    ),
    "ui.hud.goal.face": "Cash in hand—upgrade home for face",
    "ui.hud.goal.face_tip": "Money≥120 and home can still rise: Home → contractor. Upgrades buy standing, not just walls.",
    "events.ev_power_flex.title": "Corridor Clears",
    "events.ev_power_flex.body": (
        "Afternoon corridor brighter. Someone sidesteps; someone hugs papers to the chest—as if your title just arrived.||||"
        "At the turn, Shao-ting's eyes hitch half a beat, then slide away.||||"
        "A soft intake from the side hall. Su Qing—or you hearing her into it."
    ).replace("||||", "|||"),
    "event_choices.ch_power_flex_accept.label": "Take the face: nod and pass",
    "event_choices.ch_power_flex_press.label": "Press it: make them remember who yielded",
    "events.ev_su_reconcile.title": "Loosen Under the Lamp",
    "events.ev_su_reconcile.body": (
        "At night she moves the sewing box back to the table corner. Not a vow—just less strain.||||"
        "\"A-Hai… if you still count me as home, I'll listen less to the street.\"||||"
        "Lamp oil quiet. Reconcile isn't registry—it's pulling your hand back first."
    ).replace("||||", "|||"),
    "events.ev_su_reconcile.body_divorced": (
        "The match is already off. She only says: courtesy coexistence is fine—don't use me as a blade."
    ),
    "event_choices.ch_su_reconcile_ok.label": "Nod: steady the person first",
    "events.ev_su_let_go.title": "Closing the Sewing Box",
    "events.ev_su_let_go.body": (
        "Empty room, lamp spark. Her sewing box shuts like a finished sentence.||||"
        "Letting go isn't the end of hate—it's stopping the push into the game. Person released; board remains—that is yours alone."
    ).replace("||||", "|||"),
    "event_choices.ch_su_let_go_ok.label": "Shut the door. Ask no more.",
    "dialogue_choices.dch_dlg_su_talk_let_go.label": "Let go: keep you out of the game",
    "dialogue_line_variants.var_su_office_l01_promo.text": (
        "VP office door ajar. Su Qing with files; her eyes rest on your title a breath: \"…Manager.\" First time she means it."
    ),
    "dialogue_line_variants.var_su_talk_l01_tool.text": (
        "Door opens. She checks the hall before looking at you—a piece verifying it's her cue."
    ),
    "dialogue_line_variants.var_su_talk_l03_tool.text": (
        "Father-son crack? I passed word. Satisfied—or pushing me one inch more?"
    ),
    "dialogue_line_variants.var_su_talk_l01_reconcile.text": (
        "She left the lamp on. Softer: \"Good you're back. We can… talk slow.\""
    ),
    "dialogue_line_variants.var_su_talk_l03_reconcile.text": (
        "I answer Shao-ting less. If you want the house steady, I'll stand farther from the crack."
    ),
    "dialogue_line_variants.var_su_talk_l01_let_go.text": (
        "Quiet room. A guest's nod: \"You let go. Good. Don't ask me to pass blades.\""
    ),
    "idle_chatter.chatter_su_used_tool.text": (
        "Tea doctor whispers: \"That dock boy uses a woman to push Zhou cracks—match and person both pieces.\""
    ),
    "events.ev_b_public_clash.body_reconcile": (
        "Someone mutters: home hasn't fully broken—he still guards that lamp."
    ),
    "events.ev_day7_choice.body_let_go": (
        "Person released; board remains—picking a side is only your blade now."
    ),
    "events.ev_power_flex.body_divorced": (
        "Side hall empty. Match off; the yielding looks cleaner—one less tie behind you."
    ),
}

upsert_l10n("zh_CN", zh)
upsert_l10n("en", en)

pack_path = root / "pack.json"
pack = json.loads(pack_path.read_text(encoding="utf-8"))
pack["version"] = "0.9.12"
pack["description"] = "Demo 0.9.12：钱买场面 + 权走廊碾压 + 晚晴求合/利用/放手短弧。"
pack_path.write_text(json.dumps(pack, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("pack", pack["version"])
print("done")
