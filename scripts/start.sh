#!/bin/bash
# Start AlphaOmega services via Dashboard API (auto-starts dashboard + venv)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Starting AlphaOmega via Dashboard..."

# 1) Ensure dashboard is running
if ! curl -s http://localhost:5000/api/status > /dev/null 2>&1; then
    echo "📊 Dashboard not running — starting it now..."
    "$SCRIPT_DIR/start-dashboard.sh"
    # Wait until API is ready
    echo -n "⏳ Waiting for dashboard API"; attempts=0
    until curl -s http://localhost:5000/api/status > /dev/null 2>&1; do
        attempts=$((attempts+1))
        if [ $attempts -gt 30 ]; then
            echo ""; echo "❌ Dashboard failed to become ready"; exit 1
        fi
        echo -n "."; sleep 1
    done
    echo ""; echo "✅ Dashboard is up"
else
    echo "✅ Dashboard already running"
fi

# 2) Start all services via dashboard API
echo "🚀 Starting all services..."
RESPONSE=$(curl -s -X GET http://localhost:5000/api/start_all)
if echo "$RESPONSE" | grep -q '"results"'; then
    echo "✅ Services starting..."
    echo "$RESPONSE" | python3 -m json.tool || true
else
    echo "❌ Failed to start services via dashboard"
    echo "Response: $RESPONSE"; exit 1
fi

# 3) Wait and print consolidated status
echo "\n⏳ Waiting for services to initialize..."
sleep 10
echo "📈 Final service status:"
curl -s http://localhost:5000/api/status | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('=' * 50)
for service, info in data['services'].items():
    status = '✅' if info.get('running') else '❌'
    responsive = '🟢' if info.get('responsive') else '🔴'
    svc_name = info.get('name', service)
    print(f'{status} {responsive} {service}: {svc_name}')
print('=' * 50)
" || true

echo "\n🎯 Access points:"
echo "  📊 Dashboard: http://localhost:5000"
echo "  🌐 OpenWebUI: http://localhost:8080"
echo "  🤖 Ollama: http://localhost:11434"
echo "  🔧 MCP Tools: http://localhost:8003"
echo "  🎨 ComfyUI: http://localhost:8188"
echo "  🗣️ Chatterbox TTS: http://localhost:5003"
echo "  🔍 SearxNG: http://localhost:8181"
echo "  🤖 Agent-S: http://localhost:8001"
echo "\n📋 Monitor: curl http://localhost:5000/api/status"
