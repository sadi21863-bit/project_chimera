# Free Assets - Downloaded & Ready to Use

## What Was Downloaded (7 packs, ~10 MB total)

### 1. PIPOYA Characters (386 files) — REPLACE Kenney Mini Characters
**Location:** `free-packs/extracted/PIPOYA FREE RPG Character Sprites 32x32/`
- **Female:** 91 sprites (23 characters × 4 color variants each)
- **Male:** 69 sprites (17 characters × 4 color variants)
- **Japanese School:** 134 sprites (students in uniforms)
- **Enemy:** 41 sprites
- **Soldier:** 28 sprites
- **Animal:** 12 sprites
- **Format:** 32x32 sprite sheets with 4-direction walk animations
- **License:** Free for commercial/personal use

**Pick for your 7 characters:**
| NPC | Suggested Sprite | Why |
|-----|-----------------|-----|
| Alex (RA) | Female 01-1 | Organized, authoritative |
| Jordan (Actor) | Male 02-1 | Dramatic, expressive |
| Sam (Hacker) | Male 03-1 | Tech-focused |
| Riley (Pre-Med) | Female 03-1 | Studious |
| Morgan (Athlete) | Male 01-1 | Strong, competitive |
| Casey (Artist) | Female 04-1 | Creative, quiet |
| Detective | Male 05-1 | Professional |

### 2. Pipoya RPG Tileset 32x32 (152 files) — Campus outdoor tiles
**Location:** `free-packs/extracted/Pipoya RPG Tileset 32x32/`
- BaseChip (395 KB) — ground, paths, walls
- Dirt, Grass, Flower tiles
- Wall-Up tiles
- WaterFall tiles
- Sample maps with Tiled format (.tmx)
- **License:** Free for commercial/personal use

### 3. Chrome District Characters (207 files) — 8-direction walk sprites
**Location:** `free-packs/extracted/chrome-district/release/cyber/`
- 20 unique cyberpunk characters
- 8-direction walk cycles (orthographic high/low views)
- Face sheets for dialog portraits
- JSON metadata for each character
- **License:** CC0 (public domain)

### 4. Bitglow Interior Packs (15 files) — Indoor furniture
**Location:** `free-packs/extracted/pixelinterior_*/`
- **Living Room & Kitchen** (7 PNGs): cabinets, decorations, doors/windows, floors/walls, kitchen, living room
- **Bedroom** (4 PNGs): bedroom furniture
- **Bathroom** (4 PNGs): bathroom fixtures
- **Format:** 16x16 pixel art spritesheets
- **License:** Free for commercial/non-commercial use

### 5. Free House Pixel Art (165 files) — Building tiles
**Location:** `free-packs/extracted/free-house-pixel-art/`
- House tiles (floors, walls, roofs)
- Furniture sprites
- Hut tile set (115 files)
- **License:** CC0 (public domain)

### 6. Kenney Roguelike Indoor (already in asset dump)
**Location:** `asset dump/kenney_roguelike-indoors.zip`
- 480 sprites at 16x16
- Kitchen, tables, chairs, sofas, beds, cabinets
- **License:** CC0

### 7. Kenney Furniture Kit (already in asset dump)
**Location:** `asset dump/kenney_furniture-kit.zip`
- 120 objects with top-down renders
- **License:** CC0

---

## Integration Priority

### Phase 1: Characters (Biggest visual impact)
1. Extract PIPOYA character sprite sheets
2. Pick 7 characters matching NPC personalities
3. Build SpriteFrames resources in Godot
4. Replace Kenney Mini Characters

### Phase 2: Indoor Furniture
1. Use Bitglow packs for kitchen, bathroom, bedroom
2. Use Kenney Roguelike Indoor for common room furniture
3. Add furniture sprites to each room scene

### Phase 3: Campus Outdoor
1. Use Pipoya tileset for ground/paths
2. Use existing Kenney City Kit for buildings
3. Use existing Textured Stylized Trees

### Phase 4: Polish
1. Mix Chrome District face sheets for dialog portraits
2. Apply consistent color tinting
3. Add door/window sprites to walls

---

## File Locations Summary

```
asset dump/
├── free-packs/
│   ├── itch-downloads/          # Raw zip files from itch.io
│   │   ├── chrome-district.zip
│   │   ├── free-house-pixel-art.zip
│   │   ├── PIPOYA FREE RPG Character Sprites 32x32.zip
│   │   ├── Pipoya RPG Tileset 32x32.zip
│   │   ├── pixelinterior_BA_v1.0.zip
│   │   ├── pixelinterior_BR_v1.1.zip
│   │   └── pixelinterior_LRK_v1.1.zip
│   └── extracted/               # Unpacked contents
│       ├── PIPOYA FREE RPG Character Sprites 32x32/
│       ├── Pipoya RPG Tileset 32x32/
│       ├── chrome-district/
│       ├── free-house-pixel-art/
│       ├── pixelinterior_LRK_v1.1/
│       ├── pixelinterior_BR_v1.1/
│       └── pixelinterior_BA_v1.0/
├── kenney_roguelike-indoors.zip  # Already existed
├── kenney_furniture-kit.zip      # Already existed
├── kenney_cityKitSuburban.zip    # Already existed
├── Textured Stylized Trees/      # Already existed
└── Ultimate Nature Pack/         # Already existed
```
