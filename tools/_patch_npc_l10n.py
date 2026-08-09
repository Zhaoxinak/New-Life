# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "docs" / "tables" / "packs" / "core" / "l10n"


def upsert(path: Path, updates: dict[str, str]) -> None:
    text = path.read_text(encoding="utf-8-sig")
    lines = text.splitlines()
    out = []
    seen = set()
    for line in lines:
        if not line.strip() or "," not in line:
            out.append(line)
            continue
        k = line.split(",", 1)[0]
        if k in updates:
            val = updates[k]
            if "," in val or '"' in val:
                out.append('%s,"%s"' % (k, val.replace('"', '""')))
            else:
                out.append("%s,%s" % (k, val))
            seen.add(k)
        else:
            out.append(line)
    for k, val in updates.items():
        if k in seen:
            continue
        if "," in val or '"' in val:
            out.append('%s,"%s"' % (k, val.replace('"', '""')))
        else:
            out.append("%s,%s" % (k, val))
    path.write_text("\n".join(out) + "\n", encoding="utf-8-sig")


upsert(
    ROOT / "zh_CN.csv",
    {
        "minimap.hint": "M 关闭 · 蓝点为你 · 黄点建筑 · 青点主线角色",
        "ui.world.talk_npc": "按 E 与{name}交谈",
    },
)
upsert(
    ROOT / "en.csv",
    {
        "minimap.hint": "M to close · blue = you · gold = buildings · teal = story NPCs",
        "ui.world.talk_npc": "Press E to talk to {name}",
    },
)
print("ok")
