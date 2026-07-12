[CmdletBinding()]
param(
    [string]$OutDir = "build/handoff",
    [string]$FileName = "BB-Custom-engineering-handoff.zip"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outPath = [IO.Path]::GetFullPath((Join-Path $root $OutDir))
$stagePath = Join-Path $outPath "_stage"
$stageRoot = Join-Path $stagePath "BB-Custom"
$zipPath = Join-Path $outPath $FileName
$sidecarPath = "$zipPath.sha256"
$referenceArchiveName = "mod_fantasybro-473-4-2b-1722856556.zip"
$referenceMatches = @(Get-ChildItem -LiteralPath $root -File -Recurse -Filter $referenceArchiveName | Where-Object {
    !$_.FullName.StartsWith((Join-Path $root "build") + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
})
if ($referenceMatches.Count -ne 1) {
    throw "Expected one FantasyBro source-reference archive, found $($referenceMatches.Count)"
}
$referenceSource = $referenceMatches[0]
$referenceDirName = $referenceSource.Directory.Name

function Assert-WorkspaceChild([string]$Path, [string]$ExpectedLeaf = "") {
    $full = [IO.Path]::GetFullPath($Path)
    if (!$full.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes workspace: $full"
    }
    if (![string]::IsNullOrWhiteSpace($ExpectedLeaf) -and (Split-Path -Leaf $full) -ne $ExpectedLeaf) {
        throw "Unexpected path leaf: $full"
    }
    return $full
}

Assert-WorkspaceChild $outPath | Out-Null
Assert-WorkspaceChild $stagePath "_stage" | Out-Null
Assert-WorkspaceChild $zipPath | Out-Null

if (Test-Path -LiteralPath $stagePath) {
    Remove-Item -LiteralPath $stagePath -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null

$rootFiles = @(
    "README.md",
    "START-HERE.md",
    "NEW-MACHINE-START.md",
    "Install-Custom-Appearance-To-Steam.bat",
    "Manage-Custom-Appearance-Assets.bat",
    "fantasybro-skill-book-and-shadow-walk..md"
)
foreach ($relative in $rootFiles) {
    $source = Join-Path $root $relative
    if (!(Test-Path -LiteralPath $source)) {
        throw "Missing required root file: $relative"
    }
    Copy-Item -LiteralPath $source -Destination (Join-Path $stageRoot $relative)
}

$sourceDirs = @(
    "asset_repo",
    "codex-skills",
    "docs",
    "mod_source",
    "reports",
    "tools",
    "vendor",
    "_tools"
)
foreach ($relative in $sourceDirs) {
    $source = Join-Path $root $relative
    if (!(Test-Path -LiteralPath $source)) {
        throw "Missing required directory: $relative"
    }
    Copy-Item -LiteralPath $source -Destination (Join-Path $stageRoot $relative) -Recurse
}
$referenceTargetDir = Join-Path $stageRoot $referenceDirName
New-Item -ItemType Directory -Force -Path $referenceTargetDir | Out-Null
Copy-Item -LiteralPath $referenceSource.FullName -Destination $referenceTargetDir

$gamePackSource = Join-Path $root "build\custom_appearance\mod_bb_custom_appearance.zip"
if (!(Test-Path -LiteralPath $gamePackSource)) {
    throw "Missing current game pack: $gamePackSource"
}
$gamePackTargetDir = Join-Path $stageRoot "build\custom_appearance"
New-Item -ItemType Directory -Force -Path $gamePackTargetDir | Out-Null
Copy-Item -LiteralPath $gamePackSource -Destination $gamePackTargetDir

$forbidden = @(Get-ChildItem -LiteralPath $stageRoot -File -Recurse -Force | Where-Object {
    $_.Name -like "*.bbca-backup" -or
    $_.Name -like "*.bbca-disabled*" -or
    $_.Name -eq "log.html" -or
    $_.Extension -eq ".sav"
})
if ($forbidden.Count -ne 0) {
    throw "Forbidden files entered staging: $($forbidden.FullName -join ', ')"
}

$gamePackHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $gamePackSource).Hash
$referencePath = Join-Path $referenceTargetDir $referenceArchiveName
$referenceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $referencePath).Hash
$breditorPath = Join-Path $stageRoot "vendor\mod_hx_breditor_VANILLA-294-4-31-1664773426.zip"
$hooksPath = Join-Path $stageRoot "vendor\mod_hooks.zip-42-20-1-1621709174.zip"
$breditorHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $breditorPath).Hash
$hooksHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $hooksPath).Hash

$manifest = @(
    "BB-Custom engineering handoff",
    "Created: $([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss zzz'))",
    "Source workspace: $root",
    "",
    "Current game pack SHA-256: $gamePackHash",
    "FantasyBro source-reference SHA-256: $referenceHash",
    "Breditor vendor SHA-256: $breditorHash",
    "Mod Hooks vendor SHA-256: $hooksHash",
    "",
    "Included: source assets, mod source, docs, tools, vendor dependencies,",
    "portable Codex skill, current installable game pack, reports, and the",
    "FantasyBro source-reference archive.",
    "",
    "Excluded: Steam/game files, saves, logs, translation packages, generated",
    "diagnostic/staging directories, and every .bbca-backup/.bbca-disabled file.",
    "",
    "Read NEW-MACHINE-START.md first."
)
$manifest | Set-Content -LiteralPath (Join-Path $stageRoot "HANDOFF-MANIFEST.txt") -Encoding UTF8

$sumFiles = @(Get-ChildItem -LiteralPath $stageRoot -File -Recurse | Sort-Object FullName)
$sumLines = foreach ($file in $sumFiles) {
    $relative = $file.FullName.Substring($stageRoot.Length + 1).Replace("\", "/")
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
    "$hash  $relative"
}
$sumLines | Set-Content -LiteralPath (Join-Path $stageRoot "HANDOFF-SHA256SUMS.txt") -Encoding UTF8

New-Item -ItemType Directory -Force -Path $outPath | Out-Null
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
[IO.Compression.ZipFile]::CreateFromDirectory(
    $stagePath,
    $zipPath,
    [IO.Compression.CompressionLevel]::Optimal,
    $false
)

$archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $entryNames = @($archive.Entries | ForEach-Object { $_.FullName.Replace("\", "/") })
    foreach ($required in @(
        "BB-Custom/START-HERE.md",
        "BB-Custom/NEW-MACHINE-START.md",
        "BB-Custom/HANDOFF-MANIFEST.txt",
        "BB-Custom/HANDOFF-SHA256SUMS.txt",
        "BB-Custom/build/custom_appearance/mod_bb_custom_appearance.zip",
        "BB-Custom/codex-skills/battle-brothers-skill-development/SKILL.md",
        ("BB-Custom/" + $referenceDirName + "/" + $referenceArchiveName)
    )) {
        if ($required -notin $entryNames) {
            throw "Handoff ZIP is missing: $required"
        }
    }
    $badEntries = @($entryNames | Where-Object {
        $_ -match "(?i)\.bbca-backup$|\.bbca-disabled|(^|/)log\.html$|\.sav$|steam_breditor_compat_stage|analysis_shieldwall_bug|reference_analysis"
    })
    if ($badEntries.Count -ne 0) {
        throw "Forbidden handoff entries: $($badEntries -join ', ')"
    }
}
finally {
    $archive.Dispose()
}

$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash
"$zipHash  $FileName" | Set-Content -LiteralPath $sidecarPath -Encoding ASCII

Remove-Item -LiteralPath $stagePath -Recurse -Force

$item = Get-Item -LiteralPath $zipPath
Write-Host "Built $zipPath"
Write-Host "Size: $($item.Length)"
Write-Host "SHA-256: $zipHash"
Write-Host "Sidecar: $sidecarPath"
