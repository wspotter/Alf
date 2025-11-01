# 🎯 How to Use Piper Voices in OpenWebUI

## The Problem
OpenWebUI hardcodes the OpenAI default voices (`alloy`, `echo`, `fable`, etc.) in its dropdown. It doesn't automatically fetch voices from the TTS API endpoint.

## ✅ Solution: Manual Voice Entry

### Method 1: Type Voice Name Directly (Easiest)
1. In OpenWebUI Admin Panel → Settings → Audio → Text-to-Speech
2. **Click inside the TTS Voice dropdown** (where it says "alloy")
3. **Clear it and type**: `ryan` (or any of: `lessac`, `amy`, `joe`, `alan`, `alba`)
4. **Press Enter or Tab**
5. **Click "Save"** button at the bottom
6. Test in chat with 🔊 button

### Method 2: Edit with Browser Console
1. Open OpenWebUI settings page
2. Press **F12** to open Developer Console
3. Paste this code:
```javascript
// Find the TTS voice input
const input = document.querySelector('input[value="alloy"]');
if (input) {
  input.value = 'ryan';  // Change to your preferred voice
  input.dispatchEvent(new Event('input', { bubbles: true }));
  console.log('✅ Voice changed to ryan');
}
```
4. Press Enter
5. Click "Save" in OpenWebUI

### Method 3: Direct Database Edit (Advanced)
```bash
# Backup first
cp /home/stacy/AlphaOmega/openwebui_data/webui.db /home/stacy/AlphaOmega/openwebui_data/webui.db.backup

# Edit TTS settings (replace USER_ID with your user ID)
sqlite3 /home/stacy/AlphaOmega/openwebui_data/webui.db << 'EOF'
-- Check current settings
SELECT * FROM user WHERE role='admin';
-- Update will be done via API instead
EOF
```

### Method 4: Use OpenWebUI API (Best for automation)
```bash
# Get auth token from browser (F12 → Application → Cookies → token)
TOKEN="your-token-here"

# Update TTS settings via API
curl -X POST http://localhost:8080/api/config/tts \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "engine": "openai",
    "api_base_url": "http://localhost:5002/v1",
    "voice": "ryan"
  }'
```

## 🎤 Available Piper Voices

Just type one of these into the TTS Voice field:

- **`ryan`** - Male, American, professional
- **`lessac`** - Female, American, clear (default)
- **`amy`** - Female, American, friendly
- **`joe`** - Male, American, casual
- **`alan`** - Male, British, formal
- **`alba`** - Female, British, elegant

## ✅ Verify It Works

After saving, test the voice:
```bash
# Test the API directly
curl -X POST http://localhost:5002/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"input":"Hello, this is a test","voice":"ryan"}' \
  --output /tmp/test.wav

# Play it
ffplay -nodisp -autoexit /tmp/test.wav
```

## 🔧 Why This Happens

OpenWebUI's frontend hardcodes OpenAI voices for the dropdown, but the backend accepts **any** voice string and passes it to the TTS API. So you can:

1. Type any voice name manually ✅
2. API will receive it ✅  
3. Piper will use that voice ✅

The dropdown is just UI - the actual voice value can be anything!

## 📝 Alternative: Fork OpenWebUI

If you want a proper dropdown with Piper voices, you'd need to:
1. Fork OpenWebUI repository
2. Edit the TTS settings component to fetch voices from `/v1/audio/voices`
3. Rebuild and deploy

But manual entry works perfectly fine! 🎉

---

**Quick Test**:
1. Type `ryan` in the TTS Voice field
2. Save
3. Go to chat
4. Send a message
5. Click 🔊 - you should hear Ryan's voice!
