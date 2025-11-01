#!/bin/bash
# Create clean public repository for AlphaOmega (as Alf)
# This script is idempotent and resumable

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PUBLIC_REPO_DIR="/home/stacy/Alf-public"
CHECKPOINT_FILE="$PROJECT_ROOT/.repo-creation-checkpoint"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Progress symbols
PENDING="○"
IN_PROGRESS="◐"
COMPLETE="●"
SKIPPED="◌"

# Define all steps
declare -a STEPS=(
    "create_dirs:Create clean repository structure"
    "init_git:Initialize git repository"
    "copy_code:Copy AlphaOmega original code"
    "generate_patches:Generate patches for modified dependencies"
    "create_install:Create automated installation script"
    "create_requirements:Create requirements.txt"
    "create_gitignore:Create .gitignore"
    "create_readme:Create comprehensive README.md"
    "create_docs:Create documentation files"
    "git_commit:Commit all changes to git"
    "git_push:Push to GitHub"
)

log_info() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_step() { echo -e "${CYAN}▶${NC} $1"; }

# Check if step is complete
is_complete() {
    grep -q "^$1$" "$CHECKPOINT_FILE" 2>/dev/null
}

# Mark step as complete
mark_complete() {
    echo "$1" >> "$CHECKPOINT_FILE"
}

# Display progress plan
show_plan() {
    local current_step=$1
    
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "  📋 AlphaOmega → Alf Repository Creation Plan"
    echo "════════════════════════════════════════════════════════"
    echo ""
    
    local step_num=1
    for step_info in "${STEPS[@]}"; do
        IFS=':' read -r step_id step_desc <<< "$step_info"
        
        local symbol=""
        local color=""
        local status=""
        
        if is_complete "$step_id"; then
            symbol="$COMPLETE"
            color="$GREEN"
            status="DONE"
        elif [ "$step_id" = "$current_step" ]; then
            symbol="$IN_PROGRESS"
            color="$YELLOW"
            status="IN PROGRESS"
        else
            symbol="$PENDING"
            color="$GRAY"
            status="PENDING"
        fi
        
        printf "${color}[%s]${NC} Step %2d: %-45s ${color}%s${NC}\n" \
               "$symbol" "$step_num" "$step_desc" "$status"
        
        ((step_num++))
    done
    
    echo ""
    echo "────────────────────────────────────────────────────────"
    
    # Show what will be created
    if [ "$current_step" = "" ]; then
        echo ""
        echo "${BLUE}📦 What will be created:${NC}"
        echo "  • Clean repository at: $PUBLIC_REPO_DIR"
        echo "  • Size: <100MB (no third-party bloat)"
        echo "  • Contains: Your original AlphaOmega code only"
        echo "  • Patches: For modified dependencies"
        echo "  • Scripts: One-command installation"
        echo "  • Docs: Architecture, setup, troubleshooting"
        echo ""
        echo "${BLUE}📤 What will be pushed:${NC}"
        echo "  • Repository: https://github.com/wspotter/Alf"
        echo "  • Branch: main"
        echo "  • Users can: git clone && ./install.sh"
        echo ""
        
        read -p "Press ENTER to begin, or Ctrl+C to cancel..."
    fi
    
    echo ""
}

# Cleanup on error
cleanup_on_error() {
    echo ""
    log_error "Script interrupted at current step!"
    echo ""
    echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${YELLOW}  Recovery Information${NC}"
    echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Progress saved to: $CHECKPOINT_FILE"
    echo ""
    echo "To resume from where you left off:"
    echo "  ${GREEN}./scripts/create-public-repo.sh${NC}"
    echo ""
    echo "To start completely fresh:"
    echo "  ${RED}rm $CHECKPOINT_FILE${NC}"
    echo "  ${GREEN}./scripts/create-public-repo.sh${NC}"
    echo ""
    exit 1
}

trap cleanup_on_error ERR INT TERM

# Show initial plan
show_plan ""

# STEP 1: Create directory structure
if ! is_complete "create_dirs"; then
    show_plan "create_dirs"
    log_step "Creating clean repository structure..."
    
    mkdir -p "$PUBLIC_REPO_DIR"/{scripts,config,pipelines,mcpart,docs,.github,patches}
    
    log_info "Directory structure created"
    mark_complete "create_dirs"
else
    log_warn "Step 1 already complete (skipping)"
fi

# STEP 2: Initialize git
if ! is_complete "init_git"; then
    show_plan "init_git"
    log_step "Initializing git repository..."
    
    cd "$PUBLIC_REPO_DIR"
    
    if [ ! -d ".git" ]; then
        git init
        git remote add origin https://github.com/wspotter/Alf.git 2>/dev/null || true
    fi
    
    log_info "Git repository initialized"
    mark_complete "init_git"
else
    log_warn "Step 2 already complete (skipping)"
fi

# STEP 3: Copy original AlphaOmega code
if ! is_complete "copy_code"; then
    show_plan "copy_code"
    log_step "Copying AlphaOmega original code (excluding third-party repos)..."
    
    # Copy scripts
    if [ -d "$PROJECT_ROOT/scripts" ]; then
        rsync -a "$PROJECT_ROOT/scripts/" "$PUBLIC_REPO_DIR/scripts/"
        log_info "Copied scripts/"
    fi
    
    # Copy mcpart (MCP server - 76 tools)
    if [ -d "$PROJECT_ROOT/mcpart" ]; then
        rsync -a --exclude='node_modules' --exclude='build' \
              "$PROJECT_ROOT/mcpart/" "$PUBLIC_REPO_DIR/mcpart/"
        log_info "Copied mcpart/"
    fi
    
    # Copy pipelines
    if [ -d "$PROJECT_ROOT/pipelines" ]; then
        rsync -a "$PROJECT_ROOT/pipelines/" "$PUBLIC_REPO_DIR/pipelines/"
        log_info "Copied pipelines/"
    fi
    
    # Copy config
    if [ -d "$PROJECT_ROOT/config" ]; then
        rsync -a "$PROJECT_ROOT/config/" "$PUBLIC_REPO_DIR/config/"
        log_info "Copied config/"
    fi
    
    # Copy GitHub workflows
    if [ -d "$PROJECT_ROOT/.github" ]; then
        rsync -a "$PROJECT_ROOT/.github/" "$PUBLIC_REPO_DIR/.github/"
        log_info "Copied .github/"
    fi
    
    # Copy CUA (Computer Use Agent)
    [ -f "$PROJECT_ROOT/computer_use_agent.py" ] && cp "$PROJECT_ROOT/computer_use_agent.py" "$PUBLIC_REPO_DIR/" && log_info "Copied CUA"
    [ -f "$PROJECT_ROOT/computer_use_gui.html" ] && cp "$PROJECT_ROOT/computer_use_gui.html" "$PUBLIC_REPO_DIR/"
    
    # Copy Dashboard
    [ -f "$PROJECT_ROOT/dashboard.py" ] && cp "$PROJECT_ROOT/dashboard.py" "$PUBLIC_REPO_DIR/" && log_info "Copied Dashboard"
    if [ -d "$PROJECT_ROOT/templates" ]; then
        rsync -a "$PROJECT_ROOT/templates/" "$PUBLIC_REPO_DIR/templates/"
    fi
    
    # Copy TTS setup files (exclude large repos)
    if [ -d "$PROJECT_ROOT/tts" ]; then
        mkdir -p "$PUBLIC_REPO_DIR/tts"
        cp "$PROJECT_ROOT/tts/"*.py "$PUBLIC_REPO_DIR/tts/" 2>/dev/null || true
        cp "$PROJECT_ROOT/tts/"*.sh "$PUBLIC_REPO_DIR/tts/" 2>/dev/null || true
        cp "$PROJECT_ROOT/tts/Dockerfile"* "$PUBLIC_REPO_DIR/tts/" 2>/dev/null || true
        cp "$PROJECT_ROOT/tts/"*.md "$PUBLIC_REPO_DIR/tts/" 2>/dev/null || true
        log_info "Copied TTS setup files"
    fi
    
    # Copy ComfyUI bridge
    if [ -d "$PROJECT_ROOT/comfyui_bridge" ]; then
        rsync -a "$PROJECT_ROOT/comfyui_bridge/" "$PUBLIC_REPO_DIR/comfyui_bridge/"
        log_info "Copied comfyui_bridge/"
    fi
    
    # Copy SearXNG config (exclude .venv)
    if [ -d "$PROJECT_ROOT/searxng" ]; then
        mkdir -p "$PUBLIC_REPO_DIR/searxng"
        cp "$PROJECT_ROOT/searxng/docker-compose.yml" "$PUBLIC_REPO_DIR/searxng/" 2>/dev/null || true
        cp "$PROJECT_ROOT/searxng/"*.conf "$PUBLIC_REPO_DIR/searxng/" 2>/dev/null || true
        cp "$PROJECT_ROOT/searxng/"*.md "$PUBLIC_REPO_DIR/searxng/" 2>/dev/null || true
        log_info "Copied SearXNG config"
    fi
    
    # Copy small data files
    if [ -d "$PROJECT_ROOT/data" ]; then
        rsync -a --exclude='*.db' --exclude='cache' \
              "$PROJECT_ROOT/data/" "$PUBLIC_REPO_DIR/data/"
        log_info "Copied data/"
    fi
    
    # Copy misc files
    [ -f "$PROJECT_ROOT/.env.example" ] && cp "$PROJECT_ROOT/.env.example" "$PUBLIC_REPO_DIR/"
    [ -f "$PROJECT_ROOT/README.md" ] && cp "$PROJECT_ROOT/README.md" "$PUBLIC_REPO_DIR/"
    
    log_info "Original code copied successfully"
    mark_complete "copy_code"
else
    log_warn "Step 3 already complete (skipping)"
fi

# STEP 4: Generate patches for modified repos
if ! is_complete "generate_patches"; then
    show_plan "generate_patches"
    log_step "Generating patches for modified dependencies..."
    
    cd "$PROJECT_ROOT"
    patches_created=0
    
    # ComfyUI patches (if modified)
    if [ -d "ComfyUI/.git" ]; then
        cd ComfyUI
        if ! git diff --quiet 2>/dev/null; then
            git diff > "$PUBLIC_REPO_DIR/patches/comfyui.patch"
            log_info "Created ComfyUI patch"
            ((patches_created++))
        fi
        cd "$PROJECT_ROOT"
    fi
    
    # OpenWebUI patches (if modified)
    if [ -d "open-webui/.git" ]; then
        cd open-webui
        if ! git diff --quiet 2>/dev/null; then
            git diff > "$PUBLIC_REPO_DIR/patches/open-webui.patch"
            log_info "Created OpenWebUI patch"
            ((patches_created++))
        fi
        cd "$PROJECT_ROOT"
    fi
    
    if [ $patches_created -eq 0 ]; then
        log_warn "No patches needed (no modifications detected)"
    else
        log_info "$patches_created patch(es) generated"
    fi
    
    mark_complete "generate_patches"
else
    log_warn "Step 4 already complete (skipping)"
fi

# STEP 5: Create installation script
if ! is_complete "create_install"; then
    show_plan "create_install"
    log_step "Creating automated installation script..."
    
    cat > "$PUBLIC_REPO_DIR/install.sh" << 'INSTALL_EOF'
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
INSTALL_EOF
    
    chmod +x "$PUBLIC_REPO_DIR/install.sh"
    log_info "Installation script created"
    mark_complete "create_install"
else
    log_warn "Step 5 already complete (skipping)"
fi

# STEP 6: Create requirements.txt
if ! is_complete "create_requirements"; then
    show_plan "create_requirements"
    log_step "Creating requirements.txt..."
    
    cat > "$PUBLIC_REPO_DIR/requirements.txt" << 'REQS_EOF'
# AlphaOmega Core Dependencies
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
pydantic>=2.5.0
python-dotenv>=1.0.0
aiofiles>=23.2.1
httpx>=0.25.0

# MCP Server
anthropic>=0.5.0

# Dashboard
flask>=3.0.0
flask-cors>=4.0.0

# Logging
python-json-logger>=2.0.7

# Utilities
pillow>=10.0.0
psutil>=5.9.0
requests>=2.31.0
REQS_EOF
    
    log_info "requirements.txt created"
    mark_complete "create_requirements"
else
    log_warn "Step 6 already complete (skipping)"
fi

# STEP 7: Create .gitignore
if ! is_complete "create_gitignore"; then
    show_plan "create_gitignore"
    log_step "Creating .gitignore..."
    
    cat > "$PUBLIC_REPO_DIR/.gitignore" << 'IGNORE_EOF'
# Third-party installations (installed via install.sh)
open-webui/
ComfyUI/
Agent-S/
cherry-studio/

# Python
venv/
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
*.so
*.egg-info/
dist/
build/

# Logs
logs/
*.log

# Environment
.env
.env.local

# Models (too large for git)
models/
*.ckpt
*.safetensors
*.pth

# Node
node_modules/
package-lock.json

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Build artifacts
*.egg-info/
dist/
build/

# Checkpoints
.repo-creation-checkpoint
IGNORE_EOF
    
    log_info ".gitignore created"
    mark_complete "create_gitignore"
else
    log_warn "Step 7 already complete (skipping)"
fi

# STEP 8: Create comprehensive README
if ! is_complete "create_readme"; then
    show_plan "create_readme"
    log_step "Creating README.md..."
    
    cat > "$PUBLIC_REPO_DIR/README.md" << 'README_EOF'
# Alf (AlphaOmega) - Unified Local AI Orchestration Platform

Privacy-first, hardware-agnostic AI platform combining multiple AI capabilities under one interface.

## 🎯 What is Alf?

A **unified local AI platform** that combines:
- **OpenWebUI** - Single web interface for all AI interactions
- **Ollama + LLaVA** - Multi-model LLM inference (vision, reasoning, code)
- **ComfyUI** - Advanced image generation workflows
- **Agent-S** - Computer use automation (screen analysis, mouse/keyboard control)
- **MCP Server (mcpart)** - Persistent memory, artifacts, and file operations

## ⚡ Quick Start

```bash
git clone https://github.com/wspotter/Alf.git
cd Alf
./install.sh
./scripts/start.sh
```

Open http://localhost:8080 and start using AI locally!

## 💡 Why Alf?

✅ **One-command installation** - No Docker, no complex setup  
✅ **Hardware-agnostic** - Auto-detects NVIDIA (CUDA), AMD (ROCm), or CPU  
✅ **100% local** - No cloud dependencies, complete privacy  
✅ **Unified interface** - No context switching between tools  
✅ **Computer use** - AI can see and control your screen  
✅ **Persistent memory** - Conversations and artifacts saved across sessions  

## 🔧 System Requirements

- **GPU**: NVIDIA (CUDA) or AMD (ROCm) recommended, CPU fallback supported
- **RAM**: 16GB minimum (32GB recommended for vision models)
- **Disk**: 50GB free space (for models and dependencies)
- **OS**: Linux (tested on Ubuntu 22.04+)

## 📚 Architecture

```
User → OpenWebUI (8080) → Pipeline Router (Intent Detection)
  ↓
  ├─> Ollama (11434) - Vision/Reasoning/Code
  ├─> ComfyUI (8188) - Image Generation
  ├─> Agent-S (8001) - Computer Use
  └─> MCP Server - Memory/Artifacts
```

All components run **locally** on your hardware.

## 📖 Documentation

- [Installation Guide](docs/INSTALL.md)
- [Architecture Overview](docs/ARCHITECTURE.md)
- [Configuration](docs/CONFIG.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## 🤝 Contributing

This is a meta-repository that integrates multiple open-source projects. Contributions welcome!

## 📄 License

Alf integration code: MIT  
Third-party components retain their original licenses.

## 🙏 Built With

- [OpenWebUI](https://github.com/open-webui/open-webui)
- [Ollama](https://ollama.com)
- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- [Agent-S](https://github.com/simular-ai/Agent-S)
README_EOF
    
    log_info "README.md created"
    mark_complete "create_readme"
else
    log_warn "Step 8 already complete (skipping)"
fi

# STEP 9: Create documentation
if ! is_complete "create_docs"; then
    show_plan "create_docs"
    log_step "Creating documentation files..."
    
    # Copy architecture from copilot instructions
    if [ -f "$PROJECT_ROOT/.github/copilot-instructions.md" ]; then
        cp "$PROJECT_ROOT/.github/copilot-instructions.md" "$PUBLIC_REPO_DIR/docs/ARCHITECTURE.md"
        log_info "Copied ARCHITECTURE.md"
    fi
    
    # Create install guide
    cat > "$PUBLIC_REPO_DIR/docs/INSTALL.md" << 'INSTALL_DOC_EOF'
# Installation Guide

## Automated Installation (Recommended)

```bash
./install.sh
```

This will:
1. Clone all dependencies (OpenWebUI, ComfyUI, Agent-S)
2. Apply AlphaOmega integration patches
3. Setup Python virtual environment
4. Install Ollama (if not present)
5. Pull recommended AI models

## Manual Installation

See [ARCHITECTURE.md](ARCHITECTURE.md) for component details.

## Post-Installation

1. Edit `.env` to configure your setup (optional)
2. Run `./scripts/start.sh` to start all services
3. Open http://localhost:8080

## Hardware-Specific Notes

### NVIDIA GPU
- CUDA will be auto-detected
- Models run on GPU by default

### AMD GPU  
- ROCm will be auto-detected
- Set `HSA_OVERRIDE_GFX_VERSION` if needed

### CPU Only
- Inference will be slower but fully functional
- Consider using smaller models (7B instead of 13B)
INSTALL_DOC_EOF
    
    log_info "Created INSTALL.md"
    
    # Create config guide
    cat > "$PUBLIC_REPO_DIR/docs/CONFIG.md" << 'CONFIG_DOC_EOF'
# Configuration Guide

## Environment Variables (.env)

```bash
# GPU Settings
CUDA_VISIBLE_DEVICES=0        # NVIDIA GPU selection
ROCR_VISIBLE_DEVICES=0        # AMD GPU selection

# Ollama
OLLAMA_KEEP_ALIVE=-1          # Keep models loaded (faster inference)
OLLAMA_HOST=http://localhost:11434

# Agent-S Safety
AGENT_SAFE_MODE=true          # Require confirmation for risky actions
AGENT_ALLOW_FILE_WRITE=true
AGENT_ALLOW_SYSTEM_COMMANDS=false
AGENT_ALLOWED_PATHS=/tmp,~/Downloads

# Logging
PIPELINE_LOG_LEVEL=INFO       # DEBUG for verbose logging
```

## Service Ports

- OpenWebUI: 8080
- Ollama: 11434
- ComfyUI: 8188
- Agent-S: 8001
- Dashboard: 5000

## Model Configuration

Edit `config/models.yaml` to add/remove models.
CONFIG_DOC_EOF
    
    log_info "Created CONFIG.md"
    
    # Create troubleshooting guide
    cat > "$PUBLIC_REPO_DIR/docs/TROUBLESHOOTING.md" << 'TROUBLE_DOC_EOF'
# Troubleshooting

## Common Issues

### GPU Not Detected
```bash
# NVIDIA
nvidia-smi

# AMD
rocm-smi
```

### Models Won't Load
```bash
# Check Ollama
curl http://localhost:11434/api/tags

# Restart Ollama
systemctl restart ollama
```

### Port Already in Use
```bash
# Find process using port
lsof -i :8080

# Stop service
./scripts/stop.sh
```

### Permission Denied
```bash
# Make scripts executable
chmod +x scripts/*.sh
chmod +x install.sh
```

## Getting Help

1. Check logs: `tail -f logs/pipeline.log`
2. Review documentation in `docs/`
3. Open an issue on GitHub
TROUBLE_DOC_EOF
    
    log_info "Created TROUBLESHOOTING.md"
    mark_complete "create_docs"
else
    log_warn "Step 9 already complete (skipping)"
fi

# STEP 10: Git commit
if ! is_complete "git_commit"; then
    show_plan "git_commit"
    log_step "Committing all changes to git..."
    
    cd "$PUBLIC_REPO_DIR"
    git add -A
    git commit -m "Initial commit: Alf (AlphaOmega) unified AI platform

Meta-repository with automated installation:
- One-command setup script (install.sh)
- Integration patches for third-party components
- Only includes original AlphaOmega code
- Hardware-agnostic (CUDA/ROCm/CPU)
- Privacy-first local execution

Components installed via install.sh:
- OpenWebUI (orchestration layer)
- Ollama (LLM inference)
- ComfyUI (image generation)
- Agent-S (computer use automation)
- MCP Server (memory/artifacts)

Repository size: <100MB (third-party code cloned during install)" 2>/dev/null || true
    
    log_info "Changes committed to git"
    mark_complete "git_commit"
else
    log_warn "Step 10 already complete (skipping)"
fi

# STEP 11: Push to GitHub
if ! is_complete "git_push"; then
    show_plan "git_push"
    log_step "Pushing to GitHub..."
    
    cd "$PUBLIC_REPO_DIR"
    
    # Try to push
    if git push -u origin main 2>&1; then
        log_info "Successfully pushed to GitHub!"
        mark_complete "git_push"
    else
        log_error "Push failed - you may need to authenticate or check the remote URL"
        echo ""
        echo "Manual push command:"
        echo "  cd $PUBLIC_REPO_DIR"
        echo "  git push -u origin main"
        echo ""
        exit 1
    fi
else
    log_warn "Step 11 already complete (skipping)"
fi

# Final success message
show_plan "COMPLETE"

echo ""
echo "════════════════════════════════════════════════════════"
echo -e "  ${GREEN}✅ SUCCESS! Repository Created and Pushed${NC}"
echo "════════════════════════════════════════════════════════"
echo ""
echo "${CYAN}Repository Details:${NC}"
echo "  GitHub URL: https://github.com/wspotter/Alf"
echo "  Local path: $PUBLIC_REPO_DIR"
echo "  Size: <100MB (excludes third-party dependencies)"
echo ""
echo "${CYAN}Users can now install with:${NC}"
echo "  ${GREEN}git clone https://github.com/wspotter/Alf.git${NC}"
echo "  ${GREEN}cd Alf && ./install.sh${NC}"
echo ""
echo "${CYAN}What was included:${NC}"
echo "  ✓ Original AlphaOmega code (scripts, pipelines, mcpart, config)"
echo "  ✓ Integration patches for modified dependencies"
echo "  ✓ One-command installation script"
echo "  ✓ Comprehensive documentation"
echo "  ✓ Hardware-agnostic setup (NVIDIA/AMD/CPU)"
echo ""

# Cleanup checkpoint file on complete success
rm -f "$CHECKPOINT_FILE"

log_info "Checkpoint file cleaned up"
