# -*- coding: utf-8 -*-
"""P5: failure events F001–F005 + overlay l10n."""
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "packs" / "anchao"


def load(name: str):
    return json.loads((ROOT / name).read_text(encoding="utf-8"))


def save(name: str, data) -> None:
    (ROOT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("updated", name)


def upsert_rows(table_file: str, id_key: str, new_rows: list) -> None:
    data = load(table_file)
    rows = data["rows"]
    index = {str(r.get(id_key)): i for i, r in enumerate(rows)}
    for nr in new_rows:
        k = str(nr.get(id_key))
        if k in index:
            rows[index[k]] = nr
        else:
            rows.append(nr)
    save(table_file, {"rows": rows})


EVENTS = [
    {
        "event_id": "F001",
        "loc_key": "event.f001.name",
        "dialog_entry": "dialog_f001_start",
        "mutex_group": "",
        "route_tags": [],
        "require": [{"key": "stat_suspicion", "op": ">=", "value": 30}],
        "effects": [],
        "effects_when": "dialog",
    },
    {
        "event_id": "F002",
        "loc_key": "event.f002.name",
        "dialog_entry": "dialog_f002_start",
        "mutex_group": "",
        "route_tags": [],
        "require": [
            {"key": "stat_suspicion", "op": ">=", "value": 50},
            {"key": "stat_trust_firm", "op": "<=", "value": 20},
        ],
        "effects": [],
        "effects_when": "dialog",
    },
    {
        "event_id": "F003",
        "loc_key": "event.f003.name",
        "dialog_entry": "dialog_f003_start",
        "mutex_group": "",
        "route_tags": [],
        "require": [{"key": "stat_suspicion", "op": ">=", "value": 70}],
        "effects": [],
        "effects_when": "dialog",
    },
    {
        "event_id": "F004",
        "loc_key": "event.f004.name",
        "dialog_entry": "dialog_f004_start",
        "mutex_group": "",
        "route_tags": [],
        "require": [
            {
                "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"},
                "key": "score",
                "op": "<=",
                "value": -20,
            },
            {"meter": "pursuit", "op": ">=", "value": 60},
        ],
        "effects": [],
        "effects_when": "dialog",
    },
    {
        "event_id": "F005",
        "loc_key": "event.f005.name",
        "dialog_entry": "dialog_f005_start",
        "mutex_group": "",
        "route_tags": [],
        "require": [
            {
                "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"},
                "key": "suspicion",
                "op": ">=",
                "value": 3,
            }
        ],
        "effects": [],
        "effects_when": "dialog",
    },
]


DIALOGS = [
    {
        "dialog_id": "dialog_f001_start",
        "event_id": "F001",
        "speaker": "narrator",
        "loc_key": "dialog.f001.start",
        "next": "dialog_f001_qian",
    },
    {
        "dialog_id": "dialog_f001_qian",
        "speaker": "char_qian_demao",
        "loc_key": "dialog.f001.qian",
        "next": "dialog_f001_outro",
    },
    {
        "dialog_id": "dialog_f001_outro",
        "speaker": "narrator",
        "loc_key": "dialog.f001.outro",
        "effects": [
            {
                "op": "add",
                "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"},
                "key": "score",
                "value": -5,
            }
        ],
        "next": "",
    },
    {
        "dialog_id": "dialog_f002_start",
        "event_id": "F002",
        "speaker": "narrator",
        "loc_key": "dialog.f002.start",
        "next": "dialog_f002_qian",
    },
    {
        "dialog_id": "dialog_f002_qian",
        "speaker": "char_qian_demao",
        "loc_key": "dialog.f002.qian",
        "next": "dialog_f002_outro",
    },
    {
        "dialog_id": "dialog_f002_outro",
        "speaker": "narrator",
        "loc_key": "dialog.f002.outro",
        "effects": [
            {"op": "set_flag", "key": "flag_demoted", "value": True},
            {"op": "set_rank", "value": "apprentice"},
            {
                "op": "add",
                "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"},
                "key": "score",
                "value": -10,
            },
        ],
        "next": "",
    },
    {
        "dialog_id": "dialog_f003_start",
        "event_id": "F003",
        "speaker": "narrator",
        "loc_key": "dialog.f003.start",
        "next": "dialog_f003_qian",
    },
    {
        "dialog_id": "dialog_f003_qian",
        "speaker": "char_qian_demao",
        "loc_key": "dialog.f003.qian",
        "next": "dialog_f003_outro",
    },
    {
        "dialog_id": "dialog_f003_outro",
        "speaker": "narrator",
        "loc_key": "dialog.f003.outro",
        "effects": [
            {"op": "set_flag", "key": "flag_fired", "value": True},
            {"op": "set_flag", "key": "route_endure_failed", "value": True},
            {"op": "set_flag", "key": "flag_ending_fail", "value": True},
            {
                "op": "add",
                "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"},
                "key": "score",
                "value": -40,
            },
            {"op": "end_run", "reason": "fired"},
        ],
        "next": "",
    },
    {
        "dialog_id": "dialog_f004_start",
        "event_id": "F004",
        "speaker": "narrator",
        "loc_key": "dialog.f004.start",
        "next": "dialog_f004_overhear",
    },
    {
        "dialog_id": "dialog_f004_overhear",
        "speaker": "narrator",
        "loc_key": "dialog.f004.overhear",
        "next": "dialog_f004_zian",
    },
    {
        "dialog_id": "dialog_f004_zian",
        "speaker": "char_qian_zian",
        "loc_key": "dialog.f004.zian",
        "next": "dialog_f004_outro",
    },
    {
        "dialog_id": "dialog_f004_outro",
        "speaker": "narrator",
        "loc_key": "dialog.f004.outro",
        "effects": [
            {"op": "add", "key": "stat_suspicion", "value": 30},
            {
                "op": "add",
                "edge": {"from": "char_qian_zian", "to": "char_lin_ruisheng"},
                "key": "score",
                "value": -20,
            },
            {
                "op": "add",
                "edge": {"from": "char_liu_ruyan", "to": "char_lin_ruisheng"},
                "key": "score",
                "value": -15,
            },
            {"op": "set_flag", "key": "flag_liu_betrayed", "value": True},
        ],
        "next": "",
    },
    {
        "dialog_id": "dialog_f005_start",
        "event_id": "F005",
        "speaker": "narrator",
        "loc_key": "dialog.f005.start",
        "next": "dialog_f005_watch",
    },
    {
        "dialog_id": "dialog_f005_watch",
        "speaker": "narrator",
        "loc_key": "dialog.f005.watch",
        "next": "dialog_f005_frame",
    },
    {
        "dialog_id": "dialog_f005_frame",
        "speaker": "narrator",
        "loc_key": "dialog.f005.frame",
        "next": "dialog_f005_out",
    },
    {
        "dialog_id": "dialog_f005_out",
        "speaker": "char_qian_demao",
        "loc_key": "dialog.f005.out",
        "effects": [
            {"op": "set_flag", "key": "flag_purged", "value": True},
            {"op": "set_flag", "key": "flag_ending_fail", "value": True},
            {
                "op": "add",
                "edge": {"from": "char_qian_demao", "to": "char_lin_ruisheng"},
                "key": "score",
                "value": -50,
            },
            {"op": "end_run", "reason": "purged"},
        ],
        "next": "",
    },
]


LOC = {
    "event.f001.name": "被敲打",
    "event.f002.name": "被降职",
    "event.f003.name": "被开除",
    "event.f004.name": "柳如烟反水",
    "event.f005.name": "钱德茂清除",
    "dialog.f001.start": "钱德茂把你叫进账房，把门关上。桌上的茶凉了，他却不急着喝。",
    "dialog.f001.qian": "瑞生，我待你不薄。有些事，看见了当没看见。听见了当没听见。再不安分，这商行容不下你。",
    "dialog.f001.outro": "他挥了挥手让你出去。警告已经落下，下一次就不会只是谈话。",
    "dialog.f002.start": "前堂众人面前，钱德茂当众点了你的名。",
    "dialog.f002.qian": "从今天起，瑞生去做杂役。跑街、管货的事，先放下。月例减半——自己好好想想。能不能吃饱饭、还谈不谈得起婚事，就看你还长不长记性。",
    "dialog.f002.outro": "伙计们低头不语。你站在原地，像被当众剥了一层皮。这不只是丢脸；从明天起，银钱就会一点点告诉你，什么叫往下掉。",
    "dialog.f003.start": "钱德茂把你的铺盖卷扔到前堂门外。伙计们低头让路，没人敢接你的目光。",
    "dialog.f003.qian": "钱记商行，容不下你这种人。走吧。天津卫大得很——别让我再看见你在附近转。",
    "dialog.f003.outro": "隐忍线断了。朱红大门在身后合上，合得很死。你兜里那点散碎银子，撑不了几天；从今往后，吃饭、住店、抬头见人，都得另算。",
    "dialog.f004.start": "你绕过后院廊柱时，听见钱子安的笑声——旁边，是如烟压得很低的声音。",
    "dialog.f004.overhear": "「……是他让我接近您的。他说，打听账上的事……」半句话够了。枕边风翻了面，变成刀子。",
    "dialog.f004.zian": "（似笑非笑，抬眼望向廊外）林瑞生啊……胆子不小。",
    "dialog.f004.outro": "你退进阴影。商行里的空气变了——像有人把你的名字写进了黑册。",
    "dialog.f005.start": "东家的疑心已经压不住了。先是盯梢，再是栽赃，最后是一纸「送客」。",
    "dialog.f005.watch": "有人夜夜跟在你身后。货栈小屋的门缝外，有新脚印。",
    "dialog.f005.frame": "第二天，账房「丢」了一笔银子。证据齐得像早写好的戏——你的名字写在最上面。",
    "dialog.f005.out": "天津卫容不下你了。滚。",
    "ui.failure_pending": "风声不对……",
    "ui.done": "收势",
    "ui.reckon_title": "清算",
    "ui.reckon.punish": "罚：当众夺脸。",
    "ui.reckon.forgive": "恕：能杀而收刀。",
    "ui.reckon.status": "恩怨状态 → %s",
    "promo.demote_tip": "降为%s · 月例档 %d 两",
}


def main() -> None:
    upsert_rows("def_event.json", "event_id", EVENTS)
    upsert_rows("def_dialog.json", "dialog_id", DIALOGS)

    l10n = load("l10n/zh_CN.json")
    l10n.setdefault("zh_CN", {}).update(LOC)
    save("l10n/zh_CN.json", l10n)

    reg = load("registry/events.json")
    have = {e["event_id"] for e in reg.get("events", [])}
    for ev in EVENTS:
        if ev["event_id"] not in have:
            reg["events"].append(
                {
                    "event_id": ev["event_id"],
                    "chapter": 0,
                    "event_type": "failure",
                    "dialog_entry": ev["dialog_entry"],
                    "mutex_group": "",
                    "route_tags": [],
                    "status": "active",
                }
            )
        else:
            for row in reg["events"]:
                if row["event_id"] == ev["event_id"]:
                    row["event_type"] = "failure"
                    row["dialog_entry"] = ev["dialog_entry"]
                    row["status"] = "active"
    save("registry/events.json", reg)

    pack = load("pack.json")
    pack["content_version"] = "0.6.0-p5"
    save("pack.json", pack)
    print("dialogs", len(DIALOGS), "events", len(EVENTS))


if __name__ == "__main__":
    main()
