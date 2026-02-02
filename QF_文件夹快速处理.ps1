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
    $lblStatus.Text = "正在标记源文件..."
    $lblStatus.ForeColor = [System.Drawing.Color]::Blue
    $form.Refresh()
   
    $items = @()
    foreach ($item in $script:itemList) {
        $name = $item.TextBox.Text.Trim()
        if (-not [string]::IsNullOrWhiteSpace($name)) {
            $items += @{
                Name = $name
                Transparent = $item.CheckBox.Checked
            }
        }
    }
   
    if ($items.Count -eq 0) {
        $lblStatus.Text = "请至少输入一个文件名！"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
        [System.Windows.Forms.MessageBox]::Show("请至少输入一个文件名！", "提示", "OK", "Warning")
        return
    }
    
    # 存储标记项目的信息
    $markedItems = @()
    
    # 第一步：标记所有下划线后面不是数字的文件夹
    $allFolders = Get-ChildItem -Path $targetFolder -Directory |
        Where-Object { $_.Name -match '_' -and $_.Name -notin @("Assets", "截图") }
    
    foreach ($folder in $allFolders) {
        $folderName = $folder.Name
        
        if ($folderName -match "^(.+?)_(.+)$") {
            $suffix = $Matches[2]
            
            # 如果下划线后面的部分不是纯数字，则标记（例如：Hand_手持）
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
    
    # 第二步：标记待改_截图.jpg
    $screenshotFolder = Join-Path $targetFolder "截图"
    $screenshotFile = Join-Path $screenshotFolder "待改_截图.jpg"
    $screenshotFileMarked = Join-Path $screenshotFolder "待改_截图_删.jpg"
    
    if (Test-Path $screenshotFile) {
        try {
            # 如果已经有标记的文件，先删除它
            if (Test-Path $screenshotFileMarked) {
                Remove-Item $screenshotFileMarked -Force -ErrorAction SilentlyContinue
            }
            
            Rename-Item -Path $screenshotFile -NewName "待改_截图_删.jpg" -Force
            
            $markedItems += @{
                Type = "File"
                OriginalPath = $screenshotFile
                MarkedPath = $screenshotFileMarked
                OriginalName = "待改_截图.jpg"
                MarkedName = "待改_截图_删.jpg"
            }
        } catch {
            # 如果重命名失败，继续
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
            
            # 查找标记后的模板文件夹（去掉"_删"后缀来匹配前缀）
            $sourceFolder = $markedTemplates | Where-Object { 
                $baseName = $_.Name -replace '_删$', ''
                $baseName -match "^${prefix}_"
            } | Select-Object -First 1
            
            if ($sourceFolder) {
                $sourcePath = $sourceFolder.FullName
                $targetPath = Join-Path $targetFolder $fileName
                
                try {
                    if (Test-Path $targetPath) {
                        $result = [System.Windows.Forms.MessageBox]::Show("文件夹 '$fileName' 已存在，是否覆盖？", "确认", "YesNo", "Question")
                        if ($result -eq "No") { continue }
                        Remove-Item -Path $targetPath -Recurse -Force
                    }
                    
                    Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
                    
                    # 重命名.max文件
                    $maxFile = Get-ChildItem -Path $targetPath -Filter "*.max" | Select-Object -First 1
                    if ($maxFile) {
                        Rename-Item -Path $maxFile.FullName -NewName "$fileName.max" -Force
                    }
                    
                    # 图片处理
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
                    
                    # 复制截图
                    if (Test-Path $screenshotFileMarked -PathType Leaf) {
                        $newScreenshotName = "$fileName.jpg"
                        $targetScreenshot = Join-Path $screenshotFolder $newScreenshotName
                        Copy-Item -Path $screenshotFileMarked -Destination $targetScreenshot -Force
                    }
                    
                    $successCount++
                } catch {
                    $errorCount++
                }
            } else {
                $errorCount++
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
                    } else {
                        Remove-Item $markedItem.MarkedPath -Force -ErrorAction SilentlyContinue
                    }
                }
            } catch {
                # 如果删除失败，尝试强制删除
                try {
                    if (Test-Path $markedItem.MarkedPath) {
                        if ($markedItem.Type -eq "Folder") {
                            cmd /c "rd /s /q `"$($markedItem.MarkedPath)`""
                        } else {
                            cmd /c "del /f /q `"$($markedItem.MarkedPath)`""
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
    $lblStatus.Text = "处理完成！成功: $successCount 个，失败: $errorCount 个"
    $lblStatus.ForeColor = if ($successCount -gt 0) { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::Red }
       
    # 关闭窗口
    $form.Close()
}

$btnOK.Add_Click({ Process-Folders })

[void]$form.ShowDialog()