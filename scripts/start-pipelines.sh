#!/bin/bash
# Start OpenWebUI Pipelines Server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PIPELINES_DIR="$PROJECT_ROOT/pipelines"
LOG_FILE="$PROJECT_ROOT/logs/pipelines.log"
PID_FILE="/tmp/openwebui-pipelines.pid"
PORT="${PIPELINES_PORT:-9099}"

cd "$PROJECT_ROOT"

echo "🔧 Starting OpenWebUI Pipelines Server..."

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "⚠️  Pipelines server already running (PID: $OLD_PID)"
        exit 0
    fi
    rm -f "$PID_FILE"
fi

mkdir -p "$PROJECT_ROOT/logs"

# Activate environment and start pipelines server
source venv/bin/activate

echo "Starting pipelines server on port $PORT..."
echo "Pipelines directory: $PIPELINES_DIR"

nohup python -m pipelines.main --port "$PORT" --host 0.0.0.0 > "$LOG_FILE" 2>&1 &
PIPELINES_PID=$!
echo $PIPELINES_PID > "$PID_FILE"

sleep 2

if ps -p "$PIPELINES_PID" > /dev/null 2>&1; then
    echo "✅ Pipelines server started!"
    echo "   PID: $PIPELINES_PID"
    echo "   Port: $PORT"
    echo "   Logs: $LOG_FILE"
    echo ""
    echo "Configure OpenWebUI to use: http://localhost:$PORT"
else
    echo "❌ Failed to start pipelines server"
    echo "Check logs: tail -f $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
fi
