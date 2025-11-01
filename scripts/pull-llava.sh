#!/bin/bash
# AlphaOmega - Download LLaVA Vision Model
# Downloads llava:13b for vision capabilities

set -e

echo "=== AlphaOmega LLaVA Model Download ==="
echo "Date: $(date)"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "Ollama not found! Please install Ollama first."
    exit 1
fi

echo "Ollama version: $(ollama --version)"
echo ""

# Check if model already exists
if ollama list | grep -q "llava"; then
    echo -e "${GREEN}✓ LLaVA model already downloaded${NC}"
    ollama list | grep llava
    exit 0
fi

# Estimate size
echo -e "${YELLOW}This will download llava:13b (~7-8 GB)${NC}"
echo "This may take 15-30 minutes depending on your internet speed"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Download cancelled"
    exit 0
fi

# Download model
echo ""
echo "Downloading llava:13b..."
echo "Started at: $(date)"
echo ""

ollama pull llava:13b

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ LLaVA model downloaded successfully!${NC}"
    echo "Completed at: $(date)"
    echo ""
    echo "Available models:"
    ollama list
else
    echo "Download failed!"
    exit 1
fi
