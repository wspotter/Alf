#!/bin/bash
# Stop All AlphaOmega Services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=================================================="
echo "Stopping AlphaOmega Stack"
echo "=================================================="
echo ""

# Function to stop service by PID file
stop_service() {
    local name=$1
    local pidfile="$PROJECT_DIR/logs/${name}.pid"
    
    if [ -f "$pidfile" ]; then
        local pid=$(cat "$pidfile")
        if ps -p $pid > /dev/null 2>&1; then
            echo -e "Stopping $name (PID: $pid)..."
            kill $pid
            sleep 1
            if ps -p $pid > /dev/null 2>&1; then
                echo -e "${YELLOW}Force killing $name...${NC}"
                kill -9 $pid
            fi
            echo -e "${GREEN}✓ $name stopped${NC}"
        else
            echo -e "${YELLOW}⚠ $name not running${NC}"
        fi
        rm -f "$pidfile"
    else
        echo -e "${YELLOW}⚠ No PID file for $name${NC}"
    fi
}

# Stop services in reverse order (shutdown order matters)
stop_service "openwebui"
stop_service "tts"
stop_service "comfyui"
stop_service "searxng"
stop_service "computer-use-agent"

echo "Stopping unified MCP server..."
bash "$SCRIPT_DIR/stop-mcp-unified.sh" >/dev/null 2>&1 || true

# Stop Ollama separately (might not have PID file if started externally)
if pgrep -x "ollama" > /dev/null; then
    echo "Stopping Ollama..."
    pkill ollama
    sleep 1
    echo -e "${GREEN}✓ Ollama stopped${NC}"
else
    echo -e "${YELLOW}⚠ Ollama not running${NC}"
fi

# Clean up any remaining processes
echo ""
echo "Checking for remaining processes..."
pkill -f "open-webui serve" 2>/dev/null && echo "  Killed remaining OpenWebUI processes"
pkill -f "computer_use_agent.py" 2>/dev/null && echo "  Killed remaining Computer Use Agent processes"
pkill -f "searx.webapp" 2>/dev/null && echo "  Killed remaining SearXNG processes"
pkill -f "comfyui.server.py" 2>/dev/null && echo "  Killed remaining ComfyUI processes"
pkill -f "uvx mcpo" 2>/dev/null && echo "  Killed remaining MCP processes"

# Stop Chatterbox TTS container if running
if command -v docker >/dev/null 2>&1; then
    if docker ps --format '{{.Names}}' | grep -q '^alphaomega-chatterbox$'; then
        echo "Stopping Chatterbox TTS container..."
        docker rm -f alphaomega-chatterbox >/dev/null 2>&1 && echo "  Chatterbox container stopped"
    fi
fi

echo ""
echo -e "${GREEN}All services stopped${NC}"
echo ""
