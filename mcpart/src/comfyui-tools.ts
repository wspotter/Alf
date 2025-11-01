/**
 * ComfyUI Integration Tools for MCP Server
 * Provides image generation capabilities via local ComfyUI instance
 */

import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export interface ComfyUITool {
  name: string;
  description: string;
  inputSchema: {
    type: string;
    properties: Record<string, any>;
    required?: string[];
  };
}

export const comfyuiTools: ComfyUITool[] = [
  {
    name: 'generate_image',
    description: 'Generate an image using ComfyUI (LOCAL GPU - TAKES 30-120 SECONDS). Use when user asks to create, generate, or draw an image. WARN USER IT WILL TAKE TIME. Tell user "Generating image, this will take about 30-60 seconds..." then call this tool.',
    inputSchema: {
      type: 'object',
      properties: {
        prompt: {
          type: 'string',
          description: 'Detailed text description of desired image'
        },
        size: {
          type: 'string',
          description: 'Image dimensions: "512x512" (fastest ~30s), "1024x1024" (medium ~60s), "1024x1792" or "1792x1024" (slowest ~120s)',
          default: '512x512'
        },
        quality: {
          type: 'string',
          description: '"standard" (20 steps, ~30-60s) or "hd" (30 steps, ~60-120s)',
          default: 'standard'
        },
        style: {
          type: 'string',
          description: '"natural" (photorealistic) or "vivid" (artistic, stylized)',
          default: 'natural'
        }
      },
      required: ['prompt']
    }
  },
  {
    name: 'check_comfyui_status',
    description: 'Check if ComfyUI service is running and responsive. Use when debugging image generation or verifying availability.',
    inputSchema: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'list_comfyui_workflows',
    description: 'List available ComfyUI workflow templates. Shows what types of images can be generated.',
    inputSchema: {
      type: 'object',
      properties: {}
    }
  }
];

/**
 * Handle ComfyUI tool execution
 */
export async function handleComfyUITool(
  toolName: string,
  args: Record<string, any>
): Promise<{ content: Array<{ type: string; text: string }> }> {
  try {
    // Call Python bridge script
    const pythonScript = `/home/stacy/AlphaOmega/venv/bin/python3`;
    const bridgeScript = `/home/stacy/AlphaOmega/mcpart/tools/comfyui_bridge.py`;
    
    const argsJson = JSON.stringify(args);
    const command = `${pythonScript} ${bridgeScript} ${toolName} '${argsJson}'`;
    
    const { stdout, stderr } = await execAsync(command, {
      timeout: 300000, // 5 minutes for image generation
      maxBuffer: 10 * 1024 * 1024 // 10MB buffer for large responses
    });
    
    if (stderr && !stderr.includes('UserWarning')) {
      console.error(`ComfyUI tool stderr: ${stderr}`);
    }
    
    // Parse Python output
    const result = JSON.parse(stdout);
    
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(result, null, 2)
        }
      ]
    };
    
  } catch (error: any) {
    console.error(`Error executing ComfyUI tool ${toolName}:`, error);
    
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            success: false,
            error: error.message || String(error),
            tool: toolName,
            message: `❌ ComfyUI tool execution failed: ${error.message || String(error)}`
          }, null, 2)
        }
      ]
    };
  }
}
