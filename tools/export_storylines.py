# -*- coding: utf-8 -*-
"""Export early-game narrative lines by storyline for human review."""
from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / "docs" / "tables" / "packs" / "core"
L10N = PACK / "l10n" / "zh_CN.csv"
OUT = ROOT / "docs" / "exports" / "storylines_review.md"

LINES: dict[str, list[str]] = {
    "开场 / Day1": [
        "ui.prologue.body",
        "events.ev_day1_intro.title",
        "events.ev_day1_intro.body",
        "event_choices.ch_intro_ok.label",
    ],
    "码头日常": [
        "actions.dock_work.name",
        "actions.dock_work.result",
        "dialogue_lines.dlg_dock_work_l01.text",
        "dialogue_lines.dlg_dock_work_l02.text",
        "dialogue_lines.dlg_dock_work_l03.text",
        "actions.dock_chat.result",
        "actions.dock_watch_manifest.result",
        "dialogue_lines.dlg_dock_manifest_l03.text",
    ],
    "出租屋": [
        "actions.home_organize.result",
        "dialogue_lines.dlg_home_organize_l02.text",
        "actions.home_plan.result",
        "dialogue_lines.dlg_home_plan_l01.text",
        "dialogue_lines.dlg_home_plan_l02.text",
        "dialogue_lines.dlg_home_plan_l03.text",
        "dialogue_lines.dlg_home_rest_l01.text",
        "idle_chatter.chatter_home_01.text",
    ],
    "公司 / 少霆 / 晚晴": [
        "actions.co_work.result",
        "dialogue_lines.dlg_co_work_l02.text",
        "dialogue_lines.dlg_co_work_l03.text",
        "actions.co_eavesdrop.result",
        "dialogue_lines.dlg_co_eavesdrop_l03.text",
        "actions.co_meet_su.result",
        "actions.co_meet_son.result",
        "actions.co_pass_rumor.description",
        "dialogue_lines.dlg_son_rumor_l01.text",
        "dialogue_lines.dlg_su_guide_l01.text",
    ],
    "Day4–7 主线节点": [
        "events.ev_d4_salary.body",
        "events.ev_day3_son_notice.body",
        "events.ev_day5_promotion_stolen.body",
        "events.ev_day6_su_distance.body",
        "events.ev_day7_choice.body",
        "event_choices.ch_d7_finance.label",
        "events.ev_flag_su_gifts.title",
        "events.ev_flag_su_gifts.body",
        "event_choices.ch_ev_flag_su_gifts_confront.label",
        "event_choices.ch_ev_flag_su_gifts_use.label",
    ],
}


def load_l10n() -> dict[str, str]:
    rows: dict[str, str] = {}
    with L10N.open(encoding="utf-8-sig", newline="") as f:
        for row in csv.DictReader(f):
            key = (row.get("key") or "").strip()
            if key:
                rows[key] = (row.get("text") or "").strip()
    return rows


def main() -> None:
    strings = load_l10n()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    lines: list[str] = [
        "# 码头风云 · 早期剧情文案审阅包",
        "",
        "> 自动导出自 `docs/tables/packs/core/l10n/zh_CN.csv`",
        "> 按线分组，便于朋友按规矩改，不要整包糊成一团。",
        "",
        "## 规矩（给审稿人）",
        "",
        "1. 一句一事，少用抽象隐喻（刀/钉/潮+野心）。",
        "2. 人名场景要能对上：少霆、晚晴、宏远、码头。",
        "3. `|||` 是分段，保留；缺段不要空着糊弄。",
        "4. 改完回传时请保留左侧 **key**。",
        "",
    ]
    missing = 0
    for section, keys in LINES.items():
        lines.append(f"## {section}")
        lines.append("")
        for key in keys:
            text = strings.get(key)
            if text is None:
                missing += 1
                lines.append(f"- `{key}`: _(缺失)_")
            else:
                shown = text.replace("|||", "\n  - ")
                lines.append(f"- `{key}`:")
                lines.append(f"  - {shown}")
        lines.append("")
    lines.append(f"_缺失 key 数：{missing}_")
    lines.append("")
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT} ({missing} missing keys)")


if __name__ == "__main__":
    main()
