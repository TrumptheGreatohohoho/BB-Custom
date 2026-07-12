[CmdletBinding()]
param(
    [string]$GameDir = "D:\games\steam\steamapps\common\Battle Brothers",
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$root = Split-Path -Parent $PSScriptRoot
$repoPath = Join-Path $root "asset_repo\custom_appearance"
$manifestPath = Join-Path $repoPath "manifest.json"
$importTool = Join-Path $PSScriptRoot "import_custom_appearance_asset.ps1"
$buildTool = Join-Path $PSScriptRoot "build_custom_appearance_pack.ps1"
$installTool = Join-Path $PSScriptRoot "install_custom_appearance_pack.ps1"

function Get-Manifest {
    return (Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Get-RoleDimensions([string]$Role) {
    $template = @(Get-Manifest | ForEach-Object { $_.sprites } | Where-Object { $_.role -eq $Role } | Select-Object -First 1)
    if ($template.Count -ne 1) {
        throw "No manifest template found for role: $Role"
    }

    $sourcePath = Join-Path $repoPath $template[0].source
    $bitmap = [Drawing.Bitmap]::new($sourcePath)
    try {
        return "$($bitmap.Width) x $($bitmap.Height) px"
    }
    finally {
        $bitmap.Dispose()
    }
}

function Test-GameStopped {
    if (Get-Process -Name "BattleBrothers" -ErrorAction SilentlyContinue) {
        throw "BattleBrothers.exe is running. Close the game before building or installing."
    }
}

function Invoke-BuildInstall {
    Test-GameStopped
    Push-Location $root
    try {
        $output = @(& $buildTool 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Build failed with exit code $LASTEXITCODE`n$($output -join [Environment]::NewLine)" }
        $output += @(& $installTool -GameDir $GameDir 2>&1)
        if ($LASTEXITCODE -ne 0) { throw "Install failed with exit code $LASTEXITCODE`n$($output -join [Environment]::NewLine)" }
        return ($output -join [Environment]::NewLine)
    }
    finally {
        Pop-Location
    }
}

if ($ValidateOnly) {
    foreach ($role in @("body", "head", "hair", "beard")) {
        [void](Get-RoleDimensions $role)
    }
    $assetCount = @((Get-Manifest).sprites).Count
    Write-Host "Manager validation passed: $assetCount manifest assets are available."
    exit 0
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Battle Brothers Custom Appearance Manager"
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object Drawing.Size(1050, 680)
$form.Size = New-Object Drawing.Size(1120, 740)
$form.Font = New-Object Drawing.Font("Microsoft YaHei UI", 9)
$form.BackColor = [Drawing.Color]::FromArgb(36, 33, 29)
$form.ForeColor = [Drawing.Color]::FromArgb(227, 220, 203)

$title = New-Object System.Windows.Forms.Label
$title.Text = "自定义造型资源管理"
$title.Font = New-Object Drawing.Font("Microsoft YaHei UI", 16, [Drawing.FontStyle]::Bold)
$title.ForeColor = [Drawing.Color]::FromArgb(216, 189, 121)
$title.Location = New-Object Drawing.Point(20, 16)
$title.AutoSize = $true
$form.Controls.Add($title)

$fileLabel = New-Object System.Windows.Forms.Label
$fileLabel.Text = "PNG 文件"
$fileLabel.Location = New-Object Drawing.Point(24, 67)
$fileLabel.AutoSize = $true
$form.Controls.Add($fileLabel)

$fileBox = New-Object System.Windows.Forms.TextBox
$fileBox.Location = New-Object Drawing.Point(100, 63)
$fileBox.Size = New-Object Drawing.Size(500, 28)
$fileBox.ReadOnly = $true
$form.Controls.Add($fileBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "选择 PNG..."
$browseButton.Location = New-Object Drawing.Point(610, 61)
$browseButton.Size = New-Object Drawing.Size(110, 30)
$form.Controls.Add($browseButton)

$roleLabel = New-Object System.Windows.Forms.Label
$roleLabel.Text = "角色层"
$roleLabel.Location = New-Object Drawing.Point(24, 112)
$roleLabel.AutoSize = $true
$form.Controls.Add($roleLabel)

$roleBox = New-Object System.Windows.Forms.ComboBox
$roleBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
foreach ($role in @("body", "head", "hair", "beard")) {
    [void]$roleBox.Items.Add($role)
}
$roleBox.SelectedIndex = 0
$roleBox.Location = New-Object Drawing.Point(100, 108)
$roleBox.Size = New-Object Drawing.Size(160, 28)
$form.Controls.Add($roleBox)

$requiredSizeLabel = New-Object System.Windows.Forms.Label
$requiredSizeLabel.Location = New-Object Drawing.Point(280, 112)
$requiredSizeLabel.AutoSize = $true
$requiredSizeLabel.ForeColor = [Drawing.Color]::FromArgb(201, 195, 182)
$form.Controls.Add($requiredSizeLabel)

$labelLabel = New-Object System.Windows.Forms.Label
$labelLabel.Text = "显示名称"
$labelLabel.Location = New-Object Drawing.Point(24, 157)
$labelLabel.AutoSize = $true
$form.Controls.Add($labelLabel)

$labelBox = New-Object System.Windows.Forms.TextBox
$labelBox.Location = New-Object Drawing.Point(100, 153)
$labelBox.Size = New-Object Drawing.Size(310, 28)
$form.Controls.Add($labelBox)

$installAfter = New-Object System.Windows.Forms.CheckBox
$installAfter.Text = "导入后立即构建并安装（游戏必须关闭）"
$installAfter.Location = New-Object Drawing.Point(430, 156)
$installAfter.AutoSize = $true
$form.Controls.Add($installAfter)

$importButton = New-Object System.Windows.Forms.Button
$importButton.Text = "验证并导入"
$importButton.Location = New-Object Drawing.Point(730, 61)
$importButton.Size = New-Object Drawing.Size(140, 36)
$form.Controls.Add($importButton)

$buildInstallButton = New-Object System.Windows.Forms.Button
$buildInstallButton.Text = "构建并安装当前资源"
$buildInstallButton.Location = New-Object Drawing.Point(730, 108)
$buildInstallButton.Size = New-Object Drawing.Size(180, 36)
$form.Controls.Add($buildInstallButton)

$previewLabel = New-Object System.Windows.Forms.Label
$previewLabel.Text = "PNG 预览"
$previewLabel.Location = New-Object Drawing.Point(24, 207)
$previewLabel.AutoSize = $true
$form.Controls.Add($previewLabel)

$preview = New-Object System.Windows.Forms.PictureBox
$preview.Location = New-Object Drawing.Point(24, 232)
$preview.Size = New-Object Drawing.Size(240, 240)
$preview.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$preview.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$preview.BackColor = [Drawing.Color]::FromArgb(24, 21, 17)
$form.Controls.Add($preview)

$assetLabel = New-Object System.Windows.Forms.Label
$assetLabel.Text = "已导入资源"
$assetLabel.Location = New-Object Drawing.Point(290, 207)
$assetLabel.AutoSize = $true
$form.Controls.Add($assetLabel)

$assetList = New-Object System.Windows.Forms.ListView
$assetList.Location = New-Object Drawing.Point(290, 232)
$assetList.Size = New-Object Drawing.Size(790, 240)
$assetList.View = [System.Windows.Forms.View]::Details
$assetList.FullRowSelect = $true
$assetList.GridLines = $true
$assetList.BackColor = [Drawing.Color]::FromArgb(24, 21, 17)
$assetList.ForeColor = [Drawing.Color]::FromArgb(227, 220, 203)
[void]$assetList.Columns.Add("ID", 220)
[void]$assetList.Columns.Add("Role", 100)
[void]$assetList.Columns.Add("Label", 190)
[void]$assetList.Columns.Add("Source", 250)
$form.Controls.Add($assetList)

$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = "操作日志"
$logLabel.Location = New-Object Drawing.Point(24, 500)
$logLabel.AutoSize = $true
$form.Controls.Add($logLabel)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Location = New-Object Drawing.Point(24, 525)
$logBox.Size = New-Object Drawing.Size(1056, 135)
$logBox.Multiline = $true
$logBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$logBox.ReadOnly = $true
$logBox.BackColor = [Drawing.Color]::FromArgb(24, 21, 17)
$logBox.ForeColor = [Drawing.Color]::FromArgb(227, 220, 203)
$form.Controls.Add($logBox)

function Set-Log([string]$Text) {
    $logBox.Text = $Text
    $logBox.SelectionStart = $logBox.TextLength
    $logBox.ScrollToCaret()
}

function Refresh-Assets {
    $assetList.BeginUpdate()
    try {
        $assetList.Items.Clear()
        foreach ($sprite in (Get-Manifest).sprites) {
            $item = New-Object System.Windows.Forms.ListViewItem([string]$sprite.id)
            [void]$item.SubItems.Add([string]$sprite.role)
            [void]$item.SubItems.Add([string]$sprite.label)
            [void]$item.SubItems.Add([string]$sprite.source)
            [void]$assetList.Items.Add($item)
        }
    }
    finally {
        $assetList.EndUpdate()
    }
}

function Refresh-RoleHint {
    $requiredSizeLabel.Text = "Required PNG size: $(Get-RoleDimensions $roleBox.SelectedItem) with transparent background"
}

function Set-Preview([string]$Path) {
    if ($null -ne $preview.Image) {
        $oldImage = $preview.Image
        $preview.Image = $null
        $oldImage.Dispose()
    }
    if (![string]::IsNullOrWhiteSpace($Path)) {
        $sourceImage = [Drawing.Image]::FromFile($Path)
        try {
            $preview.Image = [Drawing.Bitmap]::new($sourceImage)
        }
        finally {
            $sourceImage.Dispose()
        }
    }
}

$roleBox.add_SelectedIndexChanged({
    try { Refresh-RoleHint } catch { Set-Log $_.Exception.Message }
})

$browseButton.add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "选择透明 PNG 资源"
    $dialog.Filter = "PNG images (*.png)|*.png"
    $dialog.Multiselect = $false
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        try {
            $fileBox.Text = $dialog.FileName
            Set-Preview $dialog.FileName
            Set-Log "Selected $($dialog.FileName)"
        }
        catch {
            $fileBox.Text = ""
            Set-Log "Preview failed: $($_.Exception.Message)"
        }
    }
    $dialog.Dispose()
})

$importButton.add_Click({
    if ([string]::IsNullOrWhiteSpace($fileBox.Text)) {
        [System.Windows.Forms.MessageBox]::Show("请选择 PNG 文件。", "缺少文件", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    try {
        $install = $installAfter.Checked
        $output = @(& $importTool -InputPath $fileBox.Text -Role ([string]$roleBox.SelectedItem) -Label $labelBox.Text -Install:$install -GameDir $GameDir 2>&1)
        Set-Log ($output -join [Environment]::NewLine)
        Refresh-Assets
        [System.Windows.Forms.MessageBox]::Show("资源已导入。" + $(if ($install) { " 已构建并安装；请重启游戏。" } else { "" }), "完成", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    }
    catch {
        Set-Log $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "导入失败", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

$buildInstallButton.add_Click({
    try {
        $output = Invoke-BuildInstall
        Set-Log $output
        [System.Windows.Forms.MessageBox]::Show("构建和安装完成。请重启游戏。", "完成", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    }
    catch {
        Set-Log $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "构建或安装失败", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

$form.add_FormClosed({
    if ($null -ne $preview.Image) { $preview.Image.Dispose() }
})

Refresh-RoleHint
Refresh-Assets
Set-Log "Select a PNG, choose its role, then import."
[void]$form.ShowDialog()
