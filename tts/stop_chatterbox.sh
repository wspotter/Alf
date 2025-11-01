#!/bin/bash
# Stop Chatterbox TTS Docker container

set -euo pipefail

CONTAINER_NAME="alphaomega-chatterbox"

if ! command -v docker >/dev/null 2>&1; then
  echo "⚠ Docker not available; nothing to stop"
  exit 0
fi

if ! docker info >/dev/null 2>&1; then
  echo "⚠ Docker daemon not running; skipping Chatterbox shutdown"
  exit 0
fi

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stopping ${CONTAINER_NAME}..."
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  echo "✓ Chatterbox TTS stopped"
else
  echo "⚠ No Chatterbox TTS container running"
fi
