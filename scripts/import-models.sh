#!/bin/bash
# Import Models from /mnt/sdb2/models into Ollama

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MODELS_BASE="/mnt/sdb2/models"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=================================================="
echo "AlphaOmega Model Importer"
echo "=================================================="
echo ""

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Ollama doesn't appear to be running${NC}"
    echo "Please start Ollama first:"
    echo "  ./scripts/start-all.sh"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Function to create and import model
import_model() {
    local name=$1
    local path=$2
    local temp=$3
    local ctx=$4
    local description=$5
    
    echo -e "${BLUE}Importing $name...${NC}"
    
    # Create Modelfile
    cat > /tmp/${name}.modelfile <<EOF
FROM $path
PARAMETER temperature $temp
PARAMETER num_ctx $ctx
EOF
    
    # Import to Ollama
    if ollama create $name -f /tmp/${name}.modelfile; then
        echo -e "${GREEN}✓ Successfully imported $name${NC}"
        echo "  Description: $description"
        echo ""
        rm /tmp/${name}.modelfile
        return 0
    else
        echo -e "${YELLOW}✗ Failed to import $name${NC}"
        echo ""
        return 1
    fi
}

# List available models
echo "Found models in $MODELS_BASE:"
echo ""

# Vision Model
echo "Vision Models:"
if [ -f "$MODELS_BASE/leafspark/Devstral-Small-Vision-2505-GGUF/Devstral-Small-Vision-2505-Q4_K_M.gguf" ]; then
    echo "  ✓ Devstral-Small-Vision-2505 (Q4_K_M) - 4-bit quantized vision model"
fi

echo ""
echo "Code Models:"
if [ -f "$MODELS_BASE/bartowski/Phind-CodeLlama-34B-v2-GGUF/Phind-CodeLlama-34B-v2.Q3_K_S.gguf" ]; then
    echo "  ✓ Phind-CodeLlama-34B-v2 (Q3_K_S) - Optimized for code completion"
fi
if [ -f "$MODELS_BASE/bartowski/Qwen2.5-Coder-14B-Instruct-abliterated-GGUF/Qwen2.5-Coder-14B-Instruct-abliterated-Q4_K_S.gguf" ]; then
    echo "  ✓ Qwen2.5-Coder-14B (Q4_K_S) - Instruction-tuned coder"
fi

echo ""
echo "General Purpose Models:"
if [ -f "$MODELS_BASE/lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF/Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf" ]; then
    echo "  ✓ Llama-3.1-8B-Instruct (Q5_K_M) - Versatile assistant"
fi

echo ""
echo "=================================================="
echo ""

# Interactive import
echo "Which models would you like to import?"
echo ""
echo "1. Vision Model (Devstral - for Agent-S screen analysis)"
echo "2. Code Model (Phind-CodeLlama-34B - for code generation)"
echo "3. Code Model (Qwen2.5-Coder-14B - lighter, instruction-tuned)"
echo "4. General Model (Llama-3.1-8B - versatile assistant)"
echo "5. All of the above"
echo "6. Skip import (models already imported)"
echo ""

read -p "Enter choice (1-6): " choice

case $choice in
    1)
        import_model "devstral-vision" \
            "$MODELS_BASE/leafspark/Devstral-Small-Vision-2505-GGUF/Devstral-Small-Vision-2505-Q4_K_M.gguf" \
            "0.2" "2048" "Vision model for screen analysis"
        ;;
    2)
        import_model "phind-codellama" \
            "$MODELS_BASE/bartowski/Phind-CodeLlama-34B-v2-GGUF/Phind-CodeLlama-34B-v2.Q3_K_S.gguf" \
            "0.1" "4096" "Code generation and completion"
        ;;
    3)
        import_model "qwen-coder" \
            "$MODELS_BASE/bartowski/Qwen2.5-Coder-14B-Instruct-abliterated-GGUF/Qwen2.5-Coder-14B-Instruct-abliterated-Q4_K_S.gguf" \
            "0.1" "4096" "Instruction-tuned code model"
        ;;
    4)
        import_model "llama3-8b" \
            "$MODELS_BASE/lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF/Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf" \
            "0.7" "4096" "General purpose assistant"
        ;;
    5)
        import_model "devstral-vision" \
            "$MODELS_BASE/leafspark/Devstral-Small-Vision-2505-GGUF/Devstral-Small-Vision-2505-Q4_K_M.gguf" \
            "0.2" "2048" "Vision model for screen analysis"
        
        import_model "phind-codellama" \
            "$MODELS_BASE/bartowski/Phind-CodeLlama-34B-v2-GGUF/Phind-CodeLlama-34B-v2.Q3_K_S.gguf" \
            "0.1" "4096" "Code generation and completion"
        
        import_model "qwen-coder" \
            "$MODELS_BASE/bartowski/Qwen2.5-Coder-14B-Instruct-abliterated-GGUF/Qwen2.5-Coder-14B-Instruct-abliterated-Q4_K_S.gguf" \
            "0.1" "4096" "Instruction-tuned code model"
        
        import_model "llama3-8b" \
            "$MODELS_BASE/lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF/Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf" \
            "0.7" "4096" "General purpose assistant"
        ;;
    6)
        echo "Skipping model import"
        echo ""
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo "=================================================="
echo ""
echo "Model import complete!"
echo ""
echo "To see imported models:"
echo "  ollama list"
echo ""
echo "To test a model:"
echo "  ollama run devstral-vision"
echo ""
