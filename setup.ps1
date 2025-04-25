

# 1. 允许脚本执行
Set-ExecutionPolicy Bypass -Scope Process -Force

# 2. 安装 WinGet PowerShell 模块（如还没安装）
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing WinGet PowerShell module…' -ForegroundColor Cyan
    Install-PackageProvider -Name NuGet -Force | Out-Null
    if (-not (Get-Module -ListAvailable Microsoft.WinGet.Client)) {
        Install-Module Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
    }
    Import-Module Microsoft.WinGet.Client -Force
    Repair-WinGetPackageManager | Out-Null
}

# 3. 安装 Git（如还没安装）
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing Git via WinGet…' -ForegroundColor Cyan
    winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements | Out-Null
}

# 4. Clone 或更新项目到用户目录
$target = Join-Path $HOME 'chatbot-project'
if (-not (Test-Path $target)) {
    Write-Host "Cloning repository to $target…" -ForegroundColor Cyan
    git clone https://github.com/qazasd2518995/chatbot-project.git $target
} else {
    Write-Host "Updating existing repository in $target…" -ForegroundColor Cyan
    Set-Location $target
    git pull origin main
}
Set-Location $target

# 5. 复制 .env 示例文件
if (-not (Test-Path ".\backend\.env")) {
    Copy-Item .\backend\.env.example .\backend\.env -Force
}

# 6. 提示用户启动 Ollama 服务
Write-Host 'If Ollama is not running, open a new PowerShell window and run:' -ForegroundColor Yellow
Write-Host '  ollama serve --listen 0.0.0.0:11434' -ForegroundColor Yellow

# 7. 检查 Docker Desktop 是否在运行
if (-not (Get-Process -Name 'com.docker.backend' -ErrorAction SilentlyContinue)) {
    Write-Host 'Docker Desktop 未启动，请先启动 Docker Desktop，然后再运行本脚本。' -ForegroundColor Red
    exit 1 }

# 8. 启动 Docker Compose
Write-Host 'Stopping existing containers…' -ForegroundColor Cyan
docker compose down | Out-Null
Write-Host 'Building and starting containers…' -ForegroundColor Cyan
docker compose up -d --build | Out-Null

# 9. 打开浏览器
Write-Host 'All set! Opening http://localhost:5173' -ForegroundColor Green
Start-Process http://localhost:5173