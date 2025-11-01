#!/usr/bin/env python3
"""
Fetch and optionally pre-download Coqui TTS English models to the local cache.

Usage:
  python tts/fetch_coqui_voices.py --list            # list available English models
  python tts/fetch_coqui_voices.py --download top    # download curated top English models
  python tts/fetch_coqui_voices.py --download all    # download all English models (large)

Notes:
  - Uses Coqui TTS model registry via TTS().list_models()
  - Filters for English models by simple heuristics ("/en/" in model id)
  - Pre-download by running a tiny synth to force cache population
"""
import argparse
import sys
from pathlib import Path

from TTS.api import TTS

CURATED = [
    # Fast, stable single-speaker English
    "tts_models/en/ljspeech/tacotron2-DDC",
    "tts_models/en/jenny/jenny",  # High-quality neural (already downloaded)
    "tts_models/en/ljspeech/glow-tts",
    "tts_models/en/ljspeech/neural_hmm",
]

# Skip models known to have config issues or require special params
SKIP_MODELS = [
    "tts_models/en/ljspeech/vits",  # IndexError in generate_path
    "tts_models/en/ljspeech/speedy-speech",  # Config deserialization errors
    "tts_models/en/ljspeech/overflow",  # Config issues
    "tts_models/en/vctk/vits",  # Requires speaker_idx
    "tts_models/multilingual/multi-dataset/xtts_v2",  # Requires language param, very large
    "tts_models/en/multi-dataset/tortoise-v2",  # Very slow, requires special setup
]

def list_english_models() -> list[str]:
    tts = TTS()
    models = tts.list_models()
    english = [m for m in models if "/en/" in m or m.endswith("xtts_v2")]
    return sorted(set(english))

def predownload(models: list[str]) -> None:
    print(f"Prefetching {len(models)} model(s) into cache...")
    success_count = 0
    skip_count = 0
    fail_count = 0
    
    for m in models:
        if m in SKIP_MODELS:
            print(f"  ⊘ {m} (skipped - known issues)")
            skip_count += 1
            continue
            
        try:
            print(f"  ↓ {m}...", end=" ", flush=True)
            import warnings
            with warnings.catch_warnings():
                warnings.filterwarnings("ignore", category=UserWarning)
                t = TTS(model_name=m, progress_bar=False)
                # Minimal warm-up: build vocoder and save a tiny wav to trigger cache
                t.tts_to_file(text="hello", file_path=str(Path("/tmp")/"coqui_warmup.wav"))
            print("✓")
            success_count += 1
        except Exception as e:
            print(f"✗ ({type(e).__name__})")
            fail_count += 1
    
    print(f"\nSummary: {success_count} succeeded, {skip_count} skipped, {fail_count} failed")

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--list", action="store_true", help="List English models")
    p.add_argument("--download", choices=["top", "all"], help="Download curated top or all English models")
    args = p.parse_args()

    if args.list:
        english = list_english_models()
        print("English-capable models:")
        for m in english:
            print(f"- {m}")
        return

    if args.download:
        if args.download == "top":
            print("Downloading curated stable models...")
            predownload(CURATED)
        else:
            print("Downloading all English models (this may take a while)...")
            all_models = list_english_models()
            predownload(all_models)
        print("Done.")
        return

    p.print_help()

if __name__ == "__main__":
    main()
