# Blender MCP vs Chimera MCP Comparison

## Overview
Comparison between the official Blender MCP server and the custom Chimera MCP addon for Project Chimera.

---

## Official Blender MCP

**Source**: https://github.com/ahujasid/blender-mcp
**Version**: 1.8.0
**Port**: 9876

### Core Features
| Feature | Description | Status |
|---------|-------------|--------|
| Scene Info | Get basic scene information | ✅ |
| Object Info | Get details about specific objects | ✅ |
| Viewport Screenshot | Capture viewport images | ✅ |
| Code Execution | Execute arbitrary Python code | ✅ |
| Polyhaven Integration | Search/download PBR assets | ✅ |
| Hyper3D Integration | AI 3D model generation | ✅ |
| Sketchfab Integration | Search/download 3D models | ✅ |
| Hunyuan3D Integration | AI 3D generation | ✅ |

### Capabilities
- **General Purpose**: Works for any Blender project
- **External Services**: Connects to Polyhaven, Sketchfab, Hyper3D, Hunyuan3D
- **Flexible**: Can handle any Blender task via code execution
- **Generic Commands**: `get_scene_info`, `get_object_info`, `execute_code`

### Limitations
- No game-specific features
- No sprite rendering pipeline
- No tileset generation
- No material library for specific aesthetics
- No batch processing for game assets
- No Godot-specific export tools

---

## Chimera MCP (Custom)

**Source**: Local addon for Project Chimera
**Version**: 1.0
**Port**: 9877

### Core Features
| Feature | Description | Status |
|---------|-------------|--------|
| Character Sprite Rendering | Render 3D characters into 2D sprites | ✅ |
| Batch Character Rendering | Render multiple characters at once | ✅ |
| Interior Scene Composition | Compose room scenes from assets | ✅ |
| Tileset Generation | Create tilesets from textures | ✅ |
| Detective Noir Materials | Predefined material library | ✅ |
| GLTF Export | Export to Godot-compatible format | ✅ |
| Sprite Atlas Creation | Combine sprites into atlases | ✅ |
| Scene Analysis | Analyze polygon count, suggest optimizations | ✅ |

### Capabilities
- **Game-Focused**: Specifically designed for Project Chimera
- **Character Pipeline**: Complete workflow from GLB to sprite sheets
- **Room Composition**: Arrange furniture for interior scenes
- **Material Library**: Detective noir aesthetic (wood, metal, leather, etc.)
- **Batch Processing**: Render multiple characters automatically
- **Optimization Analysis**: Identify high-poly objects for game performance

### Game-Specific Features

#### 1. Character Sprite Rendering
```python
# Chimera MCP
render_character_sprites(
    glb_path="path/to/character.glb",
    char_id="detective",
    directions=["down", "up", "left", "right"],
    frames=6,
    size=256
)
```

vs

```python
# Official MCP - Manual approach
execute_code(code="""
    # Import GLB
    bpy.ops.import_scene.gltf(filepath='character.glb')
    # Set up camera...
    # Set up lighting...
    # Render each direction manually...
""")
```

**Winner**: Chimera MCP (dedicated pipeline vs manual setup)

#### 2. Batch Processing
```python
# Chimera MCP
batch_render_characters([
    {"glb_path": "detective.glb", "char_id": "detective"},
    {"glb_path": "alex.glb", "char_id": "alex"},
    {"glb_path": "jordan.glb", "char_id": "jordan"}
])
```

vs

```python
# Official MCP - Requires manual iteration
for char in characters:
    # Manual import, setup, render, export for each
```

**Winner**: Chimera MCP (automated batch vs manual)

#### 3. Material Library
```python
# Chimera MCP
create_chimera_material("wood_dark")  # Pre-configured noir aesthetic
apply_chimera_material("Desk", "leather")
```

vs

```python
# Official MCP - Must create materials manually
execute_code(code="""
    mat = bpy.data.materials.new('Wood')
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes['Principled BSDF']
    bsdf.inputs['Base Color'].default_value = (0.15, 0.08, 0.04, 1)
    # ... more manual setup
""")
```

**Winner**: Chimera MCP (preset library vs manual creation)

#### 4. Scene Analysis
```python
# Chimera MCP
analyze_polycount()  # Returns detailed breakdown
suggest_optimizations()  # Game-specific suggestions
export_scene_report("report.json")  # JSON report
```

vs

```python
# Official MCP - Basic info only
get_scene_info()  # Limited object count
# No optimization suggestions
```

**Winner**: Chimera MCP (detailed analysis vs basic info)

#### 5. Tileset Generation
```python
# Chimera MCP
create_tileset_from_texture(
    texture_path="wood_floor.png",
    tile_size=32,
    output_path="tileset.png",
    include_variations=True
)
```

vs

```python
# Official MCP - No tileset support
# Must use external tools or manual creation
```

**Winner**: Chimera MCP (dedicated feature vs none)

#### 6. Sprite Atlas Creation
```python
# Chimera MCP
export_sprite_atlas(
    images=["idle_down.png", "walk_down_0.png", ...],
    output_path="atlas.png",
    columns=8
)
```

vs

```python
# Official MCP - No atlas support
# Must use external image editor
```

**Winner**: Chimera MCP (built-in vs external)

---

## Feature Comparison Matrix

| Category | Official MCP | Chimera MCP | Winner |
|----------|--------------|-------------|--------|
| **General Scene Operations** | ✅ Full | ✅ Basic | Official |
| **Code Execution** | ✅ Full | ❌ Not needed | Official |
| **External Asset Services** | ✅ Polyhaven, Sketchfab | ❌ Not implemented | Official |
| **AI 3D Generation** | ✅ Hyper3D, Hunyuan3D | ❌ Not implemented | Official |
| **Character Sprite Pipeline** | ❌ Manual | ✅ Automated | Chimera |
| **Batch Processing** | ❌ Manual | ✅ Automated | Chimera |
| **Game Material Library** | ❌ Generic | ✅ Noir Aesthetic | Chimera |
| **Tileset Generation** | ❌ None | ✅ Built-in | Chimera |
| **Sprite Atlas Creation** | ❌ None | ✅ Built-in | Chimera |
| **Scene Optimization Analysis** | ❌ None | ✅ Built-in | Chimera |
| **Godot Export** | ❌ Generic GLTF | ✅ Game-optimized | Chimera |
| **Room Composition** | ❌ Manual | ✅ Semi-automated | Chimera |

---

## Use Case Scenarios

### Scenario 1: Rendering Character Sprites
**Official MCP**: 15-20 minutes manual setup per character
**Chimera MCP**: 1-2 minutes automated per character

### Scenario 2: Creating 9 Character Sprites
**Official MCP**: 2-3 hours of manual work
**Chimera MCP**: 10-15 minutes batch processing

### Scenario 3: Setting Up Room with Furniture
**Official MCP**: Manual positioning, no presets
**Chimera MCP**: Room type presets, faster arrangement

### Scenario 4: Analyzing Scene for Optimization
**Official MCP**: Basic object count only
**Chimera MCP**: Detailed polygon analysis + suggestions

---

## Recommendation

### Use Official Blender MCP When:
- Working on general Blender projects
- Need access to external asset libraries (Polyhaven, Sketchfab)
- Want AI-generated 3D models
- Need arbitrary Python code execution
- Working on non-game projects

### Use Chimera MCP When:
- Building Project Chimera specifically
- Rendering character sprites from 3D models
- Creating tilesets for game levels
- Need detective noir aesthetic materials
- Batch processing multiple assets
- Optimizing scenes for game performance

### Best Approach: Use Both
The two addons can coexist on different ports:
- **Official MCP (9876)**: For general Blender operations
- **Chimera MCP (9877)**: For game-specific asset creation

---

## Installation Comparison

### Official MCP
```bash
pip install blender-mcp
# Or: uvx blender-mcp
# Addon installed in Blender
```

### Chimera MCP
```bash
# Copy chimera_mcp.py to Blender addons folder
# Enable in Blender Preferences
# No external dependencies needed
```

---

## Conclusion

**For Project Chimera**: Chimera MCP is significantly more efficient for game asset creation workflows. The automated pipelines, batch processing, and game-specific features save hours of manual work.

**For General Use**: Official MCP is more versatile with external service integrations and arbitrary code execution.

**Recommended Setup**: Install both addons for maximum flexibility - use Official MCP for general operations and Chimera MCP for Project Chimera-specific asset pipelines.

---

## Last Updated
Comparison created: August 11, 2026
