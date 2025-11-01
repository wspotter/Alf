#!/bin/bash
# Stop TTS service (Chatterbox via Docker)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Stopping Chatterbox TTS service..."
cd "$PROJECT_ROOT/tts"
./stop_chatterbox.sh