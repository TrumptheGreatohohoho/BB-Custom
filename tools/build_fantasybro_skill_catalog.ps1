param(
    [string]$ReferenceArchive = "",
    [string]$TranslationFile = "docs\reference\fantasybro-skill-cn.tsv",
    [string]$OutFile = "docs\fantasybro-skill-catalog.html"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).ProviderPath
if ([string]::IsNullOrWhiteSpace($ReferenceArchive)) {
    $archiveCandidates = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter "mod_fantasybro-*.zip" |
        Where-Object { $_.FullName -notlike (Join-Path $root "build\*") })
    if ($archiveCandidates.Count -ne 1) {
        throw "Expected exactly one mod_fantasybro archive outside build; found $($archiveCandidates.Count). Pass -ReferenceArchive explicitly."
    }
    $archivePath = $archiveCandidates[0].FullName
}
else {
    $archivePath = (Resolve-Path -LiteralPath (Join-Path $root $ReferenceArchive)).ProviderPath
}
$translationPath = (Resolve-Path -LiteralPath (Join-Path $root $TranslationFile)).ProviderPath
$outputPath = Join-Path $root $OutFile

function Read-ZipText([System.IO.Compression.ZipArchive]$Zip, [string]$Path) {
    $entry = $Zip.GetEntry($Path)
    if ($null -eq $entry) {
        throw "Missing ZIP entry: $Path"
    }
    $reader = [System.IO.StreamReader]::new($entry.Open(), [System.Text.Encoding]::UTF8, $true)
    try {
        return $reader.ReadToEnd()
    }
    finally {
        $reader.Dispose()
    }
}

function Get-Field([string]$Text, [string]$Field) {
    $match = [regex]::Match($Text, "this\.m\.$Field\s*=\s*([^;]+);")
    if (!$match.Success) {
        return ""
    }
    return $match.Groups[1].Value.Trim().Trim('"')
}

function Get-Description([string]$Text) {
    $match = [regex]::Match($Text, "this\.m\.Description\s*=\s*(.+?);", [Text.RegularExpressions.RegexOptions]::Singleline)
    if (!$match.Success) {
        return ""
    }

    $parts = [regex]::Matches($match.Groups[1].Value, '"((?:\\.|[^"\\])*)"')
    $value = ($parts | ForEach-Object { $_.Groups[1].Value }) -join ""
    $value = $value.Replace('\n', ' ').Replace('\"', '"').Replace("\'", "'")
    $value = [regex]::Replace($value, '\[/?color[^\]]*\]', '')
    return [regex]::Replace($value, '\s+', ' ').Trim()
}

function Get-IconData([System.IO.Compression.ZipArchive]$Zip, [string]$Icon) {
    if ([string]::IsNullOrWhiteSpace($Icon)) {
        return ""
    }
    $entry = $Zip.GetEntry("gfx/$Icon")
    if ($null -eq $entry) {
        return ""
    }
    $stream = $entry.Open()
    try {
        $memory = [System.IO.MemoryStream]::new()
        try {
            $stream.CopyTo($memory)
            return "data:image/png;base64,$([Convert]::ToBase64String($memory.ToArray()))"
        }
        finally {
            $memory.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
}

$translations = @{}
$rows = Get-Content -LiteralPath $translationPath -Encoding UTF8
foreach ($line in $rows | Select-Object -Skip 1) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }
    $columns = $line.Split("`t")
    if ($columns.Count -ne 4) {
        throw "Invalid translation row: $line"
    }
    $translations[$columns[0]] = @{
        Name = $columns[1]
        Summary = $columns[2]
        Tags = @($columns[3].Split(";") | Where-Object { $_ })
    }
}

$zip = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    $config = Read-ZipText $zip "scripts/!mods_preload/!config/mod_xx_config.nut"
    $start = $config.IndexOf("gt.FantasySpellbookact")
    $end = $config.IndexOf("for( local i", $start)
    if ($start -lt 0 -or $end -lt 0) {
        throw "FantasySpellbookact catalog was not found"
    }

    $catalogText = $config.Substring($start, $end - $start)
    $skillFiles = @([regex]::Matches($catalogText, '"([^"]+_skill)"') | ForEach-Object {
        $_.Groups[1].Value
    })
    if ($skillFiles.Count -ne 111) {
        throw "Expected 111 spellbook skills, found $($skillFiles.Count)"
    }

    $skills = foreach ($file in $skillFiles) {
        if (!$translations.ContainsKey($file)) {
            throw "Missing Chinese translation for $file"
        }
        $text = Read-ZipText $zip "scripts/skills/actives/$file.nut"
        $translation = $translations[$file]
        $type = if ($file -like "sbp_*" -or $file -like "sbq2p_*" -or $file -like "sbq3p_*") {
            "passive"
        }
        else {
            "active"
        }
        $minRange = Get-Field $text "MinRange"
        $maxRange = Get-Field $text "MaxRange"
        $cooldownMatch = [regex]::Match($text, "Cooldown\s*=\s*(\d+)")
        $icon = Get-Field $text "Icon"

        [ordered]@{
            file = $file
            source = "scripts/skills/actives/$file.nut"
            id = Get-Field $text "ID"
            type = $type
            enName = Get-Field $text "Name"
            enDescription = Get-Description $text
            cnName = $translation.Name
            cnSummary = $translation.Summary
            tags = $translation.Tags
            ap = Get-Field $text "ActionPointCost"
            fatigue = Get-Field $text "FatigueCost"
            range = if ($minRange -or $maxRange) { "$minRange-$maxRange" } else { "" }
            cooldown = if ($cooldownMatch.Success) { $cooldownMatch.Groups[1].Value } else { "" }
            icon = Get-IconData $zip $icon
        }
    }
}
finally {
    $zip.Dispose()
}

$json = $skills | ConvertTo-Json -Depth 6 -Compress
$json = $json.Replace("</", "<\/")
$activeCount = @($skills | Where-Object { $_.type -eq "active" }).Count
$passiveCount = @($skills | Where-Object { $_.type -eq "passive" }).Count
$archiveName = Split-Path -Leaf $archivePath
$generated = Get-Date -Format "yyyy-MM-dd HH:mm"

$template = @'
<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>FantasyBro 技能中文图鉴</title>
<style>
:root{color-scheme:light;--paper:#f5f6f2;--surface:#fff;--ink:#202322;--muted:#68706d;--line:#d8ddda;--red:#ad3b36;--teal:#176f6a;--gold:#9b711b;--shadow:0 2px 10px rgba(25,35,32,.08)}
*{box-sizing:border-box}
body{margin:0;background:var(--paper);color:var(--ink);font-family:"Microsoft YaHei","Noto Sans SC",Arial,sans-serif;letter-spacing:0}
header{background:#242927;color:#fff;border-bottom:4px solid var(--red)}
.header-inner{max-width:1440px;margin:auto;padding:28px 24px 24px}
h1{margin:0 0 8px;font-size:clamp(26px,4vw,42px);font-weight:750}
.subtitle{margin:0;color:#cfd6d2;line-height:1.7}
.summary-strip{display:flex;gap:22px;flex-wrap:wrap;margin-top:20px}
.summary-item strong{display:block;font-size:24px;color:#fff}.summary-item span{font-size:12px;color:#aeb8b3}
main{max-width:1440px;margin:auto;padding:20px 24px 48px}
.toolbar{position:sticky;top:0;z-index:5;background:rgba(245,246,242,.96);border-bottom:1px solid var(--line);padding:12px 0}
.controls{display:grid;grid-template-columns:minmax(220px,1fr) auto;gap:12px;align-items:center}
input[type=search]{width:100%;height:42px;border:1px solid #bfc7c3;border-radius:6px;background:#fff;padding:0 14px;font:inherit;color:var(--ink)}
.segments{display:flex;border:1px solid #bfc7c3;border-radius:6px;overflow:hidden;background:#fff}
.segments button{height:40px;border:0;border-right:1px solid #d5dbd8;background:#fff;color:#3c4441;padding:0 14px;font:inherit;cursor:pointer}
.segments button:last-child{border-right:0}.segments button.active{background:var(--teal);color:#fff}
.result-line{margin:14px 0;color:var(--muted);font-size:13px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(330px,1fr));gap:14px}
.card{background:var(--surface);border:1px solid var(--line);border-radius:7px;box-shadow:var(--shadow);padding:16px;min-width:0}
.card-head{display:grid;grid-template-columns:56px minmax(0,1fr);gap:13px;align-items:start}
.icon{width:56px;height:56px;object-fit:contain;background:#edf0ed;border:1px solid #d8ddda;border-radius:5px;image-rendering:auto}
.icon.empty{display:grid;place-items:center;color:#8b9490;font-weight:700}
h2{margin:0;font-size:19px;line-height:1.35;overflow-wrap:anywhere}.en-name{margin-top:3px;color:var(--muted);font-size:12px;overflow-wrap:anywhere}
.type{display:inline-block;margin-top:7px;font-size:11px;font-weight:700;color:#fff;background:var(--red);padding:3px 7px;border-radius:4px}.type.passive{background:var(--teal)}
.description{margin:13px 0 12px;line-height:1.75;font-size:14px;min-height:72px}
.stats{display:flex;flex-wrap:wrap;gap:7px;margin-bottom:11px}.stat{font-size:12px;color:#424a47;border-left:3px solid var(--gold);background:#f0f2ef;padding:4px 7px}
.tags{display:flex;flex-wrap:wrap;gap:6px}.tag{font-size:11px;color:#39504d;border:1px solid #c8d5d1;padding:3px 6px;border-radius:4px}
details{margin-top:12px;border-top:1px solid #e2e6e4;padding-top:10px}summary{cursor:pointer;color:var(--teal);font-size:12px}
.source{margin-top:8px;color:var(--muted);font:12px/1.6 Consolas,monospace;overflow-wrap:anywhere}.english{font:12px/1.65 Arial,sans-serif;color:#4b5450;margin-top:8px}
.empty-state{display:none;padding:48px 0;text-align:center;color:var(--muted)}
footer{max-width:1440px;margin:auto;padding:0 24px 30px;color:var(--muted);font-size:12px;line-height:1.7}
@media(max-width:720px){.header-inner,main,footer{padding-left:14px;padding-right:14px}.controls{grid-template-columns:1fr}.segments{width:100%}.segments button{flex:1;padding:0 8px}.grid{grid-template-columns:1fr}.toolbar{position:static}}
</style>
</head>
<body>
<header><div class="header-inner">
  <h1>FantasyBro 技能中文图鉴</h1>
  <p class="subtitle">基于源码中的技能书授予目录整理。中文效果以代码与原始说明综合归纳，AI、装备专属技和内部 effect 不计入下方 111 项。</p>
  <div class="summary-strip">
    <div class="summary-item"><strong>__TOTAL__</strong><span>技能书技能</span></div>
    <div class="summary-item"><strong>__ACTIVE__</strong><span>主动/特殊技能</span></div>
    <div class="summary-item"><strong>__PASSIVE__</strong><span>被动技能</span></div>
  </div>
</div></header>
<main>
  <div class="toolbar"><div class="controls">
    <input id="search" type="search" placeholder="搜索中文名、英文名、效果、ID 或标签" aria-label="搜索技能">
    <div class="segments" role="group" aria-label="技能类型">
      <button class="active" data-filter="all">全部</button>
      <button data-filter="active">主动</button>
      <button data-filter="passive">被动</button>
    </div>
  </div></div>
  <div class="result-line" id="result"></div>
  <section class="grid" id="grid"></section>
  <div class="empty-state" id="empty">没有匹配的技能。</div>
</main>
<footer>
  来源：__ARCHIVE__ · 生成时间：__GENERATED__。数值以该压缩包源码为准；部分技能依赖 FantasyBro 自定义实体、effect、地块或全局状态，不能只复制单个文件。
</footer>
<script>
const skills=__DATA__;
const grid=document.querySelector("#grid");
const search=document.querySelector("#search");
const result=document.querySelector("#result");
const empty=document.querySelector("#empty");
let filter="all";
const esc=s=>String(s??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
function stat(label,value){return value?`<span class="stat">${label} ${esc(value)}</span>`:""}
function render(){
  const q=search.value.trim().toLowerCase();
  const shown=skills.filter(s=>{
    if(filter!=="all"&&s.type!==filter)return false;
    const hay=[s.cnName,s.enName,s.cnSummary,s.id,s.file,...s.tags].join(" ").toLowerCase();
    return !q||hay.includes(q);
  });
  grid.innerHTML=shown.map(s=>`<article class="card">
    <div class="card-head">
      ${s.icon?`<img class="icon" src="${s.icon}" alt="">`:`<div class="icon empty">?</div>`}
      <div><h2>${esc(s.cnName)}</h2><div class="en-name">${esc(s.enName)}</div><span class="type ${s.type}">${s.type==="passive"?"被动":"主动"}</span></div>
    </div>
    <p class="description">${esc(s.cnSummary)}</p>
    <div class="stats">${stat("AP",s.ap)}${stat("疲劳",s.fatigue)}${stat("射程",s.range)}${stat("冷却",s.cooldown)}</div>
    <div class="tags">${s.tags.map(t=>`<span class="tag">${esc(t)}</span>`).join("")}</div>
    <details><summary>源码信息</summary><div class="source">${esc(s.id)}<br>${esc(s.source)}</div><div class="english">${esc(s.enDescription)}</div></details>
  </article>`).join("");
  result.textContent=`显示 ${shown.length} / ${skills.length} 项`;
  empty.style.display=shown.length?"none":"block";
}
document.querySelectorAll(".segments button").forEach(button=>button.addEventListener("click",()=>{
  document.querySelectorAll(".segments button").forEach(x=>x.classList.remove("active"));
  button.classList.add("active");filter=button.dataset.filter;render();
}));
search.addEventListener("input",render);
render();
</script>
</body>
</html>
'@

$html = $template.
    Replace("__TOTAL__", [string]$skills.Count).
    Replace("__ACTIVE__", [string]$activeCount).
    Replace("__PASSIVE__", [string]$passiveCount).
    Replace("__ARCHIVE__", [System.Net.WebUtility]::HtmlEncode($archiveName)).
    Replace("__GENERATED__", [System.Net.WebUtility]::HtmlEncode($generated)).
    Replace("__DATA__", $json)

[System.IO.Directory]::CreateDirectory((Split-Path -Parent $outputPath)) | Out-Null
[System.IO.File]::WriteAllText($outputPath, $html, [System.Text.UTF8Encoding]::new($false))
Write-Host "Built $outputPath with $($skills.Count) skills"
