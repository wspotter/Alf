#!/bin/bash
# Stop the unified MCP OpenAPI proxy (mcpo)

set -e

PID_FILE="/tmp/mcp-unified.pid"
PORT="${MCP_UNIFIED_PORT:-8003}"

echo "Stopping unified MCP server..."

if [ -f "$PID_FILE" ]; then
    MCP_PID=$(cat "$PID_FILE")
    if kill -0 "$MCP_PID" 2>/dev/null; then
        kill "$MCP_PID"
        sleep 1
        if kill -0 "$MCP_PID" 2>/dev/null; then
            echo "Forcing unified MCP server to stop (PID: $MCP_PID)"
            kill -9 "$MCP_PID" || true
        fi
    fi
    rm -f "$PID_FILE"
fi

pkill -f "mcpo.*${PORT}" >/dev/null 2>&1 || true
pkill -f "node mcpart/build/index.js" >/dev/null 2>&1 || true

if pgrep -f "mcpo.*${PORT}" >/dev/null 2>&1; then
    echo "Warning: unified MCP server still appears to be running"
    exit 1
fi

echo "Unified MCP server stopped."
