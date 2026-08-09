# -*- coding: utf-8 -*-
import csv
import json
from pathlib import Path

root = Path(r"f:/Games/New-Life/docs/tables/packs/core")

# fix dialogues once field
p = root / "dialogues.csv"
with p.open(encoding="utf-8-sig", newline="") as f:
    rows = list(csv.DictReader(f))
    fn = list(rows[0].keys())
for r in rows:
    if r["id"] == "dlg_home_divorce":
        r["tags"] = "B|all"
        r["priority"] = "60"
        r["once"] = "0"
        r["enabled"] = "1"
        r["notes"] = "home divorce talk"
with p.open("w", encoding="utf-8-sig", newline="") as f:
    w = csv.DictWriter(f, fieldnames=fn, lineterminator="\n", extrasaction="ignore")
    w.writeheader()
    w.writerows(rows)
print("fixed dialogue")

en = {
    "events.ev_divorce_ultimatum.title": "Lamp Oil Running Out",
    "events.ev_divorce_ultimatum.body": (
        "The lamp cracks. Only the two of you left—night tide pressed to the window paper like an ear.||||"
        "Su Qing starts, then yields half a breath: \"This match… can it still count?\" Her nails dig the table edge. "
        "\"I've walked the mill road. If you drag me into the Zhou game—\"||||"
        "The name \"Ting\" rolls in her throat and dies unfinished. Handkerchief warmth still hangs in the air.||||"
        "Tonight the match chooses: endure, break, or become a blade."
    ).replace("||||", "|||"),
    "events.ev_divorce_aftermath.title": "The Match Is Off",
    "events.ev_divorce_aftermath.body": (
        "Before the tea-house clapper, gossip lands: \"Hongyuan's engagement—called off.\" Sighs and smirks.||||"
        "You open your door. A corner of the room is emptier: her sewing box gone, the lamp still remembering where you sat."
    ).replace("||||", "|||"),
    "events.ev_divorce_aftermath.body_divorce_weapon": (
        "A lower voice on the corner: \"He meant it. Break it to push the crack.\""
    ),
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
    "dialogue_line_variants.var_su_talk_l01_divorced.text": (
        "The door opens. She still says \"A-Hai,\" like courtesy—cold politeness fills the house."
    ),
    "dialogue_line_variants.var_su_talk_l03_divorced.text": (
        "Shao-ting? …The match is off; he has more reason to \"take over with dignity.\" Why ask."
    ),
    "dialogue_line_variants.var_su_talk_l01_weapon.text": "She flinches: \"You came back. To see if I'm afraid?\"",
    "dialogue_line_variants.var_su_talk_l03_weapon.text": (
        "I know you broke it for the Zhous to see. Pieces on a board still shake."
    ),
    "dialogue_line_variants.var_chen_lobby_l02_divorced.text": (
        "Manager Chen's smile thins: \"Alone cuts cleaner. Fewer ties, sharper schedules.\""
    ),
    "dialogue_line_variants.var_home_rest_l02_divorced.text": (
        "Empty-house arithmetic: numbers clear, people halved. The lamp pops like a mockery."
    ),
    "idle_chatter.chatter_divorce_rumor.text": (
        "The tea doctor lowers his voice: \"Hongyuan's match is off. Dock boy couldn't hold her—"
        "Young Master Zhou laughs easy.\""
    ),
    "idle_chatter.chatter_divorce_weapon.text": (
        "Someone whispers: \"He meant to break it. Home already cracked—still playing loyal at Hongyuan?\""
    ),
    "events.ev_day7_choice.body_divorced": (
        "Home broke first; the game remains—whether you pick a side is still your blade."
    ),
    "events.ev_b_public_clash.body_divorced": (
        "In the corridor someone mutters: home already broken—what's left to pretend."
    ),
    "events.ev_b_public_clash.body_divorce_weapon": (
        "A voice rises on purpose: \"Home already broken and still pretending—the crack isn't only in the teacup.\""
    ),
    "events.ev_a_first_strike.body_divorced": (
        "One less tie behind you. The cut lands with only your breath for witness."
    ),
    "events.ev_c_first_short.body_divorced": (
        "Closing the position, you think of the empty room: lonelier books, obedient numbers."
    ),
    "ui.hud.goal.divorce_talk": "Tonight you may need to talk it out at home",
    "ui.hud.goal.divorce_talk_tip": (
        "After the handkerchief crack, favor collapse, resign/job-hop—parlor can open break-off talk; "
        "or wait for the ultimatum night."
    ),
}

p = root / "l10n" / "en.csv"
with p.open(encoding="utf-8-sig", newline="") as f:
    rows = list(csv.reader(f))
header = rows[0]
assert header[:2] == ["key", "text"], header
data = {}
for row in rows[1:]:
    if not row:
        continue
    k = row[0]
    t = row[1] if len(row) > 1 else ""
    if k:
        data[k] = t
data.update(en)
with p.open("w", encoding="utf-8-sig", newline="") as f:
    w = csv.writer(f, lineterminator="\n")
    w.writerow(["key", "text"])
    for k in sorted(data.keys()):
        w.writerow([k, data[k]])
print("en keys", len(data))

# strip empty zh key
p = root / "l10n" / "zh_CN.csv"
with p.open(encoding="utf-8-sig", newline="") as f:
    rows = list(csv.reader(f))
out = [rows[0]]
for row in rows[1:]:
    if row and row[0] == "events.ev_divorce_ultimatum.body_divorced":
        continue
    out.append(row)
with p.open("w", encoding="utf-8-sig", newline="") as f:
    w = csv.writer(f, lineterminator="\n")
    w.writerows(out)
print("cleaned zh")

pack_path = root / "pack.json"
pack = json.loads(pack_path.read_text(encoding="utf-8"))
pack["version"] = "0.9.11"
pack["description"] = "Demo 0.9.11：晚晴退婚/散伙线（可选摊牌+主线软挂钩）。"
pack_path.write_text(json.dumps(pack, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("pack", pack["version"])
