# 1. 允許腳本執行並強制使用 TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy Bypass -Scope Process -Force

# 2. 安裝 WinGet PowerShell 模組（如未安裝）
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing WinGet PowerShell module...' -ForegroundColor Cyan
    Install-PackageProvider -Name NuGet -Force | Out-Null
    if (-not (Get-Module -ListAvailable Microsoft.WinGet.Client)) {
        Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
    }
    Import-Module Microsoft.WinGet.Client -Force
    Repair-WinGetPackageManager | Out-Null
}

# 3. 安裝 Git（如未安裝）
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing Git via WinGet...' -ForegroundColor Cyan
    winget install --id Git.Git -e --source winget `
        --accept-source-agreements --accept-package-agreements | Out-Null
}

# 4. Clone 或更新專案到使用者主目錄
$target = Join-Path $HOME 'chatbot-project'
if (-not (Test-Path $target)) {
    Write-Host "Cloning repository to $target..." -ForegroundColor Cyan
    git clone https://github.com/qazasd2518995/chatbot-project.git $target
} else {
    Write-Host "Updating existing repository in $target..." -ForegroundColor Cyan
    Set-Location $target
    git pull origin main
}
Set-Location $target

# 5. 複製 .env 範例檔
if (-not (Test-Path ".\backend\.env")) {
    Copy-Item ".\backend\.env.example" ".\backend\.env" -Force
}

# 6. 提示啟動 Ollama 服務
Write-Host 'If Ollama is not running, open another PowerShell window and run:' -ForegroundColor Yellow
Write-Host '  ollama serve --listen 0.0.0.0:11434' -ForegroundColor Yellow

# 7. 檢查 Docker Desktop 是否在運行
if (-not (Get-Process -Name 'com.docker.backend' -ErrorAction SilentlyContinue)) {
    Write-Host 'Docker Desktop 未啟動，請先啟動 Docker Desktop，然後再執行本腳本。' -ForegroundColor Red
    exit 1
}

# 8. 啟動 Docker Compose
Write-Host 'Stopping existing containers...' -ForegroundColor Cyan
docker compose down | Out-Null
Write-Host 'Building and starting containers...' -ForegroundColor Cyan
docker compose up -d --build | Out-Null

# 9. 打開瀏覽器
Write-Host 'All set! Opening http://localhost:5173' -ForegroundColor Green
Start-Process 'http://localhost:5173'