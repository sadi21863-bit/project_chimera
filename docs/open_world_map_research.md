# Project Chimera: Continuous Outdoor World Research

**Research date:** 2026-09-24  
**Verified toolchain:** Godot **4.7.2** is the current Windows stable release ([official download](https://godotengine.org/download/windows/)); Blender **5.1.2** was released on 2026-05-19 ([official 5.1 release notes](https://www.blender.org/download/releases/5-1/)). The project itself declares Godot 4.7, Forward+, 1280×720, and a 2D `Node2D` main scene ([project.godot](../godot/project.godot), [main.tscn](../godot/scenes/main.tscn)).

## Recommendation in one sentence

Keep Project Chimera in **2D**, make every outdoor district one walkable, bounded **OutdoorWorld** with shared coordinates, keep its base terrain/collision/navigation resident, and defer custom chunk streaming until profiling proves it necessary; only building interiors may swap rooms/scenes.

“Open” should mean **no outdoor travel transitions**, not an infinite map. Author a clear boundary and camera limits so the player can walk anywhere outdoors without a load, fade, or invisible travel between “campus” and “courtyard.”

## Current-state implications

- `LocationManager` currently conflates outdoor destinations with interiors: `campus` and `courtyard` are entries alongside the dorm, bedrooms, university, police station, library, hospital, bar, and other rooms ([location_manager.gd](../godot/autoload/location_manager.gd)). `main.gd` responds to every location change by freeing the old scene, loading another, and fitting the camera to its floor ([main.gd](../godot/scenes/main.gd)). That architecture directly conflicts with the requested continuous outdoors.
- The current campus is one roughly 1400×900 composed Blender/Kenney backdrop with three door triggers, while the courtyard is another approximately 1200×560 scene ([campus.tscn](../godot/scenes/locations/campus.tscn), [courtyard.tscn](../godot/scenes/locations/courtyard.tscn), [build_campus.gd](../godot/tools/build_campus.gd)). The campus navigation polygon is currently a large rectangle, so it does not describe paths around buildings accurately.
- The dorm already uses room-scale scenes and door triggers inside one building, which is the useful precedent to preserve. It should become the prototype for all enterable buildings, not a model for outdoor travel.
- The existing performance target is 60 FPS, under 50 draw calls, and a 32×32 pixel-sprite aesthetic ([performance-notes.md](performance-notes.md)). Moving outdoors to 3D would replace this low-overdraw path with mesh, material, light, LOD, and navigation costs without improving the mystery game.

## Workflow comparison

| Workflow | Player continuity | Memory/I/O | Navigation | Fit for Chimera |
|---|---|---|---|---|
| One large 2D scene, everything resident | Perfect | Simplest; grows with node count | One or a few merged regions | **Best first implementation** at campus scale |
| One logical 2D world with resident terrain/collision/nav plus streamed content chunks | Perfect; streaming is invisible | Predictable and bounded; adds custom lifecycle code | Keep outdoor nav resident; chunk only presentation/dynamics | **Recommended end state if profiling requires it** |
| Separate outdoor room scenes, current design | Breaks at every boundary | Low per scene | Simple, but cannot support global outdoor schedules | Reject for outdoor spaces |
| Procedural 2D terrain | Perfect | Can generate cheaply, but content still needs nodes/textures | Works with grid or generated polygons | Use only for optional grass/detail variation, not mystery landmarks |
| 3D open world with heightmap, occlusion, LOD, visibility ranges | Perfect | Highest asset, memory, and authoring cost for this hardware | Requires 3D nav, meshes, and physics | Defer; it is a different game and renderer workload |

## Godot 4.7 building blocks

### Terrain and world size

- `TileMapLayer` is optimized for large numbers of tiles; Godot recommends multiple layers for background, ground, and foreground, and supports collision, light occlusion, terrains/autotiling, Y-sort, and rendering/physics quadrants ([Using TileMaps](https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilemaps.html), [`TileMapLayer`](https://docs.godotengine.org/en/4.7/classes/class_tilemaplayer.html)). A practical Chimera layout is three or four global layers: ground, paths/ground detail, collision/terrain decoration, and a sparse foreground/Y-sort layer—not thousands of individual ground sprites.
- Serialized `TileMapLayer` coordinates are signed 16-bit (`-32768..32767` cells). At 16 px per cell that is ±524,272 px, far beyond a plausible campus, so Chimera does **not** need coordinate-based world partitioning ([`TileMapLayer`](https://docs.godotengine.org/en/4.7/classes/class_tilemaplayer.html)). This is a documented engine limit, not a target map size.
- Set the player camera’s `Camera2D.limit_*` values to the authored outdoor bounds and stop calling the current whole-location auto-fit for outdoor play ([`Camera2D`](https://docs.godotengine.org/en/4.7/classes/class_camera2d.html)). Zoom should be a fixed gameplay setting, not a way to fit each outdoor district to the screen.

### Culling, occlusion, and batching

- Godot renders ordinary `CanvasItem`s without requiring a visible-on-screen node. Use `VisibleOnScreenNotifier2D` to run or disable distant ambient systems, and `VisibleOnScreenEnabler2D` for simple nearby activation ([notifier](https://docs.godotengine.org/en/4.7/classes/class_visibleonscreennotifier2d.html), [enabler](https://docs.godotengine.org/en/4.7/classes/class_visibleonscreenenabler2d.html)).
- **No general 2D portal/visibility-occlusion-culling node was found in the Godot 4.7 class reference.** `LightOccluder2D` exists, but it only blocks `Light2D` shadows; it is not a 2D renderer occlusion system ([`LightOccluder2D`](https://docs.godotengine.org/en/4.7/classes/class_lightoccluder2d.html)). Do not build Chimera around unverified 2D occlusion claims.
- Godot’s documented occlusion-culling system is **3D-only**. It is most effective in interiors with many occluders and can be ineffective in open scenes, while baking/running it adds CPU cost ([3D occlusion culling](https://docs.godotengine.org/en/4.7/tutorials/3d/occlusion_culling.html)). Chimera’s open top-down outdoors and room-swapped interiors give little reason to adopt it.
- Batch repeated distant grass, litter, and small decorations with `MultiMeshInstance2D`; Godot notes it can outperform many transparent `Sprite2D` nodes with large transparent areas ([`MultiMeshInstance2D`](https://docs.godotengine.org/en/4.7/classes/class_multimeshinstance2d.html)). Keep interactive, clue-bearing, and story-critical objects as ordinary nodes.

### Navigation

- Keep Chimera’s current `NavigationAgent2D` model. For the outdoor campus, author one or a few merged, pre-baked `NavigationRegion2D` polygons covering paths, lawns, and plazas while excluding building footprints. The official manual warns that built-in TileMap navigation has practical quality/performance limitations and recommends baking a `NavigationPolygon` ([Using navigation meshes](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_using_navigationmeshes.html)).
- With one bounded campus, keep the complete outdoor navigation mesh resident even if presentation chunks stream. This prevents an NPC path from failing across an unloaded boundary and avoids runtime baking. Monitor `NAVIGATION_2D_*` values through the official `Performance` monitors ([`Performance`](https://docs.godotengine.org/en/4.7/classes/class_performance.html)).
- If the outdoor map later grows enough to require navigation chunks, use aligned `baking_rect` and `border_size` values so region edges connect cleanly; Godot provides an official 2D chunk demo for this pattern ([navigation mesh chunk guidance](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_using_navigationmeshes.html#baking-navigation-mesh-chunks-for-large-worlds), [official demo](https://github.com/godotengine/godot-demo-projects/tree/master/2d/navigation_mesh_chunks)).
- `AStarGrid2D` is a good alternative only if outdoor walkability becomes a simple cell grid that changes often. It is simpler for solid cells but would duplicate the current navigation concept and is not needed for the first campus ([`AStarGrid2D`](https://docs.godotengine.org/en/4.7/classes/class_astargrid2d.html)).

### Streaming and world partitioning

- No first-party Godot 4.7 core world-partition/automatic outdoor-streaming system was found in the official class reference, documentation, or the `godotengine/godot` source search performed for this note. Treat this as a **bounded 2026-09-24 finding**, not a guarantee about later releases.
- Godot supplies asynchronous resource loading, not a world manager: `ResourceLoader.load_threaded_request()` loads in background threads, while `load_threaded_get()` can block if called too early ([Background loading](https://docs.godotengine.org/en/4.7/tutorials/io/background_loading.html), [`ResourceLoader`](https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html)). The official threaded-loading demo is MIT-licensed and uses Compatibility ([Asset Library page](https://godotengine.org/asset-library/asset/2778)).
- For Chimera’s small set of interiors, **preload the `PackedScene` resources at startup and instantiate only the active interior**. Avoid I/O while the player is at a door. For future outdoor content chunks, use `ResourceLoader` with `use_sub_threads=false` on this low-end CPU; Godot warns sub-threads can slow the main thread. If eviction matters, evaluate `CACHE_MODE_IGNORE` and verify memory with profiling rather than assuming a freed node immediately removes every resource.
- Start with all outdoor content resident. If measurement fails, split only props, ambient systems, and noncritical actors into addressable content chunks. A starting experiment is 2048×2048 px chunks with the player chunk plus eight neighbors resident; increase the chunk size only after testing. Keep terrain, collisions, and navigation outside that streaming ring.

## Performance implications for the stated PC

The AMD A9/Radeon M330/7.5 GB RAM target makes **2D the lower-risk direction**, not merely the cheaper migration. Godot’s renderer guide says Compatibility targets low-end hardware and 2D games and that Forward+ has the highest base cost ([renderer comparison](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html)). Chimera currently uses Forward+, so test a Compatibility-renderer build before shipping; retain Forward+ only if an actually used feature or visual test justifies it.

Proposed acceptance guardrails—not measured facts—are:

- 1280×720, 60 FPS at 1× and at least 55 FPS at 4× simulation, matching the existing target.
- Fewer than 50 rendered draw calls in normal outdoor traversal; inspect `RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, `TIME_FPS`, `TIME_PROCESS`, `TIME_PHYSICS_PROCESS`, `RENDER_VIDEO_MEM_USED`, node count, physics pairs, and 2D navigation metrics in the Debugger Monitor ([`Performance`](https://docs.godotengine.org/en/4.7/classes/class_performance.html)).
- Establish an explicit release-build RSS ceiling that leaves headroom for Windows and the optional local AI stack; treat 1.0 GB process RSS as an initial **test budget**, not a guarantee.
- Prefer several shared 2048×2048 atlases over many unique textures. One uncompressed RGBA8 2048² texture is about 16 MiB before mipmaps; a 4096² one is about 64 MiB, which is expensive on a 2 GB GPU.
- Share the ground TileSet and materials, use `use_parent_material` where appropriate, avoid per-tile `queue_redraw()`, and cap real-time 2D lights. Godot documents that larger 2D lights and PCF13 soft shadows are expensive; retain `CanvasModulate` for day/night and use additive sprites for brief effects where acceptable ([2D lights and shadows](https://docs.godotengine.org/en/4.7/tutorials/2d/2d_lights_and_shadows.html)).
- Do not profile only the editor. Record the same route outdoors at startup, after a building round trip, after all chunks have been touched, and with the AI server/Ollama configuration that will actually ship.

## Assets and licensing

### Best-fit existing/free sources

| Source | Use | License/access caveat |
|---|---|---|
| [Kenney City Kit (Suburban)](https://kenney.nl/assets/city-kit-suburban) | Existing local 3D source for building shells, roads, and suburban forms rendered into Chimera’s 2D style | Official listing: 40 3D assets, **CC0**; attribution not required |
| [Kenney Furniture Kit](https://kenney.nl/assets/furniture-kit) | Existing local 3D reference/source for dorm and institutional interiors | Official listing: 140 3D assets, **CC0** |
| [Kenney Roguelike Indoors](https://kenney.nl/assets/roguelike-indoors) | Existing local 2D prototype furniture | Official listing: 480 2D assets, **CC0**; style is not modern-campus-specific |
| [Pipoya 32×32 world tiles](https://pipoya.itch.io/pipoya-rpg-tileset-32x32) and [characters](https://pipoya.itch.io/pipoya-free-rpg-character-sprites-32x32) | Already downloaded; useful for blockout and small props | Creator page describes commercial/personal use, editing, and no redistribution/resale. This is a **custom license, not CC0**; preserve the exact downloaded license/version and verify before release |
| [bitglow 16×16 interiors](https://bitglow.itch.io/pixelinterior-livingroomkitchen) | Cozy dorm/kitchen/common-room furniture; bedroom and bathroom pages are linked from the creator page | Custom Bitglow license: commercial/non-commercial use allowed, no redistribution/resale; preserve packaged terms |
| [Quaternius Downtown City MegaKit](https://quaternius.com/packs/downtowncitymegakit.html) | Modular 3D city source for Blender orthographic sprite production | Specific pack page says the free tier is **CC0** and includes FBX/Blend/glTF; the site-wide [QAL](https://quaternius.com/license.html) prohibits redistributing assets, so save the exact download’s license and distinguish free from paid source tiers |
| [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) | Low-poly Blender renders or placeholders; visual style needs substantial campus/dorm adaptation | Creator page says **CC0**, with FBX/glTF; source `.blend` is a paid tier |
| [Poly Haven](https://polyhaven.com/license) and [ambientCG](https://docs.ambientcg.com/license/) | Useful PBR ground/building material references when producing stylized Blender renders | Both say assets are **CC0 1.0** and may be used, modified, and shipped without attribution. They are not stylized sprite packs; use selectively and preserve attribution records even though credit is not required |
| [Blender Studio remixing](https://studio.blender.org/remixing) and [Texture Library](https://studio.blender.org/blog/new-texture-library) | Official source for selected production assets/textures | Blender Studio is generally **CC BY** with per-asset notices; the linked historical Texture Library announcement says its textures are **CC0**. Check each item rather than assuming one license |

### Commercial option

- [Pixel Art Top Down – Village](https://assetstore.unity.com/packages/2d/environments/pixel-art-top-down-village-317193) is the clearest direct 2D paid reference found: the listing identifies 32×32 top-down pixel art, a 22.3 MB package, and version 1.0.11 as of this research. It uses the [standard Unity Asset Store EULA](https://unity.com/legal/as-terms), which permits embedding and distributing the asset as part of a licensed product and does not state a Unity-only runtime restriction. **Verify before purchase** that the package contains ordinary PNG/source images usable in Godot, that it is not a restricted asset, and that no provider-specific terms override the EULA. Prices, versions, and package contents can change; this is not legal advice.
- Do not assume a Unity package imports directly into Godot merely because its license allows use outside Unity. Confirm formats, prefab-only dependencies, shaders, and derivative-work terms first.

### Licensing warning for the existing audit

The local [free-assets report](free-assets-downloaded.md) is useful inventory, but its blanket “safe for commercial use” conclusion is not a substitute for preserving each source license. In particular, the current [CHROME DISTRICT page](https://booliebuilds.itch.io/chrome-district) says **CC0 1.0** in its description while itch.io’s metadata labels the asset license **CC BY 4.0** and also marks it AI-assisted. That conflict needs creator clarification before commercial use. Similar provenance should be checked for the local “Ultimate” packs and “Free House Pixel Art,” whose exact source pages were not established here.

## Blender 5.1.2 production workflow

1. **Use Blender as an offline asset factory, not a runtime dependency.** Import the CC0 Kenney/Quaternius models or model only Chimera-specific building shells, sidewalks, fences, trees, benches, signage, and dorm façades.
2. Match the existing campus camera, scale, lighting direction, and pixel footprint exactly. Render modular objects individually with an orthographic camera rather than continuing one giant composed backdrop; otherwise Y-sorting, entrances, occlusion, and later expansion remain awkward.
3. Use a transparent film for PNG props ([Blender 5.1 Film manual](https://docs.blender.org/manual/en/5.1/render/eevee/render_settings/film.html)), flat/toon materials, and restrained source geometry. Blender’s Decimate modifier can reduce source complexity before export/render when appropriate ([Decimate modifier](https://docs.blender.org/manual/en/5.1/modeling/modifiers/generate/decimate.html)).
4. Render one family at a time and close Blender before playtests. This is particularly important with 7.5 GB system RAM; do not render a whole district or open all source packs at once.
5. Package final PNGs, the Blender source, source URL, creator, license text, version, and any modifications together. Downsample runtime art to 16/32 px while keeping a higher-resolution master only in source control or offline storage.
6. If Chimera ever moves to 3D, export **glTF 2.0/GLB** rather than inventing another path: Godot recommends glTF 2.0 ([Godot 3D formats](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html)), and Blender 5.1 includes the official glTF exporter ([Blender 5.1 glTF manual](https://docs.blender.org/manual/en/5.1/addons/import_export/scene_gltf2.html)).

## Recommended architecture and migration

### Target scene/state model

```text
Main (persistent)
├─ WorldCoordinator
│  ├─ OutdoorWorld (created once; one coordinate space)
│  │  ├─ TerrainLayers (resident TileMapLayers)
│  │  ├─ OutdoorNavigation (resident, baked)
│  │  ├─ BuildingPortals
│  │  ├─ ContentChunkHost (initially all resident; later streamed)
│  │  └─ OutdoorActorHost
│  └─ InteriorHost (one active building room at a time)
├─ Player (one persistent instance)
├─ GlobalSimulation (NPC schedule/state, evidence, time)
└─ UI
```

`WorldCoordinator` should own a small context record such as `mode`, `building_id`, `room_id`, `interior_entry_id`, and `outdoor_return_transform`. `LocationManager` can be retained temporarily, but it must no longer treat outdoor areas as loadable scenes. Its registry should distinguish `OUTDOOR_DISTRICT` metadata from `INTERIOR_ROOM` scenes.

### Ordered migration

1. **Capture a baseline first.** On the target PC, record a fixed outdoor route plus FPS, frame/process/physics/navigation time, draw calls, texture/video memory, node count, and release-build RSS. No architecture decision should be called “cheap” without this evidence.
2. **Build `outdoor_world.tscn` as a graybox.** Merge `campus` and `courtyard` into one coordinate space, remove the wall/floor boundary where they should connect, relocate existing search markers, and set camera limits. Keep the current backdrop temporarily as a visual reference, not the final terrain.
3. **Replace the backdrop with layered terrain.** Add ground, path, detail, and foreground/Y-sort layers; add real collision around buildings; then bake the outdoor walkable polygons so NPCs and the player cannot walk through façades. Do not import interior geometry into outdoor navigation.
4. **Introduce building portals.** Each exterior entrance stores `building_id`, `interior_scene`, `interior_entry_id`, `outdoor_return_transform`, schedule/access rules, and display text. Entering a portal swaps only `InteriorHost`; leaving restores the exact outdoor position and facing. University, police station, library, hospital, bar, server room, and the detective’s room can all become interior destinations behind authored exteriors.
5. **Preserve dorm room loading.** Keep the current dorm, hallway, kitchen, common room, bathroom, and bedroom scene mechanism. Add building identity and paired entry/exit IDs so moving from a bedroom back to `crestwood_hall`, then outside, cannot accidentally return to the campus spawn.
6. **Make the player persistent.** Chimera currently spawns a detective inside each location. Move ownership to `Main`/`WorldCoordinator` and reparent the same player into the active spatial context. Save the outdoor position before entering and apply the paired interior spawn after loading.
7. **Separate simulation identity from scene nodes.** NPC schedule/location/relationships remain in global data. Outdoor NPC nodes activate near their current world position; an off-screen NPC can still advance on schedule without a permanent sprite/physics node. Dorm room nodes should not be duplicated merely because the player can see the same resident while outdoors.
8. **Preload all interior scene resources.** This is a small, bounded set and removes I/O hitches at doors. Add chunk streaming only if step 1 or end-to-end playtesting shows memory/node pressure. When added, use 2048×2048 content chunks, a three-by-three resident ring, one-chunk prefetch, and never unload a chunk containing an active actor, clue, or return portal.
9. **Change the map’s role.** The existing fast-travel UI can become a campus overview/journal showing the player’s continuous position and discovered buildings. Normal outdoor-to-outdoor teleport should be removed; interior room travel remains local to a building.
10. **Validate with a migration matrix.** Test every building entrance/exit, every dorm room pair, locked doors, save/load in outdoor and interior contexts, NPC schedule continuity, navigation across every road/path, camera bounds, chunk eviction if enabled, and the target PC after a full outdoor circuit.

## Tools and addons

- **No addon is required for the first implementation.** Godot’s built-in `TileMapLayer`, `NavigationRegion2D`, `Camera2D`, `VisibleOnScreenEnabler2D`, `MultiMeshInstance2D`, `FastNoiseLite`, and `ResourceLoader` cover the recommended architecture ([`FastNoiseLite`](https://docs.godotengine.org/en/4.7/classes/class_fastnoiselite.html)).
- Use the official [Navigation Mesh Chunks 2D demo](https://github.com/godotengine/godot-demo-projects/tree/master/2d/navigation_mesh_chunks) as a reference only if navigation chunking becomes necessary; the current campus should start with one merged map.
- Tiled’s built-in [Godot 4 exporter](https://doc.mapeditor.org/en/stable/manual/export-tscn) can author external/shared TileSets and layer metadata, but it has documented limitations. Adopt it only if Godot-native painting becomes the bottleneck; do not introduce it merely to implement runtime streaming.
- LDtk lists three **community** Godot importers, not an official Godot integration ([LDtk importer directory](https://ldtk.io/api/)). They add maintenance, Godot-version, and license review burden that Chimera does not currently need.
- The [2D Procedural Map Generator](https://godotengine.org/asset-library/asset/3070) is an MIT-licensed community add-on for Godot 4.2, but its randomized sequential-path model is a poor fit for an authored mystery campus. Treat the Asset Library listing as a submission, not an official endorsement, and recheck compatibility before adoption.

## Final recommendation and uncertainty

Adopt a **single continuous 2D outdoor world with resident terrain/collision/navigation, optional content-only chunk streaming, and scene/room loading confined to building interiors**. Do not adopt 3D, procedural generation as the primary world, unverified 2D occlusion, Tiled/LDtk, or a third-party world-partition add-on for the first migration. Validate the Compatibility renderer and use a small set of shared atlases, Y-sorted tilemaps, baked navigation, and strict profiler budgets.

The architectural direction is high confidence. Exact chunk size, eviction radius, memory ceiling, and renderer choice remain uncertain until measured on the stated PC. The direct paid pack’s importability was not verified, the local archive does not preserve every source license consistently, and CHROME DISTRICT currently has contradictory CC0/CC BY metadata. Treat those as release blockers until verified rather than inferred.
