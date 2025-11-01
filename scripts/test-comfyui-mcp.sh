#!/usr/bin/env bash
# Test ComfyUI MCP tool integration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "🧪 Testing ComfyUI MCP Integration..."
echo ""

# Check if ComfyUI is running
echo "1️⃣ Checking if ComfyUI is running..."
if curl -sf http://localhost:8188/system_stats > /dev/null 2>&1; then
    echo "   ✅ ComfyUI is running at port 8188"
else
    echo "   ⚠️  ComfyUI is not running"
    echo "   Start it with: ./scripts/start-comfyui.sh"
    echo ""
fi

# Check if MCP server is running
echo ""
echo "2️⃣ Checking if MCP server (mcpo) is running..."
if curl -sf http://localhost:8003/openapi.json > /dev/null 2>&1; then
    echo "   ✅ MCP server is running at port 8003"
    
    # Check how many endpoints
    ENDPOINT_COUNT=$(curl -s http://localhost:8003/openapi.json | jq '.paths | length')
    echo "   📊 Current endpoint count: $ENDPOINT_COUNT"
else
    echo "   ❌ MCP server is not running"
    echo "   Start it with: uvx mcpo --port 8003 -- node /home/stacy/AlphaOmega/mcpart/build/index.js"
    exit 1
fi

# Test ComfyUI tools directly (Python)
echo ""
echo "3️⃣ Testing ComfyUI tools directly (Python)..."
source venv/bin/activate

python3 << 'PYTEST'
import sys
sys.path.insert(0, '/home/stacy/AlphaOmega/mcpart')

from tools.comfyui_tools import check_comfyui_status, list_comfyui_workflows

print("\n   Testing check_comfyui_status()...")
result = check_comfyui_status()
print(f"   Status: {result.get('status', 'unknown')}")
print(f"   Message: {result.get('message', 'no message')}")

print("\n   Testing list_comfyui_workflows()...")
result = list_comfyui_workflows()
print(f"   Workflows found: {result.get('count', 0)}")
for wf in result.get('workflows', []):
    print(f"      - {wf['name']}")

print("\n   ✅ Direct Python tests passed")
PYTEST

# Check if tools are exposed via MCP API
echo ""
echo "4️⃣ Checking if ComfyUI tools are exposed via MCP API..."

# List all available endpoints
ENDPOINTS=$(curl -s http://localhost:8003/openapi.json | jq -r '.paths | keys[]')

# Check for ComfyUI endpoints
if echo "$ENDPOINTS" | grep -q "comfyui"; then
    echo "   ✅ ComfyUI tools found in MCP API:"
    echo "$ENDPOINTS" | grep comfyui | while read endpoint; do
        echo "      - $endpoint"
    done
else
    echo "   ⚠️  ComfyUI tools not yet registered with MCP"
    echo "   Run: node mcpart/build/index.js to rebuild with new tools"
fi

# Test via curl (if endpoints exist)
echo ""
echo "5️⃣ Testing ComfyUI status via MCP API..."

if echo "$ENDPOINTS" | grep -q "check_comfyui_status"; then
    curl -s -X POST http://localhost:8003/check_comfyui_status \
        -H "Content-Type: application/json" \
        -d '{}' | jq '.'
else
    echo "   ⚠️  Endpoint not yet available - tools need to be registered"
fi

echo ""
echo "="*60
echo "✅ Test complete!"
echo "="*60
echo ""
echo "📝 Next steps:"
echo "   1. If tools not registered, rebuild mcpart with new tools"
echo "   2. Restart mcpo: pkill -f mcpo && uvx mcpo --port 8003 -- node mcpart/build/index.js"
echo "   3. Test in OpenWebUI: 'Check ComfyUI status'"
echo ""
