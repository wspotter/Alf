#!/bin/bash
# Start SearXNG privacy-respecting metasearch engine

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SEARXNG_DIR="${PROJECT_ROOT}/searxng"
VENV_DIR="${PROJECT_ROOT}/venv"
PORT="${SEARXNG_PORT:-8181}"
BIND="${SEARXNG_BIND:-127.0.0.1}"
PID_FILE="${PROJECT_ROOT}/logs/searxng.pid"
LOG_FILE="${PROJECT_ROOT}/logs/searxng.log"

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "SearXNG already running (PID: $OLD_PID) on ${BIND}:${PORT}."
        exit 0
    else
        rm -f "$PID_FILE"
    fi
fi

# Check if SearXNG exists
if [ ! -d "$SEARXNG_DIR" ]; then
    echo "❌ SearXNG not found at $SEARXNG_DIR"
    echo "Run: git clone https://github.com/searxng/searxng.git $SEARXNG_DIR"
    exit 1
fi

# Use shared venv and install SearxNG if needed
if [ ! -d "$VENV_DIR" ]; then
    echo "❌ Shared venv not found at $VENV_DIR"
    echo "Run: python3 -m venv $VENV_DIR"
    exit 1
fi

source "${VENV_DIR}/bin/activate"

# SearxNG dependencies are already installed via requirements.txt
# No need to install with pip install -e .

# Create logs directory
mkdir -p "${PROJECT_ROOT}/logs"

# Create settings if needed  
if [ ! -f "${SEARXNG_DIR}/searx/settings.yml" ]; then
    echo "Creating SearXNG settings..."
    cp "${SEARXNG_DIR}/utils/templates/etc/searxng/settings.yml" "${SEARXNG_DIR}/searx/settings.yml"
fi

echo "Starting SearXNG on ${BIND}:${PORT}..."

# Start SearXNG using Python module directly
cd "${SEARXNG_DIR}"
export SEARXNG_SETTINGS_PATH="${SEARXNG_DIR}/searx/settings.yml"
export SEARXNG_PORT="${PORT}"
export SEARXNG_BIND_ADDRESS="${BIND}"
export PYTHONPATH="${SEARXNG_DIR}:$PYTHONPATH"
nohup python -m searx.webapp > "${LOG_FILE}" 2>&1 &

SEARXNG_PID=$!
echo "$SEARXNG_PID" > "$PID_FILE"

# Wait for startup
sleep 3

if ps -p "$SEARXNG_PID" > /dev/null 2>&1; then
    echo "✓ SearXNG started successfully!"
    echo "   PID: $SEARXNG_PID"
    echo "   URL: http://${BIND}:${PORT}"
    echo "   Logs: ${LOG_FILE}"
else
    echo "✗ Failed to start SearXNG. Check logs: ${LOG_FILE}"
    rm -f "$PID_FILE"
    exit 1
fi