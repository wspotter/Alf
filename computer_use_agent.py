"""
Computer Use Agent for AlphaOmega
Simple, production-ready computer automation using pyautogui + LLaVA
"""
import os
import asyncio
import base64
from io import BytesIO
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from typing import Optional, List
import pyautogui
from PIL import Image
import httpx

# Initialize FastAPI app
app = FastAPI(title="AlphaOmega Computer Use Agent")

# Serve GUI
@app.get("/", response_class=HTMLResponse)
async def serve_gui():
    """Serve the web GUI"""
    try:
        with open("/home/stacy/AlphaOmega/computer_use_gui.html", "r") as f:
            return f.read()
    except FileNotFoundError:
        return "<h1>GUI not found</h1><p>Access API docs at <a href='/docs'>/docs</a></p>"

# Ollama configuration
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
VISION_MODEL = os.getenv("VISION_MODEL", "llava:13b")

# Safety configuration
SAFE_MODE = os.getenv("SAFE_MODE", "true").lower() == "true"

class ActionRequest(BaseModel):
    action: str  # "click", "type", "move", "scroll", "key"
    target: Optional[str] = None  # Description of target for vision-based actions
    text: Optional[str] = None  # Text to type
    x: Optional[int] = None  # Explicit coordinates
    y: Optional[int] = None
    key: Optional[str] = None  # Key to press

class ActionResponse(BaseModel):
    success: bool
    message: str
    screenshot: Optional[str] = None  # Base64 encoded screenshot


def capture_screenshot() -> Image.Image:
    """Capture current screen"""
    screenshot = pyautogui.screenshot()
    # Resize for faster vision processing
    screenshot.thumbnail((1280, 720), Image.Resampling.LANCZOS)
    return screenshot


def encode_image(image: Image.Image) -> str:
    """Encode image to base64"""
    buffered = BytesIO()
    image.save(buffered, format="PNG")
    return base64.b64encode(buffered.getvalue()).decode()


async def analyze_screen_with_vision(prompt: str, image: Image.Image) -> dict:
    """Use LLaVA to analyze screenshot"""
    img_b64 = encode_image(image)
    
    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(
            f"{OLLAMA_URL}/api/generate",
            json={
                "model": VISION_MODEL,
                "prompt": prompt,
                "images": [img_b64],
                "stream": False
            }
        )
        return response.json()


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "computer-use-agent"}


@app.get("/screenshot")
async def get_screenshot():
    """Capture and return current screenshot"""
    screenshot = capture_screenshot()
    return {
        "screenshot": encode_image(screenshot),
        "width": screenshot.width,
        "height": screenshot.height
    }


@app.post("/action", response_model=ActionResponse)
async def execute_action(request: ActionRequest):
    """Execute computer use action"""
    try:
        screenshot = capture_screenshot()
        
        if request.action == "click":
            if request.x and request.y:
                # Explicit coordinates
                pyautogui.click(request.x, request.y)
                message = f"Clicked at ({request.x}, {request.y})"
            elif request.target:
                # Vision-based click
                prompt = f"Locate the {request.target} on screen. Return only the x,y coordinates as 'x,y'"
                result = await analyze_screen_with_vision(prompt, screenshot)
                # Parse coordinates from vision model response
                # This is simplified - production would need better parsing
                message = f"Vision-based click on {request.target}"
                # For now, require explicit coordinates
                raise HTTPException(400, "Vision-based clicking requires explicit coordinates for now")
            else:
                raise HTTPException(400, "Click requires either x,y coordinates or target description")
        
        elif request.action == "type":
            if not request.text:
                raise HTTPException(400, "Type action requires text")
            pyautogui.write(request.text, interval=0.05)
            message = f"Typed: {request.text}"
        
        elif request.action == "key":
            if not request.key:
                raise HTTPException(400, "Key action requires key parameter")
            pyautogui.press(request.key)
            message = f"Pressed key: {request.key}"
        
        elif request.action == "scroll":
            amount = request.y if request.y else -3
            pyautogui.scroll(amount)
            message = f"Scrolled {amount} clicks"
        
        elif request.action == "move":
            if not (request.x and request.y):
                raise HTTPException(400, "Move action requires x,y coordinates")
            pyautogui.moveTo(request.x, request.y, duration=0.5)
            message = f"Moved to ({request.x}, {request.y})"
        
        else:
            raise HTTPException(400, f"Unknown action: {request.action}")
        
        # Capture post-action screenshot
        post_screenshot = capture_screenshot()
        
        return ActionResponse(
            success=True,
            message=message,
            screenshot=encode_image(post_screenshot)
        )
    
    except Exception as e:
        return ActionResponse(
            success=False,
            message=f"Action failed: {str(e)}"
        )


@app.post("/analyze")
async def analyze_screen(prompt: str):
    """Analyze current screen with vision AI"""
    screenshot = capture_screenshot()
    result = await analyze_screen_with_vision(prompt, screenshot)
    return {
        "analysis": result.get("response", ""),
        "screenshot": encode_image(screenshot)
    }


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8001"))
    host = os.getenv("HOST", "0.0.0.0")
    uvicorn.run(app, host=host, port=port, log_level="info")
