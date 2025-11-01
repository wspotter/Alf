#!/bin/bash
# Build and run Chatterbox TTS in Docker

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="alphaomega-chatterbox:latest"
CONTAINER_NAME="alphaomega-chatterbox"
PORT="${CHATTERBOX_PORT:-5003}"
GPU_ARGS="${CHATTERBOX_GPU_ARGS:-}"

mkdir -p "$PROJECT_ROOT/logs"

echo "Building Chatterbox TTS Docker image..."
docker build -f "$SCRIPT_DIR/Dockerfile.chatterbox" -t "$IMAGE_NAME" "$SCRIPT_DIR"

echo ""
echo "Starting Chatterbox TTS service..."
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stopping existing ${CONTAINER_NAME} container..."
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

echo "Starting Chatterbox TTS service on port $PORT..."
docker run -d \
  --name "$CONTAINER_NAME" \
  $GPU_ARGS \
  -p "$PORT:5003" \
  -v "$PROJECT_ROOT/logs:/app/logs" \
  --restart unless-stopped \
  "$IMAGE_NAME"

cat <<INFO

✓ Chatterbox TTS started on port $PORT
✓ API endpoint: http://localhost:$PORT/v1/audio/speech
✓ Health endpoint: http://localhost:$PORT/health

Test with:
  curl -X POST http://localhost:$PORT/v1/audio/speech \
    -H 'Content-Type: application/json' \
    -d '{"model":"tts-1","input":"Hello from Chatterbox!","voice":"alloy"}' \
    --output test_chatterbox.wav
INFO

echo ""
echo "✓ Chatterbox TTS started on port 5003"
echo "✓ API endpoint: http://localhost:5003/v1/audio/speech"
echo ""
echo "Test with:"
echo "  curl -X POST http://localhost:5003/v1/audio/speech \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"model\":\"tts-1\",\"input\":\"Hello from Chatterbox!\",\"voice\":\"alloy\"}' \\"
echo "    --output test_chatterbox.wav"
