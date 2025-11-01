"""ComfyUI image generation tools for MCP server."""

import json
import time
import uuid
import requests
from pathlib import Path
from typing import Optional


class ComfyUIClient:
    """Client for ComfyUI HTTP API."""
    
    def __init__(self, host: str = "127.0.0.1", port: int = 8188):
        self.base_url = f"http://{host}:{port}"
        self.workflow_dir = Path("/home/stacy/AlphaOmega/workflows")
        self.output_dir = Path("/home/stacy/AlphaOmega/outputs/comfyui")
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def load_workflow(self, workflow_name: str = "text2img_sdxl.json") -> dict:
        """Load a ComfyUI workflow template."""
        workflow_path = self.workflow_dir / workflow_name
        if not workflow_path.exists():
            raise FileNotFoundError(f"Workflow not found: {workflow_path}")
        return json.loads(workflow_path.read_text())
    
    def update_workflow_params(
        self,
        workflow: dict,
        prompt: str,
        negative_prompt: str = "",
        width: int = 1024,
        height: int = 1024,
        steps: int = 20,
        cfg: float = 7.0
    ) -> dict:
        """Update workflow with generation parameters."""
        # Find and update nodes based on class_type
        for node_id, node in workflow.items():
            class_type = node.get("class_type", "")
            
            # Update positive prompt (CLIPTextEncode)
            if class_type == "CLIPTextEncode":
                meta_title = node.get("_meta", {}).get("title", "")
                if "positive" in meta_title.lower() or "prompt" in node_id.lower():
                    node["inputs"]["text"] = prompt
                elif "negative" in meta_title.lower():
                    node["inputs"]["text"] = negative_prompt
            
            # Update dimensions - support multiple latent image types
            elif class_type in ["EmptyLatentImage", "EmptySD3LatentImage"]:
                node["inputs"]["width"] = width
                node["inputs"]["height"] = height
            
            # Update sampler settings (KSampler)
            elif class_type == "KSampler":
                node["inputs"]["steps"] = steps
                node["inputs"]["cfg"] = cfg
                # Update seed to random
                import random
                node["inputs"]["seed"] = random.randint(0, 2**32 - 1)
        
        return workflow
    
    def queue_prompt(self, workflow: dict) -> str:
        """Queue a workflow for generation. Returns prompt_id."""
        client_id = str(uuid.uuid4())
        payload = {"prompt": workflow, "client_id": client_id}
        
        response = requests.post(f"{self.base_url}/prompt", json=payload)
        response.raise_for_status()
        
        return response.json()["prompt_id"]
    
    def wait_for_completion(self, prompt_id: str, timeout: int = 300) -> dict:
        """Wait for generation to complete. Returns history with outputs."""
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            response = requests.get(f"{self.base_url}/history/{prompt_id}")
            history = response.json()
            
            if prompt_id in history:
                prompt_info = history[prompt_id]
                if "outputs" in prompt_info:
                    return prompt_info
            
            time.sleep(2)
        
        raise TimeoutError(f"Generation timed out after {timeout}s")
    
    def get_image_path(self, history: dict) -> Optional[Path]:
        """Extract image path from generation history."""
        outputs = history.get("outputs", {})
        
        for node_output in outputs.values():
            if "images" in node_output:
                for img_info in node_output["images"]:
                    filename = img_info["filename"]
                    subfolder = img_info.get("subfolder", "")
                    
                    # Download from ComfyUI
                    params = {"filename": filename, "subfolder": subfolder, "type": "output"}
                    response = requests.get(f"{self.base_url}/view", params=params)
                    response.raise_for_status()
                    
                    # Save locally
                    output_path = self.output_dir / filename
                    output_path.write_bytes(response.content)
                    
                    return output_path
        
        return None
    
    def generate(
        self,
        prompt: str,
        negative_prompt: str = "blurry, low quality, distorted, deformed",
        width: int = 1024,
        height: int = 1024,
        steps: int = 20,
        cfg: float = 7.0,
        workflow_name: str = "qwen_text2img.json"
    ) -> Path:
        """
        Generate an image from text prompt.
        
        Args:
            prompt: Text description of desired image
            negative_prompt: Things to avoid
            width: Image width (multiple of 8)
            height: Image height (multiple of 8)
            steps: Sampling steps (higher = better quality, slower)
            cfg: Classifier-free guidance scale (7-12 typical)
            workflow_name: ComfyUI workflow file to use
        
        Returns:
            Path to generated image
        """
        # Load and customize workflow
        workflow = self.load_workflow(workflow_name)
        workflow = self.update_workflow_params(
            workflow, prompt, negative_prompt, width, height, steps, cfg
        )
        
        # Queue and wait
        prompt_id = self.queue_prompt(workflow)
        history = self.wait_for_completion(prompt_id)
        
        # Get image
        image_path = self.get_image_path(history)
        if not image_path:
            raise ValueError("No image found in generation output")
        
        return image_path


# MCP Tool Functions
def generate_image(
    prompt: str,
    size: str = "1024x1024",
    quality: str = "standard",
    style: str = "natural"
) -> dict:
    """
    Generate an image using ComfyUI (LOCAL - runs on your hardware).
    
    USE THIS TOOL WHEN:
    - User asks to "generate", "create", "draw", or "make" an image
    - Queries like: "generate a sunset", "create an illustration of..."
    - Image description provided
    
    DO NOT USE FOR:
    - Analyzing existing images (use vision models)
    - Editing photos (use img2img tools)
    - Checking if images exist in inventory
    
    Args:
        prompt: Detailed text description of desired image
        size: Image dimensions - "512x512", "1024x1024", "1024x1792", or "1792x1024"
        quality: "standard" (20 steps) or "hd" (30 steps, better quality but slower)
        style: "natural" (photorealistic) or "vivid" (artistic, stylized)
    
    Returns:
        JSON with image_path, prompt used, generation_time
    
    Example:
        generate_image(
            prompt="a serene mountain landscape at sunset, oil painting style",
            size="1024x1024",
            quality="hd"
        )
    """
    try:
        # Parse size
        size_map = {
            "512x512": (512, 512),
            "1024x1024": (1024, 1024),
            "1024x1792": (1024, 1792),
            "1792x1024": (1792, 1024),
        }
        width, height = size_map.get(size, (1024, 1024))
        
        # Map quality to steps
        steps = 30 if quality == "hd" else 20
        
        # Adjust prompt based on style
        if style == "vivid":
            prompt = f"{prompt}, vibrant colors, artistic, stylized"
        elif style == "natural":
            prompt = f"{prompt}, photorealistic, natural lighting"
        
        # Generate
        client = ComfyUIClient()
        start_time = time.time()
        
        image_path = client.generate(
            prompt=prompt,
            width=width,
            height=height,
            steps=steps
        )
        
        generation_time = time.time() - start_time
        
        return {
            "success": True,
            "image_path": str(image_path),
            "image_url": f"file://{image_path}",
            "prompt": prompt,
            "size": f"{width}x{height}",
            "quality": quality,
            "generation_time_seconds": round(generation_time, 2),
            "message": f"✅ Generated image in {round(generation_time, 1)}s: {image_path.name}"
        }
    
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "message": f"❌ Image generation failed: {str(e)}"
        }


def check_comfyui_status() -> dict:
    """
    Check if ComfyUI service is running and responsive (LOCAL).
    
    USE THIS TOOL WHEN:
    - User asks about ComfyUI health or status
    - Debugging image generation issues
    - Verifying ComfyUI is available before generating
    
    Returns:
        JSON with status, queue info, system stats
    """
    try:
        client = ComfyUIClient()
        
        # Check system stats
        response = requests.get(f"{client.base_url}/system_stats", timeout=5)
        stats = response.json()
        
        # Check queue
        queue_response = requests.get(f"{client.base_url}/queue", timeout=5)
        queue_info = queue_response.json()
        
        return {
            "success": True,
            "status": "running",
            "queue_pending": len(queue_info.get("queue_pending", [])),
            "queue_running": len(queue_info.get("queue_running", [])),
            "system": {
                "devices": stats.get("devices", []),
                "vram_total": stats.get("system", {}).get("vram", {}).get("total", 0),
                "vram_free": stats.get("system", {}).get("vram", {}).get("free", 0)
            },
            "message": "✅ ComfyUI is running and responsive"
        }
    
    except Exception as e:
        return {
            "success": False,
            "status": "not_responding",
            "error": str(e),
            "message": "❌ ComfyUI is not responding. Start it with: ./scripts/start-comfyui.sh"
        }


def list_comfyui_workflows() -> dict:
    """
    List available ComfyUI workflow templates (LOCAL).
    
    USE THIS TOOL WHEN:
    - User asks what types of images can be generated
    - Showing available generation styles/workflows
    - User wants to know ComfyUI capabilities
    
    Returns:
        JSON with list of available workflow files and their purposes
    """
    try:
        workflow_dir = Path("/home/stacy/AlphaOmega/workflows")
        
        if not workflow_dir.exists():
            return {
                "success": False,
                "workflows": [],
                "message": "⚠️ Workflows directory not found"
            }
        
        workflows = []
        for workflow_file in workflow_dir.glob("*.json"):
            # Try to extract workflow metadata
            try:
                workflow_data = json.loads(workflow_file.read_text())
                description = workflow_data.get("_meta", {}).get("description", "No description")
            except:
                description = "ComfyUI workflow"
            
            workflows.append({
                "name": workflow_file.name,
                "path": str(workflow_file),
                "description": description
            })
        
        return {
            "success": True,
            "workflows": workflows,
            "count": len(workflows),
            "message": f"✅ Found {len(workflows)} ComfyUI workflow(s)"
        }
    
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "message": f"❌ Failed to list workflows: {str(e)}"
        }


# Export tools
__all__ = [
    "generate_image",
    "check_comfyui_status",
    "list_comfyui_workflows",
    "ComfyUIClient"
]
