[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GameDir
)

$ErrorActionPreference = "Stop"
$knownHash = "4C53189CC73DD5BDEB8C30E7CFC41A337088F048F71F3ACDDE947B4A2A1256FB"

if (Get-Process -Name "BattleBrothers" -ErrorAction SilentlyContinue) {
    throw "BattleBrothers.exe is running. Close the game before disabling the conflicting legacy hit-chance archive; no files were changed."
}

$dataDir = Join-Path $GameDir "data"
if (!(Test-Path -LiteralPath (Join-Path $dataDir "data_001.dat"))) {
    throw "Steam game data archive was not found: $(Join-Path $dataDir 'data_001.dat')"
}

$matches = @(Get-ChildItem -LiteralPath $dataDir -File -Filter "*.zip" | Where-Object {
    (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash -eq $knownHash
})

foreach ($archive in $matches) {
    $backup = "$($archive.FullName).bbca-backup"
    if (!(Test-Path -LiteralPath $backup)) {
        Move-Item -LiteralPath $archive.FullName -Destination $backup
        Write-Host "Disabled known conflicting legacy hit-chance archive and preserved it as $backup"
        continue
    }

    $disabled = "$($archive.FullName).bbca-disabled"
    $suffix = 1
    while (Test-Path -LiteralPath $disabled) {
        $disabled = "$($archive.FullName).bbca-disabled-$suffix"
        $suffix++
    }
    Move-Item -LiteralPath $archive.FullName -Destination $disabled
    Write-Host "Disabled known conflicting legacy hit-chance archive as $disabled; existing backup was not changed"
}
