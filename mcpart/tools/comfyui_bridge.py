#!/usr/bin/env python3
"""
Python bridge for ComfyUI tools.
Called by TypeScript MCP server to execute ComfyUI operations.
"""

import sys
import json
from pathlib import Path

# Add tools directory to path
sys.path.insert(0, str(Path(__file__).parent))

from comfyui_tools import (
    generate_image,
    check_comfyui_status,
    list_comfyui_workflows
)

TOOL_MAP = {
    'generate_image': generate_image,
    'check_comfyui_status': check_comfyui_status,
    'list_comfyui_workflows': list_comfyui_workflows
}

def main():
    if len(sys.argv) < 3:
        print(json.dumps({
            "success": False,
            "error": "Usage: comfyui_bridge.py <tool_name> '<args_json>'"
        }))
        sys.exit(1)
    
    tool_name = sys.argv[1]
    args_json = sys.argv[2]
    
    try:
        args = json.loads(args_json)
    except json.JSONDecodeError as e:
        print(json.dumps({
            "success": False,
            "error": f"Invalid JSON arguments: {e}"
        }))
        sys.exit(1)
    
    # Get tool function
    tool_func = TOOL_MAP.get(tool_name)
    if not tool_func:
        print(json.dumps({
            "success": False,
            "error": f"Unknown tool: {tool_name}",
            "available_tools": list(TOOL_MAP.keys())
        }))
        sys.exit(1)
    
    # Execute tool
    try:
        result = tool_func(**args)
        print(json.dumps(result))
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e),
            "tool": tool_name,
            "args": args
        }))
        sys.exit(1)

if __name__ == '__main__':
    main()
