#!/bin/bash
# Stop SearXNG search engine

set -e

echo "Stopping SearXNG..."

# Check if running as system service
if systemctl list-unit-files | grep -q "^searxng.service"; then
    sudo systemctl stop searxng 2>/dev/null || true
    sudo systemctl stop uwsgi 2>/dev/null || true
    echo "✓ SearXNG service stopped"
else
    echo "SearXNG not installed as system service"
fi

# Clean up PID file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PID_FILE="${PROJECT_ROOT}/logs/searxng.pid"
rm -f "$PID_FILE"

exit 0