# Copy authoritative packs into game/data for Godot export.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "docs\tables\packs"
$dst = Join-Path $root "game\data\packs"
if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item -Recurse -Force (Join-Path $src "*") $dst
Write-Host "Copied packs -> $dst"
Get-ChildItem (Join-Path $dst "core") | Select-Object -First 5 Name
