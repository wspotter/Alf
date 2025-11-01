#!/bin/bash
# Start Ollama (vendor-agnostic, single instance)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="${PROJECT_ROOT}/logs"
PID_FILE="/tmp/ollama.pid"

mkdir -p "$LOG_DIR"

echo "Starting Ollama on port 11434..."

# Already running?
if pgrep -x "ollama" > /dev/null; then
    echo "Ollama already running"
    exit 0
fi

# Load .env if present
if [ -f "${PROJECT_ROOT}/.env" ]; then
    set -a
    source <(grep -v '^#' "${PROJECT_ROOT}/.env" | grep -v '^$' | sed 's/#.*$//')
    set +a
fi

# Optional: prefer NVIDIA/AMD if user set envs; otherwise let Ollama decide
# Do not set CUDA_VISIBLE_DEVICES or ROCR_VISIBLE_DEVICES by default

export OLLAMA_HOST=127.0.0.1:11434
nohup ollama serve > "${LOG_DIR}/ollama.log" 2>&1 &
OLLAMA_PID=$!
echo "$OLLAMA_PID" > "$PID_FILE"

sleep 3
if ps -p "$OLLAMA_PID" > /dev/null 2>&1; then
    echo "✓ Ollama started (PID: $OLLAMA_PID)"
else
    echo "✗ Failed to start Ollama (see ${LOG_DIR}/ollama.log)"
    exit 1
fi