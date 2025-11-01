#!/bin/bash
# Download Piper voice models (medium and high quality)

BASE_URL="https://huggingface.co/rhasspy/piper-voices/resolve/main"

echo "🎙️  Downloading Piper voice models..."
echo ""

# High-quality voices (116MB, 109MB - most natural sounding)
echo "📥 Downloading high-quality voices (recommended)..."
echo "   Ryan (Male US) - 116MB"
wget -q --show-progress "$BASE_URL/en/en_US/ryan/high/en_US-ryan-high.onnx" -O en_US-ryan-high.onnx 2>/dev/null || echo "✓ ryan-high (already exists)"
wget -q --show-progress "$BASE_URL/en/en_US/ryan/high/en_US-ryan-high.onnx.json" -O en_US-ryan-high.onnx.json 2>/dev/null

echo "   Lessac (Female US) - 109MB"
wget -q --show-progress "$BASE_URL/en/en_US/lessac/high/en_US-lessac-high.onnx" -O en_US-lessac-high.onnx 2>/dev/null || echo "✓ lessac-high (already exists)"
wget -q --show-progress "$BASE_URL/en/en_US/lessac/high/en_US-lessac-high.onnx.json" -O en_US-lessac-high.onnx.json 2>/dev/null

echo ""
echo "📥 Downloading medium-quality voices..."
echo "   Amy (Female US) - 60MB"
wget -q --show-progress "$BASE_URL/en/en_US/amy/medium/en_US-amy-medium.onnx" -O en_US-amy-medium.onnx 2>/dev/null || echo "✓ amy (already exists)"
wget -q --show-progress "$BASE_URL/en/en_US/amy/medium/en_US-amy-medium.onnx.json" -O en_US-amy-medium.onnx.json 2>/dev/null

echo "   Joe (Male US) - 60MB"
wget -q --show-progress "$BASE_URL/en/en_US/joe/medium/en_US-joe-medium.onnx" -O en_US-joe-medium.onnx 2>/dev/null || echo "✓ joe (already exists)"
wget -q --show-progress "$BASE_URL/en/en_US/joe/medium/en_US-joe-medium.onnx.json" -O en_US-joe-medium.onnx.json 2>/dev/null

echo "   Alan (Male UK) - 60MB"
wget -q --show-progress "$BASE_URL/en/en_GB/alan/medium/en_GB-alan-medium.onnx" -O en_GB-alan-medium.onnx 2>/dev/null || echo "✓ alan (already exists)"
wget -q --show-progress "$BASE_URL/en/en_GB/alan/medium/en_GB-alan-medium.onnx.json" -O en_GB-alan-medium.onnx.json 2>/dev/null

echo "   Alba (Female UK) - 60MB"
wget -q --show-progress "$BASE_URL/en/en_GB/alba/medium/en_GB-alba-medium.onnx" -O en_GB-alba-medium.onnx 2>/dev/null || echo "✓ alba (already exists)"
wget -q --show-progress "$BASE_URL/en/en_GB/alba/medium/en_GB-alba-medium.onnx.json" -O en_GB-alba-medium.onnx.json 2>/dev/null

echo ""
echo "✅ Voice downloads complete!"
echo ""
echo "📊 Available voices:"
echo "   High-quality (most natural):"
echo "   • ryan (Male US) - Professional, clear"
echo "   • lessac (Female US) - Warm, engaging"
echo ""
echo "   Medium-quality:"
echo "   • amy (Female US) - Friendly, casual"
echo "   • joe (Male US) - Conversational"
echo "   • alan (Male UK) - British accent"
echo "   • alba (Female UK) - British accent"
echo ""
echo "💡 The API automatically uses high-quality versions when available."
