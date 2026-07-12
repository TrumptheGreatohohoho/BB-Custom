param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,
    [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$resolved = (Resolve-Path -LiteralPath $InputPath).ProviderPath
$records = [System.Collections.Generic.List[object]]::new()

function Get-Field([string]$Text, [string]$Field) {
    $match = [regex]::Match($Text, "this\.m\.$Field\s*=\s*([^;]+);")
    if (!$match.Success) {
        return ""
    }
    return $match.Groups[1].Value.Trim().Trim('"')
}

function Convert-Skill([string]$Path, [string]$Text) {
    $normalized = $Path.Replace([char]92, [char]47)
    $dependencies = @([regex]::Matches($Text, 'new\("([^"]+)"\)') | ForEach-Object {
        $_.Groups[1].Value
    } | Sort-Object -Unique)
    $callbacks = @([regex]::Matches($Text, 'function\s+(on[A-Za-z0-9_]+|isUsable|isHidden|getTooltip)\s*\(') |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $fileBase = [IO.Path]::GetFileNameWithoutExtension($normalized)
    $id = Get-Field $Text "ID"
    $expected = if ($normalized -match '(?:^|/)scripts/skills/([^/]+)/') {
        $category = $Matches[1]
        if ($category -eq "actives") { "actives.$fileBase" }
        elseif ($category -eq "effects") { "effects.$fileBase" }
        else { "" }
    }
    else {
        ""
    }

    [ordered]@{
        path = $normalized
        id = $id
        expectedId = $expected
        idMismatch = [bool]($expected -and $id -and $expected -ne $id)
        name = Get-Field $Text "Name"
        type = Get-Field $Text "Type"
        isActive = Get-Field $Text "IsActive"
        isAttack = Get-Field $Text "IsAttack"
        isSerialized = Get-Field $Text "IsSerialized"
        actionPointCost = Get-Field $Text "ActionPointCost"
        fatigueCost = Get-Field $Text "FatigueCost"
        minRange = Get-Field $Text "MinRange"
        maxRange = Get-Field $Text "MaxRange"
        icon = Get-Field $Text "Icon"
        callbacks = $callbacks
        dependencies = $dependencies
        usesDelayedEvents = $Text.Contains("Time.scheduleEvent")
        spawnsEntity = $Text.Contains("Tactical.spawnEntity")
    }
}

if ((Get-Item -LiteralPath $resolved) -is [System.IO.DirectoryInfo]) {
    $base = $resolved.TrimEnd([IO.Path]::DirectorySeparatorChar)
    foreach ($file in Get-ChildItem -LiteralPath $resolved -Recurse -File -Filter "*.nut") {
        $relative = $file.FullName.Substring($base.Length + 1)
        if ($relative.Replace([char]92, [char]47) -notmatch '(^|/)scripts/skills/') {
            continue
        }
        $text = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
        $records.Add((Convert-Skill $relative $text))
    }
}
else {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($resolved)
    try {
        foreach ($entry in $zip.Entries) {
            $path = $entry.FullName.Replace([char]92, [char]47)
            if ($path -notmatch '(^|/)scripts/skills/.*\.nut$') {
                continue
            }
            $reader = [IO.StreamReader]::new($entry.Open(), [Text.Encoding]::UTF8, $true)
            try {
                $text = $reader.ReadToEnd()
            }
            finally {
                $reader.Dispose()
            }
            $records.Add((Convert-Skill $path $text))
        }
    }
    finally {
        $zip.Dispose()
    }
}

$result = [ordered]@{
    input = $resolved
    generatedAt = (Get-Date).ToString("s")
    count = $records.Count
    idMismatchCount = @($records | Where-Object { $_.idMismatch }).Count
    delayedEventCount = @($records | Where-Object { $_.usesDelayedEvents }).Count
    entitySpawnerCount = @($records | Where-Object { $_.spawnsEntity }).Count
    skills = @($records | Sort-Object path)
}

$json = $result | ConvertTo-Json -Depth 8
if ([string]::IsNullOrWhiteSpace($OutFile)) {
    $json
}
else {
    $output = [IO.Path]::GetFullPath($OutFile)
    [IO.Directory]::CreateDirectory((Split-Path -Parent $output)) | Out-Null
    [IO.File]::WriteAllText($output, $json, [Text.UTF8Encoding]::new($false))
    Write-Host "Wrote $output"
}
