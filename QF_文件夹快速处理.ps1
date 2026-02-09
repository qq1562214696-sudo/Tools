# 文件夹文件规范整理工具
# 右键点击总文件夹运行此脚本
param (
    [string]$targetFolder
)

# 校验路径
if (-not (Test-Path $targetFolder -PathType Container)) {
    [System.Windows.Forms.MessageBox]::Show("请选择一个有效的文件夹路径！", "错误", "OK", "Error")
    exit
}

# 检查是否为总文件夹结构
$hasAssets = Test-Path (Join-Path $targetFolder "Assets") -PathType Container
$hasScreenshot = Test-Path (Join-Path $targetFolder "截图") -PathType Container
if (-not ($hasAssets -and $hasScreenshot)) {
    [System.Windows.Forms.MessageBox]::Show("选择的文件夹不符合总文件夹结构！`n应包含 Assets 和 截图 文件夹", "错误", "OK", "Error")
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 创建主窗体
$form = New-Object System.Windows.Forms.Form
$form.Text = "文件夹文件规范整理"
$form.Size = New-Object System.Drawing.Size(600, 430)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# 标题标签
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "请输入要创建的文件名（每行一个）：类型_编号（如 Hand_00001）"
$lblTitle.Location = New-Object System.Drawing.Point(20, 10)
$lblTitle.Size = New-Object System.Drawing.Size(600, 25)
$lblTitle.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblTitle)

# 删除源文件选项
$chkDeleteSource = New-Object System.Windows.Forms.CheckBox
$chkDeleteSource.Text = "删除原模板"
$chkDeleteSource.Location = New-Object System.Drawing.Point(20, 40)
$chkDeleteSource.Size = New-Object System.Drawing.Size(500, 25)
$chkDeleteSource.Checked = $true
$form.Controls.Add($chkDeleteSource)

# 容器面板（用于放置动态列表）
$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(20, 70)
$panel.Size = New-Object System.Drawing.Size(540, 250)
$panel.AutoScroll = $true
$panel.BorderStyle = "FixedSingle"
$form.Controls.Add($panel)

# 全局变量存储动态控件
$script:itemList = @()

# 添加项目函数
function Add-Item {
    param([string]$fileName = "", [bool]$transparent = $true)
   
    $yPos = $script:itemList.Count * 40 + 10
   
    # 创建复选框
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = "透明贴图"
    $chk.Location = New-Object System.Drawing.Point(10, $yPos)
    $chk.Size = New-Object System.Drawing.Size(80, 25)
    $chk.Checked = $transparent
    $panel.Controls.Add($chk)
   
    # 创建文本框
    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Location = New-Object System.Drawing.Point(100, $yPos)
    $txt.Size = New-Object System.Drawing.Size(330, 25)
    $txt.Text = $fileName
    $panel.Controls.Add($txt)
   
    # 创建删除按钮
    $btnDel = New-Object System.Windows.Forms.Button
    $btnDel.Text = "删除"
    $btnDel.Location = New-Object System.Drawing.Point(440, $yPos)
    $btnDel.Size = New-Object System.Drawing.Size(60, 25)
    $btnDel.Tag = $script:itemList.Count
    $btnDel.Add_Click({
        Remove-Item -index $this.Tag
    })
    $panel.Controls.Add($btnDel)
   
    $script:itemList += @{
        CheckBox = $chk
        TextBox = $txt
        DeleteButton = $btnDel
    }
}

# 删除项目函数
function Remove-Item {
    param([int]$index)
   
    $panel.Controls.Remove($script:itemList[$index].CheckBox)
    $panel.Controls.Remove($script:itemList[$index].TextBox)
    $panel.Controls.Remove($script:itemList[$index].DeleteButton)
   
    $script:itemList = $script:itemList | Where-Object { $_ -ne $script:itemList[$index] }
   
    Refresh-Items
}

# 刷新列表位置
function Refresh-Items {
    for ($i = 0; $i -lt $script:itemList.Count; $i++) {
        $yPos = $i * 40 + 10
        $script:itemList[$i].CheckBox.Location = New-Object System.Drawing.Point(10, $yPos)
        $script:itemList[$i].TextBox.Location = New-Object System.Drawing.Point(100, $yPos)
        $script:itemList[$i].DeleteButton.Location = New-Object System.Drawing.Point(440, $yPos)
        $script:itemList[$i].DeleteButton.Tag = $i
    }
}

Add-Item -fileName "Hand_00001" -transparent $true

# 添加条目按钮
$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = "➕ 新增道具"
$btnAdd.Location = New-Object System.Drawing.Point(20, 330)
$btnAdd.Size = New-Object System.Drawing.Size(120, 35)
$btnAdd.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
$btnAdd.Add_Click({ Add-Item })
$form.Controls.Add($btnAdd)

# 确定按钮
$btnOK = New-Object System.Windows.Forms.Button
$btnOK.Text = "✔ 创建道具"
$btnOK.Location = New-Object System.Drawing.Point(435, 330)
$btnOK.Size = New-Object System.Drawing.Size(120, 35)
$btnOK.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Bold)
$btnOK.BackColor = [System.Drawing.Color]::LightGreen
$form.Controls.Add($btnOK)

# 状态标签
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = ""
$lblStatus.Location = New-Object System.Drawing.Point(20, 420)
$lblStatus.Size = New-Object System.Drawing.Size(550, 20)
$lblStatus.ForeColor = [System.Drawing.Color]::Blue
$form.Controls.Add($lblStatus)

# 处理文件夹函数
function Process-Folders {
    $lblStatus.Text = "正在收集并复制命名..."
    $lblStatus.ForeColor = [System.Drawing.Color]::Blue
    $form.Refresh()
   
    # 收集所有有效的命名
    $items = @()
    $validNames = @()
    foreach ($item in $script:itemList) {
        $name = $item.TextBox.Text.Trim()
        if (-not [string]::IsNullOrWhiteSpace($name)) {
            $items += @{
                Name = $name
                Transparent = $item.CheckBox.Checked
            }
            $validNames += $name
        }
    }
   
    if ($items.Count -eq 0) {
        $lblStatus.Text = "请至少输入一个文件名！"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
        [System.Windows.Forms.MessageBox]::Show("请至少输入一个文件名！", "提示", "OK", "Warning")
        return
    }
    
    # 第一步：自动复制命名到剪贴板
    $textToCopy = $validNames -join "`n"
    [System.Windows.Forms.Clipboard]::SetText($textToCopy)
    $lblStatus.Text = "已复制 $($validNames.Count) 个命名到剪贴板，开始处理文件..."
    $lblStatus.ForeColor = [System.Drawing.Color]::Green
    $form.Refresh()
    
    # 第二步：标记源文件
    $lblStatus.Text = "正在标记源文件..."
    $lblStatus.ForeColor = [System.Drawing.Color]::Blue
    $form.Refresh()
    
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
                        
                        # 重命名文件夹
                        Rename-Item -Path $folder.FullName -NewName $newName -Force
                        
                        $markedItems += @{
                            Type = "Folder"
                            OriginalPath = $folder.FullName
                            MarkedPath = $newPath
                            OriginalName = $folderName
                            MarkedName = $newName
                        }
                    } catch {
                        # 如果重命名失败，继续下一个
                    }
                }
            }
        }
    }
    
    # 第三步：使用标记后的模板文件夹创建新文件夹
    $lblStatus.Text = "正在创建新文件夹..."
    $form.Refresh()
    
    $successCount = 0
    $errorCount = 0
    
    # 获取所有标记后的模板文件夹
    $markedTemplates = Get-ChildItem -Path $targetFolder -Directory |
        Where-Object { $_.Name.EndsWith("_删") }
    
    foreach ($item in $items) {
        $fileName = $item.Name
        $isTransparent = $item.Transparent
        
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
                        $result = [System.Windows.Forms.MessageBox]::Show("文件夹 '$newFolderName' 已存在，是否覆盖？", "确认", "YesNo", "Question")
                        if ($result -eq "No") { continue }
                        Remove-Item -Path $targetPath -Recurse -Force
                    }
                    
                    # 复制文件夹
                    Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
                    
                    # 重命名.max文件 - 使用原始文件名（不带_boy/_girl后缀）
                    $maxFile = Get-ChildItem -Path $targetPath -Filter "*.max" | Select-Object -First 1
                    if ($maxFile) {
                        Rename-Item -Path $maxFile.FullName -NewName "$fileName.max" -Force
                    }
                    
                    # 图片处理 - 使用原始文件名（不带_boy/_girl后缀）
                    $imageFiles = Get-ChildItem -Path $targetPath -File | Where-Object {
                        $_.Extension -match "\.(png|psd)$"
                    }
                    
                    foreach ($imgFile in $imageFiles) {
                        $baseName = $imgFile.BaseName
                        $extension = $imgFile.Extension
                        
                        if ($baseName -match ".*_A$" -and $extension -eq ".png") {
                            if (-not $isTransparent) {
                                Remove-Item -Path $imgFile.FullName -Force
                            } else {
                                $newImageName = "$fileName" + "_A.png"
                                Rename-Item -Path $imgFile.FullName -NewName $newImageName -Force
                            }
                        } elseif ($baseName -match ".*_D$" -and $extension -eq ".png") {
                            $newImageName = "$fileName" + "_D.png"
                            Rename-Item -Path $imgFile.FullName -NewName $newImageName -Force
                        } elseif ($baseName -match ".*_D$" -and $extension -eq ".psd") {
                            $newImageName = "$fileName" + "_D.psd"
                            Rename-Item -Path $imgFile.FullName -NewName $newImageName -Force
                        }
                    }
                    
                    $successCount++
                } catch {
                    $errorCount++
                }
            }
        } else {
            $errorCount++
        }
    }
    
    # 第四步：立即处理标记项目 - 删除或还原
    $lblStatus.Text = "正在处理标记文件..."
    $form.Refresh()
    
    if ($chkDeleteSource.Checked) {
        # 删除所有标记的项目
        foreach ($markedItem in $markedItems) {
            try {
                if (Test-Path $markedItem.MarkedPath) {
                    if ($markedItem.Type -eq "Folder") {
                        Remove-Item $markedItem.MarkedPath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            } catch {
                # 如果删除失败，尝试强制删除
                try {
                    if (Test-Path $markedItem.MarkedPath) {
                        if ($markedItem.Type -eq "Folder") {
                            cmd /c "rd /s /q `"$($markedItem.MarkedPath)`""
                        }
                    }
                } catch {
                    # 忽略所有错误
                }
            }
        }
    } else {
        # 还原所有标记的项目（去掉"_删"后缀）
        foreach ($markedItem in $markedItems) {
            try {
                if (Test-Path $markedItem.MarkedPath) {
                    Rename-Item -Path $markedItem.MarkedPath -NewName $markedItem.OriginalName -Force
                }
            } catch {
                # 如果还原失败，继续下一个
            }
        }
    }
    
    # 第五步：显示结果并关闭
    $lblStatus.Text = "处理完成！成功: $successCount 个，失败: $errorCount 个，命名已复制"
    $lblStatus.ForeColor = if ($successCount -gt 0) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }

    $form.Close()
}

$btnOK.Add_Click({ Process-Folders })

[void]$form.ShowDialog()