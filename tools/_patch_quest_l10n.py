# -*- coding: utf-8 -*-
from pathlib import Path


def upsert_csv(path: Path, updates: dict) -> None:
    text = path.read_text(encoding="utf-8-sig")
    lines = text.splitlines()
    out = []
    seen = set()
    for line in lines:
        if not line.strip() or "," not in line:
            out.append(line)
            continue
        key = line.split(",", 1)[0]
        if key in updates:
            val = updates[key]
            if "," in val or '"' in val or val.startswith(" ") or "\n" in val:
                esc = val.replace('"', '""')
                out.append(f'{key},"{esc}"')
            else:
                out.append(f"{key},{val}")
            seen.add(key)
        else:
            out.append(line)
    missing = [k for k in updates if k not in seen]
    for k in missing:
        val = updates[k]
        if "," in val or '"' in val:
            esc = val.replace('"', '""')
            out.append(f'{k},"{esc}"')
        else:
            out.append(f"{k},{val}")
    path.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(path.name, "updated", len(seen), "appended", len(missing))


zh = {
    "unlock.hotspot.rival_office": "第20天起 · 须先「接受通洋职位」",
    "unlock.hotspot.dock_office": "第2天起 · 需装卸组组长职级",
    "ui.locked.reason_periods": "仅{periods}可用",
    "ui.locked.flag.joined_tongyang": "须先在掌柜办公室「接受通洋职位」",
    "ui.locked.flag.can_join_tongyang": "须先售卖情报或攒够陈掌柜好感，获得跳槽资格",
    "ui.locked.flag.flag_sold_intel": "须先售卖过宏远情报",
    "ui.empty.hotspots_locked_hint": "灰色项未开放；括号内是解锁/条件说明",
}

en = {
    "unlock.hotspot.rival_office": "From day 20 · Accept Tongyang job first",
    "unlock.hotspot.dock_office": "From day 2 · need Foreman rank",
    "ui.locked.reason_periods": "Only available: {periods}",
    "ui.locked.flag.joined_tongyang": "Accept the Tongyang job in the Manager Office first",
    "ui.locked.flag.can_join_tongyang": "Sell intel or raise Chen favor enough to become eligible",
    "ui.locked.flag.flag_sold_intel": "Sell Hongyuan intel first",
    "ui.empty.hotspots_locked_hint": "Gray items are locked; parentheses show unlock conditions",
}

base = Path(r"f:\Games\New-Life\docs\tables\packs\core\l10n")
upsert_csv(base / "zh_CN.csv", zh)
upsert_csv(base / "en.csv", en)
