#!/bin/bash

# Cleanup Script - Move old files to review/ folder
# This organizes the repository for GitHub publication

PROJECT_ROOT="/home/stacy/AlphaOmega"
cd "$PROJECT_ROOT"

echo "🧹 Organizing AlphaOmega repository..."
echo "Moving old files to review/ folder for verification"
echo ""

# Create review directories
mkdir -p review/old_docs
mkdir -p review/old_scripts
mkdir -p review/old_configs
mkdir -p review/old_data

# Move old documentation
echo "📄 Moving old documentation..."
mv CHEAT_SHEET.md review/old_docs/ 2>/dev/null
mv CODE_REVIEW_SUMMARY.md review/old_docs/ 2>/dev/null
mv CURRENT_STATUS.md review/old_docs/ 2>/dev/null
mv DEPLOYMENT_GUIDE.md review/old_docs/ 2>/dev/null
mv KNOWLEDGE_BASE_SETUP.md review/old_docs/ 2>/dev/null
mv MCP_FINAL_SETUP.md review/old_docs/ 2>/dev/null
mv MCP_OPENWEBUI_SETUP.md review/old_docs/ 2>/dev/null
mv OPENWEBUI_DOCS_FETCHED.md review/old_docs/ 2>/dev/null
mv PIPER_TTS_COMPLETE.md review/old_docs/ 2>/dev/null
mv PROJECT_PLAN.md review/old_docs/ 2>/dev/null
mv QUICK_REFERENCE.txt review/old_docs/ 2>/dev/null
mv READY_TO_RUN.md review/old_docs/ 2>/dev/null
mv SETUP_STATUS.md review/old_docs/ 2>/dev/null
mv START_HERE_FIRST.md review/old_docs/ 2>/dev/null
mv SYSTEM_READY.md review/old_docs/ 2>/dev/null
mv UNIFIED_MCP_SERVER.md review/old_docs/ 2>/dev/null
mv VISUAL_SUMMARY.txt review/old_docs/ 2>/dev/null

# Move old model files
echo "📦 Moving old Modelfiles..."
mv Modelfile.devstral-vision review/old_configs/ 2>/dev/null
mv Modelfile.devstral-vision-fixed review/old_configs/ 2>/dev/null

# Move renamed wrong scripts
echo "🔧 Moving old/wrong scripts..."
find scripts/ -name "*.WRONG_DONT_USE" -exec mv {} review/old_scripts/ \; 2>/dev/null
find scripts/ -name "*old*" -exec mv {} review/old_scripts/ \; 2>/dev/null

# Move Dockerfile for agent_s (if using local instead)
echo "🐳 Moving unused Docker files..."
mv Dockerfile.agent_s review/old_configs/ 2>/dev/null

# Move old data directories
echo "📁 Moving old data..."
mv open-webui-docs review/old_data/ 2>/dev/null
mv artifacts review/old_data/ 2>/dev/null 2>/dev/null
mv data review/old_data/ 2>/dev/null

# Check what's left in scripts/
echo ""
echo "📋 Checking for other old scripts..."
ls -la scripts/ | grep -i "old\|backup\|test\|tmp" | while read line; do
    file=$(echo "$line" | awk '{print $NF}')
    if [ -f "scripts/$file" ]; then
        echo "  Found: scripts/$file"
    fi
done

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Files moved to review/ folder:"
echo "  - review/old_docs/     (old documentation)"
echo "  - review/old_scripts/  (wrong/old scripts)"  
echo "  - review/old_configs/  (old config files)"
echo "  - review/old_data/     (old data directories)"
echo ""
echo "Please verify the contents before deleting:"
echo "  ls -la review/old_docs/"
echo "  ls -la review/old_scripts/"
echo ""
