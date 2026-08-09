# -*- coding: utf-8 -*-
import csv
from pathlib import Path

path = Path(__file__).resolve().parents[1] / "docs/tables/packs/core/l10n/en.csv"
updates = {
    "quest.done.title": "Showcase route complete",
    "quest.done.hint": (
        "1. After the public clash you may explore freely||"
        "2. Watch suspicion and money on the top bar||"
        "3. Full demo still keeps rival/exchange branches||"
        "4. Save before starting another run"
    ),
    "quest.day5.title": "Survive the handkerchief night — reach Day 5",
    "quest.day5.hint": (
        '1. From Day 4 evening, "The Handkerchief Isn\'t Mine" may fire||'
        "2. Confront or swallow it — either way the crack shows; talk to Wanqing later turns cold||"
        "3. Each day has morning / evening / night||"
        "4. Top bar Day 5 completes this||"
        "5. If suspicion is high, rest at home first"
    ),
    "quest.day7.title": "Day 7 choice: endure and divide",
    "quest.day7.hint": (
        "1. Keep acting until Day 7||"
        "2. Evening choice: for the showcase pick Endure / Divide (Route B)||"
        "3. Rival/Exchange unlock, but this showcase pushes the father–son crack||"
        "4. Reaching Day 7 completes this"
    ),
    "quest.b_wedge.title": "Push the father–son crack deeper",
    "quest.b_wedge.hint": (
        "Do any one (company preferred):||"
        "A. Hongyuan → Vice Office → Plant a False Tip / Deal with Vice||"
        "B. Hongyuan → Boss Office → Flatter the Boss||"
        "C. Home → Living Room → Guide pillow talk / Talk to fiancée||"
        "D. Frame a ledger gap also works||"
        "Goal: raise tension until the public clash"
    ),
    "quest.b_clash.title": "Wait for the cup to break (public clash)",
    "quest.b_clash.hint": (
        "1. Keep dividing inside company/home||"
        '2. When tension is high enough, "The Cup Breaks" fires||'
        '3. Choose "Stand in the crack. Remember this cut."||'
        '4. Ending "The Crack Opens" finishes the showcase||'
        "5. You do not need Day 28"
    ),
    "quest.meet_people.hint": (
        "1. Enter Hongyuan Trading||"
        "2. Open Vice Manager Office||"
        "3. Pick one:||"
        "   · Chance into Fiancée (Wanqing)||"
        "   · Deal with the Vice Manager (Shaoting)||"
        "4. Finish dialogue/settle to complete||"
        "5. Watch her sleeve and tone — it will turn"
    ),
    "quest.enter_company.hint": (
        "1. Return outdoors||"
        "2. Walk to Hongyuan Trading (upper-left stone building)||"
        "3. Approach the doorplate to enter||"
        "4. The location menu appears — talk here sounds like orders"
    ),
    "quest.dock_work.hint": (
        "1. Outdoors: enter Dock Yard first||"
        "2. In the menu pick Loading Area||"
        "3. Run Haul Cargo||"
        "4. Read the result beat first, then numbers||"
        "5. Exit when done"
    ),
}

rows = []
seen = set()
with path.open(encoding="utf-8", newline="") as f:
    reader = csv.reader(f)
    header = next(reader)
    rows.append(header)
    for row in reader:
        if row and row[0] in updates:
            rows.append([row[0], updates[row[0]]] + row[2:])
            seen.add(row[0])
        else:
            rows.append(row)
for key, val in updates.items():
    if key not in seen:
        rows.append([key, val])
with path.open("w", encoding="utf-8", newline="") as f:
    csv.writer(f, lineterminator="\n").writerows(rows)
print("en quest updated", len(seen), "appended", len(updates) - len(seen))
