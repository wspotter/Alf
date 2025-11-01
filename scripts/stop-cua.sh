#!/bin/bash
# Stop Computer Use Agent

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"

echo "🛑 Stopping Computer Use Agent..."

# Stop via PID file
if [ -f "$LOG_DIR/cua.pid" ]; then
    PID=$(cat "$LOG_DIR/cua.pid")
    if kill -0 $PID 2>/dev/null; then
        kill $PID 2>/dev/null || true
        echo "✅ Stopped Computer Use Agent (PID: $PID)"
    fi
    rm "$LOG_DIR/cua.pid"
fi

# Fallback: kill by process name
pkill -f "computer_use_agent.py" 2>/dev/null || true

echo "✅ Computer Use Agent stopped"
