#!/bin/bash
# Start ComfyUI image generation service

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMFYUI_DIR="${PROJECT_ROOT}/ComfyUI"
PORT="${COMFYUI_PORT:-8188}"
PID_FILE="${PROJECT_ROOT}/logs/comfyui.pid"
LOG_FILE="${PROJECT_ROOT}/logs/comfyui.log"

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "ComfyUI already running (PID: $OLD_PID) on port ${PORT}."
        exit 0
    else
        rm -f "$PID_FILE"
    fi
fi

# Check if ComfyUI exists
if [ ! -d "$COMFYUI_DIR" ]; then
    echo "❌ ComfyUI not found at $COMFYUI_DIR"
    echo "Run: cd $PROJECT_ROOT && git clone https://github.com/comfyanonymous/ComfyUI.git"
    exit 1
fi

# Create directories
mkdir -p "${PROJECT_ROOT}/logs"
mkdir -p "${PROJECT_ROOT}/models/comfyui"
mkdir -p "${PROJECT_ROOT}/comfyui_bridge/workflows"
mkdir -p "${PROJECT_ROOT}/comfyui_bridge/output"

echo "Starting ComfyUI on port ${PORT}..."

# Start ComfyUI
cd "${COMFYUI_DIR}"
nohup venv/bin/python main.py --listen --port "${PORT}" > "${LOG_FILE}" 2>&1 &

COMFYUI_PID=$!
echo "$COMFYUI_PID" > "$PID_FILE"

# Wait for startup
sleep 3

if ps -p "$COMFYUI_PID" > /dev/null 2>&1; then
    echo "✓ ComfyUI started successfully!"
    echo "   PID: $COMFYUI_PID"
    echo "   URL: http://localhost:${PORT}"
    echo "   Logs: ${LOG_FILE}"
else
    echo "✗ Failed to start ComfyUI. Check logs: ${LOG_FILE}"
    rm -f "$PID_FILE"
    exit 1
fi
