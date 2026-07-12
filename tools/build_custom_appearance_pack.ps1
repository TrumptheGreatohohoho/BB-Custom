param(
    [string]$Repository = "asset_repo/custom_appearance",
    [string]$OutDir = "build/custom_appearance",
    [string]$Bbrusher = "_tools/bbros/bin/bbrusher.exe",
    [string]$ModSource = "mod_source/bb_custom_appearance"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = (Resolve-Path ".").Path
$repoPath = Resolve-Path (Join-Path $root $Repository)
$outPath = Join-Path $root $OutDir
$bbrusherPath = Resolve-Path (Join-Path $root $Bbrusher)
$modSourcePath = Resolve-Path (Join-Path $root $ModSource)
$manifestPath = Join-Path $repoPath "manifest.json"

if (!(Test-Path -LiteralPath $manifestPath)) {
    throw "Missing manifest: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$stage = Join-Path $outPath "_stage"
$input = Join-Path $outPath "_bbrusher_input"
$modRoot = Join-Path $stage "mod"
$brushPath = Join-Path $modRoot $manifest.brushPath
$gfxRoot = $modRoot
$supportedRoles = @("head", "hair", "beard", "body", "tattoo_head", "tattoo_body")

function Assert-TransparentPng([string]$Path, [string]$SpriteId) {
    if ([IO.Path]::GetExtension($Path).ToLowerInvariant() -ne ".png") {
        throw "Sprite source must be a PNG: $SpriteId ($Path)"
    }

    $bitmap = [Drawing.Bitmap]::new($Path)
    try {
        if ($bitmap.Width -lt 1 -or $bitmap.Height -lt 1 -or $bitmap.Width -gt 512 -or $bitmap.Height -gt 512) {
            throw "Sprite image dimensions must be between 1 and 512 pixels: $SpriteId is $($bitmap.Width)x$($bitmap.Height)"
        }

        $hasOpaquePixel = $false
        $hasTransparentPixel = $false
        for ($y = 0; $y -lt $bitmap.Height; $y++) {
            for ($x = 0; $x -lt $bitmap.Width; $x++) {
                $alpha = $bitmap.GetPixel($x, $y).A
                if ($alpha -eq 0) { $hasTransparentPixel = $true }
                else { $hasOpaquePixel = $true }
            }
        }
        if (!$hasOpaquePixel) { throw "Sprite image is fully transparent: $SpriteId" }
        if (!$hasTransparentPixel) { throw "Sprite image must have a transparent background: $SpriteId" }
    }
    finally {
        $bitmap.Dispose()
    }
}

Remove-Item -LiteralPath $outPath -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $input | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $brushPath) | Out-Null
Copy-Item -Path (Join-Path $modSourcePath "*") -Destination $modRoot -Recurse -Force

$xml = New-Object System.Xml.XmlDocument
$brush = $xml.CreateElement("brush")
$brush.SetAttribute("name", [string]$manifest.atlasPath)
$brush.SetAttribute("version", "17")
$xml.AppendChild($brush) | Out-Null

foreach ($sprite in $manifest.sprites) {
    if ($sprite.id -notmatch "^[A-Za-z0-9_]+$") {
        throw "Sprite id must contain only letters, numbers, and underscores: $($sprite.id)"
    }
    if ($sprite.role -notin $supportedRoles) {
        throw "Unsupported role for $($sprite.id): $($sprite.role)"
    }

    $source = Join-Path $repoPath $sprite.source
    if (!(Test-Path -LiteralPath $source)) {
        throw "Missing sprite image for $($sprite.id): $source"
    }
    Assert-TransparentPng $source $sprite.id

    $targetRel = $sprite.source -replace "/", "\"
    $target = Join-Path $input $targetRel
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $source -Destination $target -Force

    $node = $xml.CreateElement("sprite")
    foreach ($prop in $sprite.PSObject.Properties) {
        if ($prop.Name -in @("source", "role", "label")) {
            continue
        }
        $attrName = if ($prop.Name -eq "source") { "img" } else { $prop.Name }
        $node.SetAttribute($attrName, [string]$prop.Value)
    }
    $node.SetAttribute("img", $targetRel)
    $brush.AppendChild($node) | Out-Null
}

$catalogEntries = foreach ($sprite in $manifest.sprites) {
    $label = if ($sprite.label) { [string]$sprite.label } else { [string]$sprite.id }
    $safeLabel = $label.Replace("\", "\\").Replace('"', '\"')
    "    { ID = `"$($sprite.id)`", Role = `"$($sprite.role)`", Label = `"$safeLabel`" }"
}
$catalogBlock = "::BBCA_Catalog <- [`n" + ($catalogEntries -join ",`n") + "`n];"
$catalogScript = Join-Path $modRoot "scripts/!mods_preload/mod_bb_custom_appearance.nut"
$catalogTemplate = [System.IO.File]::ReadAllText($catalogScript)
if (!$catalogTemplate.Contains("// __BBCA_CATALOG__")) {
    throw "Missing catalog placeholder in $catalogScript"
}
[System.IO.File]::WriteAllText(
    $catalogScript,
    $catalogTemplate.Replace("// __BBCA_CATALOG__", $catalogBlock),
    [System.Text.UTF8Encoding]::new($false)
)

$metadataPath = Join-Path $input "metadata.xml"
$settings = New-Object System.Xml.XmlWriterSettings
$settings.Indent = $true
$settings.Encoding = [System.Text.Encoding]::UTF8
$writer = [System.Xml.XmlWriter]::Create($metadataPath, $settings)
$xml.Save($writer)
$writer.Close()

& $bbrusherPath pack --gfxPath $gfxRoot $brushPath $input
if ($LASTEXITCODE -ne 0) {
    throw "bbrusher failed with exit code $LASTEXITCODE"
}

Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $modRoot "custom_appearance_manifest.json") -Force

$zipPath = Join-Path $outPath ("mod_" + $manifest.packName + ".zip")
Compress-Archive -Path (Join-Path $modRoot "*") -DestinationPath $zipPath -Force

Write-Host "Built $zipPath"
