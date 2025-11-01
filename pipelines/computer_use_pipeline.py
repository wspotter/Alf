"""
Computer Use Tools for OpenWebUI
Enables AI to control the computer through chat
"""
from typing import List, Optional, Dict, Any
import httpx
import json
import os

class Tools:
    """Computer Use Agent Tools for OpenWebUI"""
    
    def __init__(self):
        self.name = "Computer Use Agent"
        self.agent_url = os.getenv("COMPUTER_USE_AGENT_URL", "http://localhost:8001")
        
    async def on_startup(self):
        """Called when the pipeline starts"""
        print(f"Computer Use Agent Pipeline initialized")
        print(f"Agent URL: {self.agent_url}")
        
    async def on_shutdown(self):
        """Called when the tools stop"""
        print("Computer Use Agent Tools stopped")
        
    def get_tools(self) -> List[Dict[str, Any]]:
        """Register computer use tools for OpenWebUI"""
        return [
            {
                "name": "click_at_position",
                "description": "Click the mouse at specific X,Y coordinates on the screen",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "x": {
                            "type": "integer",
                            "description": "X coordinate (horizontal position)"
                        },
                        "y": {
                            "type": "integer",
                            "description": "Y coordinate (vertical position)"
                        }
                    },
                    "required": ["x", "y"]
                }
            },
            {
                "name": "type_text",
                "description": "Type text on the keyboard as if a human were typing",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "text": {
                            "type": "string",
                            "description": "The text to type"
                        }
                    },
                    "required": ["text"]
                }
            },
            {
                "name": "press_key",
                "description": "Press a keyboard key (enter, tab, space, backspace, delete, escape, arrow keys, etc.)",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "key": {
                            "type": "string",
                            "description": "The key to press",
                            "enum": ["enter", "tab", "space", "backspace", "delete", "escape", 
                                   "up", "down", "left", "right", "home", "end", "pageup", "pagedown"]
                        }
                    },
                    "required": ["key"]
                }
            },
            {
                "name": "scroll_page",
                "description": "Scroll the page or window up or down",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "direction": {
                            "type": "string",
                            "description": "Direction to scroll",
                            "enum": ["up", "down"]
                        },
                        "amount": {
                            "type": "integer",
                            "description": "Number of scroll clicks (default 3)",
                            "default": 3
                        }
                    },
                    "required": ["direction"]
                }
            },
            {
                "name": "move_mouse",
                "description": "Move the mouse cursor to specific coordinates",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "x": {
                            "type": "integer",
                            "description": "X coordinate"
                        },
                        "y": {
                            "type": "integer",
                            "description": "Y coordinate"
                        }
                    },
                    "required": ["x", "y"]
                }
            },
            {
                "name": "capture_screenshot",
                "description": "Take a screenshot of the current screen and return it as base64 image",
                "parameters": {
                    "type": "object",
                    "properties": {}
                }
            },
            {
                "name": "analyze_screen",
                "description": "Use AI vision (LLaVA) to analyze what's currently on the screen",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "question": {
                            "type": "string",
                            "description": "What to analyze or ask about the screen"
                        }
                    },
                    "required": ["question"]
                }
            }
        ]
    
    async def execute_tool(self, tool_name: str, tool_input: Dict[str, Any]) -> str:
        """Execute a computer use tool"""
        parameters = tool_input
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                
                if tool_name == "click_at_position":
                    response = await client.post(
                        f"{self.agent_url}/action",
                        json={"action": "click", "x": parameters["x"], "y": parameters["y"]}
                    )
                    data = response.json()
                    return f"✅ Clicked at ({parameters['x']}, {parameters['y']})"
                
                elif tool_name == "type_text":
                    response = await client.post(
                        f"{self.agent_url}/action",
                        json={"action": "type", "text": parameters["text"]}
                    )
                    data = response.json()
                    return f"✅ Typed: {parameters['text']}"
                
                elif tool_name == "press_key":
                    response = await client.post(
                        f"{self.agent_url}/action",
                        json={"action": "key", "key": parameters["key"]}
                    )
                    data = response.json()
                    return f"✅ Pressed key: {parameters['key']}"
                
                elif tool_name == "scroll_page":
                    amount = parameters.get("amount", 3)
                    if parameters["direction"] == "up":
                        amount = -amount
                    response = await client.post(
                        f"{self.agent_url}/action",
                        json={"action": "scroll", "y": amount}
                    )
                    data = response.json()
                    return f"✅ Scrolled {parameters['direction']}"
                
                elif tool_name == "move_mouse":
                    response = await client.post(
                        f"{self.agent_url}/action",
                        json={"action": "move", "x": parameters["x"], "y": parameters["y"]}
                    )
                    data = response.json()
                    return f"✅ Moved mouse to ({parameters['x']}, {parameters['y']})"
                
                elif tool_name == "capture_screenshot":
                    response = await client.get(f"{self.agent_url}/screenshot")
                    data = response.json()
                    return f"📸 Screenshot captured ({data['width']}x{data['height']})\n\nBase64 data available in response."
                
                elif tool_name == "analyze_screen":
                    response = await client.post(
                        f"{self.agent_url}/analyze",
                        params={"prompt": parameters["question"]}
                    )
                    data = response.json()
                    return f"🤖 AI Analysis:\n\n{data['analysis']}"
                
                else:
                    return f"❌ Unknown tool: {tool_name}"
                    
        except Exception as e:
            return f"❌ Error executing {tool_name}: {str(e)}"
