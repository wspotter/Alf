#!/bin/bash
# Start unified MCP server for AlphaOmega (NVIDIA-friendly defaults)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/logs/mcp-unified.log"
PID_FILE="/tmp/mcp-unified.pid"
PORT="${MCP_UNIFIED_PORT:-8003}"
MCPO_BUILD_ENTRY="$PROJECT_ROOT/mcpart/build/index.js"

cd "$PROJECT_ROOT"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "=================================================="
echo "Launching unified MCP server"
echo "=================================================="
echo ""

# Prevent duplicate instances
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  MCP server already running (PID: $OLD_PID).${NC}"
        echo "   Use pkill -f 'mcpo' or delete $PID_FILE if this is stale."
        exit 0
    fi
    rm -f "$PID_FILE"
fi

# Validate build artifacts
if [ ! -f "$MCPO_BUILD_ENTRY" ]; then
    echo -e "${RED}✗ mcpart build not found at $MCPO_BUILD_ENTRY${NC}"
    echo "  Run: cd mcpart && npm install && npm run build"
    exit 1
fi

mkdir -p "$PROJECT_ROOT/logs"

# Locate mcpo runner
if command -v uvx >/dev/null 2>&1; then
    MCPO_CMD=(uvx mcpo --port "$PORT" -- node "$MCPO_BUILD_ENTRY")
elif command -v npx >/dev/null 2>&1; then
    MCPO_CMD=(npx mcpo --port "$PORT" -- node "$MCPO_BUILD_ENTRY")
else
    echo -e "${RED}✗ mcpo runner not found (uvx or npx required).${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting mcpo with command:${NC} ${MCPO_CMD[*]}"
nohup "${MCPO_CMD[@]}" > "$LOG_FILE" 2>&1 &

MCP_PID=$!
echo $MCP_PID > "$PID_FILE"

# Wait briefly for startup
sleep 3

if ps -p "$MCP_PID" > /dev/null 2>&1; then
    if curl -s "http://localhost:${PORT}/openapi.json" > /dev/null 2>&1; then
        TOOL_COUNT=$(curl -s "http://localhost:${PORT}/openapi.json" | jq '.paths | keys | length' || echo "?")
        echo -e "${GREEN}✓ MCP server online${NC}"
        echo "  PID: $MCP_PID"
        echo "  Port: $PORT"
        echo "  Tools: $TOOL_COUNT"
        echo "  Logs: $LOG_FILE"
    else
        echo -e "${YELLOW}⚠️  MCP server started but openapi.json not reachable yet.${NC}"
        echo "  Check logs: tail -f $LOG_FILE"
    fi
else
    echo -e "${RED}✗ Failed to start MCP server${NC}"
    echo "  Inspect logs: tail -f $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
fi

echo ""
echo "Use ./scripts/stop-mcp-unified.sh or pkill -f 'mcpo --port ${PORT}' to stop."
echo ""
