#!/usr/bin/env python3
"""
Simple OpenAI-compatible TTS API for Piper via subprocess
Ultra-fast and reliable - Now with multiple voices!
"""

import os
import subprocess
import tempfile
from pathlib import Path
import shutil
from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel
from typing import Optional
import uvicorn
import asyncio
import glob

app = FastAPI(title="Piper TTS API", version="2.0.0")

# Configuration
def _locate_piper_binary() -> Path:
    local = Path(__file__).parent / "piper" / "piper"
    if local.exists():
        return local
    # Try system PATH
    which = shutil.which("piper")
    if which:
        return Path(which)
    return local  # non-existing; health endpoint will reflect

PIPER_BINARY = _locate_piper_binary()
VOICES_DIR = Path(__file__).parent

# Discover all available voices
def get_available_voices():
    """Scan directory for .onnx voice models - prefer high quality"""
    voices = {}
    quality_priority = ['high', 'medium', 'low']  # Prefer high quality
    
    for onnx_file in VOICES_DIR.glob("*.onnx"):
        voice_name = onnx_file.stem  # e.g., "en_US-lessac-high"
        
        # Extract short name (e.g., "lessac") and quality level
        parts = voice_name.split('-')
        if len(parts) >= 2:
            short_name = parts[1]  # Get voice name
            quality = parts[-1] if parts[-1] in quality_priority else 'medium'
            
            # Only store if we don't have this voice yet, or if this is higher quality
            if short_name not in voices:
                voices[short_name] = onnx_file
            else:
                # Replace with higher quality version
                existing_quality = voices[short_name].stem.split('-')[-1]
                if quality_priority.index(quality) < quality_priority.index(existing_quality):
                    voices[short_name] = onnx_file
            
            # Also map full name for direct access
            voices[voice_name] = onnx_file
    
    return voices

AVAILABLE_VOICES = get_available_voices()

# Default voice
DEFAULT_VOICE = "lessac" if "lessac" in AVAILABLE_VOICES else list(AVAILABLE_VOICES.keys())[0]

class TTSRequest(BaseModel):
    model: str = "tts-1"
    input: str
    voice: str = DEFAULT_VOICE
    response_format: Optional[str] = "wav"
    speed: Optional[float] = 1.0

@app.get("/")
async def root():
    return {
        "service": "Piper TTS",
        "status": "running",
        "version": "2.0.0",
        "voices": len(AVAILABLE_VOICES),
        "default_voice": DEFAULT_VOICE
    }

@app.get("/v1/models")
async def list_models():
    return {
        "object": "list",
        "data": [{"id": "tts-1", "object": "model", "owned_by": "piper"}]
    }

@app.get("/v1/voices")
async def list_voices():
    """List all available voices"""
    voices_info = []
    for short_name, path in AVAILABLE_VOICES.items():
        # Skip duplicate full names
        if '-' in short_name:
            continue
        full_name = path.stem
        voices_info.append({
            "id": short_name,
            "name": full_name,
            "language": full_name.split('-')[0] if '-' in full_name else "en_US",
            "gender": _guess_gender(short_name),
            "accent": _guess_accent(full_name)
        })
    return {"voices": sorted(voices_info, key=lambda x: x['id'])}

@app.get("/v1/audio/voices")
async def list_audio_voices():
    """OpenWebUI-compatible voice list endpoint"""
    # OpenWebUI expects a simple array of voice IDs
    voice_ids = sorted([k for k in AVAILABLE_VOICES.keys() if '-' not in k])
    return voice_ids

def _guess_gender(name):
    """Guess gender from voice name"""
    male_names = ['ryan', 'joe', 'alan', 'john', 'danny']
    female_names = ['lessac', 'amy', 'alba', 'jenny', 'sara']
    name_lower = name.lower()
    if any(m in name_lower for m in male_names):
        return "male"
    elif any(f in name_lower for f in female_names):
        return "female"
    return "neutral"

def _guess_accent(full_name):
    """Extract accent from full voice name"""
    if 'en_GB' in full_name:
        return "British"
    elif 'en_US' in full_name:
        return "American"
    elif 'en_AU' in full_name:
        return "Australian"
    return "English"

@app.post("/v1/audio/speech")
async def create_speech(request: TTSRequest):
    """Generate speech - fast and simple"""
    
    if not request.input.strip():
        raise HTTPException(status_code=400, detail="Input required")
    
    # Select voice model
    voice_key = request.voice.lower()
    if voice_key not in AVAILABLE_VOICES:
        raise HTTPException(
            status_code=400,
            detail=f"Voice '{request.voice}' not found. Available: {list(set([k for k in AVAILABLE_VOICES.keys() if '-' not in k]))}"
        )
    
    voice_model = AVAILABLE_VOICES[voice_key]
    
    try:
        # Run Piper TTS with file output (proper WAV headers)
        output_file = f"/tmp/tts_{hash(request.input)}_{voice_key}.wav"
        process = await asyncio.create_subprocess_exec(
            str(PIPER_BINARY),
            "-m", str(voice_model),
            "-f", output_file,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE  # Capture errors
        )
        
        # Send input text and wait for completion (with timeout)
        stdout, stderr = await asyncio.wait_for(
            process.communicate(request.input.encode('utf-8')),
            timeout=30.0
        )
        
        # Check for errors
        if process.returncode != 0:
            error_msg = stderr.decode('utf-8') if stderr else "Unknown error"
            raise HTTPException(status_code=500, detail=f"Piper failed: {error_msg}")
        
        # Wait a bit for file to be fully written
        await asyncio.sleep(0.1)
        
        # Verify file exists
        if not os.path.exists(output_file):
            raise HTTPException(status_code=500, detail=f"Output file not created: {output_file}")
        
        # Read generated WAV file
        with open(output_file, 'rb') as f:
            audio_data = f.read()
        
        # Verify we got data
        if len(audio_data) < 1000:
            raise HTTPException(status_code=500, detail=f"Audio file too small: {len(audio_data)} bytes")
        
        # Clean up temp file
        try:
            os.unlink(output_file)
        except:
            pass  # Don't fail if cleanup fails
        
        # Return WAV audio data
        return Response(content=audio_data, media_type="audio/wav")
    
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail="TTS timeout")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "piper": PIPER_BINARY.exists(),
        "voices": len(AVAILABLE_VOICES),
        "available_voices": sorted(set([k for k in AVAILABLE_VOICES.keys() if '-' not in k]))
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5002, log_level="warning")
