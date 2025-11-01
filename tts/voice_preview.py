#!/usr/bin/env python3
"""
Voice Preview Tool - Test all Piper voices
"""

import requests
import os
import subprocess
from pathlib import Path

API_URL = "http://localhost:5002"
TEST_TEXT = "Hello! I'm an AI assistant. It's great to meet you. How can I help you today?"

def preview_voices():
    """Generate preview audio for all available voices"""
    
    print("🎙️  Piper TTS Voice Preview Tool\n")
    
    # Get available voices
    try:
        response = requests.get(f"{API_URL}/v1/voices")
        voices = response.json()["voices"]
    except Exception as e:
        print(f"❌ Error connecting to API: {e}")
        print(f"Make sure the server is running on {API_URL}")
        return
    
    print(f"Found {len(voices)} voices:\n")
    
    # Create preview directory
    preview_dir = Path("/tmp/voice_previews")
    preview_dir.mkdir(exist_ok=True)
    
    for i, voice in enumerate(voices, 1):
        voice_id = voice['id']
        voice_name = voice['name']
        gender = voice['gender']
        accent = voice['accent']
        
        print(f"{i}. {voice_id:12} | {gender:7} | {accent:10} | {voice_name}")
        
        # Generate preview
        try:
            response = requests.post(
                f"{API_URL}/v1/audio/speech",
                json={"input": TEST_TEXT, "voice": voice_id},
                timeout=10
            )
            
            if response.status_code == 200:
                # Save preview file
                preview_file = preview_dir / f"{voice_id}.wav"
                with open(preview_file, 'wb') as f:
                    f.write(response.content)
                print(f"   ✓ Preview saved: {preview_file}")
            else:
                print(f"   ✗ Error: {response.status_code}")
        except Exception as e:
            print(f"   ✗ Failed: {e}")
    
    print(f"\n📁 All previews saved to: {preview_dir}")
    print(f"\n🔊 To play a voice:")
    print(f"   ffplay /tmp/voice_previews/ryan.wav")
    print(f"\n📋 Voice Selection Guide:")
    print(f"   • Male American: ryan, joe")
    print(f"   • Female American: lessac, amy")
    print(f"   • Male British: alan")
    print(f"   • Female British: alba")

def interactive_test():
    """Interactive voice testing"""
    print("\n🎤 Interactive Voice Test")
    print("Type text and select a voice to hear it.\n")
    
    # Get voices
    response = requests.get(f"{API_URL}/v1/voices")
    voices = response.json()["voices"]
    voice_ids = [v['id'] for v in voices]
    
    print("Available voices:", ", ".join(voice_ids))
    print("Type 'quit' to exit\n")
    
    while True:
        text = input("Text to speak: ").strip()
        if text.lower() in ['quit', 'exit', 'q']:
            break
        
        if not text:
            continue
        
        voice = input(f"Voice ({voice_ids[0]}): ").strip() or voice_ids[0]
        
        if voice not in voice_ids:
            print(f"❌ Unknown voice. Available: {', '.join(voice_ids)}")
            continue
        
        # Generate speech
        response = requests.post(
            f"{API_URL}/v1/audio/speech",
            json={"input": text, "voice": voice}
        )
        
        if response.status_code == 200:
            # Save and play
            temp_file = "/tmp/test_voice.wav"
            with open(temp_file, 'wb') as f:
                f.write(response.content)
            
            print(f"🔊 Playing with {voice} voice...")
            subprocess.run(["ffplay", "-nodisp", "-autoexit", temp_file], 
                         stderr=subprocess.DEVNULL)
        else:
            print(f"❌ Error: {response.status_code}")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "interactive":
        interactive_test()
    else:
        preview_voices()
        
        # Ask if user wants interactive mode
        print("\n" + "="*60)
        response = input("\nTry interactive mode? (y/n): ").strip().lower()
        if response == 'y':
            interactive_test()
