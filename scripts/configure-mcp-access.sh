#!/bin/bash
# Configure MCP server file access permissions

set -e

PROJECT_DIR="/home/stacy/AlphaOmega"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "=================================================="
echo "MCP Filesystem Server - Access Configuration"
echo "=================================================="
echo ""

echo -e "${BLUE}Current Access:${NC}"
ps aux | grep "mcp-server-filesystem" | grep -v grep | sed 's/.*mcp-server-filesystem/  - /'

echo ""
echo -e "${YELLOW}Which directories should MCP have access to?${NC}"
echo ""
echo "1. Artifacts only (default, most secure)"
echo "2. Artifacts + Logs (read project logs)"
echo "3. Artifacts + Logs + Project root (full access)"
echo "4. Custom paths"
echo "5. Keep current configuration"
echo ""
read -p "Enter choice (1-5): " choice

case $choice in
    1)
        PATHS="$PROJECT_DIR/artifacts"
        ;;
    2)
        PATHS="$PROJECT_DIR/artifacts $PROJECT_DIR/logs"
        ;;
    3)
        PATHS="$PROJECT_DIR/artifacts $PROJECT_DIR/logs $PROJECT_DIR"
        ;;
    4)
        echo ""
        echo "Enter paths separated by spaces:"
        echo "Example: /home/stacy/documents /home/stacy/projects"
        read -p "Paths: " CUSTOM_PATHS
        PATHS="$PROJECT_DIR/artifacts $CUSTOM_PATHS"
        ;;
    5)
        echo -e "${GREEN}Keeping current configuration.${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}Restarting MCP server with access to:${NC}"
for path in $PATHS; do
    echo "  - $path"
done

# Stop current MCP server
echo ""
echo "Stopping current MCP server..."
pkill -f "mcpo.*8002" 2>/dev/null || true
sleep 1

# Start with new paths
echo "Starting MCP server with new configuration..."
cd "$PROJECT_DIR"
$HOME/.local/bin/uvx mcpo --port 8002 -- npx -y @modelcontextprotocol/server-filesystem $PATHS > logs/mcp-server.log 2>&1 &

sleep 3

# Verify it's running
if curl -s http://localhost:8002/docs > /dev/null; then
    echo -e "${GREEN}✓ MCP server restarted successfully!${NC}"
    echo ""
    echo "Updated paths:"
    ps aux | grep "mcp-server-filesystem" | grep -v grep | sed 's/.*mcp-server-filesystem/  /'
    echo ""
    echo "Test in OpenWebUI with:"
    echo "  'List files in artifacts'"
    echo "  'Show me the logs directory'"
else
    echo -e "${RED}✗ Failed to start MCP server. Check logs/mcp-server.log${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Note: You may need to refresh OpenWebUI for changes to take effect${NC}"
echo ""
