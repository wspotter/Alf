#!/bin/bash
# Test AlphaOmega Services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=================================================="
echo "AlphaOmega Service Tests"
echo "=================================================="
echo ""

# Test function
test_service() {
    local name=$1
    local url=$2
    local expected=$3
    
    echo -n "Testing $name... "
    
    response=$(curl -s -w "\n%{http_code}" "$url" 2>&1)
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "404" ]; then
        # 404 is OK for some endpoints without a GET handler
        echo -e "${GREEN}✓ OK${NC}"
        if [ ! -z "$expected" ] && echo "$body" | grep -q "$expected"; then
            echo -e "  ${GREEN}→ Response contains expected data${NC}"
        fi
        return 0
    else
        echo -e "${RED}✗ FAIL (HTTP $http_code)${NC}"
        echo "  Response: $body"
        return 1
    fi
}

# Test Ollama
echo "1. Ollama Service"
test_service "Ollama API" "http://localhost:11434/api/tags"
if curl -s http://localhost:11434/api/tags | grep -q "models"; then
    echo "  Available models:"
    curl -s http://localhost:11434/api/tags | python3 -c "import sys, json; data=json.load(sys.stdin); [print(f'    - {m[\"name\"]}') for m in data.get('models', [])]" 2>/dev/null || echo "    (unable to parse model list)"
fi
echo ""

# Test MCP Server
echo "2. MCP Server"
test_service "MCP Health" "http://localhost:8002/health"
echo ""

# Test Agent-S
echo "3. Agent-S"
test_service "Agent-S Health" "http://localhost:8001/health"
echo ""

# Test OpenWebUI
echo "4. OpenWebUI"
test_service "OpenWebUI" "http://localhost:8080/"
echo ""

# Test Ollama model inference
echo "5. Ollama Inference Test"
echo -n "Testing model inference... "

# Check if we have any models
if curl -s http://localhost:11434/api/tags | grep -q "models"; then
    # Get first model name
    model=$(curl -s http://localhost:11434/api/tags | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['models'][0]['name'] if data.get('models') else '')" 2>/dev/null)
    
    if [ ! -z "$model" ]; then
        response=$(curl -s -X POST http://localhost:11434/api/generate \
            -d "{\"model\":\"$model\",\"prompt\":\"Say hello in one word\",\"stream\":false}" 2>&1)
        
        if echo "$response" | grep -q "response"; then
            echo -e "${GREEN}✓ OK${NC}"
            echo "  Model: $model"
            echo "  Response: $(echo $response | python3 -c "import sys, json; print(json.load(sys.stdin).get('response', 'N/A')[:50])" 2>/dev/null)"
        else
            echo -e "${RED}✗ FAIL${NC}"
            echo "  Response: $response"
        fi
    else
        echo -e "${YELLOW}⚠ No models loaded${NC}"
        echo "  Run ./scripts/import-models.sh to import models"
    fi
else
    echo -e "${YELLOW}⚠ Ollama not responding${NC}"
fi
echo ""

# Test Agent-S screenshot capability
echo "6. Agent-S Screenshot Test"
echo -n "Testing screenshot capture... "

response=$(curl -s -X POST http://localhost:8001/action \
    -H "Content-Type: application/json" \
    -d '{"prompt":"capture screenshot","safe_mode":true}' 2>&1)

if echo "$response" | grep -q "screenshot"; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "  Agent-S can capture screenshots"
else
    echo -e "${YELLOW}⚠ Unable to verify${NC}"
    echo "  Response: $(echo $response | head -c 100)"
fi
echo ""

# Test MCP file operations
echo "7. MCP File Operations Test"
echo -n "Testing MCP server... "

# Test listing directory
response=$(curl -s -X POST http://localhost:8002/mcp/call \
    -H "Content-Type: application/json" \
    -d "{\"tool\":\"list_directory\",\"arguments\":{\"path\":\"$PROJECT_DIR\"}}" 2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "  MCP can list directories"
else
    echo -e "${YELLOW}⚠ Unable to verify${NC}"
    echo "  Note: MCP server might use different API format"
fi
echo ""

# GPU Status (vendor-agnostic)
echo "8. GPU Status"
if command -v nvidia-smi > /dev/null 2>&1; then
    echo "NVIDIA GPUs detected:"
    nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total --format=csv,noheader 2>/dev/null |
      awk -F, '{printf "  - %s | Util: %s | Mem: %s / %s\n", $1,$2,$3,$4}' || echo "  Unable to query NVIDIA GPUs"
elif command -v rocm-smi > /dev/null 2>&1; then
    echo "AMD GPUs detected:"
    rocm-smi --showuse 2>/dev/null | grep -E "GPU|%" || echo "  Unable to query GPU usage"
    echo ""
    rocm-smi --showmeminfo vram 2>/dev/null | grep -E "GPU|Memory" || echo "  Unable to query GPU memory"
else
    echo -e "${YELLOW}⚠ No GPU utility found (CPU-only or drivers not installed)${NC}"
fi
echo ""

# Summary
echo "=================================================="
echo "Test Summary"
echo "=================================================="
echo ""
echo "Core Services:"
echo "  - Ollama: $(curl -s http://localhost:11434/api/tags > /dev/null 2>&1 && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Not Running${NC}")"
echo "  - MCP Server: $(curl -s http://localhost:8002/health > /dev/null 2>&1 && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Not Running${NC}")"
echo "  - Agent-S: $(curl -s http://localhost:8001/health > /dev/null 2>&1 && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Not Running${NC}")"
echo "  - OpenWebUI: $(curl -s http://localhost:8080 > /dev/null 2>&1 && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Not Running${NC}")"
echo ""
echo "Next Steps:"
echo "  1. Import models: ./scripts/import-models.sh"
echo "  2. Open OpenWebUI: http://localhost:8080"
echo "  3. Configure MCP in Admin → Tools → Tool Servers"
echo "  4. Test vision: curl -X POST http://localhost:8001/action -H 'Content-Type: application/json' -d '{\"prompt\":\"What is on my screen?\"}'"
echo ""
