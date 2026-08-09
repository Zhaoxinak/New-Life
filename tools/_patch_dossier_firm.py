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


upsert(ROOT / "zh_CN.csv", {"ui.dossier.stat_firm": "{name}（公司）"})
upsert(ROOT / "en.csv", {"ui.dossier.stat_firm": "{name} (firm)"})
print("ok")
