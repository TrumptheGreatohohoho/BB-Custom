[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GameDir
)

$ErrorActionPreference = "Stop"
$knownHash = "98ACE863999F58B039D20948E3B03713DA1D8E8EC7FEBE3ADC6B661BBB448BE8"

if (Get-Process -Name "BattleBrothers" -ErrorAction SilentlyContinue) {
    throw "BattleBrothers.exe is running. Close the game before disabling the legacy fatigue-recovery archive; no files were changed."
}

$dataDir = Join-Path $GameDir "data"
if (!(Test-Path -LiteralPath (Join-Path $dataDir "data_001.dat"))) {
    throw "Steam game data archive was not found: $(Join-Path $dataDir 'data_001.dat')"
}

$matches = @(Get-ChildItem -LiteralPath $dataDir -File -Filter "*.zip" | Where-Object {
    (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash -eq $knownHash
})

foreach ($archive in $matches) {
    $disabled = "$($archive.FullName).bbca-disabled"
    $suffix = 1
    while (Test-Path -LiteralPath $disabled) {
        $disabled = "$($archive.FullName).bbca-disabled-$suffix"
        $suffix++
    }

    Move-Item -LiteralPath $archive.FullName -Destination $disabled
    Write-Host "Disabled known legacy fatigue-recovery archive as $disabled; no .bbca-backup file was changed"
}
