#!/bin/bash
# Start TTS service (Chatterbox via Docker)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Starting Chatterbox TTS service..."
cd "$PROJECT_ROOT/tts"
./start_chatterbox.sh