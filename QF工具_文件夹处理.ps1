# 文件夹文件规范整理工具
# 右键点击总文件夹运行此脚本
param (
    [string]$targetFolder
)

Add-Type -AssemblyName System.Windows.Forms

# 校验路径
if (-not (Test-Path $targetFolder -PathType Container)) {
    [System.Windows.Forms.MessageBox]::Show("请选择一个有效的文件夹路径！", "错误", "OK", "Error")
    exit
}

# 检查是否为总文件夹结构，如果不是则查找"提交文件夹"
$originalFolder = $targetFolder
$hasAssets = Test-Path (Join-Path $targetFolder "Assets") -PathType Container
$hasScreenshot = Test-Path (Join-Path $targetFolder "截图") -PathType Container

if (-not ($hasAssets -and $hasScreenshot)) {
    # 查找"提交文件夹"
    $submitFolder = Get-ChildItem -Path $targetFolder -Directory -Filter "提交文件夹" | Select-Object -First 1
    if ($submitFolder) {
        $targetFolder = $submitFolder.FullName
        Write-Host "检测到提交文件夹，自动切换到: $targetFolder" -ForegroundColor Cyan
        
        # 重新检查新路径
        $hasAssets = Test-Path (Join-Path $targetFolder "Assets") -PathType Container
        $hasScreenshot = Test-Path (Join-Path $targetFolder "截图") -PathType Container
    }
}

# 再次检查是否为总文件夹结构
if (-not ($hasAssets -and $hasScreenshot)) {
    [System.Windows.Forms.MessageBox]::Show("选择的文件夹不符合总文件夹结构！`n应包含 Assets 和 截图 文件夹", "错误", "OK", "Error")
    exit
}

# 第一步：查找同级目录下的.psd文件并提取命名
$parentFolder = Split-Path $targetFolder -Parent
$psdFiles = Get-ChildItem -Path $parentFolder -Filter "*.psd" -Recurse -ErrorAction SilentlyContinue

# 从.psd文件名中提取命名（格式：前缀_数字）
$validNames = @()
foreach ($psdFile in $psdFiles) {
    $fileName = $psdFile.BaseName
    if ($fileName -match "^([A-Za-z]+)_(\d+)") {
        $prefix = $Matches[1]
        $number = $Matches[2]
        $newName = "${prefix}_${number}"
        $validNames += $newName
    }
}

# 去重并排序
$validNames = $validNames | Sort-Object -Unique

if ($validNames.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("在同级目录下未找到符合格式的.psd文件！`n格式应为：前缀_数字（如 Hand_00001）", "提示", "OK", "Warning")
    exit
}

# 只显示一个确认面板
$confirmMessage = "找到 $($validNames.Count) 个道具：`n`n"
$confirmMessage += ($validNames -join "`n")
$confirmMessage += "`n`n点确定执行所有操作，点取消退出。"

$result = [System.Windows.Forms.MessageBox]::Show($confirmMessage, "确认操作", "OKCancel", "Question")
if ($result -ne "OK") {
    exit
}

# 第二步：复制命名到剪贴板（静默执行，不提示）
$textToCopy = $validNames -join "`n"
[System.Windows.Forms.Clipboard]::SetText($textToCopy)

# 第三步：提取贴图到总文件夹
Write-Host "正在提取公共贴图到总文件夹..." -ForegroundColor Blue

# 定义贴图文件模式
$texturePatterns = @("*_A.png", "*_D.png", "*_D.psd")

# 检查是否已存在公共贴图
$hasCommonTextures = $true
foreach ($pattern in $texturePatterns) {
    if (-not (Get-ChildItem -Path $targetFolder -Filter $pattern -ErrorAction SilentlyContinue)) {
        $hasCommonTextures = $false
        break
    }
}

# 如果总文件夹没有公共贴图，从第一个模板文件夹中提取
if (-not $hasCommonTextures) {
    # 查找第一个模板文件夹（排除Assets和截图）
    $templateFolders = Get-ChildItem -Path $targetFolder -Directory |
        Where-Object { $_.Name -notin @("Assets", "截图") } |
        Select-Object -First 1
    
    if ($templateFolders) {
        $firstTemplate = $templateFolders[0]
        Write-Host "从模板文件夹提取公共贴图: $($firstTemplate.Name)" -ForegroundColor Cyan
        
        foreach ($pattern in $texturePatterns) {
            $textureFiles = Get-ChildItem -Path $firstTemplate.FullName -Filter $pattern -ErrorAction SilentlyContinue
            foreach ($textureFile in $textureFiles) {
                $destPath = Join-Path $targetFolder $textureFile.Name
                if (-not (Test-Path $destPath)) {
                    Copy-Item -Path $textureFile.FullName -Destination $destPath -Force
                    Write-Host "  提取: $($textureFile.Name)" -ForegroundColor Green
                }
            }
        }
    } else {
        Write-Host "未找到模板文件夹，无法提取公共贴图" -ForegroundColor Yellow
    }
} else {
    Write-Host "公共贴图已存在于总文件夹" -ForegroundColor Cyan
}

# 第四步：标记源文件并删除模板文件夹中的贴图
Write-Host "正在标记源文件并清理重复贴图..." -ForegroundColor Blue

# 存储标记项目的信息
$markedItems = @()

# 标记所有下划线后面不是数字的文件夹
$allFolders = Get-ChildItem -Path $targetFolder -Directory |
    Where-Object { $_.Name -match '_' -and $_.Name -notin @("Assets", "截图") }

foreach ($folder in $allFolders) {
    $folderName = $folder.Name
    
    if ($folderName -match "^(.+?)_(.+)$") {
        $suffix = $Matches[2]
        
        # 如果下划线后面的部分不是纯数字，则标记
        if (-not ($suffix -match "^\d+$")) {
            # 检查是否已经被标记过
            if (-not $folderName.EndsWith("_删")) {
                $newName = "${folderName}_删"
                $newPath = Join-Path $targetFolder $newName
                
                try {
                    # 如果已经有标记的文件，先删除它
                    if (Test-Path $newPath) {
                        Remove-Item $newPath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                    
                    # 先删除模板文件夹中的贴图文件（节省空间）
                    foreach ($pattern in $texturePatterns) {
                        $textureFiles = Get-ChildItem -Path $folder.FullName -Filter $pattern -ErrorAction SilentlyContinue
                        foreach ($textureFile in $textureFiles) {
                            Remove-Item -Path $textureFile.FullName -Force -ErrorAction SilentlyContinue
                            Write-Host "  删除模板贴图: $($folder.Name)\$($textureFile.Name)" -ForegroundColor DarkGray
                        }
                    }
                    
                    # 重命名文件夹
                    Rename-Item -Path $folder.FullName -NewName $newName -Force
                    
                    $markedItems += @{
                        Type = "Folder"
                        OriginalPath = $folder.FullName
                        MarkedPath = $newPath
                        OriginalName = $folderName
                        MarkedName = $newName
                    }
                    Write-Host "已标记: $folderName -> $newName" -ForegroundColor Yellow
                } catch {
                    Write-Host "标记失败: $folderName" -ForegroundColor Red
                }
            }
        }
    }
}

# 第五步：使用标记后的模板文件夹创建新文件夹
Write-Host "正在创建新文件夹..." -ForegroundColor Blue

# 获取所有标记后的模板文件夹
$markedTemplates = Get-ChildItem -Path $targetFolder -Directory |
    Where-Object { $_.Name.EndsWith("_删") }

$successCount = 0
$errorCount = 0

# 获取总文件夹中的公共贴图文件
$commonTextures = @()
foreach ($pattern in $texturePatterns) {
    $commonTextures += Get-ChildItem -Path $targetFolder -Filter $pattern -ErrorAction SilentlyContinue
}

Write-Host "找到 $($commonTextures.Count) 个公共贴图文件" -ForegroundColor Cyan

foreach ($fileName in $validNames) {
    if ($fileName -match "^(.+?)_(.+)$") {
        $prefix = $Matches[1]
        
        # 查找标记后的模板文件夹
        # 1. 首先查找是否有_boy和_girl后缀的模板
        $boyTemplate = $null
        $girlTemplate = $null
        $genericTemplate = $null
        
        foreach ($template in $markedTemplates) {
            $baseName = $template.Name -replace '_删$', ''
            
            # 检查是否匹配前缀
            if ($baseName -match "^${prefix}_") {
                # 检查是否是_boy模板
                if ($baseName -match '_boy$') {
                    $boyTemplate = $template
                }
                # 检查是否是_girl模板
                elseif ($baseName -match '_girl$') {
                    $girlTemplate = $template
                }
                # 检查是否是通用模板（没有_boy或_girl后缀）
                elseif (-not ($baseName -match '_(boy|girl)$')) {
                    $genericTemplate = $template
                }
            }
        }
        
        # 根据找到的模板决定创建哪些文件夹
        $templatesToProcess = @()
        
        if ($boyTemplate -and $girlTemplate) {
            # 同时存在_boy和_girl模板，创建两份
            $templatesToProcess += @{
                Template = $boyTemplate
                Suffix = "_boy"
            }
            $templatesToProcess += @{
                Template = $girlTemplate
                Suffix = "_girl"
            }
        }
        elseif ($genericTemplate) {
            # 只有通用模板，创建一份
            $templatesToProcess += @{
                Template = $genericTemplate
                Suffix = ""
            }
        }
        elseif ($boyTemplate -or $girlTemplate) {
            # 只有_boy或_girl模板中的一个，也创建一份（带相应后缀）
            if ($boyTemplate) {
                $templatesToProcess += @{
                    Template = $boyTemplate
                    Suffix = "_boy"
                }
            }
            else {
                $templatesToProcess += @{
                    Template = $girlTemplate
                    Suffix = "_girl"
                }
            }
        }
        else {
            # 没有找到任何匹配的模板
            Write-Host "未找到模板: $fileName" -ForegroundColor Red
            $errorCount++
            continue
        }
        
        # 处理每个模板
        foreach ($templateInfo in $templatesToProcess) {
            $sourceFolder = $templateInfo.Template
            $suffix = $templateInfo.Suffix
            $newFolderName = $fileName + $suffix  # 文件夹名带后缀
            $sourcePath = $sourceFolder.FullName
            $targetPath = Join-Path $targetFolder $newFolderName
            
            try {
                if (Test-Path $targetPath) {
                    # 自动覆盖已存在的文件夹
                    Remove-Item -Path $targetPath -Recurse -Force -ErrorAction SilentlyContinue
                }
                
                # 创建新文件夹
                New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
                Write-Host "创建文件夹: $newFolderName" -ForegroundColor Green
                
                # 复制.max文件
                $maxFile = Get-ChildItem -Path $sourcePath -Filter "*.max" | Select-Object -First 1
                if ($maxFile) {
                    $newMaxName = "$fileName.max"
                    Copy-Item -Path $maxFile.FullName -Destination (Join-Path $targetPath $newMaxName) -Force
                    Write-Host "  复制.max文件: $newMaxName" -ForegroundColor Cyan
                } else {
                    Write-Host "  警告: 未找到.max文件" -ForegroundColor Yellow
                }
                
                # 复制公共贴图并重命名
                foreach ($textureFile in $commonTextures) {
                    $textureBaseName = $textureFile.BaseName  # 获取不带扩展名的文件名
                    $textureExtension = $textureFile.Extension  # 获取扩展名
                    
                    # 提取贴图类型后缀（_A, _D等）
                    if ($textureBaseName -match "_(A|D)$") {
                        $textureSuffix = $Matches[0]  # 获取_A或_D后缀
                        $newTextureName = "${fileName}${textureSuffix}${textureExtension}"
                        $destTexturePath = Join-Path $targetPath $newTextureName
                        
                        Copy-Item -Path $textureFile.FullName -Destination $destTexturePath -Force
                        Write-Host "  复制贴图: $newTextureName" -ForegroundColor Cyan
                    } else {
                        Write-Host "  跳过非标准贴图: $($textureFile.Name)" -ForegroundColor Yellow
                    }
                }
                
                $successCount++
            } catch {
                Write-Host "创建失败: $newFolderName - $($_.Exception.Message)" -ForegroundColor Red
                $errorCount++
            }
        }
    } else {
        Write-Host "命名格式错误: $fileName" -ForegroundColor Red
        $errorCount++
    }
}

# 第六步：删除所有标记的项目
Write-Host "正在删除原模板文件夹..." -ForegroundColor Blue
foreach ($markedItem in $markedItems) {
    try {
        if (Test-Path $markedItem.MarkedPath) {
            Remove-Item $markedItem.MarkedPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "已删除: $($markedItem.MarkedName)" -ForegroundColor DarkGray
        }
    } catch {
        # 如果删除失败，尝试强制删除
        try {
            if (Test-Path $markedItem.MarkedPath) {
                cmd /c "rd /s /q `"$($markedItem.MarkedPath)`""
            }
        } catch {
            # 忽略所有错误
        }
    }
}

# 第七步：自动删除总文件夹中的原贴图（不询问）
Write-Host "正在删除总文件夹中的原贴图..." -ForegroundColor Blue
foreach ($textureFile in $commonTextures) {
    try {
        if (Test-Path $textureFile.FullName) {
            Remove-Item -Path $textureFile.FullName -Force -ErrorAction SilentlyContinue
            Write-Host "已删除原贴图: $($textureFile.Name)" -ForegroundColor DarkGray
        }
    } catch {
        # 忽略删除错误
    }
}