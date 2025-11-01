# AlphaOmega - AI Coding Assistant Instructions

## Project Overview

AlphaOmega is a unified local AI orchestration platform that combines:
- **OpenWebUI** - Single web interface for all AI interactions
- **Ollama + LLaVA** - Multi-model LLM inference (vision, reasoning, code)
- **ComfyUI** - Advanced image generation (SDXL, Flux workflows)
- **Agent-S** - Computer use automation (screen analysis, mouse/keyboard control)
- **MCP Server (mcpart)** - Persistent artifacts, memory, and file operations

Hardware-agnostic: Works with NVIDIA (CUDA), AMD (ROCm), or CPU fallback.
Philosophy: Everything runs locally, no cloud dependencies, privacy-first design

## Architecture

### System Flow
```
User → OpenWebUI (Port 8080) → Pipeline Router (Intent Detection)
  ↓
  ├─> Ollama - Vision/Reasoning/Code (auto-selects GPU/CPU)
  ├─> ComfyUI - Image generation [LOCAL] (auto-selects GPU)
  ├─> Agent-S (Computer use) - Screen/mouse/keyboard [LOCAL]
  ├─> Chatterbox TTS (port 5003) - Text-to-speech [LOCAL]
  └─> MCP Server (mcpart) - Artifacts/memory/files [LOCAL]
```

### Acceleration
- NVIDIA (CUDA) and AMD (ROCm) supported; CPU fallback when no GPU.
- No per-GPU pinning by default. To constrain devices if needed:
  - NVIDIA: `CUDA_VISIBLE_DEVICES=0`
  - AMD: `ROCR_VISIBLE_DEVICES=0`

### Key Design Decisions

**Why OpenWebUI as orchestrator?**
- Single unified interface (no context switching)
- Built-in pipeline system for intelligent routing
- Active development, ComfyUI integration support
- Streaming responses and great UX
- **Runs locally** - No Docker, direct Python execution

**Why separate Agent-S service (LOCAL)?**
- Needs host network access for X11/Wayland
- Requires privileged mode for input control
- Isolates potentially risky computer use actions
- Independent FastAPI server for direct API access
- **Must run locally** - Needs direct display/input access

**Why integrate mcpart MCP server (LOCAL)?**
- Persistent memory across sessions
- Artifact creation/management (code, documents)
- File operations with safety validation
- Extensible tool system
- **Must run locally** - Needs direct filesystem access

## Development Setup

All startup and testing is centralized under `scripts/` and the web dashboard.

### Quick Start (Dashboard-centric)
```bash
cd /home/stacy/AlphaOmega
# Start dashboard (auto-creates venv and installs deps if needed)
./scripts/start-dashboard.sh

# Start all services via dashboard API
./scripts/start.sh

# Check status
curl -s http://localhost:5000/api/status | jq '.'
```

### Stop Services
- Use the Dashboard UI Stop All button, or call `POST /api/stop_all`.
- Stop the dashboard itself when done:
```bash
./scripts/stop-dashboard.sh
```

### Monitor Pipeline Routing
```bash
export PIPELINE_LOG_LEVEL=DEBUG

# Restart OpenWebUI locally
pkill -f "open-webui serve"
cd /home/stacy/AlphaOmega
source venv/bin/activate
open-webui serve --port 8080 &

tail -f logs/pipeline.log | grep "intent:"
```

### Optimize Model Performance
```bash
# Keep models loaded in memory (no reload delays)
export OLLAMA_KEEP_ALIVE=-1
```

## GPU Notes (Vendor-agnostic)

- Verify NVIDIA GPUs with `nvidia-smi`; verify AMD GPUs with `rocm-smi`.
- By default, AlphaOmega does not pin devices; frameworks auto-select available accelerators.
- If you must pin, set `CUDA_VISIBLE_DEVICES` (NVIDIA) or `ROCR_VISIBLE_DEVICES` (AMD) before launching a service.

## Safety Considerations

### Agent-S Safe Mode
```bash
# Enable safe mode (requires confirmation for risky actions)
AGENT_SAFE_MODE=true

# Actions that trigger validation:
# - File system writes outside /tmp
# - System command execution
# - Application launches
# - Dangerous hotkeys (Ctrl+Alt+Del, Alt+F4, etc.)
```

### Action Logging
All Agent-S actions are logged:
```bash
tail -f logs/agent_actions.log
# Format: timestamp | action_type | params | result | safety_check
```

### Configurable Permissions
Edit `.env`:
```bash
AGENT_ALLOW_FILE_WRITE=false        # Disable file operations
AGENT_ALLOW_SYSTEM_COMMANDS=false   # Disable system commands
AGENT_ALLOW_APP_LAUNCH=true         # Allow app launching
AGENT_ALLOWED_PATHS=/tmp,~/Downloads  # Restrict file access
```

## Performance Tips

1. **Keep Models Loaded**: `OLLAMA_KEEP_ALIVE=-1` prevents reload delays (~5-10s)
2. **Resize Screenshots**: Scale to 1280x720 before vision analysis (2-3x faster, similar accuracy)
3. **Region Analysis**: Use `analyze_region()` for UI elements instead of full screen
4. **Parallel Inference**: Vision and reasoning can run concurrently; backends share available accelerators
5. **ComfyUI Cache**: Enable model caching to speed up repeated generations

## Integration Points

### OpenWebUI ↔ Agent-S
- OpenWebUI pipeline detects computer use intent
- Routes to Agent-S API at http://localhost:8001/action
- Agent-S streams back results with screenshots

### Agent-S ↔ Ollama
- Agent-S captures screenshot
- Sends to Ollama endpoint via ollama.Client
- Receives vision analysis for action planning

### Agent-S ↔ MCP Server
- Agent-S uses MCPClient for artifacts and memory
- Stores action history, creates code artifacts
- Persistent memory across sessions

---

*This is a living document. Update as new patterns emerge, especially around vision optimization and multi-GPU workload distribution.*
