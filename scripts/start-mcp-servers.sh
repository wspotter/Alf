#!/bin/bash
# Start multiple MCP servers for OpenWebUI integration

set -e

PROJECT_DIR="/home/stacy/AlphaOmega"
cd "$PROJECT_DIR"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "=================================================="
echo "Starting MCP Servers"
echo "=================================================="
echo ""

# Stop any existing MCP servers
echo "Stopping existing MCP servers..."
pkill -f "mcpo.*800[2-9]" 2>/dev/null || true
pkill -f "node.*mcpart" 2>/dev/null || true
sleep 1

# Start unified MCPart MCP Server (Port 8003 by default)
MCP_PORT="${MCP_UNIFIED_PORT:-8003}"
echo -e "${BLUE}Starting MCPart Unified MCP Server (Port ${MCP_PORT})...${NC}"

mkdir -p "$PROJECT_DIR/logs"

bash "$PROJECT_DIR/scripts/start-mcp-unified.sh"

sleep 3
if curl -s "http://localhost:${MCP_PORT}/openapi.json" > /dev/null; then
    TOOL_COUNT=$(curl -s "http://localhost:${MCP_PORT}/openapi.json" | jq '.paths | keys | length' 2>/dev/null)
    echo -e "${GREEN}✓ MCPart Unified MCP Server running${NC}"
    [ -n "$TOOL_COUNT" ] && echo "  Tools available: $TOOL_COUNT"
else
    echo -e "${RED}✗ Failed to start MCPart server${NC}"
fi

echo ""
echo "=================================================="
echo -e "${GREEN}MCP Server Started!${NC}"
echo "=================================================="
echo ""
echo "Available Server:"
echo ""
echo -e "  ${BLUE}MCPart Unified MCP${NC}"
echo "    URL: http://localhost:${MCP_PORT}"
echo "    Docs: http://localhost:${MCP_PORT}/docs"
echo "    Tools: filesystem ops, inventory, CRM, scheduling, analytics, more"
echo ""
echo "=================================================="
echo ""
echo "Add to OpenWebUI:"
echo "  Admin Panel → Settings → External Tools"
echo "  Click [+] under 'Manage Tool Servers'"
echo ""
echo "  Server:"
echo "    Name: AlphaOmega MCP"
echo "    URL:  http://localhost:${MCP_PORT}"
echo ""
