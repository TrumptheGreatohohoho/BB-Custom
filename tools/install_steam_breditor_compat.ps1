[CmdletBinding()]
param(
    [string]$GameDir = "D:\games\steam\steamapps\common\Battle Brothers",
    [string]$PackPath = "build/custom_appearance/mod_bb_custom_appearance.zip",
    [string]$BreditorSourceArchive = "",
    [string]$ModHooksSourceArchive = ""
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (Get-Process -Name "BattleBrothers" -ErrorAction SilentlyContinue) {
    throw "BattleBrothers.exe is running. Close the game before installing the Steam Breditor compatibility pack; no files were changed."
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$vendorDir = Join-Path $root "vendor"
if ([string]::IsNullOrWhiteSpace($BreditorSourceArchive)) {
    $BreditorSourceArchive = Join-Path $vendorDir "mod_hx_breditor_VANILLA-294-4-31-1664773426.zip"
}
if ([string]::IsNullOrWhiteSpace($ModHooksSourceArchive)) {
    $ModHooksSourceArchive = Join-Path $vendorDir "mod_hooks.zip-42-20-1-1621709174.zip"
}
$dataDir = Join-Path $GameDir "data"
$modDir = $dataDir
$packSource = Resolve-Path (Join-Path $root $PackPath)
$breditorSource = Resolve-Path -LiteralPath $BreditorSourceArchive
$modHooksSource = Resolve-Path -LiteralPath $ModHooksSourceArchive

if (!(Test-Path -LiteralPath (Join-Path $dataDir "data_001.dat"))) {
    throw "Steam game data archive was not found: $(Join-Path $dataDir 'data_001.dat')"
}

function Set-ManagedArchive([string]$Source, [string]$Destination, [string]$BackupSource = "") {
    $backup = "$Destination.bbca-backup"
    if (!(Test-Path -LiteralPath $backup)) {
        if (Test-Path -LiteralPath $Destination) {
            Copy-Item -LiteralPath $Destination -Destination $backup
        }
        elseif (![string]::IsNullOrWhiteSpace($BackupSource)) {
            Copy-Item -LiteralPath $BackupSource -Destination $backup
        }
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Read-ZipText([System.IO.Compression.ZipArchiveEntry]$Entry) {
    $reader = [System.IO.StreamReader]::new($Entry.Open(), [System.Text.Encoding]::UTF8, $true)
    try {
        return $reader.ReadToEnd()
    }
    finally {
        $reader.Dispose()
    }
}

$stageRoot = Join-Path $root ("build\steam_breditor_compat_stage_" + [guid]::NewGuid().ToString("N"))
$stageData = Join-Path $stageRoot "data"
$breditorFileName = Split-Path -Leaf $breditorSource
$stageArchive = Join-Path $stageData $breditorFileName

New-Item -ItemType Directory -Force -Path $stageData, $modDir | Out-Null
Copy-Item -LiteralPath $breditorSource -Destination $stageArchive

& (Join-Path $PSScriptRoot "patch_active_breditor_ui.ps1") -GameDir $stageRoot -UiArchiveName $breditorFileName

$archive = [System.IO.Compression.ZipFile]::OpenRead($stageArchive)
try {
    foreach ($required in @("ui/main.html", "ui/world_names.js", "ui/ui.js", "ui/bbca_cn_ui_compat.js", "ui/mods/bb_custom_appearance.css", "ui/mods/bb_custom_appearance.js", "brushes/bb_custom_appearance.brush", "gfx/bb_custom_appearance.png")) {
        if ($null -eq $archive.GetEntry($required)) {
            throw "Steam compatibility archive is missing $required"
        }
    }

    $mainEntry = $archive.GetEntry("ui/main.html")
    $mainHtml = Read-ZipText $mainEntry
    if (!$mainHtml.Contains('<script type="text/javascript" src="world_names.js"></script>')) {
        throw "Steam compatibility archive does not load the Chinese world-name translation helper"
    }
    if (!$mainHtml.Contains('<script type="text/javascript" src="ui.js"></script>')) {
        throw "Steam compatibility archive does not load the full Chinese UI translation helper"
    }

    $fullTranslationEntry = $archive.GetEntry("ui/ui.js")
    $fullTranslationScript = Read-ZipText $fullTranslationEntry
    foreach ($requiredText in @("var TranslatePopupDialog", "var TranslateDialog", "var TranslateButtons", "var TranslateSLCampaignMenuModule")) {
        if (!$fullTranslationScript.Contains($requiredText)) {
            throw "Steam compatibility full Chinese UI helper is missing $requiredText"
        }
    }

    $worldNamesEntry = $archive.GetEntry("ui/world_names.js")
    $worldNamesScript = Read-ZipText $worldNamesEntry
    foreach ($requiredText in @("TranslateTooltips", "TranslateTownScreenNames")) {
        if (!$worldNamesScript.Contains($requiredText)) {
            throw "Steam compatibility world-name helper is missing $requiredText"
        }
    }
    if (!$mainHtml.Contains('<script type="text/javascript" src="bbca_cn_ui_compat.js"></script>')) {
        throw "Steam compatibility archive does not load the BBCA Chinese UI compatibility helper"
    }

    $translationEntry = $archive.GetEntry("ui/bbca_cn_ui_compat.js")
    $translationScript = Read-ZipText $translationEntry
    foreach ($requiredText in @('typeof TranslateDialog === "undefined"', 'typeof TranslateButtons === "undefined"', 'typeof TranslateAllWorldNames === "undefined"')) {
        if (!$translationScript.Contains($requiredText)) {
            throw "Steam compatibility translation helper is missing $requiredText"
        }
    }

    $screenEntry = $archive.GetEntry("scripts/ui/screens/world/world_breditor_screen.nut")
    if ($null -eq $screenEntry) {
        throw "Steam compatibility archive is missing the Breditor backend"
    }
    $screenScript = Read-ZipText $screenEntry
    foreach ($requiredText in @("// BBCA_BACKEND_BEGIN", "function applyCustomAppearance", "function getCustomSkillCatalog", "function applyCustomSkill", "bbca_female_body_01", "local isNoBeard")) {
        if (!$screenScript.Contains($requiredText)) {
            throw "Steam compatibility backend is missing $requiredText"
        }
    }
}
finally {
    $archive.Dispose()
}

$breditorDestination = Join-Path $modDir $breditorFileName
$modHooksDestination = Join-Path $modDir (Split-Path -Leaf $modHooksSource)
$packDestination = Join-Path $modDir (Split-Path -Leaf $packSource)

Set-ManagedArchive -Source $stageArchive -Destination $breditorDestination -BackupSource $breditorSource
Set-ManagedArchive -Source $modHooksSource -Destination $modHooksDestination -BackupSource $modHooksSource
Set-ManagedArchive -Source $packSource -Destination $packDestination

Write-Host "Installed Steam Breditor compatibility archive $breditorDestination"
Write-Host "Installed Mod Hooks $modHooksDestination"
Write-Host "Installed Custom Appearance pack $packDestination"
Write-Host "Breditor rollback backup $($breditorDestination).bbca-backup"
