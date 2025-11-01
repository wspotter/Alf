#!/bin/bash
# Start Computer Use Agent
# Uses local Ollama with LLaVA vision model + pyautogui

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_DIR/venv"
LOG_DIR="$PROJECT_DIR/logs"

mkdir -p "$LOG_DIR"

echo "🤖 Starting Computer Use Agent..."

# Activate venv
if [ ! -d "$VENV_DIR" ]; then
    echo "❌ Virtual environment not found at $VENV_DIR"
    exit 1
fi

source "$VENV_DIR/bin/activate"

# Ensure Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "⚠️  Ollama is not running. Vision features will be limited."
fi

# Ensure LLaVA model is available (optional for basic actions)
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "📦 Checking for LLaVA model..."
    if ! ollama list | grep -q "llava"; then
        echo "⚠️  LLaVA not found. Pulling llava:13b..."
        ollama pull llava:13b
    fi
fi

# Kill any existing computer use agent
pkill -f "computer_use_agent.py" 2>/dev/null || true
sleep 1

# Set environment variables
export OLLAMA_URL=http://localhost:11434
export VISION_MODEL=llava:13b
export SAFE_MODE=true
export PORT=8001
export HOST=0.0.0.0

# Start Computer Use Agent
echo "✅ Starting Computer Use Agent on port 8001..."
cd "$PROJECT_DIR"

nohup python computer_use_agent.py \
    > "$LOG_DIR/cua.log" 2>&1 &

CUA_PID=$!
echo "$CUA_PID" > "$LOG_DIR/cua.pid"

sleep 3

# Verify startup
if kill -0 $CUA_PID 2>/dev/null; then
    echo "✅ Computer Use Agent started successfully!"
    echo "   PID: $CUA_PID"
    echo "   URL: http://localhost:8001"
    echo "   Vision Model: LLaVA 13b (via Ollama)"
    echo "   Logs: $LOG_DIR/cua.log"
    echo ""
    echo "API Endpoints:"
    echo "   GET  /health - Health check"
    echo "   GET  /screenshot - Capture screen"
    echo "   POST /action - Execute action (click, type, key, scroll, move)"
    echo "   POST /analyze - Analyze screen with vision AI"
else
    echo "❌ Computer Use Agent failed to start. Check logs:"
    tail -20 "$LOG_DIR/cua.log"
    exit 1
fi
