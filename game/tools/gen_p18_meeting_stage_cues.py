# -*- coding: utf-8 -*-
"""P18: 朝账对话补 set_meeting_segment + stage cues + 旁听关键字。"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "packs" / "anchao"

# dialog_id 前缀/子串 → segment
SEGMENT_RULES: list[tuple[str, str]] = [
    ("_rollcall", "rollcall"),
    ("_zhou_order", "rollcall"),
    ("_zhou_rollcall", "rollcall"),
    ("_start", "rollcall"),
    ("_enter_hall", "rollcall"),
    ("_ladder", "report"),
    ("_report", "report"),
    ("_after_report", "report"),
    ("_player_report", "report"),
    ("_player_named", "report"),
    ("_demao_comment", "report"),
    ("_paojie_echo", "report"),
    ("_manshi_hint", "report"),
    ("_council", "council"),
    ("dialog_council_", "council"),
    ("dialog_meeting_council_", "council"),
    ("_policy", "policy"),
    ("dialog_meeting_policy_", "policy"),
    ("_task", "tasks"),
    ("_close", "tasks"),
]

LISTEN_KEYWORD_IDS = {
    "dialog_m001_start",
    "dialog_m001_rollcall",
    "dialog_m001_paojie_echo",
    "dialog_m001_manshi_hint",
    "dialog_m001_council_zhou",
    "dialog_m001_council_wang_pass",
    "dialog_m002_player_named",
    "dialog_m002_ladder_read",
    "dialog_m000_council_listen",
    "dialog_m000_council_listen_wang",
}

DEFAULT_KEYWORDS = ["跑街", "满师", "特别货", "货单", "聚丰", "外场", "学徒", "后院", "差事"]


def load(name: str):
    return json.loads((ROOT / name).read_text(encoding="utf-8"))


def save(name: str, data) -> None:
    (ROOT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("updated", name)


def infer_segment(dialog_id: str) -> str:
    did = dialog_id.lower()
    if not (
        did.startswith("dialog_m")
        or did.startswith("dialog_meeting")
        or did.startswith("dialog_council")
    ):
        return ""
    # 更具体的规则优先（列表顺序已大致从具体到一般）
    for needle, seg in SEGMENT_RULES:
        if needle in did:
            return seg
    return ""


def ensure_seg_effect(effects: list, segment: str) -> list:
    out = []
    found = False
    for fx in effects:
        if isinstance(fx, dict) and fx.get("op") == "set_meeting_segment":
            if not found:
                out.append({"op": "set_meeting_segment", "value": segment})
                found = True
            # drop duplicates
            continue
        out.append(fx)
    if not found:
        out.insert(0, {"op": "set_meeting_segment", "value": segment})
    return out


def main() -> None:
    data = load("def_dialog.json")
    rows = data["rows"]
    patched = 0
    for row in rows:
        did = str(row.get("dialog_id", ""))
        seg = infer_segment(did)
        if not seg:
            continue
        tags = list(row.get("tags", []) or [])
        if "meeting" not in tags and (
            did.startswith("dialog_m") or did.startswith("dialog_meeting") or did.startswith("dialog_council")
        ):
            tags.append("meeting")
        seg_tag = f"seg_{seg}"
        if seg_tag not in tags:
            tags.append(seg_tag)
        if seg == "council" and "council" not in tags:
            tags.append("council")
        if did in LISTEN_KEYWORD_IDS and "keyword_highlight" not in tags:
            tags.append("keyword_highlight")
        row["tags"] = tags

        stage = row.get("stage") if isinstance(row.get("stage"), dict) else {}
        stage["segment"] = seg
        if did in LISTEN_KEYWORD_IDS:
            stage["keywords"] = list(DEFAULT_KEYWORDS)
        if "listen" in did or did in LISTEN_KEYWORD_IDS:
            stage["camera"] = "listen" if "listen" in did or did.startswith("dialog_m001") else stage.get("camera", "")
        row["stage"] = {k: v for k, v in stage.items() if v}

        effects = list(row.get("effects", []) or [])
        # 仅在段首节点写 effect，避免每句都刷 DomainBus：用启发式——start/rollcall/gate/policy/tasks/close 或首次 council
        write_fx = any(
            x in did
            for x in (
                "_start",
                "_rollcall",
                "_zhou_order",
                "_zhou_rollcall",
                "_ladder",
                "_enter_hall",
                "_council_gate",
                "_council_zhou",
                "_council_zian",
                "dialog_meeting_council_player_pick",
                "dialog_meeting_policy_resolve",
                "_policy_wood",
                "_policy_son",
                "_policy",
                "_tasks",
                "_task_",
                "_close",
            )
        )
        # m003_policy / m000_tasks etc.
        if did.endswith("_policy") or did.endswith("_tasks") or "policy_resolve" in did:
            write_fx = True
        if write_fx:
            row["effects"] = ensure_seg_effect(effects, seg)
        patched += 1

    save("def_dialog.json", data)
    print(f"patched meeting dialogs: {patched}")


if __name__ == "__main__":
    main()
