#!/bin/bash
# AlphaOmega - OpenWebUI Setup
# Installs OpenWebUI in virtual environment

set -e

echo "=== AlphaOmega OpenWebUI Setup ==="
echo "Date: $(date)"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="/home/stacy/AlphaOmega"
cd "$PROJECT_DIR"

# Check if venv exists
if [ ! -d "venv" ]; then
    echo -e "${RED}✗ Virtual environment not found!${NC}"
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate venv
echo "Activating virtual environment..."
source venv/bin/activate

# Check Python version
PYTHON_VERSION=$(python --version 2>&1 | awk '{print $2}')
echo -e "${GREEN}✓ Python version: $PYTHON_VERSION${NC}"

# Update pip
echo ""
echo "Updating pip..."
pip install --upgrade pip setuptools wheel

# Install OpenWebUI
echo ""
echo "Installing OpenWebUI (this may take 5-10 minutes)..."
echo "Installation started at: $(date)"

pip install open-webui

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ OpenWebUI installed successfully!${NC}"
else
    echo -e "${RED}✗ OpenWebUI installation failed${NC}"
    exit 1
fi

# Create OpenWebUI startup script
echo ""
echo "Creating OpenWebUI startup script..."
cat > "$PROJECT_DIR/scripts/start-openwebui.sh" << 'OWEBUI'
#!/bin/bash
# Start OpenWebUI

PROJECT_DIR="/home/stacy/AlphaOmega"
cd "$PROJECT_DIR"

# Activate venv
source venv/bin/activate

# Environment variables
export OLLAMA_BASE_URL="http://localhost:11434"
export WEBUI_AUTH="false"  # Disable auth for local development
export DATA_DIR="$PROJECT_DIR/openwebui_data"

# Create data directory
mkdir -p "$DATA_DIR"

echo "Starting OpenWebUI on http://localhost:8080..."
echo "Ollama: $OLLAMA_BASE_URL"
echo "Data directory: $DATA_DIR"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start OpenWebUI
open-webui serve --host 0.0.0.0 --port 8080
OWEBUI

chmod +x "$PROJECT_DIR/scripts/start-openwebui.sh"
echo -e "${GREEN}✓ OpenWebUI startup script created${NC}"

echo ""
echo -e "${GREEN}=== OpenWebUI Setup Complete! ===${NC}"
echo ""
echo "To start OpenWebUI:"
echo "  ./scripts/start-openwebui.sh"
echo ""
echo "Then open in browser:"
echo "  http://localhost:8080"
echo ""
echo "NOTE: Make sure Ollama is running first!"
