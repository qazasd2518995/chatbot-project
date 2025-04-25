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
        try {
            Repair-WinGetPackageManager | Out-Null
        } catch {
            Write-Host "注意: Repair-WinGetPackageManager 命令失敗，但安裝將繼續。" -ForegroundColor Yellow
        }
    }

    # 安裝 Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host 'Installing Git via WinGet...' -ForegroundColor Cyan
        try {
            winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements | Out-Null
        } catch {
            Write-Host "注意: 無法通過 winget 安裝 Git。請手動安裝 Git 後再運行此腳本。" -ForegroundColor Yellow
            Write-Host "下載地址: https://git-scm.com/download/win" -ForegroundColor Yellow
            exit 1
        }
    }

    # 確保 HOME 變數存在
    if (-not $HOME) {
        $HOME = [Environment]::GetFolderPath('UserProfile')
        Write-Host "注意: 使用 UserProfile 作為 HOME 目錄: $HOME" -ForegroundColor Yellow
    }

    # Clone 或更新專案
    $target = Join-Path -Path $HOME -ChildPath 'chatbot-project'
    Write-Host "目標目錄: $target" -ForegroundColor Cyan
    
    if (-not (Test-Path -Path $target)) {
        Write-Host "Cloning repository to $target..." -ForegroundColor Cyan
        git clone https://github.com/qazasd2518995/chatbot-project.git $target
        if (-not $?) {
            Write-Host "克隆倉庫失敗。請確保您有網絡連接並且 Git 已正確安裝。" -ForegroundColor Red
            exit 1
        }
    } 
    else {
        Write-Host "Updating existing repository in $target..." -ForegroundColor Cyan
        Set-Location $target
        git pull origin main
    }
    
    # 確保我們在正確的目錄中
    if (Test-Path -Path $target) {
        Set-Location $target
    } else {
        Write-Host "錯誤: 找不到專案目錄 $target" -ForegroundColor Red
        exit 1
    }

    # 複製 .env 範例
    if (-not (Test-Path -Path '.\backend\.env')) {
        if (Test-Path -Path '.\backend\.env.example') {
            Write-Host "正在複製環境配置文件..." -ForegroundColor Cyan
            Copy-Item -Path '.\backend\.env.example' -Destination '.\backend\.env' -Force
        } else {
            Write-Host "警告: 找不到 backend\.env.example 文件" -ForegroundColor Yellow
        }
    }

    # 提示啟動 Ollama 服務
    Write-Host 'If Ollama is not running, open a new PowerShell window and run:' -ForegroundColor Yellow
    Write-Host '  ollama serve --listen 0.0.0.0:11434' -ForegroundColor Yellow

    # 檢查 Docker Desktop 是否執行
    try {
        $dockerProcess = Get-Process -Name 'com.docker.backend' -ErrorAction SilentlyContinue
        if (-not $dockerProcess) {
            Write-Host 'Docker Desktop not running. Please start Docker Desktop and run this script again.' -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "無法檢查 Docker 狀態。請確保 Docker Desktop 正在運行。" -ForegroundColor Yellow
    }

    # 啟動 Docker Compose
    Write-Host 'Stopping existing containers...' -ForegroundColor Cyan
    docker compose down | Out-Null
    Write-Host 'Building and starting containers...' -ForegroundColor Cyan
    docker compose up -d --build | Out-Null
    Write-Host 'All set! Opening web UI at http://localhost:5173' -ForegroundColor Green

    # 開啟瀏覽器
    try {
        Start-Process "http://localhost:5173"
    } catch {
        Write-Host "無法自動打開瀏覽器。請手動訪問: http://localhost:5173" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

