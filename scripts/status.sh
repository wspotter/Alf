#!/bin/bash
# Quick Status Check for AlphaOmega Services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=================================================="
echo "AlphaOmega Service Status"
echo "=================================================="
echo ""

# Function to check if port is in use
port_in_use() {
    lsof -i:$1 > /dev/null 2>&1
}

# Function to check service
check_service() {
    local name=$1
    local port=$2
    local url=$3
    
    if port_in_use $port; then
        echo -e "  ${GREEN}✓${NC} $name (port $port)"
        if [ ! -z "$url" ]; then
            echo -e "    ${BLUE}→${NC} $url"
        fi
    else
        echo -e "  ${RED}✗${NC} $name (port $port) - NOT RUNNING"
    fi
}

echo "Service Status:"
check_service "Ollama" 11434 "http://localhost:11434"
check_service "MCP Server" 8003 "http://localhost:8003"
check_service "Agent-S" 8001 "http://localhost:8001"
check_service "OpenWebUI" 8080 "http://localhost:8080"
check_service "SearxNG" "${SEARXNG_PORT:-8181}" "http://localhost:${SEARXNG_PORT:-8181}"
check_service "ComfyUI" "${COMFYUI_PORT:-8188}" "http://localhost:${COMFYUI_PORT:-8188}"

echo ""
echo "GPU Status:"
if command -v rocm-smi > /dev/null 2>&1; then
    rocm-smi --showuse 2>/dev/null | grep -E "GPU|Usage" || echo "  Unable to query GPU usage"
else
    echo "  ROCm not available"
fi

echo ""
echo "Recent Logs:"
if [ -d "$PROJECT_DIR/logs" ]; then
    for log in ollama mcp-unified agent-s openwebui; do
        logfile="$PROJECT_DIR/logs/${log}.log"
        if [ -f "$logfile" ]; then
            echo ""
            echo -e "${YELLOW}=== Last 5 lines of ${log}.log ===${NC}"
            tail -5 "$logfile"
        fi
    done
else
    echo "  No logs directory found"
fi

echo ""
echo "=================================================="
echo ""
