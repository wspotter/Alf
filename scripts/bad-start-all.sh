#!/bin/bash

# AlphaOmega Dashboard Startup Script
# Starts the web-based service management dashboard on port 5000

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PID_FILE="/tmp/alphaomega-dashboard.pid"
LOG_FILE="$PROJECT_ROOT/logs/dashboard.log"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🚀 Starting AlphaOmega Dashboard..."

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Dashboard already running (PID: $OLD_PID)${NC}"
        echo "   Access at: http://localhost:5000"
        exit 0
    else
        rm -f "$PID_FILE"
    fi
fi

# Check if port 5000 is available
if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${RED}✗ Port 5000 is already in use${NC}"
    echo "  Kill the process using: lsof -ti:5000 | xargs kill"
    exit 1
fi

# Ensure logs directory exists
mkdir -p "$PROJECT_ROOT/logs"

# Activate virtual environment if it exists
if [ -d "$PROJECT_ROOT/venv" ]; then
    source "$PROJECT_ROOT/venv/bin/activate"
else
    echo -e "${YELLOW}⚠️  Virtual environment not found${NC}"
    echo "   Install dependencies with: pip install flask requests psutil"
fi

# Check for required dependencies
if ! python -c "import flask, requests, psutil" 2>/dev/null; then
    echo -e "${RED}✗ Missing dependencies${NC}"
    echo "  Install with: pip install flask requests psutil"
    exit 1
fi

# Start dashboard
cd "$PROJECT_ROOT"
nohup python dashboard.py > "$LOG_FILE" 2>&1 &
DASHBOARD_PID=$!

# Save PID
echo "$DASHBOARD_PID" > "$PID_FILE"

# Wait a moment for startup
sleep 2

# Verify it started
if ps -p "$DASHBOARD_PID" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Dashboard started successfully!${NC}"
    echo ""
    echo "   Process ID: $DASHBOARD_PID"
    echo "   Dashboard: http://localhost:5000"
    echo "   Logs: $LOG_FILE"
    echo ""
    echo "Quick commands:"
    echo "   View logs: tail -f $LOG_FILE"
    echo "   Stop dashboard: ./scripts/stop-dashboard.sh"
    echo ""
    
    # Try to open browser
    if command -v xdg-open > /dev/null; then
        echo "Opening dashboard in browser..."
        xdg-open http://localhost:5000 &
    fi
else
    echo -e "${RED}✗ Failed to start dashboard${NC}"
    echo "Check logs: $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
fi
