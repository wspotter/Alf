#!/bin/bash

# AlphaOmega Dashboard Stop Script
# Stops the web-based service management dashboard

PID_FILE="/tmp/alphaomega-dashboard.pid"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VENV_PATH="$PROJECT_ROOT/venv"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "⏹️  Stopping AlphaOmega Dashboard..."

# Deactivate virtual environment if active
if [[ "$VIRTUAL_ENV" != "" ]]; then
    echo "📦 Deactivating virtual environment..."
    deactivate 2>/dev/null || true
fi

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
    echo -e "${YELLOW}⚠️  Dashboard doesn't appear to be running${NC}"
    echo "   (No PID file found at $PID_FILE)"
    
    # Try to find and kill any running dashboard process
    PIDS=$(pgrep -f "python.*dashboard.py")
    if [ -n "$PIDS" ]; then
        echo "   Found dashboard process(es): $PIDS"
        echo "   Killing..."
        pkill -f "python.*dashboard.py"
        sleep 1
        echo -e "${GREEN}✓ Dashboard stopped${NC}"
    fi
    exit 0
fi

# Read PID
PID=$(cat "$PID_FILE")

# Check if process is running
if ps -p "$PID" > /dev/null 2>&1; then
    # Kill the process
    kill "$PID"
    
    # Wait for process to stop
    for i in {1..5}; do
        if ! ps -p "$PID" > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # Force kill if still running
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "   Process didn't stop gracefully, forcing..."
        kill -9 "$PID"
        sleep 1
    fi
    
    # Verify stopped
    if ! ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Dashboard stopped successfully${NC}"
        rm -f "$PID_FILE"
    else
        echo -e "${RED}✗ Failed to stop dashboard${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Dashboard process not found${NC}"
    rm -f "$PID_FILE"
fi

echo "📦 Virtual environment deactivated"
