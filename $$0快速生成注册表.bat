@echo off
setlocal EnableDelayedExpansion

rem === 可选：设为 yes 则全程自动，不询问确认 ===
set "AUTO=no"

if "%~1"=="" (
    echo 请把 .ps1 文件拖到这个 bat 上！
    pause
    exit /b
)

set "FULLPATH=%~f1"
set "PATHONLY=%~dp1"
set "NAME=%~n1"
set "EXT=%~x1"

if /i not "%EXT%"==".ps1" (
    echo 只能拖 .ps1 文件！
    pause
    exit /b
)

set "MENU_NAME=%NAME%"
set "ICON=shell32.dll,167"

rem === 将路径中的 \ 转义成 \\ ===
set "ESCAPED_PATH=%FULLPATH:\=\\%"

set "REG_KEY=HKEY_CLASSES_ROOT\Directory\shell\%MENU_NAME%"

rem === 检查是否已经存在同名右键菜单 ===
reg query "%REG_KEY%" >nul 2>&1
if !errorlevel! == 0 (
    echo.
    echo 检测到已存在右键菜单项："%MENU_NAME%"
   
    if /i "%AUTO%"=="yes" (
        set "choice=y"
    ) else (
        set /p "choice=是否先删除旧的注册表项？(Y/N，默认N): "
    )
   
    if /i "!choice!"=="y" (
        echo 正在删除旧注册表项...
        reg delete "%REG_KEY%" /f >nul 2>&1
        if !errorlevel! == 0 (
            echo 删除成功。
        ) else (
            echo 删除失败，可能需要管理员权限。
            pause
            exit /b
        )
    ) else (
        echo 用户取消删除，脚本结束。
        pause
        exit /b
    )
)

rem === 生成正确的 .reg 文件（关键修复）===
(
echo Windows Registry Editor Version 5.00
echo.
echo [HKEY_CLASSES_ROOT\Directory\shell\%MENU_NAME%]
echo @="%MENU_NAME%"
echo "Icon"="%ICON%"
echo.
echo [HKEY_CLASSES_ROOT\Directory\shell\%MENU_NAME%\command]
echo @="powershell -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File \"%ESCAPED_PATH%\" \"%%1\""
) > "%PATHONLY%%MENU_NAME%.reg"

echo.
echo 已成功生成右键菜单注册表文件：
echo %PATHONLY%%MENU_NAME%.reg
echo.
echo 请双击该 .reg 文件进行注册（需要管理员权限）。
echo 如果想直接自动导入，可以右键以管理员身份运行此 BAT。
echo.

if /i "%AUTO%"=="yes" (
    reg import "%PATHONLY%%MENU_NAME%.reg" >nul 2>&1
    if !errorlevel! == 0 (
        echo 已自动导入注册表。
    ) else (
        echo 自动导入失败，请手动双击 .reg 文件并以管理员身份运行。
    )
)

pause