#!/usr/bin/env bash
set -e

# 1. 安装 Homebrew（如未安装）
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2. 安装 Git（如未安装）
if ! command -v git >/dev/null 2>&1; then
  echo "Installing Git..."
  brew install git
fi

# 3. 安装 Ollama CLI（如未安装）并拉模型
if ! command -v ollama >/dev/null 2>&1; then
  echo "Installing Ollama CLI..."
  brew install ollama
  echo "Pulling Gemma3 model..."
  ollama pull gemma3:1b
fi

# 4. 检查 Docker
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker CLI not found. Please install Docker Desktop and start it, then re-run this script."
  exit 1
fi

# 5. 克隆项目到 ~/chatbot-project（若不存在）
TARGET="$HOME/chatbot-project"
if [ ! -d "$TARGET" ]; then
  git clone https://github.com/qazasd2518995/chatbot-project.git "$TARGET"
fi
cd "$TARGET"

# 6. 复制 .env 示例
if [ ! -f backend/.env ]; then
  cp backend/.env.example backend/.env
fi

# 7. 启动 Docker 服务
docker compose down
docker compose up -d --build

# 8. 打开前端页面
echo "Opening http://localhost:5173..."
open http://localhost:5173

echo "✔ Setup complete! Frontend is available at http://localhost:5173"
