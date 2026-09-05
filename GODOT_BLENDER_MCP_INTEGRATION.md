# Godot ↔ Blender MCP Integration: Research & Architecture

## TL;DR

**Yes, it's absolutely possible.** Multiple approaches exist, ranging from simple dual-MCP setups to fully orchestrated AI-driven pipelines. The recommended approach for Project Chimera: install `ricky-yosh/blender-mcp` (Godot-specific) alongside our existing `godot-mcp`, connected via a Python orchestrator script.

---

## Existing Solutions (Ranked by Fit)

### 1. `ricky-yosh/blender-mcp` — Godot-Specific Blender MCP ⭐ RECOMMENDED

**GitHub:** https://github.com/ricky-yosh/blender-mcp  
**Port:** 9877 (avoids conflict with official 9876)  
**Tools:** 21 Godot-tailored tools

| Tool | What it does |
|---|---|
| `blender_export_gltf` | Exports GLB/GLTF with Y-up, applied modifiers, Godot metadata |
| `blender_export_selected_gltf` | Export selected objects only |
| `blender_set_godot_custom_properties` | Set collision layers, node type hints, LOD bias that survive GLB export |
| `blender_set_material_pbr` | Set metallic/roughness/emission (Godot reads these natively) |
| `blender_create_armature` | Create skeleton for rigged characters |
| `blender_set_keyframe` | Insert keyframes for animations |

**Why it wins:** Purpose-built for the Blender→Godot workflow. Custom properties survive GLB export and appear in Godot's scene tree as node metadata. Handles Y-up conversion automatically.

### 2. `hermes-asset-pipeline` — Full AI Pipeline (ComfyUI + Blender + Godot)

**GitHub:** https://github.com/Limbicnation/hermes-asset-pipeline  
**Architecture:**
```
ComfyUI (AI image gen) → Blender (texturing/render) → Godot (scene import)
```

**Pros:** End-to-end automation, staged workflow with manifest logging, format bridge (PNG↔WebP↔GLB↔OBJ), texture pack generation  
**Cons:** Requires ComfyUI, Hermes Agent, heavier setup — overkill for our needs but excellent reference architecture

### 3. Official Blender MCP (port 9876) + Godot MCP (port 6505) — Dual Setup

**Blender MCP:** https://www.blender.org/lab/mcp-server/  
**Godot MCP:** https://github.com/bradypp/godot-mcp

**Pros:** Both well-maintained, broad toolsets  
**Cons:** Not Godot-aware (Blender MCP doesn't know about GLB export best practices, collision layers, etc.)

### 4. BlenderMCP Pro (Paid, $29)

**Features:** Asset validation, batch export to engine-specific formats (UE5/Unity/Godot), structured error handling  
**Cons:** Paid, requires Anthropic API key, overkill for our needs

---

## Architecture Options for Project Chimera

### Option A: Dual MCP + Orchestrator (RECOMMENDED)

```
Claude Code
├── godot-mcp (port 6505)          ← Scene manipulation, GDScript, testing
├── blender-godot (port 9877)      ← 3D modeling, materials, GLB export
└── orchestrator.py                ← Bridges both MCPs, manages pipeline

Workflow:
1. Claude calls blender-godot: "Create desk mesh, apply wood material, export to assets/3d/"
2. Claude calls orchestrator: "Import GLB into Godot, create .tscn scene"
3. Claude calls godot-mcp: "Add desk to scene, set collision layer 3"
```

**Setup:**
```json
// .mcp.json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "python",
      "args": ["C:/Users/aditya/Desktop/project-chimera/tools/mcp/bridge.py"],
      "env": { "GODOT_PATH": "C:/Users/aditya/Desktop/Godot_v4.7-stable_win64_console.exe" }
    },
    "blender-godot": {
      "command": "python",
      "args": ["C:/Users/aditya/Desktop/project-chimera/tools/mcp/blender_godot_server.py"],
      "env": { "BLENDER_PORT": "9877" }
    }
  }
}
```

### Option B: Unified Bridge Server (Advanced)

A single Python server that connects to both Blender (TCP :9877) and Godot (WebSocket :6505), exposing cross-tool operations:

```
blender_export_and_import → Blender GLB export → Godot scene import
blender_to_game_asset → Full pipeline: model → material → export → import → setup
validate_asset_in_engine → Blender render → Godot visual comparison
```

### Option C: Hermes-Style Staged Pipeline (Production)

```
Staging directories:
staging/
├── blender_exports/    ← GLB files from Blender
├── godot_imports/      ← Imported .tscn scenes
├── textures/           ← Albedo, normal, roughness maps
└── manifest.json       ← Asset tracking

Pipeline skills:
1. Export from Blender → staging/blender_exports/
2. Import to Godot → staging/godot_imports/
3. Setup in scene → Apply materials, collisions, scripts
4. Verify → Visual QA comparison
```

---

## Effects & Benefits

### Direct Benefits

| Area | Before | After |
|---|---|---|
| Asset creation | Manual modeling or find free assets | AI generates models in Blender, exports directly to Godot |
| Material setup | Create in Blender, re-setup in Godot | PBR materials transfer automatically via GLB |
| Animation | Export skeletal data, re-import | Armatures + keyframes transfer with Godot custom properties |
| Iteration speed | Hours per asset | Minutes — describe what you want, AI executes |
| Quality control | Manual visual checks | Vision model validates at each step |

### Specific to Project Chimera

1. **Evidence 3D Models** — Generate crime scene props (fingerprints, documents, weapons) directly in Blender, export to Godot with collision layers pre-configured
2. **Character Sprites** — Render 3D character poses in Blender, extract as 2D sprites for the dorm sim
3. **Environment Assets** — Generate dorm room furniture, hallway props, office equipment
4. **Animation Clips** — Create interrogation gestures, evidence examination animations
5. **Visual QA** — Compare Blender renders against Godot in-game screenshots for consistency

### Pipeline Pattern (From Real Production)

The dev.to article by Aleksandr Kossarev documents this exact pattern working in production:

```
Architecture:
Human (instructions)
  → AI Agent (generates bpy code)
    → MCP Protocol (JSON-RPC)
      → Blender Addon (executes Python)
        → Viewport Screenshot
          → Vision Model (validates result)
            → AI Agent (adjusts or proceeds)
              → Export GLB → Godot
```

**Key lesson:** One action → one verification. Don't batch operations. After each Blender step, take a screenshot and validate before proceeding.

---

## Potential Issues & Mitigations

| Issue | Impact | Mitigation |
|---|---|---|
| Axis mismatch (Blender Z-up vs Godot Y-up) | Models rotated 90° | `blender_export_gltf` handles this; apply transforms before export |
| Animation speed (30 FPS Blender vs 60 FPS Godot) | Half-speed animations | Set `speed_scale = 2.0` in Godot or bake at 60 FPS |
| Blender context modes | `bpy.ops` fails in wrong mode | Use `blender_execute_python` with explicit mode_set calls |
| No LLM API key | Can't use AI for model generation | Use `--dry-run` heuristic mode; still get MCP automation benefits |
| Blender not running | MCP connection fails | Start Blender with addon enabled before using tools |
| File size | Large GLB files slow imports | Use `batch_decimate` for polygon reduction, `texture_optimize` for compression |

---

## Implementation Plan

### Phase 1: Install Godot Pipeline MCP (30 min)

1. Download `addon.py` from `ricky-yosh/blender-mcp`
2. Install in Blender: Edit → Preferences → Add-ons → Install from Disk
3. Enable "Godot Pipeline MCP" addon
4. Click "Start MCP Server" in N panel (port 9877)
5. Add to `.mcp.json` as `blender-godot` server

### Phase 2: Create Orchestrator Script (1 hour)

Build `tools/mcp/blender_godot_bridge.py`:
- Connects to Blender MCP (TCP :9877)
- Connects to Godot MCP (WebSocket :6505)
- Exposes cross-tool operations:
  - `export_and_import(glb_path)` — Export from Blender, import to Godot
  - `create_game_asset(name, type, material)` — Full pipeline
  - `validate_asset(blender_render, godot_screenshot)` — Visual comparison

### Phase 3: Build Asset Pipeline (2 hours)

Create `tools/mcp/asset_pipeline.py`:
- Staging directory management
- GLB → .tscn conversion
- Material transfer (PBR properties)
- Collision layer assignment
- Script attachment

### Phase 4: Integrate with Visual QA (1 hour)

Extend `tools/visual_diff.gd`:
- Add Blender render comparison mode
- Compare Blender viewport screenshots against Godot in-game renders
- Auto-detect material/lighting differences

---

## Commands to Test

Once installed, these Claude Code prompts would work:

```
"Check what's in my current Blender scene"
"Create a low-poly evidence marker mesh, name it Evidence_Fingerprint_01"
"Make a metal material with roughness 0.3 and metallic 1.0, assign it to the evidence marker"
"Export the evidence marker to C:/Users/aditya/Desktop/project-chimera/godot/assets/3d/evidence/"
"Set Evidence_Fingerprint_01's collision_layer to 2 and node_type to StaticBody3D"
"Export just the selected character mesh and its armature to assets/3d/characters/"
```

---

## Bottom Line

**The Godot↔Blender MCP bridge already exists.** The `ricky-yosh/blender-mcp` addon is purpose-built for exactly this workflow. Combined with our existing `godot-mcp` setup, we can:

1. Model/modify 3D assets in Blender via Claude Code
2. Export with Godot-specific settings (collision layers, node types, LOD)
3. Import directly into Godot scenes
4. Validate visually via screenshot comparison

This transforms our asset pipeline from "find free assets → import manually" to "describe what I want → AI creates in Blender → auto-imports to Godot → visual verification."

---

## References

- **Blender → Godot MCP:** https://github.com/ricky-yosh/blender-mcp
- **Hermes Asset Pipeline:** https://github.com/Limbicnation/hermes-asset-pipeline
- **Official Blender MCP:** https://www.blender.org/lab/mcp-server/
- **Godot MCP:** https://github.com/bradypp/godot-mcp
- **Production case study:** https://dev.to/aleksandr_kossarev_e23623/ai-orchestrated-3d-asset-pipeline-from-jpeg-to-game-ready-glb-without-touching-blender-1akf
- **MCP comparison article:** https://mcp.directory/blog/godot-vs-unity-vs-blender-mcp-skills-2026
- **Blender Studio workflow:** https://studio.blender.org/blog/our-workflow-with-blender-and-godot/
