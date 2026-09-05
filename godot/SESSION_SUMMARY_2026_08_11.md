# Session Summary — 2026-08-11

## What We Accomplished

### 1. Godot↔Blender MCP Integration ✅

**Research complete.** Found that purpose-built solutions already exist:

- **`ricky-yosh/blender-mcp`** — Godot-specific Blender MCP addon (port 9877)
  - 21 Godot-tailored tools
  - GLB export with Y-up, applied modifiers, Godot metadata
  - Custom properties that survive export (collision layers, node types, LOD)
  - PBR materials that Godot reads natively

- **`hermes-asset-pipeline`** — Full AI pipeline (ComfyUI → Blender → Godot)
  - Staged workflow with manifest logging
  - Format bridge (PNG↔WebP↔GLB↔OBJ)
  - Texture pack generation

**Architecture decided:**
```
Claude Code
├── godot-mcp (port 6505)          ← Scene manipulation, GDScript
├── blender-godot (port 9877)      ← 3D modeling, materials, GLB export
└── orchestrator.py                ← Bridges both, manages pipeline
```

### 2. Blender MCP Addon Installed ✅

Files created:
- `tools/mcp/blender_godot_addon.py` — Blender addon (TCP socket server on port 9877)
- `tools/mcp/blender_godot_server.py` — MCP server bridging clients to Blender
- `tools/mcp/BLENDER_GODOT_SETUP.md` — Setup guide with all 21 tools documented

Package installed:
- `mcp` v2.0.0 (with all dependencies)

`.mcp.json` updated — `blender-godot` server entry added.

### 3. Comprehensive Free Asset Catalog ✅

**150+ asset packs cataloged** across ALL genres:

| Category | Count | Highlights |
|----------|-------|------------|
| 3D Models | 50+ packs | Furniture, sci-fi, medieval, horror, nature, characters |
| 2D Art | 30+ packs | VN sprites, tilesets, UI kits |
| Audio | 20+ packs | Ambient ambiences, music loops, SFX |
| Textures | 1000+ | PBR materials from ambientCG (all CC0) |
| HDRIs | 3400+ | Professional lighting from Poly Haven (all CC0) |
| Fonts | 10+ packs | Pixel fonts for dialogue and UI |
| VFX | 10+ packs | Godot-specific particle effects |
| Animations | 2000+ | Mixamo library + Quaternius character anims |

**Key finding:** Assets from ALL genres can be repurposed:
- Sci-fi → Research facility, high-tech dorm wing
- Medieval → Old university architecture
- Horror → Nighttime dorm suspense
- Fantasy → Magical collectibles, occult decorations
- Nature → Campus grounds, outdoor investigation
- Office → University admin, detective workspace
- Food → Cafeteria scenes, dorm kitchen

### 4. Game Dev Pipeline Best Practices ✅

Key insights:
- **Blender is the universal intermediate** — Keep .blend files as source of truth
- **GLB is king for Godot** — Native support, materials + animations transfer
- **Style consistency via single creator** — Kenney's consistent style prevents visual clashes
- **Kitbashing works** — One furniture pack → recolor for different contexts
- **License hierarchy matters** — CC0 (zero risk) > CC-BY (low) > CC-BY-SA (medium) > CC-BY-NC (cannot use)

---

## Files Created This Session

| File | Purpose |
|------|---------|
| `GODOT_BLENDER_MCP_INTEGRATION.md` | Godot↔Blender MCP research & architecture |
| `FREE_ASSETS_MASTER_CATALOG.md` | 150+ asset packs across all genres |
| `GAME_DEV_PIPELINE_BEST_PRACTICES.md` | Industry best practices for asset pipelines |
| `tools/mcp/blender_godot_addon.py` | Blender addon (TCP port 9877) |
| `tools/mcp/blender_godot_server.py` | MCP server bridging clients to Blender |
| `tools/mcp/BLENDER_GODOT_SETUP.md` | Step-by-step installation guide |

---

## Next Steps

### Immediate (Ready to Execute)
1. **Test Blender MCP** — Open Blender GUI, enable addon, verify connection on port 9877
2. **Download priority assets** — Start with Kenney Furniture Kit, Food Kit, Building Kit
3. **Create style bible** — Define Project Chimera's visual identity

### Short-Term (This Week)
4. **Build asset pipeline** — GLB → .tscn, material transfer, collision setup
5. **Build Detective's Notebook feature** — Highest-impact missing game feature
6. **Build Evidence Board / Timeline Reconstruction UI**

### Medium-Term (Next Sprint)
7. **Enhanced interrogation system** — Skill-based questioning
8. **Tutorial / onboarding** — First 5 minutes experience
9. **Campus exploration** — Outdoor areas, day/night cycle

---

## Critical Path Items

| Blocker | Resolution |
|---------|------------|
| Blender MCP not tested yet | Need to open Blender GUI and enable addon |
| No LLM API key | Use `--dry-run` heuristic mode for AI features |
| Kenney download URLs changed | Manual download from kenney.nl needed |
| Framedash API key missing | Not blocking — can work without it |

---

## Asset Download Priority List

### Tier 1 — Download Now (Directly Applicable)
1. Kenney Furniture Kit — https://kenney.nl/assets/furniture-kit
2. Kenney Food Kit — https://kenney.nl/assets/food-kit
3. Kenney Building Kit — https://kenney.nl/assets/building-kit
4. Quaternius Universal Base Characters — https://quaternius.com/packs/universalbasecharacters.html
5. Quaternius Stylized Nature MegaKit — https://quaternius.itch.io/stylized-nature-megakit

### Tier 2 — Download Soon (High Repurposing Value)
6. PSX Apartment Pack — https://goodgriffith.itch.io/psx-assets-apartment-pack
7. Abandoned School PSX — https://cursedlake.itch.io/psxschool
8. Modular Sci-Fi MegaKit — https://quaternius.itch.io/modular-sci-fi-megakit
9. Medieval Village MegaKit — https://quaternius.itch.io/medieval-village-megakit
10. Mixamo animations — https://www.mixamo.com/

### Tier 3 — Download When Needed
11. Visual Novel Sprite Packs (various itch.io sources)
12. Freesound.org ambient ambiences
13. ambientCG PBR materials
14. Poly Haven HDRIs
15. Pixel fonts (Fibberish, dia.log, Pixellari)
