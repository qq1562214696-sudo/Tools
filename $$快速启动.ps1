param (
    [string]$folderPath
)

if (-not (Test-Path $folderPath -PathType Container)) { exit }

$iniFile = Join-Path $folderPath "desktop.ini"
$quickRelative = ""

if (Test-Path $iniFile) {
    try {
        attrib -s -h -r $iniFile 2>$null
        $content = Get-Content $iniFile -Encoding Unicode -Raw

        # 优先从 QuickLaunchPath 读取
        if ($content -match 'QuickLaunchPath\s*=\s*(.+?)\r?\n') {
            $quickRelative = $Matches[1].Trim()
        } elseif ($content -match 'IconResource\s*=\s*(.+?)\r?\n') {
            # 如果没有，从 IconResource 读取并清理（兼容旧版）
            $rawValue = $Matches[1].Trim()
            $cleanValue = $rawValue -replace '^@', '' -replace ',\d+$', ''
            $quickRelative = $cleanValue.Trim()
        }
    } catch { }
}

if ([string]::IsNullOrWhiteSpace($quickRelative)) { exit }

# 拼接成绝对路径
$targetPath = Join-Path $folderPath $quickRelative

if (Test-Path $targetPath) {
    Start-Process -FilePath $targetPath
}
# 文件不存在时静默退出，不打扰用户