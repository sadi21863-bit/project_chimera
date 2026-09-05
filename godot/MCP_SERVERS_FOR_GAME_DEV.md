# MCP Servers for Game Development

## Overview
Recommended MCP servers for Project Chimera and game development workflows.

---

## 3D Asset Creation & Management

### Blender MCP (Official)
- **URL**: https://www.blender.org/lab/mcp-server/
- **Category**: Design
- **Description**: Lightweight MCP server for Blender with natural language interface
- **Features**:
  - Analyze scene performance
  - Rename data-blocks
  - Query data relationships
  - Debug scene issues
  - Document Geometry Nodes setups
- **Installation**:
  1. Blender 5.1 or newer
  2. Install Blender Lab add-on
  3. Install LLM client (Llama.cpp recommended)
  4. Install MCP Server
- **Use Case**: Create and optimize 3D models for detective office, dormitory, crime scenes

### PicoBerry
- **URL**: https://mcpservers.org/servers/umodeler/picoberry-mcp
- **Category**: Design
- **Description**: Generate 3D models and images from text prompts or reference images
- **Features**:
  - Text to 3D model generation
  - Image to 3D conversion
  - Remesh, retexture, auto-rig
  - Export GLB/FBX/OBJ
- **Use Case**: Generate custom 3D assets for the game

### VRM Toolkit
- **URL**: https://mcpservers.org/servers/dwarehouse1/vrm-toolkit-mcp
- **Category**: Design
- **Description**: Inspect, validate and preview VRM/VRMA avatar and animation files
- **Use Case**: If using VRM avatars for characters

---

## Image & Asset Generation

### GPT Image MCP
- **URL**: https://mcpservers.org/servers/codeChap/mcp-server-gpt-image
- **Category**: Design
- **Description**: MCP server for OpenAI GPT image generation and editing
- **Use Case**: Generate concept art, textures, UI elements

### Google Image MCP
- **URL**: https://mcpservers.org/servers/codeChap/mcp-server-google-image
- **Category**: Design
- **Description**: MCP server for Google Gemini image generation and editing
- **Use Case**: Alternative image generation

### Grok Image MCP
- **URL**: https://mcpservers.org/servers/codeChap/mcp-server-grok-image
- **Category**: Design
- **Description**: MCP server for Grok image generation and editing
- **Use Case**: Alternative image generation

### Pixel Agent
- **URL**: https://mcpservers.org/servers/pixel-agent-for-ai-agents-workers-dev
- **Category**: Design
- **Description**: Remote MCP image conversion tool for PNG, JPEG, WebP, AVIF, GIF, SVG, and HEIC workflows
- **Use Case**: Convert and optimize image assets

---

## Browser Automation & Web Scraping

### Playwright MCP (Official)
- **URL**: https://mcpservers.org/servers/playwright-mcp-server
- **Category**: Web Scraping
- **Description**: Official Playwright MCP server for browser automation
- **Features**:
  - Browser automation
  - Page inspection
  - Screenshots
  - Web interaction
- **Use Case**: Automate asset downloads from Sketchfab, itch.io, CGTrader

### Firecrawl MCP
- **URL**: https://mcpservers.org/servers/firecrawl-mcp-server
- **Category**: Web Scraping
- **Description**: Adds powerful web scraping and search capabilities
- **Use Case**: Scrape asset metadata and download links

### Browserbase
- **URL**: https://mcpservers.org/servers/browserbase/mcp-server-browserbase
- **Category**: Web Scraping
- **Description**: Automate browser interactions in the cloud
- **Use Case**: Cloud-based asset downloading

---

## Development & Code

### GitHub MCP (Official)
- **URL**: https://mcpservers.org/servers/github-mcp-server
- **Category**: Version Control
- **Description**: Official GitHub MCP server for repository management
- **Use Case**: Manage game repository, issues, pull requests

### Context7 MCP
- **URL**: https://mcpservers.org/servers/context7-mcp-server
- **Category**: Development
- **Description**: Brings up-to-date library documentation into AI coding prompts
- **Use Case**: Get Godot documentation and examples

---

## Productivity & Documentation

### NotebookLM MCP Server
- **URL**: https://mcpservers.org/servers/pleaseprompto/notebooklm-mcp
- **Category**: Productivity
- **Description**: Let CLI agents chat directly with NotebookLM
- **Use Case**: Zero-hallucination answers based on game design documents

### DeepWiki by Devin
- **URL**: https://mcpservers.org/servers/devin/deepwiki
- **Category**: Development
- **Description**: AI-powered codebase context and answers
- **Use Case**: Understand codebase structure and relationships

---

## File System & Storage

### Google MCP Servers
- **URL**: https://mcpservers.org/servers/google/mcp
- **Category**: Development
- **Description**: Collection of Google's official MCP servers
- **Use Case**: Access Google Drive, Docs, and other services

---

## Recommended Setup for Project Chimera

### Essential MCP Servers
1. **Blender MCP** - For 3D asset creation and optimization
2. **Playwright MCP** - For automated asset downloads
3. **GitHub MCP** - For repository management
4. **Context7 MCP** - For Godot documentation

### Nice to Have
1. **PicoBerry** - For AI-generated 3D models
2. **GPT Image MCP** - For concept art generation
3. **NotebookLM MCP** - For game design documentation

---

## Installation Guide

### Blender MCP
```bash
# 1. Install Blender 5.1+
# 2. Download Blender Lab add-on
# 3. Install Llama.cpp
# 4. Clone MCP server
git clone https://github.com/blender/mcp-server.git
cd mcp-server
pip install -r requirements.txt
# 5. Configure LLM client to use MCP server
```

### Playwright MCP
```bash
# 1. Install Playwright
pip install playwright
playwright install chromium
# 2. Install MCP server
npm install -g @playwright/mcp
# 3. Configure in .mcp.json
```

### GitHub MCP
```bash
# 1. Install GitHub MCP
npm install -g @github/mcp
# 2. Configure GitHub token
# 3. Add to .mcp.json
```

---

## .mcp.json Configuration Example

```json
{
  "mcpServers": {
    "blender": {
      "command": "python",
      "args": ["-m", "mcp_server_blender"],
      "env": {
        "BLENDER_PATH": "C:\\Program Files\\Blender Foundation\\Blender 5.1\\blender.exe"
      }
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@github/mcp"],
      "env": {
        "GITHUB_TOKEN": "your_token_here"
      }
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

---

## Use Cases for Project Chimera

### 1. 3D Asset Pipeline
- Use **Blender MCP** to create and optimize 3D models
- Use **PicoBerry** for quick AI-generated prototypes
- Export as GLTF/GLB for Godot import

### 2. Asset Acquisition
- Use **Playwright MCP** to automate downloads from asset stores
- Use **Firecrawl MCP** to scrape asset metadata
- Download free assets from Sketchfab, itch.io, CGTrader

### 3. Documentation
- Use **Context7 MCP** for Godot documentation
- Use **NotebookLM MCP** for game design documents
- Use **DeepWiki** for codebase understanding

### 4. Version Control
- Use **GitHub MCP** for repository management
- Track asset changes and iterations
- Collaborate with team members

---

## Last Updated
MCP server recommendations: August 11, 2026
