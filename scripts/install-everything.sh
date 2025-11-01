#!/bin/bash
# AlphaOmega Full Stack Installation Script
# Installs: Ollama, OpenWebUI, ComfyUI, MCP Server, Agent-S

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo_error "Please do not run as root"
   exit 1
fi

echo_info "========================================="
echo_info "AlphaOmega Full Stack Installation"
echo_info "========================================="
echo ""

# Check AMD GPUs
echo_info "Checking AMD GPUs..."
if ! command -v rocm-smi &> /dev/null; then
    echo_error "rocm-smi not found. Please install ROCm first."
    exit 1
fi

rocm-smi --showid
echo ""

# Create necessary directories
echo_info "Creating directories..."
mkdir -p "$PROJECT_DIR/artifacts"
mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$PROJECT_DIR/models/ollama"
mkdir -p "$PROJECT_DIR/models/comfyui"
mkdir -p "$PROJECT_DIR/openwebui_data"

# 1. Install Ollama
echo_info "========================================="
echo_info "1. Installing Ollama"
echo_info "========================================="

if command -v ollama &> /dev/null; then
    echo_info "Ollama already installed: $(ollama --version)"
else
    echo_info "Downloading Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

# Set environment for ROCm
export HSA_OVERRIDE_GFX_VERSION=9.0.0
echo_info "Set HSA_OVERRIDE_GFX_VERSION=9.0.0 for MI50 compatibility"

# 2. Install OpenWebUI
echo_info "========================================="
echo_info "2. Installing OpenWebUI"
echo_info "========================================="

if [ ! -d "venv" ]; then
    echo_info "Creating Python virtual environment..."
    python3 -m venv venv
fi

echo_info "Activating virtual environment..."
source venv/bin/activate

echo_info "Installing OpenWebUI and dependencies..."
pip install --upgrade pip
pip install open-webui

# Install additional dependencies
pip install -r requirements.txt

echo_info "OpenWebUI installed successfully"

# 3. Install ComfyUI
echo_info "========================================="
echo_info "3. Installing ComfyUI"
echo_info "========================================="

if [ ! -d "/opt/ComfyUI" ]; then
    echo_info "Cloning ComfyUI repository..."
    sudo mkdir -p /opt/ComfyUI
    sudo chown $USER:$USER /opt/ComfyUI
    git clone https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI
else
    echo_info "ComfyUI already exists at /opt/ComfyUI"
fi

cd /opt/ComfyUI

if [ ! -d "venv" ]; then
    echo_info "Creating ComfyUI virtual environment..."
    python3 -m venv venv
fi

echo_info "Installing ComfyUI dependencies..."
source venv/bin/activate
pip install --upgrade pip

# Install PyTorch with ROCm support
echo_info "Installing PyTorch with ROCm 6.2 support..."
pip install torch torchvision --index-url https://download.pytorch.org/whl/rocm6.2

# Install ComfyUI requirements
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
fi

echo_info "ComfyUI installed successfully"

cd "$PROJECT_DIR"
source venv/bin/activate  # Switch back to project venv

# 4. Install MCP tools
echo_info "========================================="
echo_info "4. Installing MCP Tools"
echo_info "========================================="

if ! command -v uvx &> /dev/null; then
    echo_info "Installing uv (for uvx)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi

echo_info "MCP tools ready (using uvx)"

# 5. Install Agent-S dependencies
echo_info "========================================="
echo_info "5. Installing Agent-S Dependencies"
echo_info "========================================="

echo_info "Agent-S dependencies already in requirements.txt"
echo_info "Installing any missing packages..."
pip install -r requirements.txt

# 6. Download models for Ollama
echo_info "========================================="
echo_info "6. Downloading Ollama Models"
echo_info "========================================="

echo_warn "This will take a while (~30-40 GB total)..."
read -p "Download models now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo_info "Pulling LLaVA 13B (vision model)..."
    ROCR_VISIBLE_DEVICES=1 ollama pull llava:13b
    
    echo_info "Pulling Mistral 7B (reasoning model)..."
    ROCR_VISIBLE_DEVICES=1 ollama pull mistral:7b
    
    echo_info "Pulling CodeLlama 13B (code model)..."
    ROCR_VISIBLE_DEVICES=1 ollama pull codellama:13b
    
    echo_info "All models downloaded!"
else
    echo_warn "Skipping model download. Run this later:"
    echo "  ROCR_VISIBLE_DEVICES=1 ollama pull llava:13b"
    echo "  ROCR_VISIBLE_DEVICES=1 ollama pull mistral:7b"
    echo "  ROCR_VISIBLE_DEVICES=1 ollama pull codellama:13b"
fi

# 7. Create startup script
echo_info "========================================="
echo_info "7. Creating Startup Scripts"
echo_info "========================================="

cat > "$PROJECT_DIR/scripts/start-all.sh" << 'STARTSCRIPT'
#!/bin/bash
# Start all AlphaOmega services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Set ROCm environment
export HSA_OVERRIDE_GFX_VERSION=9.0.0

echo_info "Starting AlphaOmega Stack..."
echo ""

# 1. Start Ollama on GPU1
echo_info "Starting Ollama on GPU1 (MI50)..."
export ROCR_VISIBLE_DEVICES=1
export OLLAMA_HOST=127.0.0.1:11434
export OLLAMA_KEEP_ALIVE=-1

if pgrep -f "ollama serve" > /dev/null; then
    echo_warn "Ollama already running"
else
    nohup ollama serve > logs/ollama.log 2>&1 &
    sleep 3
    echo_info "Ollama started (PID: $!)"
fi

# 2. Start ComfyUI on GPU2
echo_info "Starting ComfyUI on GPU2 (MI50)..."
export ROCR_VISIBLE_DEVICES=2

if pgrep -f "comfyui.*main.py" > /dev/null; then
    echo_warn "ComfyUI already running"
else
    cd /opt/ComfyUI
    source venv/bin/activate
    nohup python main.py --listen --port 8188 > "$PROJECT_DIR/logs/comfyui.log" 2>&1 &
    echo_info "ComfyUI started (PID: $!)"
    cd "$PROJECT_DIR"
fi

sleep 2

# 3. Start MCP Server
echo_info "Starting MCP Server..."
source venv/bin/activate

if pgrep -f "mcpo.*8002" > /dev/null; then
    echo_warn "MCP server already running"
else
    nohup uvx mcpo --port 8002 -- uvx mcp-server-filesystem "$PROJECT_DIR/artifacts" > logs/mcp.log 2>&1 &
    echo_info "MCP Server started (PID: $!)"
fi

sleep 2

# 4. Start OpenWebUI
echo_info "Starting OpenWebUI..."

if pgrep -f "open-webui serve" > /dev/null; then
    echo_warn "OpenWebUI already running"
else
    export OLLAMA_BASE_URL=http://localhost:11434
    export COMFYUI_BASE_URL=http://localhost:8188
    export DATA_DIR="$PROJECT_DIR/openwebui_data"
    
    nohup open-webui serve --port 8080 --host 0.0.0.0 > logs/openwebui.log 2>&1 &
    echo_info "OpenWebUI started (PID: $!)"
fi

sleep 3

# 5. Optional: Start Agent-S
read -p "Start Agent-S (computer use module)? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo_info "Starting Agent-S..."
    if pgrep -f "agent_s/server.py" > /dev/null; then
        echo_warn "Agent-S already running"
    else
        export DISPLAY=:0
        nohup python agent_s/server.py > logs/agent_s.log 2>&1 &
        echo_info "Agent-S started (PID: $!)"
    fi
fi

echo ""
echo_info "========================================="
echo_info "AlphaOmega Stack Started!"
echo_info "========================================="
echo ""
echo_info "Services:"
echo_info "  • Ollama:     http://localhost:11434"
echo_info "  • ComfyUI:    http://localhost:8188"
echo_info "  • MCP Server: http://localhost:8002"
echo_info "  • OpenWebUI:  http://localhost:8080"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo_info "  • Agent-S:    http://localhost:8001"
fi
echo ""
echo_info "Open your browser to: http://localhost:8080"
echo ""
echo_info "To view logs:"
echo_info "  tail -f logs/*.log"
echo ""
echo_info "To stop all services:"
echo_info "  ./scripts/stop-all.sh"
echo ""
STARTSCRIPT

chmod +x "$PROJECT_DIR/scripts/start-all.sh"

# 8. Create stop script
cat > "$PROJECT_DIR/scripts/stop-all.sh" << 'STOPSCRIPT'
#!/bin/bash
# Stop all AlphaOmega services

GREEN='\033[0;32m'
NC='\033[0m'
echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }

echo_info "Stopping AlphaOmega services..."

# Stop OpenWebUI
pkill -f "open-webui serve" && echo_info "OpenWebUI stopped"

# Stop Agent-S
pkill -f "agent_s/server.py" && echo_info "Agent-S stopped"

# Stop MCP Server
pkill -f "mcpo.*8002" && echo_info "MCP Server stopped"

# Stop ComfyUI
pkill -f "comfyui.*main.py" && echo_info "ComfyUI stopped"

# Stop Ollama
pkill -f "ollama serve" && echo_info "Ollama stopped"

echo_info "All services stopped"
STOPSCRIPT

chmod +x "$PROJECT_DIR/scripts/stop-all.sh"

# 9. Create status check script
cat > "$PROJECT_DIR/scripts/check-status.sh" << 'STATUSSCRIPT'
#!/bin/bash
# Check status of all AlphaOmega services

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check_service() {
    local name=$1
    local pattern=$2
    local port=$3
    
    if pgrep -f "$pattern" > /dev/null; then
        echo -e "${GREEN}✓${NC} $name (running)"
        if [ -n "$port" ]; then
            if nc -z localhost $port 2>/dev/null; then
                echo -e "  Port $port: ${GREEN}OK${NC}"
            else
                echo -e "  Port $port: ${RED}NOT RESPONDING${NC}"
            fi
        fi
    else
        echo -e "${RED}✗${NC} $name (not running)"
    fi
}

echo "AlphaOmega Service Status:"
echo "=========================="
check_service "Ollama" "ollama serve" 11434
check_service "ComfyUI" "comfyui.*main.py" 8188
check_service "MCP Server" "mcpo.*8002" 8002
check_service "OpenWebUI" "open-webui serve" 8080
check_service "Agent-S" "agent_s/server.py" 8001
echo ""
STATUSSCRIPT

chmod +x "$PROJECT_DIR/scripts/check-status.sh"

echo ""
echo_info "========================================="
echo_info "Installation Complete!"
echo_info "========================================="
echo ""
echo_info "Next steps:"
echo ""
echo_info "1. Start all services:"
echo "   ./scripts/start-all.sh"
echo ""
echo_info "2. Open browser to:"
echo "   http://localhost:8080"
echo ""
echo_info "3. Configure MCP in OpenWebUI:"
echo "   Admin → Tools → Add Connection"
echo "   - Type: MCP"
echo "   - URL: http://localhost:8002"
echo "   - ID: filesystem"
echo "   - Name: File System Tools"
echo ""
echo_info "4. Check status anytime:"
echo "   ./scripts/check-status.sh"
echo ""
echo_info "5. View logs:"
echo "   tail -f logs/*.log"
echo ""
echo_info "6. Stop all services:"
echo "   ./scripts/stop-all.sh"
echo ""
echo_warn "Note: If models weren't downloaded, run them manually before starting"
echo ""
