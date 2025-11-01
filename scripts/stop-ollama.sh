#!/bin/bash
# Stop Ollama services

echo "Stopping Ollama services..."

# Stop all Ollama processes
pkill -f "ollama serve" || true

# Clean up PID files
rm -f /tmp/ollama-vision.pid /tmp/ollama-reasoning.pid

echo "✓ Ollama services stopped"