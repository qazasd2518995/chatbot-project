Set-ExecutionPolicy Bypass -Scope Process -Force

# 2. Silent install WinGet module
$progressPreference = 'silentlyContinue'
Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
Repair-WinGetPackageManager | Out-Null

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
Write-Host 'If Ollama not running, execute in another terminal:' -ForegroundColor Yellow
Write-Host '  ollama serve --listen 0.0.0.0:11434' -ForegroundColor Yellow

# 7. Start Docker Compose
docker compose down | Out-Null
docker compose up -d --build | Out-Null

# 8. Open browser
Start-Process http://localhost:5173