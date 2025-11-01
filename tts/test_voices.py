#!/usr/bin/env python3
"""
Test different TTS voices and compare quality.
Generates sample audio files for each voice model.
"""
import sys
from pathlib import Path
from TTS.api import TTS

# Models to test
MODELS = {
    "jenny": "tts_models/en/jenny/jenny",
    "tacotron2": "tts_models/en/ljspeech/tacotron2-DDC",
    "glow": "tts_models/en/ljspeech/glow-tts",
    "neural_hmm": "tts_models/en/ljspeech/neural_hmm",
    "fast_pitch": "tts_models/en/ljspeech/fast_pitch",
}

TEST_TEXT = "Hello! This is a test of the text to speech system. How does this voice sound to you?"

def test_voice(name: str, model: str):
    """Generate speech with a specific model."""
    output_path = f"/tmp/tts_test_{name}.wav"
    
    try:
        print(f"Testing {name}...", end=" ", flush=True)
        tts = TTS(model, progress_bar=False)
        tts.tts_to_file(text=TEST_TEXT, file_path=output_path)
        print(f"✓ Saved to {output_path}")
        return True
    except Exception as e:
        print(f"✗ Failed: {e}")
        return False

def main():
    print("Testing TTS voices...\n")
    
    successful = []
    for name, model in MODELS.items():
        if test_voice(name, model):
            successful.append(name)
    
    print(f"\n✅ Successfully generated {len(successful)}/{len(MODELS)} test files")
    
    if successful:
        print("\nPlay them with:")
        for name in successful:
            print(f"  aplay /tmp/tts_test_{name}.wav")
        print("\nOr play all:")
        print(f"  aplay /tmp/tts_test_*.wav")

if __name__ == "__main__":
    main()
