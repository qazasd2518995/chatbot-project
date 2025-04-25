# 建議加在最上方：早期 Windows PowerShell 會把 TLS 1.0 預設給 PSGallery
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Set-ExecutionPolicy Bypass -Scope Process -Force

# 2. Silent install WinGet module
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing WinGet PowerShell module…' -ForegroundColor Cyan
    Install-PackageProvider -Name NuGet -Force | Out-Null
    if (-not (Get-Module -ListAvailable Microsoft.WinGet.Client)) {
        Install-Module Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
    }
    Import-Module Microsoft.WinGet.Client -Force
    Repair-WinGetPackageManager | Out-Null
}

# 3. Install Git if missing
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements | Out-Null
}

# 4. Clone or update repo in user folder
$target = Join-Path $HOME 'chatbot-project'
if (-not (Test-Path $target)) {
    git clone https://github.com/qazasd2518995/chatbot-project.git $target
} else {
    Set-Location $target
    Write-Host 'Updating existing repository...' -ForegroundColor Cyan
    git pull origin main
}
Set-Location $target

# 5. Copy .env example
if (-not (Test-Path '.\backend\.env')) {
    Copy-Item .\backend\.env.example .\backend\.env -Force
}

# 6. Prompt for Ollama service
Write-Host "If Ollama is not running, open a new PowerShell window and run:" -ForegroundColor Yellow
Write-Host "  ollama serve --listen 0.0.0.0:11434" -ForegroundColor Yellow
# --- sanity check: Docker Desktop running? ---
if (-not (Get-Process -Name "com.docker.backend" -ErrorAction SilentlyContinue)) {
    Write-Host "Docker Desktop 未執行，請先啟動後再執行腳本。" -ForegroundColor Red
    exit 1
}

# 7. Start Docker Compose
docker compose down | Out-Null
docker compose up -d --build | Out-Null
Write-Host "Docker containers are up and running! Opening the web UI…" -ForegroundColor Green

# 8. Open browser
Start-Process http://localhost:5173