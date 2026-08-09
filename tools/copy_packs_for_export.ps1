# Copy authoritative packs into game/data for Godot export.
# CRITICAL: mark every CSV as importer=keep so Godot does NOT treat pack tables
# as csv_translation (that breaks PackDB/L10n in exported builds → money 0,
# all doors locked, quests finished).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root "docs\tables\packs"
$dst = Join-Path $root "game\data\packs"
if (-not (Test-Path $src)) {
	throw "Pack source missing: $src"
}
if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item -Recurse -Force (Join-Path $src "*") $dst

# Strip any Godot translation artifacts if present from a previous bad import.
Get-ChildItem -Path $dst -Recurse -File -Include *.translation, *.csv.import |
	Remove-Item -Force -ErrorAction SilentlyContinue

$keepImport = @"
[remap]

importer="keep"

"@
$csvCount = 0
Get-ChildItem -Path $dst -Recurse -Filter *.csv | ForEach-Object {
	$importPath = "$($_.FullName).import"
	Set-Content -Path $importPath -Value $keepImport -Encoding ascii
	$csvCount++
}

Write-Host "Copied packs -> $dst"
Write-Host "Marked $csvCount CSV files as importer=keep (raw data for PackDB)"
Get-ChildItem (Join-Path $dst "core") -Filter *.csv | Select-Object -First 8 Name
