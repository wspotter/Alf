#!/bin/bash
# Stop Coqui TTS API Server

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Stopping Coqui TTS API Server...${NC}"

# Check for PID file
if [ -f /tmp/coqui_tts.pid ]; then
    PID=$(cat /tmp/coqui_tts.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo -e "${YELLOW}Stopping process $PID...${NC}"
        kill $PID
        sleep 2
        
        # Force kill if still running
        if ps -p $PID > /dev/null 2>&1; then
            echo -e "${YELLOW}Force killing process $PID...${NC}"
            kill -9 $PID
        fi
        
        echo -e "${GREEN}✓ Coqui TTS API stopped${NC}"
    else
        echo -e "${YELLOW}Process $PID not running${NC}"
    fi
    rm -f /tmp/coqui_tts.pid
else
    echo -e "${YELLOW}No PID file found${NC}"
fi

# Kill any remaining processes on port 5002
if lsof -Pi :5002 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${YELLOW}Killing process on port 5002...${NC}"
    kill $(lsof -t -i:5002) 2>/dev/null || true
    sleep 1
    echo -e "${GREEN}✓ Port 5002 freed${NC}"
fi

echo -e "${GREEN}Coqui TTS API stopped successfully${NC}"
