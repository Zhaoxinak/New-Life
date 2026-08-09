# -*- coding: utf-8 -*-
"""Restore EN strings lost when en.csv was reset; translate from zh for freedom/HUD keys."""
import csv
from pathlib import Path

root = Path(r"f:/Games/New-Life/docs/tables/packs/core/l10n")

# Hand EN for keys that code/HUD depends on (not auto-garbled).
HAND = {
    "actions.co_ask_promotion.name": "Ask for promotion",
    "actions.co_ask_promotion.description": "When ready, ask for a title you can say aloud. Check the dossier promotion bar.",
    "actions.co_ask_promotion.result": "You put the request on the desk. Whether it sticks depends on the ledger.",
    "actions.co_resign.name": "Resign from Hongyuan",
    "actions.co_resign.description": "Walk away from Hongyuan. Work and docks stay open; the Zhou game does not force you.",
    "actions.co_resign.result": "The badge is gone. The harbor still needs hands.",
    "actions.rival_ask_promotion.name": "Ask Tongyang for promotion",
    "actions.rival_ask_promotion.description": "Ask Manager Chen for a louder title inside Tongyang.",
    "actions.rival_ask_promotion.result": "Chen weighs you like a schedule sheet.",
    "actions.rival_work.name": "Tongyang office work",
    "actions.rival_work.description": "Do the day job at Tongyang—trust and schedule muscle.",
    "actions.rival_work.result": "Ink, stamps, and another notch on Tongyang's trust.",
    "actions.co_memo_run.name": "Run the memo",
    "actions.co_memo_run.description": "Carry papers across floors. Safe trust work.",
    "actions.co_memo_run.result": "The memo lands. Someone notes you were useful.",
    "dialogue_choices.dch_dlg_co_resign_ok.label": "Hand in the badge. Leave Hongyuan.",
    "dialogue_choices.dch_dlg_co_resign_cancel.label": "Not today. Keep the badge.",
    "dialogue_lines.dlg_co_resign_l01.text": "The corridor smells of tea and coal. Your Hongyuan badge feels heavier than usual.",
    "dialogue_lines.dlg_co_resign_l02.text": "Leave, and the Zhous stop being your employers—not your enemies, not your fate.",
    "dialogue_lines.dlg_co_resign_l03.text": "The clerk waits with a brush. One word ends the wage; the harbor does not.",
    "stats.tongyang_trust.name": "Tongyang trust",
    "stats.tongyang_trust.description": "How far Tongyang will let you into real work.",
    "rank_tracks.tongyang_career.name": "Tongyang career",
    "rank_tracks.tongyang_career.description": "Clerk → supervisor → core.",
    "ranks.ty_clerk.name": "Tongyang clerk",
    "ranks.ty_clerk.can_access_note": "Front desk and routine papers.",
    "ranks.ty_supervisor.name": "Tongyang supervisor",
    "ranks.ty_supervisor.can_access_note": "Can push schedules and junior clerks.",
    "ranks.ty_core.name": "Tongyang core",
    "ranks.ty_core.can_access_note": "Inside the real board.",
    "flags.resigned_hongyuan.description": "Voluntarily left Hongyuan.",
    "flags.hongyuan_fired.description": "Fired from Hongyuan (unemployed, not an ending).",
    "flags.did_tongyang_poach.description": "Ran a Tongyang poach plot once.",
    "flags.claimed_promo_manager.description": "Claimed Hongyuan manager title.",
    "flags.claimed_promo_inner.description": "Claimed Hongyuan inner-circle title.",
    "flags.claimed_promo_ty_supervisor.description": "Claimed Tongyang supervisor title.",
    "flags.claimed_promo_ty_core.description": "Claimed Tongyang core title.",
    "ui.employer.hongyuan": "Hongyuan",
    "ui.employer.none": "Unemployed",
    "ui.employer.tongyang": "Tongyang",
    "ui.dossier.faction_tongyang": "Tongyang",
    "ui.dossier.faction_hongyuan": "Hongyuan",
    "ui.dossier.section_promo": "Promotion",
    "ui.dossier.next_rank": "Next rank",
    "ui.hud.goal.ask_hy": "Ask for promotion in the boss's office",
    "ui.hud.goal.ask_ty": "Ask for promotion in the Tongyang office",
    "ui.hud.goal.ask_tip": "Dossier promotion checks are green. Use Ask for promotion in the matching office.",
    "ui.hud.goal.boss_door": "Earn a bit more trust to enter the boss's office",
    "ui.hud.goal.boss_door_tip": "Company office work and boss tasks raise trust. Open the dossier for promotion progress.",
    "ui.hud.goal.cool": "Heat is high—go home and cool off",
    "ui.hud.goal.cool_tip": "When suspicion is high, skip eavesdropping/theft. Rest at home.",
    "ui.hud.goal.fame": "For Tongyang: build standing first",
    "ui.hud.goal.fame_tip": "Tongyang contact wants standing ~20. Details in the dossier.",
    "ui.hud.goal.fame_ty": "To join Tongyang: build elite standing",
    "ui.hud.goal.fame_ty_tip": "Tongyang contact wants standing ~20. Tea house, intel sales, network events help.",
    "ui.hud.goal.free": "Free play: work, meet people, or push the crack",
    "ui.hud.goal.free_tip": "No urgent gate. Promote, earn, or follow the optional main quest.",
    "ui.hud.goal.intel": "Thin intel—eavesdrop or chat at the dock",
    "ui.hud.goal.intel_tip": "Intel fuels rumors, poaching, plots. Office eavesdrop, dock chat, plaza tips.",
    "ui.hud.goal.jobless": "Dock work to survive, or wait for Tongyang",
    "ui.hud.goal.jobless_tip": "Unemployed: no Hongyuan office actions. Dock labor keeps you alive; Tongyang opens day 7 (earlier if you resign).",
    "ui.hud.goal.money": "Earn at the dock or plaza first",
    "ui.hud.goal.money_tip": "Low cash tightens the day. Haul, overtime, help the stall.",
    "ui.hud.goal.promo": "Do more office work toward “{rank}”",
    "ui.hud.goal.promo_tip": "Open the dossier for checkboxes. Hongyuan: office/boss tasks; Tongyang: Tongyang office/intel.",
    "ui.hud.goal.ty_accept": "Tongyang lobby: accept the job and start work",
    "ui.hud.goal.ty_accept_tip": "Qualified. Enter Tongyang → lobby → Accept Tongyang job. Then Tongyang office work unlocks.",
    "ui.hud.goal.ty_apply": "See Manager Chen in the Tongyang lobby",
    "ui.hud.goal.ty_apply_tip": "Resign/fire opens Tongyang early. Lobby Ask about hiring → qualify → Accept job → office work.",
    "ui.hud.next_line": "Next: %s",
    "ui.hud.firm_line": "Firm: %s",
    "ui.hud.heat_line": "Heat: %s",
    "ui.hud.unemployed": "Unemployed",
    "ui.hud.firm_jobless": "No badge",
    "ui.hud.firm_jobless_tip": "No employer. Dock or Tongyang.",
    "ui.hud.firm_hy_low": "Just standing",
    "ui.hud.firm_hy_fore": "Voice in the crew",
    "ui.hud.firm_hy_chief": "Useful enough",
    "ui.hud.firm_hy_mgr": "Near manager",
    "ui.hud.firm_hy_inner": "Near the inner ring",
    "ui.hud.firm_ty_new": "Still new",
    "ui.hud.firm_ty_mid": "Being used",
    "ui.hud.firm_ty_core": "Near the core",
    "ui.hud.heat_safe": "Quiet",
    "ui.hud.heat_watch": "Watched",
    "ui.hud.heat_hot": "Hot",
    "ui.hud.heat_fire": "At the door",
    "ui.promo.title": "Promotion",
    "ui.promo.ready_line": "Ready to ask",
    "ui.promo.not_ready": "Not yet",
    "ui.promo.hint_ready": "Go to the matching office and ask.",
    "ui.promo.unemployed_hint": "Need an employer first.",
    "ui.promo.wrong_ask": "Wrong office for this track.",
}

zh = {r["key"]: r["text"] for r in csv.DictReader(open(root / "zh_CN.csv", encoding="utf-8-sig"))}
rows = list(csv.DictReader(open(root / "en.csv", encoding="utf-8-sig")))
by = {r["key"]: i for i, r in enumerate(rows)}

added = 0
for k, t in HAND.items():
    if k not in zh:
        continue
    if k in by:
        rows[by[k]] = {"key": k, "text": t}
    else:
        rows.append({"key": k, "text": t})
        by[k] = len(rows) - 1
        added += 1
        print("add", k)

with (root / "en.csv").open("w", encoding="utf-8-sig", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["key", "text"], lineterminator="\n", extrasaction="ignore")
    w.writeheader()
    w.writerows(rows)
print("added", added, "total", len(rows))
