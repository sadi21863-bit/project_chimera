# Free Asset Research Report (2026-08-06)

## Summary

Downloaded and audited free assets for Project Chimera. The game needs:
1. **Indoor furniture** for dorm rooms (kitchen, bathroom, bedrooms, common room)
2. **Outdoor campus tiles** (roads, grass, buildings, trees)
3. **Character sprites** with walk animations (7 characters)

---

## What Was Downloaded

### Already in `asset dump/` (useful)

| Pack | Size | Type | License | Use For |
|------|------|------|---------|---------|
| `kenney_roguelike-indoors.zip` | 0.1 MB | 2D spritesheet (16x16) | CC0 | **Indoor furniture** — 480 sprites: kitchen, tables, chairs, sofas, beds, cabinets |
| `kenney_furniture-kit.zip` | 4.9 MB | 3D + 2D renders | CC0 | **Furniture** — 120 objects with top-down/isometric renders |
| `kenney_cityKitSuburban.zip` | 1.9 MB | 3D models + isometric renders | CC0 | **Campus buildings** — houses, driveways, roads |
| `kenney_retro-urban-kit.zip` | 2.1 MB | 2D tiles | CC0 | **Urban environment** — roads, buildings, details |
| `Buildings pack` | 2.6 MB | 3D models | CC0 | **Building exteriors** — hospital, bank, flats |
| `Textured Stylized Trees` | 11.8 MB | 3D models | CC0 | **Trees** — for campus decoration |
| `Ultimate Nature Pack` | 22.9 MB | 3D models | CC0 | **Nature** — grass, rocks, plants |
| `Ultimate House Interior Pack` | 12.8 MB | 3D models (FBX) | CC0 | **Interior reference** — 93 house interior models |
| `Ultimate Animated Character Pack` | 73 MB | 3D models (FBX/glTF) | CC0 | **Character reference** — 52 animated character models |

### Newly Downloaded to `free-packs/`

| Pack | Size | Type | License | Use For |
|------|------|------|---------|---------|
| `kenney_roguelike_indoor_oga.zip` | 0.2 MB | 2D spritesheet (16x16) | CC0 | Same as above, from OGA |
| `kenney_furniture_kit.zip` | 5.3 MB | 3D + 2D renders | CC0 | Same as above, from OGA |
| `kenney_city_builder_kit.zip` | 1.5 MB | 2D tiles | CC0 | **City builder tiles** — roads, buildings, nature |

---

## Best Free Alternatives to Paid Packs

### For Indoor Furniture (replaces LimeZu $5)

**Best option: Kenney Roguelike Indoor Pack (already downloaded)**
- 480 sprites at 16x16, CC0 license
- Covers: kitchen (stove, fridge, counters), tables, chairs, sofas, bookshelves, beds, cabinets, rugs, plants
- Missing: bathroom items, modern style (more medieval/roguelike)

**Supplement with:**
- **bitglow Pixel Interior Series** (free, 3 packs) — kitchen/living room, bedroom, bathroom
  - Download manually from: https://bitglow.itch.io/pixelinterior-livingroomkitchen
  - 16x16, modern furniture, same style across all 3 packs
- **NinjaGame_Dev Pixel Furniture** (free) — 30 items at 32x32
  - Download manually from: https://ninjagame-dev.itch.io/pixel-furniture-30-free-top-down-objects

### For Character Sprites (replaces bobmac321 $5)

**Best option: PIPOYA FREE RPG Character Sprites (free, manual download)**
- 64 characters with 4-way walk animations
- 32x32 pixel art, includes character generator
- Download from: https://pipoya.itch.io/pipoya-free-rpg-character-sprites-32x32

**Supplement with:**
- **CHROME DISTRICT** (CC0) — 20 characters with 8-direction walks
  - Download manually from: https://booliebuilds.itch.io/chrome-district
- **Kenney Toon Characters** (CC0) — 6 characters with 45 poses each
  - Download from Kenney website (requires manual download)

### For Campus/Outdoor (replaces 2DPIXX $15)

**Best option: Kenney City Kit Suburban (already downloaded)**
- Isometric buildings, roads, driveways
- CC0 license, 3D models with renders

**Supplement with:**
- **Kenney Retro Urban Kit** (already downloaded) — 2D urban tiles
- **Pipoya FREE RPG Tileset 32x32** (free, manual download)
  - Indoor + outdoor with door transitions
  - Download from: https://pipoya.itch.io/pipoya-rpg-tileset-32x32

### For Large Character Collection (replaces Pixel Citizen $20)

**Best option: Combine multiple free packs**
1. PIPOYA (64 characters) + CHROME DISTRICT (20 characters) = 84 characters
2. Kenney Toon Characters (6 characters × 45 poses) for dialog portraits
3. FreePixel Character Library (289 characters, fantasy-themed)
   - Browse at: https://freepixel.art/characters

---

## Recommended Integration Strategy

### Phase 1: Indoor Furniture (Immediate)
1. Use Kenney Roguelike Indoor spritesheet for all rooms
2. Download bitglow packs for bathroom (missing from Kenney)
3. Create TileSet from spritesheet for Godot

### Phase 2: Campus Outdoor
1. Use Kenney City Kit Suburban for building exteriors
2. Use Kenney Retro Urban Kit for roads and paths
3. Use existing Textured Stylized Trees for decoration

### Phase 3: Character Sprites
1. Download PIPOYA characters (64 characters, 4-way walk)
2. Select 7 that match NPC personalities
3. Build SpriteFrames resources

### Phase 4: Polish
1. Mix and match from multiple packs for variety
2. Apply consistent color palette/tint
3. Add furniture to bedrooms, kitchen, common room

---

## Manual Downloads Required

These packs need browser interaction to download (itch.io requires it):

| Pack | URL | Why Manual |
|------|-----|------------|
| bitglow Living Room & Kitchen | https://bitglow.itch.io/pixelinterior-livingroomkitchen | itch.io download |
| bitglow Bedroom | https://bitglow.itch.io/pixelinterior-bedroom | itch.io download |
| bitglow Bathroom | https://bitglow.itch.io/pixelinterior-bathroom | itch.io download |
| PIPOYA Characters | https://pipoya.itch.io/pipoya-free-rpg-character-sprites-32x32 | itch.io download |
| CHROME DISTRICT | https://booliebuilds.itch.io/chrome-district | itch.io download |
| Pipoya RPG Tileset | https://pipoya.itch.io/pipoya-rpg-tileset-32x32 | itch.io download |

---

## License Summary

| Pack | License | Commercial Use | Attribution |
|------|---------|----------------|-------------|
| All Kenney packs | CC0 | Yes | Not required |
| bitglow packs | Custom | Yes | Not required |
| PIPOYA | Free use | Yes | Appreciated |
| CHROME DISTRICT | CC0 | Yes | Not required |
| Ultimate packs | CC0 | Yes | Not required |

All downloaded assets are safe for commercial use.
