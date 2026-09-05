# Game Dev Asset Pipeline Best Practices

## How Indie Devs Organize Assets

**Best practice: Type-first folder structure with metadata tagging**

```
Assets/
├── Characters/    (3D models, sprites, animations)
├── Environments/  (tiles, textures, props)
├── UI/            (panels, buttons, fonts, icons)
├── Audio/         (SFX, music, ambient)
├── VFX/           (particles, shaders)
└── Scripts/       (GDScript, shaders)
```

**Modern twist:** Pure folder structures are being supplemented by metadata tagging. An asset gets tagged (`#environment`, `#wood`, `#dungeon`, `#dorm`), allowing dynamic filtering instead of rigid directories.

---

## Most Commonly Reused Asset Types

| Asset Type | Reuse Rate | Why |
|---|---|---|
| **Furniture/props** | Very High | Tables, chairs, bookcases work everywhere |
| **UI elements** | Very High | Buttons, panels, dialogs — nearly universal |
| **Ambient audio** | Very High | Footsteps, doors, ambient room tone |
| **Vegetation/nature** | High | Trees, plants for outdoor scenes |
| **Textures** | High | Wood, stone, fabric — universal materials |
| **Characters (base meshes)** | Medium | Rigged characters can be re-posed/re-rendered |

---

## Best Practices for Converting Assets Between Engines

1. **Blender is the universal intermediate** — Export from Blender to GLB (Godot), FBX (Unity/Unreal), or OBJ (universal). Keep your source `.blend` files.
2. **Scale differences are real** — Blender uses meters, Unity uses centimeters, Godot uses meters.
3. **Material/shader conversion is manual** — No engine can directly transfer another engine's shaders.
4. **GLB is king for Godot** — Godot 4.7 has native GLTF/GLB support. FBX requires FBX2glTF conversion.
5. **Unity→Godot tool exists** — The `Unidot Importer` addon converts `.unitypackage` assets to Godot-native formats.

---

## Style Consistency When Mixing Assets

1. **Art Bible** — Define color palette, line weight, style rules, and reference images.
2. **Topic segregation** — Assign different asset categories to different artists/styles.
3. **Style constraints as a feature** — Severely constraining the art style naturally creates consistency.
4. **Post-processing unification** — Apply the same color grading, lighting, or shader effects to all assets.

---

## Most Underrated Free Asset Sources

### Tier 1: Production-Ready CC0 (Zero Legal Risk)

| Source | What's There | Why It's Great |
|---|---|---|
| **Kenney.nl** | 60,000+ assets | Single creator, consistent style, CC0 |
| **Poly Haven** | 3,400+ models, materials, HDRIs | Professional PBR quality, CC0 |
| **Quaternius** | Low-poly 3D model packs | Consistent style, CC0, pre-rigged |
| **Open Source 3D Assets** | 991+ GLB models | CC0, game-ready GLB format |
| **ambientCG** | 2,400+ PBR materials | All CC0, professional quality |

### Tier 2: Community-Driven

| Source | What's There | Watch Out |
|---|---|---|
| **OpenGameArt.org** | Massive 2D sprite library | License varies per asset |
| **itch.io assets** | Indie-focused, often "pay what you want" | Quality varies, check license |
| **Sketchfab** (free) | 500K+ free models | Filter by CC license |
| **Freesound.org** | 600,000+ sound effects | CC licenses vary |

### Tier 3: Professional Hidden Gems

| Source | What's There |
|---|---|
| **NASA 3D Models** | 27+ realistic space/science models (public domain) |
| **BBC Sound Effects** | 33,000+ free sound effects |
| **Internet Archive Audio** | 12+ million free audio recordings |
| **Poly Pizza** | 10,600+ free low-poly models |

---

## How Successful Indie Games Reuse Assets

### FromSoftware (Dark Souls, Elden Ring)
- Reuses animations, enemy models, and environmental assets across games
- **Key insight:** Reuse is acceptable when each game offers enough new content

### RGG Studios (Yakuza series)
- Reuses character models, city assets, and animations across entries
- **Key insight:** Redirected saved time into writing, gameplay, and polish

### Successful indie patterns:
1. **Kitbashing** — Take one furniture pack, recolor/tint for different contexts
2. **Modular building** — Combine walls/floors/windows into different room layouts
3. **Pre-rendered sprites from 3D** — One rigged character → unlimited sprite poses
4. **Shared audio libraries** — One ambient track works for multiple locations

---

## License Safety Guide

| License | Commercial Use | Attribution | Share-Alike | Risk |
|---|---|---|---|---|
| **CC0** | ✅ | ❌ | ❌ | Zero risk |
| **CC-BY** | ✅ | ✅ | ❌ | Low |
| **MIT/Unlicense** | ✅ | ❌ | ❌ | Zero risk |
| **CC-BY-SA** | ✅ | ✅ | ✅ | Medium — viral |
| **CC-BY-NC** | ❌ | ✅ | ❌ | **CANNOT USE** |

---

## For Project Chimera Specifically

### Current approach is industry-leading:
- All CC0 assets (Kenney + Quaternius)
- Consistent art style via single creator
- Blender-mediated rendering pipeline
- Clean folder structure

### Gaps to fill:
1. A few specialized asset packs for detective/mystery content
2. A style bible document
3. Audio pipeline expansion

### Recommended next steps:
1. Download `kenney_indoor-tiles` for floor/wall tiles
2. Download `quaternius_free_lowpoly_characters` for variety
3. Download `kenney_sounds` for UI click/hover sounds
4. Create asset audit spreadsheet tracking source, license, format
5. Build reusable prop library (re-render same furniture with different tints)
