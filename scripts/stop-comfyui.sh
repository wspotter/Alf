#!/bin/bash
# Stop ComfyUI local service

PID_FILE="/tmp/comfyui.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Stopping ComfyUI (PID: $PID)..."
        sudo kill "$PID"
        sleep 2
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "Force killing ComfyUI..."
            sudo kill -9 "$PID"
        fi
        rm -f "$PID_FILE"
        echo "✓ ComfyUI stopped."
    else
        echo "ComfyUI not running (stale PID file)."
        rm -f "$PID_FILE"
    fi
else
    echo "ComfyUI not running (no PID file)."
fi

# Kill any remaining python processes
sudo pkill -f "python.*main.py.*--listen.*--port.*8188" 2>/dev/null || true
