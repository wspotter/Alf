#!/bin/bash
# Live monitoring dashboard for AlphaOmega

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Check if port is in use
port_in_use() {
    lsof -i:$1 > /dev/null 2>&1
}

while true; do
    clear
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║         AlphaOmega Live Status Monitor           ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Services Status
    echo -e "${BOLD}Services:${NC}"
    if port_in_use 11434; then
        echo -e "  ${GREEN}●${NC} Ollama         (11434) ${GREEN}RUNNING${NC}"
    else
        echo -e "  ${RED}○${NC} Ollama         (11434) ${RED}STOPPED${NC}"
    fi
    
    if port_in_use 8003; then
        echo -e "  ${GREEN}●${NC} MCP Server     (8003)  ${GREEN}RUNNING${NC}"
    else
        echo -e "  ${RED}○${NC} MCP Server     (8003)  ${RED}STOPPED${NC}"
    fi
    
    if port_in_use 8001; then
        echo -e "  ${GREEN}●${NC} Agent-S        (8001)  ${GREEN}RUNNING${NC}"
    else
        echo -e "  ${RED}○${NC} Agent-S        (8001)  ${RED}STOPPED${NC}"
    fi
    
    if port_in_use 8080; then
        echo -e "  ${GREEN}●${NC} OpenWebUI      (8080)  ${GREEN}RUNNING${NC}"
    else
        echo -e "  ${RED}○${NC} OpenWebUI      (8080)  ${RED}STOPPED${NC}"
    fi
    
    echo ""
    
    # Models Loaded
    echo -e "${BOLD}Loaded Models:${NC}"
    if port_in_use 11434; then
        models=$(curl -s http://localhost:11434/api/tags 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print('\n'.join([m['name'] for m in data.get('models', [])]))" 2>/dev/null)
        if [ ! -z "$models" ]; then
            echo "$models" | while read model; do
                echo -e "  ${BLUE}▸${NC} $model"
            done
        else
            echo -e "  ${YELLOW}No models loaded${NC}"
        fi
    else
        echo -e "  ${RED}Ollama not running${NC}"
    fi
    
    echo ""
    
    # GPU Status
    echo -e "${BOLD}GPU Status:${NC}"
    if command -v rocm-smi > /dev/null 2>&1; then
        # Parse GPU utilization
        gpu_info=$(rocm-smi --showuse 2>/dev/null | grep -A1 "GPU\[")
        if [ ! -z "$gpu_info" ]; then
            echo "$gpu_info" | while read line; do
                if echo "$line" | grep -q "GPU\["; then
                    gpu_id=$(echo "$line" | grep -o "GPU\[[0-9]\]")
                    echo -e "  ${MAGENTA}$gpu_id${NC}"
                elif echo "$line" | grep -q "%"; then
                    usage=$(echo "$line" | grep -o "[0-9]\+%" | head -1)
                    temp=$(echo "$line" | grep -o "[0-9]\+c")
                    echo -e "    Usage: $usage  Temp: $temp"
                fi
            done
        else
            echo -e "  ${YELLOW}Unable to query GPU status${NC}"
        fi
        
        # Memory usage
        mem_info=$(rocm-smi --showmeminfo vram 2>/dev/null | grep -E "GPU\[|Memory")
        if [ ! -z "$mem_info" ]; then
            echo ""
            echo -e "${BOLD}GPU Memory:${NC}"
            current_gpu=""
            echo "$mem_info" | while read line; do
                if echo "$line" | grep -q "GPU\["; then
                    current_gpu=$(echo "$line" | grep -o "GPU\[[0-9]\]")
                    echo -e "  ${MAGENTA}$current_gpu${NC}"
                elif echo "$line" | grep -q "Memory"; then
                    used=$(echo "$line" | awk '{print $2}')
                    total=$(echo "$line" | awk '{print $4}')
                    echo -e "    Used: $used / $total"
                fi
            done
        fi
    else
        echo -e "  ${YELLOW}ROCm not available${NC}"
    fi
    
    echo ""
    
    # Recent Activity (last log entry from each service)
    echo -e "${BOLD}Recent Activity:${NC}"
    if [ -d "$PROJECT_DIR/logs" ]; then
    for service in ollama mcp-unified agent-s openwebui; do
            logfile="$PROJECT_DIR/logs/${service}.log"
            if [ -f "$logfile" ]; then
                last_line=$(tail -1 "$logfile" 2>/dev/null | cut -c 1-60)
                if [ ! -z "$last_line" ]; then
                    echo -e "  ${CYAN}${service}:${NC} $last_line..."
                fi
            fi
        done
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Press Ctrl+C to exit${NC}  |  Updates every 2 seconds"
    
    sleep 2
done
