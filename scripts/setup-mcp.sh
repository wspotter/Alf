#!/bin/bash
# AlphaOmega - MCP Server Setup
# Safe, fast installation (~1 minute)

set -e

echo "=== AlphaOmega MCP Server Setup ==="
echo "Date: $(date)"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Project directory
PROJECT_DIR="/home/stacy/AlphaOmega"
cd "$PROJECT_DIR"

# Check if uvx is available
echo "Checking uvx installation..."
if ! command -v uvx &> /dev/null; then
    echo "uvx not found! Installing..."
    pip install --user pipx
    pipx install uv
else
    echo -e "${GREEN}✓ uvx found: $(which uvx)${NC}"
fi

# Create directories
echo ""
echo "Creating directories..."
mkdir -p "$PROJECT_DIR/artifacts"
mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$PROJECT_DIR/mcp_data"

echo -e "${GREEN}✓ Directories created${NC}"

# Test MCP server
echo ""
echo "Testing MCP server..."
if uvx mcpo --help &> /dev/null; then
    echo -e "${GREEN}✓ MCP server (mcpo) is available${NC}"
else
    echo -e "${YELLOW}⚠ MCP server test failed, but will try to start anyway${NC}"
fi

# Create MCP startup script
echo ""
echo "Creating MCP startup script..."
cat > "$PROJECT_DIR/scripts/start-mcp.sh" << 'MCPEOF'
#!/bin/bash
# Start MCP server with filesystem access

PROJECT_DIR="/home/stacy/AlphaOmega"
cd "$PROJECT_DIR"

echo "Starting MCP server on port 8002..."
echo "Artifacts directory: $PROJECT_DIR/artifacts"
echo ""

# Start MCP server
uvx mcpo --port 8002 -- uvx mcp-server-filesystem "$PROJECT_DIR/artifacts"
MCPEOF

chmod +x "$PROJECT_DIR/scripts/start-mcp.sh"
echo -e "${GREEN}✓ MCP startup script created: scripts/start-mcp.sh${NC}"

# Create MCP test script
cat > "$PROJECT_DIR/scripts/test-mcp.sh" << 'TESTEOF'
#!/bin/bash
# Test MCP server connection

echo "Testing MCP server at http://localhost:8002..."
curl -s http://localhost:8002/health || curl -s http://localhost:8002/ || echo "MCP server not responding (this is OK if not started yet)"
TESTEOF

chmod +x "$PROJECT_DIR/scripts/test-mcp.sh"

echo ""
echo -e "${GREEN}=== MCP Server Setup Complete! ===${NC}"
echo ""
echo "To start MCP server:"
echo "  ./scripts/start-mcp.sh"
echo ""
echo "To test MCP server (after starting):"
echo "  ./scripts/test-mcp.sh"
echo ""
echo "Artifacts will be stored in: $PROJECT_DIR/artifacts"
