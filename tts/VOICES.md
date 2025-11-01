# Piper TTS Voices (Quick Picks)

This page lists a handful of high‑quality English voices for Piper TTS with direct download links. You don’t need a different TTS “model” in OpenWebUI—just drop these files into this `tts/` folder and restart the local TTS server.

Works with our local API at:
- Base URL: `http://localhost:5002/v1`
- Voices endpoint: `GET /v1/voices`
- Health: `GET /health`

Tip: In OpenWebUI → Settings → Audio → Text‑to‑Speech set:
- Engine: OpenAI
- Base URL: `http://localhost:5002/v1`
- Voice: type the short name below (e.g., `ryan`, `lessac`)

Then test with the Speak button in a chat. If you see an error, verify `/v1/voices` lists your chosen voice.

---

## How to install a voice

Place both files (.onnx and .onnx.json) in this `tts/` directory and restart the server.

```bash
# From repo root
bash scripts/start-tts.sh   # (auto-downloads a default set if none found)

# Or download specific voices using the links below, then restart:
# bash scripts/start-tts.sh
```

Base direct‑download host used below:
```
https://huggingface.co/rhasspy/piper-voices/resolve/main
```

---

## Popular English voices

| Language | Voice (short) | Gender | Accent | Quality | ONNX | JSON | Notes |
|---|---|---|---|---|---|---|---|
| en_US | ryan | Male | American | high | [onnx](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx) | [json](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx.json) | Clear, professional (recommended) |
| en_US | lessac | Female | American | high | [onnx](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/high/en_US-lessac-high.onnx) | [json](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/high/en_US-lessac-high.onnx.json) | Warm, natural (recommended) |
| en_US | amy | Female | American | medium | [onnx](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx) | [json](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx.json) | Friendly, casual |
| en_US | joe | Male | American | medium | [onnx](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/joe/medium/en_US-joe-medium.onnx) | [json](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/joe/medium/en_US-joe-medium.onnx.json) | Conversational |
| en_GB | alan | Male | British | medium | [onnx](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alan/medium/en_GB-alan-medium.onnx) | [json](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alan/medium/en_GB-alan-medium.onnx.json) | Clear UK accent |
| en_GB | alba | Female | British | medium | [onnx](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alba/medium/en_GB-alba-medium.onnx) | [json](https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alba/medium/en_GB-alba-medium.onnx.json) | Elegant UK accent |

> The “high” quality models are larger (~100–120 MB) but sound more natural. “medium” models are ~60 MB and still very good.

### One‑liners to download into `tts/`
```bash
# From repo root
cd tts

# Ryan (Male, US, high)
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx" -O en_US-ryan-high.onnx
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx.json" -O en_US-ryan-high.onnx.json

# Lessac (Female, US, high)
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/high/en_US-lessac-high.onnx" -O en_US-lessac-high.onnx
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/lessac/high/en_US-lessac-high.onnx.json" -O en_US-lessac-high.onnx.json

# Amy (Female, US, medium)
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx" -O en_US-amy-medium.onnx
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/amy/medium/en_US-amy-medium.onnx.json" -O en_US-amy-medium.onnx.json

# Joe (Male, US, medium)
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/joe/medium/en_US-joe-medium.onnx" -O en_US-joe-medium.onnx
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/joe/medium/en_US-joe-medium.onnx.json" -O en_US-joe-medium.onnx.json

# Alan (Male, UK, medium)
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alan/medium/en_GB-alan-medium.onnx" -O en_GB-alan-medium.onnx
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alan/medium/en_GB-alan-medium.onnx.json" -O en_GB-alan-medium.onnx.json

# Alba (Female, UK, medium)
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alba/medium/en_GB-alba-medium.onnx" -O en_GB-alba-medium.onnx
wget -q "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_GB/alba/medium/en_GB-alba-medium.onnx.json" -O en_GB-alba-medium.onnx.json
```

---

## Verify your voices

```bash
# After downloading, (re)start the server
bash ../scripts/start-tts.sh

# Check API
curl -s http://localhost:5002/health | jq .
curl -s http://localhost:5002/v1/voices | jq .
```

If the `voices` array lists your short IDs (e.g., `ryan`, `lessac`), you’re good to go.

Try it locally without OpenWebUI:
```bash
curl -s -X POST http://localhost:5002/v1/audio/speech \
	-H 'Content-Type: application/json' \
	-d '{"input":"This is a test of Piper text to speech.","voice":"lessac"}' \
	-o /tmp/tts.wav && aplay /tmp/tts.wav
```

---

## Troubleshooting
- If `/v1/voices` is empty: make sure the `.onnx` and matching `.onnx.json` are in `tts/` and restart the TTS server.
- If audio doesn’t play in OpenWebUI: confirm Base URL is `http://localhost:5002/v1` and the Voice matches one of the short names listed by `GET /v1/voices`.
- If you don’t have a `piper` binary in `tts/piper/piper`, the server will try to use the system `piper` from `$PATH`.

---

Looking for more voices? Browse all Piper voices here:
- https://huggingface.co/rhasspy/piper-voices/tree/main
