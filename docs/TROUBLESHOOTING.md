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
