[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GameDir
)

$ErrorActionPreference = "Stop"
$archiveName = "狐狸汉化适配-疲劳恢复从15改为(8+面板疲劳÷10)汉化版.zip"
$knownHash = "98ACE863999F58B039D20948E3B03713DA1D8E8EC7FEBE3ADC6B661BBB448BE8"

if (Get-Process -Name "BattleBrothers" -ErrorAction SilentlyContinue) {
    throw "BattleBrothers.exe is running. Close the game before disabling the legacy fatigue-recovery archive; no files were changed."
}

$dataDir = Join-Path $GameDir "data"
if (!(Test-Path -LiteralPath (Join-Path $dataDir "data_001.dat"))) {
    throw "Steam game data archive was not found: $(Join-Path $dataDir 'data_001.dat')"
}

$activeArchive = Join-Path $dataDir $archiveName
if (!(Test-Path -LiteralPath $activeArchive)) {
    return
}

$actualHash = (Get-FileHash -LiteralPath $activeArchive -Algorithm SHA256).Hash
if ($actualHash -ne $knownHash) {
    Write-Host "Leaving unknown fatigue-recovery archive active: $activeArchive ($actualHash)"
    return
}

$disabled = "$activeArchive.bbca-disabled"
$suffix = 1
while (Test-Path -LiteralPath $disabled) {
    $disabled = "$activeArchive.bbca-disabled-$suffix"
    $suffix++
}

Move-Item -LiteralPath $activeArchive -Destination $disabled
Write-Host "Disabled known legacy fatigue-recovery archive as $disabled; no .bbca-backup file was changed"
