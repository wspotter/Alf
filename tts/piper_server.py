#!/usr/bin/env python3
"""
OpenAI-compatible TTS API server for Piper TTS
Provides /v1/audio/speech endpoint compatible with OpenWebUI
"""

import os
import subprocess
import tempfile
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse, Response
from pydantic import BaseModel
from typing import Optional
import uvicorn

app = FastAPI(title="Piper TTS API", version="1.0.0")

# Configuration
PIPER_BINARY = Path(__file__).parent / "piper" / "piper"
VOICE_MODEL = Path(__file__).parent / "en_US-lessac-medium.onnx"

class TTSRequest(BaseModel):
    model: str = "tts-1"  # OpenAI compatibility
    input: str
    voice: str = "lessac"  # Only one voice for now
    response_format: Optional[str] = "mp3"
    speed: Optional[float] = 1.0

@app.get("/")
async def root():
    return {
        "service": "Piper TTS API",
        "status": "running",
        "version": "1.0.0",
        "compatible_with": "OpenAI TTS API"
    }

@app.get("/v1/models")
async def list_models():
    """List available TTS models (OpenAI compatibility)"""
    return {
        "object": "list",
        "data": [
            {
                "id": "tts-1",
                "object": "model",
                "created": 1677610602,
                "owned_by": "piper-tts"
            }
        ]
    }

@app.post("/v1/audio/speech")
async def create_speech(request: TTSRequest):
    """
    Generate speech from text using Piper TTS
    Compatible with OpenAI's /v1/audio/speech endpoint
    """
    
    if not request.input or request.input.strip() == "":
        raise HTTPException(status_code=400, detail="Input text is required")
    
    if not PIPER_BINARY.exists():
        raise HTTPException(status_code=500, detail="Piper binary not found")
    
    if not VOICE_MODEL.exists():
        raise HTTPException(status_code=500, detail="Voice model not found")
    
    try:
        # Create temporary WAV file
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_wav:
            wav_path = tmp_wav.name
        
        # Generate speech with Piper
        process = subprocess.Popen(
            [
                str(PIPER_BINARY),
                "-m", str(VOICE_MODEL),
                "-f", wav_path,
                "--length_scale", str(1.0 / request.speed)  # Speed adjustment
            ],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        stdout, stderr = process.communicate(input=request.input.encode('utf-8'))
        
        if process.returncode != 0:
            os.remove(wav_path)
            raise HTTPException(
                status_code=500, 
                detail=f"Piper TTS failed: {stderr.decode('utf-8')}"
            )
        
        # If MP3 requested, convert with ffmpeg (if available)
        if request.response_format == "mp3":
            mp3_path = wav_path.replace(".wav", ".mp3")
            
            # Try to convert to MP3
            try:
                subprocess.run(
                    ["ffmpeg", "-i", wav_path, "-codec:a", "libmp3lame", "-qscale:a", "2", 
                     "-y", mp3_path],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=True
                )
                os.remove(wav_path)
                audio_path = mp3_path
                media_type = "audio/mpeg"
            except (subprocess.CalledProcessError, FileNotFoundError):
                # ffmpeg not available or failed, return WAV
                audio_path = wav_path
                media_type = "audio/wav"
        else:
            audio_path = wav_path
            media_type = "audio/wav"
        
        # Read audio file
        with open(audio_path, "rb") as f:
            audio_data = f.read()
        
        # Clean up
        os.remove(audio_path)
        
        return Response(content=audio_data, media_type=media_type)
    
    except Exception as e:
        # Clean up on error
        if 'wav_path' in locals() and os.path.exists(wav_path):
            os.remove(wav_path)
        if 'mp3_path' in locals() and os.path.exists(mp3_path):
            os.remove(mp3_path)
        
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "piper_binary": str(PIPER_BINARY.exists()),
        "voice_model": str(VOICE_MODEL.exists())
    }

if __name__ == "__main__":
    import sys
    sys.stderr.write("🎙️  Starting Piper TTS API Server\n")
    sys.stderr.write(f"📍 Piper binary: {PIPER_BINARY}\n")
    sys.stderr.write(f"🎤 Voice model: {VOICE_MODEL}\n")
    sys.stderr.write(f"🌐 API endpoint: http://0.0.0.0:5002\n")
    sys.stderr.write(f"📖 OpenAI-compatible endpoint: /v1/audio/speech\n")
    sys.stderr.write(f"✅ Health check: http://localhost:5002/health\n")
    sys.stderr.flush()
    
    uvicorn.run(app, host="0.0.0.0", port=5002, log_level="error")
