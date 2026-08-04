# Hybrid 2D/3D Art Pipeline — Prep Notes

**Goal:** Replace placeholder ColorRects with real visuals using a fully permissive (CC0,
public-domain-equivalent) hybrid pipeline: 2D tilesets/UI for environments, and CC0 3D character
models pre-rendered (via Blender, driven through the Blender MCP connector once installed) into 2D
sprite sheets for the detective/suspects/NPCs. Pre-rendering (not live 3D-in-2D) keeps runtime cost
identical to plain 2D sprites — important given the target hardware (AMD A9-9420, 1.7GB VRAM GPU)
is already known to struggle with heavier workloads (see the local-AI performance-ceiling finding).

## Asset list (all CC0 — no attribution, no commercial restriction, no share-alike)

| Layer | Pack | Source | License |
|---|---|---|---|
| Environment tiles/furniture | Furniture Kit | kenney.nl/assets/furniture-kit | CC0 |
| Environment tiles | Isometric Prototype / Library Tiles | kenney-assets.itch.io | CC0 |
| UI theme | UI Pack | kenney.nl/assets/ui-pack | CC0 |
| 3D characters | Mini Characters (primary) | kenney.nl/assets/mini-characters | CC0 |
| 3D characters | Quaternius (supplement, more variety + pre-rigged animations) | quaternius.com | CC0 |

Kenney's 2D and 3D packs share a consistent stylized-toy aesthetic, so leaning on Kenney first for
both halves keeps the look cohesive; Quaternius fills in if more character variety or ready-made
walk-cycle animations are wanted.

## Codebase audit (what changes, what doesn't)

- **No test asserts on visual properties** (`grep` across `godot/tests/` for `.color`/`ColorRect`
  found nothing) — the sprite swap is test-safe.
- **`detective.tscn`**: `Sprite` (ColorRect) is purely visual, zero code references it
  (`detective.gd` never touches `$Sprite`) — a direct swap to `AnimatedSprite2D` named `Sprite`.
- **`npc.tscn`/`npc.gd`**: `_sprite: ColorRect = $ColorRect`, and `_apply_profile()` sets
  `_sprite.color = p.color` — this is the one real code dependency. Plan: add
  `@export var sprite_frames: SpriteFrames` to `NpcProfile` (godot/resources/npc_profiles/npc_profile.gd),
  swap `$ColorRect` for an `AnimatedSprite2D` named `Sprite`, and in `_apply_profile()` set
  `_sprite.sprite_frames = p.sprite_frames` (or `.play("idle_down")`) instead of `.color`. Keep the
  `color` field as a harmless fallback/debug tint, don't remove it.
- **Floor rendering** (`crestwood_hall.tscn`, `police_station.tscn`, `university.tscn`,
  `detective_room.tscn`): currently flat `ColorRect` floors — swap for a `TileMapLayer` using a
  `TileSet` built from the Kenney tile packs. Room markers/`NavigationRegion2D` positions are
  independent of the floor's visual — no logic changes needed, purely a new TileSet resource + node
  swap.
- **UI theme**: none of the UI scenes (`story_screen.tscn`, `settings_screen.tscn`, `travel_map.tscn`,
  etc.) set an explicit `Theme` resource — they're all inheriting the Godot default theme. Plan: one
  shared `Theme` resource (built from the Kenney UI Pack) assigned at the root `CanvasLayer`/
  `Control` of each UI scene (or project-wide via `ProjectSettings` default theme) — a single-point
  change, not per-scene rewrites.

## Character rendering spec (for once Blender MCP is live)

Minimum per character (detective + alex/jordan/sam/riley/morgan/casey + dean): idle (facing down) +
4-directional walk cycle (down/up/left/right, ~4-6 frames each). Nice-to-have if time allows: a
"talk" idle variant for interrogation portraits. Render orthographic top-down (matching the existing
camera), transparent background, consistent character height/scale across all 9 so nobody looks
mismatched standing in the same room.

## Approved follow-up (after the indoor art pass — not started)

User dumped ~40 additional CC0 asset packs into `asset dump/` (all audited: Kenney + Quaternius,
all CC0 1.0 Universal; two "Starter-Kit" zips are Kenney's own official Godot templates, MIT). Full
audit results in chat history / `HANDOFF.md`. Beyond what this plan already covers, one pack stands
out as a real "expand the world" opportunity: **`Starter-Kit-City-Builder-main.zip`** — a complete,
already-imported Godot scene (buildings, roads, pavement, fountain, grass/trees) that could seed an
actual walkable **outdoor campus** connecting the dorm/university/police station, supplemented by
the Buildings pack, Ultimate Textured Building Pack, Public Transport Pack, Textured Stylized Trees,
Ultimate Nature Pack, and `kenney_retro-urban-kit.zip` (all exterior-suited, all CC0). **User
approved this as a real follow-up slice — sequenced after the indoor art pass (this plan) is done,
not before.** Treat it as its own plan doc + branch when its turn comes, same TDD/playtest/merge
rhythm as everything else in this project.

## Not started yet — waiting on
- User finishing the Kenney/Quaternius downloads.
- Blender + the Blender MCP connector being installed and running (`claude mcp add blender -- uvx blender-mcp`).

Once both are ready: pose/render each character in Blender via the MCP connector, export sprite
sheets into `godot/assets/characters/<npc_id>/`, build the `SpriteFrames` resources, wire them into
`NpcProfileFactory`, build the `TileSet` from the downloaded tile packs, and apply the UI theme —
each as its own small, tested slice following the project's usual TDD + branch + merge rhythm.
