@echo off
echo 開始安裝 Chatbot Project...
echo 正在初始化安裝環境...

REM 確認 PowerShell 可使用
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo 錯誤: 找不到 PowerShell。請確認 Windows PowerShell 已安裝。
    echo 按任意鍵退出...
    pause >nul
    exit /b 1
)

REM 下載並執行安裝腳本
echo 正在下載安裝腳本...
powershell -ExecutionPolicy Bypass -Command "& {try { $env:TEMP = [System.IO.Path]::GetTempPath(); Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/qazasd2518995/chatbot-project/main/setup.ps1' -OutFile \"$env:TEMP\setup.ps1\"; powershell -ExecutionPolicy Bypass \"$env:TEMP\setup.ps1\" } catch { Write-Host \"錯誤: $_\"; pause }}"

REM 如果腳本執行失敗，等待用戶按鍵
if %errorlevel% neq 0 (
    echo 安裝過程中發生錯誤。請檢查錯誤訊息。
    echo 按任意鍵退出...
    pause >nul
    exit /b 1
)

echo 安裝已完成!
pause
