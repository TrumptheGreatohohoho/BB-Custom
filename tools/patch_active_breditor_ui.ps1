param(
    [string]$GameDir = "D:\games\Battle Brothers v1.5.0.15",
    [string]$UiArchiveName = "",
    [switch]$Restore
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = (Resolve-Path ".").Path
$dataDir = Join-Path $GameDir "data"
if ([string]::IsNullOrWhiteSpace($UiArchiveName)) {
    $matches = @(Get-ChildItem -LiteralPath $dataDir -File | Where-Object { $_.Name -like "*data_cn_u_20240303.zip" })
    if ($matches.Count -ne 1) {
        throw "Expected exactly one active Breditor UI archive ending in data_cn_u_20240303.zip under $dataDir"
    }
    $archivePath = $matches[0].FullName
}
else {
    $archivePath = Join-Path $dataDir $UiArchiveName
}
$backupPath = "$archivePath.bbca-backup"

if ($Restore) {
    if (!(Test-Path -LiteralPath $backupPath)) {
        throw "Backup was not found: $backupPath"
    }
    Copy-Item -LiteralPath $backupPath -Destination $archivePath -Force
    Write-Host "Restored $archivePath from backup"
    exit 0
}

if (!(Test-Path -LiteralPath $archivePath)) {
    throw "Active Breditor UI archive was not found: $archivePath"
}

if (!(Test-Path -LiteralPath $backupPath)) {
    Copy-Item -LiteralPath $archivePath -Destination $backupPath
    Write-Host "Created backup $backupPath"
}

$cssPath = Join-Path $root "mod_source\bb_custom_appearance\ui\mods\bb_custom_appearance.css"
$jsPath = Join-Path $root "mod_source\bb_custom_appearance\ui\mods\bb_custom_appearance.js"
$translationCompatPath = Join-Path $root "mod_source\bb_custom_appearance\ui\bbca_cn_ui_compat.js"
$worldNamesPath = Join-Path $root "mod_source\bb_custom_appearance\ui\world_names.js"
$manifestPath = Join-Path $root "asset_repo\custom_appearance\manifest.json"
$resourceStage = Join-Path $root "build\custom_appearance\_stage\mod"
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$brushResourcePath = Join-Path $resourceStage $manifest.brushPath
$atlasResourcePath = Join-Path $resourceStage $manifest.atlasPath
$resourcePackPath = Join-Path $root ("build\custom_appearance\mod_" + $manifest.packName + ".zip")
$usePackResources = !(Test-Path -LiteralPath $brushResourcePath) -or !(Test-Path -LiteralPath $atlasResourcePath)
foreach ($path in @($cssPath, $jsPath, $translationCompatPath, $worldNamesPath, $manifestPath)) {
    if (!(Test-Path -LiteralPath $path)) {
        throw "Missing UI patch file: $path"
    }
}
if ($usePackResources -and !(Test-Path -LiteralPath $resourcePackPath)) {
    throw "Missing Custom Appearance resource pack: $resourcePackPath"
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

function Set-ZipText($Archive, [string]$Name, [string]$Text) {
    $existing = $Archive.GetEntry($Name)
    if ($null -ne $existing) {
        $existing.Delete()
    }

    $entry = $Archive.CreateEntry($Name, [System.IO.Compression.CompressionLevel]::Optimal)
    $writer = [System.IO.StreamWriter]::new($entry.Open(), [System.Text.UTF8Encoding]::new($false))
    try {
        $writer.Write($Text)
    }
    finally {
        $writer.Dispose()
    }
}

function Set-ZipFile($Archive, [string]$Name, [string]$SourcePath) {
    $existing = $Archive.GetEntry($Name)
    if ($null -ne $existing) {
        $existing.Delete()
    }

    $entry = $Archive.CreateEntry($Name, [System.IO.Compression.CompressionLevel]::Optimal)
    $input = [System.IO.File]::OpenRead($SourcePath)
    $output = $entry.Open()
    try {
        $input.CopyTo($output)
    }
    finally {
        $output.Dispose()
        $input.Dispose()
    }
}

function Set-ZipArchiveEntry($Archive, [string]$Name, $SourceArchive, [string]$SourceName) {
    $normalizedSourceName = $SourceName -replace "\\", "/"
    $sourceEntry = $SourceArchive.Entries | Where-Object {
        ($_.FullName -replace "\\", "/") -eq $normalizedSourceName
    } | Select-Object -First 1
    if ($null -eq $sourceEntry) {
        throw "Resource $SourceName was not found in the Custom Appearance pack"
    }

    $existing = $Archive.GetEntry($Name)
    if ($null -ne $existing) {
        $existing.Delete()
    }

    $entry = $Archive.CreateEntry($Name, [System.IO.Compression.CompressionLevel]::Optimal)
    $input = $sourceEntry.Open()
    $output = $entry.Open()
    try {
        $input.CopyTo($output)
    }
    finally {
        $output.Dispose()
        $input.Dispose()
    }
}

function Escape-SquirrelString([string]$Value) {
    return $Value.Replace("\", "\\").Replace('"', '\"').Replace("`r", "").Replace("`n", "\n")
}

function Get-BbcaBackend([string]$ManifestFile) {
    $manifest = Get-Content -LiteralPath $ManifestFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $supportedRoles = @("head", "hair", "beard", "body", "tattoo_head", "tattoo_body")
    $entries = foreach ($sprite in $manifest.sprites) {
        if ($sprite.id -notmatch "^[A-Za-z0-9_]+$") {
            throw "Sprite id must contain only letters, numbers, and underscores: $($sprite.id)"
        }
        if ($sprite.role -notin $supportedRoles) {
            throw "Unsupported appearance role: $($sprite.role)"
        }

        $label = if ($sprite.label) { [string]$sprite.label } else { [string]$sprite.id }
        '                { ID = "' + (Escape-SquirrelString ([string]$sprite.id)) + '", Role = "' +
            (Escape-SquirrelString ([string]$sprite.role)) + '", Label = "' + (Escape-SquirrelString $label) + '" }'
    }

    $catalog = $entries -join ",`r`n"
    return @"
    // BBCA_BACKEND_BEGIN
    function getCustomAppearanceCatalog()
    {
        return [
$catalog
        ];
    }

    function getCustomAppearance( _result )
    {
        if (_result == null || !("BroId" in _result))
        {
            return null;
        }

        foreach (bro in this.World.getPlayerRoster().getAll())
        {
            if (bro.getID() == _result.BroId)
            {
                return {
                    BroId = bro.getID(),
                    ImagePath = bro.getImagePath(),
                    Appearance = this.bbca_getAppearance(bro)
                };
            }
        }
        return null;
    }

    function applyCustomAppearance( _result )
    {
        if (_result == null || !("BroId" in _result) || !("Role" in _result) || !("BrushId" in _result))
        {
            return { Error = "Invalid appearance request." };
        }
        local isNoBeard = _result.Role == "beard" && _result.BrushId == "";
        if (!isNoBeard && !this.bbca_isCatalogBrush(_result.Role, _result.BrushId))
        {
            return { Error = "The selected brush is not in the custom appearance catalog." };
        }

        foreach (bro in this.World.getPlayerRoster().getAll())
        {
            if (bro.getID() != _result.BroId)
            {
                continue;
            }

            if (isNoBeard)
            {
                if (bro.getSprite("beard").HasBrush)
                {
                    bro.getSprite("beard").resetBrush();
                }
            }
            else if (_result.Role == "body")
            {
                bro.m.Body = _result.BrushId;
                bro.getSprite("body").setBrush(_result.BrushId);
            }
            else
            {
                bro.getSprite(_result.Role).setBrush(_result.BrushId);
            }

            if (_result.Role == "beard" && bro.getSprite("beard_top").HasBrush)
            {
                bro.getSprite("beard_top").resetBrush();
            }

            bro.getSkills().update();
            return {
                BroId = bro.getID(),
                ImagePath = bro.getImagePath(),
                Appearance = this.bbca_getAppearance(bro)
            };
        }
        return { Error = "Brother was not found in the player roster." };
    }

    function getCustomSkillCatalog()
    {
        return ::BBCA_SkillCatalog;
    }

    function getCustomSkillState( _result )
    {
        if (_result == null || !("BroId" in _result))
        {
            return { Error = "Invalid brother selection." };
        }

        local bro = this.bbca_findBrother(_result.BroId);
        if (bro == null)
        {
            return { Error = "Brother was not found in the player roster." };
        }

        local skills = [];
        foreach (definition in ::BBCA_SkillCatalog)
        {
            local container = bro.getSkills();
            local hasSkill = container.hasSkill(definition.ID);
            local skill = hasSkill ? container.getSkillByID(definition.ID) : null;
            local config = ("ConfigID" in definition) ? container.getSkillByID(definition.ConfigID) : null;
            skills.push({
                ID = definition.ID,
                HasSkill = hasSkill,
                Settings = this.bbca_getCustomSkillSettings(definition, config == null ? skill : config)
            });
        }

        return { BroId = bro.getID(), Skills = skills };
    }

    function applyCustomSkill( _result )
    {
        if (_result == null || !("BroId" in _result) || !("SkillId" in _result) || !("Settings" in _result))
        {
            return { Error = "Invalid skill request." };
        }

        local definition = this.bbca_getCustomSkillDefinition(_result.SkillId);
        if (definition == null)
        {
            return { Error = "The selected skill is not in the custom skill catalog." };
        }

        local bro = this.bbca_findBrother(_result.BroId);
        if (bro == null)
        {
            return { Error = "Brother was not found in the player roster." };
        }

        local settings = this.bbca_validateCustomSkillSettings(definition, _result.Settings);
        if ("Error" in settings)
        {
            return settings;
        }

        local container = bro.getSkills();
        local wasAlreadyGranted = container.hasSkill(definition.ID);
        local skill = wasAlreadyGranted ? container.getSkillByID(definition.ID) : null;
        local isNewSkill = skill == null;
        if (isNewSkill)
        {
            if (wasAlreadyGranted)
            {
                container.removeByID(definition.ID);
            }
            skill = this.new(definition.Script);
            container.add(skill);
        }

        local config = null;
        if ("ConfigID" in definition && "ConfigScript" in definition)
        {
            config = container.getSkillByID(definition.ConfigID);
            if (config == null)
            {
                config = this.new(definition.ConfigScript);
                container.add(config);
            }
            foreach (parameter in definition.Parameters)
            {
                config.m[parameter.Key] = settings[parameter.Key];
            }
        }

        if (config == null)
        {
            foreach (parameter in definition.Parameters)
            {
                skill.m[parameter.Key] = settings[parameter.Key];
            }
        }

        if ("Cooldown" in skill.m && "Skillcool" in skill.m)
        {
            local configuredCooldown = "Cooldown" in settings ? settings.Cooldown : skill.m.Cooldown;
            if (isNewSkill)
            {
                skill.m.Skillcool = configuredCooldown;
            }
            else if (skill.m.Skillcool > configuredCooldown)
            {
                skill.m.Skillcool = configuredCooldown;
            }
        }

        container.update();

        return {
            BroId = bro.getID(),
            SkillId = definition.ID,
            HasSkill = true,
            WasAlreadyGranted = wasAlreadyGranted,
            Settings = this.bbca_getCustomSkillSettings(definition, config == null ? skill : config)
        };
    }

    function bbca_findBrother( _broId )
    {
        foreach (bro in this.World.getPlayerRoster().getAll())
        {
            if (bro.getID() == _broId)
            {
                return bro;
            }
        }
        return null;
    }

    function bbca_getCustomSkillDefinition( _skillId )
    {
        foreach (definition in ::BBCA_SkillCatalog)
        {
            if (definition.ID == _skillId)
            {
                return definition;
            }
        }
        return null;
    }

    function bbca_getCustomSkillSettings( _definition, _skill )
    {
        local settings = { };
        foreach (parameter in _definition.Parameters)
        {
            if ("Type" in parameter && parameter.Type == "bool")
            {
                settings[parameter.Key] <- _skill == null ? parameter.Default : _skill.m[parameter.Key];
                continue;
            }
            settings[parameter.Key] <- _skill == null ? parameter.Default : _skill.m[parameter.Key];
        }
        return settings;
    }

    function bbca_validateCustomSkillSettings( _definition, _requestedSettings )
    {
        local settings = { };
        foreach (parameter in _definition.Parameters)
        {
            if (!(parameter.Key in _requestedSettings))
            {
                return { Error = "Missing value for " + parameter.Key + "." };
            }

            local rawValue = _requestedSettings[parameter.Key];
            if ("Type" in parameter && parameter.Type == "bool")
            {
                if (typeof rawValue != "bool")
                {
                    return { Error = "Invalid value for " + parameter.Key + "." };
                }
                settings[parameter.Key] <- rawValue;
                continue;
            }
            if (typeof rawValue != "integer" && typeof rawValue != "float")
            {
                return { Error = "Invalid value for " + parameter.Key + "." };
            }

            local value = rawValue.tointeger();
            if (value < parameter.Min || value > parameter.Max)
            {
                return { Error = parameter.Key + " must be between " + parameter.Min + " and " + parameter.Max + "." };
            }
            settings[parameter.Key] <- value;
        }

        if ("MinRange" in settings && "MaxRange" in settings && settings.MinRange > settings.MaxRange)
        {
            return { Error = "MinRange cannot exceed MaxRange." };
        }
        return settings;
    }

    function bbca_getAppearance( _bro )
    {
        local result = { };
        foreach (slot in ["body", "head", "hair", "beard", "tattoo_head", "tattoo_body"])
        {
            result[slot] <- _bro.getSprite(slot).HasBrush ? _bro.getSprite(slot).getBrush().Name : "";
        }
        return result;
    }

    function bbca_isCatalogBrush( _role, _brushId )
    {
        foreach (entry in this.getCustomAppearanceCatalog())
        {
            if (entry.Role == _role && entry.ID == _brushId)
            {
                return true;
            }
        }
        return false;
    }
    // BBCA_BACKEND_END
"@
}

function Add-BbcaBackend([string]$Script, [string]$Backend) {
    $beginMarker = "// BBCA_BACKEND_BEGIN"
    $endMarker = "// BBCA_BACKEND_END"
    $begin = $Script.IndexOf($beginMarker, [System.StringComparison]::Ordinal)
    if ($begin -ge 0) {
        $end = $Script.IndexOf($endMarker, $begin, [System.StringComparison]::Ordinal)
        if ($end -lt 0) {
            throw "Existing BBCA backend marker has no end marker"
        }
        $end += $endMarker.Length
        return $Script.Substring(0, $begin) + $Backend + $Script.Substring($end)
    }

    $closing = $Script.LastIndexOf("};", [System.StringComparison]::Ordinal)
    if ($closing -lt 0) {
        throw "Could not find the end of world_breditor_screen.nut"
    }
    return $Script.Insert($closing, "`r`n$Backend`r`n")
}

$resourceArchive = $null
if ($usePackResources) {
    $resourceArchive = [System.IO.Compression.ZipFile]::OpenRead($resourcePackPath)
}

$archive = [System.IO.Compression.ZipFile]::Open($archivePath, [System.IO.Compression.ZipArchiveMode]::Update)
try {
    $mainEntry = $archive.GetEntry("ui/main.html")
    if ($null -eq $mainEntry) {
        throw "ui/main.html was not found in $archivePath"
    }

    $mainHtml = Read-ZipText $mainEntry
    $cssTag = '<link rel="stylesheet" type="text/css" href="mods/bb_custom_appearance.css" />'
    $jsTag = '<script type="text/javascript" src="mods/bb_custom_appearance.js"></script>'
    $worldNamesTag = '<script type="text/javascript" src="world_names.js"></script>'
    $translationCompatTag = '<script type="text/javascript" src="bbca_cn_ui_compat.js"></script>'

    if (!$mainHtml.Contains($cssTag)) {
        $cssAnchor = '<link rel="stylesheet" type="text/css" href="mods/world_breditor_screen.css" />'
        if (!$mainHtml.Contains($cssAnchor)) {
            throw "Could not find the Breditor CSS entry in ui/main.html"
        }
        $mainHtml = $mainHtml.Replace($cssAnchor, "$cssAnchor`r`n`t`t$cssTag")
    }

    if (!$mainHtml.Contains($jsTag)) {
        $jsAnchor = '<script type="text/javascript" src="mods/world_breditor_screen.js"></script>'
        if (!$mainHtml.Contains($jsAnchor)) {
            throw "Could not find the Breditor JS entry in ui/main.html"
        }
        $mainHtml = $mainHtml.Replace($jsAnchor, "$jsAnchor`r`n`t`t$jsTag")
    }

    if (!$mainHtml.Contains($translationCompatTag)) {
        $translationCompatAnchor = '<script type="text/javascript" src="mod_hooks.js"></script>'
        if (!$mainHtml.Contains($translationCompatAnchor)) {
            throw "Could not find the Mod Hooks JS entry in ui/main.html"
        }
        $mainHtml = $mainHtml.Replace($translationCompatAnchor, "$translationCompatTag`r`n`t`t$translationCompatAnchor")
    }

    if (!$mainHtml.Contains($worldNamesTag)) {
        if (!$mainHtml.Contains($translationCompatTag)) {
            throw "Could not find the BBCA Chinese UI compatibility entry in ui/main.html"
        }
        $mainHtml = $mainHtml.Replace($translationCompatTag, "$worldNamesTag`r`n`t`t$translationCompatTag")
    }

    Set-ZipText $archive "ui/main.html" $mainHtml
    Set-ZipFile $archive "ui/mods/bb_custom_appearance.css" $cssPath
    Set-ZipFile $archive "ui/mods/bb_custom_appearance.js" $jsPath
    Set-ZipFile $archive "ui/world_names.js" $worldNamesPath
    Set-ZipFile $archive "ui/bbca_cn_ui_compat.js" $translationCompatPath
    if ($usePackResources) {
        Set-ZipArchiveEntry $archive ($manifest.brushPath -replace "\\", "/") $resourceArchive ($manifest.brushPath -replace "\\", "/")
        Set-ZipArchiveEntry $archive ($manifest.atlasPath -replace "\\", "/") $resourceArchive ($manifest.atlasPath -replace "\\", "/")
    }
    else {
        Set-ZipFile $archive ($manifest.brushPath -replace "\\", "/") $brushResourcePath
        Set-ZipFile $archive ($manifest.atlasPath -replace "\\", "/") $atlasResourcePath
    }

    $screenEntry = $archive.GetEntry("scripts/ui/screens/world/world_breditor_screen.nut")
    if ($null -eq $screenEntry) {
        throw "Breditor backend script was not found in $archivePath"
    }
    $screenScript = Read-ZipText $screenEntry
    Set-ZipText $archive "scripts/ui/screens/world/world_breditor_screen.nut" (Add-BbcaBackend $screenScript (Get-BbcaBackend $manifestPath))
}
finally {
    $archive.Dispose()
    if ($null -ne $resourceArchive) {
        $resourceArchive.Dispose()
    }
}

Write-Host "Patched Breditor UI archive $archivePath"
