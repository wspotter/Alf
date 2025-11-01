#!/usr/bin/env python3
"""
Coqui TTS Voice Cloning Demo
Demonstrates voice cloning with XTTS-v2
"""

import os
import sys
from TTS.api import TTS

def demo_voice_cloning():
    """Quick demo of voice cloning"""
    print("=" * 70)
    print("🎙️  COQUI TTS VOICE CLONING DEMO")
    print("=" * 70)
    print()
    
    # Demo 1: Basic TTS (no cloning) - use simple VITS model
    print("🔊 Demo 1: Basic Text-to-Speech")
    print("-" * 70)
    print("📦 Loading LJSpeech VITS model (fast, good quality)...")
    tts_basic = TTS("tts_models/en/ljspeech/vits")
    print("✓ Model loaded!")
    print()
    
    text1 = "Hello! This is Coqui TTS generating speech with a high-quality voice."
    output1 = "/tmp/coqui_demo_basic.wav"
    
    print(f"Text: {text1}")
    print(f"Generating audio... ", end="", flush=True)
    
    tts_basic.tts_to_file(
        text=text1,
        file_path=output1
    )
    
    print(f"✓ Saved to: {output1}")
    print()
    
    # Demo 2: Voice cloning instructions
    print("🎭 Demo 2: Voice Cloning (XTTS-v2)")
    print("-" * 70)
    print("📦 Loading XTTS-v2 model (voice cloning support)...")
    tts_xtts = TTS("tts_models/multilingual/multi-dataset/xtts_v2")
    print("✓ Model loaded!")
    print()
    
    print("Voice cloning requires a reference audio sample.")
    print("To clone a voice, you need:")
    print("  1. A 5-10 second audio sample (WAV format, clear speech)")
    print("  2. The text you want to synthesize")
    print()
    print("Example command:")
    print("  python tts/demo_voice_cloning.py clone <reference_audio.wav> \"Text to speak\"")
    print()
    print("Or use the API:")
    print("  curl -X POST http://localhost:5002/v1/audio/clone \\")
    print("    -F 'text=Your text here' \\")
    print("    -F 'reference_audio=@voice_sample.wav' \\")
    print("    -F 'model=tts-1-hd' \\")
    print("    --output cloned_speech.wav")
    print()
    
    # Demo 3: Multi-language capability
    print("🌍 Demo 3: Multi-Language Support (XTTS-v2)")
    print("-" * 70)
    print("XTTS-v2 supports multiple languages:")
    print("  - English, Spanish, French, German, Italian")
    print("  - Portuguese, Polish, Turkish, Russian, Dutch")
    print("  - Czech, Arabic, Chinese, Japanese, Hungarian, Korean")
    print()
    print("Note: Multi-language with XTTS requires a speaker reference.")
    print("Using your test voice sample from earlier...")
    
    # Check if we have the test audio from earlier
    test_audio = "/tmp/coqui_test.wav"
    if os.path.exists(test_audio):
        text_spanish = "Hola, este es Coqui TTS hablando en español."
        output_spanish = "/tmp/coqui_demo_spanish.wav"
        
        print()
        print(f"Text (Spanish): {text_spanish}")
        print(f"Reference: {test_audio}")
        print(f"Generating audio... ", end="", flush=True)
        
        tts_xtts.tts_to_file(
            text=text_spanish,
            file_path=output_spanish,
            speaker_wav=test_audio,
            language="es"
        )
        
        print(f"✓ Saved to: {output_spanish}")
        print()
    else:
        print()
        print("(Skipping multi-language demo - no reference audio available)")
        print("Create a reference audio first with:")
        print("  tts --text 'Test' --model_name 'tts_models/en/ljspeech/vits' --out_path /tmp/ref.wav")
        print()
    
    # Summary
    print("=" * 70)
    print("✅ DEMO COMPLETE!")
    print("=" * 70)
    print()
    print("Generated files:")
    print(f"  - {output1} (English, LJSpeech VITS)")
    if os.path.exists("/tmp/coqui_demo_spanish.wav"):
        print(f"  - /tmp/coqui_demo_spanish.wav (Spanish with XTTS-v2)")
    print()
    print("Next steps:")
    print("  1. Play the generated audio files")
    print("  2. Try voice cloning with your own audio sample")
    print("  3. Read docs/VOICE_CLONING_GUIDE.md for detailed instructions")
    print()
    print("Documentation:")
    print("  - Setup: docs/COQUI_TTS_SETUP.md")
    print("  - Voice Cloning: docs/VOICE_CLONING_GUIDE.md")
    print()


def clone_voice(reference_audio, text):
    """Clone voice from reference audio"""
    if not os.path.exists(reference_audio):
        print(f"❌ Error: Reference audio not found: {reference_audio}")
        sys.exit(1)
    
    print("=" * 70)
    print("🎭 VOICE CLONING")
    print("=" * 70)
    print()
    print(f"Reference audio: {reference_audio}")
    print(f"Text to synthesize: {text}")
    print()
    
    # Load model
    print("📦 Loading XTTS-v2 model...")
    tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2")
    print("✓ Model loaded!")
    print()
    
    # Generate cloned speech
    output_path = "/tmp/cloned_voice.wav"
    print(f"🔊 Generating cloned speech... ", end="", flush=True)
    
    tts.tts_to_file(
        text=text,
        file_path=output_path,
        speaker_wav=reference_audio,
        language="en"
    )
    
    print(f"✓ Done!")
    print()
    print(f"✅ Cloned speech saved to: {output_path}")
    print()
    print("Play the audio to hear the result!")
    print()


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "clone":
        if len(sys.argv) < 4:
            print("Usage: python demo_voice_cloning.py clone <reference_audio.wav> \"Text to speak\"")
            sys.exit(1)
        
        reference_audio = sys.argv[2]
        text = sys.argv[3]
        clone_voice(reference_audio, text)
    else:
        demo_voice_cloning()
