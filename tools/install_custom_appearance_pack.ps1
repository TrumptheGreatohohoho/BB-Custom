param(
    [string]$GameDir = "D:\games\steam\steamapps\common\Battle Brothers",
    [string]$PackPath = "build/custom_appearance/mod_bb_custom_appearance.zip"
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path ".").Path
$source = Resolve-Path (Join-Path $root $PackPath)
$dataDir = Join-Path $GameDir "data"
if (!(Test-Path -LiteralPath $dataDir)) {
    throw "Battle Brothers data directory was not found: $dataDir"
}

$legacyArchives = @(Get-ChildItem -LiteralPath $dataDir -File | Where-Object { $_.Name -like "*data_cn_u_20240303.zip" })
if ($legacyArchives.Count -eq 1) {
    $modDir = Join-Path $dataDir "mod"
    if (!(Test-Path -LiteralPath $modDir)) {
        throw "Battle Brothers mod directory was not found: $modDir"
    }

    $destination = Join-Path $modDir (Split-Path -Leaf $source)
    Copy-Item -LiteralPath $source -Destination $destination -Force
    Write-Host "Installed $destination"
    & (Join-Path $PSScriptRoot "install_active_breditor_ui_patch.ps1") -GameDir $GameDir
}
else {
    & (Join-Path $PSScriptRoot "install_steam_breditor_compat.ps1") -GameDir $GameDir -PackPath $PackPath
}

& (Join-Path $PSScriptRoot "disable_known_legacy_hitchance_archive.ps1") -GameDir $GameDir
& (Join-Path $PSScriptRoot "disable_known_legacy_bbca_all_in_one_archive.ps1") -GameDir $GameDir
