[CmdletBinding()]
param(
    [string]$PackPath = "build/custom_appearance/mod_bb_custom_appearance.zip",
    [string]$GameDir = "D:\games\steam\steamapps\common\Battle Brothers",
    [string]$BreditorArchiveName = "mod_hx_breditor_VANILLA-294-4-31-1664773426.zip",
    [int]$ExpectedCatalogEntries = 14,
    [int]$ExpectedBrushNames = 18,
    [int]$ExpectedBackups = 5
)

# Static / binary acceptance checks for the Custom Appearance pack.
# These verify everything that can be proven WITHOUT launching the game.
# Anything requiring gameplay stays in 工程记录/待办与回归清单.md as 待人工回归.

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\")).Path
$packFull = Resolve-Path (Join-Path $root $PackPath)
$dataDir = Join-Path $GameDir "data"

$script:pass = 0
$script:fail = 0

function Check([string]$Name, [bool]$Condition, [string]$Detail = "") {
    if ($Condition) {
        $script:pass++
        Write-Host ("  PASS  {0}" -f $Name) -ForegroundColor Green
    }
    else {
        $script:fail++
        $msg = "  FAIL  {0}" -f $Name
        if ($Detail) { $msg += "  --> $Detail" }
        Write-Host $msg -ForegroundColor Red
    }
}

function Section([string]$Title) {
    Write-Host ""
    Write-Host ("== {0}" -f $Title) -ForegroundColor Cyan
}

function Read-ZipEntryText($Archive, [string]$EntryName) {
    # ZipArchive.GetEntry() is an exact-match lookup, but the pack is written by
    # Compress-Archive with backslash separators on Windows. Match on a normalised name.
    $want = $EntryName -replace '\\', '/'
    $entry = $Archive.Entries | Where-Object { ($_.FullName -replace '\\', '/') -eq $want } | Select-Object -First 1
    if ($null -eq $entry) { return $null }
    $reader = [System.IO.StreamReader]::new($entry.Open(), [System.Text.Encoding]::UTF8, $true)
    try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
}

function Get-EntryCount($Archive, [string]$EntryName) {
    return @($Archive.Entries | Where-Object { $_.FullName -replace '\\', '/' -eq $EntryName }).Count
}

$archive = [System.IO.Compression.ZipFile]::OpenRead($packFull)
try {
    $allPaths = @($archive.Entries | ForEach-Object { $_.FullName -replace '\\', '/' })

    Section "Pack identity"
    Write-Host ("  pack      : {0}" -f $packFull)
    $packItem = Get-Item $packFull
    $packHash = (Get-FileHash $packFull -Algorithm SHA256).Hash
    Write-Host ("  size      : {0}" -f $packItem.Length)
    Write-Host ("  sha256    : {0}" -f $packHash)

    Section "Custom appearance: derived brushes (2026-09-23 fix)"
    $brushEntry = $archive.Entries | Where-Object { $_.FullName -match 'bb_custom_appearance\.brush$' } | Select-Object -First 1
    Check "brush file present" ($null -ne $brushEntry)
    if ($brushEntry) {
        $ms = New-Object System.IO.MemoryStream
        $s = $brushEntry.Open(); $s.CopyTo($ms); $s.Close()
        $brushText = [System.Text.Encoding]::ASCII.GetString($ms.ToArray())
        $ms.Dispose()
        $brushNames = @([regex]::Matches($brushText, 'bbca_[A-Za-z0-9_]+') | ForEach-Object { $_.Value } | Sort-Object -Unique)
        Check ("brush name count = {0}" -f $ExpectedBrushNames) ($brushNames.Count -eq $ExpectedBrushNames) ("got {0}" -f $brushNames.Count)
        foreach ($derived in @('bbca_female_body_01_injured', 'bbca_female_body_02_injured', 'bbca_female_body_01_dead', 'bbca_female_body_02_dead')) {
            Check ("brush contains {0}" -f $derived) ($brushNames -contains $derived)
        }
    }

    Section "Custom appearance: catalog must stay user-facing only"
    $preload = Read-ZipEntryText $archive "scripts/!mods_preload/mod_bb_custom_appearance.nut"
    Check "preload script present" ($null -ne $preload)
    if ($preload) {
        $catBody = [regex]::Match($preload, '::BBCA_Catalog\s*<-\s*\[(.*?)\];', [System.Text.RegularExpressions.RegexOptions]::Singleline).Groups[1].Value
        $catIds = @([regex]::Matches($catBody, 'ID\s*=\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
        Check ("catalog entries = {0}" -f $ExpectedCatalogEntries) ($catIds.Count -eq $ExpectedCatalogEntries) ("got {0}" -f $catIds.Count)
        Check "catalog exposes no _injured/_dead brush" (@($catIds | Where-Object { $_ -match '_(injured|dead)$' }).Count -eq 0)
        Check "catalog placeholder was substituted" (-not $preload.Contains('// __BBCA_CATALOG__'))
        Check "catalog keeps bbca_female_body_01/02" (($catIds -contains 'bbca_female_body_01') -and ($catIds -contains 'bbca_female_body_02'))
    }

    Section "Lone Wolf roster cap 16"
    $lw = Read-ZipEntryText $archive "scripts/!mods_preload/mod_bbca_lone_wolf_roster_cap.nut"
    Check "hook present exactly once" ((Get-EntryCount $archive "scripts/!mods_preload/mod_bbca_lone_wolf_roster_cap.nut") -eq 1)
    if ($lw) {
        Check "sets BrothersMax = 16" ([regex]::IsMatch($lw, 'BrothersMax\s*=\s*16'))
        Check "sets BrothersMaxInCombat = 16" ([regex]::IsMatch($lw, 'BrothersMaxInCombat\s*=\s*16'))
        Check "calls the vanilla onInit" ($lw.Contains('onInit'))
        Check "does not touch BrothersScaleMax (enemy scaling)" (-not $lw.Contains('BrothersScaleMax'))
        Check "menu copy updated to 16" ($lw.Contains('16'))
    }

    Section "Hard Chance (normalized fatigue)"
    Check "skill present exactly once" ((Get-EntryCount $archive "scripts/skills/effects/bbca_hard_chance_skill.nut") -eq 1)
    $hc = Read-ZipEntryText $archive "scripts/skills/effects/bbca_hard_chance_skill.nut"
    if ($hc) {
        Check "clears fatigue at turn start (setFatigue(0))" ([regex]::IsMatch($hc, 'setFatigue\s*\(\s*0\s*\)'))
        Check "no FatigueRecoveryRate injection" (-not $hc.Contains('FatigueRecoveryRate'))
        Check "no forcedRecovery leftover" (-not $hc.Contains('forcedRecovery'))
    }
    $hcc = Read-ZipEntryText $archive "scripts/skills/effects/bbca_hard_chance_config_skill.nut"
    Check "config present" ($null -ne $hcc)
    if ($hcc) {
        Check "hard chance config serializes version 1" ([regex]::IsMatch($hcc, '_out\.writeI32\(\s*1\s*\)'))
        Check "exposes HardHitChance / HardEvasionChance" (($hcc.Contains('HardHitChance')) -and ($hcc.Contains('HardEvasionChance')))
    }

    Section "Aegis v6 + hooks"
    Check "negative immunity skill present exactly once" ((Get-EntryCount $archive "scripts/skills/effects/bbca_negative_immunity_skill.nut") -eq 1)
    $aegis = Read-ZipEntryText $archive "scripts/skills/effects/bbca_negative_immunity_skill.nut"
    if ($aegis) {
        Check "has StunPiercer" ($aegis.Contains('StunPiercer'))
        Check "has PassiveCounterattack" ($aegis.Contains('PassiveCounterattack'))
    }
    $cfg = Read-ZipEntryText $archive "scripts/skills/effects/bbca_negative_immunity_config_skill.nut"
    if ($cfg) {
        Check "serializes config version 6" ([regex]::IsMatch($cfg, '_out\.writeI32\(\s*6\s*\)'))
        Check "reads v6 branch" ([regex]::IsMatch($cfg, 'version\s*>=\s*6'))
        $compat = @(2..5 | Where-Object { [regex]::IsMatch($cfg, ("version\s*>=\s*" + $_)) })
        Check "keeps v1-v5 back-compat read branches" ($compat.Count -eq 4) ("found {0}/4" -f $compat.Count)
    }
    else { Check "negative immunity config present" $false }
    $pc = Read-ZipEntryText $archive "scripts/!mods_preload/mod_bbca_passive_counterattack.nut"
    if ($pc) {
        Check "passive counterattack uses mods_hookExactClass" ($pc.Contains('mods_hookExactClass'))
        Check "does not resurrect the crashing actor mods_hookClass" (-not [regex]::IsMatch($pc, 'mods_hookClass\s*\(\s*"entity/tactical/actor"'))
        Check "hooks onAttackOfOpportunity" ($pc.Contains('onAttackOfOpportunity'))
    }
    else { Check "passive counterattack hook present" $false }
    foreach ($h in @('mod_bbca_overwhelmed_immunity.nut', 'mod_bbca_distracted_immunity.nut', 'mod_bbca_swallow_whole_immunity.nut')) {
        Check ("immunity hook present: {0}" -f $h) ((Get-EntryCount $archive ("scripts/!mods_preload/" + $h)) -eq 1)
    }

    Section "Hit chance 0-100 (embedded)"
    $hc100 = Read-ZipEntryText $archive "scripts/!mods_preload/mod_bbca_hitchance_100or0.nut"
    if ($hc100) {
        Check "no dead IsShieldwallRelevant field" (-not $hc100.Contains('IsShieldwallRelevant'))
        Check "registers mod_bbca_hitchance via mods_queue" (($hc100.Contains('mod_bbca_hitchance')) -and ($hc100.Contains('mods_queue')))
        Check "keeps diversion parameters" (($hc100.Contains('HitChanceOnDiversion')) -and ($hc100.Contains('DamageTotalOnDiversionMult')))
    }
    else { Check "hit chance hook present" $false }

    Section "Fire grenade (config v2)"
    $fg = Read-ZipEntryText $archive "scripts/skills/actives/bbca_fire_grenade_skill.nut"
    Check "skill present exactly once" ((Get-EntryCount $archive "scripts/skills/actives/bbca_fire_grenade_skill.nut") -eq 1)
    if ($fg) { Check "uses AreaRadius" ($fg.Contains('AreaRadius')) }
    $fgc = Read-ZipEntryText $archive "scripts/skills/effects/bbca_fire_grenade_config_skill.nut"
    if ($fgc) {
        Check "serializes config version 2" ([regex]::IsMatch($fgc, '_out\.writeI32\(\s*2\s*\)'))
        Check "reads v2 branch for AreaRadius" ([regex]::IsMatch($fgc, 'version\s*>=\s*2'))
        Check "v1 files default AreaRadius to 2" ([regex]::IsMatch($fgc, 'AreaRadius\s*=\s*2'))
    }
    else { Check "fire grenade config present" $false }

    Section "Summon zombie (config v1)"
    $sz = Read-ZipEntryText $archive "scripts/skills/actives/bbca_summon_zombie_skill.nut"
    Check "skill present exactly once" ((Get-EntryCount $archive "scripts/skills/actives/bbca_summon_zombie_skill.nut") -eq 1)
    if ($sz) {
        Check "spawns vanilla zombie_yeoman entity" ($sz.Contains('zombie_yeoman'))
        Check "uses PlayerAnimals faction" ($sz.Contains('PlayerAnimals'))
        Check "forbids auto resurrection" ([regex]::IsMatch($sz, 'ResurrectionChance\s*=\s*0'))
    }
    Check "own enable icon packed" ($allPaths -contains 'gfx/ui/bbca_summon_zombie.png')
    Check "own disable icon packed" ($allPaths -contains 'gfx/ui/bbca_summon_zombie_sw.png')
    $szc = Read-ZipEntryText $archive "scripts/skills/effects/bbca_summon_zombie_config_skill.nut"
    if ($szc) { Check "summon config serializes version 1" ([regex]::IsMatch($szc, '_out\.writeI32\(\s*1\s*\)')) }
    else { Check "summon config present" $false }

    Section "Regenerating gear"
    $mail = Read-ZipEntryText $archive "scripts/items/armor/legendary/bbca_regenerating_adorned_mail_shirt.nut"
    $coif = Read-ZipEntryText $archive "scripts/items/helmets/legendary/bbca_regenerating_heavy_mail_coif.nut"
    Check "adorned mail shirt present" ($null -ne $mail)
    Check "heavy mail coif present" ($null -ne $coif)
    if ($mail) {
        Check "shirt uses stable id" ($mail.Contains('armor.body.bbca_regenerating_adorned_mail_shirt'))
        Check "shirt 270 durability" ([regex]::IsMatch($mail, '270'))
    }
    if ($coif) {
        Check "coif uses stable id" ($coif.Contains('armor.head.bbca_regenerating_heavy_mail_coif'))
        Check "coif pins blue-feather Variant 265" ([regex]::IsMatch($coif, 'Variant\s*=\s*265'))
        Check "coif migrates on deserialize" (($coif.Contains('onDeserialize')) -and ($coif.Contains('updateVariant')))
        Check "coif refreshes equipped appearance" ($coif.Contains('updateAppearance'))
        Check "coif no longer uses old Variant 237" (-not [regex]::IsMatch($coif, 'Variant\s*=\s*237'))
    }

    Section "Chinese UI resources ship with the pack"
    foreach ($p in @('ui/world_names.js', 'ui/ui.js', 'ui/bbca_cn_ui_compat.js')) {
        Check ("packed: {0}" -f $p) ($allPaths -contains $p)
    }
}
finally {
    $archive.Dispose()
}

if (Test-Path -LiteralPath $dataDir) {
    Section "Steam deployment consistency"
    $steamPack = Join-Path $dataDir (Split-Path -Leaf $packFull)
    if (Test-Path -LiteralPath $steamPack) {
        $steamHash = (Get-FileHash $steamPack -Algorithm SHA256).Hash
        Check "Steam pack SHA-256 matches build" ($steamHash -eq $packHash) ("steam {0}" -f $steamHash)
    }
    else { Check "Steam pack present" $false $steamPack }

    $backups = @(Get-ChildItem -LiteralPath $dataDir -File -Filter "*.bbca-backup")
    Check ("backup count = {0} (iron rule: never delete/modify)" -f $ExpectedBackups) ($backups.Count -eq $ExpectedBackups) ("got {0}" -f $backups.Count)

    $breditorPath = Join-Path $dataDir $BreditorArchiveName
    if (Test-Path -LiteralPath $breditorPath) {
        $bz = [System.IO.Compression.ZipFile]::OpenRead($breditorPath)
        try {
            $main = Read-ZipEntryText $bz "ui/main.html"
            Check "Breditor main.html present" ($null -ne $main)
            if ($main) {
                $order = @()
                foreach ($js in @('world_names.js', 'ui.js', 'bbca_cn_ui_compat.js', 'mod_hooks.js')) {
                    $idx = $main.IndexOf($js)
                    $order += [pscustomobject]@{ Name = $js; Index = $idx }
                }
                $missing = @($order | Where-Object { $_.Index -lt 0 })
                Check "all four UI scripts referenced" ($missing.Count -eq 0) (($missing | ForEach-Object { $_.Name }) -join ',')
                if ($missing.Count -eq 0) {
                    $sorted = @($order | Sort-Object Index)
                    $sequence = ($sorted | ForEach-Object { $_.Name }) -join ' -> '
                    Check "load order world_names -> ui -> compat -> mod_hooks" (($sorted[0].Name -eq 'world_names.js') -and ($sorted[1].Name -eq 'ui.js') -and ($sorted[2].Name -eq 'bbca_cn_ui_compat.js') -and ($sorted[3].Name -eq 'mod_hooks.js')) $sequence
                }
            }
            $compat = Read-ZipEntryText $bz "ui/bbca_cn_ui_compat.js"
            if ($compat) {
                Check "compat helper guards TranslateDialog" ($compat.Contains('typeof TranslateDialog === "undefined"'))
                Check "compat helper guards TranslateButtons" ($compat.Contains('typeof TranslateButtons === "undefined"'))
            }
        }
        finally { $bz.Dispose() }
    }
    else { Check "Breditor archive present in Steam data" $false $breditorPath }

    $running = @(Get-Process -Name "BattleBrothers" -ErrorAction SilentlyContinue)
    Write-Host ("  info  BattleBrothers.exe running: {0}" -f ($running.Count -gt 0))
}

Write-Host ""
Write-Host ("RESULT: {0} passed, {1} failed" -f $script:pass, $script:fail) -ForegroundColor $(if ($script:fail -eq 0) { "Green" } else { "Red" })
if ($script:fail -gt 0) { exit 1 }
exit 0
