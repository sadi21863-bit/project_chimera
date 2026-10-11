# Project Chimera — Complete Visual Redesign Research

**Research date:** 2026-09-25  
**Target:** Windows PC, AMD A9-9420 / Radeon R5 M330 2 GB / 7.5 GB RAM  
**Authoring/runtime stack named by the project:** Godot 4.7.2, GDScript, Blender 5.1.2  
**Scope:** art direction, 2D versus low-poly 3D, engine import, free and commercial sources, licensing, performance budgets, asset manifest, and a direction-neutral hero prototype. No game code changes are proposed or made here.

> This is production research, not legal advice. “Free,” “CC0,” a store category, and an itch.io download button do not by themselves prove that every file may be used, modified, committed, or shipped. Preserve the exact license and purchase record for every accepted asset.

## Executive recommendation

### Top direction: **Archival Cutaway** — bespoke 2.5D, pre-rendered, orthographic

Keep Godot 2D at runtime, but reject the current “assemble unrelated CC0 packs” approach. Rebuild the look as a **hand-inked institutional cutaway** whose rooms, characters, evidence markers, and UI share one authored visual language. Use Blender 5.1.2 offline as a modeling, staging, lighting, and orthographic-render tool; ship the result as controlled 2D atlases and layered sprites rather than live 3D.

This is the strongest option because it:

1. preserves the existing 2D navigation, schedule simulation, UI, and detective-mystery loop;
2. fits the target PC’s 2 GB graphics card and 7.5 GB system RAM much more safely than live 3D;
3. allows a complete visual reset without turning the project into a low-poly “toy” aesthetic;
4. expresses the story’s themes—records, intrusive observation, institutional spaces, conflicting accounts—through the art itself;
5. still uses Blender and free 3D kits productively, but moves their cost to the authoring machine instead of the runtime budget.

**Do not treat this as another tile-skin pass.** The defining deliverable is a bespoke room-and-character style frame. Kenney, Quaternius, KayKit, ambientCG, and Poly Haven are blockout, source, material, or reference inputs—not the final identity by default.

### When live low-poly 3D is justified

Keep a controlled live-3D spike, but do not migrate until one room passes all of these gates on the actual target PC:

- 60 FPS median at 1280×720 in a release build, with six animated NPCs;
- no sustained frame above 25 ms during a ten-minute 4× simulation soak;
- at most 120,000 visible triangles, 100 draw calls, 16 shared materials, and one shadow-casting light;
- less than 1.0 GB video memory and less than 2.0 GB game working set while the local AI path is active;
- load time under eight seconds for the room;
- a clear visual or gameplay advantage over the pre-rendered version that offsets the migration and art cost.

If any hard gate fails, use Archival Cutaway. The fallback is not failure; it is the lower-risk way to deliver a coherent game on the stated hardware.

## Evidence labels used in this note

- **Verified:** confirmed from a first-party engine, vendor, creator, or license page on 2026-09-25.
- **Project-derived:** a recommendation or budget based on this project, not a vendor guarantee.
- **Manual check:** dynamic price, availability, product-specific terms, target-driver behavior, or a conflicting source must be checked again before acceptance.
- **Not established:** evidence was insufficient; do not turn this into a factual assumption.

## 1. Current project constraints and visual diagnosis

### 1.1 Verified project facts

- **Godot 4.7.2 is a real current maintenance release.** Godot published 4.7.2 on 2026-08-18 and recommends it over 4.7.1.  
  <https://godotengine.org/article/maintenance-release-godot-4-7-2/>
- **Blender 5.1.2 is a real corrective release.** Blender published 5.1.2 on 2026-05-19 with 12 additional fixes.  
  <https://www.blender.org/download/releases/5-1/>
- The project identifies itself as a 2D isometric dorm simulation with six autonomous NPCs at `godot/project.godot:18`.
- The project currently selects the **Forward+** renderer at `godot/project.godot:20`.
- The project uses a 1280×720 base viewport and `canvas_items` stretch at `godot/project.godot:54`.
- Direct Blender import is disabled at `godot/project.godot:72`.
- A global detective theme resource is assigned at `godot/project.godot:76`.
- The existing performance note targets 60 FPS, fewer than 50 draw calls, and less than 8 ms of physics at `docs/performance-notes.md:31`.
- The story is specifically about an outsider turning an accidental death into a suspected murder, and about institutions shaping the accepted story. The visual redesign should express that theme rather than merely decorate a dorm.

### 1.2 What is wrong with the current look

The audit screenshots at `godot/qa/captures/dorm.png`, `godot/qa/captures/dialogue.png`, `godot/qa/captures/case_panel.png`, and `godot/qa/captures/cinematic.png` show a coherent set of failure modes:

1. **The world is mostly empty gray field.** The actual floor plan is pushed into a small lower band rather than acting as the main stage.
2. **The floor reads as a flat brown grid.** There is no architectural cutaway, material hierarchy, or visual reason for room boundaries.
3. **Characters are too small and low-contrast.** The player cannot quickly distinguish people, evidence, and room labels.
4. **The UI resembles debug rectangles.** Borders, placeholder-like labels, and oversized empty panels do not feel like a designed product.
5. **Dialogue and cinematic overlays crush the world into near-black.** Important information becomes low-contrast gray-on-black.
6. **The furniture montage at `asset_montage.png` exposes broken or noisy topology and arbitrary material colors.** Those meshes can be blockouts, not final assets.
7. **The cast has no shared identity beyond sprite substitution.** Different source packs produce mismatched silhouettes, proportions, outlines, and detail density.
8. **The current asset pipeline optimizes for “available” rather than “approved.”** That explains why unrelated packs accumulated without producing a coherent style.

The redesign must therefore replace the **whole visual system**: world art, characters, camera language, palette, lighting, typography, icons, panels, transitions, evidence presentation, and accessibility—not only the tileset.

## 2. Three viable visual directions

These are deliberately different in camera, rendering method, and mood. All three can represent the mystery, but they imply different production systems.

---

## Direction A — **Archival Cutaway**

**Core fantasy:** the dorm is an institutional evidence model that the detective physically intrudes upon. The player sees rooms as a rebuilt cutaway diagram, while the cast appears as authored, hand-inked figures inside it.

### Art direction

- Combine architectural drafting, photocopy texture, dry ink, matte gouache, and restrained halftone.
- Give every room a distinct institutional function through material and shape, not just color:
  - kitchen: enamel, steel, tile grids;
  - bedrooms: worn textile, painted wall panels, private clutter;
  - hallway: linoleum, doors, cameras, noticeboards;
  - common room: fabric, laminate, shelves, bulletin layers;
  - police/university spaces if revisited: concrete, fluorescent panels, labeled storage.
- Use a consistent light direction and contact shadow so pre-rendered props and characters feel physically placed.
- Reject toy proportions and default glossy low-poly materials. Source low-poly kits may be restyled into grounded adult silhouettes with longer coats, institutional footwear, asymmetrical bags, and visible props.

### Camera

- Fixed or gently snapping **orthographic isometric** camera.
- Compose the full dorm as a shallow architectural relief at 1280×720; do not leave half the viewport as unused gray space.
- Allow room focus with small pans and modest zoom, not free rotation.
- Separate background, floor/characters, foreground occluders, evidence highlights, and UI into deterministic depth layers.
- Preserve enough top-down information to support schedule observation and NPC pathfinding.

### Palette

| Role | Suggested color | Use |
|---|---:|---|
| Carbon ink | `#111820` | outlines, deepest occlusion, primary text |
| Blueprint slate | `#293B49` | walls, shadow masses, HUD surfaces |
| Dirty paper | `#D8D0BE` | UI paper, labels, evidence cards |
| Institutional green | `#687C6D` | floors, room accents, neutral state |
| Sodium amber | `#D99A4D` | practical light, interactable cues, warmth |
| Evidence red | `#A6403D` | contradiction, accusation, danger—not routine “selected” |
| Faded teal | `#4E7778` | police/university institutional identity |

**Value rule:** most of the frame stays in low-to-middle value; faces and evidence receive the brightest local contrast. Do not communicate evidence state by red/green alone; pair color with icon, border pattern, label, and motion.

### Materials and rendering

- Runtime: 2D atlases, layered room plates, character sprites, decals, and light/shadow masks.
- Authoring: Blender can generate low-poly props, orthographic cameras, contact shadows, and consistent lighting; Krita can repaint, ink, and composite the result.
- Prefer 2–3 painted value bands per character over noisy texture detail.
- Bake lighting into the source render. Do not multiply every room by a full-screen day/night tint; use authored dusk/night variants or selective masks.

### Lighting

- Cool ambient fill from windows and corridors.
- Warm sodium practicals in kitchens, common areas, and the evidence scene.
- Strong contact shadows under characters and large props.
- Day/night changes should affect pools of light and color temperature while preserving minimum character readability.
- No runtime light accumulation or expensive full-screen post effects in the 2D target.

### Characters and motion

- Seven active characters plus Daniel: detective, Alex, Jordan, Sam, Riley, Morgan, and Casey.
- Each needs a unique silhouette readable at 80–110 screen pixels: hair/head shape, shoulder line, bag, posture, and one identifying prop.
- Four-direction idle/walk coverage is sufficient for the schedule loop. Add talk, point, and evidence-hand-over states before adding emotes.
- Pre-rendered Blender turnarounds can provide consistent 3D volume, but the final frames should be repainted in 2D so faces and silhouettes do not become generic low-poly toy art.

### UI and typography

- Use an **archival case-filing system**, not a generic RPG menu:
  - top rail: day/time and current objective;
  - left edge: compact evidence/notebook/board/map navigation;
  - world overlays: evidence tags that can be pinned to objects;
  - case file: full-screen evidence cards with source, timestamp, contradictions, and confidence;
  - dialogue: portrait, name/role, transcript body, and evidence-topic controls.
- Recommended open fonts:
  - Atkinson Hyperlegible Next for body/UI legibility;
  - Source Serif 4 for case headings and evidence quotations.
- Avoid full-screen black scrims. Use a blurred/desaturated world plate plus a solid paper or slate panel.
- Controls should remain keyboard, mouse, and controller navigable. Use 18–20 px body text and 44 px minimum targets at the 720p reference.

### Production tradeoffs

**Advantages**

- Best hardware fit and lowest runtime risk.
- Preserves the existing simulation architecture.
- Can look bespoke even when the source 3D is inexpensive.
- Strong fit for evidence, records, and institutional distortion.

**Costs**

- Requires disciplined 2D composition and custom cleanup; stock tiles cannot carry the identity.
- Camera changes are limited compared with live 3D.
- Large room plates and many sprite directions create authoring and atlas-management work.
- Parallax and lighting transitions need deliberate masks rather than free camera movement.

**Best when:** the priority is a complete, polished, distinctive mystery game on the stated minimum PC.

---

## Direction B — **Civic Model** — live low-poly 3D cutaway

**Core fantasy:** the dorm is a physical reconstruction under investigation. The player moves around a precise architectural model, and the cast are simplified human markers within it.

### Art direction

- Use stylized realism, not cute toys: restrained proportions, readable hands/faces, grounded clothing, institutional props.
- Treat architecture as the hero. Rooms should be recognizable from floor plan, wall rhythm, furniture layout, and material wear.
- Use a limited set of shared PBR materials and vertex-color wear rather than many unique high-resolution textures.
- Evidence objects receive a single high-contrast practical material so the eye knows what matters.

### Camera

- Orthographic 3/4 cutaway camera with fixed room angles and smooth transitions.
- Wall fading or roof removal communicates the cutaway.
- Limited camera yaw and dolly are acceptable; free third-person control is unnecessary and would hide the authored composition.
- The 2D navigation layer would need a later 3D-navigation migration; that cost is a major reason to prototype rather than commit.

### Palette

| Role | Suggested color | Use |
|---|---:|---|
| Concrete | `#6B7073` | primary architecture |
| Faded teal | `#3F5F60` | institutional paint and trim |
| Bone | `#C9C1AE` | floors, paper, neutral props |
| Evidence red | `#B6463F` | contradiction pins and scene markers |
| Emergency amber | `#D8A04A` | practicals and warnings |
| Near black | `#15191C` | structural outlines and occlusion |

### Materials and lighting

- Use `StandardMaterial3D` with mostly shared albedo/roughness resources.
- Flat or lightly smoothed normals; no clearcoat, refraction, expensive rim lighting, or high-frequency normal maps.
- Compatibility-renderer baseline:
  - one directional or spot shadow at most;
  - additional practical lights without shadows;
  - baked ambient/lightmap or vertex-color fill where possible;
  - no SSAO, SDFGI, clustered-light assumptions, or high-resolution shadow cascades.
- Prefer alpha-tested foliage/glass over alpha blending.

### UI

- Evidence pins and contradiction lines live in 3D; the notebook and case board remain 2D.
- Labels use restrained blueprint annotation, not floating game-store badges.
- A room-focus overlay can replace the top bar with a clean objective and time strip.

### Production tradeoffs

**Advantages**

- Real camera transitions, occlusion, doors, vertical geometry, and future location expansion.
- Lighting and material changes can happen at runtime.
- Strong “forensic reconstruction” concept if the art is authored rather than assembled from kits.

**Costs**

- Highest migration and QA cost.
- CPU, GPU, RAM, lighting, and import complexity are all materially higher.
- A large imported scene can undermine the target’s stability before gameplay work begins.
- Stock low-poly models tend to pull the project toward the rejected “toy diorama” look unless heavily restyled.

**Best when:** the 3D performance gate passes and the team values spatial camera freedom enough to pay for a 3D navigation/import migration.

---

## Direction C — **Rain on Glass** — layered graphic 2D

**Core fantasy:** the player observes a living building through obstructing glass, rain, venetian shadows, doorframes, and remembered flashes. The world is cinematic, but the investigation remains a record of partial observations.

### Art direction

- Graphic-novel cut-paper silhouettes, dry-brush textures, photocopy grain, hard blacks, and selective pools of light.
- Characters are larger and more expressive than in Archival Cutaway, but faces are frequently obscured by glass, glare, or shadow.
- Use repeated visual motifs: half-open doors, taped windows, streaked reflections, framed photographs, and redacted pages.
- Rain and memory effects must support meaning rather than obscure all interaction.

### Camera

- Near-orthographic side or shallow-oblique elevation rather than top-down isometric.
- Horizontal room-to-room panning with three or four parallax planes.
- A limited “lean past the obstruction” move for key evidence, not free 3D movement.
- This reduces whole-dorm overview and makes schedule-based NPC discovery slower, so the game must compensate through stronger schedule cues and a clear whereabouts panel.

### Palette

| Role | Suggested color | Use |
|---|---:|---|
| Ink black | `#0B1016` | silhouettes and frame |
| Blue black | `#182637` | interior depth |
| Dirty ivory | `#D8D0BF` | evidence and dialogue paper |
| Sodium orange | `#F0A044` | practical lights and immediacy |
| Police blue | `#426A8C` | institutional pressure |
| Blood red | `#A83236` | irreversible accusation |

### Materials and UI

- Matte ink and paper rather than rendered PBR realism.
- Lighting becomes animated masks, gradients, and shadow shapes.
- The case board is the visual center when the player needs certainty; the world is intentionally uncertain.
- The dialogue layout resembles annotated interview transcripts with portrait fragments and redactions.

### Production tradeoffs

**Advantages**

- Strong, memorable identity with no live-3D performance cost.
- Can use 2D transitions and compositing to make ordinary dorm spaces feel cinematic.
- Existing 2D systems remain useful.

**Costs**

- Character animation and multi-plane redraw are expensive.
- Darkness can destroy readability on a low-quality display.
- Whole-floor schedule observation is weaker than isometric.
- The direction demands original art more than either alternative; stock packs will not carry it.

**Best when:** graphicnovel atmosphere is more important than always seeing the entire simulated floor at once.

---

## 3. Direction comparison

Scores are **project estimates, not measured results**, on a 1–5 scale.

| Criterion | Weight | Archival Cutaway | Civic Model | Rain on Glass |
|---|---:|---:|---:|---:|
| Target-PC safety | 25% | 5 | 2 | 5 |
| Existing-system fit | 20% | 5 | 1 | 4 |
| Mystery/story fit | 20% | 5 | 5 | 4 |
| Distinctiveness | 15% | 4 | 5 | 5 |
| Production throughput | 10% | 3 | 2 | 2 |
| Camera flexibility | 10% | 2 | 5 | 3 |
| **Weighted estimate** | 100% | **4.45** | **3.20** | **4.15** |

**Decision:** prototype Archival Cutaway and Civic Model with the same room content. Produce Rain on Glass as a short motion/compositing study rather than a full third engine spike unless the first two fail the subjective brief.

## 4. Target hardware and renderer strategy

### 4.1 Verified hardware facts

- AMD’s official Radeon R5 M330 page identifies it as a legacy product with 5 compute units, boost up to 1030 MHz, DDR3 memory, a 64-bit bus, OpenGL 4.4, and DirectX 12 listed. It also says the product is on legacy support and its last listed Windows driver is from 2022.  
  <https://www.amd.com/en/support/downloads/drivers.html/graphics/radeon-r9-r7-r5/radeon-r5-300-series/amd-radeon-r5-m330.html>
- AMD’s page lists a maximum memory size of 4 GB for the family, but the user-supplied board has 2 GB. The exact board memory and active driver must be verified on the machine; do not substitute the family maximum for the actual device.
- AMD’s feature list does not list Vulkan. **Manual check:** do not assume Vulkan/D3D12 behavior from marketing labels; test the actual installed driver.
- Godot 4.7’s Compatibility renderer is explicitly the low-end option, uses OpenGL, supports 2D and core 3D, and targets older desktops that may lack Vulkan.  
  <https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html>
- Godot’s minimum-style system table lists 4 GB RAM for the native editor. The 7.5 GB target leaves room for the game, but not for careless asset loading plus a concurrent local AI process.  
  <https://docs.godotengine.org/en/4.7/about/system_requirements.html>

### 4.2 Renderer recommendation

- **Archival Cutaway and Rain on Glass:** remain 2D. The renderer choice is less important than texture count, overdraw, and UI scaling.
- **Civic Model:** start the spike in **Compatibility**, not Forward+. Godot 4.7 can fall back when RenderingDevice support is unavailable, but fallback can look different; an explicit prototype avoids learning the visual result only after export.
- Keep 1280×720 as the art and performance reference. Test 1366×768 and 1920×1080 output, but do not accept a design that only works at 4K.
- Preserve `canvas_items` stretch and use anchored UI. Godot’s 4.7 documentation recommends `canvas_items` + `expand` for multi-aspect 2D/UI and separately exposes 3D resolution scaling.  
  <https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html>  
  <https://docs.godotengine.org/en/4.7/tutorials/3d/resolution_scaling.html>

## 5. Official Godot asset discovery and import workflow

### 5.1 Godot 4.7 has both the legacy Asset Library and a new beta Asset Store

**Verified:** Godot 4.7 introduced a new Asset Store integrated into the editor. The old Asset Library remains online, and old entries were not migrated automatically. The new store is a successor, not a second license authority.

- Asset Store overview: <https://docs.godotengine.org/en/4.7/community/asset_store/what_is_asset_store.html>
- In-editor use: <https://docs.godotengine.org/en/4.7/community/asset_store/using_in_editor.html>
- Current store roadmap/help: <https://store.godotengine.org/roadmap/> and <https://store.godotengine.org/help/>
- Legacy Asset Library: <https://godotengine.org/asset-library/asset>

**Current-state caveat:** the roadmap says only free assets can currently be published. Recheck before assuming paid availability.  
**License caveat:** the platform terms say providers retain ownership and grant users a broad license to use, integrate, and modify content; some content can have additional written terms. Read the product listing and included license.  
<https://store.godotengine.org/terms/>

The Asset Library documentation says the in-editor browser only returns assets for the current engine version. The old listing “2D Isometric Demo” still appears as a 3.5 asset even though the official demo repository contains a 4.7 version. Use the repository’s current 4.7 project rather than assuming the listing badge is current:

- Asset Library listing: <https://godotengine.org/asset-library/asset/112>
- Official Godot 4.7 demo: <https://github.com/godotengine/godot-demo-projects/tree/4.7/2d/isometric>

### 5.2 Import rules that apply regardless of source

1. Place source files in the Godot project or drag them into the FileSystem dock.
2. Godot imports supported files and stores generated resources under `.godot/imported/`; runtime code should load the imported resource, not read the source file with `FileAccess`.  
   <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/import_process.html>
3. Use the Import dock for project-wide defaults, the Advanced Import dialog for per-object mesh/material settings, and inherited scenes when source changes should not be overwritten.  
   <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html>
4. Record source, license, version, author, download date, modifications, and redistribution status **outside the imported resource**.
5. Keep paid or redistribution-restricted raw files out of public repositories unless the exact license and repository visibility allow it.
6. A Godot PCK is a container, not a legal boundary. If a license forbids standalone or separable raw assets, obtain a specific answer before shipping open source formats inside it.

### 5.3 2D import rules

Godot’s image documentation states:

- Lossless is the normal 2D choice, but lossless/lossy WebP textures are still uncompressed on the GPU.
- VRAM compression is intended for 3D and can visibly damage 2D art.
- Mipmaps add roughly 33% memory and are normally unnecessary for fixed-scale 2D.

Source: <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html>

**Archival Cutaway import policy**

- Use linear filtering for painterly/vector art.
- Use nearest filtering and integer scaling only if a deliberately pixel-art subfamily is approved.
- Mipmaps off for UI, portraits, and fixed-scale sprites.
- Mipmaps on only for a world layer that is repeatedly minified and visibly benefits.
- Extract textures when external control is needed; verify alpha edges and premultiplication.
- Pack characters and small props into 2048×2048 atlases. Use 4096×4096 only after measuring.
- Keep the authored 1280×720 layer separation even if individual props are atlased.

For tilemaps, Godot 4.7 uses `TileMapLayer`; the old `TileMap` node is deprecated. Multiple layers are the intended organization, and isometric TileSets work best with Y-sort.  
<https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilemaps.html>  
<https://docs.godotengine.org/en/4.7/classes/class_tilemaplayer.html>

### 5.4 3D import rules

Godot 4.7 officially lists:

- **glTF 2.0 / GLB as recommended**;
- FBX through `ufbx`;
- `.blend` through an installed Blender executable;
- COLLADA;
- OBJ, with major limitations.

USD is not listed in the reviewed Godot 4.7 native scene-format list. Convert USD to GLB/FBX or import it in Blender and export a supported format.

Source: <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html>

Godot’s exporter documentation recommends triangulating before export, applying transforms where appropriate, and designing lighting in Godot for live scenes.  
<https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.html>

**Project policy:** keep Blender direct import disabled. Export reviewed GLB files into the Godot project. This avoids requiring every contributor to install a specific Blender build and keeps imported results reproducible. It also matches the current project setting.

## 6. Recommended 2D production pipelines

| Tool | Best use in Chimera | License/output caveat | Primary source |
|---|---|---|---|
| **Krita** | room concept paintings, material studies, UI comps, portraits, cleanup, frame-by-frame 2D animation | GPLv3 applies to the application; artwork created with it remains the artist’s property and may be commercial | <https://krita.org/en/about/license/> |
| **Aseprite** | tightly controlled pixel/cel animation, palettes, sprite sheets, JSON atlas export, CLI batching | Paid proprietary EULA; source is available, but redistributing compiled versions is restricted. Commercial artwork output is allowed | <https://www.aseprite.org/faq/> and <https://github.com/aseprite/aseprite/blob/main/EULA.txt> |
| **Aseprite CLI** | deterministic sheet generation, tag/range export, atlas JSON | Requires a lawfully installed/copied Aseprite binary; do not redistribute it in a build pipeline | <https://www.aseprite.org/docs/cli/> |
| **LibreSprite** | free GPL alternative for basic sprite editing | GPLv2; less actively evolving than the commercial original. Repository currently labels its latest release as pre-release, so treat as a secondary tool | <https://libresprite.github.io/> and <https://github.com/LibreSprite/LibreSprite> |
| **Tiled** | isometric/staggered maps, room layers, object markers, custom properties, batch export | Editor components have mixed GPL/BSD notices; the Tiled Godot 4 exporter assumes a shared project hierarchy. Output maps are project data, not Tiled code | <https://doc.mapeditor.org/en/stable/manual/maps/> and <https://doc.mapeditor.org/en/stable/manual/export-tscn/> |
| **Godot TileMapLayer** | final runtime map, collision/navigation/occlusion layers, Y-sort | Use external reusable TileSet resources and multiple layers | <https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilemaps.html> |

### 6.1 Painterly/pre-rendered Archival Cutaway flow

1. Blender: block out the room and furniture with metric scale and fixed camera.
2. Blender: use CC0/owned geometry only; restyle proportions, materials, and wear.
3. Blender/EEVEE or another offline renderer: render orthographic stills and turntables at the exact 2D projection.
4. Krita: clean silhouettes, repaint faces, unify palette, add ink and paper texture.
5. Aseprite or Krita animation: normalize frames, palette, pivots, and contact points.
6. Aseprite CLI, Krita export, or a deterministic image script: pack atlases and metadata.
7. Godot: lossless import, linear filter, no unintended mipmaps, external reusable TileSet/atlases.
8. Validate at native 1280×720 and in the full UI over the world.

### 6.2 Pixel-art flow

Pixel art is viable but should be a deliberate **sub-family**, not an accidental consequence of using 16×16 or 32×32 sources.

- Establish one pixel density, silhouette language, outline weight, and light direction.
- Do not mix 16×16 top-down furniture, 32×32 RPG sprites, and 56×84 cyberpunk sprites merely because all are “free.”
- If characters display around 96 px high, author or upscale to a deliberate target grid; do not use nearest-neighbor enlargement of 32×32 sprites as a final look.
- Use Aseprite/LibreSprite for animation and Krita only for large-area cleanup that preserves the pixel grid.

## 7. Recommended 3D production pipeline

### 7.1 Source organization

Use a source tree outside the Godot import scope, then export only approved deliverables. A practical conceptual layout is:

```text
art_source/
  licenses/
  manifests/
  blender/
    libraries/
    characters/
    environments/
    materials/
    lighting/
  raster/
    room_layers/
    characters/
    ui_source/
godot/assets/
  imported_source/    # reviewed GLB only for live-3D candidate
  2d/                # approved PNG atlases/layers
  fonts/
  ui/
```

The folders above are a recommended future workflow, not files created by this note.

### 7.2 Blender rules

1. Use real-world scale and a documented unit convention.
2. Keep source meshes, pivots, and names deterministic.
3. Apply transforms before delivery.
4. Triangulate export geometry where the toolchain requires it.
5. Check UVs, normal direction, tangents, texture paths, and alpha edges.
6. Use simple collision proxies; do not ship decorative topology as collision.
7. Author three LODs or let Godot generate and then visually validate them.
8. For live 3D, strip cameras/lights from the GLB and rebuild the small lighting set in Godot.
9. For pre-rendering, keep Blender lighting and export only the rendered result.
10. Keep high-resolution source files outside the exported game.

Blender’s own license page confirms that output artwork and `.blend` data remain the creator’s property and may be used commercially.  
<https://www.blender.org/about/license/>

### 7.3 glTF delivery

- Use **GLB** for compact final delivery.
- Use separate `.gltf + .bin + textures` for source review and version control when reviewing a diff matters.
- Khronos describes glTF as a royalty-free runtime format for 3D scenes and models. The format’s royalty-free status does **not** grant rights to the content stored inside it.  
  <https://www.khronos.org/gltf/>
- Validate every imported GLB in Godot’s Advanced Import screen before approving it.

## 8. Free and CC0 asset-source audit

### 8.1 Low-risk, broad CC0 sources

| Source | Recommended Chimera use | Verified terms and caveats | Exact URL |
|---|---|---|---|
| **Kenney** | UI/input glyph bases, blockout furniture, simple prop silhouettes, prototyping | Kenney says game assets on its asset pages are public-domain CC0. Preserve each included license. Do not mistake a CC0 pack for art that fits the approved direction. | <https://kenney.nl/support> |
| Kenney Furniture Kit | Blender room/prop blockout and collision planning | CC0; source page identifies a 3D furniture kit. Use as reference/proxy unless its toy style is explicitly approved. | <https://www.kenney.nl/assets/furniture-kit> |
| Kenney Mini Characters | temporary silhouettes and scale tests | CC0 site support; do not use as final cast if the style is rejected. | <https://kenney.nl/assets/mini-characters> |
| Kenney UI Pack / Input Prompts | starting panel shapes and control glyphs | CC0 site support. Restyle; avoid shipping a generic UI-pack look unchanged. | <https://kenney.nl/assets/ui-pack> and <https://kenney.nl/assets/input-prompts> |
| **Quaternius** | architectural blockouts, furniture, city context, character mannequins, animation tests | Current pack pages describe personal/commercial CC0 use, but availability varies by free/source/supporter tier. Save the license from the exact downloaded pack. | <https://quaternius.com/> |
| Quaternius Universal Base Characters | Blender mannequin family for pre-render silhouettes; possible live-3D base after optimization | Current page says average 13k triangles, FBX/glTF, humanoid rig, and CC0. 13k is too high as an unquestioned target for six live characters on this PC; pre-render or decimate. | <https://quaternius.com/packs/universalbasecharacters.html> |
| Quaternius Furniture Pack | bed, chair, table, shelving blockout | Current page says free for personal/commercial use and FBX/OBJ/Blend. Exact pack license must still be saved. | <https://quaternius.com/packs/furniture.html> |
| Quaternius Downtown City MegaKit | university/police/campus context and later exterior scenes | Current page describes CC0, GLB/GLTF/FBX/OBJ options and tiered availability. Check the current file list before relying on a particular module. | <https://quaternius.com/packs/downtowncitymegakit.html> |
| **KayKit Furniture Bits** | fast low-poly room dressing source | Current itch page says free for personal/commercial use, no attribution required, CC0; OBJ/FBX/GLTF. | <https://kaylousberg.itch.io/furniture-bits> |
| **KayKit Restaurant Bits** | kitchen appliances, food, counters, clutter | Current page says free CC0, 140+ models, OBJ/FBX/GLTF. | <https://kaylousberg.itch.io/restaurant-bits> |
| **KayKit City Builder Bits** | campus road/building/prop blockout | Current page says free CC0, 32+ models, OBJ/FBX/GLTF. | <https://kaylousberg.itch.io/city-builder-bits> |
| **KayKit Adventurers** | rigged mannequin/animation tests only | Current page says free CC0 with FBX/GLTF and basic animation, but the fantasy silhouette is not automatically suitable for a grounded dorm mystery. | <https://kaylousberg.itch.io/kaykit-adventurers> |
| **Poly Haven** | offline HDRI references, physically plausible lighting studies, select texture detail | All HDRIs, textures, and models are CC0. Asset files require no attribution. The **live API** has a separate attribution condition; downloading files does not automatically invoke the API terms. | <https://polyhaven.com/license> and <https://polyhaven.com/our-api> |
| **ambientCG** | wood, plaster, concrete, tile, fabric, and floor material source | All downloadable files and previews are CC0. Current repackaging includes Godot `.tres` files, but build them yourself from controlled source maps for predictable import settings and memory. | <https://ambientcg.com/license> and <https://docs.ambientcg.com/updates/2025/10/18/repackaging-of-nearly-all-assets-on-ambientcg/> |

### 8.2 Conditional or per-item sources

| Source | Viability | Current terms and caveats | Exact URL |
|---|---|---|---|
| **Blendkit**, formerly BlenderKit | Useful for realistic props, materials, and Blender-native references; not a blanket CC0 library | Current user terms effective 2026-06-12 allow Royalty-free or CC0 per product. Both allow commercial games; Royalty-free forbids reselling the asset/model. For software, the product must not expose/separate the open 3D asset. Its FAQ expressly permits making 2D renders. **Manual check:** use pre-rendered output unless counsel or the creator confirms raw 3D inside a Godot PCK. | <https://www.blendkit.com/terms-and-conditions-2026/> and <https://www.blendkit.com/docs/licenses/licensing-faq/> |
| **Sketchfab** | Useful for one-off hero props with clean topology | License is per model. Free downloads may use Creative Commons or Standard terms. CC BY can be commercial but requires credit/change notice; NC, ND, and SA restrictions may apply. Standard terms are broader. Never infer terms from the word “free.” | <https://sketchfab.com/licenses> and <https://sketchfab.com/terms> |
| **itch.io** | Excellent for bespoke 2D/3D packs; terms are entirely creator-defined | The platform is a storefront, not a blanket asset license. Preserve the product page and included license. Free/name-your-own-price does not imply CC0. | <https://itch.io/docs/creators/getting-started> and <https://itch.io/docs/creators/pricing> |
| **OpenGameArt** | Broad 2D source; high per-submission variance | The site FAQ says art can be commercial if its listed terms are followed. CC0, CC BY, OGA BY, CC BY-SA, and GPL have materially different obligations. Prefer CC0/CC BY/OGA BY for this project; avoid GPL-labeled art and NC/ND/SA unless legal review approves. | <https://opengameart.org/content/faq> |
| **Godot Asset Store/Library** | Addons, tools, demos, templates; occasional art | Product license controls. New store is beta and currently free-only according to its roadmap. Inspect included source and license; do not install unreviewed addons into the main project. | <https://store.godotengine.org/> and <https://godotengine.org/asset-library/asset> |

### 8.3 KayKit Mystery characters: relevant but not free

KayKit’s current **Mystery Monthly Series 6** page describes 14 current-style rigged/animated characters and lists CC0 rights, but it is a paid product, not part of the free furniture/city range. It may be a useful optional character source if the budget and exact checkout terms are approved.

- <https://kaylousberg.itch.io/kaykit-series-6>

No price is reproduced in this note because store pricing can change and must be checked at acquisition time.

### 8.4 Do not call CC0 “zero legal risk”

The official CC0 deed permits copying, modification, distribution, and commercial use, but it also states that Creative Commons has not verified every work’s copyright status and that patents, trademarks, publicity, privacy, and similar rights may remain. Treat CC0 as **low risk with provenance requirements**, not an unconditional warranty.  
<https://creativecommons.org/publicdomain/zero/1.0/>

## 9. Existing Project Chimera asset audit

### 9.1 Inventory is not provenance

`godot/assets/asset_manifest.json` inventories path, size, hash, and import state. It does **not** record source URL, author, license text, purchase receipt, or redistribution status. It cannot serve as the rights manifest.

At audit time:

- `asset dump/` is ignored by Git, which is appropriate for raw downloads but means provenance can disappear locally.
- `godot/assets/` contains many untracked derived/source files.
- Only a small subset of discovered files had an adjacent license file.
- A full per-file source/license audit is required before the next public repository push or release build.

### 9.2 Existing pack disposition

| Existing material | Verified evidence | Disposition |
|---|---|---|
| Kenney icon pack | Local `godot/assets/2d/kenney_icons/license.txt` says CC0 | **Candidate**, but restyle and record source/version |
| Quaternius Ultimate House Interior | Local extracted `License.txt` says CC0 1.0 | **Candidate source/blockout**; FBX, not the preferred runtime interchange |
| Quaternius Ultimate Animated Character Pack | Local extracted `License.txt` says CC0 1.0 | **Reference/mannequin only**; replace generic faces and silhouettes |
| Bitglow interior packs | Current pages and local files use a custom license: commercial use allowed; modification allowed; no resale, standalone redistribution, resource-pack inclusion, or sharing outside the project team | **Hold for repository/distribution policy.** Keep the exact license with any accepted files. Do not commit raw files to a public repository without written clarification. |
| PIPOYA characters/tiles | Current itch pages allow commercial/personal use and modification, but forbid redistributing/reselling the assets; these are **not CC0** | **Reference-only for the recommended direction.** Preserve exact page/license; do not put raw sheets in a public asset repository. |
| Chrome District | Local `LICENSE` says PNG+JSON are CC0, while the current itch page metadata says CC BY 4.0 and the page says AI-assisted graphics | **Hold.** Ask the creator to resolve the metadata conflict. The cyberpunk style is not the top recommendation anyway. |
| Generated furniture shown in `asset_montage.png` | Local visual evidence; noisy triangulation and arbitrary materials | **Replace as final art; retain only as collision/scale blockout if useful** |
| Existing dark UI/cinematic captures | Local visual evidence; low contrast and debug-like composition | **Replace as a visual system; preserve functional layout requirements only** |

Exact current pages:

- Bitglow living/kitchen: <https://bitglow.itch.io/pixelinterior-livingroomkitchen>
- Bitglow bedroom: <https://bitglow.itch.io/pixelinterior-bedroom>
- Bitglow bathroom: <https://bitglow.itch.io/pixelinterior-bathroom>
- PIPOYA characters: <https://pipoya.itch.io/pipoya-free-rpg-character-sprites-32x32>
- PIPOYA tiles: <https://pipoya.itch.io/pipoya-rpg-tileset-32x32>
- Chrome District: <https://booliebuilds.itch.io/chrome-district>

The earlier local report’s statement that “all downloaded assets are safe for commercial use” at `docs/free-assets-report-2026-08-06.md:128` is too broad. Commercial game use and redistribution are different rights, and some current/local terms are custom or conflicting.

## 10. Commercial stores and Godot viability

| Store | Godot viability | Import rule | License caveat |
|---|---|---|---|
| **Godot Asset Store** | Highest for Godot-native addons, tools, demos, and templates | Install archive; Godot imports contained resources | Beta; current roadmap says free-only. Product terms and included license control. Do not equate “Godot asset” with art ownership. |
| **Fab** | High for generic source assets | Prefer FBX, GLB/glTF, OBJ, PNG/TGA/EXR. Convert USD to a Godot-supported format if needed. Unreal `.uasset`, Blueprints, Niagara, MetaHuman packages, and engine shaders are not portable. | Current Fab Standard summary allows commercial/private use, modification, distribution inside projects, and use with any compatible tool. No standalone redistribution; no credit required. Legacy UE Marketplace license may still apply to migrated listings. |
| **Unity Asset Store** | Viable for generic FBX/OBJ/textures/audio, but high due diligence | Re-export raw interchange files. Unity packages, prefabs with scripts, Shader Graph assets, ScriptableObjects, editor extensions, and C# tools are not Godot-compatible. | Current standard EULA grants a broad embedded-product license and does not itself state that the asset must be used with Unity. Provider-specific terms and Restricted Asset terms override; “intended purpose” and seat limits still apply. |
| **Unreal Marketplace** | It is now Fab; treat as the same service | Prefer source/exchange files. Do not buy an Unreal-only package merely because it is available through the successor store. | Some legacy listings remain under the UE Marketplace License until migrated. Check the listing’s license section. |
| **itch.io** | High for engine-neutral source packs; variable quality | Prefer PNG, SVG, PSD, KRA, FBX, GLB, OBJ, Blend, WAV/OGG, and documented JSON. | Creator-defined. Save the page, included license, version, and receipt. |

Primary sources:

- Fab Standard License and non-binding summary: <https://www.fab.com/eula>
- Fab license types and legacy migration note: <https://dev.epicgames.com/documentation/fab/licenses-and-pricing-in-fab>
- Fab accepted formats: <https://dev.epicgames.com/documentation/fab/asset-file-format-and-structure-requirements-in-fab>
- Unreal Marketplace redirect: <https://www.unrealengine.com/marketplace/en-US/>
- Unity Asset Store EULA: <https://unity.com/legal/as-terms>
- itch creator documentation: <https://itch.io/docs/creators/getting-started>

### 10.1 Store-selection policy

1. Buy only after confirming a **source/interchange file** is included.
2. Prefer Standard/CC0/CC BY or a clearly commercial custom license.
3. Reject any product whose value depends on an engine-only shader, blueprint, prefab graph, or editor extension.
4. Do not commit paid raw assets to source control by default.
5. Keep the receipt and license in a private provenance store; include only what the final license requires in the shipped notices.
6. Re-check price and availability manually. This note intentionally does not reproduce dynamic store prices.

## 11. Performance and memory budgets

All numeric limits in this section are **project-derived acceptance budgets**, not manufacturer guarantees. First measure a release build on the exact target PC.

### 11.1 Frame budget

At 60 FPS, one frame has 16.67 ms. The existing project already aims for fewer than 50 draw calls, so preserve that target for 2D.

| Measurement | 2D target | Live-3D gate |
|---|---:|---:|
| Median frame rate at 1280×720 | 60 FPS | 60 FPS |
| 1% low frame time | ≤ 22.2 ms | ≤ 22.2 ms |
| No sustained frame | > 25 ms | > 25 ms |
| Draw calls | < 50 | < 100; hard stop 150 |
| Game-thread frame time | ≤ 10 ms average | ≤ 10 ms average |
| Physics | < 8 ms, matching current note | < 8 ms |
| Scene load | < 3 s | < 8 s |
| Ten-minute 4× soak | no growth or hitch pattern | no growth or hitch pattern |

Godot exposes draw-call and video-memory monitors, and its documentation recommends profiling a representative release build rather than guessing.  
<https://docs.godotengine.org/en/4.7/classes/class_performance.html>  
<https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html>

### 11.2 Texture budgets and memory arithmetic

Godot states that only VRAM-compressed textures materially reduce GPU memory; lossless/lossy textures remain uncompressed on the GPU. Mipmaps add roughly 33%.

| Uncompressed RGBA texture | Base size | With mipmaps |
|---|---:|---:|
| 1280×720 | 3.52 MiB | 4.69 MiB |
| 2048×2048 | 16 MiB | 21.33 MiB |
| 2560×1440 | 14.06 MiB | 18.75 MiB |
| 4096×4096 | 64 MiB | 85.33 MiB |

**Project budgets**

- 2D texture residency: **≤ 512 MiB** total.
- Live-3D texture residency: **≤ 600 MiB** total.
- Mesh/vertex and render-buffer budget for live 3D: **≤ 250 MiB**.
- Total Godot-reported video memory: **warning at 900 MiB; hard stop at 1.0 GiB** on the 2 GB target.
- No runtime 4K texture unless a measured close-up requires it.
- 2048 maximum for normal 3D materials; 1024 for most props; 2048 for one hero material family.
- No more than 16 shared live-3D materials; no unique material per prop.
- 2D atlases: default 2048 maximum, 4096 only with measured need.

### 11.3 2D geometry/animation budgets

- 7 active characters plus Daniel; background residents may be silhouettes or palette variants until the cast is proven.
- Target active-character display height: 80–110 px at 1280×720.
- One 2048 atlas per character family or a small number of shared atlases.
- Four directions; 4–8 frames per walk; idle breathing through 2–4 frames or subtle transform animation.
- Avoid full-screen animated grain. Use one static grain texture and at most one low-resolution moving weather layer.
- Prefer many sprites sharing a texture/material over unique draw state. Godot documents 2D batching as the primary way to reduce draw calls.  
  <https://docs.godotengine.org/en/4.7/tutorials/performance/gpu_optimization.html>

### 11.4 Live-3D hard gates

- Visible triangles per room: **80,000–120,000**.
- Active character mesh: **≤ 8,000 triangles**, with simple 20–32 bone rigs if possible.
- Room prop: usually **100–1,500 triangles**; hero evidence prop maximum 5,000.
- LODs: 100%, 50%, and 25%; visually validate transitions.
- One shadow-casting light maximum; 1024 shadow map initially, 2048 only if measured necessary.
- Additional Omni/Spot lights without shadows; distance-fade/cull distant ones.
- No expensive transparency; no large overlapping alpha volumes.
- No SSAO, SDFGI, or advanced post stack in the Compatibility candidate.
- Bake static lighting where practical, but verify the exact look because Compatibility uses a different lighting path from Forward+.

Godot’s Compatibility architecture uses a multi-pass path for shadowed lights and recommends only a handful in view. It also documents LOD, occlusion culling, instancing, and baked lighting as the main 3D tools.  
<https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html>  
<https://docs.godotengine.org/en/4.7/tutorials/performance/optimizing_3d_performance.html>  
<https://docs.godotengine.org/en/4.7/tutorials/3d/mesh_lod.html>  
<https://docs.godotengine.org/en/4.7/tutorials/3d/lights_and_shadows.html>

### 11.5 System RAM and the local AI path

The repository includes an embedded GGUF local AI path and optional Python/Ollama paths. Their runtime memory is not bounded by this visual note and must be measured separately.

**Project budgets**

- With local AI active: game working set **≤ 2.0 GiB**.
- With AI inactive: game working set **≤ 3.0 GiB**.
- Peak total committed memory should remain below 5.5 GiB, leaving headroom for Windows and the 7.5 GiB physical limit.
- No asset streaming test is valid until it runs with the intended AI mode active.
- Record private working set, peak working set, and commit for the game, AI process, and model separately; do not infer from file size.

### 11.6 Required target-PC test matrix

1. Godot 4.7.2 release export, Compatibility renderer for the 3D candidate.
2. Actual target machine, actual Windows build, actual AMD driver.
3. 1280×720, 1366×768, and 1920×1080 windowed output.
4. Six NPCs at 1× and 4× simulation speed.
5. AI rule-based, local GGUF, and server/Ollama modes as applicable.
6. Worst room, all major UI overlays open, dialogue, case board, map, and save/load.
7. Ten-minute soak plus cold boot and second-run load.
8. Capture FPS, frame time, CPU/GPU split, draw calls, primitives, video memory, process RAM, load time, and package size.

The AMD M330 is on legacy driver support. The exact driver and graphics API must be validated before promising renderer behavior.  
<https://www.amd.com/en/resources/support-articles/faqs/GPU-630.html>

## 12. Recommended asset manifest

### 12.1 Production assets for the complete visual reset

| ID | Asset family | First production count | Runtime target | Approval gate |
|---|---|---:|---|---|
| A01 | Crestwood master cutaway and depth layers | 1 dorm + 3 location establishing plates | 2560×1440 source maximum; 1280×720 reference | Full floor reads without labels; all ten zones discoverable |
| A02 | Modular room slices | 10 rooms/zones, 3 variants each | 64×32 or approved isometric grid | Tiles repeat without obvious seams |
| A03 | Architecture/foreground occluders | 25–40 pieces | atlas ≤2048 | Consistent perspective and light |
| A04 | Furniture/prop family | 60–90 final props | 64–256 px or 2048 atlas | Same material and edge language; no exposed source-pack identity |
| A05 | Evidence objects | 20–30 hero-readable objects | 64–256 px | Recognizable at gameplay scale and in the evidence card |
| A06 | Active character set | 7 active + Daniel | 80–110 px high | Unique silhouette; 4-direction set; no face drift |
| A07 | Character portraits | 8 | 512×512 source, downsample as needed | Consistent crop, lighting, and expression language |
| A08 | Day/night/weather variants | Dorm day, dusk, night; rain optional | Layered masks/palettes | Characters remain readable at every state |
| A09 | UI shell | Title, settings, map, notebook, case board, dialogue, accusation, legal | Vector/native controls + ≤2048 textures | 1366×768 and 1080p; controller focus; no debug-like boxes |
| A10 | Icon set | 30–50 final SVG-derived icons | 24/32/48 px | One stroke/fill system |
| A11 | Typography | Atkinson Hyperlegible Next + Source Serif 4 subsets | WOFF/TTF/OTF as Godot supports | Complete OFL files and language coverage |
| A12 | Paper/print/halftone textures | 3–5 seamless 512²/1024² maps | 2D, no mip unless measured | No visible tiling at 720p |
| A13 | Interaction/VFX | evidence pulse, contradiction, schedule marker, rain/dust | small atlases/particles | Readable without relying on color alone |
| A14 | Legal/credits presentation | one legal screen and notices file | text/native | Every shipped third-party item represented |

### 12.2 Recommended font sources

- Atkinson Hyperlegible Next: <https://github.com/googlefonts/atkinson-hyperlegible-next> and license <https://github.com/googlefonts/atkinson-hyperlegible-next/blob/main/OFL.txt>
- Source Serif 4: <https://github.com/adobe-fonts/source-serif> and license <https://github.com/adobe-fonts/source-serif/blob/master/LICENSE.md>

Both are SIL OFL 1.1. Bundle the font files and license, do not sell a font by itself, and observe reserved-font-name rules if modifying a font.  
<https://openfontlicense.org/ofl-faq/>

### 12.3 Conditional icon source

Kenney’s CC0 icons are the lowest-friction starting point. Lucide may be used for generic utility symbols, but its current license contains ISC terms plus an MIT list for Feather-derived icons; preserve the complete root license rather than assuming every icon has identical terms.  
<https://lucide.dev/license>

Game-icons.net is another option, but most icons are CC BY 3.0 and require creator/source credit. Use only selected icons, not indiscriminate bulk import.  
<https://game-icons.net/>

### 12.4 Required provenance record

For every accepted asset or family, record:

- asset ID and local path;
- title and publisher/author;
- exact product URL and download page;
- acquisition date and version/build;
- license name, SPDX identifier where applicable, and complete license file;
- price/receipt/tier without exposing payment data;
- commercial-use status;
- modification status;
- attribution requirement and approved credit string;
- standalone/source redistribution status;
- public-repository permission;
- AI-generation/AI-assistance disclosure if any;
- modifications and derived-asset chain;
- approver and approval date;
- whether the asset is blockout, reference, runtime dependency, or final art.

## 13. Direction-neutral staged hero-prototype plan

The goal of this plan is to learn whether the look and technical path work, not to finish the art direction prematurely.

### Stage 0 — Baseline and license quarantine (0.5–1 day)

**Deliverables**

- A private inventory of currently used files and their exact licenses.
- Hold list for Bitglow, Chrome District, any PIPOYA files intended for repository distribution, and all assets with no provenance.
- Target-PC baseline capture using the current build.
- 1280×720, 1366×768, and 1920×1080 reference screenshots.
- One page defining the non-negotiable redesign requirements: readable cast, evidence legibility, institutional mood, no toy-pack collage, no low-contrast overlays.

**Gate**

Do not acquire more packs until existing rights and target performance are known.

### Stage 1 — Shared content slice (1 day)

Use exactly the same narrative content for every direction:

- kitchen/hallway intersection;
- one bedroom doorway;
- detective, Jordan, and Morgan;
- one bottle/pills evidence object;
- one contradiction marker;
- one case card;
- one dialogue exchange;
- day-to-night transition.

Keep this slice small enough that a full art family is not accidentally produced.

### Stage 2 — Archival Cutaway style frame (1–2 days)

**Deliverables**

- One room-depth composition at 1280×720.
- Three character silhouettes at final gameplay size.
- One evidence close-up and one case card.
- Day and night palette versions.
- A 10–15 second interaction sequence assembled from static/layered art.

**Test**

View at native size, full size, and 50% size. Verify the player can name each person and evidence object within two seconds.

### Stage 3 — Civic Model live-3D spike (1–2 days)

**Deliverables**

- Import the same three characters and room through GLB.
- Godot Compatibility renderer.
- Orthographic cutaway camera.
- One baked/static fill, one shadowed light, one unshadowed practical.
- No final materials beyond the approved flat institutional palette.

**Gate**

Pass every 3D hard budget and the subjective comparison. If it only barely passes, use pre-rendering. A 45 FPS technical pass is not enough for a 60 FPS minimum target.

### Stage 4 — Rain on Glass compositing study (0.5 day)

Create one 10–15 second sequence from the shared slice. Do not build a full room. This tests graphic identity, readability, and the cost of multi-plane compositing.

### Stage 5 — Blind comparison and decision (0.5 day)

Show unlabeled captures/video to at least three testers. Ask:

1. What kind of place is this?
2. Which person is the detective?
3. Which object is evidence?
4. What time/mood does the scene communicate?
5. Does the image look intentionally designed or assembled from unrelated packs?
6. Would the same style support all three locations?

Score:

| Criterion | Weight |
|---|---:|
| Immediate readability | 25% |
| Mystery/story fit | 20% |
| Distinctiveness | 20% |
| Target-PC performance | 20% |
| Production throughput for the full cast/world | 15% |

**Decision rule**

- Choose Archival Cutaway if it wins readability/story and has no technical blocker.
- Choose Civic Model only if it offers a decisive gameplay/camera advantage and passes all hard performance gates.
- Choose Rain on Glass only if testers find the atmosphere and evidence language substantially stronger and the schedule-overview loss is acceptable.

### Stage 6 — One complete hero beat (3–5 days after direction approval)

Complete one polished five-to-eight-minute sequence:

1. observe a routine;
2. notice an anomaly;
3. examine evidence;
4. question one suspect;
5. place two facts on the case board;
6. see a contradiction;
7. close the scene without resolving the case.

Use final-quality art and UI, not greyboxes. This is the production gate.

### Stage 7 — Production expansion only after the gate

Only after the hero beat is approved:

- derive the cast family;
- build all ten dorm zones;
- build police and university establishing art;
- finalize atlases, import presets, and legal notices;
- run the target performance/load/soak matrix.

## 14. Manual verification queue

These are the facts that most require manual recheck before purchasing, committing, or shipping:

1. **Radeon R5 M330 installed driver and API support.** AMD lists the GPU as legacy and the last Windows driver as 2022. Verify actual driver, OpenGL function support, and Godot Compatibility startup on the target machine.
2. **Actual 2 GB board memory.** The AMD family page lists a maximum of 4 GB; the target machine is stated as 2 GB. Confirm in Windows diagnostics.
3. **Godot Asset Store paid availability.** The current roadmap says free-only; recheck before planning purchases.
4. **Fab listing license.** Some migrated Unreal Marketplace products may still use the legacy UE Marketplace License. Check each listing.
5. **Fab Personal versus Professional tier.** The current docs base the choice on commercial revenue, not on whether the output game is commercial. Recheck the EULA at purchase.
6. **Unity provider-specific terms.** The standard EULA is not the whole story for every product; check Restricted Assets, provider EULAs, and editor/extension seat rules.
7. **KayKit Mystery Series 6.** It is current and CC0-labeled but paid; confirm the current tier, files, and license at checkout.
8. **Quaternius tier/file availability.** Pages distinguish free portions, source/supporter versions, and file formats. Confirm the exact archive downloaded.
9. **Blendkit product license.** “Free” does not tell you whether the product is Royalty Free or CC0. Confirm each product and whether raw 3D may be shipped in a Godot PCK.
10. **Sketchfab model license.** Capture the license shown at the moment of download; do not rely on a category filter.
11. **Bitglow redistribution.** The custom license forbids standalone redistribution and sharing outside the project team. Confirm repository visibility and any contractor/team boundaries.
12. **Chrome District conflict.** Local files say CC0 for PNG/JSON; the current itch metadata says CC BY 4.0 and discloses AI assistance. Obtain clarification before use.
13. **PIPOYA terms.** Commercial game use is stated, but raw redistribution is forbidden. Confirm how the project repository will be distributed.
14. **All current `godot/assets/` files.** A generated file manifest is not a source/license manifest; missing adjacent licenses need reconstruction from the original pack.
15. **Paid raw files in Git.** A private local workspace, a private repository, a public repository, a contractor handoff, and an exported PCK are different distribution contexts.
16. **Target AI memory.** Measure the selected local/remote AI path under real conversation and batch conditions; do not budget from model filename size.

## 15. Final recommendation

Proceed with **Archival Cutaway** as the default redesign direction and use **Civic Model** only as a measured technical alternative. The next artifact should be a shared kitchen/hallway hero slice with detective, Jordan, Morgan, one evidence object, one case card, and one dialogue exchange. That slice can test both the bespoke 2.5D recommendation and live 3D without committing to a full migration or buying a large asset library.

The decisive rule is simple: **no asset enters the final game because it was free; it enters only because its license, silhouette, material, scale, performance, and story role all passed the same approval gate.**

## 16. Primary source index

### Godot 4.7.2

- Release: <https://godotengine.org/article/maintenance-release-godot-4-7-2/>
- System requirements: <https://docs.godotengine.org/en/4.7/about/system_requirements.html>
- Renderers: <https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html>
- Internal rendering architecture: <https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html>
- Import process: <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/import_process.html>
- Image import/compression: <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html>
- 3D formats and Blender import: <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html>
- 3D import configuration: <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html>
- Advanced 3D import settings: <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/advanced_import_settings.html>
- Model export considerations: <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/model_export_considerations.html>
- TileMapLayer: <https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilemaps.html>
- Multiple resolutions: <https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html>
- Performance monitors: <https://docs.godotengine.org/en/4.7/classes/class_performance.html>
- GPU optimization: <https://docs.godotengine.org/en/4.7/tutorials/performance/gpu_optimization.html>
- 3D optimization: <https://docs.godotengine.org/en/4.7/tutorials/performance/optimizing_3d_performance.html>
- Mesh LOD: <https://docs.godotengine.org/en/4.7/tutorials/3d/mesh_lod.html>
- Lights and shadows: <https://docs.godotengine.org/en/4.7/tutorials/3d/lights_and_shadows.html>
- Godot license: <https://godotengine.org/license/>
- Third-party license compliance: <https://docs.godotengine.org/en/4.7/about/complying_with_licenses.html>

### Godot asset discovery

- Legacy Asset Library: <https://godotengine.org/asset-library/asset>
- New Asset Store: <https://store.godotengine.org/>
- Asset Store overview: <https://docs.godotengine.org/en/4.7/community/asset_store/what_is_asset_store.html>
- Asset Store terms: <https://store.godotengine.org/terms/>
- Official Godot 4.7 isometric demo: <https://github.com/godotengine/godot-demo-projects/tree/4.7/2d/isometric>

### Blender and glTF

- Blender 5.1.2 release: <https://www.blender.org/download/releases/5-1/>
- Blender license/output rights: <https://www.blender.org/about/license/>
- Blender 5.1 glTF add-on: <https://docs.blender.org/manual/en/5.1/addons/import_export/scene_gltf2.html>
- Khronos glTF: <https://www.khronos.org/gltf/>

### Target hardware

- Radeon R5 M330 support/specifications: <https://www.amd.com/en/support/downloads/drivers.html/graphics/radeon-r9-r7-r5/radeon-r5-300-series/amd-radeon-r5-m330.html>
- AMD legacy GPU support: <https://www.amd.com/en/resources/support-articles/faqs/GPU-630.html>

### Asset sources and licenses

- Kenney support/license: <https://kenney.nl/support>
- Quaternius: <https://quaternius.com/>
- KayKit Furniture Bits: <https://kaylousberg.itch.io/furniture-bits>
- KayKit Restaurant Bits: <https://kaylousberg.itch.io/restaurant-bits>
- KayKit City Builder Bits: <https://kaylousberg.itch.io/city-builder-bits>
- Blendkit user terms: <https://www.blendkit.com/terms-and-conditions-2026/>
- Poly Haven license: <https://polyhaven.com/license>
- ambientCG license: <https://ambientcg.com/license>
- Sketchfab license agreement: <https://sketchfab.com/licenses>
- OpenGameArt FAQ: <https://opengameart.org/content/faq>
- CC0 1.0 deed: <https://creativecommons.org/publicdomain/zero/1.0/>

### Commercial stores

- Fab Standard License: <https://www.fab.com/eula>
- Fab license types: <https://dev.epicgames.com/documentation/fab/licenses-and-pricing-in-fab>
- Fab accepted formats: <https://dev.epicgames.com/documentation/fab/asset-file-format-and-structure-requirements-in-fab>
- Unity Asset Store EULA: <https://unity.com/legal/as-terms>
- Unreal Marketplace successor page: <https://www.unrealengine.com/marketplace/en-US/>

### 2D tools and fonts

- Krita license: <https://krita.org/en/about/license/>
- Aseprite FAQ/license: <https://www.aseprite.org/faq/>
- Aseprite CLI: <https://www.aseprite.org/docs/cli/>
- LibreSprite: <https://libresprite.github.io/>
- Tiled isometric maps: <https://doc.mapeditor.org/en/stable/manual/maps/>
- Tiled Godot 4 exporter: <https://doc.mapeditor.org/en/stable/manual/export-tscn/>
- Atkinson Hyperlegible Next: <https://github.com/googlefonts/atkinson-hyperlegible-next>
- Source Serif 4: <https://github.com/adobe-fonts/source-serif>
- SIL OFL FAQ: <https://openfontlicense.org/ofl-faq/>

## 17. Prototype measurements (2026-09-25)

The first hero slice and a controlled live-3D comparison were built in `godot/scenes/prototypes/`. Both used the same Blender-authored room geometry and the same Compatibility/Windows target path where applicable.

| Path | Capture | Draw calls | Primitives | Result |
|---|---|---:|---:|---|
| Archival Cutaway 2.5D | `archival_cutaway_hero_capture.png` | 122 | 5,662 | Chosen for the redesign: authored ink/paper treatment, readable cast, low geometry cost |
| Civic Model live 3D | `civic_model_spike_capture.png` | 137 | 61,618 | Rejected for now: one room already exceeds the recommended 100-draw-call target and loses character readability from the top-down camera |

The fixed-fps capture harness makes the instantaneous FPS reading unsuitable as a benchmark, so the decision uses draw calls, primitive count, visual comparison, and the documented target-PC gates rather than that single FPS sample. The 3D spike remains available for a later lighting/material pass, but the evidence supports keeping the runtime in 2D and using Blender offline.

Prototype files:

- `godot/scenes/prototypes/archival_cutaway_hero.tscn`
- `godot/scenes/prototypes/civic_model_spike.tscn`
- `godot/assets/prototypes/asset_manifest.json`
- `tools/blender/generate_archival_cutaway_hero.py`
- `tools/blender/apply_archival_treatment.py`
