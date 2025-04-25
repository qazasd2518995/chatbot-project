# 1. Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(brew shellenv)"
fi

# 2. Install Git if missing
if ! command -v git >/dev/null 2>&1; then
  echo "Installing Git..."
  brew install git
fi

# 3. Install Ollama CLI if missing and pull model
if ! command -v ollama >/dev/null 2>&1; then
  echo "Installing Ollama CLI..."
  brew install ollama
  echo "Pulling Gemma3 model..."
  ollama pull gemma3:1b
fi

# 4. Ensure Docker is available
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker CLI not found. Please install Docker Desktop and start it, then re-run this script."
  exit 1
fi

# 4b. Ensure Docker Desktop daemon is running
if ! docker system info >/dev/null 2>&1; then
  echo "Docker Desktop appears to be installed but not running."
  echo "Please start Docker Desktop, wait until it reports \"Docker is running\", then re‑run this script."
  exit 1
fi

# 5. Clone or update repo to ~/chatbot-project
TARGET="$HOME/chatbot-project"
if [ ! -d "$TARGET" ]; then
  git clone https://github.com/qazasd2518995/chatbot-project.git "$TARGET"
else
  cd "$TARGET"
  echo "Updating existing repository..."
  git pull origin main
fi
cd "$TARGET"

# 6. Copy .env example
if [ ! -f backend/.env ]; then
  cp backend/.env.example backend/.env
fi

# 7. Start Docker Compose
docker compose down
docker compose up -d --build

# 8. Open browser
echo "Opening http://localhost:5173..."
open http://localhost:5173