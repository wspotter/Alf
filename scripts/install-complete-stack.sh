#!/bin/bash
# AlphaOmega Complete Stack Installation
# Installs: Ollama, OpenWebUI, MCP Server, Agent-S

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=================================================="
echo "AlphaOmega Complete Stack Installation"
echo "=================================================="
echo ""
echo "This will install:"
echo "  1. Ollama (if not present)"
echo "  2. OpenWebUI"
echo "  3. MCP Server (uvx + mcp-server-filesystem)"
echo "  4. Agent-S dependencies"
echo ""
echo "Project directory: $PROJECT_DIR"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run as root${NC}"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "==> Step 1: Checking system requirements..."
echo ""

# Check ROCm
if ! command_exists rocm-smi; then
    echo -e "${YELLOW}Warning: rocm-smi not found. AMD GPU acceleration may not work.${NC}"
else
    echo -e "${GREEN}✓ ROCm detected${NC}"
    rocm-smi --showid | head -10
fi

# Check Python
if ! command_exists python3; then
    echo -e "${RED}Error: Python 3 is required${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python $(python3 --version)${NC}"

echo ""
echo "==> Step 2: Installing Ollama..."
echo ""

if ! command_exists ollama; then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    echo -e "${GREEN}✓ Ollama installed${NC}"
else
    echo -e "${GREEN}✓ Ollama already installed ($(ollama --version))${NC}"
fi

echo ""
echo "==> Step 3: Setting up Python virtual environment..."
echo ""

cd "$PROJECT_DIR"

if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${GREEN}✓ Virtual environment exists${NC}"
fi

# Activate venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip wheel setuptools

echo ""
echo "==> Step 4: Installing OpenWebUI..."
echo ""

pip install open-webui
echo -e "${GREEN}✓ OpenWebUI installed${NC}"

echo ""
echo "==> Step 5: Installing MCP tools..."
echo ""

# Install uvx (pipx alternative)
pip install pipx
pipx ensurepath

# Install mcp via uvx
echo "Installing mcp and mcp-server-filesystem..."
pipx install mcp
echo -e "${GREEN}✓ MCP tools installed${NC}"

echo ""
echo "==> Step 6: Installing Agent-S dependencies..."
echo ""

pip install -r requirements.txt
echo -e "${GREEN}✓ Agent-S dependencies installed${NC}"

echo ""
echo "==> Step 7: Creating directories..."
echo ""

mkdir -p "$PROJECT_DIR/artifacts"
mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$PROJECT_DIR/screenshots"

echo -e "${GREEN}✓ Directories created${NC}"

echo ""
echo "==> Step 8: Verifying Ollama models..."
echo ""

# Check if Ollama is running
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama service..."
    ollama serve > /dev/null 2>&1 &
    sleep 2
fi

echo "Available models on your system:"
echo "Models directory: /home/stacy/models"
echo ""
echo "Code models:"
find /mnt/sdb2/models -name "*code*" -name "*.gguf" -type f 2>/dev/null | head -5
echo ""
echo "Vision models:"
find /mnt/sdb2/models -name "*vision*" -name "*.gguf" -type f 2>/dev/null
echo ""

echo -e "${YELLOW}Note: You'll need to import models into Ollama manually.${NC}"
echo "See the start-with-models.sh script for model setup."

echo ""
echo "=================================================="
echo -e "${GREEN}Installation Complete!${NC}"
echo "=================================================="
echo ""
echo "Next steps:"
echo "  1. Review: cat $PROJECT_DIR/scripts/start-all.sh"
echo "  2. Start services: $PROJECT_DIR/scripts/start-all.sh"
echo "  3. Access OpenWebUI at: http://localhost:8080"
echo ""
echo "Your models are at: /home/stacy/models"
echo "Artifacts will be stored in: $PROJECT_DIR/artifacts"
echo ""
