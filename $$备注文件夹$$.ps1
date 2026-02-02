param (
    [string]$folderPath
)

# 校验路径
if (-not (Test-Path $folderPath -PathType Container)) { exit }

$iniFile = Join-Path $folderPath "desktop.ini"
$parentDir = Split-Path $folderPath -Parent

# 读取已有值
$currentRemark = ""
$currentQuickRelative = ""

if (Test-Path $iniFile) {
    try {
        attrib -s -h -r $iniFile 2>$null
        $content = Get-Content $iniFile -Encoding Unicode -Raw

        if ($content -match 'LocalizedResourceName\s*=\s*(.+?)\r?\n') {
            $currentRemark = $Matches[1].Trim()
            # 仅为显示去除可能的 @ 前缀和 ,0 后缀
            $currentRemark = $currentRemark -replace '^@', '' -replace ',0$', ''
        }

        if ($content -match 'QuickLaunchPath\s*=\s*(.+?)\r?\n') {
            $currentQuickRelative = $Matches[1].Trim()
            # 仅为显示去除可能的 @ 前缀和 ,0 后缀
            $currentQuickRelative = $currentQuickRelative -replace '^@', '' -replace ',0$', ''
        }
    } catch { }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "文件夹备注 & 快速启动"
$form.Size = New-Object System.Drawing.Size(480, 360)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# 备注
$lblRemark = New-Object System.Windows.Forms.Label
$lblRemark.Text = "文件夹备注（留空则删除备注）"
$lblRemark.Location = New-Object System.Drawing.Point(20, 20)
$lblRemark.Size = New-Object System.Drawing.Size(420, 30)
$form.Controls.Add($lblRemark)

$txtRemark = New-Object System.Windows.Forms.TextBox
$txtRemark.Location = New-Object System.Drawing.Point(20, 50)
$txtRemark.Size = New-Object System.Drawing.Size(420, 30)
$txtRemark.Text = $currentRemark
$form.Controls.Add($txtRemark)

# 快速启动
$lblQuick = New-Object System.Windows.Forms.Label
$lblQuick.Text = "快速启动程序（选择本文件夹内的 .exe/.bat/.cmd，留空则删除）"
$lblQuick.Location = New-Object System.Drawing.Point(20, 100)
$lblQuick.Size = New-Object System.Drawing.Size(420, 40)
$form.Controls.Add($lblQuick)

$txtQuick = New-Object System.Windows.Forms.TextBox
$txtQuick.Location = New-Object System.Drawing.Point(20, 140)
$txtQuick.Size = New-Object System.Drawing.Size(340, 30)
$txtQuick.Text = $currentQuickRelative
$txtQuick.ReadOnly = $true
$form.Controls.Add($txtQuick)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "浏览..."
$btnBrowse.Location = New-Object System.Drawing.Point(370, 140)
$btnBrowse.Size = New-Object System.Drawing.Size(80, 30)
$btnBrowse.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.InitialDirectory = $folderPath
    $ofd.Filter = "可执行文件 (*.exe;*.bat;*.cmd)|*.exe;*.bat;*.cmd|所有文件 (*.*)|*.*"
    $ofd.Title = "请选择本文件夹（含子文件夹）内的程序"

    if ($ofd.ShowDialog() -eq "OK") {
        $selectedPath = $ofd.FileName
        # 判断是否在 $folderPath 或其子目录中
        if ($selectedPath.StartsWith($folderPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            # 计算相对路径（去掉开头的 folderPath 和 \）
            $relative = $selectedPath.Substring($folderPath.Length).TrimStart('\')
            $txtQuick.Text = $relative
        } else {
            [System.Windows.Forms.MessageBox]::Show("只能选择当前文件夹内的文件！", "错误", "OK", "Error")
        }
    }
})
$form.Controls.Add($btnBrowse)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = "清除"
$btnClear.Location = New-Object System.Drawing.Point(20, 190)
$btnClear.Size = New-Object System.Drawing.Size(80, 30)
$btnClear.Add_Click({ $txtQuick.Text = "" })
$form.Controls.Add($btnClear)

# 确定按钮
$btnOK = New-Object System.Windows.Forms.Button
$btnOK.Text = "确定"
$btnOK.Location = New-Object System.Drawing.Point(180, 250)
$btnOK.Size = New-Object System.Drawing.Size(100, 40)
$btnOK.DialogResult = "OK"
$form.AcceptButton = $btnOK
$form.Controls.Add($btnOK)

if ($form.ShowDialog() -ne "OK") { exit }

$remark = $txtRemark.Text.Trim()
$quickRelative = $txtQuick.Text.Trim()

# 全空 → 删除所有自定义设置
if ([string]::IsNullOrWhiteSpace($remark) -and [string]::IsNullOrWhiteSpace($quickRelative)) {
    if (Test-Path $iniFile) {
        attrib -s -h -r $iniFile 2>$null
        Remove-Item $iniFile -Force
    }
    attrib -r $folderPath 2>$null
} else {
    # 写入 desktop.ini（使用相对路径）
    $lines = "[.ShellClassInfo]`r`n"
    if ($remark) {
        $lines += "LocalizedResourceName=$remark`r`n"
    }
    if ($quickRelative) {
        $lines += "IconResource=$quickRelative,0`r`n"
        $lines += "QuickLaunchPath=$quickRelative`r`n"
    }

    $lines | Out-File -FilePath $iniFile -Encoding Unicode -Force
    attrib +s +h $iniFile
    attrib +r $folderPath
}

# 刷新资源管理器
Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 800
if (Test-Path $parentDir) {
    Start-Process explorer.exe $parentDir
}