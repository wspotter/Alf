#!/bin/bash
# Cherry Studio Integration Script for AlphaOmega
# This script starts Cherry Studio with proper environment configuration

set -e

PROJECT_DIR="/home/stacy/AlphaOmega"
CHERRY_DIR="$PROJECT_DIR/cherry-studio-1.7.0-beta.2"

echo "=========================================="
echo "🚀 Starting Cherry Studio Integration"
echo "=========================================="
echo ""

# Check if Cherry Studio directory exists
if [ ! -d "$CHERRY_DIR" ]; then
    echo "❌ Error: Cherry Studio not found at $CHERRY_DIR"
    echo "Please install Cherry Studio first:"
    echo "  https://github.com/kangrongji/CherryStudio/releases"
    exit 1
fi

# Create or update Cherry Studio environment configuration
ENV_FILE="$CHERRY_DIR/.env"
cat > "$ENV_FILE" << 'EOF'
# AlphaOmega Integration Configuration
NODE_OPTIONS=--max-old-space-size=8000

# OpenWebUI Integration (AlphaOmega)
OPENWEBUI_URL=http://localhost:8080
OPENWEBUI_ENABLED=true

# Ollama Integration (Local Models)
OLLAMA_URL=http://localhost:11434
OLLAMA_ENABLED=true

# MCP Server Integration (mcpart)
MCP_SERVER_URL=http://localhost:8003
MCP_ENABLED=true

# Agent-S Computer Automation
AGENT_S_URL=http://localhost:8001
AGENT_S_ENABLED=false

# ComfyUI Image Generation
COMFYUI_URL=http://localhost:8188
COMFYUI_ENABLED=true

# Chatterbox TTS
TTS_URL=http://localhost:5003
TTS_ENABLED=true

# SearxNG Search
SEARXNG_URL=http://localhost:8181
SEARXNG_ENABLED=true

# Logging
CSLOGGER_MAIN_LEVEL=info
CSLOGGER_RENDERER_LEVEL=info
EOF

echo "✅ Created environment configuration"
echo ""

# Check if Cherry Studio is already running
if pgrep -f "electron.*cherry-studio" > /dev/null; then
    echo "⚠️  Cherry Studio is already running!"
    echo "   PID: $(pgrep -f 'electron.*cherry-studio' | head -1)"
    echo ""
    echo "To restart, run: pkill -f 'electron.*cherry-studio' && $0"
    echo ""
    echo "Keeping existing instance running"
    exit 0
fi

# Start Cherry Studio in development mode
echo "Starting Cherry Studio with AlphaOmega integration..."
echo ""
cd "$CHERRY_DIR"

# Use yarn dev for development mode with auto-reload
yarn dev &

CHERRY_PID=$!
echo $CHERRY_PID > "$PROJECT_DIR/cherry-studio.pid"

echo "✅ Cherry Studio started successfully!"
echo ""
echo "=========================================="
echo "📊 Status Information"
echo "=========================================="
echo "PID File: $PROJECT_DIR/cherry-studio.pid"
echo "PID: $CHERRY_PID"
echo "Working Directory: $CHERRY_DIR"
echo "Environment: $ENV_FILE"
echo ""
echo "🌐 Access Points:"
echo "  Cherry Studio: Will auto-open when ready"
echo "  OpenWebUI: http://localhost:8080"
echo "  MCP Server: http://localhost:8003"
echo "  AlphaOmega Dashboard: http://localhost:5000"
echo ""
echo "💡 MCP Server Integration:"
echo "  Name: mcpart-alphaomega"
echo "  Type: STDIO"
echo "  Command: node"
echo "  Args: /home/stacy/AlphaOmega/mcpart/build/index.js"
echo ""
echo "To stop Cherry Studio:"
echo "  kill $CHERRY_PID"
echo "  or"
echo "  $PROJECT_DIR/scripts/stop-cherry-studio.sh"
echo "=========================================="
