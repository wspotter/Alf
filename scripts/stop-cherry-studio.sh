#!/bin/bash
# Cherry Studio Stop Script for AlphaOmega

set -e

PROJECT_DIR="/home/stacy/AlphaOmega"
CHERRY_DIR="$PROJECT_DIR/cherry-studio-1.7.0-beta.2"
PID_FILE="$PROJECT_DIR/cherry-studio.pid"

echo "=========================================="
echo "⏹️  Stopping Cherry Studio"
echo "=========================================="
echo ""

# Check if PID file exists
if [ -f "$PID_FILE" ]; then
    CHERRY_PID=$(cat "$PID_FILE")
    echo "Reading PID from file: $CHERRY_PID"
    
    # Check if process is running
    if kill -0 "$CHERRY_PID" 2>/dev/null; then
        echo "Stopping Cherry Studio (PID: $CHERRY_PID)..."
        kill "$CHERRY_PID"
        sleep 2
        
        # Force kill if still running
        if kill -0 "$CHERRY_PID" 2>/dev/null; then
            echo "Force stopping Cherry Studio..."
            kill -9 "$CHERRY_PID"
            sleep 1
        fi
        
        echo "✅ Cherry Studio stopped"
    else
        echo "⚠️  Cherry Studio was not running (PID file exists but process not found)"
    fi
    
    # Remove PID file
    rm -f "$PID_FILE"
    echo "Removed PID file"
else
    echo "No PID file found. Stopping by process name..."
    
    # Try multiple patterns
    if pgrep -f "electron.*cherry-studio" > /dev/null; then
        echo "Stopping Cherry Studio by process name..."
        pkill -f "electron.*cherry-studio"
        sleep 2
        echo "✅ Cherry Studio stopped"
    else
        echo "Cherry Studio was not running"
    fi
fi

echo ""
echo "=========================================="
echo "🧹 Cleaning Up Related Processes"
echo "=========================================="
echo ""

# Stop related processes
echo "Stopping related processes..."

# MCP tool server (if running separately)
if pgrep -f "mcp-tool-server" > /dev/null; then
    pkill -f "mcp-tool-server"
    echo "  ✅ Stopped MCP tool server"
fi

# Node dev servers
if pgrep -f "electron-vite dev" > /dev/null; then
    pkill -f "electron-vite dev"
    echo "  ✅ Stopped Vite dev server"
fi

# Esbuild watchers
if pgrep -f "esbuild.*--service" > /dev/null; then
    pkill -f "esbuild.*--service"
    echo "  ✅ Stopped esbuild watchers"
fi

echo ""
echo "=========================================="
echo "✅ All Cherry Studio processes stopped"
echo "=========================================="
echo ""
echo "To restart:"
echo "  $PROJECT_DIR/scripts/start-cherry-studio.sh"
