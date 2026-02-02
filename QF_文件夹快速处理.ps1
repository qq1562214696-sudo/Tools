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

# 添加 Windows Forms 程序集
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 创建主窗体
$form = New-Object System.Windows.Forms.Form
$form.Text = "文件夹文件规范整理"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.AutoScroll = $true

# 标题标签
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "请输入要创建的文件名（每行一个）："
$lblTitle.Location = New-Object System.Drawing.Point(20, 20)
$lblTitle.Size = New-Object System.Drawing.Size(400, 25)
$lblTitle.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblTitle)

# 说明标签
$lblDesc = New-Object System.Windows.Forms.Label
$lblDesc.Text = "文件名格式：类型_编号（如 Hand_00001）"
$lblDesc.Location = New-Object System.Drawing.Point(20, 45)
$lblDesc.Size = New-Object System.Drawing.Size(400, 20)
$lblDesc.ForeColor = [System.Drawing.Color]::Gray
$form.Controls.Add($lblDesc)

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
    $txt.Size = New-Object System.Drawing.Size(350, 25)
    $txt.Text = $fileName
    $panel.Controls.Add($txt)
    
    # 创建删除按钮
    $btnDel = New-Object System.Windows.Forms.Button
    $btnDel.Text = "删除"
    $btnDel.Location = New-Object System.Drawing.Point(440, $yPos)
    $btnDel.Size = New-Object System.Drawing.Size(60, 25)
    $btnDel.Tag = $script:itemList.Count  # 存储索引
    $btnDel.Add_Click({
        Remove-Item -index $this.Tag
    })
    $panel.Controls.Add($btnDel)
    
    # 添加到列表
    $script:itemList += @{
        CheckBox = $chk
        TextBox = $txt
        DeleteButton = $btnDel
    }
}

# 删除项目函数
function Remove-Item {
    param([int]$index)
    
    # 移除控件
    $panel.Controls.Remove($script:itemList[$index].CheckBox)
    $panel.Controls.Remove($script:itemList[$index].TextBox)
    $panel.Controls.Remove($script:itemList[$index].DeleteButton)
    
    # 从列表移除
    $script:itemList = $script:itemList | Where-Object { $_ -ne $script:itemList[$index] }
    
    # 重新排列
    Refresh-Items
}

# 刷新列表位置
function Refresh-Items {
    for ($i = 0; $i -lt $script:itemList.Count; $i++) {
        $yPos = $i * 40 + 10
        $script:itemList[$i].CheckBox.Location = New-Object System.Drawing.Point(10, $yPos)
        $script:itemList[$i].TextBox.Location = New-Object System.Drawing.Point(100, $yPos)
        $script:itemList[$index].DeleteButton.Location = New-Object System.Drawing.Point(440, $yPos)
        $script:itemList[$i].DeleteButton.Tag = $i
    }
}

# 添加第一个默认项
Add-Item -fileName "Hand_手持" -transparent $true

# 添加条目按钮
$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = "➕ 添加条目"
$btnAdd.Location = New-Object System.Drawing.Point(20, 330)
$btnAdd.Size = New-Object System.Drawing.Size(120, 35)
$btnAdd.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
$btnAdd.Add_Click({ Add-Item })
$form.Controls.Add($btnAdd)

# 确定按钮
$btnOK = New-Object System.Windows.Forms.Button
$btnOK.Text = "✔ 开始处理"
$btnOK.Location = New-Object System.Drawing.Point(240, 330)
$btnOK.Size = New-Object System.Drawing.Size(120, 35)
$btnOK.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Bold)
$btnOK.BackColor = [System.Drawing.Color]::LightGreen
$form.Controls.Add($btnOK)

# 取消按钮
$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "✖ 取消"
$btnCancel.Location = New-Object System.Drawing.Point(380, 330)
$btnCancel.Size = New-Object System.Drawing.Size(120, 35)
$btnCancel.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
$btnCancel.Add_Click({ $form.Close() })
$form.Controls.Add($btnCancel)

# 删除源文件选项
$chkDeleteSource = New-Object System.Windows.Forms.CheckBox
$chkDeleteSource.Text = "处理完成后删除源文件（Hand_手持等模板文件夹和待改_截图.jpg）"
$chkDeleteSource.Location = New-Object System.Drawing.Point(20, 380)
$chkDeleteSource.Size = New-Object System.Drawing.Size(500, 25)
$chkDeleteSource.Checked = $true
$form.Controls.Add($chkDeleteSource)

# 状态标签
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = ""
$lblStatus.Location = New-Object System.Drawing.Point(20, 420)
$lblStatus.Size = New-Object System.Drawing.Size(550, 20)
$lblStatus.ForeColor = [System.Drawing.Color]::Blue
$form.Controls.Add($lblStatus)

# 处理文件夹函数
function Process-Folders {
    # 更新状态
    $lblStatus.Text = "正在处理..."
    $lblStatus.ForeColor = [System.Drawing.Color]::Blue
    $form.Refresh()
    
    # 收集所有输入
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
    
    # 收集原始模板文件夹（用于后续删除）
    $originalFolders = @()
    $allFolders = Get-ChildItem -Path $targetFolder -Directory
    foreach ($folder in $allFolders) {
        if ($folder.Name -match "^(.+?)_.+$" -and $folder.Name -ne "Assets" -and $folder.Name -ne "截图") {
            $originalFolders += @{
                Name = $folder.Name
                FullPath = $folder.FullName
                Prefix = $Matches[1]
            }
        }
    }
    
    # 收集原始截图文件
    $screenshotFolder = Join-Path $targetFolder "截图"
    $screenshotFile = Join-Path $screenshotFolder "待改_截图.jpg"
    
    $successCount = 0
    $errorCount = 0
    
    # 存储已处理的源文件夹（用于后续删除）
    $processedSourceFolders = @()
    
    # 处理每个输入的文件名
    foreach ($item in $items) {
        $fileName = $item.Name
        $isTransparent = $item.Transparent
        
        # 分割文件名获取前缀（如Hand、Head、Wing等）
        if ($fileName -match "^(.+?)_(.+)$") {
            $prefix = $Matches[1]
            
            # 查找匹配前缀的源文件夹
            $sourceFolder = $originalFolders | Where-Object { 
                $_.Prefix -eq $prefix
            } | Select-Object -First 1
            
            if ($sourceFolder) {
                $sourcePath = $sourceFolder.FullPath
                $targetPath = Join-Path $targetFolder $fileName
                
                try {
                    # 检查目标文件夹是否已存在
                    if (Test-Path $targetPath) {
                        $result = [System.Windows.Forms.MessageBox]::Show("文件夹 '$fileName' 已存在，是否覆盖？", "确认", "YesNo", "Question")
                        if ($result -eq "No") {
                            Write-Host "跳过已存在的文件夹: $fileName" -ForegroundColor Yellow
                            continue
                        }
                        # 删除已存在的文件夹
                        Remove-Item -Path $targetPath -Recurse -Force -ErrorAction Stop
                    }
                    
                    # 复制整个文件夹
                    Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
                    
                    # 重命名.max文件
                    $maxFile = Get-ChildItem -Path $targetPath -Filter "*$prefix*.max" | Select-Object -First 1
                    if ($maxFile) {
                        $newMaxName = "$fileName.max"
                        Rename-Item -Path $maxFile.FullName -NewName $newMaxName -Force
                    }
                    
                    # 处理图片文件
                    $imageFiles = Get-ChildItem -Path $targetPath -File | Where-Object {
                        $_.Extension -match "\.(png|psd)$"
                    }
                    
                    foreach ($imgFile in $imageFiles) {
                        $baseName = $imgFile.BaseName
                        $extension = $imgFile.Extension
                        
                        if ($baseName -match ".*_A$" -and $extension -eq ".png") {
                            if (-not $isTransparent) {
                                # 如果不透明，删除_A.png文件
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
                    
                    # 处理截图文件夹
                    if (Test-Path $screenshotFile -PathType Leaf) {
                        $newScreenshotName = "$fileName.jpg"
                        $targetScreenshot = Join-Path $screenshotFolder $newScreenshotName
                        Copy-Item -Path $screenshotFile -Destination $targetScreenshot -Force
                    }
                    
                    # 记录已处理的源文件夹
                    $processedSourceFolders += $sourceFolder
                    
                    $successCount++
                    Write-Host "成功处理: $fileName" -ForegroundColor Green
                    
                } catch {
                    Write-Host "处理 $fileName 时出错: $_" -ForegroundColor Red
                    $errorCount++
                }
            } else {
                Write-Host "未找到匹配前缀 '$prefix' 的源文件夹" -ForegroundColor Yellow
                $errorCount++
            }
        } else {
            Write-Host "文件名格式不正确，应使用 '前缀_描述' 格式: $fileName" -ForegroundColor Yellow
            $errorCount++
        }
    }
    
    # 删除源文件（如果用户选择）
    if ($chkDeleteSource.Checked) {
        try {
            # 删除已处理过的模板文件夹（避免删除未使用的模板）
            foreach ($folder in $processedSourceFolders) {
                if (Test-Path $folder.FullPath) {
                    Remove-Item -Path $folder.FullPath -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "已删除模板文件夹: $($folder.Name)" -ForegroundColor Cyan
                }
            }
            
            # 删除待改_截图.jpg（只有在有成功处理时才删除）
            if ($successCount -gt 0 -and (Test-Path $screenshotFile)) {
                Remove-Item -Path $screenshotFile -Force -ErrorAction SilentlyContinue
                Write-Host "已删除待改_截图.jpg" -ForegroundColor Cyan
            }
        } catch {
            Write-Host "删除源文件时出错: $_" -ForegroundColor Red
        }
    }
    
    # 更新状态
    if ($successCount -gt 0) {
        $lblStatus.Text = "处理完成！成功: $successCount 个，失败: $errorCount 个"
        $lblStatus.ForeColor = [System.Drawing.Color]::Green
        
        # 打开总文件夹
        Start-Process "explorer.exe" -ArgumentList $targetFolder
        
        # 2秒后关闭窗口
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 2000
        $timer.Add_Tick({
            $timer.Stop()
            $form.Close()
        })
        $timer.Start()
    } else {
        $lblStatus.Text = "处理失败！请检查文件名格式和源文件夹是否存在"
        $lblStatus.ForeColor = [System.Drawing.Color]::Red
    }
}

# 确定按钮点击事件
$btnOK.Add_Click({
    Process-Folders
})

# 显示窗体
[void]$form.ShowDialog()