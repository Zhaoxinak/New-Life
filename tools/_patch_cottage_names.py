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
        "npc_homes.dock_foreman": "老号工棚",
        "npc_homes.stall_aunt": "阿婶糖糕铺",
        "npc_homes.tea_waiter": "小福栖处",
        "npc_homes.garage_hand": "阿强修车棚",
        "npc_homes.zhou_shaoting": "少霆外宅",
        "npc_homes.chen_manager": "通洋驻处",
    },
)
upsert(
    ROOT / "en.csv",
    {
        "npc_homes.dock_foreman": "Foreman Shed",
        "npc_homes.stall_aunt": "Auntie's Sweet Stall",
        "npc_homes.tea_waiter": "Xiao Fu's Quarters",
        "npc_homes.garage_hand": "Ah Qiang's Workshop",
        "npc_homes.zhou_shaoting": "Shaoting Annex",
        "npc_homes.chen_manager": "Tongyang Lodge",
    },
)
print("names ok")
