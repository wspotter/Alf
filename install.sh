#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "  🚀 AlphaOmega Unified AI Platform Installer"
echo "════════════════════════════════════════════════════════"
echo ""

# Detect GPU
echo "🔍 Detecting hardware..."
if command -v nvidia-smi &> /dev/null; then
    echo "✓ NVIDIA GPU detected"
    GPU_TYPE="nvidia"
elif command -v rocm-smi &> /dev/null; then
    echo "✓ AMD GPU detected"
    GPU_TYPE="amd"
else
    echo "⚠ No GPU detected, using CPU"
    GPU_TYPE="cpu"
fi

# Clone dependencies
echo ""
echo "📦 Cloning dependencies..."

if [ ! -d "open-webui" ]; then
    echo "  → OpenWebUI..."
    git clone --depth 1 https://github.com/open-webui/open-webui.git
fi

if [ ! -d "ComfyUI" ]; then
    echo "  → ComfyUI..."
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git
fi

if [ ! -d "Agent-S" ]; then
    echo "  → Agent-S..."
    git clone --depth 1 https://github.com/simular-ai/Agent-S.git
fi

# Apply patches
echo ""
echo "🔧 Applying AlphaOmega integration patches..."

if [ -f "patches/open-webui.patch" ] && [ -d "open-webui/.git" ]; then
    cd open-webui && git apply ../patches/open-webui.patch 2>/dev/null && cd .. || echo "  ⚠ OpenWebUI patch skipped"
fi

if [ -f "patches/comfyui.patch" ] && [ -d "ComfyUI/.git" ]; then
    cd ComfyUI && git apply ../patches/comfyui.patch 2>/dev/null && cd .. || echo "  ⚠ ComfyUI patch skipped"
fi

if [ -f "patches/agent-s.patch" ] && [ -d "Agent-S/.git" ]; then
    cd Agent-S && git apply ../patches/agent-s.patch 2>/dev/null && cd .. || echo "  ⚠ Agent-S patch skipped"
fi

# Setup Python environment
echo ""
echo "🐍 Setting up Python environment..."
python3 -m venv venv
source venv/bin/activate

# Install dependencies
echo ""
echo "📚 Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Install components
echo "  → OpenWebUI..."
cd open-webui && pip install -e . && cd ..

echo "  → ComfyUI..."
cd ComfyUI && pip install -r requirements.txt && cd ..

echo "  → Agent-S..."
cd Agent-S && pip install -r requirements.txt && cd ..

# Install MCP Server
if [ -d "mcpart" ]; then
    echo "  → MCP Server (mcpart)..."
    cd mcpart && npm install && npm run build && cd ..
fi

# Install Ollama
if ! command -v ollama &> /dev/null; then
    echo ""
    echo "🦙 Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

# Setup config
echo ""
echo "⚙️  Setting up configuration..."
[ -f ".env.example" ] && cp .env.example .env

echo ""
echo "📥 Pulling AI models (this may take a while)..."
echo "  → llava:13b (vision + reasoning)..."
ollama pull llava:13b &

echo "  → codellama:13b (code generation)..."
ollama pull codellama:13b &

echo "  → mistral:latest (general chat)..."
ollama pull mistral:latest &

wait

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅ Installation Complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Edit .env with your preferences (if needed)"
echo "  2. Run: ./scripts/start.sh"
echo "  3. Open http://localhost:8080"
echo ""
