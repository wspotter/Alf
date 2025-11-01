#!/bin/bash
# Start Coqui TTS API Server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Coqui TTS API Server${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Activate virtual environment
if [ -f "$PROJECT_ROOT/venv/bin/activate" ]; then
    echo -e "${YELLOW}Activating virtual environment...${NC}"
    source "$PROJECT_ROOT/venv/bin/activate"
else
    echo -e "${RED}Error: Virtual environment not found at $PROJECT_ROOT/venv${NC}"
    exit 1
fi

# Check if coqui-tts is installed
if ! python -c "import TTS" 2>/dev/null; then
    echo -e "${RED}Error: Coqui TTS not installed. Run: pip install coqui-tts${NC}"
    exit 1
fi

# Set environment variables
export TTS_HOST="${TTS_HOST:-0.0.0.0}"
export TTS_PORT="${TTS_PORT:-5002}"
export ROCR_VISIBLE_DEVICES="${ROCR_VISIBLE_DEVICES:-1}"  # Use MI50 GPU 1
export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-9.0.0}"  # MI50 compatibility

# Log configuration
echo -e "${YELLOW}Configuration:${NC}"
echo "  Host: $TTS_HOST"
echo "  Port: $TTS_PORT"
echo "  GPU: $ROCR_VISIBLE_DEVICES"
echo "  GFX Version: $HSA_OVERRIDE_GFX_VERSION"

# Kill any existing process on the port
if lsof -Pi :$TTS_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}Killing existing process on port $TTS_PORT...${NC}"
    kill $(lsof -t -i:$TTS_PORT) 2>/dev/null || true
    sleep 2
fi

# Start the API server
echo -e "${GREEN}Starting API server on http://$TTS_HOST:$TTS_PORT${NC}"
echo -e "${YELLOW}Logs will be written to: $PROJECT_ROOT/logs/coqui_tts.log${NC}"

# Create logs directory
mkdir -p "$PROJECT_ROOT/logs"

# Start server (daemonize with nohup)
nohup python "$SCRIPT_DIR/coqui_api.py" \
    > "$PROJECT_ROOT/logs/coqui_tts.log" 2>&1 &

PID=$!
echo $PID > /tmp/coqui_tts.pid

# Wait a moment and check if it's running
sleep 3

if ps -p $PID > /dev/null; then
    echo -e "${GREEN}✓ Coqui TTS API started successfully (PID: $PID)${NC}"
    echo -e "${GREEN}✓ API available at: http://localhost:$TTS_PORT${NC}"
    echo -e "${GREEN}✓ OpenAI endpoint: http://localhost:$TTS_PORT/v1/audio/speech${NC}"
    echo -e "${GREEN}✓ Voice cloning: http://localhost:$TTS_PORT/v1/audio/clone${NC}"
    echo ""
    echo -e "${YELLOW}Test with:${NC}"
    echo "  curl -X POST http://localhost:$TTS_PORT/v1/audio/speech \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{\"model\":\"tts-1\",\"input\":\"Hello from Coqui TTS!\",\"voice\":\"alloy\"}' \\"
    echo "    --output test.wav"
else
    echo -e "${RED}✗ Failed to start Coqui TTS API${NC}"
    echo -e "${RED}Check logs: $PROJECT_ROOT/logs/coqui_tts.log${NC}"
    exit 1
fi
