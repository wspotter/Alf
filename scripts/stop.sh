#!/bin/bash
# Stop AlphaOmega services via Dashboard API

echo "Stopping AlphaOmega services via Dashboard API..."

# Check if dashboard is running
if ! curl -s http://localhost:5000/api/status > /dev/null 2>&1; then
    echo "❌ Dashboard not running. Stopping services directly..."

    # Fallback: stop services directly
    pkill -f "ollama serve" || true
    pkill -f "python.*agent_s.server" || true
    pkill -f "mcpo.*800[0-9]" || true
    pkill -f "node.*build/index.js" || true
    pkill -f "open-webui" || true

    # Stop containers
    if command -v docker >/dev/null 2>&1; then
        ./scripts/stop-tts.sh > /dev/null 2>&1 || true
        ./scripts/stop-searxng.sh > /dev/null 2>&1 || true
        ./scripts/stop-comfyui.sh > /dev/null 2>&1 || true
    fi

    echo "✓ Services stopped (fallback method)"
    exit 0
fi

echo "📊 Dashboard found at http://localhost:5000"

# Stop all services via dashboard API
echo "🛑 Stopping all services..."
RESPONSE=$(curl -s -X GET http://localhost:5000/api/stop_all)

if echo "$RESPONSE" | grep -q '"results"'; then
    echo "✅ Services stopping..."
    echo "$RESPONSE" | python3 -m json.tool
else
    echo "❌ Failed to stop services via dashboard"
    echo "Response: $RESPONSE"
    exit 1
fi

echo ""
echo "⏳ Waiting for services to shut down..."
sleep 5

# Check final status
echo "📈 Final service status:"
curl -s http://localhost:5000/api/status | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('=' * 50)
for service, info in data['services'].items():
    status = '❌' if not info.get('running') else '✅'
    responsive = '🔴' if not info.get('responsive') else '🟢'
    print(f'{status} {responsive} {service}: {info.get(\"name\", service)}')
print('=' * 50)
"

echo ""
echo "✓ All services stopped via dashboard"
