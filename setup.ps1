# https://raw.githubusercontent.com/qazasd2518995/chatbot-project/main/setup.ps1
param()

# 1. 保证脚本可以执行外部命令
Set-ExecutionPolicy Bypass -Scope Process -Force

# 2. 安装 WinGet 模块（静默）
$progressPreference = 'silentlyContinue'
Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
Repair-WinGetPackageManager | Out-Null

# 3. 安装 Git（如果没装）——静默返回
winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements | Out-Null

# 4. 在用户主目录里克隆（如已存在就跳过）
$target = Join-Path $HOME 'chatbot-project'
if (-not (Test-Path $target)) {
    git clone https://github.com/qazasd2518995/chatbot-project.git $target
}
Set-Location $target

# 5. 复制 env 文件
if (-not (Test-Path '.\backend\.env')) {
    Copy-Item .\backend\.env.example .\backend\.env -Force
}

# 6. 启动 Ollama（如果没启动，会在后面报错，学生再手动跑一次 ollama serve）
#    可以提示：请在另一个终端里执行 `ollama serve --listen 0.0.0.0:11434`
Write-Host "如果你还没启动 Ollama，请在新窗口执行："
Write-Host "  ollama serve --listen 0.0.0.0:11434" -ForegroundColor Yellow

# 7. 启动 Docker 全家桶
docker compose down | Out-Null
docker compose up -d --build

# 8. 打开浏览器
Start-Process http://localhost:5173
