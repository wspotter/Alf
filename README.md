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
