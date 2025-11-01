"""
AlphaOmega Pipeline Router for OpenWebUI
Routes requests intelligently to: Ollama (vision/reasoning/code), ComfyUI, Agent-S, MCP
"""
from typing import Optional, List, Dict, Any, AsyncGenerator
import json
import os
from pydantic import BaseModel, Field
import httpx
from datetime import datetime


class Pipeline:
    """Intelligent router for AlphaOmega multi-backend system"""
    
    class Valves(BaseModel):
        """Pipeline configuration - editable from OpenWebUI"""
        _OLLAMA_VISION_DEFAULT = os.getenv("OLLAMA_VISION_HOST", "http://localhost:11434")
        _OLLAMA_REASON_DEFAULT = os.getenv("OLLAMA_REASONING_HOST", _OLLAMA_VISION_DEFAULT)
        _COMFYUI_DEFAULT = os.getenv("COMFYUI_HOST", "http://localhost:8188")
        _AGENT_S_DEFAULT = os.getenv("AGENT_S_HOST", "http://localhost:8001")
    _MCP_DEFAULT = os.getenv("MCP_HOST", "http://localhost:8003")
        _VISION_MODEL_DEFAULT = os.getenv("VISION_MODEL", "devstral-vision")
        _REASONING_MODEL_DEFAULT = os.getenv("REASONING_MODEL", "llama3-8b")
        _CODE_MODEL_DEFAULT = os.getenv("CODE_MODEL", "phind-codellama")

        OLLAMA_VISION_HOST: str = Field(
            default=_OLLAMA_VISION_DEFAULT,
            description="Ollama endpoint (GPU1 MI50 - LLaVA, Mistral, CodeLlama)"
        )
        OLLAMA_REASONING_HOST: str = Field(
            default=_OLLAMA_REASON_DEFAULT,
            description="Ollama endpoint (same as vision - single instance)"
        )
        COMFYUI_HOST: str = Field(
            default=_COMFYUI_DEFAULT,
            description="ComfyUI endpoint (GPU2 MI50 - Image generation)"
        )
        AGENT_S_HOST: str = Field(
            default=_AGENT_S_DEFAULT,
            description="Agent-S endpoint (Computer use)"
        )
        MCP_HOST: str = Field(
            default=_MCP_DEFAULT,
            description="MCP server endpoint (Artifacts, memory, files)"
        )
        VISION_MODEL: str = Field(
            default=_VISION_MODEL_DEFAULT,
            description="Vision model for screen analysis"
        )
        REASONING_MODEL: str = Field(
            default=_REASONING_MODEL_DEFAULT,
            description="Reasoning model for planning"
        )
        CODE_MODEL: str = Field(
            default=_CODE_MODEL_DEFAULT,
            description="Code generation model"
        )
        ENABLE_LOGGING: bool = Field(
            default=True,
            description="Log routing decisions"
        )
    
    def __init__(self):
        self.name = "AlphaOmega Router"
        self.valves = self.Valves()
        self.id = "alphaomega_router"
        self.type = "manifold"
        
    def pipes(self) -> List[dict]:
        """Available backend options"""
        return [
            {"id": "vision", "name": f"Vision ({self.valves.VISION_MODEL})"},
            {"id": "reasoning", "name": f"Reasoning ({self.valves.REASONING_MODEL})"},
            {"id": "code", "name": f"Code ({self.valves.CODE_MODEL})"},
            {"id": "agent", "name": "Computer Use (Agent-S)"},
            {"id": "image", "name": "Image Generation (ComfyUI)"},
            {"id": "mcp", "name": "Tools (MCP)"},
        ]
    
    def _detect_intent(self, message: str) -> str:
        """Detect user intent from message content"""
        message_lower = message.lower()
        
        # MCP tool keywords (check FIRST before image keywords to avoid false positives)
        mcp_keywords = [
            # Artifacts & Memory
            "create artifact", "save artifact", "artifact",
            "save to memory", "remember this", "store this",
            # File operations
            "read file", "write file", "list files", "file operation",
            # Tasks
            "task", "todo", "to-do", "list tasks", "my tasks", "create task", "add task",
            # Inventory (check before 'paint' in image keywords)
            "inventory", "stock", "low stock", "check inventory", "in stock", "out of stock",
            # Customers
            "customer", "add customer", "list customers", "vip", "client", "show customers",
            # Notes
            "note", "notes", "search notes", "add note", "create note", "my notes",
            # Sales
            "sale", "sales", "revenue", "record sale", "sales report", "last month",
            # Expenses
            "expense", "expenses", "cost", "spending",
            # Business operations
            "invoice", "appointment", "calendar", "schedule", "meeting",
            # Social media
            "facebook", "instagram", "post to", "social media", "tweet"
        ]
        if any(kw in message_lower for kw in mcp_keywords):
            return "mcp"
        
        # Image generation keywords (check AFTER MCP to avoid conflicts)
        image_keywords = [
            "generate image", "create image", "draw a", "render a", "painting of",
            "picture of", "illustration of", "artwork of", "sdxl", "flux",
            "generate a photo", "make an image", "visualize this", "art of"
        ]
        if any(kw in message_lower for kw in image_keywords):
            return "image"
        
        # Computer use keywords
        computer_keywords = [
            "screenshot", "screen", "click", "type", "press",
            "open app", "close window", "launch", "mouse", "keyboard",
            "what's on my screen", "find window", "desktop",
            "what can you see on", "show me my", "take a picture of my screen"
        ]
        if any(kw in message_lower for kw in computer_keywords):
            return "agent"
        
        # Vision analysis keywords (but not computer use)
        vision_keywords = [
            "analyze this image", "what's in this image", "describe image",
            "look at this", "vision", "see this", "examine image"
        ]
        if any(kw in message_lower for kw in vision_keywords):
            return "vision"
        
        # Code generation keywords
        code_keywords = [
            "write code", "write a function", "write a script",
            "implement", "code for", "python code", "javascript",
            "create a class", "algorithm", "debug this code",
            "refactor", "optimize code"
        ]
        if any(kw in message_lower for kw in code_keywords):
            return "code"
        
        # Default to reasoning
        return "reasoning"
    
    async def pipe(
        self,
        body: Dict[str, Any],
        __user__: Optional[Dict[str, Any]] = None,
        __event_emitter__: Any = None
    ) -> AsyncGenerator[str, None]:
        """Main routing logic with streaming support"""
        
        try:
            # Extract message
            messages = body.get("messages", [])
            if not messages:
                yield "Error: No messages provided"
                return
            
            user_message = messages[-1].get("content", "")
            
            # Detect intent
            intent = self._detect_intent(user_message)
            
            # Log routing decision
            if self.valves.ENABLE_LOGGING:
                self._log_routing(intent, user_message, __user__)
            
            # Emit status
            if __event_emitter__:
                await __event_emitter__({
                    "type": "status",
                    "data": {
                        "description": f"Routing to {intent}...",
                        "done": False
                    }
                })
            
            # Route to appropriate backend
            if intent == "image":
                async for chunk in self._route_to_comfyui(user_message, messages, __event_emitter__):
                    yield chunk
            elif intent == "agent":
                async for chunk in self._route_to_agent_s(user_message, messages, __event_emitter__):
                    yield chunk
            elif intent == "mcp":
                async for chunk in self._route_to_mcp(user_message, messages, __event_emitter__):
                    yield chunk
            elif intent == "vision":
                async for chunk in self._route_to_ollama(
                    user_message, messages, self.valves.VISION_MODEL,
                    self.valves.OLLAMA_VISION_HOST, __event_emitter__
                ):
                    yield chunk
            elif intent == "code":
                async for chunk in self._route_to_ollama(
                    user_message, messages, self.valves.CODE_MODEL,
                    self.valves.OLLAMA_REASONING_HOST, __event_emitter__
                ):
                    yield chunk
            else:  # reasoning
                async for chunk in self._route_to_ollama(
                    user_message, messages, self.valves.REASONING_MODEL,
                    self.valves.OLLAMA_REASONING_HOST, __event_emitter__
                ):
                    yield chunk
                    
        except Exception as e:
            error_msg = f"Error in pipeline: {str(e)}"
            print(error_msg)
            yield error_msg
    
    async def _route_to_ollama(
        self,
        message: str,
        messages: List[Dict],
        model: str,
        host: str,
        event_emitter: Any = None
    ) -> AsyncGenerator[str, None]:
        """Route to Ollama for LLM inference with streaming"""
        
        try:
            async with httpx.AsyncClient(timeout=120.0) as client:
                response = await client.post(
                    f"{host}/api/chat",
                    json={
                        "model": model,
                        "messages": messages,
                        "stream": True
                    },
                    timeout=120.0
                )
                
                async for line in response.aiter_lines():
                    if line:
                        try:
                            data = json.loads(line)
                            if "message" in data:
                                content = data["message"].get("content", "")
                                if content:
                                    yield content
                        except json.JSONDecodeError:
                            continue
                            
        except Exception as e:
            yield f"\n\n[Error communicating with Ollama ({model}): {str(e)}]"
    
    async def _route_to_comfyui(
        self,
        message: str,
        messages: List[Dict],
        event_emitter: Any = None
    ) -> AsyncGenerator[str, None]:
        """Route to ComfyUI for image generation"""
        
        try:
            if event_emitter:
                await event_emitter({
                    "type": "status",
                    "data": {"description": "Generating image with ComfyUI...", "done": False}
                })
            
            prompt = self._extract_image_prompt(message)
            
            async with httpx.AsyncClient(timeout=180.0) as client:
                response = await client.post(
                    f"{self.valves.COMFYUI_HOST}/api/generate",
                    json={"prompt": prompt},
                    timeout=180.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    image_url = result.get("image_url", "")
                    
                    if image_url:
                        yield "✅ Image generated successfully!\n\n"
                        yield f"Prompt: {prompt}\n\n"
                        yield f"![Generated Image]({image_url})"
                    else:
                        yield "Image generated but URL not available."
                else:
                    yield f"ComfyUI error: {response.status_code}"
                    
        except httpx.ConnectError:
            yield "⚠️ ComfyUI service is not available. Please ensure ComfyUI is running."
        except Exception as e:
            yield f"Error generating image: {str(e)}"
    
    async def _route_to_agent_s(
        self,
        message: str,
        messages: List[Dict],
        event_emitter: Any = None
    ) -> AsyncGenerator[str, None]:
        """Route to Agent-S for computer use automation"""
        
        try:
            if event_emitter:
                await event_emitter({
                    "type": "status",
                    "data": {"description": "Executing computer use action...", "done": False}
                })
            
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    f"{self.valves.AGENT_S_HOST}/action",
                    json={
                        "prompt": message,
                        "messages": messages,
                        "safe_mode": True
                    },
                    timeout=60.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    
                    # Stream response
                    yield result.get("response", "Action completed")
                    
                    # Add screenshot if available
                    if "screenshot" in result and result["screenshot"]:
                        yield f"\n\n📸 Screenshot:\n![Screen]({result['screenshot']})"
                    
                    # Add actions taken
                    if "actions_taken" in result and result["actions_taken"]:
                        yield "\n\n**Actions taken:**\n"
                        for action in result["actions_taken"]:
                            yield f"- {action}\n"
                            
                elif response.status_code == 403:
                    yield "⚠️ Action blocked by safety validator."
                else:
                    yield f"Agent-S error: {response.status_code}"
                    
        except httpx.ConnectError:
            yield "⚠️ Agent-S service is not available. Please ensure Agent-S is running."
        except Exception as e:
            yield f"Error executing action: {str(e)}"
    
    async def _route_to_mcp(
        self,
        message: str,
        messages: List[Dict],
        event_emitter: Any = None
    ) -> AsyncGenerator[str, None]:
        """Route to MCP server for tool use"""
        
        try:
            # Detect which tool to call
            tool_name, params = self._detect_mcp_tool(message)
            
            if not tool_name:
                yield "I can help you with tasks, inventory, customers, notes, and more. What would you like to do?"
                return
            
            if event_emitter:
                await event_emitter({
                    "type": "status",
                    "data": {"description": f"Calling {tool_name}...", "done": False}
                })
            
            # Call MCP tool
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    f"{self.valves.MCP_HOST}/{tool_name}",
                    json=params,
                    headers={"Content-Type": "application/json"},
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    result = response.json()
                    
                    # Format response nicely
                    formatted = self._format_mcp_response(tool_name, result)
                    yield formatted
                    
                elif response.status_code == 422:
                    yield f"⚠️ Invalid parameters for {tool_name}: {response.text}"
                else:
                    yield f"⚠️ MCP error ({response.status_code}): {response.text}"
                    
        except httpx.ConnectError:
            yield "⚠️ MCP server is not available. Please ensure MCP server is running on port 8003."
        except Exception as e:
            yield f"Error executing MCP tool: {str(e)}"
    
    def _detect_mcp_tool(self, message: str) -> tuple:
        """Detect which MCP tool to call and extract parameters"""
        message_lower = message.lower()
        
        # Task management
        if "list task" in message_lower or "my task" in message_lower or "what task" in message_lower or "show task" in message_lower:
            return ("list_tasks", {})
        if "create task" in message_lower or "add task" in message_lower or "new task" in message_lower:
            # Extract task details (simple version)
            task_text = message.split("task")[-1].strip().strip(":").strip()
            return ("create_task", {
                "title": task_text,
                "priority": "medium"
            })
        
        # Inventory
        if "inventory" in message_lower or "stock" in message_lower:
            if "low stock" in message_lower:
                return ("get_low_stock_items", {})
            else:
                # Extract search term
                search = ""
                if "for" in message_lower:
                    search = message_lower.split("for")[-1].strip()
                return ("check_inventory", {"product_name": search} if search else {})
        
        # Customers
        if "customer" in message_lower or "client" in message_lower:
            if "list" in message_lower or "show" in message_lower or "all" in message_lower:
                return ("list_customers", {})
            elif "add" in message_lower:
                return ("add_customer", {})
            elif "vip" in message_lower:
                return ("list_customers", {})  # Can filter VIP in future
            
        # Notes
        if "create" in message_lower and "note" in message_lower:
            # Extract note content
            note_text = message_lower.split("note")[-1].strip().strip(":").strip()
            return ("create_note", {"title": "Note", "content": note_text})
        if "add" in message_lower and "note" in message_lower:
            note_text = message_lower.split("note")[-1].strip().strip(":").strip()
            return ("create_note", {"title": "Note", "content": note_text})
        if "note" in message_lower or "my note" in message_lower:
            if "search" in message_lower:
                query = message_lower.replace("search", "").replace("note", "").strip()
                return ("search_notes", {"query": query})
            else:
                return ("list_notes", {})
        
        # Sales
        if "sale" in message_lower or "sales" in message_lower or "revenue" in message_lower:
            if "report" in message_lower or "last" in message_lower or "month" in message_lower:
                return ("get_sales_report", {})
            elif "record" in message_lower or "add" in message_lower:
                return ("record_sale", {})
            else:
                return ("get_sales_report", {})
        
        # Expenses
        if "expense" in message_lower or "cost" in message_lower or "spending" in message_lower:
            if "list" in message_lower or "show" in message_lower:
                return ("list_expenses", {})
            elif "add" in message_lower:
                # Extract expense details
                expense_text = message_lower.split(":")[-1].strip() if ":" in message_lower else ""
                return ("add_expense", {"description": expense_text})
            else:
                return ("list_expenses", {})
        
        # Appointments/Calendar
        if "appointment" in message_lower or "schedule" in message_lower or "calendar" in message_lower or "meeting" in message_lower:
            if "list" in message_lower or "show" in message_lower or "my" in message_lower:
                return ("list_appointments", {})
            elif "add" in message_lower or "create" in message_lower or "schedule" in message_lower:
                return ("create_appointment", {})
            else:
                return ("list_appointments", {})
        
        # Social Media - Instagram
        if "instagram" in message_lower:
            if "post" in message_lower:
                content = message_lower.split(":")[-1].strip() if ":" in message_lower else ""
                return ("post_to_instagram", {"content": content})
            elif "message" in message_lower or "dm" in message_lower:
                return ("get_instagram_messages", {})
            elif "notification" in message_lower:
                return ("get_instagram_notifications", {})
            else:
                return ("get_instagram_notifications", {})
        
        # Social Media - Facebook
        if "facebook" in message_lower:
            if "post" in message_lower:
                content = message_lower.split(":")[-1].strip() if ":" in message_lower else ""
                return ("post_to_facebook", {"content": content})
            elif "message" in message_lower:
                return ("get_facebook_messages", {})
            else:
                return ("get_facebook_notifications", {})
        
        # Default - no specific tool matched
        return (None, {})
    
    def _format_mcp_response(self, tool_name: str, result: Any) -> str:
        """Format MCP tool responses for chat"""
        
        # Handle list results
        if isinstance(result, list):
            if not result:
                return f"No {tool_name.replace('_', ' ')} found."
            
            # Format tasks
            if tool_name == "list_tasks":
                lines = ["**Your Tasks:**\n"]
                for task in result:
                    priority = task.get("priority", "medium")
                    emoji = "🔴" if priority == "high" else "🟡" if priority == "medium" else "🟢"
                    status_emoji = "✅" if task.get("status") == "completed" else "⏳"
                    lines.append(f"{status_emoji} {emoji} **{task.get('title')}** - {task.get('description', '')}")
                return "\n".join(lines)
            
            # Format inventory
            elif tool_name == "check_inventory" or tool_name == "get_low_stock_items":
                lines = ["**Inventory:**\n"]
                for item in result:
                    stock = item.get("quantity", 0)
                    low_stock_icon = "⚠️" if stock < item.get("reorder_point", 10) else ""
                    lines.append(f"{low_stock_icon} **{item.get('name')}** - {stock} in stock")
                return "\n".join(lines)
            
            # Format customers
            elif tool_name == "list_customers":
                lines = ["**Customers:**\n"]
                for customer in result[:10]:  # Limit to 10
                    lines.append(f"• **{customer.get('name')}** - {customer.get('email', 'no email')}")
                if len(result) > 10:
                    lines.append(f"\n...and {len(result)-10} more")
                return "\n".join(lines)
            
            # Generic list formatting
            else:
                return json.dumps(result, indent=2)
        
        # Handle object results
        elif isinstance(result, dict):
            if "success" in result or "status" in result:
                return f"✅ {result.get('message', 'Operation completed successfully')}"
            return json.dumps(result, indent=2)
        
        # Handle string results
        return str(result)
    
    def _extract_image_prompt(self, message: str) -> str:
        """Extract clean prompt from image generation request"""
        prefixes = [
            "generate image of ", "create image of ", "draw ", "draw me ",
            "make a picture of ", "generate ", "create ", "render ",
            "make an image of ", "paint "
        ]
        
        prompt = message
        for prefix in prefixes:
            if prompt.lower().startswith(prefix):
                prompt = prompt[len(prefix):].strip()
                break
        
        return prompt
    
    def _log_routing(self, intent: str, message: str, user: Optional[Dict] = None):
        """Log routing decisions for debugging"""
        try:
            log_dir = "/app/backend/data/logs"
            os.makedirs(log_dir, exist_ok=True)
            
            log_entry = {
                "timestamp": datetime.now().isoformat(),
                "intent": intent,
                "message_preview": message[:100],
                "user": user.get("email", "unknown") if user else "unknown"
            }
            
            with open(f"{log_dir}/routing.log", "a") as f:
                f.write(json.dumps(log_entry) + "\n")
        except Exception:
            pass  # Don't fail on logging errors
