# Export / run notes for 码头风云 Demo

## Local Godot (this machine)

Engine zip is already unpacked under the repo:

`Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe`

## Run (editor)

1. Open Godot 4.7.1 → **Import** → `game/project.godot`
2. Play (`F5`) → Title → New Game
3. **WASD** move on the harbor map · **E** enter buildings / interact indoors

Optional art: `game/art/world/`, `game/art/locations/`, `game/art/portraits/`, `game/art/player/`.

Headless smoke (no window):

```powershell
& ".\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path game --quit-after 60
```

## Pack data

- Dev: engine reads `../docs/tables/packs`
- Export: copy packs into the project first:

```powershell
# from repo root
.\tools\copy_packs_for_export.ps1
```

## Export Windows

1. In Godot: **Editor → Manage Export Templates… → Download and Install** (4.7.1 · ~1.2GB, once)
2. Copy packs (script above)
3. **Project → Export → Windows Desktop** → Export Project → `builds/DocksideStorm.exe`

Or CLI (after templates are installed):

```powershell
New-Item -ItemType Directory -Force builds | Out-Null
.\tools\copy_packs_for_export.ps1
& ".\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe" --headless --path game --export-release "Windows Desktop" ../builds/DocksideStorm.exe
```

Preset file: `game/export_presets.cfg`.

## QA shortcuts

- `F3` — debug panel (set day / suspicion / force B clash pulse)
- Title → Settings — language & SFX mute

## Smoke (no Godot)

```powershell
python tools/scan_l10n.py
python tools/smoke_w3_data.py
python tools/smoke_w4_data.py
python tools/smoke_w6_sim.py
```
