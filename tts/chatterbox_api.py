#!/usr/bin/env python3
"""
Chatterbox TTS API Server - OpenAI-compatible TTS endpoint
Uses Resemble AI's state-of-the-art Chatterbox model for natural, expressive speech.
"""
import io
import os
import logging
from pathlib import Path
from typing import Optional

import torchaudio as ta
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from chatterbox.tts import ChatterboxTTS

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(
    title="Chatterbox TTS API",
    description="OpenAI-compatible TTS API using Chatterbox",
    version="1.0.0"
)

# Global model instance (lazy loaded)
chatterbox_model: Optional[ChatterboxTTS] = None


def get_model() -> ChatterboxTTS:
    """Lazy load Chatterbox model."""
    global chatterbox_model
    if chatterbox_model is None:
        logger.info("Loading Chatterbox TTS model...")
        device = "cpu"  # Force CPU for now
        chatterbox_model = ChatterboxTTS.from_pretrained(device=device)
        logger.info(f"Chatterbox model loaded on {device}")
    return chatterbox_model


class TTSRequest(BaseModel):
    """OpenAI-compatible TTS request"""
    model: str = "tts-1"
    input: str
    voice: str = "alloy"
    response_format: str = "wav"
    speed: float = 1.0
    # Chatterbox-specific parameters
    exaggeration: float = 0.5  # 0.0-1.0, higher = more expressive
    cfg_weight: float = 0.5  # 0.0-1.0, guidance weight


@app.get("/")
async def root():
    return {
        "name": "Chatterbox TTS API",
        "version": "1.0.0",
        "model": "Chatterbox (ResembleAI)",
        "description": "State-of-the-art open source TTS with natural prosody"
    }


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy", "model_loaded": chatterbox_model is not None}


@app.post("/v1/audio/speech")
async def create_speech(request: TTSRequest):
    """
    Generate speech from text (OpenAI compatible)
    
    Supports:
    - model: "tts-1" (standard), "tts-1-hd" (high quality, more expressive)
    - voice: ignored for now (uses default Chatterbox voice)
    - response_format: "wav" (others not yet implemented)
    - exaggeration: 0.0-1.0 (Chatterbox-specific, default 0.5)
    - cfg_weight: 0.0-1.0 (Chatterbox-specific, default 0.5)
    """
    try:
        logger.info(f"TTS request: model={request.model}, text length={len(request.input)}")
        
        # Adjust parameters for HD model (more expressive)
        exaggeration = request.exaggeration
        cfg_weight = request.cfg_weight
        
        if request.model in ("tts-1-hd", "hd"):
            exaggeration = min(0.7, exaggeration * 1.4)  # More expressive
            cfg_weight = max(0.3, cfg_weight * 0.8)  # Slower, more deliberate
            logger.info(f"HD mode: exaggeration={exaggeration}, cfg_weight={cfg_weight}")
        
        # Get model
        model = get_model()
        
        # Generate audio
        logger.info(f"Generating speech with exaggeration={exaggeration}, cfg_weight={cfg_weight}")
        wav = model.generate(
            request.input,
            exaggeration=exaggeration,
            cfg_weight=cfg_weight
        )
        
        # Convert to bytes
        buffer = io.BytesIO()
        ta.save(buffer, wav, model.sr, format="wav")
        buffer.seek(0)
        audio_data = buffer.read()
        
        logger.info(f"Generated {len(audio_data)} bytes of audio")
        
        # Return audio
        return StreamingResponse(
            io.BytesIO(audio_data),
            media_type="audio/wav",
            headers={
                "Content-Disposition": f"attachment; filename=speech.{request.response_format}"
            }
        )
        
    except Exception as e:
        logger.error(f"TTS generation failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/v1/voices")
async def list_voices():
    """List available voices (for compatibility)"""
    return {
        "voices": [
            {
                "id": "chatterbox",
                "name": "Chatterbox",
                "description": "State-of-the-art neural voice with natural prosody"
            }
        ]
    }


if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("PORT", "5003"))
    host = os.getenv("HOST", "0.0.0.0")
    
    print("Starting Chatterbox API")
    logger.info(f"Starting Chatterbox TTS API on {host}:{port}")
    uvicorn.run(app, host=host, port=port, log_level="info")
