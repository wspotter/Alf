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
