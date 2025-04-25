# 建議加在最上方：早期 Windows PowerShell 會把 TLS 1.0 預設給 PSGallery
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 1. 允許腳本執行
Set-ExecutionPolicy Bypass -Scope Process -Force

# 2. 靜默安裝 WinGet 模組（如尚未安裝）
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing WinGet PowerShell module...' -ForegroundColor Cyan
    Install-PackageProvider -Name NuGet -Force | Out-Null
    if (-not (Get-Module -ListAvailable Microsoft.WinGet.Client)) {
        Install-Module Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
    }
    Import-Module Microsoft.WinGet.Client -Force
    Repair-WinGetPackageManager | Out-Null
}

# 3. 安裝 Git（如尚未安裝）
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing Git via WinGet...' -ForegroundColor Cyan
    winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements | Out-Null
}

# 4. Clone 或更新專案至使用者目錄
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

# 5. 複製 .env 範例
if (-not (Test-Path '.\backend\.env')) {
    Copy-Item .\backend\.env.example .\backend\.env -Force
}

# 6. 提示啟動 Ollama 服務
Write-Host 'If Ollama is not running, open a new PowerShell window and run:' -ForegroundColor Yellow
Write-Host '  ollama serve --listen 0.0.0.0:11434' -ForegroundColor Yellow

# 7. 檢查 Docker Desktop 是否執行
if (-not (Get-Process -Name 'com.docker.backend' -ErrorAction SilentlyContinue)) {
    Write-Host 'Docker Desktop 未啟動，請先啟動 Docker Desktop，然後再執行本腳本。' -ForegroundColor Red
    exit 1
}

# 8. 啟動 Docker Compose
Write-Host 'Stopping existing containers...' -ForegroundColor Cyan
docker compose down | Out-Null
Write-Host 'Building and starting containers...' -ForegroundColor Cyan
docker compose up -d --build | Out-Null
Write-Host 'All set! Opening web UI at http://localhost:5173' -ForegroundColor Green

# 9. 開啟瀏覽器
Start-Process http://localhost:5173