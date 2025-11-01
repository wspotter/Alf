#!/bin/bash
# Start Agent-S (Computer Use Automation)
# Uses LLaVA 13b vision model across available GPUs (hardware-agnostic)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_DIR/venv"
LOG_DIR="$PROJECT_DIR/logs"

mkdir -p "$LOG_DIR"

echo "🤖 Starting Agent-S (Computer Use Automation)..."

# Activate venv
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# Load Agent-S configuration
if [ -f "$PROJECT_DIR/.env" ]; then
    # Create a temporary clean env file with only key=value pairs
    set -a
    source <(cat "$PROJECT_DIR/.env" | sed 's/#.*//' | grep -E '^\w+=')
    set +a
fi

# Ensure LLaVA 13b model is available
echo "📦 Pulling LLaVA 13b model (if not cached)..."
ollama pull llava:13b 2>&1 | tail -3

# Start Agent-S with xvfb for headless operation
echo "✅ Starting Agent-S on port 8001..."
cd "$PROJECT_DIR"

# Kill any existing Agent-S process
pkill -f "agent_s/server.py" 2>/dev/null || true
sleep 1

# Run with virtual X display for screen capture and input control
xvfb-run -a python agent_s/server.py \
    --port 8001 \
    --host 0.0.0.0 \
    >> "$LOG_DIR/agent-s.log" 2>&1 &

AGENT_PID=$!
echo "$AGENT_PID" > "$LOG_DIR/agent-s.pid"

sleep 2

# Verify startup
if kill -0 $AGENT_PID 2>/dev/null; then
    echo "✅ Agent-S started (PID: $AGENT_PID)"
    echo "📊 Vision Model: LLaVA 13b"
    echo "🎮 Safe Mode: $(grep AGENT_SAFE_MODE $PROJECT_DIR/.env | cut -d= -f2)"
    echo "⚙️  System Commands: $(grep 'AGENT_ALLOW_SYSTEM_COMMANDS=' $PROJECT_DIR/.env | cut -d= -f2)"
    echo "📍 Health Check: http://localhost:8001/health"
    echo ""
    echo "Logs: tail -f $LOG_DIR/agent-s.log"
else
    echo "❌ Agent-S failed to start. Check logs:"
    tail -20 "$LOG_DIR/agent-s.log"
    exit 1
fi
