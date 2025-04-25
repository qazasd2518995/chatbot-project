# 設定 TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 允許腳本執行
Set-ExecutionPolicy Bypass -Scope Process -Force

try {
    # 安裝 WinGet 模組
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host 'Installing WinGet PowerShell module...' -ForegroundColor Cyan
        Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
        if (-not (Get-Module -ListAvailable Microsoft.WinGet.Client)) {
            Install-Module Microsoft.WinGet.Client -Force -Repository PSGallery -Scope CurrentUser | Out-Null
        }
        Import-Module Microsoft.WinGet.Client -Force
        Repair-WinGetPackageManager | Out-Null
    }

    # 安裝 Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host 'Installing Git via WinGet...' -ForegroundColor Cyan
        winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements | Out-Null
    }

    # Clone 或更新專案
    $target = Join-Path $HOME 'chatbot-project'
    if (-not (Test-Path $target)) {
        Write-Host "Cloning repository to $target..." -ForegroundColor Cyan
        git clone https://github.com/qazasd2518995/chatbot-project.git $target
    } 
    else {
        Write-Host "Updating existing repository in $target..." -ForegroundColor Cyan
        Set-Location $target
        git pull origin main
    }
    Set-Location $target

    # 複製 .env 範例
    if (-not (Test-Path '.\backend\.env')) {
        if (Test-Path '.\backend\.env.example') {
            Copy-Item .\backend\.env.example .\backend\.env -Force
        }
    }

    # 提示啟動 Ollama 服務
    Write-Host 'If Ollama is not running, open a new PowerShell window and run:' -ForegroundColor Yellow
    Write-Host '  ollama serve --listen 0.0.0.0:11434' -ForegroundColor Yellow

    # 檢查 Docker Desktop 是否執行
    if (-not (Get-Process -Name 'com.docker.backend' -ErrorAction SilentlyContinue)) {
        Write-Host 'Docker Desktop not running. Please start Docker Desktop and run this script again.' -ForegroundColor Red
        exit 1
    }

    # 啟動 Docker Compose
    Write-Host 'Stopping existing containers...' -ForegroundColor Cyan
    docker compose down | Out-Null
    Write-Host 'Building and starting containers...' -ForegroundColor Cyan
    docker compose up -d --build | Out-Null
    Write-Host 'All set! Opening web UI at http://localhost:5173' -ForegroundColor Green

    # 開啟瀏覽器
    Start-Process http://localhost:5173
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

