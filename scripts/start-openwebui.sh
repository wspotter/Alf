#!/bin/bash

# Start OpenWebUI on port 8080
# Connects to Ollama at localhost:11434

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PID_FILE="/tmp/openwebui.pid"
LOG_FILE="$PROJECT_ROOT/logs/openwebui.log"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🌐 Starting OpenWebUI..."

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  OpenWebUI already running (PID: $OLD_PID)${NC}"
        echo "   Access at: http://localhost:8080"
        exit 0
    else
        rm -f "$PID_FILE"
    fi
fi

# Check if port 8080 is available
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${RED}✗ Port 8080 is already in use${NC}"
    echo "  Kill the process using: lsof -ti:8080 | xargs kill"
    exit 1
fi

# Ensure logs directory exists
mkdir -p "$PROJECT_ROOT/logs"

# Activate virtual environment
if [ -d "$PROJECT_ROOT/venv" ]; then
    source "$PROJECT_ROOT/venv/bin/activate"
else
    echo -e "${RED}✗ Virtual environment not found${NC}"
    exit 1
fi

# Check if open-webui is installed
if ! command -v open-webui > /dev/null; then
    echo -e "${RED}✗ open-webui not installed${NC}"
    echo "  Install with: pip install open-webui"
    exit 1
fi

# Set environment variables
export OLLAMA_BASE_URL="http://localhost:11434"
export WEBUI_AUTH=true  # Enable auth so login/signup routes are available
export DEFAULT_USER_ROLE=admin # Ensure first user is admin
export DATA_DIR="$PROJECT_ROOT/openwebui_data"
export OPENWEBUI_PIPELINES_DIR="$PROJECT_ROOT/pipelines"  # Enable pipeline support
export MCP_HOST="http://localhost:8003"  # Point OpenWebUI pipelines at unified MCP
export MCP_SERVER_URL="http://localhost:8003"

# Ensure data directory exists
mkdir -p "$DATA_DIR"
mkdir -p "$OPENWEBUI_PIPELINES_DIR"

# Start OpenWebUI
cd "$PROJECT_ROOT"
echo "Starting OpenWebUI on port 8080..."
echo "Connecting to Ollama at $OLLAMA_BASE_URL"

nohup open-webui serve --port 8080 > "$LOG_FILE" 2>&1 &
WEBUI_PID=$!

# Save PID
echo "$WEBUI_PID" > "$PID_FILE"

# Wait a moment for startup
sleep 3

# Verify it started
if ps -p "$WEBUI_PID" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OpenWebUI started successfully!${NC}"
    echo ""
    echo "   Process ID: $WEBUI_PID"
    echo "   URL: http://localhost:8080"
    echo "   Logs: $LOG_FILE"
    echo "   Data: $DATA_DIR"
    echo ""
    echo "Quick commands:"
    echo "   View logs: tail -f $LOG_FILE"
    echo "   Stop: pkill -f 'open-webui'"
    echo ""
    
    # Try to open browser
    if command -v xdg-open > /dev/null; then
        echo "Opening OpenWebUI in browser..."
        xdg-open http://localhost:8080 &
    fi
else
    echo -e "${RED}✗ Failed to start OpenWebUI${NC}"
    echo "Check logs: $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
fi
