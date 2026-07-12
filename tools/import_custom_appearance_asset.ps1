[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet("head", "hair", "beard", "body")]
    [string]$Role,

    [ValidatePattern("^bbca_[A-Za-z0-9_]+$")]
    [string]$Id = "",

    [string]$Label = "",

    [switch]$Install,

    [string]$GameDir = "D:\games\steam\steamapps\common\Battle Brothers"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$repoPath = Join-Path $root "asset_repo\custom_appearance"
$manifestPath = Join-Path $repoPath "manifest.json"

if ($Install -and (Get-Process -Name "BattleBrothers" -ErrorAction SilentlyContinue)) {
    throw "BattleBrothers.exe is running. Close the game before using -Install; no files were changed."
}

if (!(Test-Path -LiteralPath $manifestPath)) {
    throw "Missing manifest: $manifestPath"
}

$sourcePath = Resolve-Path -LiteralPath $InputPath -ErrorAction Stop
if ([IO.Path]::GetExtension($sourcePath.Path).ToLowerInvariant() -ne ".png") {
    throw "Input must be a .png file: $sourcePath"
}

$signature = [IO.File]::ReadAllBytes($sourcePath.Path)
if ($signature.Length -lt 8 -or ([BitConverter]::ToString($signature[0..7]) -ne "89-50-4E-47-0D-0A-1A-0A")) {
    throw "Input is not a valid PNG file: $sourcePath"
}

$manifestText = [IO.File]::ReadAllText($manifestPath, [Text.Encoding]::UTF8)
$manifest = $manifestText | ConvertFrom-Json
$template = @($manifest.sprites | Where-Object { $_.role -eq $Role } | Select-Object -First 1)
if ($template.Count -ne 1) {
    throw "The manifest has no $Role template. Keep at least one validated sample asset for each supported role."
}

$templatePath = Join-Path $repoPath $template[0].source
if (!(Test-Path -LiteralPath $templatePath)) {
    throw "The $Role template image is missing: $templatePath"
}

function Get-PngMetrics([string]$Path) {
    $bitmap = [Drawing.Bitmap]::new($Path)
    try {
        $hasOpaquePixel = $false
        $hasTransparentPixel = $false
        for ($y = 0; $y -lt $bitmap.Height; $y++) {
            for ($x = 0; $x -lt $bitmap.Width; $x++) {
                $alpha = $bitmap.GetPixel($x, $y).A
                if ($alpha -eq 0) { $hasTransparentPixel = $true }
                else { $hasOpaquePixel = $true }
            }
        }
        return [pscustomobject]@{
            Width = $bitmap.Width
            Height = $bitmap.Height
            HasOpaquePixel = $hasOpaquePixel
            HasTransparentPixel = $hasTransparentPixel
        }
    }
    finally {
        $bitmap.Dispose()
    }
}

$inputMetrics = Get-PngMetrics $sourcePath.Path
$templateMetrics = Get-PngMetrics $templatePath
if ($inputMetrics.Width -ne $templateMetrics.Width -or $inputMetrics.Height -ne $templateMetrics.Height) {
    throw "Invalid $Role image size: got $($inputMetrics.Width)x$($inputMetrics.Height); expected $($templateMetrics.Width)x$($templateMetrics.Height), matching $($template[0].id)."
}
if (!$inputMetrics.HasOpaquePixel) {
    throw "The PNG is fully transparent and contains no visible pixels."
}
if (!$inputMetrics.HasTransparentPixel) {
    throw "The PNG must include a transparent background (alpha = 0) outside the artwork."
}

$existingIds = @($manifest.sprites | ForEach-Object { [string]$_.id })
if ([string]::IsNullOrWhiteSpace($Id)) {
    for ($number = 1; $number -le 999; $number++) {
        $candidate = "bbca_{0}_{1:D2}" -f $Role, $number
        if ($existingIds -notcontains $candidate) {
            $Id = $candidate
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($Id)) {
        throw "Could not allocate an unused ID for role $Role."
    }
}
if ($existingIds -contains $Id) {
    throw "Asset ID already exists: $Id"
}

if ([string]::IsNullOrWhiteSpace($Label)) {
    $Label = "Custom {0} {1}" -f $Role, ($Id -replace "^bbca_" -replace "^$Role`_")
}
if ($Label.Length -gt 48 -or $Label -notmatch "^[ -~]+$") {
    throw "Label must be 1-48 printable ASCII characters because the injected game UI does not reliably render non-ASCII labels."
}

$destinationFolder = if ($Role -eq "body") { "sprites/bodies" } else { "sprites/heads" }
$destinationRelative = "$destinationFolder/$Id.png"
$destinationPath = Join-Path $repoPath $destinationRelative
if (Test-Path -LiteralPath $destinationPath) {
    throw "Destination already exists: $destinationPath"
}

$newSprite = [ordered]@{
    id = $Id
    role = $Role
    label = $Label
    source = $destinationRelative
    offsetY = [string]$template[0].offsetY
    ic = [string]$template[0].ic
    width = [string]$template[0].width
    height = [string]$template[0].height
    left = [string]$template[0].left
    right = [string]$template[0].right
    top = [string]$template[0].top
    bottom = [string]$template[0].bottom
}

$manifest.sprites = @($manifest.sprites) + [pscustomobject]$newSprite
$newManifestText = $manifest | ConvertTo-Json -Depth 8
$newManifestText += [Environment]::NewLine
$copied = $false

try {
    if ($PSCmdlet.ShouldProcess($destinationPath, "Import $Role asset $Id")) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destinationPath) | Out-Null
        Copy-Item -LiteralPath $sourcePath.Path -Destination $destinationPath -ErrorAction Stop
        $copied = $true
    }
    if ($PSCmdlet.ShouldProcess($manifestPath, "Add $Id to the custom appearance manifest")) {
        [IO.File]::WriteAllText($manifestPath, $newManifestText, [Text.UTF8Encoding]::new($false))
    }
}
catch {
    if ($copied -and (Test-Path -LiteralPath $destinationPath)) {
        Remove-Item -LiteralPath $destinationPath -Force
    }
    throw
}

Write-Host "Imported $Id as ${Role}: $destinationRelative"
if ($WhatIfPreference) {
    Write-Host "WhatIf mode: no files were changed."
    exit 0
}

if ($Install) {
    Push-Location $root
    try {
        & (Join-Path $PSScriptRoot "build_custom_appearance_pack.ps1")
        if ($LASTEXITCODE -ne 0) { throw "Build failed with exit code $LASTEXITCODE" }
        & (Join-Path $PSScriptRoot "install_custom_appearance_pack.ps1") -GameDir $GameDir
        if ($LASTEXITCODE -ne 0) { throw "Install failed with exit code $LASTEXITCODE" }
    }
    finally {
        Pop-Location
    }
}
