#!/bin/bash
# Start All AlphaOmega Services
# This script starts: Ollama, MCP Server, Computer Use Agent, SearXNG, ComfyUI, TTS, OpenWebUI

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=================================================="
echo "Starting AlphaOmega Stack"
echo "=================================================="
echo ""

# Load environment
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
fi

# Export ROCm settings
export HSA_OVERRIDE_GFX_VERSION=9.0.0

# Create log directory
mkdir -p "$PROJECT_DIR/logs"

# Function to check if port is in use
port_in_use() {
    lsof -i:$1 > /dev/null 2>&1
}

# Function to start service in background
start_service() {
    local name=$1
    local command=$2
    local port=$3
    local logfile="$PROJECT_DIR/logs/${name}.log"
    
    if port_in_use $port; then
        echo -e "${YELLOW}⚠ $name already running on port $port${NC}"
    else
        echo -e "${BLUE}Starting $name on port $port...${NC}"
        eval "$command" > "$logfile" 2>&1 &
        local pid=$!
        echo $pid > "$PROJECT_DIR/logs/${name}.pid"
        sleep 2
        if ps -p $pid > /dev/null; then
            echo -e "${GREEN}✓ $name started (PID: $pid)${NC}"
        else
            echo -e "${RED}✗ $name failed to start. Check $logfile${NC}"
        fi
    fi
}

echo ""
echo "==> Step 1: Starting Ollama..."
echo ""

# Set GPU for Ollama (use GPU 1 - MI50 #1)
export ROCR_VISIBLE_DEVICES=1

if ! pgrep -x "ollama" > /dev/null; then
    start_service "ollama" "ollama serve" 11434
else
    echo -e "${GREEN}✓ Ollama already running${NC}"
fi

echo ""
echo "==> Step 2: Starting MCP Server (mcpart unified)..."
echo ""

# Create necessary directories
mkdir -p "$PROJECT_DIR/artifacts"
mkdir -p "$PROJECT_DIR/logs"

MCP_PORT="${MCP_UNIFIED_PORT:-8003}"
if port_in_use "$MCP_PORT"; then
    echo -e "${GREEN}✓ MCP server already running on port ${MCP_PORT}${NC}"
else
    echo -e "${BLUE}Starting unified MCP server on port ${MCP_PORT}...${NC}"
    bash "$PROJECT_DIR/scripts/start-mcp-unified.sh"
fi

echo ""
echo "==> Step 3: Starting Computer Use Agent..."
echo ""

if port_in_use 8001; then
    echo -e "${GREEN}✓ Computer Use Agent already running on port 8001${NC}"
else
    echo -e "${BLUE}Starting Computer Use Agent on port 8001...${NC}"
    bash "$PROJECT_DIR/scripts/start-cua.sh"
fi

echo ""
echo "==> Step 4: Starting SearXNG..."
echo ""

if port_in_use 8181; then
    echo -e "${GREEN}✓ SearXNG already running on port 8181${NC}"
else
    echo -e "${BLUE}Starting SearXNG on port 8181...${NC}"
    bash "$PROJECT_DIR/scripts/start-searxng.sh"
fi

echo ""
echo "==> Step 5: Starting ComfyUI..."
echo ""

if port_in_use 8188; then
    echo -e "${GREEN}✓ ComfyUI already running on port 8188${NC}"
else
    echo -e "${BLUE}Starting ComfyUI on port 8188...${NC}"
    bash "$PROJECT_DIR/scripts/start-comfyui.sh"
fi

echo ""
echo "==> Step 6: Starting TTS (Chatterbox)..."
echo ""

if port_in_use 5003; then
    echo -e "${GREEN}✓ TTS already running on port 5003${NC}"
else
    echo -e "${BLUE}Starting TTS on port 5003...${NC}"
    bash "$PROJECT_DIR/scripts/start-tts.sh"
fi

echo ""
echo "==> Step 7: Starting OpenWebUI..."
echo ""

# Set environment variables for OpenWebUI
export OLLAMA_BASE_URL=http://localhost:11434
export WEBUI_AUTH=false  # Disable auth for local dev
export DATA_DIR="$PROJECT_DIR/openwebui_data"

mkdir -p "$DATA_DIR"

# Start OpenWebUI
OPENWEBUI_CMD="cd $PROJECT_DIR && source venv/bin/activate && open-webui serve --host 0.0.0.0 --port 8080"
start_service "openwebui" "$OPENWEBUI_CMD" 8080

echo ""
echo "=================================================="
echo -e "${GREEN}All Services Started!${NC}"
echo "=================================================="
echo ""
echo "Access URLs:"
echo -e "  ${BLUE}OpenWebUI:${NC}        http://localhost:8080"
echo -e "  ${BLUE}Ollama:${NC}           http://localhost:11434"
echo -e "  ${BLUE}MCP Server:${NC}       http://localhost:8003"
echo -e "  ${BLUE}Computer Use:${NC}     http://localhost:8001"
echo -e "  ${BLUE}SearXNG:${NC}          http://localhost:8181"
echo -e "  ${BLUE}ComfyUI:${NC}          http://localhost:8188"
echo -e "  ${BLUE}TTS:${NC}              http://localhost:5003"
echo ""
echo "Logs are in: $PROJECT_DIR/logs/"
echo ""
echo "To stop all services:"
echo "  $SCRIPT_DIR/stop-all.sh"
echo ""
echo "To view logs:"
echo "  tail -f $PROJECT_DIR/logs/openwebui.log"
echo "  tail -f $PROJECT_DIR/logs/mcp-unified.log"
echo "  tail -f $PROJECT_DIR/logs/agent-s.log"
echo ""

# Wait a moment for services to stabilize
sleep 3

echo "Checking service status..."
echo ""

# Check each service
services=("ollama:11434" "mcp:8003" "cua:8001" "searxng:8181" "comfyui:8188" "tts:5003" "openwebui:8080")
for service in "${services[@]}"; do
    IFS=':' read -r name port <<< "$service"
    if port_in_use $port; then
        echo -e "  ${GREEN}✓${NC} $name (port $port)"
    else
        echo -e "  ${RED}✗${NC} $name (port $port) - NOT RUNNING"
    fi
done

echo ""
echo -e "${GREEN}Ready to use!${NC} Open http://localhost:8080 in your browser"
echo ""
