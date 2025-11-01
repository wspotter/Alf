#!/bin/bash
# Verify all AlphaOmega services are running correctly

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "=================================================="
echo "AlphaOmega Services Status Check"
echo "=================================================="
echo ""

# Function to check service
check_service() {
    local name=$1
    local port=$2
    local endpoint=$3
    
    if curl -s http://localhost:$port$endpoint > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name (port $port)"
        return 0
    else
        echo -e "${RED}✗${NC} $name (port $port) - NOT RESPONDING"
        return 1
    fi
}

# Check services
echo -e "${BLUE}Checking Services...${NC}"
echo ""

# 1. Ollama
if pgrep -x "ollama" > /dev/null; then
    echo -e "${GREEN}✓${NC} Ollama (port 11434)"
    MODELS=$(curl -s http://localhost:11434/api/tags | jq -r '.models | length')
    echo -e "  Models loaded: $MODELS"
else
    echo -e "${RED}✗${NC} Ollama - NOT RUNNING"
fi

# 2. MCP Server (Unified)
if curl -s http://localhost:8003/openapi.json > /dev/null 2>&1; then
    TOOLS=$(curl -s http://localhost:8003/openapi.json | jq '.paths | keys | length')
    echo -e "${GREEN}✓${NC} MCP Server (port 8003)"
    echo -e "  Total tools: $TOOLS"
else
    echo -e "${RED}✗${NC} MCP Server (port 8003) - NOT RESPONDING"
fi

# 3. Coqui TTS
if pgrep -f "coqui_api.py" > /dev/null; then
    if curl -s http://localhost:5002/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Coqui TTS (port 5002)"
    else
        echo -e "${YELLOW}⚠${NC} Coqui TTS running but health check failed"
    fi
else
    echo -e "${RED}✗${NC} Coqui TTS - NOT RUNNING"
fi

# 4. ComfyUI
COMFYUI_PORT="${COMFYUI_PORT:-8188}"
if curl -s "http://localhost:${COMFYUI_PORT}/system_stats" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} ComfyUI (port ${COMFYUI_PORT})"
else
    echo -e "${RED}✗${NC} ComfyUI (port ${COMFYUI_PORT}) - NOT RESPONDING"
fi

echo ""
echo "=================================================="
echo -e "${BLUE}Service URLs:${NC}"
echo "=================================================="
echo ""
echo "  Ollama API:     http://localhost:11434"
echo "  MCP Server:     http://localhost:8003"
echo "  MCP Docs:       http://localhost:8003/docs"
echo "  Coqui TTS:      http://localhost:5002"
echo "  TTS Health:     http://localhost:5002/health"
echo "  ComfyUI:        http://localhost:${COMFYUI_PORT}"
echo ""
echo "=================================================="
echo -e "${BLUE}Quick Commands:${NC}"
echo "=================================================="
echo ""
echo "  Start MCP:      ./scripts/start-mcp-unified.sh"
echo "  Start TTS:      ./scripts/start-tts.sh"
echo "  Stop TTS:       ./scripts/stop-tts.sh"
echo "  Stop MCP:       pkill -f 'mcpo.*8003'"
echo "  Start ComfyUI:  ./scripts/start-comfyui.sh"
echo "  Stop ComfyUI:   ./scripts/stop-comfyui.sh"
echo "  View logs:      tail -f logs/mcp-unified.log"
echo "  View TTS logs:  tail -f logs/coqui_tts.log"
echo ""
