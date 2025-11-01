#!/usr/bin/env python3
"""
Coqui TTS OpenAI-Compatible API Server
Provides OpenAI /v1/audio/speech compatible endpoint for OpenWebUI
Supports voice cloning via reference audio
"""

import io
import os
import base64
import hashlib
import logging
from pathlib import Path
from typing import Optional, List
import tempfile

from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel
import uvicorn

from TTS.api import TTS

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(
    title="Coqui TTS API",
    description="OpenAI-compatible TTS API with voice cloning",
    version="1.0.0"
)

# Configuration
CONFIG = {
    # Use jenny for best quality - 48kHz high-fidelity neural voice with natural prosody
    "default_model": "tts_models/en/jenny/jenny",
    # Fallback to tacotron2-DDC (very stable, good quality)
    "fallback_model": "tts_models/en/ljspeech/tacotron2-DDC",
    "xtts_model": "tts_models/multilingual/multi-dataset/xtts_v2",  # For voice cloning
    # Prefer CPU unless CUDA is explicitly available; ROCm setups generally use CPU here
    "gpu_device": "cuda:0" if os.getenv("CUDA_VISIBLE_DEVICES") else "cpu",
    "cache_dir": Path.home() / ".cache" / "coqui_tts",
    "speaker_samples_dir": Path("/tmp/coqui_speakers"),
}

# Ensure cache directories exist
CONFIG["cache_dir"].mkdir(parents=True, exist_ok=True)
CONFIG["speaker_samples_dir"].mkdir(parents=True, exist_ok=True)

# Initialize TTS models (lazy loading)
_tts_models = {}

def get_tts_model(model_name: str) -> TTS:
    """Get or create TTS model instance"""
    if model_name not in _tts_models:
        logger.info(f"Loading TTS model: {model_name}")
        try:
            _tts_models[model_name] = TTS(model_name=model_name)
            # Try to use GPU if available
            if CONFIG["gpu_device"] != "cpu":
                _tts_models[model_name].to(CONFIG["gpu_device"])
        except Exception as e:
            logger.error(f"Failed to load model {model_name}: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to load model: {str(e)}")
    return _tts_models[model_name]


class TTSRequest(BaseModel):
    """OpenAI-compatible TTS request"""
    model: str = "tts-1"
    input: str
    voice: str = "alloy"
    response_format: str = "wav"
    speed: float = 1.0


class VoiceInfo(BaseModel):
    """Voice information"""
    id: str
    name: str
    description: str


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "Coqui TTS API",
        "version": "1.0.0",
        "models": list(_tts_models.keys()) or ["none loaded yet"]
    }


@app.get("/v1/models")
async def list_models():
    """List available TTS models (OpenAI compatible)"""
    # Get actual TTS models from Coqui
    try:
        tts = TTS()
        model_list = tts.list_models()
        
        # Format as OpenAI-compatible response
        models = [
            {
                "id": model,
                "object": "model",
                "created": 0,
                "owned_by": "coqui-ai",
            }
            for model in model_list[:50]  # Limit to first 50 for performance
        ]
        
        # Add shortcuts
        models.insert(0, {
            "id": "tts-1-hd",
            "object": "model",
            "created": 0,
            "owned_by": "coqui-ai",
            "description": "XTTS-v2 with voice cloning"
        })
        models.insert(0, {
            "id": "tts-1",
            "object": "model",
            "created": 0,
            "owned_by": "coqui-ai",
            "description": "LJSpeech VITS (fast, good quality)"
        })
        
        return {"object": "list", "data": models}
    except Exception as e:
        logger.error(f"Failed to list models: {e}")
        return {"object": "list", "data": []}


@app.get("/v1/audio/voices")
async def list_voices():
    """List available voices (detailed)"""
    voices = [
        VoiceInfo(id="ljspeech", name="LJSpeech", description="Female English voice (fast)"),
        VoiceInfo(id="vctk", name="VCTK", description="Multi-speaker English dataset"),
        VoiceInfo(id="jenny", name="Jenny", description="High-quality female voice"),
        VoiceInfo(id="custom", name="Custom", description="Upload your own voice sample"),
    ]
    return {"voices": [v.dict() for v in voices]}

@app.get("/v1/voices")
async def list_voices_simple():
    """OpenAI-compatible simple list of voices"""
    return {"voices": [
        {"id": "ljspeech", "name": "LJSpeech", "description": "Female English voice (fast)"},
        {"id": "vctk", "name": "VCTK", "description": "Multi-speaker English dataset"},
        {"id": "jenny", "name": "Jenny", "description": "High-quality female voice"},
        {"id": "custom", "name": "Custom", "description": "Upload your own voice sample"},
    ]}


@app.post("/v1/audio/speech")
async def create_speech(request: TTSRequest):
    """
    Generate speech from text (OpenAI compatible)
    
    Supports:
    - model: "tts-1" (fast), "tts-1-hd" (XTTS with cloning)
    - voice: Voice ID or path to speaker WAV file
    - response_format: "mp3", "opus", "aac", "flac", "wav", "pcm"
    """
    try:
        logger.info(f"TTS request: model={request.model}, voice={request.voice}, text length={len(request.input)}")
        
        # Map OpenAI-like model names and voice hints to specific Coqui models
        # Use jenny by default for best quality (48kHz high-fidelity)
        if request.voice and request.voice.lower() in ("vctk", "multi", "multispeaker"):
            coqui_model = "tts_models/en/vctk/vits"
        elif request.model in ("tts-1-hd", "hd"):
            # High-quality request - use jenny (48kHz)
            coqui_model = "tts_models/en/jenny/jenny"
        else:
            # Default to jenny for smooth, high-quality audio
            coqui_model = CONFIG["default_model"]
        
        logger.info(f"Mapped model: {request.model} -> {coqui_model}")
        
        # Get TTS model
        tts = get_tts_model(coqui_model)
        
        # Generate audio with retry/fallback to improve robustness
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
            output_path = tmp_file.name

            def synthesize(model_name: str) -> None:
                _tts = get_tts_model(model_name)
                is_xtts = "xtts" in model_name.lower()
                speaker_wav = None
                if request.voice and os.path.exists(request.voice):
                    speaker_wav = request.voice
                    logger.info(f"Using voice cloning with: {speaker_wav}")
                if is_xtts:
                    _tts.tts_to_file(
                        text=request.input,
                        file_path=output_path,
                        speaker_wav=speaker_wav,
                        language="en"
                    )
                else:
                    # For multi-speaker English models, pick a default speaker if needed
                    kwargs = {}
                    if "vctk" in model_name.lower():
                        kwargs["speaker"] = "p225"  # common female speaker in VCTK
                    _tts.tts_to_file(text=request.input, file_path=output_path, **kwargs)

            try:
                synthesize(coqui_model)
            except Exception as e:
                logger.warning(f"Primary model failed ({coqui_model}): {e}. Trying fallback {CONFIG['fallback_model']}...")
                # Clean partial output if any
                try:
                    if os.path.exists(output_path):
                        os.unlink(output_path)
                except Exception:
                    pass
                synthesize(CONFIG["fallback_model"])
        
        # Read generated audio
        with open(output_path, "rb") as f:
            audio_data = f.read()
        
        # Clean up temp file
        os.unlink(output_path)
        
        # Return audio (convert to requested format if needed)
        media_type = {
            "mp3": "audio/mpeg",
            "opus": "audio/opus",
            "aac": "audio/aac",
            "flac": "audio/flac",
            "wav": "audio/wav",
            "pcm": "audio/pcm",
        }.get(request.response_format, "audio/wav")
        
        return StreamingResponse(
            io.BytesIO(audio_data),
            media_type=media_type,
            headers={
                "Content-Disposition": f"attachment; filename=speech.{request.response_format}"
            }
        )
        
    except Exception as e:
        logger.error(f"TTS generation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/v1/audio/clone")
async def clone_voice(
    text: str = Form(...),
    reference_audio: UploadFile = File(...),
    model: str = Form("tts-1-hd"),
):
    """
    Voice cloning endpoint
    Upload reference audio and generate speech in that voice
    """
    try:
        logger.info(f"Voice cloning request: text length={len(text)}, audio={reference_audio.filename}")
        
        # Save uploaded audio
        speaker_id = hashlib.md5(reference_audio.filename.encode()).hexdigest()[:8]
        speaker_path = CONFIG["speaker_samples_dir"] / f"speaker_{speaker_id}.wav"
        
        with open(speaker_path, "wb") as f:
            f.write(await reference_audio.read())
        
        logger.info(f"Saved speaker audio to: {speaker_path}")
        
        # Use XTTS for voice cloning
        tts = get_tts_model(CONFIG["xtts_model"])
        
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
            output_path = tmp_file.name
            
            tts.tts_to_file(
                text=text,
                file_path=output_path,
                speaker_wav=str(speaker_path),
                language="en"
            )
        
        # Read and return audio
        with open(output_path, "rb") as f:
            audio_data = f.read()
        
        os.unlink(output_path)
        
        return StreamingResponse(
            io.BytesIO(audio_data),
            media_type="audio/wav",
            headers={
                "Content-Disposition": "attachment; filename=cloned_speech.wav",
                "X-Speaker-ID": speaker_id,
            }
        )
        
    except Exception as e:
        logger.error(f"Voice cloning failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "models_loaded": len(_tts_models),
        "gpu_available": CONFIG["gpu_device"] != "cpu",
    }


if __name__ == "__main__":
    # Configuration
    host = os.getenv("TTS_HOST", "0.0.0.0")
    port = int(os.getenv("TTS_PORT", "5002"))
    
    logger.info(f"Starting Coqui TTS API server on {host}:{port}")
    logger.info(f"GPU device: {CONFIG['gpu_device']}")
    logger.info(f"Default model: {CONFIG['default_model']}")
    
    uvicorn.run(app, host=host, port=port, log_level="info")
