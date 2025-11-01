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
