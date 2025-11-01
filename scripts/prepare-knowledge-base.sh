#!/bin/bash
# Prepare documentation for OpenWebUI Knowledge upload

PROJECT_DIR="/home/stacy/AlphaOmega"
KNOWLEDGE_DIR="$PROJECT_DIR/artifacts/knowledge-uploads"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=================================================="
echo "Preparing Documentation for OpenWebUI Knowledge"
echo "=================================================="
echo ""

# Create directory
mkdir -p "$KNOWLEDGE_DIR"
rm -f "$KNOWLEDGE_DIR"/* 2>/dev/null

echo -e "${BLUE}Collecting documentation files...${NC}"
echo ""

# Project documentation
if [ -d "$PROJECT_DIR/docs" ]; then
    echo "  • Project docs"
    cp "$PROJECT_DIR/docs"/*.md "$KNOWLEDGE_DIR/" 2>/dev/null
fi

# MCP setup guides
echo "  • MCP guides"
cp "$PROJECT_DIR"/MCP_*.md "$KNOWLEDGE_DIR/" 2>/dev/null

# System documentation
echo "  • System docs"
cp "$PROJECT_DIR/SYSTEM_READY.md" "$KNOWLEDGE_DIR/" 2>/dev/null
cp "$PROJECT_DIR/QUICK_REFERENCE.txt" "$KNOWLEDGE_DIR/" 2>/dev/null
cp "$PROJECT_DIR/KNOWLEDGE_BASE_SETUP.md" "$KNOWLEDGE_DIR/" 2>/dev/null

# MCPart documentation
if [ -d "$PROJECT_DIR/mcpart" ]; then
    echo "  • MCPart docs"
    cp "$PROJECT_DIR/mcpart/README.md" "$KNOWLEDGE_DIR/MCPart-README.md" 2>/dev/null
    cp "$PROJECT_DIR/mcpart/TOOLS_DOCUMENTATION.md" "$KNOWLEDGE_DIR/MCPart-Tools.md" 2>/dev/null
    cp "$PROJECT_DIR/mcpart/QUICK_REFERENCE.md" "$KNOWLEDGE_DIR/MCPart-QuickRef.md" 2>/dev/null
fi

# Copilot instructions (helpful context)
if [ -f "$PROJECT_DIR/.github/copilot-instructions.md" ]; then
    echo "  • Project instructions"
    cp "$PROJECT_DIR/.github/copilot-instructions.md" "$KNOWLEDGE_DIR/AlphaOmega-Instructions.md" 2>/dev/null
fi

echo ""
echo -e "${GREEN}✓ Documentation collected!${NC}"
echo ""
echo "=================================================="
echo "Files ready for upload:"
echo "=================================================="
echo ""
ls -lh "$KNOWLEDGE_DIR" | grep -v ^total | awk '{printf "  %-40s %5s\n", $9, $5}'
echo ""
echo "=================================================="
echo "Total files: $(ls -1 "$KNOWLEDGE_DIR" | wc -l)"
echo "Total size:  $(du -sh "$KNOWLEDGE_DIR" | cut -f1)"
echo "=================================================="
echo ""
echo "📚 Next Steps:"
echo ""
echo "1. Open OpenWebUI: http://localhost:8080"
echo "2. Go to Workspace → Knowledge"
echo "3. Click 'Create Knowledge' or '+ New Collection'"
echo "4. Name it: 'AlphaOmega Documentation'"
echo "5. Upload all files from:"
echo "   $KNOWLEDGE_DIR"
echo ""
echo "Or use file browser to navigate and select all files."
echo ""
echo "💡 Tip: You can also drag & drop the entire folder!"
echo ""
