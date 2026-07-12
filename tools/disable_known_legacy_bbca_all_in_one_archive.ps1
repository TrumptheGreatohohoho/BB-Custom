[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GameDir
)

$ErrorActionPreference = "Stop"
$archiveName = "mod_bbca_all_in_one_cn_compat.zip"
$knownHash = "1E75A631FA34A6D0760C661DEC41112A2BC29BBC1CCDDFB2F39D8A4827344750"

if (Get-Process -Name "BattleBrothers" -ErrorAction SilentlyContinue) {
    throw "BattleBrothers.exe is running. Close the game before disabling the conflicting legacy BBCA all-in-one archive; no files were changed."
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
    Write-Host "Leaving unknown BBCA all-in-one archive active: $activeArchive ($actualHash)"
    return
}

$disabled = "$activeArchive.bbca-disabled"
$suffix = 1
while (Test-Path -LiteralPath $disabled) {
    $disabled = "$activeArchive.bbca-disabled-$suffix"
    $suffix++
}

Move-Item -LiteralPath $activeArchive -Destination $disabled
Write-Host "Disabled known conflicting legacy BBCA all-in-one archive as $disabled; no .bbca-backup file was changed"
