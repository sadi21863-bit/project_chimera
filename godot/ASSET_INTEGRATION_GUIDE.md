# Project Chimera Asset Integration Guide

## Overview
This guide explains how to download, import, and integrate art assets into Project Chimera.

## Quick Start

### 1. Download Free Assets
```bash
# Download Kenney CC0 assets
python scripts/download_kenney.py --download-all

# Or download specific packs
python scripts/download_kenney.py --download office furniture ui
```

### 2. Import Assets
```bash
# Scan and create import files
python scripts/import_assets.py --scan

# Scan specific directory
python scripts/import_assets.py --scan --directory godot/assets/3d
```

### 3. Generate Asset Manifest
```bash
# Create asset manifest
python scripts/asset_manifest.py --scan

# Generate GDScript loader
python scripts/asset_manifest.py --generate-script
```

### 4. Use in Godot
1. Open Godot editor
2. Assets will be automatically imported
3. Use `AssetManager` autoload to load assets

## Asset Directory Structure
```
godot/assets/
├── 3d/                    # 3D models and scenes
│   ├── detective_office/  # Detective office assets
│   ├── crime_scene/       # Crime scene props
│   ├── dormitory/         # Dorm room furniture
│   └── furniture/         # General furniture
├── 2d/                    # 2D sprites and tilesets
│   ├── detective_items/   # Evidence items, clues
│   ├── interior/          # Interior tilesets
│   ├── characters/        # Character sprites
│   └── ui/                # UI elements
├── audio/                 # Sound effects and music
│   ├── sfx/               # Sound effects
│   ├── music/             # Background music
│   └── ambience/          # Ambient sounds
├── textures/              # Textures for 3D models
│   ├── floors/            # Floor textures
│   ├── walls/             # Wall textures
│   └── props/             # Prop textures
├── fonts/                 # Font files
├── buildings/             # Building exteriors
├── characters/            # Existing character sprites
├── furniture/             # Existing furniture sprites
├── tiles/                 # Existing floor tiles
├── tilesets/              # Existing tilesets
└── ui/                    # Existing UI elements
```

## Using AssetManager

### GDScript Usage
```gdscript
# Load a texture
var texture = AssetManager.load_texture("2d/detective_items/evidence_bloodstain_01.png")

# Load audio
var sfx = AssetManager.load_audio("audio/sfx/door_creak_01.wav")

# Load 3D model
var model = AssetManager.load_model("3d/detective_office/detective_desk_01.glb")

# Get random asset from category
var random_texture = AssetManager.get_random_asset("textures", "detective")

# Preload assets
AssetManager.preload_assets([
    "2d/detective_items/evidence_bloodstain_01.png",
    "audio/sfx/door_creak_01.wav"
])
```

### Asset Info
```gdscript
# Get asset information
var info = AssetManager.get_asset_info("2d/detective_items/evidence_bloodstain_01.png")
print(info.type)      # "textures"
print(info.category)  # "detective"
print(info.size)      # 12345 (bytes)
print(info.hash)      # "abc123..."
```

## Import Presets

### Pixel Art
- Filter: Nearest neighbor
- Mipmaps: Disabled
- Repeat: Disabled

### UI Textures
- Filter: Linear
- Mipmaps: Disabled
- Repeat: Disabled

### Tilesets
- Filter: Nearest neighbor
- Mipmaps: Disabled
- Repeat: Enabled

### 3D Textures
- Filter: Linear
- Mipmaps: Enabled
- Repeat: Enabled

### Audio (SFX)
- Compress: Disabled
- Loop: OFF
- Mono: ON

### Audio (Music)
- Compress: RAM
- Loop: ON
- Mono: OFF

## Manual Asset Download

### From itch.io
1. Visit the asset page
2. Download the asset pack
3. Extract to `godot/assets/` in appropriate category
4. Run `python scripts/import_assets.py --scan`

### From Sketchfab
1. Visit the model page
2. Download in GLTF/GLB format
3. Place in `godot/assets/3d/` in appropriate category
4. Run `python scripts/import_assets.py --scan`

### From CGTrader
1. Visit the model page
2. Download in FBX/GLTF format
3. Place in `godot/assets/3d/` in appropriate category
4. Run `python scripts/import_assets.py --scan`

## Recommended Assets for Project Chimera

### Priority 1 (Free)
1. **Private Detective's Office** (Sketchfab, GLTF)
2. **Crime Scene Pack** (CGTrader, FBX)
3. **Voxel Noir Crime** (itch.io, OBJ)
4. **Interior Pack** (itch.io, PNG)
5. **Kenney 3D + 2D kits** (CC0)

### Priority 2 (Low-cost)
1. **Investigation Board** ($9, CGTrader)
2. **Interrogation Room Pack** ($10, CGTrader)
3. **Police Documents Pack** ($9, CGTrader)
4. **Detective Office LowPoly** ($5, itch.io)

## Troubleshooting

### Assets Not Importing
1. Check file format is supported
2. Run `python scripts/import_assets.py --scan`
3. Restart Godot editor

### AssetManager Not Found
1. Check `project.godot` for autoload
2. Add `AssetManager` autoload if missing
3. Restart Godot editor

### Import Errors
1. Check file permissions
2. Verify file is not corrupted
3. Check Godot console for errors

## Additional Resources

- **Asset Catalog**: `godot/assets/ASSET_CATALOG.md`
- **Import Guides**: See README.md in each asset directory
- **Kenney Assets**: https://kenney.nl (CC0)
- **Sketchfab**: https://sketchfab.com
- **CGTrader**: https://www.cgtrader.com
- **itch.io**: https://itch.io

## Last Updated
Asset integration guide created: August 11, 2026
